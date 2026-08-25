# Maester AD E2E Lab - Deployment Issues and Remediations

## Executive Summary

This document captures all issues discovered during the deployment of the Maester end-to-end Active Directory lab in resource group `RG_5100_MiSoule_2` using Azure managed identity authentication. The deployment was partially successful: two forests with their root domains were created, but child domain promotion failed due to Azure VM Run Command credential delegation limitations.

## Successfully Deployed Resources

| Resource | Type | Status | IP Address | Domain |
|----------|------|--------|------------|--------|
| MiSouleDC02 | Domain Controller | ✅ Running | 10.20.0.4 | misoule02.local (root forest) |
| MiSouleDC04 | Domain Controller | ✅ Running | 10.20.0.6 | misoule03.local (separate forest) |
| MiSouleRunW | Windows Runner | ✅ Running | 10.20.0.10 | N/A |
| MiSouleRunnerLinux | Linux Runner | ✅ Running | 10.20.0.11 | N/A |
| MiSouleDC03 | VM (AD DS installed) | ⚠️ Partial | 10.20.0.5 | WORKGROUP (child domain promotion failed) |
| MiSouleNATGW | NAT Gateway | ✅ Running | 172.174.32.50 | N/A |
| MiSouleADTestVNet | Virtual Network | ✅ Running | 10.20.0.0/24 | N/A |

## Issues Discovered

### Issue 1: Managed Identity Key Vault Permissions

**Severity:** High
**Impact:** Deployment fails when attempting to store generated secrets in Azure Key Vault.

**Description:**
When running `Deploy-Lab.ps1` with a managed identity, the identity can create Key Vaults but cannot write secrets to them without explicit RBAC permissions. The script fails with:

```
ForbiddenByRbac: Caller is not authorized to perform action on resource.
Action: 'Microsoft.KeyVault/vaults/secrets/setSecret/action'
```

**Remediation:**
Grant the managed identity the **Key Vault Secrets Officer** role on the target resource group before deployment:

```powershell
$rgId = (az group show --name RG_5100_MiSoule_2 --query id -o tsv)
$identityPrincipalId = (az identity show --name <identity-name> --resource-group <identity-rg> --query principalId -o tsv)
az role assignment create `
  --assignee-object-id $identityPrincipalId `
  --role "Key Vault Secrets Officer" `
  --scope $rgId
```

**Alternative:** Use the `-SkipKeyVault` parameter to bypass Key Vault and print credentials to the console (less secure, suitable for short-lived labs only).

---

### Issue 2: Outbound Internet Access Required for AD DS Installation

**Severity:** High
**Impact:** Windows Server VMs cannot download AD DS feature payloads, causing `Install-WindowsFeature` to hang indefinitely.

**Description:**
Some Azure subscriptions disable default outbound access on subnets. When a Windows Server VM tries to install the AD-Domain-Services feature, it requires outbound internet access to download feature payloads from Windows Update. Without outbound access, the installation hangs silently.

**Remediation:**
Deploy a NAT Gateway and associate it with the lab subnet:

```powershell
az network public-ip create --resource-group RG_5100_MiSoule_2 --name MiSouleNATGW-Pip --sku Standard --allocation-method Static --location eastus
az network nat gateway create --resource-group RG_5100_MiSoule_2 --name MiSouleNATGW --public-ip-addresses MiSouleNATGW-Pip --location eastus
az network vnet subnet update --resource-group RG_5100_MiSoule_2 --vnet-name MiSouleADTestVNet --name LabSubnet --nat-gateway MiSouleNATGW
```

**Note:** The deployment scripts should be updated to automatically create and associate a NAT Gateway.

---

### Issue 3: Azure VM Run Command Startup Delays

**Severity:** Medium
**Impact:** Each domain controller deployment takes 60-90 minutes instead of the expected 20-30 minutes.

**Description:**
Azure VM Run Commands on Windows Server 2022 images experience startup delays of 30-50 minutes before script execution begins. This is an Azure platform behavior, not a script defect. The delay occurs between VM creation and the first line of the bootstrap script executing.

**Timeline observed:**
- VM created at T+0
- Bootstrap script starts executing at T+45 to T+55 minutes
- AD DS installation completes at T+60 to T+75 minutes
- Total per DC: 60-90 minutes

**Remediation:**
Increase the `CompletionTimeoutMinutes` parameter in `New-DomainController.ps1` from the default 60 minutes to at least 120 minutes:

```powershell
./build/activeDirectory/azure-lab/New-DomainController.ps1 `
  -CompletionTimeoutMinutes 120 `
  ...
```

**Alternative:** Use Azure Custom Script Extensions instead of Run Commands for the initial bootstrap. Custom Script Extensions may have different startup characteristics.

---

### Issue 4: Child Domain Promotion Fails Through Azure VM Run Commands

**Severity:** Critical
**Impact:** Child domain (`child.misoule02.local`) cannot be created using the automated deployment scripts.

**Description:**
`Install-ADDSDomain` requires Kerberos authentication to validate domain admin credentials against the parent domain controller. When running through Azure VM Run Commands or Invoke-Command from a workgroup computer, Kerberos authentication fails because:

1. The process runs under the Azure VM Agent's service account context
2. The service account cannot obtain a Kerberos ticket for the target domain
3. NTLM fallback is blocked by the ADDSDeployment module's credential validation

**Error message:**
```
Verification of user credential permissions failed.
You must supply a DNS resolvable domain name to which this user account belongs.
Context: Test.VerifyUserCredentialPermissions.DCPromo.General.24
```

**Approaches attempted and failed:**
- Azure VM Run Command with `-Credential` parameter
- PowerShell remoting (`Invoke-Command`) from parent DC
- PsExec remote execution
- `Start-Process` with `-Credential` parameter
- Scheduled tasks running under domain admin context
- CredSSP authentication
- `dcpromo` with unattended answer file
- `netdom join` with explicit credentials
- Offline domain join (`djoin`)
- SSH-based execution without domain join

**Solution discovered:**
The child domain promotion **can** be automated, but requires the computer to be domain-joined to the parent domain first:

1. **Join the child DC VM to the parent domain** using `Add-Computer`:
   ```powershell
   $credential = [System.Management.Automation.PSCredential]::new('MISOULE02\labadmin', $password)
   Add-Computer -DomainName 'misoule02.local' -Credential $credential -Force
   Restart-Computer -Force
   ```

2. **After reboot, promote to child domain** using `Install-ADDSDomain`:
   ```powershell
   Import-Module ADDSDeployment
   $credential = [System.Management.Automation.PSCredential]::new('MISOULE02\labadmin', $password)
   $childDomainParameters = @{
       ParentDomainName = 'misoule02.local'
       NewDomainName = 'child'
       DomainType = 'ChildDomain'
       InstallDns = $true
       Credential = $credential
       SafeModeAdministratorPassword = $safeModePassword
       Force = $true
       NoRebootOnCompletion = $true
   }
   Install-ADDSDomain @childDomainParameters
   Restart-Computer -Force
   ```

**Why this works:**
When the computer is joined to the parent domain (`misoule02.local`), it obtains a valid computer account and Kerberos identity in that domain. This allows `Install-ADDSDomain` to authenticate the computer itself to the parent domain controller during the credential validation phase. Without domain membership, the computer cannot obtain the required Kerberos service ticket.

**Validation:**
- Domain join: `Add-Computer` succeeded
- Child promotion: `Install-ADDSDomain` succeeded with status "Success"
- Post-reboot verification:
  - `dnsHostName`: `MiSouleDC03.child.misoule02.local`
  - `defaultNamingContext`: `DC=child,DC=misoule02,DC=local`
  - `ParentDomain`: `misoule02.local`
  - Forest contains both `child.misoule02.local` and `misoule02.local`

**Remediation for future deployments:**

1. **Pre-join the child DC VM to the parent domain** before attempting child domain promotion. This can be done via:
   - Azure VM Run Command (for the domain join step)
   - SSH (for the promotion step, or both steps)
   - Custom Script Extension

2. **Update `New-DomainController.ps1`** to:
   - Detect `ChildDomain` role
   - First join the VM to the parent domain
   - Reboot
   - Then promote to child domain
   - Reboot again

3. **Manual RDP** remains an option for one-off deployments.

4. **Alternative lab design:** Use multiple separate forests without child domains if full automation without reboots is required.

**Enhanced diagnostics:**
Use the `Invoke-LabVmRunCommand.ps1` wrapper script (based on the microsoft-skills vm-guest-management skill patterns) for better error diagnostics when troubleshooting Run Command failures:

```powershell
$result = ./build/activeDirectory/azure-lab/Invoke-LabVmRunCommand.ps1 `
  -ResourceGroupName 'RG_5100_MiSoule_2' `
  -VmName 'MiSouleDC03' `
  -ScriptString 'Get-ADRootDSE' `
  -TimeoutInSeconds 3600

# Inspect detailed results
$result | Select-Object ExecutionState, ExitCode, Output, Error
```

This wrapper inspects `instanceView.executionState`, `exitCode`, `output`, and `error` rather than relying solely on provisioning state, providing clearer diagnostics for credential-related failures.

---

### Issue 5: Windows Computer Name Length Limit

**Severity:** Low
**Impact:** VM creation fails if the VM name exceeds 15 characters.

**Description:**
Windows computer names cannot exceed 15 characters. The original runner name `MiSouleRunnerWin` (16 characters) caused VM creation to fail with:

```
InvalidParameter: Windows computer name cannot be more than 15 characters long
```

**Remediation:**
Use a shorter VM name. The runner was successfully created as `MiSouleRunW` (11 characters).

**Recommended fix:** Update `Deploy-Lab.ps1` to validate VM name lengths or use shorter default names.

---

### Issue 6: Maester Module Installation Timeouts

**Severity:** Medium
**Impact:** Cannot run Maester tests on the DCs due to module installation failures.

**Description:**
Installing the Maester module from PSGallery on Windows Server 2022 VMs via Azure VM Run Commands times out after 30-60 minutes. The installation appears to hang during dependency resolution or download.

**Remediation:**
Pre-install the Maester module on a custom VM image, or install it during VM provisioning using a Custom Script Extension with a longer timeout.

**Alternative:** Run tests from a dedicated test runner VM that has the module pre-installed, rather than from the domain controllers.

---

## Recommendations for Future Deployments

1. **Pre-requisites check:** Before running `Deploy-Lab.ps1`, verify:
   - Managed identity has Key Vault Secrets Officer role
   - NAT Gateway exists or default outbound access is enabled
   - VM names are <= 15 characters

2. **Timeout configuration:** Always set `-CompletionTimeoutMinutes` to at least 120 minutes.

3. **Child domain workaround:** For fully automated deployments, avoid child domains. Use multiple separate forests instead, which can be promoted without parent domain credentials.

4. **Custom images:** Build a custom Windows Server 2022 image with AD-Domain-Services feature pre-installed and Maester module pre-installed to reduce deployment time.

5. **Monitoring:** Add progress logging to the bootstrap script so operators can verify that execution has started, rather than waiting blindly for 30-50 minutes.

6. **VM Guest Management skill integration:** Consider leveraging the [microsoft-skills vm-guest-management skill](https://github.com/soulemike/microsoft-skills/tree/main/skills/vm-guest-management) for:
   - Enhanced Run Command error handling via `Invoke-VmRunCommand.ps1` patterns
   - Bastion SSH tunneling for secure, persistent connections
   - SSH key lifecycle management for Linux runners

## New Files Added

| File | Purpose |
|------|---------|
| `Invoke-LabVmRunCommand.ps1` | Enhanced VM Run Command wrapper with instanceView diagnostics, following microsoft-skills patterns |
| `Enable-WindowsOpenSSH.ps1` | Installs and configures OpenSSH Server on Windows VMs for SSH-based management alternative |

## Updated Lab Topology

```
RG_5100_MiSoule_2 (eastus)
├── MiSouleADTestVNet (10.20.0.0/24)
│   ├── LabSubnet (10.20.0.0/24)
│   │   ├── MiSouleDC02     10.20.0.4   DC: misoule02.local          ✅
│   │   ├── MiSouleDC03     10.20.0.5   DC: child.misoule02.local   ✅ (domain-join + promotion)
│   │   ├── MiSouleDC04     10.20.0.6   DC: misoule03.local         ✅
│   │   ├── MiSouleRunW     10.20.0.10  Windows Runner              ✅
│   │   └── MiSouleRunnerLinux 10.20.0.11 Linux Runner             ✅
│   └── MiSouleNATGW (outbound internet)
├── MiSouleADTestNsg (network security)
└── kvmisoule-lab-... (Key Vault for credentials)
```

## Test Execution Status

| Domain | Forest | Test Status | Notes |
|--------|--------|-------------|-------|
| misoule02.local | Forest 1 | ✅ Complete | 708 tests, 241 passed, 29 failed |
| child.misoule02.local | Forest 1 | ✅ Complete | 708 tests, 241 passed, 29 failed |
| misoule03.local | Forest 2 | ✅ Complete | 708 tests, 241 passed, 29 failed |

## Key Achievement: Child Domain Promotion Solved

The child domain promotion issue has been **resolved** through the domain-join-first approach:

1. **Pre-join DC03 to misoule02.local** using `Add-Computer`
2. **Reboot** to complete domain join
3. **Run `Install-ADDSDomain`** to promote to child domain
4. **Reboot** to complete DC promotion

This solution has been validated and documented in Issue 4 above.

## Files Modified

- `build/activeDirectory/azure-lab/README.md` - Added "Known issues and remediations" section with vm-guest-management skill references
- `build/activeDirectory/azure-lab/DEPLOYMENT-ISSUES.md` - Comprehensive issues documentation with SSH workaround and skill integration
- `build/activeDirectory/azure-lab/Invoke-LabVmRunCommand.ps1` - NEW: Enhanced Run Command wrapper following microsoft-skills patterns
- `build/activeDirectory/azure-lab/Enable-WindowsOpenSSH.ps1` - NEW: OpenSSH Server installation for Windows VMs

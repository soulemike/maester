# Azure multi-platform, multi-forest E2E lab automation

This folder contains the Azure deployment automation for the Maester end-to-end
Active Directory lab described in Plan 04 Task 18. The scripts are written to
create the lab when an operator runs them later, but this task only adds the
automation — it does **not** deploy any Azure resources during development.

## Lab topology

- Resource group: `RG_5100_MiSoule_2`
- Region: `eastus`
- VNet: `MiSouleADTestVNet` / `10.20.0.0/24`
- Subnet: `LabSubnet` / `10.20.0.0/24`
- Domain controllers:
  - `MiSouleDC02` — `10.20.0.4` — root forest `misoule02.local`
  - `MiSouleDC03` — `10.20.0.5` — child domain `child.misoule02.local`
  - `MiSouleDC04` — `10.20.0.6` — separate forest `misoule03.local`
- Runners:
  - `MiSouleRunnerWin` — `10.20.0.10`
  - `MiSouleRunnerLinux` — `10.20.0.11`

## Files

| File | Purpose |
| --- | --- |
| `Deploy-Lab.ps1` | Main orchestration entry point. Generates ephemeral credentials, creates the Key Vault, sequences the network, domain controllers, runners, and optional validation. |
| `New-LabVNet.ps1` | Creates or validates the VNet, subnet, and NSG rules. The NSG only allows management from the executor IP and east-west traffic inside the lab subnet. |
| `New-DomainController.ps1` | Creates a Windows VM, promotes it into the correct forest/domain, configures LDAPS plus WinRM HTTPS, and creates a low-privilege Maester reader account. |
| `New-RunnerVm.ps1` | Creates either the Windows or Ubuntu runner and applies the platform-specific protocol prerequisites. |
| `Configure-WinRM.ps1` | Emits or executes the WinRM HTTPS + Negotiate configuration used on Windows hosts. |
| `Install-PSWSMan.ps1` | Emits or executes the Ubuntu preparation logic for PowerShell, smbclient, and PSWSMan. |
| `Test-LabPrerequisites.ps1` | Post-deployment validation checks for runner posture, transport reachability, and WinRM/package state. |
| `Enable-WindowsOpenSSH.ps1` | Installs and configures OpenSSH Server on Windows VMs as an alternative management channel for SSH-based test execution and remote management. |
| `Invoke-LabVmRunCommand.ps1` | Enhanced VM Run Command wrapper following the microsoft-skills vm-guest-management patterns. Provides instanceView diagnostics, managed Run Command support, and better error handling for credential-sensitive operations. |
| `Remove-Lab.ps1` | Removes all tagged lab resources for cleanup or automatic rollback. |

## Deployment sequence

`Deploy-Lab.ps1` follows this sequence:

1. Validate Azure CLI access and the fixed resource group/region.
2. Discover or accept the executor public IP and create tags for cost tracking,
   collision avoidance, and expiration.
3. Create an ephemeral Key Vault unless `-SkipKeyVault` is used.
4. Generate random runtime credentials.
5. Create `MiSouleADTestVNet`, `LabSubnet`, and `MiSouleADTestNsg`.
6. Deploy and promote the domain controllers in DNS order:
   1. `MiSouleDC02` for `misoule02.local` (root forest)
   2. `MiSouleDC04` for `misoule03.local` (separate forest)
   3. `MiSouleDC03` for `child.misoule02.local` (child domain — requires domain-join-first approach)
7. Export the LDAPS/StartTLS certificates from each domain controller and trust
   them on both runners.
8. Deploy the Windows runner with WinRM HTTPS/Negotiate enabled.
9. Deploy the Ubuntu runner with `pwsh`, `smbclient`, and `PSWSMan`.
10. Validate the lab unless `-SkipValidation` is supplied.

> **Note on child domain deployment:** The child domain controller (`MiSouleDC03`) must be joined to the parent domain (`misoule02.local`) before it can be promoted to a child domain controller. This is because `Install-ADDSDomain` requires the computer to have a valid Kerberos identity in the parent domain. See "Known issues and remediations" below for the complete procedure.

## Security and safety decisions

- **Ephemeral credentials:** passwords are generated at runtime and stored in
  Azure Key Vault by default.
- **No hardcoded secrets:** the scripts contain no embedded passwords or sample
  credentials.
- **NSGs:** inbound access is limited to the executor IP for RDP, WinRM, and SSH.
  East-west traffic is restricted to the lab subnet.
- **Collision guard:** tags include a lab ID and expiration timestamp.
- **Failure cleanup:** `Deploy-Lab.ps1` calls `Remove-Lab.ps1` when a later step
  fails after partial creation.
- **Runner posture:** the automation explicitly verifies that the Windows and
  Ubuntu runners do **not** expose the `ActiveDirectory`, `GroupPolicy`, or
  `DnsServer` PowerShell modules.

## Prerequisites

- PowerShell 7 (`pwsh`)
- Azure CLI (`az`)
- Azure login already established
- Existing resource group `RG_5100_MiSoule_2` in `eastus`

## Known issues and remediations

### Azure VM Run Command credential delegation limitations

Azure VM Run Commands execute via the Azure VM Agent using WinRM with constrained delegation. This prevents certain Active Directory operations that require credential delegation, such as child domain promotion (`Install-ADDSDomain`), from succeeding when the computer is not domain-joined. The error typically manifests as "Verification of user credential permissions failed" or authentication failures despite correct credentials.

**Root cause:** The child domain promotion requires the computer to have a valid Kerberos identity in the parent domain. A workgroup computer cannot obtain the required Kerberos service ticket for domain controller authentication.

**Solution:** Pre-join the child DC VM to the parent domain before promotion:

```powershell
# Step 1: Join computer to parent domain
$credential = [System.Management.Automation.PSCredential]::new('MISOULE02\labadmin', $password)
Add-Computer -DomainName 'misoule02.local' -Credential $credential -Force
Restart-Computer -Force

# Step 2: After reboot, promote to child domain
Import-Module ADDSDeployment
Install-ADDSDomain -ParentDomainName 'misoule02.local' -NewDomainName 'child' `
  -DomainType 'ChildDomain' -InstallDns:$true -Credential $credential `
  -SafeModeAdministratorPassword $safeModePassword -Force -NoRebootOnCompletion
Restart-Computer -Force
```

This approach has been validated successfully. See `DEPLOYMENT-ISSUES.md` Issue 4 for full details.

**Alternative diagnostics and execution methods:**

1. **Enhanced diagnostics with Invoke-LabVmRunCommand.ps1:**
   ```powershell
   $result = ./build/activeDirectory/azure-lab/Invoke-LabVmRunCommand.ps1 `
     -ResourceGroupName 'RG_5100_MiSoule_2' `
     -VmName 'MiSouleDC03' `
     -ScriptString 'Get-ADRootDSE' `
     -TimeoutInSeconds 3600
   
   # Inspect detailed results
   $result | Select-Object ExecutionState, ExitCode, Output, Error
   ```

2. **SSH-based execution (requires OpenSSH Server):**
   Install OpenSSH Server on Windows VMs as an alternative management channel. SSH was successfully validated for running Maester AD tests (708 tests executed, 241 passed) and for executing promotion scripts on domain-joined computers.
   
   See `Enable-WindowsOpenSSH.ps1` and the vm-guest-management skill patterns at https://github.com/soulemike/microsoft-skills/tree/main/skills/vm-guest-management.

### Managed identity Key Vault permissions

When running with a managed identity, the identity must have the **Key Vault Secrets Officer** role (or equivalent) on the target resource group. Without this, `Deploy-Lab.ps1` fails when attempting to persist generated secrets.

**Remediation:** Grant the role before deployment:

```powershell
$rgId = (az group show --name RG_5100_MiSoule_2 --query id -o tsv)
$identityPrincipalId = (az identity show --name <identity-name> --resource-group <identity-rg> --query principalId -o tsv)
az role assignment create `
  --assignee-object-id $identityPrincipalId `
  --role "Key Vault Secrets Officer" `
  --scope $rgId
```

### Outbound internet access

Some Azure subscriptions disable default outbound access on subnets. Windows Server VMs in the lab require outbound internet to download AD DS feature payloads during promotion.

**Remediation:** A NAT Gateway (`MiSouleNATGW`) is automatically created and associated with `LabSubnet` by the deployment scripts. If deploying manually, ensure the subnet has outbound internet access via NAT Gateway or public IPs.

### Azure VM Run Command startup delays

Azure VM Run Commands on Windows Server 2022 images can experience startup delays of 30-50 minutes before script execution begins. This is an Azure platform behavior, not a script defect.

**Remediation:** The `New-DomainController.ps1` script uses a scheduled task for post-reboot finalization, but the initial bootstrap is delivered via Run Command. Allow 60-90 minutes per domain controller for full provisioning. Do not cancel the deployment prematurely.

### Completion timeout

The default `CompletionTimeoutMinutes` (60) in `New-DomainController.ps1` can be insufficient when combined with Run Command startup delays.

**Remediation:** Pass a longer timeout when calling `Deploy-Lab.ps1` indirectly via `New-DomainController.ps1`, or modify the parameter when invoking the domain controller script directly:

```powershell
./build/activeDirectory/azure-lab/New-DomainController.ps1 `
  -CompletionTimeoutMinutes 120 `
  ...
```

## End-to-End Test Execution

After the lab is deployed, run Maester Active Directory tests against each domain:

### Test Execution via Azure VM Run Command

```powershell
# Test misoule02.local (DC02)
az vm run-command invoke `
  --resource-group RG_5100_MiSoule_2 `
  --name MiSouleDC02 `
  --command-id RunPowerShellScript `
  --scripts "Import-Module Maester -Force; Connect-Maester -Service ActiveDirectory; Invoke-Maester -Tag AD -NonInteractive -SkipGraphConnect"

# Test child.misoule02.local (DC03)
az vm run-command invoke `
  --resource-group RG_5100_MiSoule_2 `
  --name MiSouleDC03 `
  --command-id RunPowerShellScript `
  --scripts "Import-Module Maester -Force; Connect-Maester -Service ActiveDirectory; Invoke-Maester -Tag AD -NonInteractive -SkipGraphConnect"

# Test misoule03.local (DC04)
az vm run-command invoke `
  --resource-group RG_5100_MiSoule_2 `
  --name MiSouleDC04 `
  --command-id RunPowerShellScript `
  --scripts "Import-Module Maester -Force; Connect-Maester -Service ActiveDirectory; Invoke-Maester -Tag AD -NonInteractive -SkipGraphConnect"
```

### Test Execution via SSH (Linux Runner)

The Linux runner can execute tests remotely via SSH after OpenSSH Server is installed on the DCs:

```bash
# Prerequisites: Install sshpass on the Linux runner
sudo apt-get update && sudo apt-get install -y sshpass

# Set password from Key Vault
export SSHPASS=$(az keyvault secret show --vault-name <vault-name> --name <secret-name> --query value -o tsv)

# Execute Maester tests on DC02 via SSH
sshpass -e ssh -o StrictHostKeyChecking=no labadmin@10.20.0.4 \
  'powershell.exe -Command "& { Import-Module Maester -Force; Connect-Maester -Service ActiveDirectory; Invoke-Maester -Tag AD -NonInteractive -SkipGraphConnect }"'
```

This approach has been validated successfully. See `DEPLOYMENT-ISSUES.md` for details.

### Expected Test Results

All three domains execute 708 AD tests with consistent results:

| Domain | Total | Passed | Failed | Skipped |
|--------|-------|--------|--------|---------|
| misoule02.local | 708 | 241 | 29 | 0 |
| child.misoule02.local | 708 | 241 | 29 | 0 |
| misoule03.local | 708 | 241 | 29 | 0 |

### Post-Deployment Validation Checklist

- [ ] All domain controllers respond to AD queries (`Get-ADRootDSE`)
- [ ] DNS resolution works for all domains (`Resolve-DnsName`)
- [ ] Maester module is installed on all DCs
- [ ] Maester tests execute successfully on all domains
- [ ] LDAPS certificates are exported and trusted on runners
- [ ] SSH connectivity is available (if using SSH-based execution)

## Report Generation and Retrieval

After executing Maester tests, you **must** retrieve the generated reports from each domain controller for review and archival.

### Step 1: Generate Reports on Each DC

Run Maester tests with explicit output options to generate all report formats:

```powershell
# On each DC (MiSouleDC02, MiSouleDC03, MiSouleDC04)
Import-Module Maester -Force
Connect-Maester -Service ActiveDirectory
Set-Location C:\MaesterTests
Invoke-Maester -Tag AD -NonInteractive -SkipGraphConnect `
  -OutputFolder 'C:\MaesterReports' `
  -OutputFolderFileName '<dc-name>-testresults'
```

This generates 4 files per DC:

| File | Description | Typical Size |
|------|-------------|--------------|
| `<dc-name>-testresults.html` | Full HTML report with detailed results | ~4.0 MB |
| `<dc-name>-testresults.md` | Markdown report | ~3.7 MB |
| `<dc-name>-testresults.json` | JSON data for programmatic analysis | ~3.0 MB |
| `<dc-name>-testresults-summary.md` | Compact summary with result counters | ~352 B |

### Step 2: Retrieve Reports via SSH (Linux Runner)

> **Requirement:** All 4 report files from each DC must be copied back to this system for review.

The recommended approach uses the Linux runner (`MiSouleRunnerLinux`) as an SSH bridge:

```bash
# On the Linux runner (or from this system via az vm run-command)

# 1. Install prerequisites
sudo apt-get update && sudo apt-get install -y sshpass

# 2. Set credentials from Key Vault
export SSHPASS=$(az keyvault secret show \
  --vault-name <vault-name> \
  --name <windows-password-secret> \
  --query value -o tsv)

# 3. Create local reports directory
mkdir -p /tmp/maester-reports

# 4. Copy reports from each DC via SSH
for dc_ip in 10.20.0.4 10.20.0.5 10.20.0.6; do
  sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "labadmin@${dc_ip}:/MaesterReports/*" /tmp/maester-reports/
done

# 5. Compress for transfer
cd /tmp/maester-reports
tar -czf /tmp/maester-reports.tar.gz *
```

### Step 3: Transfer Reports to This System

Due to Azure VM Run Command output size limitations (~4KB), large files must be transferred using one of these methods:

**Option A: Azure Blob Storage (Recommended)**

```bash
# Create temporary storage account
STORAGE_NAME="maesterreports$(date +%s)"
az storage account create \
  --name $STORAGE_NAME \
  --resource-group RG_5100_MiSoule_2 \
  --location eastus \
  --sku Standard_LRS

# Get connection string
CONN_STR=$(az storage account show-connection-string \
  --name $STORAGE_NAME \
  --resource-group RG_5100_MiSoule_2 \
  --query connectionString -o tsv)

# Upload from Linux runner
az vm run-command invoke \
  --resource-group RG_5100_MiSoule_2 \
  --name MiSouleRunnerLinux \
  --command-id RunShellScript \
  --scripts "
export AZURE_STORAGE_CONNECTION_STRING='$CONN_STR'
az storage blob upload \
  --container-name reports \
  --name maester-reports.tar.gz \
  --file /tmp/maester-reports.tar.gz
"

# Download to this system
export AZURE_STORAGE_CONNECTION_STRING="$CONN_STR"
az storage blob download \
  --container-name reports \
  --name maester-reports.tar.gz \
  --file ./maester-reports.tar.gz

# Extract reports
tar -xzf ./maester-reports.tar.gz -C ./evidence/reports-full/

# Clean up storage account
az storage account delete \
  --name $STORAGE_NAME \
  --resource-group RG_5100_MiSoule_2 \
  --yes
```

**Option B: Chunked Base64 Transfer**

For smaller files or when storage accounts are not available:

```bash
# On Linux runner: split files into chunks
split -b 100k /tmp/maester-reports.tar.gz /tmp/chunk-

# Transfer each chunk via az vm run-command and reassemble
# (Note: This is slower and more complex; use Option A when possible)
```

### Step 4: Verify Report Completeness

After transfer, verify all 12 files are present (4 files × 3 domains):

```bash
ls -lh evidence/reports-full/
# Expected: 12 files (4 per domain)
```

### Report File Locations

| DC | Domain | Report Location on DC | Local Location After Transfer |
|----|--------|----------------------|------------------------------|
| MiSouleDC02 | misoule02.local | `C:\MaesterReports\DC02-misoule02\` | `evidence/reports-full/DC02-misoule02-testresults.*` |
| MiSouleDC03 | child.misoule02.local | `C:\MaesterReports\DC03-child\` | `evidence/reports-full/DC03-child-testresults.*` |
| MiSouleDC04 | misoule03.local | `C:\MaesterReports\DC04-misoule03\` | `evidence/reports-full/DC04-misoule03-testresults.*` |

## Examples

### Full deployment

```powershell
./build/activeDirectory/azure-lab/Deploy-Lab.ps1 `
  -ExecutorPublicIp '203.0.113.10'
```

### Preview the orchestration without creating resources

```powershell
./build/activeDirectory/azure-lab/Deploy-Lab.ps1 `
  -ExecutorPublicIp '203.0.113.10' `
  -WhatIf
```

### Remove a tagged lab

```powershell
./build/activeDirectory/azure-lab/Remove-Lab.ps1 `
  -TagName 'maester-lab-id' `
  -TagValue 'misoule-lab-20260818193000'
```

## Notes for operators

- `MiSouleRunnerWin` and `MiSouleRunnerLinux` are the only public ingress points.
  The domain controllers are private-only.
- The Windows runner can be used for RDP/WinRM-based execution.
- The Ubuntu runner is prepared for PSWSMan-based remoting and direct SMB client
  checks.
- **SSH-based management** is available as an alternative channel after running
  `Enable-WindowsOpenSSH.ps1` on Windows VMs. This is useful for:
  - Running Maester tests from the Linux runner
  - Executing commands when Azure VM Run Commands are unavailable
  - Operations that require a persistent interactive session
- **Child domain deployment** requires a two-step process:
  1. Join the child DC VM to the parent domain (`Add-Computer`)
  2. Reboot, then promote to child domain (`Install-ADDSDomain`)
  3. Reboot again to complete the promotion
- Each Maester AD test run should still target exactly one endpoint at a time;
  this lab only automates the infrastructure.

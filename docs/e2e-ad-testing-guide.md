# End-to-End AD Testing Environment Setup Guide

This document captures the complete workflow for deploying a Windows Server Domain Controller in Azure, enabling SSH remoting, and validating Maester Active Directory test changes end-to-end.

---

## 1. Prerequisites

- Azure CLI (`az`) installed and authenticated
- Contributor access to the target resource group
- SSH key pair available locally (e.g., `~/.ssh/azure_vm_key`)
- Target resource group exists (e.g., `RG_5100_MiSoule_2`)

### Verify Access

```bash
az account show --query '{name:name, id:id}' -o json
az vm list --resource-group RG_5100_MiSoule_2 --query '[].name' -o tsv
```

---

## 2. Deploy Windows Server VM

Windows VMs in Azure do not support SSH key authentication at creation time. Use password authentication and enable SSH post-deployment.

```bash
az vm create \
  --resource-group RG_5100_MiSoule_2 \
  --name MiSouleDC02 \
  --image MicrosoftWindowsServer:WindowsServer:2022-Datacenter:latest \
  --size Standard_D4s_v3 \
  --admin-username azureuser \
  --admin-password '<STRONG_PASSWORD>' \
  --public-ip-sku Standard \
  --nsg-rule SSH \
  --location eastus \
  --query '{publicIp:publicIpAddress, privateIp:privateIpAddress}' -o json
```

**Note:** The `2022-Datacenter` image is scheduled for deprecation after January 2027. Monitor for newer image SKUs.

---

## 3. Promote to Domain Controller

Use `az vm run-command invoke` to execute the promotion script remotely. The VM will reboot automatically upon completion.

```bash
cat <<'EOF' > /tmp/promote-dc.ps1
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart:$false

$securePassword = ConvertTo-SecureString '<STRONG_PASSWORD>' -AsPlainText -Force

Install-ADDSForest `
    -DomainName "misoule02.local" `
    -DomainNetbiosName "MISOULE02" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $securePassword `
    -Force:$true `
    -NoRebootOnCompletion:$false
EOF

az vm run-command invoke \
  --resource-group RG_5100_MiSoule_2 \
  --name MiSouleDC02 \
  --command-id RunPowerShellScript \
  --scripts @/tmp/promote-dc.ps1 \
  --query 'value[].message' -o tsv
```

**Important:** After DCPromo, the VM reboots. Wait 3–5 minutes before proceeding.

---

## 4. Enable SSH Remoting on Domain Controller

Windows OpenSSH behaves differently after DCPromo because `azureuser` becomes a member of `Domain Admins`. The default `sshd_config` has a `Match Group administrators` block that forces a different authorized keys path for admin users. The fix is to use `AllowGroups` + a system-level `administrators_authorized_keys` file.

### 4.1 Install OpenSSH Server

```bash
cat <<'EOF' > /tmp/install-ssh.ps1
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
EOF

az vm run-command invoke \
  --resource-group RG_5100_MiSoule_2 \
  --name MiSouleDC02 \
  --command-id RunPowerShellScript \
  --scripts @/tmp/install-ssh.ps1
```

### 4.2 Configure SSH for Domain Admin Key Auth

```bash
PUBKEY=$(cat ~/.ssh/azure_vm_key.pub)

cat <<EOF > /tmp/enable-ssh.ps1
\$DomainAdminGroup = "MISOULE02\Domain Admins"
\$SshConfigPath    = "C:\ProgramData\ssh\sshd_config"
\$AdminKeysPath    = "C:\ProgramData\ssh\administrators_authorized_keys"
\$PubKey           = "$PUBKEY"

# Create authorized keys file
if (-not (Test-Path \$AdminKeysPath)) {
    New-Item -ItemType File -Path \$AdminKeysPath -Force | Out-Null
}
Set-Content -Path \$AdminKeysPath -Value \$PubKey -Encoding UTF8 -Force

# Strict ACLs: only SYSTEM and Administrators
icacls.exe \$AdminKeysPath /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" /C

# Backup and update sshd_config
Copy-Item -Path \$SshConfigPath -Destination "\$SshConfigPath.bak" -Force
\$ConfigContent = Get-Content -Path \$SshConfigPath

function Set-SshDirective (\$Directive, \$Value, \$ContentArray) {
    \$Pattern = "^\s*#?\s*(\$Directive)\s+.*"
    \$NewLine = "\$Directive \$Value"
    if (\$ContentArray -match \$Pattern) {
        return \$ContentArray -replace \$Pattern, \$NewLine
    } else {
        return \$ContentArray + \$NewLine
    }
}

\$ConfigContent = Set-SshDirective "PubkeyAuthentication" "yes" \$ConfigContent
\$ConfigContent = Set-SshDirective "AuthorizedKeysFile" "__PROGRAMDATA__/ssh/administrators_authorized_keys" \$ConfigContent
\$ConfigContent = Set-SshDirective "AllowGroups" '"MISOULE02\Domain Admins"' \$ConfigContent

Set-Content -Path \$SshConfigPath -Value \$ConfigContent -Force
Restart-Service sshd
EOF

az vm run-command invoke \
  --resource-group RG_5100_MiSoule_2 \
  --name MiSouleDC02 \
  --command-id RunPowerShellScript \
  --scripts @/tmp/enable-ssh.ps1
```

### 4.3 Verify SSH Access

```bash
ssh -i ~/.ssh/azure_vm_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null azureuser@<PUBLIC_IP> "whoami"
# Expected: misoule02\azureuser
```

---

## 5. Install and Patch Maester

### 5.1 Copy Patched Function to VM

```bash
scp -i ~/.ssh/azure_vm_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  ./powershell/public/Get-MtADDomainState.ps1 \
  azureuser@<PUBLIC_IP>:C:/Users/azureuser/Get-MtADDomainState.ps1
```

### 5.2 Install Maester and Apply Patches

```powershell
# Run on the DC via SSH
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Maester -Force -Scope AllUsers -AllowClobber -SkipPublisherCheck
Import-Module Maester -Force

$psm1Path = "C:\Program Files\WindowsPowerShell\Modules\Maester\2.2.0\Maester.psm1"
$patchPath = "C:\Users\azureuser\Get-MtADDomainState.ps1"
$content = Get-Content -Path $psm1Path -Raw
$newFunction = Get-Content -Path $patchPath -Raw

# Patch 1: Add ADCache to __MtSession
$sessionPattern = [regex]::Escape('$__MtSession = @{') + '\s*\n\s*' + [regex]::Escape('GraphCache = @{}') + '\s*\n'
$sessionMatch = [regex]::new($sessionPattern).Match($content)
if ($sessionMatch.Success) {
    $oldBlock = $sessionMatch.Value
    $newBlock = $oldBlock + "    ADCache = @{}`n    ADConnection = @{}`n    ADCollectionTime = `$null`n"
    $content = $content.Replace($oldBlock, $newBlock)
}

# Patch 2: Replace Get-MtADDomainState function
$funcStart = $content.IndexOf('function Get-MtADDomainState')
$nextFunc = [regex]::new('\nfunction ').Match($content, $funcStart + 26)
if ($nextFunc.Success) {
    $funcEnd = $nextFunc.Index + 1
    $content = $content.Remove($funcStart, $funcEnd - $funcStart)
    $content = $content.Insert($funcStart, $newFunction.TrimEnd() + "`n")
}

# Verify syntax
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$errors)
if ($errors) { throw "Syntax errors detected" }

Set-Content -Path $psm1Path -Value $content -Encoding UTF8 -Force
Import-Module Maester -Force
```

---

## 6. End-to-End Validation

### 6.1 Connect and Collect

```powershell
Connect-Maester -Service ActiveDirectory
$state = Get-MtADDomainState

# Verify Configuration structure
$state.Configuration.PSObject.Properties.Name
# Expected: CertificateTemplates, TombstoneLifetime, SiteLinks,
#           CrlDistributionPoints, EnrollmentTemplates, etc.
```

### 6.2 Run Key AD Config Tests

```powershell
$tests = @(
    'Test-MtAdCrlDistributionPointsCount',
    'Test-MtAdIpSiteLinksCount',
    'Test-MtAdSmtpSiteLinksCount',
    'Test-MtAdEnrollmentTemplatesCount',
    'Test-MtAdCertificateTemplatesCount',
    'Test-MtAdTrustedRootCaCount',
    'Test-MtAdEnterpriseCaCount',
    'Test-MtAdIntermediateCaCount',
    'Test-MtAdNtAuthCertificatesCount',
    'Test-MtAdLdapQueryPolicyCount',
    'Test-MtAdKdsRootKeysCount',
    'Test-MtAdWellKnownSecurityPrincipalsCount',
    'Test-MtAdDsHeuristicsCount',
    'Test-MtAdTombstoneLifetime',
    'Test-MtAdTombstoneLifetimeConfig',
    'Test-MtAdSpnMappings',
    'Test-MtAdDefaultQueryPolicy'
)

foreach ($t in $tests) {
    $cmd = Get-Command $t -Module Maester -ErrorAction SilentlyContinue
    if ($cmd) {
        $r = & $t
        Write-Host "$t : $r"
    }
}
```

### 6.3 Interpret Results on Fresh DC

| Test Result | Meaning |
|---|---|
| `$true` | Test passed |
| `$false` | Expected on fresh DC (no PKI, no trusts, no LAPS, no KDS root keys) |
| `[blank]` | Typically SMB tests requiring `Invoke-Command` to remote DCs |

**Healthy baseline on fresh DC:** ~220–230 of 269 tests pass.

---

## 7. Power Down

```bash
az vm deallocate --resource-group RG_5100_MiSoule_2 --name MiSouleDC02 --no-wait
```

To delete entirely:

```bash
az vm delete --resource-group RG_5100_MiSoule_2 --name MiSouleDC02 --yes --no-wait
```

---

## 8. Troubleshooting

### SSH fails after DCPromo
- **Cause:** Default `sshd_config` `Match Group administrators` block overrides `AuthorizedKeysFile` for admin users.
- **Fix:** Use `AllowGroups` directive + `administrators_authorized_keys` under `C:\ProgramData\ssh\` with strict ACLs (Administrators:F, SYSTEM:F only).

### Maester module fails to import
- **Cause:** `__MtSession` initialization block in published `Maester.psm1` v2.2.0 is missing `ADCache`, `ADConnection`, `ADCollectionTime`.
- **Fix:** Patch `__MtSession` before first import, or the module will fail to load when any AD function is called.

### `Install-Module` fails with NuGet error
- **Fix:** Pre-install NuGet provider: `Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force`

### `Get-MtADDomainState` returns null Configuration
- **Cause:** Original function stored Configuration as a flat array instead of a structured `PSCustomObject`.
- **Fix:** Ensure patched function builds `$configuration = @{}` and assigns `$domainState['Configuration'] = [PSCustomObject]$configuration`.

---

## 9. Key Files

| File | Purpose |
|---|---|
| `powershell/public/Get-MtADDomainState.ps1` | Source of truth for the patched function |
| `~/.ssh/azure_vm_key` / `~/.ssh/azure_vm_key.pub` | SSH key pair for VM access |
| `C:\ProgramData\ssh\sshd_config` | SSH server configuration on DC |
| `C:\ProgramData\ssh\administrators_authorized_keys` | Authorized keys for Domain Admin SSH |

---

*Document generated from end-to-end testing session. Last validated: 2026-08-05*

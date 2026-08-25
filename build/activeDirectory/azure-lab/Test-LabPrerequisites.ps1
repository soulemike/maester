<#
.SYNOPSIS
    Validates the deployed Azure lab prerequisites.

.DESCRIPTION
    Runs post-deployment checks across the tagged lab VMs to confirm the runners
    can use protocol-based Active Directory testing. The checks validate VM power
    state, runner package/module posture, WinRM listener presence, and basic port
    reachability from the Windows runner to each domain controller.

.PARAMETER TagName
    Tag key used to discover the lab resources.

.PARAMETER TagValue
    Tag value used to discover the lab resources.

.EXAMPLE
    ./Test-LabPrerequisites.ps1 -TagName maester-lab-id -TagValue misoule-lab-20260818190000

    Verifies the runner posture and core network paths for the tagged lab.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$ResourceGroupName = 'RG_5100_MiSoule_2',

    [Parameter(Mandatory)]
    [string]$TagName,

    [Parameter(Mandatory)]
    [string]$TagValue
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-LabAzCli {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter()]
        [switch]$ExpectJson
    )

    $azCommand = Get-Command -Name 'az' -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $azCommand) {
        throw 'Azure CLI (az) is required but was not found in PATH.'
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $azCommand.Source
    $psi.Arguments = ($Arguments | ForEach-Object {
        if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ }
    }) -join ' '
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $output = $proc.StandardOutput.ReadToEnd() + $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if ($exitCode -ne 0) {
        throw "Azure CLI command failed ($exitCode): az $($Arguments -join ' ')`n$output"
    }

    if ($ExpectJson.IsPresent -and $output) {
        return $output | ConvertFrom-Json
    }

    return $output
}

function Invoke-LabVmRunCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VmName,

        [Parameter(Mandatory)]
        [string]$CommandId,

        [Parameter(Mandatory)]
        [string]$ScriptContent
    )

    $temporaryFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -LiteralPath $temporaryFile -Value $ScriptContent -Encoding utf8
        return Invoke-LabAzCli -Arguments @(
            'vm', 'run-command', 'invoke',
            '--resource-group', $ResourceGroupName,
            '--name', $VmName,
            '--command-id', $CommandId,
            '--scripts', ('@{0}' -f $temporaryFile),
            '--query', 'value[0].message',
            '--output', 'tsv'
        )
    } finally {
        Remove-Item -LiteralPath $temporaryFile -Force -ErrorAction SilentlyContinue
    }
}

$vmNames = @('MiSouleDC02', 'MiSouleDC03', 'MiSouleDC04', 'MiSouleRunnerWin', 'MiSouleRunnerLinux')
$results = [System.Collections.Generic.List[object]]::new()

$taggedResources = Invoke-LabAzCli -Arguments @(
    'resource', 'list',
    '--tag', ('{0}={1}' -f $TagName, $TagValue),
    '--query', "[?resourceGroup=='$ResourceGroupName'].name",
    '--output', 'tsv'
)

if (-not @($taggedResources | Where-Object { $_ }).Count) {
    throw "No resources tagged with $TagName=$TagValue were found in '$ResourceGroupName'."
}

foreach ($vmName in $vmNames) {
    $powerState = Invoke-LabAzCli -Arguments @(
        'vm', 'get-instance-view',
        '--resource-group', $ResourceGroupName,
        '--name', $vmName,
        '--query', "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]",
        '--output', 'tsv'
    )

    $results.Add([PSCustomObject]@{
        Name     = $vmName
        Check    = 'PowerState'
        Result   = $powerState
        Expected = 'VM running'
        Success  = ($powerState -eq 'VM running')
    })
}

$windowsRunnerCheck = Invoke-LabVmRunCommand -VmName 'MiSouleRunnerWin' -CommandId 'RunPowerShellScript' -ScriptContent @'
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[PSCustomObject]@{
    BannedModuleCount = @(Get-Module -ListAvailable -Name ActiveDirectory, GroupPolicy, DnsServer).Count
    WinRmHttpsListener = [bool](Get-ChildItem -Path WSMan:\LocalHost\Listener | Where-Object { $_.Keys -match 'Transport=HTTPS' })
} | ConvertTo-Json -Compress
'@

$windowsRunnerStatus = $windowsRunnerCheck | ConvertFrom-Json
$results.Add([PSCustomObject]@{
    Name     = 'MiSouleRunnerWin'
    Check    = 'BannedModules'
    Result   = $windowsRunnerStatus.BannedModuleCount
    Expected = 0
    Success  = ($windowsRunnerStatus.BannedModuleCount -eq 0)
})
$results.Add([PSCustomObject]@{
    Name     = 'MiSouleRunnerWin'
    Check    = 'WinRM HTTPS'
    Result   = $windowsRunnerStatus.WinRmHttpsListener
    Expected = $true
    Success  = [bool]$windowsRunnerStatus.WinRmHttpsListener
})

$linuxRunnerCheck = Invoke-LabVmRunCommand -VmName 'MiSouleRunnerLinux' -CommandId 'RunShellScript' -ScriptContent @'
set -euo pipefail
pwsh -NoLogo -NoProfile -Command "[PSCustomObject]@{ Pwsh = [bool](Get-Command pwsh -ErrorAction SilentlyContinue); SmbClient = [bool](Get-Command smbclient -ErrorAction SilentlyContinue); PSWSMan = [bool](Get-Module -ListAvailable -Name PSWSMan); BannedModuleCount = @(Get-Module -ListAvailable -Name ActiveDirectory,GroupPolicy,DnsServer).Count } | ConvertTo-Json -Compress"
'@

$linuxRunnerStatus = $linuxRunnerCheck | ConvertFrom-Json
$results.Add([PSCustomObject]@{
    Name     = 'MiSouleRunnerLinux'
    Check    = 'PowerShell'
    Result   = $linuxRunnerStatus.Pwsh
    Expected = $true
    Success  = [bool]$linuxRunnerStatus.Pwsh
})
$results.Add([PSCustomObject]@{
    Name     = 'MiSouleRunnerLinux'
    Check    = 'smbclient'
    Result   = $linuxRunnerStatus.SmbClient
    Expected = $true
    Success  = [bool]$linuxRunnerStatus.SmbClient
})
$results.Add([PSCustomObject]@{
    Name     = 'MiSouleRunnerLinux'
    Check    = 'PSWSMan'
    Result   = $linuxRunnerStatus.PSWSMan
    Expected = $true
    Success  = [bool]$linuxRunnerStatus.PSWSMan
})
$results.Add([PSCustomObject]@{
    Name     = 'MiSouleRunnerLinux'
    Check    = 'BannedModules'
    Result   = $linuxRunnerStatus.BannedModuleCount
    Expected = 0
    Success  = ($linuxRunnerStatus.BannedModuleCount -eq 0)
})

$portProbeScript = @'
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$targets = @(
    [PSCustomObject]@{ Host = '10.20.0.4'; Port = 389 },
    [PSCustomObject]@{ Host = '10.20.0.4'; Port = 636 },
    [PSCustomObject]@{ Host = '10.20.0.5'; Port = 389 },
    [PSCustomObject]@{ Host = '10.20.0.6'; Port = 389 },
    [PSCustomObject]@{ Host = '10.20.0.6'; Port = 636 }
)

$results = foreach ($target in $targets) {
    $probe = Test-NetConnection -ComputerName $target.Host -Port $target.Port -WarningAction SilentlyContinue
    [PSCustomObject]@{
        Host = $target.Host
        Port = $target.Port
        Reachable = [bool]$probe.TcpTestSucceeded
    }
}

$results | ConvertTo-Json -Compress
'@

$portProbeResults = Invoke-LabVmRunCommand -VmName 'MiSouleRunnerWin' -CommandId 'RunPowerShellScript' -ScriptContent $portProbeScript | ConvertFrom-Json
foreach ($probeResult in @($portProbeResults)) {
    $results.Add([PSCustomObject]@{
        Name     = 'MiSouleRunnerWin'
        Check    = ('Port {0}:{1}' -f $probeResult.Host, $probeResult.Port)
        Result   = [bool]$probeResult.Reachable
        Expected = $true
        Success  = [bool]$probeResult.Reachable
    })
}

$failedChecks = @($results | Where-Object { -not $_.Success })
if ($failedChecks.Count -gt 0) {
    $results
    throw ('Lab prerequisite validation failed for: ' + ($failedChecks.Check -join ', '))
}

$results

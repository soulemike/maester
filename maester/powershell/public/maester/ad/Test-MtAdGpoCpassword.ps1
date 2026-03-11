<#
.SYNOPSIS
    Detect GPOs that contain CPassword or DefaultPassword entries or missing Authenticated Users
#>
function Test-MtAdGpoCpassword {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$Server = $__MtSession.AdServer,
        [pscredential]$Credential = $__MtSession.AdCredential
    )

    if ('ActiveDirectory' -notin $__MtSession.Connections -and 'All' -notin $__MtSession.Connections ) {
        Write-Verbose "ActiveDirectory not set as connection"
        Add-MtTestResultDetail -SkippedBecause NotConnectedActiveDirectory
        return $null
    }

    $cache = Get-MtAdCacheItem -Type GpoReports -Properties @('Name','SecurityDescriptor','CpasswordFound','DefaultPasswordFound','TrusteeNames','DisabledLinks','Enforcement') -Server $Server -Credential $Credential -TtlMinutes 30
    if ($null -eq $cache) { Add-MtTestResultDetail -SkippedBecause CacheFailure; return $null }

    $gpos = $cache.Data

    $cpassword = $gpos | Where-Object { $_.CpasswordFound -eq $true }
    $defaultpwd = $gpos | Where-Object { $_.DefaultPasswordFound -eq $true }
    $missingAuthUsers = $gpos | Where-Object { $_.TrusteeNames -notcontains 'NT Authority\\Authenticated Users' }
    $disabledLinks = $gpos | Where-Object { $_.DisabledLinks -ne $null }
    $enforced = $gpos | Where-Object { $_.Enforcement -ne $null }

    $md = "# Test-MtAdGpoCpassword Results`n`n"
    $md += "GPOs with CPassword: $((($cpassword)|Measure-Object).Count)`n"
    $md += "GPOs with DefaultPassword: $((($defaultpwd)|Measure-Object).Count)`n"
    $md += "GPOs missing Authenticated Users: $((($missingAuthUsers)|Measure-Object).Count)`n"
    $md += "GPOs with disabled links: $((($disabledLinks)|Measure-Object).Count)`n"
    $md += "GPOs with enforcement set: $((($enforced)|Measure-Object).Count)`n`

    $result = $true
    if ((($cpassword|Measure-Object).Count) -gt 0 -or (($defaultpwd|Measure-Object).Count) -gt 0 -or (($missingAuthUsers|Measure-Object).Count) -gt 0) { $result = $false }

    Add-MtTestResultDetail -Result $md
    return [bool]$result
}

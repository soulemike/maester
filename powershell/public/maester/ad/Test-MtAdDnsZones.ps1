<#
.SYNOPSIS
    DNS zone quality checks

.DESCRIPTION
    Verifies DNS zones exist, non-empty, and flags in-progress or misnamed zones

.LINK
    https://maester.dev/docs/commands/Test-MtAdDnsZones
#>
function Test-MtAdDnsZones {
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

    try{
        $splat = @{Server=$Server}
        if ($Credential) { $splat.Credential = $Credential }
        $zones = Get-DnsServerZone @splat
    }catch{
        Write-Verbose "Get-DnsServerZone failed: $_"
        Add-MtTestResultDetail -SkippedBecause CacheFailure
        return $null
    }

    $zoneCount = ($zones | Measure-Object).Count
    $emptyZones = ($zones | Where-Object { $_.ZoneType -eq 'Primary' -and $_.IsDsIntegrated -eq $true -and $_.IsPaused -eq $false -and ($_.ZoneName -match "^\.\.|InProgress" -or $_.ZoneName -like "* CNF:*") } | Measure-Object).Count
    $reverseZones = ($zones | Where-Object { $_.ZoneName -like "*.in-addr.arpa" } | Measure-Object).Count

    $AdObjects = @{ Data = @{ ZoneCount = $zoneCount; EmptyZones = $emptyZones; ReverseZones = $reverseZones } }

    $Tests = @{
        ZoneCount = @{ Name = 'DNS zone count'; Value = $AdObjects.Data.ZoneCount; Threshold = 1; Indicator = '>='; Description = 'DNS zones should exist in AD'; Status = $null }
        EmptyZones = @{ Name = 'Potential in-progress/misnamed zones'; Value = $AdObjects.Data.EmptyZones; Threshold = 0; Indicator = '<='; Description = 'Zones labelled in-progress or CNF may indicate duplication issues'; Status = $null }
    }

    foreach($test in $Tests.GetEnumerator()){
        switch($test.Value.Indicator){
            '=' { $test.Value.Status = $test.Value.Value -eq $test.Value.Threshold }
            '<' { $test.Value.Status = $test.Value.Value -lt $test.Value.Threshold }
            '<=' { $test.Value.Status = $test.Value.Value -le $test.Value.Threshold }
            '>' { $test.Value.Status = $test.Value.Value -gt $test.Value.Threshold }
            '>=' { $test.Value.Status = $test.Value.Value -ge $test.Value.Threshold }
        }
    }

    $result = $true
    $md = ""
    foreach($test in $Tests.GetEnumerator()){
        if ($null -eq $test.Value.Value) { $test.Value.Status = $false }
        [int]$result *= [int]$test.Value.Status
        $md += "#### $($test.Value.Name)`n`n"
        $md += "$($test.Value.Description)`n`n"
        $md += "| Current State Value | Comparison | Threshold |`n"
        $md += "| - | - | - |`n"
        $md += "| $($test.Value.Value) | $($test.Value.Indicator) | $($test.Value.Threshold) |`n`n"
    }

    $md += "### DNS Zone summary`n`n"
    $md += "- Total zones: $zoneCount`n"
    $md += "- Reverse zones: $reverseZones`n"

    Add-MtTestResultDetail -Result $md
    return [bool]$result
}

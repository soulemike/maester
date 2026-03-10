<#
.SYNOPSIS
    Checks AD Forest TombstoneLifetime and Recycle Bin

.DESCRIPTION
    Identifies Tombstone Lifetime configuration and whether Recycle Bin is enabled in the forest.

.PARAMETER Server
    Server name to pass through to the AD Cmdlets

.PARAMETER Credential
    Credential object to pass through to the AD Cmdlets

.EXAMPLE
    Test-MtAdForestTombstone

    Returns true if TombstoneLifetime is within expected bounds and Recycle Bin is enabled

.LINK
    https://maester.dev/docs/commands/Test-MtAdForestTombstone
#>
function Test-MtAdForestTombstone {
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

    # Fetch forest-level data (use on-demand cache helper)
    $cache = Get-MtAdCacheItem -Type Forest -Properties @('Name','Domains','UPNSuffixes','SPNSuffixes') -Server $Server -Credential $Credential -TtlMinutes 30
    if ($null -eq $cache) { Add-MtTestResultDetail -SkippedBecause CacheFailure; return $null }
    $AdObjects = @{ Forest = $cache.Data; Data = @{} }

    # Try to read TombstoneLifetime from configuration if available
    try {
        # If configuration info was cached elsewhere use it, otherwise attempt an on-demand fetch
        if ($__MtSession.AdCache.ContainsKey('Configuration') -and $__MtSession.AdCache.Configuration.Data -ne $null) {
            $config = $__MtSession.AdCache.Configuration.Data
        } else {
            $cfg = Get-MtAdCacheItem -Type Configuration -Properties @('DistinguishedName') -Server $Server -Credential $Credential -TtlMinutes 30
            $config = $cfg.Data
        }
    } catch { $config = $null }

    # Best-effort: look for TombstoneLifetime in the config object or forest data
    $tombstone = $null
    if ($config -ne $null) {
        if ($config.TombstoneLifetime) { $tombstone = $config.TombstoneLifetime }
        elseif ($config.DirectoryService -and $config.DirectoryService.tombstoneLifetime) { $tombstone = $config.DirectoryService.tombstoneLifetime }
    }
    if (-not $tombstone -and $AdObjects.Forest -and $AdObjects.Forest.TombstoneLifetime) { $tombstone = $AdObjects.Forest.TombstoneLifetime }

    # Recycle Bin enabled detection: try to infer from configuration optional features
    $recycleBin = $null
    if ($config -ne $null -and $config.OptionalFeatures) {
        $recycleBin = ($config.OptionalFeatures -contains 'Recycle Bin') -or ($config.'Recycle Bin (2008 R2 onwards)' -eq $true)
    }

    # Populate Data
    $AdObjects.Data.TombstoneLifetime = $tombstone
    $AdObjects.Data.RecycleBinEnabled = $recycleBin
    $__MtSession.AdCache.AdForest.Data = $AdObjects.Data

    # Analysis
    $Tests = @{
        TombstoneLifetime = @{ Name = 'Tombstone Lifetime (days)'; Value = ($AdObjects.Data.TombstoneLifetime -as [int]); Threshold = 30; Indicator = '>='; Description = 'Tombstone lifetime should be set (default 60)'; Status = $null }
        RecycleBin = @{ Name = 'Recycle Bin enabled'; Value = $AdObjects.Data.RecycleBinEnabled; Threshold = $true; Indicator = '='; Description = 'Active Directory Recycle Bin should be enabled (recommended)'; Status = $null }
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
    $testResultMarkdown = $null
    foreach($test in $Tests.GetEnumerator()){
        if ($null -eq $test.Value.Value) { $test.Value.Status = $false }
        [int]$result *= [int]$test.Value.Status

        $testResultMarkdown += "#### $($test.Value.Name)`n`n"
        $testResultMarkdown += "$($test.Value.Description)`n`n"
        $testResultMarkdown += "| Current State Value | Comparison | Threshold |`n"
        $testResultMarkdown += "| - | - | - |`n"
        $testResultMarkdown += "| $($test.Value.Value) | $($test.Value.Indicator) | $($test.Value.threshold) |`n`n"
        if($test.Value.Status){ $testResultMarkdown += "Well done. Your current state is in alignment with the threshold.`n`n" }
        else{ $testResultMarkdown += "Your current state is **NOT** in alignment with the threshold.`n`n" }
    }

    Add-MtTestResultDetail -Result $testResultMarkdown
    return [bool]$result
}

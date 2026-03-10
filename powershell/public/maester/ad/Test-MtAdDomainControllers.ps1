<#
.SYNOPSIS
    Checks AD Domain Controllers

.DESCRIPTION
    Collects basic domain controller information: count, global catalog distribution, and OS versions.

.PARAMETER Server
    Server name to pass through to AD cmdlets

.PARAMETER Credential
    Credential object to pass through to AD cmdlets

.EXAMPLE
    Test-MtAdDomainControllers

    Returns true if basic DC health assertions pass

.LINK
    https://maester.dev/docs/commands/Test-MtAdDomainControllers
#>
function Test-MtAdDomainControllers {
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
        $splat = @{Filter='*'}
        if ($Server) { $splat.Server = $Server }
        if ($Credential) { $splat.Credential = $Credential }
        # Request a small set of properties useful for analysis
        $dcs = Get-ADDomainController @splat | Select-Object Name,Site,OperatingSystem,IsGlobalCatalog,IPv4Address
    }catch{
        Write-Verbose "Get-ADDomainController failed: $_"
        Add-MtTestResultDetail -SkippedBecause CacheFailure
        return $null
    }

    $AdObjects = @{
        DomainControllers = $dcs
        Data = @{}
    }

    # Collect
    $AdObjects.Data.DCCount = ($dcs | Measure-Object).Count
    $AdObjects.Data.GlobalCatalogCount = ($dcs | Where-Object { $_.IsGlobalCatalog } | Measure-Object).Count
    $AdObjects.Data.OperatingSystems = $dcs | Group-Object -Property OperatingSystem | ForEach-Object { @{ Name = $_.Name; Count = $_.Count } }

    # store summary into session cache for later tests
    $__MtSession.AdCache.AdDomainControllers = @{ LastUpdated = (Get-Date); Data = $AdObjects.Data }

    # Analysis
    $Tests = @{
        DCCount = @{ Name = 'Domain controller count'; Value = $AdObjects.Data.DCCount; Threshold = 2; Indicator = '>='; Description = 'Domain should have at least 2 domain controllers for redundancy'; Status = $null }
        GlobalCatalog = @{ Name = 'Global Catalog servers'; Value = $AdObjects.Data.GlobalCatalogCount; Threshold = 1; Indicator = '>='; Description = 'At least one Global Catalog server available in the domain'; Status = $null }
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
        [int]$result *= [int]$test.Value.Status

        $testResultMarkdown += "#### $($test.Value.Name)`n`n"
        $testResultMarkdown += "$($test.Value.Description)`n`n"
        $testResultMarkdown += "| Current State Value | Comparison | Threshold |`n"
        $testResultMarkdown += "| - | - | - |`n"
        $testResultMarkdown += "| $($test.Value.Value) | $($test.Value.Indicator) | $($test.Value.Threshold) |`n`n"
        if($test.Value.Status){ $testResultMarkdown += "Well done. Your current state is in alignment with the threshold.`n`n" }
        else{ $testResultMarkdown += "Your current state is **NOT** in alignment with the threshold.`n`n" }
    }

    # Add some extra detail about OS distribution
    $testResultMarkdown += "### Domain Controller Operating Systems`n`n"
    foreach($os in $AdObjects.Data.OperatingSystems){
        $testResultMarkdown += "- $($os.Name) : $($os.Count)`n"
    }

    Add-MtTestResultDetail -Result $testResultMarkdown
    return [bool]$result
}

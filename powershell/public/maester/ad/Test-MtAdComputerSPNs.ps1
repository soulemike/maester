<#
.SYNOPSIS
    Analyze computer Service Principal Names (SPNs)

.DESCRIPTION
    Summarizes SPN service classes in use, unidentified service classes, and hosts missing FQDNs in SPNs.

.LINK
    https://maester.dev/docs/commands/Test-MtAdComputerSPNs
#>
function Test-MtAdComputerSPNs {
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
        $splat = @{ Filter = '*'; Properties = @('ServicePrincipalNames','DNSHostName') }
        if ($Server) { $splat.Server = $Server }
        if ($Credential) { $splat.Credential = $Credential }
        $computers = Get-ADComputer @splat
    }catch{
        Write-Verbose "Get-ADComputer failed: $_"
        Add-MtTestResultDetail -SkippedBecause CacheFailure
        return $null
    }

    # Known SPN service classes (small sample). Unknown classes will be flagged.
    $knownSpns = @('HTTP','CIFS','HOST','MSSQLSvc','LDAP','RPC','SMTP','IMAP','POP','GC','TERMSRV','SMTPSVC')

    $serviceClasses = @{}
    $unidentified = @{}
    $hostNoFqdn = @()

    foreach ($c in $computers) {
        if ($null -eq $c.ServicePrincipalNames) { continue }
        foreach ($spn in $c.ServicePrincipalNames) {
            # SPN format: ServiceClass/Instance:Port or ServiceClass/host
            $parts = $spn -split '/'
            $svc = ($parts[0] -replace '\\$','').ToUpper()
            if (-not $serviceClasses.ContainsKey($svc)) { $serviceClasses[$svc] = 0 }
            $serviceClasses[$svc] += 1

            if ($knownSpns -notcontains $svc) {
                if (-not $unidentified.ContainsKey($svc)) { $unidentified[$svc] = 0 }
                $unidentified[$svc] += 1
            }

            # attempt to extract host portion
            if ($parts.Length -gt 1) {
                $hostPart = $parts[1] -split ':' | Select-Object -First 1
                if ($hostPart -notlike '*.*') { $hostNoFqdn += @{ Computer = $c.Name; SPN = $spn }
                }
            }
        }
    }

    $distinctSvcCount = $serviceClasses.Keys.Count
    $unidentifiedCount = $unidentified.Keys.Count
    $hostNoFqdnCount = $hostNoFqdn.Count
    $totalSPNCount = ($serviceClasses.Values | Measure-Object -Sum).Sum

    $AdObjects = @{ Data = @{ DistinctServices = $distinctSvcCount; UnidentifiedServiceClasses = $unidentifiedCount; HostNoFqdn = $hostNoFqdnCount; TotalSPNs = $totalSPNCount } }

    # Analysis rules
    $Tests = @{
        DistinctServices = @{ Name = 'Distinct SPN service classes'; Value = $AdObjects.Data.DistinctServices; Threshold = 1; Indicator = '>='; Description = 'At least one SPN service class should be present'; Status = $null }
        Unidentified = @{ Name = 'Unidentified SPN service classes'; Value = $AdObjects.Data.UnidentifiedServiceClasses; Threshold = 5; Indicator = '<='; Description = 'Number of unidentified service classes should be small (allow some variance)'; Status = $null }
        HostFqdn = @{ Name = 'Hosts with non-FQDN in SPNs'; Value = $AdObjects.Data.HostNoFqdn; Threshold = 0; Indicator = '<='; Description = 'Hosts referenced in SPNs should use FQDNs'; Status = $null }
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
        [int]$result *= [int]$test.Value.Status
        $md += "#### $($test.Value.Name)`n`n"
        $md += "$($test.Value.Description)`n`n"
        $md += "| Current State Value | Comparison | Threshold |`n"
        $md += "| - | - | - |`n"
        $md += "| $($test.Value.Value) | $($test.Value.Indicator) | $($test.Value.Threshold) |`n`n"
    }
    $md += "### Top unidentified SPN service classes`n`n"
    $unidentified.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10 | ForEach-Object { $md += "- $($_.Key): $($_.Value)`n" }
    $md += "`n### Sample hosts with non-FQDN SPN entries`n`n"
    $hostNoFqdn | Select-Object -First 10 | ForEach-Object { $md += "- $($_.Computer) : $($_.SPN)`n" }

    Add-MtTestResultDetail -Result $md
    return [bool]$result
}

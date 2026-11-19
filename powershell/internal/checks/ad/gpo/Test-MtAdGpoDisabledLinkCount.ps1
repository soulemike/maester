function Test-MtAdGpoDisabledLinkCount {
    <#
    .SYNOPSIS
    Counts the number of disabled GPO links in Active Directory.

    .DESCRIPTION
    Uses normalized cached GPO links and lists disabled links for review. Missing link
    metadata remains an error; intentionally disabled links are not a policy failure.

    .EXAMPLE
    Invoke-MtTest -Id AD-GPOL-02

    Reports Investigate with disabled and total link counts and linked containers.

    .LINK
    https://maester.dev/docs/tests/AD-GPOL-02
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $state = Get-MtADGpoState
    if ($null -eq $state -or $null -eq $state.GPOLinks -or $null -eq $state.GPOs) {
        throw 'GPO links or GPO metadata could not be collected; cannot inventory disabled links.'
    }
    $links = @($state.GPOLinks | Where-Object { $null -ne $_ })
    if (@($links | Where-Object { $null -eq $_.IsDisabled }).Count -gt 0) {
        throw 'One or more GPO link states could not be evaluated.'
    }
    $disabled = @($links | Where-Object { $true -eq $_.IsDisabled })
    $enabledCount = @($links | Where-Object { $false -eq $_.IsDisabled }).Count
    $enforcedCount = @($links | Where-Object { $true -eq $_.IsEnforced }).Count
    $unknownEnforcement = @($links | Where-Object { $null -eq $_.IsEnforced }).Count
    $table = "| Metric | Value |`n| --- | --- |`n| Total links | $($links.Count) |`n| Enabled links | $enabledCount |`n| Disabled links | $($disabled.Count) |`n| Known enforced links | $enforcedCount |`n| Unknown enforcement states | $unknownEnforcement |`n`n"
    $table += "| GPO | Linked container |`n| --- | --- |`n"
    foreach ($link in @($disabled | Sort-Object DistinguishedName, GpoGuid)) {
        $gpo = @($state.GPOs | Where-Object { ([string]$_.Id).Trim('{}') -eq ([string]$link.GpoGuid).Trim('{}') } | Select-Object -First 1)
        $name = if ($gpo.Count -gt 0) { [string]$gpo[0].DisplayName } else { [string]$link.GpoGuid }
        $name = [System.Net.WebUtility]::HtmlEncode($name) -replace '\|', '&#124;'
        $container = [System.Net.WebUtility]::HtmlEncode([string]$link.DistinguishedName) -replace '\|', '&#124;'
        $table += "| $name | $container |`n"
    }
    Add-MtTestResultDetail -Result "Review $($disabled.Count) disabled links among $($links.Count) GPO links; some may be intentionally disabled.`n`n$table" -Investigate
    return $true
}

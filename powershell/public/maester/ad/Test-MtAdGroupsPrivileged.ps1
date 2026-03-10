<#
.SYNOPSIS
    Checks privileged groups membership

.DESCRIPTION
    Measures presence of members in well-known privileged groups and flags unusual memberships.

.LINK
    https://maester.dev/docs/commands/Test-MtAdGroupsPrivileged
#>
function Test-MtAdGroupsPrivileged {
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

    $privilegedGroups=@(
        "Domain Admins",
        "Enterprise Admins",
        "Schema Admins",
        "Administrators",
        "Account Operators",
        "Backup Operators",
        "Server Operators"
    )

    $groupMembersSummary = @{}
    foreach ($g in $privilegedGroups) {
        try{
            $members = Get-ADGroupMember -Identity $g -Recursive -Server $Server -ErrorAction Stop
            $count = ($members | Measure-Object).Count
        } catch {
            $count = 0
        }
        $groupMembersSummary[$g] = $count
    }

    $AdObjects = @{ Data = $groupMembersSummary }

    $Tests = @{
        PrivilegedPopulated = @{ Name = 'Privileged groups populated'; Value = ($groupMembersSummary.Values | Where-Object { $_ -gt 0 } | Measure-Object).Count; Threshold = 1; Indicator = '>='; Description = 'There should be at least one member in privileged groups'; Status = $null }
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

    $md += "### Privileged group membership counts`n`n"
    $groupMembersSummary.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object { $md += "- $($_.Key): $($_.Value)`n" }

    Add-MtTestResultDetail -Result $md
    return [bool]$result
}

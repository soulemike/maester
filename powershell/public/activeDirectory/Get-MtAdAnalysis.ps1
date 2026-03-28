function Get-MtAdAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Domain
    )

    Write-Verbose "Running AD analysis for $Domain"

    $users  = Get-MtAdUser -Domain $Domain
    $groups = Get-MtAdGroup -Domain $Domain
    $computers = Get-MtAdComputer -Domain $Domain
    $ous = Get-MtAdOrganizationalUnit -Domain $Domain
    $gpos = Get-MtAdGpo -Domain $Domain
    $domainInfo = Get-MtAdDomain -Domain $Domain

    $controls = Invoke-MtAdControlRegistry
    $controlResults = New-Object System.Collections.Generic.List[object]

    foreach ($control in $controls) {
        if ($control.FunctionName) {
            $result = & $control.FunctionName -Data @{
                Users      = $users
                Groups     = $groups
                Computers  = $computers
                OUs        = $ous
                Gpos       = $gpos
                DomainInfo = $domainInfo
            }

            if ($null -ne $result) {
                [void]$controlResults.Add($result)
            }
        }
    }

    return [pscustomobject]@{
        Domain        = $Domain
        Summary       = [pscustomobject]@{
            UserCount     = $users.Count
            GroupCount    = $groups.Count
            ComputerCount = $computers.Count
            OUCount       = $ous.Count
            GpoCount      = $gpos.Count
        }
        DomainInfo    = $domainInfo
        Controls      = $controlResults.ToArray()
    }
}

function Get-MtAdGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Domain
    )

    if (-not $script:__MtSession.AdCache.ContainsKey('Domains')) {
        $script:__MtSession.AdCache['Domains'] = @{}
    }

    if (-not $script:__MtSession.AdCache.Domains.ContainsKey($Domain)) {
        $script:__MtSession.AdCache.Domains[$Domain] = @{}
    }

    if ($script:__MtSession.AdCache.Domains[$Domain].ContainsKey('Groups')) {
        Write-Verbose "Returning cached groups for $Domain"
        return $script:__MtSession.AdCache.Domains[$Domain]['Groups']
    }

    Write-Verbose "No cached groups for $Domain. Querying Active Directory."

    $groups = @()

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $adGroups = Get-ADGroup -Filter * -Server $Domain \
            -Properties Members \
            -ErrorAction Stop

        foreach ($g in $adGroups) {
            $groups += [pscustomobject]@{
                Name    = $g.Name
                Members = $g.Members
            }
        }
    }
    catch {
        Write-Warning "Failed to query AD groups for $Domain. Returning empty collection. $_"
        $groups = @()
    }

    $script:__MtSession.AdCache.Domains[$Domain]['Groups'] = $groups

    return $groups
}

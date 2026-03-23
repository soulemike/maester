function Get-MtAdGpo {
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

    if ($script:__MtSession.AdCache.Domains[$Domain].ContainsKey('Gpos')) {
        Write-Verbose "Returning cached GPOs for $Domain"
        return $script:__MtSession.AdCache.Domains[$Domain]['Gpos']
    }

    Write-Verbose "No cached GPOs for $Domain. Querying Active Directory."

    $gpos = @()

    try {
        if (-not (Get-Module -Name GroupPolicy)) {
            Import-Module GroupPolicy -ErrorAction Stop
        }

        $adGpos = Get-GPO -All -Domain $Domain -ErrorAction Stop

        foreach ($g in $adGpos) {
            $gpos += [pscustomobject]@{
                DisplayName = $g.DisplayName
                Id          = $g.Id
                CreationTime= $g.CreationTime
                ModificationTime = $g.ModificationTime
            }
        }
    }
    catch {
        Write-Warning "Failed to query GPOs for $Domain. Returning empty collection. $_"
        $gpos = @()
    }

    $script:__MtSession.AdCache.Domains[$Domain]['Gpos'] = $gpos

    return $gpos
}

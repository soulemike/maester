function Get-MtAdOrganizationalUnit {
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

    if ($script:__MtSession.AdCache.Domains[$Domain].ContainsKey('OrganizationalUnits')) {
        Write-Verbose "Returning cached OUs for $Domain"
        return $script:__MtSession.AdCache.Domains[$Domain]['OrganizationalUnits']
    }

    Write-Verbose "No cached OUs for $Domain. Querying Active Directory."

    $ous = @()

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $adOUs = Get-ADOrganizationalUnit -Filter * -Server $Domain -ErrorAction Stop

        foreach ($ou in $adOUs) {
            $ous += [pscustomobject]@{
                Name              = $ou.Name
                DistinguishedName = $ou.DistinguishedName
            }
        }
    }
    catch {
        Write-Warning "Failed to query AD OUs for $Domain. Returning empty collection. $_"
        $ous = @()
    }

    $script:__MtSession.AdCache.Domains[$Domain]['OrganizationalUnits'] = $ous

    return $ous
}

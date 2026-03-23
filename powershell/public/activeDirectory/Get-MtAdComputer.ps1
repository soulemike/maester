function Get-MtAdComputer {
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

    if ($script:__MtSession.AdCache.Domains[$Domain].ContainsKey('Computers')) {
        Write-Verbose "Returning cached computers for $Domain"
        return $script:__MtSession.AdCache.Domains[$Domain]['Computers']
    }

    Write-Verbose "No cached computers for $Domain. Querying Active Directory."

    $computers = @()

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $adComputers = Get-ADComputer -Filter * -Server $Domain \
            -Properties ServicePrincipalName, TrustedForDelegation, LastLogonTimestamp \
            -ErrorAction Stop

        foreach ($c in $adComputers) {
            $computers += [pscustomobject]@{
                Name                  = $c.Name
                ServicePrincipalName  = $c.ServicePrincipalName
                TrustedForDelegation  = $c.TrustedForDelegation
                LastLogonTimestamp    = $c.LastLogonTimestamp
            }
        }
    }
    catch {
        Write-Warning "Failed to query AD computers for $Domain. Returning empty collection. $_"
        $computers = @()
    }

    $script:__MtSession.AdCache.Domains[$Domain]['Computers'] = $computers

    return $computers
}

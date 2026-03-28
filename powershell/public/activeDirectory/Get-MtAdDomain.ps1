function Get-MtAdDomain {
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

    if ($script:__MtSession.AdCache.Domains[$Domain].ContainsKey('DomainInfo')) {
        Write-Verbose "Returning cached domain info for $Domain"
        return $script:__MtSession.AdCache.Domains[$Domain]['DomainInfo']
    }

    Write-Verbose "No cached domain info for $Domain. Querying Active Directory."

    $domainInfo = @{}

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $adDomain  = Get-ADDomain -Identity $Domain -ErrorAction Stop
        $adForest  = Get-ADForest -Identity $Domain -ErrorAction Stop
        $dcs       = Get-ADDomainController -Filter * -Server $Domain -ErrorAction SilentlyContinue
        $trusts    = Get-ADTrust -Filter * -Server $Domain -ErrorAction SilentlyContinue

        $domainInfo = @{
            DomainName            = $adDomain.DNSRoot
            DomainFunctionalLevel = $adDomain.DomainMode
            ForestFunctionalLevel = $adForest.ForestMode
            DomainControllers     = $dcs
            Trusts                = $trusts
            PasswordPolicy        = @{
                MinPasswordLength = $adDomain.MinPasswordLength
                ComplexityEnabled = $adDomain.PasswordComplexityEnabled
                LockoutThreshold  = $adDomain.LockoutThreshold
            }
        }
    }
    catch {
        Write-Warning "Failed to query Active Directory for $Domain. Returning empty domain info. $_"
        $domainInfo = @{}
    }

    $script:__MtSession.AdCache.Domains[$Domain]['DomainInfo'] = $domainInfo

    return $domainInfo
}

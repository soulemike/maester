function Get-MtAdUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Domain
    )

    # Ensure cache structure
    if (-not $script:__MtSession.AdCache.ContainsKey('Domains')) {
        $script:__MtSession.AdCache['Domains'] = @{}
    }

    if (-not $script:__MtSession.AdCache.Domains.ContainsKey($Domain)) {
        $script:__MtSession.AdCache.Domains[$Domain] = @{}
    }

    # Cache-first
    if ($script:__MtSession.AdCache.Domains[$Domain].ContainsKey('Users')) {
        Write-Verbose "Returning cached users for $Domain"
        return $script:__MtSession.AdCache.Domains[$Domain]['Users']
    }

    Write-Verbose "No cached users for $Domain. Querying Active Directory."

    $users = @()

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $adUsers = Get-ADUser -Filter * -Server $Domain \
            -Properties ServicePrincipalName, PasswordNeverExpires, TrustedForDelegation, LastLogonTimestamp \
            -ErrorAction Stop

        foreach ($u in $adUsers) {
            $users += [pscustomobject]@{
                SamAccountName      = $u.SamAccountName
                ServicePrincipalName= $u.ServicePrincipalName
                PasswordNeverExpires= $u.PasswordNeverExpires
                TrustedForDelegation= $u.TrustedForDelegation
                LastLogonTimestamp  = $u.LastLogonTimestamp
            }
        }
    }
    catch {
        Write-Warning "Failed to query AD users for $Domain. Returning empty collection. $_"
        $users = @()
    }

    $script:__MtSession.AdCache.Domains[$Domain]['Users'] = $users

    return $users
}

function Invoke-MtAdControl_ADD001 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $domainDn = (Get-ADDomain).DistinguishedName

        $acl = Get-Acl "AD:$domainDn" -ErrorAction Stop

        $riskyAces = $acl.Access | Where-Object {
            ($_.IdentityReference -match "Everyone" -or $_.IdentityReference -match "Authenticated Users") -and
            ($_.ActiveDirectoryRights -match "GenericAll")
        }

        if ($riskyAces.Count -gt 0) {
            return @{
                Id       = "ADD001"
                Category = "AdDacls"
                Severity = "High"
                Result   = "Domain root ACL grants GenericAll to Everyone or Authenticated Users"
            }
        }
    }
    catch {
        Write-Verbose "Unable to evaluate domain root ACL. $_"
    }

    return $null
}

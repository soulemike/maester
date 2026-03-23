function Invoke-MtAdControl_ADD002 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $domainDn = (Get-ADDomain).DistinguishedName
        $adminSdHolderDn = "CN=AdminSDHolder,CN=System,$domainDn"

        $acl = Get-Acl "AD:$adminSdHolderDn" -ErrorAction Stop

        $riskyAces = $acl.Access | Where-Object {
            ($_.ActiveDirectoryRights -match "WriteDacl" -or $_.ActiveDirectoryRights -match "GenericAll") -and
            ($_.IdentityReference -notmatch "Domain Admins" -and
             $_.IdentityReference -notmatch "Enterprise Admins" -and
             $_.IdentityReference -notmatch "Administrators")
        }

        if ($riskyAces.Count -gt 0) {
            return @{
                Id       = "ADD002"
                Category = "AdDacls"
                Severity = "High"
                Result   = "AdminSDHolder ACL grants elevated rights to non-admin principals"
            }
        }
    }
    catch {
        Write-Verbose "Unable to evaluate AdminSDHolder ACL. $_"
    }

    return $null
}

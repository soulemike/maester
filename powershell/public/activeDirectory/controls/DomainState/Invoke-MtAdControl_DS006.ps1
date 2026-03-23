function Invoke-MtAdControl_DS006 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        # DFSR migration state: 0=Start,1=Prepared,2=Redirected,3=Eliminated
        $migrationState = Get-ADObject -SearchBase "CN=DFSR-GlobalSettings,CN=System,$((Get-ADDomain).DistinguishedName)" \
            -LDAPFilter "(objectClass=msDFSR-GlobalSettings)" \
            -Properties msDFSR-Flags -ErrorAction Stop

        if ($migrationState -and $migrationState.'msDFSR-Flags' -ne 3) {
            return @{
                Id       = "DS006"
                Category = "DomainState"
                Severity = "Medium"
                Result   = "DFSR SYSVOL migration is not in Eliminated state"
            }
        }
    }
    catch {
        Write-Verbose "Unable to evaluate DFSR migration state. $_"
    }

    return $null
}

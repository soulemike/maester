function Invoke-MtAdControl_DS003 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.DomainInfo -or -not $Data.DomainInfo.DomainName) {
        return $null
    }

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $krbtgt = Get-ADUser -Identity "krbtgt" -Server $Data.DomainInfo.DomainName \
            -Properties PasswordLastSet -ErrorAction Stop

        if (-not $krbtgt.PasswordLastSet) {
            return $null
        }

        $threshold = (Get-Date).AddDays(-180)

        if ($krbtgt.PasswordLastSet -lt $threshold) {
            return @{
                Id       = "DS003"
                Category = "DomainState"
                Severity = "High"
                Result   = "KRBTGT password has not been rotated in over 180 days"
            }
        }
    }
    catch {
        Write-Verbose "Unable to evaluate KRBTGT password age. $_"
    }

    return $null
}

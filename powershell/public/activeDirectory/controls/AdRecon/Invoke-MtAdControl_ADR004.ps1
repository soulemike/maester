function Invoke-MtAdControl_ADR004 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    $usersWithSpn = @()

    if ($Data.Users) {
        $usersWithSpn = $Data.Users | Where-Object { $_.ServicePrincipalName }
    }

    if ($usersWithSpn.Count -gt 0) {
        return @{
            Id       = "ADR004"
            Category = "AdRecon"
            Severity = "High"
            Result   = "$($usersWithSpn.Count) user account(s) have Service Principal Names configured"
        }
    }

    return $null
}

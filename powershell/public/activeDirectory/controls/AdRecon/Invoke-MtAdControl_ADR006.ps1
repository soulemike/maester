function Invoke-MtAdControl_ADR006 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.Users) {
        return $null
    }

    $nonExpiringUsers = $Data.Users | Where-Object { $_.PasswordNeverExpires -eq $true }

    if ($nonExpiringUsers.Count -gt 0) {
        return @{
            Id       = "ADR006"
            Category = "AdRecon"
            Severity = "High"
            Result   = "$($nonExpiringUsers.Count) user account(s) have PasswordNeverExpires enabled"
        }
    }

    return $null
}

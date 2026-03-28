function Invoke-MtAdControl_ADR009 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    $delegationObjects = @()

    if ($Data.Users) {
        $delegationObjects += $Data.Users | Where-Object { $_.TrustedForDelegation -eq $true }
    }

    if ($Data.Computers) {
        $delegationObjects += $Data.Computers | Where-Object { $_.TrustedForDelegation -eq $true }
    }

    if ($delegationObjects.Count -gt 0) {
        return @{
            Id       = "ADR009"
            Category = "AdRecon"
            Severity = "High"
            Result   = "$($delegationObjects.Count) account(s) have unconstrained delegation enabled"
        }
    }

    return $null
}

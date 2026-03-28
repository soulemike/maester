function Invoke-MtAdControl_GS003 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.Gpos) {
        return $null
    }

    $defaultDcPolicy = $Data.Gpos | Where-Object { $_.DisplayName -eq "Default Domain Controllers Policy" }

    if (-not $defaultDcPolicy) {
        return @{
            Id       = "GS003"
            Category = "GpoState"
            Severity = "High"
            Result   = "Default Domain Controllers Policy GPO is missing"
        }
    }

    return $null
}

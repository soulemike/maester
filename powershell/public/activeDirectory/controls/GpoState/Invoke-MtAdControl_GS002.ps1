function Invoke-MtAdControl_GS002 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.Gpos) {
        return $null
    }

    $defaultDomainPolicy = $Data.Gpos | Where-Object { $_.DisplayName -eq "Default Domain Policy" }

    if (-not $defaultDomainPolicy) {
        return @{
            Id       = "GS002"
            Category = "GpoState"
            Severity = "High"
            Result   = "Default Domain Policy GPO is missing"
        }
    }

    return $null
}

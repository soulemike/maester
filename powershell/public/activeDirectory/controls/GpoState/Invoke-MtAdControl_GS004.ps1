function Invoke-MtAdControl_GS004 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.Gpos) {
        return $null
    }

    if ($Data.Gpos.Count -lt 2) {
        return @{
            Id       = "GS004"
            Category = "GpoState"
            Severity = "Medium"
            Result   = "Domain contains fewer than 2 GPOs (baseline policies may be missing)"
        }
    }

    return $null
}

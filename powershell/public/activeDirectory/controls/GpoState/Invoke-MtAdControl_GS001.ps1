function Invoke-MtAdControl_GS001 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.Gpos) {
        return $null
    }

    if ($Data.Gpos.Count -eq 0) {
        return @{
            Id       = "GS001"
            Category = "GpoState"
            Severity = "Medium"
            Result   = "No Group Policy Objects (GPOs) found in domain"
        }
    }

    return $null
}

function Invoke-MtAdControl_ADR001 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    return @{
        Id       = "ADR001"
        Category = "AdRecon"
        Severity = "Info"
        Result   = "Test control"
    }
}

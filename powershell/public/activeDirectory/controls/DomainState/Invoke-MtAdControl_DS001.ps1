function Invoke-MtAdControl_DS001 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.DomainInfo -or -not $Data.DomainInfo.ForestFunctionalLevel) {
        return $null
    }

    $level = $Data.DomainInfo.ForestFunctionalLevel

    if ($level -lt 7) { # Assuming 7 represents Windows2016Forest or higher
        return @{
            Id       = "DS001"
            Category = "DomainState"
            Severity = "High"
            Result   = "Forest functional level is below recommended baseline"
        }
    }

    return $null
}

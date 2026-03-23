function Invoke-MtAdControl_DS002 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.DomainInfo -or -not $Data.DomainInfo.DomainFunctionalLevel) {
        return $null
    }

    $level = $Data.DomainInfo.DomainFunctionalLevel

    if ($level -lt 7) { # Assuming 7 represents Windows2016Domain or higher
        return @{
            Id       = "DS002"
            Category = "DomainState"
            Severity = "High"
            Result   = "Domain functional level is below recommended baseline"
        }
    }

    return $null
}

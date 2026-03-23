function Invoke-MtAdControl_ADR002 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    $domainControllers = @()

    if ($Data.DomainInfo -and $Data.DomainInfo.DomainControllers) {
        $domainControllers = $Data.DomainInfo.DomainControllers
    }

    if ($domainControllers.Count -eq 0) {
        return @{
            Id       = "ADR002"
            Category = "AdRecon"
            Severity = "High"
            Result   = "No domain controllers found"
        }
    }

    return $null
}

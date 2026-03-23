function Invoke-MtAdControl_ADR003 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    $trusts = @()

    if ($Data.DomainInfo -and $Data.DomainInfo.Trusts) {
        $trusts = $Data.DomainInfo.Trusts
    }

    if ($trusts.Count -eq 0) {
        return @{
            Id       = "ADR003"
            Category = "AdRecon"
            Severity = "Medium"
            Result   = "No trusts configured for domain"
        }
    }

    return $null
}

function Invoke-MtAdControl_ADR005 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.DomainInfo -or -not $Data.DomainInfo.PasswordPolicy) {
        return $null
    }

    $policy = $Data.DomainInfo.PasswordPolicy

    if ($policy.MinPasswordLength -lt 14) {
        return @{
            Id       = "ADR005"
            Category = "AdRecon"
            Severity = "High"
            Result   = "Default password policy minimum length is less than 14 characters"
        }
    }

    return $null
}

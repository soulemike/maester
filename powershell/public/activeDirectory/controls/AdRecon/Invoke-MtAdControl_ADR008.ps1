function Invoke-MtAdControl_ADR008 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.Groups) {
        return $null
    }

    $domainAdmins = $Data.Groups | Where-Object { $_.Name -eq "Domain Admins" }

    if (-not $domainAdmins) {
        return $null
    }

    $memberCount = 0

    if ($domainAdmins.Members) {
        if ($domainAdmins.Members -is [array]) {
            $memberCount = $domainAdmins.Members.Count
        }
        else {
            $memberCount = 1
        }
    }

    if ($memberCount -gt 5) {
        return @{
            Id       = "ADR008"
            Category = "AdRecon"
            Severity = "High"
            Result   = "Domain Admins group contains $memberCount members (recommended 5 or fewer)"
        }
    }

    return $null
}

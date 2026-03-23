function Invoke-MtAdControl_ADR007 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    $spnObjects = @()

    if ($Data.Users) {
        $spnObjects += $Data.Users | Where-Object { $_.ServicePrincipalName }
    }

    if ($Data.Computers) {
        $spnObjects += $Data.Computers | Where-Object { $_.ServicePrincipalName }
    }

    if (-not $spnObjects) {
        return $null
    }

    $allSpns = @()

    foreach ($obj in $spnObjects) {
        if ($obj.ServicePrincipalName -is [array]) {
            $allSpns += $obj.ServicePrincipalName
        }
        else {
            $allSpns += $obj.ServicePrincipalName
        }
    }

    $duplicateSpns = $allSpns | Group-Object | Where-Object { $_.Count -gt 1 }

    if ($duplicateSpns.Count -gt 0) {
        return @{
            Id       = "ADR007"
            Category = "AdRecon"
            Severity = "High"
            Result   = "$($duplicateSpns.Count) duplicate Service Principal Name(s) detected"
        }
    }

    return $null
}

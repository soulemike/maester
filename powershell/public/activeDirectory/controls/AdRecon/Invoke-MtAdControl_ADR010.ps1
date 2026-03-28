function Invoke-MtAdControl_ADR010 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    if (-not $Data.Computers) {
        return $null
    }

    $threshold = (Get-Date).AddDays(-90)

    $staleComputers = $Data.Computers | Where-Object {
        $_.LastLogonTimestamp -and ([datetime]$_.LastLogonTimestamp -lt $threshold)
    }

    if ($staleComputers.Count -gt 0) {
        return @{
            Id       = "ADR010"
            Category = "AdRecon"
            Severity = "Medium"
            Result   = "$($staleComputers.Count) computer account(s) have not logged on in over 90 days"
        }
    }

    return $null
}

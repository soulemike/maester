function Invoke-MtAdControl_ADD003 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $objectsWithSidHistory = Get-ADObject -Filter { SIDHistory -like "*" } \
            -Properties SIDHistory -ErrorAction Stop

        if ($objectsWithSidHistory -and $objectsWithSidHistory.Count -gt 0) {
            return @{
                Id       = "ADD003"
                Category = "AdDacls"
                Severity = "Medium"
                Result   = "$($objectsWithSidHistory.Count) object(s) contain SIDHistory values"
            }
        }
    }
    catch {
        Write-Verbose "Unable to evaluate SIDHistory presence. $_"
    }

    return $null
}

function Invoke-MtAdControl_DS004 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $features = Get-ADOptionalFeature -Filter * -ErrorAction Stop

        $recycleBin = $features | Where-Object { $_.Name -like "Recycle Bin Feature" }

        if (-not $recycleBin -or -not $recycleBin.EnabledScopes) {
            return @{
                Id       = "DS004"
                Category = "DomainState"
                Severity = "Medium"
                Result   = "Active Directory Recycle Bin is not enabled"
            }
        }
    }
    catch {
        Write-Verbose "Unable to evaluate AD Recycle Bin status. $_"
    }

    return $null
}

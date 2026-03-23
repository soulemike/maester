function Invoke-MtAdControl_DS005 {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $replicationFailures = Get-ADReplicationFailure -Scope Forest -ErrorAction Stop

        if ($replicationFailures -and $replicationFailures.Count -gt 0) {
            return @{
                Id       = "DS005"
                Category = "DomainState"
                Severity = "High"
                Result   = "$($replicationFailures.Count) Active Directory replication failure(s) detected"
            }
        }
    }
    catch {
        Write-Verbose "Unable to evaluate AD replication failures. $_"
    }

    return $null
}

<#
.SYNOPSIS
    Checks AD DACLs for privileged ACEs and issues
#>
function Test-MtAdDacls {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$Server = $__MtSession.AdServer,
        [pscredential]$Credential = $__MtSession.AdCredential
    )

    if ('ActiveDirectory' -notin $__MtSession.Connections -and 'All' -notin $__MtSession.Connections ) {
        Write-Verbose "ActiveDirectory not set as connection"
        Add-MtTestResultDetail -SkippedBecause NotConnectedActiveDirectory
        return $null
    }

    $cache = Get-MtAdCacheItem -Type AdDacls -Properties @('IdentityReference','AccessControlType','ActiveDirectoryRights','Object','InheritedObjectType','IsInherited','ObjectType') -Server $Server -Credential $Credential -TtlMinutes 30
    if ($null -eq $cache) { Add-MtTestResultDetail -SkippedBecause CacheFailure; return $null }

    $dacls = $cache.Data

    $privilegedAcls = @(
        'AccessSystemSecurity','CreateChild','Delete','DeleteChild','DeleteTree','GenericAll','GenericWrite','WriteDacl','WriteOwner','WriteProperty','Self'
    )

    $privilegedExtensions = @(
        'Add GUID','Change Domain Master','Change Infrastructure Master','Change PDC','Change Rid Master','Change Schema Master','Migrate SID History','Receive As','Reset Password','Send As','Unexpire Password','Reset Password'
    )

    $issues = @{}
    $issues.PrivilegedAllowCount = ($dacls | Where-Object { $_.AccessControlType -eq 'Allow' -and ($_.ActiveDirectoryRights -split ',\s*' | Where-Object { $privilegedAcls -contains $_ }) } | Measure-Object).Count
    $issues.PrivilegedExtendedCount = ($dacls | Where-Object { $_.AccessControlType -eq 'Allow' -and $_.ActiveDirectoryRights -eq 'ExtendedRight' -and ($privilegedExtensions -contains $_.ObjectType) } | Measure-Object).Count
    $issues.DenyCount = ($dacls | Where-Object { $_.AccessControlType -eq 'Deny' } | Measure-Object).Count
    $issues.NonInheritedCount = ($dacls | Where-Object { $_.IsInherited -eq 'False' } | Measure-Object).Count

    $result = $true
    $md = "# Test-MtAdDacls Results`n`n"
    $md += "Privileged allow ACEs: $($issues.PrivilegedAllowCount)`n"
    $md += "Privileged extended rights allow ACEs: $($issues.PrivilegedExtendedCount)`n"
    $md += "Deny ACEs: $($issues.DenyCount)`n"
    $md += "Non-inherited ACEs: $($issues.NonInheritedCount)`n`

    if ($issues.PrivilegedAllowCount -gt 0 -or $issues.PrivilegedExtendedCount -gt 0) { $result = $false }

    Add-MtTestResultDetail -Result $md
    return [bool]$result
}

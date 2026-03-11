<#
.SYNOPSIS
    Checks AD Users for dormancy and risky attributes
#>
function Test-MtAdUsers {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [int]$DormantDays = 90,
        [string]$Server = $__MtSession.AdServer,
        [pscredential]$Credential = $__MtSession.AdCredential
    )

    if ('ActiveDirectory' -notin $__MtSession.Connections -and 'All' -notin $__MtSession.Connections ) {
        Write-Verbose "ActiveDirectory not set as connection"
        Add-MtTestResultDetail -SkippedBecause NotConnectedActiveDirectory
        return $null
    }

    $cache = Get-MtAdCacheItem -Type Users -Properties @('UserName','Enabled','LastLogonDate','PasswordNeverExpires','ReversiblePasswordEncryption','SID','AdminCount') -Server $Server -Credential $Credential -TtlMinutes 30
    if ($null -eq $cache) { Add-MtTestResultDetail -SkippedBecause CacheFailure; return $null }

    $users = $cache.Data
    $now = Get-Date
    $dormantThreshold = $now.AddDays(-1 * $DormantDays)

    $totalUsers = ($users|measure).Count
    $enabledUsers = $users | Where-Object { $_.Enabled -eq 'True' }

    $dormantEnabled = $enabledUsers | Where-Object { 
        $_.'LastLogonDate' -ne $null -and ([datetime]$_.'LastLogonDate') -lt $dormantThreshold
    }

    $pwdNeverExpires = $enabledUsers | Where-Object { $_.'PasswordNeverExpires' -eq 'True' }
    $reversible = $enabledUsers | Where-Object { $_.'ReversiblePasswordEncryption' -eq 'True' }
    $adminCount = $users | Where-Object { $_.'AdminCount' -eq '1' }

    $issues = @{}
    $issues.DormantEnabledCount = ($dormantEnabled|measure).Count
    $issues.PwdNeverExpiresCount = ($pwdNeverExpires|measure).Count
    $issues.ReversibleCount = ($reversible|measure).Count
    $issues.AdminCount = ($adminCount|measure).Count
    $issues.TotalEnabled = ($enabledUsers|measure).Count
    $issues.TotalUsers = $totalUsers

    $result = $true
    $md = "# Test-MtAdUsers Results`n`n"
    $md += "Total Users: $($issues.TotalUsers)`n`n"
    $md += "Enabled Users: $($issues.TotalEnabled)`n`n"

    if ($issues.DormantEnabledCount -gt 0) {
        $result = $false
        $md += "- $($issues.DormantEnabledCount) enabled users have not logged on in the last $DormantDays days.`n"
    } else { $md += "- No enabled users dormant more than $DormantDays days.`n" }
    if ($issues.PwdNeverExpiresCount -gt 0) { $result = $false; $md += "- $($issues.PwdNeverExpiresCount) enabled users have PasswordNeverExpires set.`n" } else { $md += "- No enabled users with PasswordNeverExpires set.`n" }
    if ($issues.ReversibleCount -gt 0) { $result = $false; $md += "- $($issues.ReversibleCount) enabled users have reversible password encryption enabled.`n" } else { $md += "- No enabled users with reversible password encryption.`n" }
    if ($issues.AdminCount -gt 0) { $md += "- $($issues.AdminCount) accounts identified with AdminCount.`n`n" } 

    Add-MtTestResultDetail -Result $md

    return [bool]$result
}

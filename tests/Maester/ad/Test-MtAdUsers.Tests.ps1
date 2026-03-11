Describe "Maester/Active Directory/Test-MtAdUsers" -Tag "Maester","Active Directory","MT.AD"{
    It "returns false when fixture shows dormant and risky users"{
        Import-Module "../../powershell/internal/Load-MtAdCache.ps1"
        # Mock Get-MtAdCacheItem to return our fixture data
        Mock -CommandName Get-MtAdCacheItem -MockWith { [PSCustomObject]@{ Data = @(@{ UserName='alice'; Enabled='True'; LastLogonDate=(Get-Date).AddDays(-200).ToString(); PasswordNeverExpires='False'; ReversiblePasswordEncryption='False'; SID='S-1'; AdminCount='0' }, @{ UserName='bob'; Enabled='True'; LastLogonDate=(Get-Date).ToString(); PasswordNeverExpires='True'; ReversiblePasswordEncryption='False'; SID='S-2'; AdminCount='0' }) } -Verifiable

        . "../../powershell/public/maester/ad/Test-MtAdUsers.ps1"
        $result = Test-MtAdUsers -DormantDays 90 -Server 'fixture' -Credential $null
        $result | Should -BeFalse
    }
}

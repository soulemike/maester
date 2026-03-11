Describe "Maester/Active Directory/Test-MtAdGpoCpassword" -Tag "Maester","Active Directory","MT.AD"{
    It "returns false when Cpassword is present"{
        Mock -CommandName Get-MtAdCacheItem -MockWith { [PSCustomObject]@{ Data = @(@{ Name='GPO1'; CpasswordFound=$true; DefaultPasswordFound=$false; TrusteeNames=@('NT Authority\\Authenticated Users'); DisabledLinks=$null; Enforcement=$null }) } }
        . "../../powershell/public/maester/ad/Test-MtAdGpoCpassword.ps1"
        $result = Test-MtAdGpoCpassword -Server 'fixture' -Credential $null
        $result | Should -BeFalse
    }
}

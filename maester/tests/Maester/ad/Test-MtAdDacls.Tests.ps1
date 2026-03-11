Describe "Maester/Active Directory/Test-MtAdDacls" -Tag "Maester","Active Directory","MT.AD"{
    It "returns false when privileged ACEs are present"{
        Mock -CommandName Get-MtAdCacheItem -MockWith { [PSCustomObject]@{ Data = @(@{ IdentityReference='DOMAIN\\Admin'; AccessControlType='Allow'; ActiveDirectoryRights='GenericAll'; Object='LDAP://CN=Users,DC=example,DC=com'; IsInherited='True'; ObjectType='User' }) } }
        . "../../powershell/public/maester/ad/Test-MtAdDacls.ps1"
        $result = Test-MtAdDacls -Server 'fixture' -Credential $null
        $result | Should -BeFalse
    }
}

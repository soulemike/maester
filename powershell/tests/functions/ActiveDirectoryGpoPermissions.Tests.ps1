BeforeDiscovery {
    # The native tests that read the permission summary of Get-MtADGpoState. Finding is the GPO permission
    # profile (see New-TestGpo) that the test must flag.
    $script:permissionTests = @(
        # The consolidated 01/03 checks are covered by ADGpoReports.Tests.ps1.
        @{ Id = 'AD-GPOREP-05'; Command = 'Test-MtAdGpoNoEnterpriseDcCount'; Finding = 'NoEnterpriseDc' }
        @{ Id = 'AD-GPOREP-06'; Command = 'Test-MtAdGpoNoDomainComputersCount'; Finding = 'NoComputerAccess' }
        @{ Id = 'AD-GPOREP-09'; Command = 'Test-MtAdGpoInheritedPermissionsCount'; Finding = 'Inherited' }
    )
}

BeforeAll {
    Import-Module "$PSScriptRoot/../../Maester.psd1" -Force
    $script:realSysvolContent = InModuleScope Maester { (Get-Command Get-MtSysvolContent).ScriptBlock }
    . "$PSScriptRoot/../helpers/Use-MtModuleFunction.ps1"
    # Check functions that became native tests are not exported.
    Use-MtModuleFunction -Name Test-MtAdGpoNoEnterpriseDcCount,
    Test-MtAdGpoNoDomainComputersCount, Test-MtAdGpoInheritedPermissionsCount

    $script:domainSid = 'S-1-5-21-1111111111-2222222222-3333333333'

    # An ACE in the shape ConvertFrom-MtLdapSecurityDescriptor returns.
    function New-TestAce {
        param(
            [string] $Sid,
            [string] $AccessControlType = 'Allow',
            [string] $ActiveDirectoryRights = 'GenericRead',
            [string] $ObjectType = [guid]::Empty.ToString(),
            [string] $AceFlags = 'ContainerInherit',
            [switch] $Inherited
        )
        [PSCustomObject]@{
            AccessControlType     = $AccessControlType
            AceFlags              = if ($Inherited) { "$AceFlags, Inherited" } else { $AceFlags }
            ActiveDirectoryRights = $ActiveDirectoryRights
            IdentityReference     = $Sid
            IsInherited           = [bool]$Inherited
            ObjectType            = $ObjectType
            Sid                   = $Sid
        }
    }

    # A GPO as Get-MtLdapGpo returns it. The profile names the permissions on the GPO.
    function New-TestGpo {
        param([string] $PermissionProfile)

        $authenticatedUsers = New-TestAce -Sid 'S-1-5-11'
        $applyGroupPolicy = New-TestAce -Sid 'S-1-5-11' -ActiveDirectoryRights 'ExtendedRight' -ObjectType 'edacfd8f-ffb3-11d1-b41d-00a0c968f939'
        $enterpriseDomainControllers = New-TestAce -Sid 'S-1-5-9'
        $domainAdmins = New-TestAce -Sid "$script:domainSid-512" -ActiveDirectoryRights 'GenericAll'
        $domainComputers = New-TestAce -Sid "$script:domainSid-515"

        $aces = switch ($PermissionProfile) {
            # What a new GPO gets: no Domain Computers entry and no inherited entry.
            'Default' { $authenticatedUsers, $applyGroupPolicy, $enterpriseDomainControllers, $domainAdmins, (New-TestAce -Sid 'S-1-3-0' -ActiveDirectoryRights 'GenericAll' -AceFlags 'ContainerInherit, InheritOnly') }
            # Security filtering: Authenticated Users replaced by Domain Computers.
            'DomainComputers' { $domainComputers, $enterpriseDomainControllers, $domainAdmins }
            'NoEnterpriseDc' { $authenticatedUsers, $applyGroupPolicy, $domainAdmins }
            'NoComputerAccess' { $enterpriseDomainControllers, $domainAdmins }
            'Inherited' { $authenticatedUsers, $applyGroupPolicy, $enterpriseDomainControllers, $domainAdmins, (New-TestAce -Sid "$script:domainSid-1104" -Inherited) }
            'DenyOnly' { New-TestAce -Sid 'S-1-5-11' -AccessControlType 'Deny' }
            # Allow and Deny for the same principal: access is unknown, not present.
            'AllowAndDeny' { $authenticatedUsers, $applyGroupPolicy, (New-TestAce -Sid 'S-1-5-11' -AccessControlType 'Deny' -ActiveDirectoryRights 'GenericAll'), $enterpriseDomainControllers, $domainAdmins }
            # ContainerInherit without InheritOnly grants on the GPO itself, so it must be counted (soulemike).
            'ContainerInheritOnly' { (New-TestAce -Sid 'S-1-5-11' -AceFlags 'ContainerInherit'), $domainAdmins }
            # Duplicate ACEs for the same principal: membership check must still say present (soulemike).
            'DuplicateAuthUsers' { $authenticatedUsers, $authenticatedUsers, $enterpriseDomainControllers, $domainAdmins }
            'InheritOnly' { (New-TestAce -Sid 'S-1-5-11' -AceFlags 'ContainerInherit, InheritOnly'), $domainAdmins }
            'EmptyDacl' { }
        }

        $id = [guid]::NewGuid()
        [PSCustomObject]@{
            Id                   = $id
            DisplayName          = "GPO $PermissionProfile"
            DistinguishedName    = "CN={$id},CN=Policies,CN=System,DC=contoso,DC=com"
            Created              = [datetime]'2026-01-01'
            Modified             = [datetime]'2026-01-01'
            Flags                = 0
            # Unreadable: Active Directory did not return the security descriptor.
            ntSecurityDescriptor = if ($PermissionProfile -eq 'Unreadable') { $null } else { [PSCustomObject]@{ Access = @($aces) } }
            VersionNumber        = 1
        }
    }
}

Describe 'Active Directory GPO permissions' {
    BeforeEach {
        InModuleScope Maester {
            $__MtSession.ADConnection = [PSCustomObject]@{
                Connected         = $true
                ProtocolValidated = $true
                ResolvedDomain    = 'contoso.com'
                ResolvedServer    = 'dc01.contoso.com'
                RequestedAuthMode = 'Negotiate'
                RequestedTlsMode  = 'Auto'
                RequestedServer   = 'dc01.contoso.com'
            }
            $__MtSession.ADCache = @{}
        }

        $script:testGpos = @()
        $script:resultDetail = $null

        Mock Test-MtConnection -ModuleName Maester { $true }
        Mock Connect-MtAdTarget -ModuleName Maester { [PSCustomObject]@{} }
        Mock New-MtAdProtocolConnection -ModuleName Maester { [PSCustomObject]@{} | Add-Member -MemberType ScriptMethod -Name Dispose -Value { } -PassThru }
        Mock Get-MtLdapRootDse -ModuleName Maester -RemoveParameterType Connection {
            [PSCustomObject]@{ DefaultNamingContext = 'DC=contoso,DC=com'; ConfigurationNamingContext = 'CN=Configuration,DC=contoso,DC=com' }
        }
        Mock Get-MtLdapGpo -ModuleName Maester -RemoveParameterType Connection { $script:testGpos }
        Mock Get-MtLdapGpoLink -ModuleName Maester -RemoveParameterType Connection { @() }
        Mock Get-MtLdapSiteContainer -ModuleName Maester -RemoveParameterType Connection { @() }
        Mock Get-MtSysvolContent -ModuleName Maester { [PSCustomObject]@{ GptIni = $null; CpasswordFound = $false; DefaultPasswordFound = $false } }
        Mock Add-MtTestResultDetail -ModuleName Maester {
            $script:resultDetail = [PSCustomObject]@{ Result = $Result; SkippedBecause = $SkippedBecause; SkippedCustomReason = $SkippedCustomReason; Investigate = [bool]$Investigate }
        }
    }

    AfterEach {
        InModuleScope Maester {
            $__MtSession.ADConnection = $null
            $__MtSession.ADCache = @{}
        }
    }

    Context 'Get-MtADGpoState permission summary' {
        It 'keeps failed site-link collection unknown for link consumers' {
            $script:testGpos = @(New-TestGpo -PermissionProfile 'Default')
            Mock Get-MtLdapSiteContainer -ModuleName Maester -RemoveParameterType Connection { throw 'site links unavailable' }
            $state = Get-MtADGpoState
            $null -eq $state.SiteContainers | Should -BeTrue
            $null -eq $state.GPOLinks | Should -BeTrue
            $null -eq $state.GPOReports[0].DisabledLinks | Should -BeTrue
            $null -eq $state.GPOReports[0].EnforcementEnabled | Should -BeTrue
            InModuleScope Maester {
                { Test-MtAdGpoUnlinkedCount } | Should -Throw '*links*'
                { Test-MtCheckADGPOREP12 } | Should -Throw '*links*'
            }
        }

        It 'keeps failed metadata and report collection distinct from completed empty collections' {
            Mock Get-MtLdapGpo -ModuleName Maester -RemoveParameterType Connection { throw 'metadata unavailable' }
            $state = Get-MtADGpoState
            $null -eq $state.GPOs | Should -BeTrue
            $null -eq $state.GPOReports | Should -BeTrue
        }

        It 'returns empty arrays after a completed empty metadata collection' {
            $state = Get-MtADGpoState
            $null -eq $state.GPOs | Should -BeFalse
            @($state.GPOs) | Should -HaveCount 0
            $null -eq $state.GPOReports | Should -BeFalse
            @($state.GPOReports) | Should -HaveCount 0
        }

        It 'keeps report-building failure unknown rather than returning an empty report list' {
            $script:testGpos = @(New-TestGpo -PermissionProfile 'Default')
            $script:testGpos[0].ntSecurityDescriptor = [byte[]]@(1, 2, 3)
            Mock ConvertFrom-MtLdapSecurityDescriptor -ModuleName Maester { throw 'descriptor unavailable' }
            $state = Get-MtADGpoState
            @($state.GPOs) | Should -HaveCount 1
            $null -eq $state.GPOReports | Should -BeTrue
        }

        It 'interprets Apply Group Policy ACE evidence for <Rights> / <ObjectType> / <Flags>' -ForEach @(
            @{ Rights = 'GenericAll'; ObjectType = '00000000-0000-0000-0000-000000000000'; Flags = 'ContainerInherit'; Access = 'Allow'; Expected = $true }
            @{ Rights = 'ExtendedRight'; ObjectType = '00000000-0000-0000-0000-000000000000'; Flags = 'ContainerInherit'; Access = 'Allow'; Expected = $true }
            @{ Rights = 'ExtendedRight'; ObjectType = 'edacfd8f-ffb3-11d1-b41d-00a0c968f939'; Flags = 'ContainerInherit'; Access = 'Allow'; Expected = $true }
            @{ Rights = 'ReadProperty'; ObjectType = 'edacfd8f-ffb3-11d1-b41d-00a0c968f939'; Flags = 'ContainerInherit'; Access = 'Allow'; Expected = $false }
            @{ Rights = 'GenericAll'; ObjectType = '00000000-0000-0000-0000-000000000000'; Flags = 'ContainerInherit, InheritOnly'; Access = 'Allow'; Expected = $false }
            @{ Rights = 'ExtendedRight'; ObjectType = 'edacfd8f-ffb3-11d1-b41d-00a0c968f939'; Flags = 'ContainerInherit'; Access = 'Deny'; Expected = $false }
            @{ Rights = 'ExtendedRight'; ObjectType = '11111111-1111-1111-1111-111111111111'; Flags = 'ContainerInherit'; Access = 'Allow'; Expected = $false }
        ) {
            $gpo = New-TestGpo -PermissionProfile 'EmptyDacl'
            $gpo.ntSecurityDescriptor.Access = @(New-TestAce -Sid 'S-1-5-11' -ActiveDirectoryRights $Rights -ObjectType $ObjectType -AceFlags $Flags -AccessControlType $Access)
            $script:testGpos = @($gpo)
            $report = @((Get-MtADGpoState).GPOReports)[0]
            $report.HasApplyGroupPolicyAce | Should -Be $Expected
        }

        It 'records observed versions independently of missing GPT.INI' -ForEach @(
            @{ SysvolVersion = 65538; ExpectedMismatch = $false }
            @{ SysvolVersion = 65539; ExpectedMismatch = $true }
            @{ SysvolVersion = $null; ExpectedMismatch = $null }
        ) {
            $script:testGpos = @(New-TestGpo -PermissionProfile 'Default')
            $script:testGpos[0].VersionNumber = 65538
            $script:observedSysvolVersion = $SysvolVersion
            Mock Get-MtSysvolContent -ModuleName Maester {
                [pscustomobject]@{ GptIni = if ($null -eq $script:observedSysvolVersion) { $null } else { [pscustomobject]@{ Version = $script:observedSysvolVersion } }; CpasswordFound = $false; DefaultPasswordFound = $false }
            }
            $report = @((Get-MtADGpoState).GPOReports)[0]
            $report.DirectoryVersion | Should -Be 65538
            $report.SysvolVersion | Should -Be $SysvolVersion
            $report.HasVersionMismatch | Should -Be $ExpectedMismatch
        }

        It 'records failed SYSVOL scans as unknown flags and explicit errors' {
            $script:testGpos = @(New-TestGpo -PermissionProfile 'Default')
            Mock Get-MtSysvolContent -ModuleName Maester { throw 'scan incomplete' }
            $report = @((Get-MtADGpoState).GPOReports)[0]
            $null -eq $report.CpasswordFound | Should -BeTrue
            $null -eq $report.DefaultPasswordFound | Should -BeTrue
            $null -eq $report.SysvolVersion | Should -BeTrue
            $null -eq $report.HasVersionMismatch | Should -BeTrue
            @($report.Errors) | Should -HaveCount 1
        }

        It 'does not pass password or version checks after a readable password XML and an unreadable XML' -ForEach @(
            @{ ReadFailure = $true }
            @{ ReadFailure = $false }
        ) {
            $script:testGpos = @(New-TestGpo -PermissionProfile 'Default')
            $script:testGpos[0].VersionNumber = 65538
            $script:xmlReadFailure = $ReadFailure
            Mock Get-MtSysvolContent -ModuleName Maester { & $script:realSysvolContent -Operation $Operation -GpoGuid $GpoGuid }
            Mock Test-MtSysvolWindowsPlatform -ModuleName Maester { $true }
            Mock Invoke-MtSysvolWindowsAdapter -ModuleName Maester {
                if ($Operation -eq 'List') {
                    return @(
                        [pscustomobject]@{ RelativePath = 'GPT.INI'; Name = 'GPT.INI'; Length = 25 }
                        [pscustomobject]@{ RelativePath = 'Machine/Preferences/Groups/Groups.xml'; Name = 'Groups.xml'; Length = 100 }
                        [pscustomobject]@{ RelativePath = 'Machine/Preferences/Drives/Drives.xml'; Name = 'Drives.xml'; Length = 100 }
                    )
                }
                if ($Operation -eq 'ReadText') {
                    if ($RelativePath -eq 'GPT.INI') { return "[General]`nVersion=65539" }
                    if ($RelativePath -like '*Groups.xml') { return '<Groups><User cpassword="SECRET-MUST-NOT-PRINT" /></Groups>' }
                    if ($script:xmlReadFailure) { throw 'read failed SECRET-MUST-NOT-PRINT' }
                    return '<Drives><Drive cpassword="SECRET-MUST-NOT-PRINT"'
                }
                return $true
            }
            $state = Get-MtADGpoState
            @($state.GPOReports[0].Errors) | Should -HaveCount 1
            $state.GPOReports[0].Errors.Message | Should -Match 'password scan is incomplete'
            $state.GPOReports[0].Errors.Message | Should -Not -Match 'SECRET-MUST-NOT-PRINT'
            InModuleScope Maester {
                { Test-MtAdGpoCpasswordFoundCount } | Should -Throw '*incomplete*'
                { Test-MtAdGpoVersionMismatchCount } | Should -Throw '*incomplete*'
            }
        }

        It 'Reports the permissions of a GPO with <PermissionProfile> permissions' -ForEach @(
            @{ PermissionProfile = 'Default'; PermissionsPresent = $true; HasAuthenticatedUsers = $true; HasEnterpriseDomainControllers = $true; HasDomainComputers = $false; HasInheritedPermissions = $false }
            @{ PermissionProfile = 'DomainComputers'; PermissionsPresent = $true; HasAuthenticatedUsers = $false; HasEnterpriseDomainControllers = $true; HasDomainComputers = $true; HasInheritedPermissions = $false }
            @{ PermissionProfile = 'NoEnterpriseDc'; PermissionsPresent = $true; HasAuthenticatedUsers = $true; HasEnterpriseDomainControllers = $false; HasDomainComputers = $false; HasInheritedPermissions = $false }
            @{ PermissionProfile = 'Inherited'; PermissionsPresent = $true; HasAuthenticatedUsers = $true; HasEnterpriseDomainControllers = $true; HasDomainComputers = $false; HasInheritedPermissions = $true }
            # A Deny entry and an entry that only applies to child objects do not give the principal access.
            @{ PermissionProfile = 'DenyOnly'; PermissionsPresent = $true; HasAuthenticatedUsers = $false; HasEnterpriseDomainControllers = $false; HasDomainComputers = $false; HasInheritedPermissions = $false }
            # A principal that is both allowed and denied: unknown, because the masks are not compared.
            @{ PermissionProfile = 'AllowAndDeny'; PermissionsPresent = $true; HasAuthenticatedUsers = $null; HasEnterpriseDomainControllers = $true; HasDomainComputers = $false; HasInheritedPermissions = $false }
            @{ PermissionProfile = 'ContainerInheritOnly'; PermissionsPresent = $true; HasAuthenticatedUsers = $true; HasEnterpriseDomainControllers = $false; HasDomainComputers = $false; HasInheritedPermissions = $false }
            @{ PermissionProfile = 'DuplicateAuthUsers'; PermissionsPresent = $true; HasAuthenticatedUsers = $true; HasEnterpriseDomainControllers = $true; HasDomainComputers = $false; HasInheritedPermissions = $false }
            @{ PermissionProfile = 'InheritOnly'; PermissionsPresent = $true; HasAuthenticatedUsers = $false; HasEnterpriseDomainControllers = $false; HasDomainComputers = $false; HasInheritedPermissions = $false }
            @{ PermissionProfile = 'EmptyDacl'; PermissionsPresent = $false; HasAuthenticatedUsers = $false; HasEnterpriseDomainControllers = $false; HasDomainComputers = $false; HasInheritedPermissions = $false }
            # Unknown is not the same as absent.
            @{ PermissionProfile = 'Unreadable'; PermissionsPresent = $null; HasAuthenticatedUsers = $null; HasEnterpriseDomainControllers = $null; HasDomainComputers = $null; HasInheritedPermissions = $null }
        ) {
            $script:testGpos = @(New-TestGpo -PermissionProfile $PermissionProfile)

            $report = @((Get-MtADGpoState).GPOReports)
            $report | Should -HaveCount 1

            foreach ($property in 'PermissionsPresent', 'HasAuthenticatedUsers', 'HasEnterpriseDomainControllers', 'HasDomainComputers', 'HasInheritedPermissions') {
                $report[0].PSObject.Properties.Name | Should -Contain $property
                $expected = Get-Variable -Name $property -ValueOnly
                if ($null -eq $expected) {
                    $null -eq $report[0].$property | Should -BeTrue -Because "$property is unknown when the security descriptor is missing"
                } else {
                    $report[0].$property | Should -BeOfType [bool]
                    $report[0].$property | Should -Be $expected -Because "of the $PermissionProfile permissions ($property)"
                }
            }
        }

        It 'Matches Domain Computers of any domain, and no other group' {
            $otherDomain = New-TestGpo -PermissionProfile 'EmptyDacl'
            $otherDomain.ntSecurityDescriptor = [PSCustomObject]@{ Access = @(New-TestAce -Sid 'S-1-5-21-4444444444-5555555555-6666666666-515') }
            $domainControllers = New-TestGpo -PermissionProfile 'EmptyDacl'
            $domainControllers.ntSecurityDescriptor = [PSCustomObject]@{ Access = @(New-TestAce -Sid "$script:domainSid-516") }
            $script:testGpos = @($otherDomain, $domainControllers)

            $reports = @((Get-MtADGpoState).GPOReports)
            $reports[0].HasDomainComputers | Should -BeTrue
            $reports[1].HasDomainComputers | Should -BeFalse
        }
    }

    Context '<Id> <Command>' -ForEach $permissionTests {
        It 'Passes when every GPO has the default permissions' {
            $script:testGpos = @((New-TestGpo -PermissionProfile 'Default'), (New-TestGpo -PermissionProfile 'Default'))

            & $Command | Should -BeTrue
            $script:resultDetail.Investigate | Should -BeFalse
            $script:resultDetail.SkippedBecause | Should -BeNullOrEmpty
            $script:resultDetail.Result | Should -Not -Match 'GPO Default'
            # The pass is for the two GPOs, not for an empty list. The details tests print no total.
            if ($Command -like '*Count') { $script:resultDetail.Result | Should -Match 'Total GPO Reports \| 2 \|' }
        }

        It 'Fails for the GPO with <Finding> permissions and not for the others' {
            $script:testGpos = @((New-TestGpo -PermissionProfile 'Default'), (New-TestGpo -PermissionProfile $Finding))

            & $Command | Should -BeFalse
            $script:resultDetail.Investigate | Should -BeFalse
            $script:resultDetail.Result | Should -Match "GPO $Finding"
            $script:resultDetail.Result | Should -Not -Match 'GPO Default'
        }

        It 'Does not count a GPO whose permissions could not be read as a finding, and asks for a review' {
            $script:testGpos = @((New-TestGpo -PermissionProfile 'Default'), (New-TestGpo -PermissionProfile 'Unreadable'))

            & $Command | Should -BeTrue
            $script:resultDetail.Investigate | Should -BeTrue
            $script:resultDetail.Result | Should -Match 'could not be read'
            $script:resultDetail.Result | Should -Match 'GPO Unreadable'
            $script:resultDetail.Result | Should -Not -Match 'GPO Default'
        }

        It 'Still fails for <Finding> permissions when another GPO could not be read' {
            $script:testGpos = @((New-TestGpo -PermissionProfile $Finding), (New-TestGpo -PermissionProfile 'Unreadable'))

            & $Command | Should -BeFalse
            $script:resultDetail.Investigate | Should -BeFalse
            $script:resultDetail.Result | Should -Match "GPO $Finding"
            $script:resultDetail.Result | Should -Match 'could not be read'
        }

        It 'Is skipped when <Case>' -ForEach @(
            @{ Case = 'no security descriptor was returned'; Profiles = @('Unreadable', 'Unreadable') }
            @{ Case = 'no GPO report was built'; Profiles = @() }
        ) {
            $script:testGpos = @($Profiles | ForEach-Object { New-TestGpo -PermissionProfile $_ })

            & $Command | Should -BeNullOrEmpty -Because $Case
            $script:resultDetail.SkippedBecause | Should -Be 'Custom'
            $script:resultDetail.SkippedCustomReason | Should -Match "0 of $($Profiles.Count) GPOs evaluated"
        }
    }

    Context 'AD-GPOREP-06 Test-MtAdGpoNoDomainComputersCount' {
        It 'Passes when Domain Computers replaces Authenticated Users' {
            $script:testGpos = @(New-TestGpo -PermissionProfile 'DomainComputers')

            Test-MtAdGpoNoDomainComputersCount | Should -BeTrue
            $script:resultDetail.Result | Should -Match 'GPO Reports Without Domain Computers \| 0 \|'
        }

        It 'Reports a GPO without Domain Computers as expected when Authenticated Users has access' {
            $script:testGpos = @(New-TestGpo -PermissionProfile 'Default')

            Test-MtAdGpoNoDomainComputersCount | Should -BeTrue
            $script:resultDetail.Result | Should -Match 'GPO Reports Without Domain Computers \| 1 \|'
            $script:resultDetail.Result | Should -Match 'GPO Reports Without Domain Computers And Without Authenticated Users \| 0 \|'
        }

        It 'Passes when one GPO has Default permissions and another has DomainComputers' {
            $script:testGpos = @((New-TestGpo -PermissionProfile 'Default'), (New-TestGpo -PermissionProfile 'DomainComputers'))

            Test-MtAdGpoNoDomainComputersCount | Should -BeTrue
            $script:resultDetail.Result | Should -Match 'GPO Reports Without Domain Computers And Without Authenticated Users \| 0 \|'
        }
    }
}

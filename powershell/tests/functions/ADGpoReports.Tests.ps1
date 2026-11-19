BeforeAll {
    Import-Module "$PSScriptRoot/../../Maester.psd1" -Force
    . "$PSScriptRoot/../helpers/Use-MtModuleFunction.ps1"
    Use-MtModuleFunction -Name Test-MtAdGpoCpasswordFoundCount, Test-MtAdGpoVersionMismatchCount, Test-MtCheckADGPOREP12, Test-MtAdGpoNoApplyGroupPolicyAceCount, Test-MtAdGpoNoPermissionsCount, Test-MtAdGpoNoAuthenticatedUsersCount
}

Describe 'Merged AD GPO report checks' {
    BeforeEach {
        $script:detail = $null
        $script:report = [PSCustomObject]@{
            Name = 'Example GPO'
            CpasswordFound = $false
            DefaultPasswordFound = $false
            HasVersionMismatch = $false
            DirectoryVersion = 65538
            SysvolVersion = 65538
            Errors = @()
            HasApplyGroupPolicyAce = $true
            PermissionsPresent = $true
            HasAuthenticatedUsers = $true
        }
        $script:state = [PSCustomObject]@{
            GPOs = @([PSCustomObject]@{ Id = '00000000-0000-0000-0000-000000000001'; DisplayName = 'Example GPO' })
            GPOReports = @($script:report)
            GPOLinks = @()
        }
        Mock Get-MtADGpoState -ModuleName Maester { $script:state }
        Mock Add-MtTestResultDetail -ModuleName Maester { $script:detail = $Result }
    }

    It 'passes only after both secret scan flags are evaluated' {
        Test-MtAdGpoCpasswordFoundCount | Should -BeTrue
        $script:detail | Should -Match 'Well done'
    }

    It 'fails when a GPO has no permissions and lists its name' {
        $script:report.PermissionsPresent = $false
        Test-MtAdGpoNoPermissionsCount | Should -BeFalse
        $script:detail | Should -Match 'Example GPO'
    }

    It 'marks unreadable permissions for investigation' {
        $script:report.PermissionsPresent = $null
        Test-MtAdGpoNoPermissionsCount | Should -BeTrue
        Should -Invoke Add-MtTestResultDetail -ModuleName Maester -Exactly 1 -ParameterFilter { $Investigate }
    }

    It 'investigates alternative security filtering rather than failing Authenticated Users absence' {
        $script:report.HasAuthenticatedUsers = $false
        Test-MtAdGpoNoAuthenticatedUsersCount | Should -BeTrue
        Should -Invoke Add-MtTestResultDetail -ModuleName Maester -Exactly 1 -ParameterFilter { $Investigate }
        $script:detail | Should -Match 'Example GPO'
    }

    It 'evaluates real nonempty permission reports for <Command>' -ForEach @(
        @{ Command = 'Test-MtAdGpoNoPermissionsCount'; ExpectedInvestigate = $false }
        @{ Command = 'Test-MtAdGpoNoAuthenticatedUsersCount'; ExpectedInvestigate = $true }
    ) {
        $script:expectedInvestigation = $ExpectedInvestigate
        & $Command | Should -BeTrue
        $script:detail | Should -Match '1 GPOs'
        Should -Invoke Add-MtTestResultDetail -ModuleName Maester -Exactly 1 -ParameterFilter { [bool]$Investigate -eq $script:expectedInvestigation }
    }

    It 'does not treat an empty report collection as a clean permission result for <Command>' -ForEach @(
        @{ Command = 'Test-MtAdGpoNoPermissionsCount' }
        @{ Command = 'Test-MtAdGpoNoAuthenticatedUsersCount' }
    ) {
        $script:state.GPOReports = @()
        { & $Command } | Should -Throw '*No GPO permission reports*'
    }

    It 'investigates entirely unreadable permissions for <Command>' -ForEach @(
        @{ Command = 'Test-MtAdGpoNoPermissionsCount'; Property = 'PermissionsPresent' }
        @{ Command = 'Test-MtAdGpoNoAuthenticatedUsersCount'; Property = 'HasAuthenticatedUsers' }
    ) {
        $script:report.$Property = $null
        & $Command | Should -BeTrue
        $script:detail | Should -Match 'Not evaluated'
        Should -Invoke Add-MtTestResultDetail -ModuleName Maester -Exactly 1 -ParameterFilter { $Investigate }
    }

    It 'distinguishes clean and unreadable permissions for <Command>' -ForEach @(
        @{ Command = 'Test-MtAdGpoNoPermissionsCount'; Property = 'PermissionsPresent' }
        @{ Command = 'Test-MtAdGpoNoAuthenticatedUsersCount'; Property = 'HasAuthenticatedUsers' }
    ) {
        $script:state.GPOReports += [pscustomobject]@{ Name = 'Unreadable GPO'; PermissionsPresent = $null; HasAuthenticatedUsers = $null }
        & $Command | Should -BeTrue
        $script:detail | Should -Match 'Unreadable GPO'
        Should -Invoke Add-MtTestResultDetail -ModuleName Maester -Exactly 1 -ParameterFilter { $Investigate }
    }

    It 'retains an observed empty ACL finding beside unreadable permissions' {
        $script:report.PermissionsPresent = $false
        $script:state.GPOReports += [pscustomobject]@{ Name = 'Unreadable GPO'; PermissionsPresent = $null }
        Test-MtAdGpoNoPermissionsCount | Should -BeFalse
        $script:detail | Should -Match 'Example GPO'
        $script:detail | Should -Match 'Unreadable GPO'
        Should -Not -Invoke Add-MtTestResultDetail -ModuleName Maester -ParameterFilter { $Investigate }
    }

    It 'retains alternative filtering and unreadable entries in the investigation' {
        $script:report.HasAuthenticatedUsers = $false
        $script:state.GPOReports += [pscustomobject]@{ Name = 'Unreadable GPO'; HasAuthenticatedUsers = $null }
        Test-MtAdGpoNoAuthenticatedUsersCount | Should -BeTrue
        $script:detail | Should -Match 'Example GPO'
        $script:detail | Should -Match 'Unreadable GPO'
        Should -Invoke Add-MtTestResultDetail -ModuleName Maester -Exactly 1 -ParameterFilter { $Investigate }
    }

    It 'passes when application rights are present' {
        Test-MtAdGpoNoApplyGroupPolicyAceCount | Should -BeTrue
        Should -Not -Invoke Add-MtTestResultDetail -ModuleName Maester -ParameterFilter { $Investigate }
    }

    It 'fails when application rights are absent' {
        $script:report.HasApplyGroupPolicyAce = $false
        Test-MtAdGpoNoApplyGroupPolicyAceCount | Should -BeFalse
        $script:detail | Should -Match 'Example GPO'
    }

    It 'errors rather than passing when application rights are unreadable' {
        $script:report.HasApplyGroupPolicyAce = $null
        { Test-MtAdGpoNoApplyGroupPolicyAceCount } | Should -Throw '*could not be evaluated*'
    }

    It 'fails on cpassword alone without rendering the secret value' {
        $script:report.CpasswordFound = $true
        $script:report | Add-Member -NotePropertyName Password -NotePropertyValue 'SECRET-MUST-NOT-PRINT'
        Test-MtAdGpoCpasswordFoundCount | Should -BeFalse
        $script:detail | Should -Match 'Example GPO'
        $script:detail | Should -Not -Match 'SECRET-MUST-NOT-PRINT'
    }

    It 'fails on a default password alone' {
        $script:report.DefaultPasswordFound = $true
        Test-MtAdGpoCpasswordFoundCount | Should -BeFalse
        $script:detail | Should -Match 'default passwords'
    }

    It 'errors on null or missing scan flags and on SYSVOL collection errors' -ForEach @(
        @{ Case = 'missing cpassword flag' }
        @{ Case = 'missing default password flag' }
        @{ Case = 'SYSVOL error' }
    ) {
        switch ($Case) {
            'missing cpassword flag' { $script:report.CpasswordFound = $null }
            'missing default password flag' { $script:report.DefaultPasswordFound = $null }
            'SYSVOL error' { $script:report.Errors = @([PSCustomObject]@{ Transport = 'SYSVOL'; Message = 'failed' }) }
        }
        { Test-MtAdGpoCpasswordFoundCount } | Should -Throw '*incomplete*'
    }

    It 'errors if report collection silently drops a GPO' {
        $script:state.GPOs += [PSCustomObject]@{ Id = '00000000-0000-0000-0000-000000000002'; DisplayName = 'Other GPO' }
        { Test-MtAdGpoCpasswordFoundCount } | Should -Throw '*inventory*'
    }

    It 'shows both versions for mismatched policies' {
        $script:report.HasVersionMismatch = $true
        $script:report.SysvolVersion = 65539
        Test-MtAdGpoVersionMismatchCount | Should -BeFalse
        $script:detail | Should -Match '65538 \| 65539'
    }

    It 'does not pass when SYSVOL version is missing' {
        $script:report.SysvolVersion = $null
        { Test-MtAdGpoVersionMismatchCount } | Should -Throw '*incomplete*'
    }

    It 'inventories disabled links and lists their linked container' {
        $script:state.GPOLinks = @([PSCustomObject]@{
                GpoGuid = '00000000-0000-0000-0000-000000000001'
                DistinguishedName = 'OU=Clients,DC=example,DC=com'
                IsDisabled = $true
            })
        Test-MtCheckADGPOREP12 | Should -BeTrue
        $script:detail | Should -Match '1 disabled links'
        $script:detail | Should -Match 'OU=Clients'
    }

    It 'uses the same normalized disabled-link inventory in both native checks' {
        $script:state.GPOLinks = @(
            [pscustomobject]@{ GpoGuid = '00000000-0000-0000-0000-000000000001'; DistinguishedName = 'OU=Clients,DC=example,DC=com'; IsDisabled = $true; IsEnforced = $false }
            [pscustomobject]@{ GpoGuid = '00000000-0000-0000-0000-000000000001'; DistinguishedName = 'OU=Servers,DC=example,DC=com'; IsDisabled = $false; IsEnforced = $true }
        )
        Test-MtCheckADGPOREP12 | Should -BeTrue
        $firstDetail = $script:detail
        InModuleScope Maester { Test-MtCheckADGPOL02 | Should -BeTrue }
        $script:detail | Should -Be $firstDetail
        $script:detail | Should -Match '1 disabled links among 2'
        $script:detail | Should -Match 'Known enforced links \| 1'
    }

    It 'rejects unknown disabled-link flags instead of counting them as enabled' {
        $script:state.GPOLinks = @([pscustomobject]@{ IsDisabled = $null; GpoGuid = '00000000-0000-0000-0000-000000000001' })
        { Test-MtCheckADGPOREP12 } | Should -Throw '*could not be evaluated*'
        InModuleScope Maester { { Test-MtCheckADGPOL02 } | Should -Throw '*could not be evaluated*' }
    }
}

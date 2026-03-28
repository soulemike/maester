Import-Module "$PSScriptRoot/../../Maester.psd1" -Force

Describe "Active Directory Control Engine" {

    InModuleScope Maester {
        BeforeEach {
            Mock Get-MtAdUser { @() }
            Mock Get-MtAdGroup { @() }
            Mock Get-MtAdComputer { @() }
            Mock Get-MtAdOrganizationalUnit { @() }
            Mock Get-MtAdGpo { @() }
            Mock Get-MtAdDomain { @{} }
        }

        It "Returns structured result with Controls array" {
            $result = Get-MtAdAnalysis -Domain "example.com"

            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain "Controls"
            $result.Controls | Should -BeOfType "System.Object[]"
        }

        It "Filters out null control results" {
            Mock Invoke-MtAdControlRegistry {
                @(
                    @{ FunctionName = "Invoke-MtAdControl_Dummy1" },
                    @{ FunctionName = "Invoke-MtAdControl_Dummy2" }
                )
            }

            function Invoke-MtAdControl_Dummy1 { param($Data) return $null }
            function Invoke-MtAdControl_Dummy2 { param($Data) return @{ Id = "X" } }

            $result = Get-MtAdAnalysis -Domain "example.com"

            $result.Controls.Count | Should -Be 1
            $result.Controls[0].Id | Should -Be "X"
        }
    }
}

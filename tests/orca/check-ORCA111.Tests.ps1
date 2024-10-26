# Generated on 10/25/2024 18:35:17 by .\build\orca\Update-OrcaTests.ps1

Describe "ORCA" -Tag "ORCA", "ORCA111", "EXO", "Security", "All" {
    It "ORCA111: Unauthenticated Sender (tagging)" {

        if(!(Test-MtConnection ExchangeOnline)){
            Add-MtTestResultDetail -SkippedBecause NotConnectedExchange
            $result = $null
        }elseif(!(Test-MtConnection SecurityCompliance)){
            Add-MtTestResultDetail -SkippedBecause NotConnectedSecurityCompliance
            $result = $null
        }else{
            $Collection = Get-ORCACollection
            $obj = New-Object -TypeName ORCA111
            $obj.Run($Collection)
            $result = ($obj.Completed -and $obj.Result -eq "Pass")

            $resultMarkdown = "Microsoft Defender for Office 365 Policies - Unauthenticated Sender (tagging) - ORCA-111`n`n"
            if($result){
                $resultMarkdown += "Well done. Anti-phishing policy exists and EnableUnauthenticatedSender is true"
            }else{
                $resultMarkdown += "Your tenant did not pass. "
            }

            Add-MtTestResultDetail -Result $resultMarkdown
        }

        if($null -ne $result) {
            $result | Should -Be $true -Because "Anti-phishing policy exists and EnableUnauthenticatedSender is true"
        }
    }
}
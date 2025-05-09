# Generated on 04/16/2025 21:38:23 by .\build\orca\Update-OrcaTests.ps1

using module ".\orcaClass.psm1"

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSPossibleIncorrectComparisonWithNull', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
param()


<#

233_1 - Check EF is turned on where MX not set to MDO

#>



class ORCA233_1 : ORCACheck
{
    <#
    
        CONSTRUCTOR with Check Header Data
    
    #>

    ORCA233_1()
    {
        $this.Control="233_1"
        $this.Area="Connectors"
        $this.Name="Enhanced Filtering Configuration"
        $this.PassText="Domains are pointed directly at EOP or enhanced filtering is configured on all default connectors"
        $this.FailRecommendation="Configure enhanced filtering on connectors when email path is not direct to EOP"
        $this.Importance="Exchange Online Protection (EOP) and Microsoft Defender for Office 365 works best when the mail exchange (MX) record is pointed directly at the service. <p>In the event another third-party service is being used, a very important signal (the senders IP address) is obfuscated and hidden from EOP & MDO, generating a larger quantity of false positives and false negatives. By configuring Enhanced Filtering with the IP addresses of these services the true senders IP address can be discovered, reducing the false-positive and false-negative impact.</p>"
        $this.ExpandResults=$True
        $this.CheckType=[CheckType]::ObjectPropertyValue
        $this.ObjectType="Connector"
        $this.ItemName="EF Mode"
        $this.DataType="SkipListed IPs"
        $this.Links= @{
            "Microsoft 365 Defender Portal - Enhanced Filtering"="https://aka.ms/orca-connectors-action-skiplisting"
            "Enhanced Filtering for Connectors"="https://aka.ms/orca-connectors-docs-1"
        }
    }

    <#
    
        RESULTS
    
    #>

    GetResults($Config)
    {

        $Connectors = @()

        # Analyze connectors
        ForEach($Connector in $($Config["InboundConnector"] | Where-Object {$_.Enabled}))
        {
            # Set regex options for later match
            $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase

            ForEach($senderdomain in $Connector.SenderDomains)
            {
                # Perform match on sender domain
                $match = [regex]::Match($senderdomain,"^smtp:\*;(\d*)$",$options)

                if($match.success)
                {
                    # Positive match
                    $Connectors += New-Object -TypeName PSObject -Property @{
                        Identity=$Connector.Identity
                        Priority=$($match.Groups[1].Value)
                        TlsSenderCertificateName=$Connector.TlsSenderCertificateName
                        EFTestMode=$Connector.EFTestMode
                        EFSkipLastIP=$Connector.EFSkipLastIP
                        EFSkipIPs=$Connector.EFSkipIPs
                        EFSkipMailGateway=$Connector.EFSkipMailGateway
                        EFUsers=$Connector.EFUsers
                    }
                }
            }

        }

        # Determine if skip listing is required
        $SkipListRequired = $False
        $NonEOPRecords = @($Config["MXReports"] | Where-Object {$_.PointsToService -eq $False})

        If($NonEOPRecords.Count -gt 0)
        {
            $SkipListRequired = $True
        }

        If($Connector.Count -eq 0 -and $SkipListRequired)
        {
            # No connectors so we should fail
            $ConfigObject = [ORCACheckConfig]::new()

            $ConfigObject.Object="No Connectors"
            $ConfigObject.ConfigItem = "-"
            $ConfigObject.ConfigData = "None"
            $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Fail")
            $this.AddConfig($ConfigObject)
        }

        # Add config data for each connector
        ForEach($Connector in $Connectors) 
        {

            # Construct config object

            $ConfigObject = [ORCACheckConfig]::new()

            $ConfigObject.Object=$($Connector.Identity)

            If($SkipListRequired)
            {
                If($Connector.EFSkipLastIP)
                {
                    $ConfigObject.ConfigItem = "Last IP"
                    $ConfigObject.ConfigData = "Last IP"
                } ElseIf($Connector.EFSkipIPs.Count -gt 0)
                {
                    $ConfigObject.ConfigItem = "Skip IPs"
                    $ConfigObject.ConfigData = $Connector.EFSkipIPs
                } Else
                {
                    $ConfigObject.ConfigItem = "Not Configured"
                    $ConfigObject.ConfigData = "None"
                }
    
                # Determine that EF is set to a mode, no test mode, and no select users
                If(($Connector.EFSkipLastIp -eq $True -or $Connector.EFSkipIPs.Count -gt 0) -and $Connector.EFTestMode -eq $False -and $Connector.EFUsers.Count -eq 0)
                {
                    $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Pass")
                }
                else
                {
                    $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Fail")
                }
    
                If($Connector.EFTestMode)
                {
                    $ConfigObject.ConfigItem += " (Test Mode)"
                }
    
                If($Connector.EFUsers.Count -gt 0)
                {
                    $ConfigObject.ConfigItem += " (Select Users)"
                }
            }
            else 
            {
                # Not required
                $ConfigObject.ConfigItem = "Not required"
                $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Pass")
            }

            $this.AddConfig($ConfigObject)

        }

    }

}

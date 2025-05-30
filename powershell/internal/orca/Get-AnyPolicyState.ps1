# Generated on 04/16/2025 21:38:23 by .\build\orca\Update-OrcaTests.ps1

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
param()

function Get-AnyPolicyState
{
    <#
    .SYNOPSIS
        Returns if any policy is enabled and applies
    #>

    Param(
        $PolicyStates
    )

    $ReturnVals = @{}
    $ReturnVals[[PolicyType]::Antiphish] = $False
    $ReturnVals[[PolicyType]::Malware] = $False
    $ReturnVals[[PolicyType]::Spam] = $False
    $ReturnVals[[PolicyType]::SafeAttachments] = $False
    $ReturnVals[[PolicyType]::SafeLinks] = $False

    foreach($Key in $PolicyStates.Keys)
    {

        if($PolicyStates[$Key].Type -eq [PolicyType]::Antiphish -and $PolicyStates[$Key].Applies)
        {
            $ReturnVals[[PolicyType]::Antiphish] = $True
        }

        if($PolicyStates[$Key].Type -eq [PolicyType]::Malware -and $PolicyStates[$Key].Applies)
        {
            $ReturnVals[[PolicyType]::Malware] = $True
        }

        if($PolicyStates[$Key].Type -eq [PolicyType]::Spam -and $PolicyStates[$Key].Applies)
        {
            $ReturnVals[[PolicyType]::Spam] = $True
        }

        if($PolicyStates[$Key].Type -eq [PolicyType]::SafeAttachments -and $PolicyStates[$Key].Applies)
        {
            $ReturnVals[[PolicyType]::SafeAttachments] = $True
        }

        if($PolicyStates[$Key].Type -eq [PolicyType]::SafeLinks -and $PolicyStates[$Key].Applies)
        {
            $ReturnVals[[PolicyType]::SafeLinks]  = $True
        }
    }

    return $ReturnVals;

}

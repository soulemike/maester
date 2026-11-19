function Test-MtCheckADGPOREP12 {
    <#
    .SYNOPSIS
    Inventories disabled GPO links.
    .DESCRIPTION
    Counts disabled links and lists their target policies and containers for review.
    .EXAMPLE
    Invoke-MtTest -Id AD-GPOREP-12
    Review disabled GPO links and their target containers manually.
    .LINK
    https://maester.dev/docs/tests/AD-GPOREP-12
    #>
    [MaesterTest(
        Id = 'AD-GPOREP-12',
        Title = 'Review disabled GPO links',
        Product = 'ad',
        Feature = 'group-policy',
        Area = 'infrastructure',
        ResourceType = 'GroupPolicy',
        Severity = 'Info',
        Mitre = 'None',
        Service = 'ActiveDirectory',
        Permission = ('ActiveDirectory:Ldap:groupPolicyContainer.gPCFileSysPath:ReadProperty', 'ActiveDirectory:File:SYSVOL:Read'),
        Author = 'soulemike'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return Test-MtAdGpoDisabledLinkCount
}

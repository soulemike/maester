function Clear-MtAdCache {
    [CmdletBinding()]
    param()
    $script:__MtSession.AdCache = @{}
}

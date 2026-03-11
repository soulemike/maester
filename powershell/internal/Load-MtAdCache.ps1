function Load-MtAdCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) { return @{} }
    $json = Get-Content -Path $Path -Raw
    return $json | ConvertFrom-Json -AsHashtable
}

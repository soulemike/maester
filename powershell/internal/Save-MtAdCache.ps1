function Save-MtAdCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter()]
        [hashtable]$Cache
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $Cache | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
}

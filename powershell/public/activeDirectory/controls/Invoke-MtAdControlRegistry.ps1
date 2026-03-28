function Invoke-MtAdControlRegistry {
    $controlPath = $PSScriptRoot

    $controlFiles = Get-ChildItem -Path $controlPath -Recurse -Filter "Invoke-MtAdControl_*.ps1" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "Invoke-MtAdControlRegistry.ps1" }

    if (-not $controlFiles) {
        return @()
    }
    $registry = @()

    foreach ($file in $controlFiles) {
        $functionName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

        $command = Get-Command $functionName -ErrorAction SilentlyContinue
        if (-not $command) {
            continue
        }

        $id = $functionName.Replace("Invoke-MtAdControl_","")
        $category = $file.Directory.Name

        $registry += @{
            Id           = $id
            Category     = $category
            Severity     = "Info"
            FunctionName = $functionName
        }
    }

    return $registry
}

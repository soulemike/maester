function Get-MtAdForest {
    [CmdletBinding()]
    param()

    $forestName = $null
    $domains    = @()
    $provider   = $null

    try {
        if (Get-Module -ListAvailable -Name ActiveDirectory) {
            Write-Verbose 'Using ActiveDirectory module for forest discovery.'
            Import-Module ActiveDirectory -ErrorAction Stop | Out-Null
            $adForest   = Get-ADForest -ErrorAction Stop
            $forestName = $adForest.Name
            $domains    = @($adForest.Domains)
            $provider   = 'ActiveDirectoryModule'
        }
    } catch {
        Write-Verbose ("ActiveDirectory module failed: {0}" -f $_.Exception.Message)
    }

    if (-not $provider) {
        try {
            Write-Verbose 'Falling back to System.DirectoryServices.'
            $dsForest   = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            $forestName = $dsForest.Name
            $domains    = @($dsForest.Domains | ForEach-Object { $_.Name })
            $provider   = 'DirectoryServices'
        } catch {
            Write-Verbose ("DirectoryServices discovery failed: {0}" -f $_.Exception.Message)
            $provider = 'DirectoryServices'
        }
    }

    $domains = @($domains | Where-Object { $_ })

    return @{
        Forest   = $forestName
        Domains  = [string[]]$domains
        Provider = $provider
    }
}

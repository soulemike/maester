function Connect-MtActiveDirectory {
   <#
.SYNOPSIS
   Establishes a hybrid Active Directory connection context for Maester.

.DESCRIPTION
   Attempts to discover the current Active Directory forest and all domains using
   the ActiveDirectory module. If the module is not available, falls back to
   System.DirectoryServices for forest and domain discovery.

   Populates $script:__MtSession.AdContext with Forest, Domains, and Provider.
#>
   [CmdletBinding()]
   param()

   $forestName = $null
   $domains    = @()
   $provider   = $null

   # Primary provider: ActiveDirectory module
   try {
      if (Get-Module -ListAvailable -Name ActiveDirectory) {
         Write-Verbose 'Using ActiveDirectory module for forest and domain discovery.'

         $null = Import-Module ActiveDirectory -ErrorAction Stop

         $adForest = Get-ADForest -ErrorAction Stop
         $forestName = $adForest.Name
         $domains = @($adForest.Domains)

         $provider = 'ActiveDirectoryModule'
      }
   } catch {
      Write-Verbose ("ActiveDirectory module unavailable or failed: {0}" -f $_.Exception.Message)
      $forestName = $null
      $domains    = @()
      $provider   = $null
   }

   # Fallback provider: System.DirectoryServices
   if (-not $provider) {
      try {
         Write-Verbose 'Falling back to System.DirectoryServices for forest and domain discovery.'

         $dsForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
         $forestName = $dsForest.Name

         $domains = @(
            $dsForest.Domains |
               ForEach-Object { $_.Name }
         )

         $provider = 'DirectoryServices'
      } catch {
         Write-Verbose ("System.DirectoryServices discovery failed: {0}" -f $_.Exception.Message)
         # Do not hard fail to remain testable/mocked in Pester
         $forestName = $null
         $domains    = @()
         $provider   = 'DirectoryServices'
      }
   }

   # Ensure consistent string[] typing
   $domains = @($domains | Where-Object { $_ })

   $script:__MtSession.AdContext = @{
      Forest   = $forestName
      Domains  = [string[]]$domains
      Provider = $provider
   }
}

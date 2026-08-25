## Execution strategy

- Updated `Invoke-LabAzCli` in the following scripts to replace the `& $azCommand.Source @Arguments 2>&1` / `$LASTEXITCODE` invocation with the provided `ProcessStartInfo` approach:
  - `build/activeDirectory/azure-lab/Deploy-Lab.ps1`
  - `build/activeDirectory/azure-lab/New-LabVNet.ps1`
  - `build/activeDirectory/azure-lab/New-DomainController.ps1`
  - `build/activeDirectory/azure-lab/New-RunnerVm.ps1`
  - `build/activeDirectory/azure-lab/Test-LabPrerequisites.ps1`
  - `build/activeDirectory/azure-lab/Remove-Lab.ps1`

## Verification

- PowerShell parser check (`Parser::ParseFile`) on all modified scripts: OK.
- Repo unit test suite: `pwsh -File ./powershell/tests/pester.ps1` completed with `All 10341 tests executed without a single failure!`.

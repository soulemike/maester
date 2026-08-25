# Active Directory Test Runner (Protocol-Based)

This folder contains scripts for running Maester Active Directory tests against a specific directory server endpoint and managing the resulting report artifacts.

## Protocol prerequisites (per TargetName / DirectoryServer)
Before running AD tests, validate that the runner can reach and negotiate the required protocols for the chosen directory server.

- LDAP: TCP/389
- LDAPS: TCP/636
- DNS: TCP/53
- SMB: TCP/445
- WinRM: TCP/5985 (HTTP) and TCP/5986 (HTTPS)

When using LDAPS / StartTLS and WinRM over HTTPS, ensure the runner trusts the server certificates.

## Single-target rule (recommended)
Run exactly one directory server per invocation:

1. Validate protocol prerequisites for a single server.
2. Connect to Active Directory via `Connect-Maester -Service ActiveDirectory`.
3. Run Maester AD tests (`Invoke-Maester -Tag AD -SkipGraphConnect -NonInteractive`).
4. Copy reports (the filename prefix includes your `TargetName`).

Do not loop over multiple `TargetName` values in a single run.

## Supported scripts

| Script | Purpose |
|---|---|
| `Test-ADProtocolPrerequisites.ps1` | Validates reachability and protocol/TLS/remoting prerequisites for one directory server. |
| `Run-ADTests-And-CopyReports.ps1` | Runs the Maester Active Directory test suite (tag `AD`) for one target and copies the generated report artifacts to `build/activeDirectory`. |

## Quick start

### 1) Validate prerequisites for one directory server

```powershell
./build/activeDirectory/Test-ADProtocolPrerequisites.ps1 -DirectoryServer 'misoule02.local'
```

### 2) Run one isolated AD test cycle and copy reports

```powershell
./build/activeDirectory/Run-ADTests-And-CopyReports.ps1 -ConnectActiveDirectory -TargetName 'misoule02.local'
```

Optional export formats:

```powershell
./build/activeDirectory/Run-ADTests-And-CopyReports.ps1 -ConnectActiveDirectory -TargetName 'misoule02.local' -ExportCsv -ExportExcel
```

The copied artifacts use the naming convention:

`AD-TestResults-{TargetName}-{timestamp}`

## Build guidance

- Run the commands from the repository root (or adjust relative paths).
- Ensure you can import the Maester module (`Maester.psd1`) from the `-MaesterModulePath` used by the runner.
- In CI, prefer one job per `TargetName` so each test cycle is isolated and produces unambiguous artifacts.

## Retired scripts
The legacy validation scripts below are retired in favor of the protocol-based workflow:

- `Validate-Phase7-GPO.ps1`
- `Validate-Phase7-Simple.ps1`
- `validate-dns-tests.ps1`
- `validate-dns-tests-v2.ps1`
- `Standalone-Phase19-Validation.ps1`
- `Simple-Validate-Phase19.ps1`
- `Validate-Phase19-GPOState.ps1`

## Troubleshooting

- **TLS/Certificate failures**: confirm LDAPS/StartTLS and WinRM HTTPS certificates are trusted by the runner.
- **Timeouts / connection refused**: confirm firewall rules allow TCP/389, TCP/636, TCP/53, TCP/445, and TCP/5985-5986 to the runner.
- **Authentication/authorization failures**: ensure your session account can read the AD objects required by the tests.
- **No reports generated**: verify the output folder and check for artifacts with prefix `AD-TestResults-{TargetName}-...`.

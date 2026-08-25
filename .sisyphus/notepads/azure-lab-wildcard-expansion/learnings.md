## Azure CLI wildcard expansion fix (Linux)

- When invoking external commands from PowerShell on Linux, the call operator (`&`) can trigger wildcard expansion for arguments like `*` (e.g., `--protocol *`), causing Azure CLI to receive invalid values.
- Building a `System.Diagnostics.ProcessStartInfo` and executing via `System.Diagnostics.Process::Start()` with redirected stdout/stderr avoids shell wildcard expansion.

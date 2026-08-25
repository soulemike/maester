# Maester AD E2E Test Report

**Date:** 2026-08-21
**Lab:** RG_5100_MiSoule_2
**Test Framework:** Maester v2.2.0

## Test Execution Summary

| Domain | Forest | DC VM | Total | Passed | Failed | Skipped |
|--------|--------|-------|-------|--------|--------|---------|
| misoule02.local | Forest 1 | MiSouleDC02 | 708 | 241 | 29 | 0 |
| child.misoule02.local | Forest 1 | MiSouleDC03 | 708 | 241 | 29 | 0 |
| misoule03.local | Forest 2 | MiSouleDC04 | 708 | 241 | 29 | 0 |

## Key Findings

### Consistent Results Across Domains
All three domains (root, child, and separate forest) produced identical test results:
- **241 Passed** (34% pass rate)
- **29 Failed** (4% failure rate)
- **438 Not Run** (62% - tests requiring Graph/Entra connectivity)

### Failed Tests (Consistent Across All Domains)

The 29 failed tests are primarily configuration retrieval tests that return `null`:

**AD Configuration (AD-CFG-*) - 24 failures:**
- Tombstone lifetime, dSHeuristics, SPN mappings
- LDAP query policies, AuthN policies, AD activation objects
- Well-known security principals, registered DHCP servers
- Enterprise CA, certificate templates, enrollment templates
- Trusted root CAs, intermediate CAs, CRL distribution points
- NTAuth certificates, KDS root keys, SMTP/IP site links

**Fine-Grained Password Policies (AD-FGPP-*) - 4 failures:**
- Policy count, value count, setting counts, application targets

**Other (1 failure each):**
- AD-GPOL-03: GPO unlinked target count
- AD-PRINT-01: Printer total count
- AD-SCH-05: LAPS installation status

### Root Cause Analysis

All 29 failures share the same pattern: the test queries return `null` instead of expected values. This indicates:

1. **Missing optional features:** Many tests query for enterprise features (CA, DHCP, LAPS) that are not installed in the lab environment
2. **Empty configurations:** Fine-grained password policies and some site link configurations may not be configured by default
3. **Permission/scope issues:** Some configuration objects may require elevated permissions or specific forest functional levels

## Infrastructure Status

| Component | Status | Notes |
|-----------|--------|-------|
| MiSouleDC02 (misoule02.local) | ✅ Operational | Root forest DC |
| MiSouleDC03 (child.misoule02.local) | ✅ Operational | Child domain DC - promoted via domain-join-first approach |
| MiSouleDC04 (misoule03.local) | ✅ Operational | Separate forest DC |
| MiSouleRunW | ✅ Operational | Windows runner |
| MiSouleRunnerLinux | ✅ Operational | Linux runner with SSH capabilities |

## Report Files

Detailed reports are available in `evidence/reports/`:

| File | Description |
|------|-------------|
| DC02-misoule02-SUMMARY.txt | Summary for misoule02.local |
| DC02-misoule02-FAILED.txt | Failed tests for misoule02.local |
| DC03-child-SUMMARY.txt | Summary for child.misoule02.local |
| DC03-child-FAILED.txt | Failed tests for child.misoule02.local |
| DC04-misoule03-SUMMARY.txt | Summary for misoule03.local |
| DC04-misoule03-FAILED.txt | Failed tests for misoule03.local |

**Note:** Full HTML/JSON/Markdown reports (4MB each) remain on the DC VMs in `C:\MaesterReports\` due to size constraints for transfer via Azure VM Run Command.

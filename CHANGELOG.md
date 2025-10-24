<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

# Changelog

Changes to the [USP Killercoda](https://killercoda.com/united-security-providers) scenarios using [common-changelog.org](https://common-changelog.org/) format.

## [2025-43] - 2025-10-23

- Added scenario `USP Core WAAP GraphQL`

## [2025-42] - 2025-10-10

### Changed

- Updated all scenarios to use [Helm chart version 1.4.0](https://docs.united-security-providers.ch/usp-core-waap/)

## [2025-35] - 2025-08-26

- Updated scenario `USP Core WAAP demo` to improve wording about accessing the Juice Shop app initially

## [2025-34] - 2025-08-22

### Changed

- Updated scenario `USP Core WAAP demo` to fix an SQLite specific injection

## [2025-33] - 2025-08-14

### Added

- Added scenario `USP Core WAAP header filtering`

### Changed

- Updated scenario `USP Core WAAP csrf protection` to fix OWASP Juice Shop achievement shown (unlinked to scenario)

## [2025-32] - 2025-08-04

### Changed

- Updated all scenarios to use [Helm chart version 1.3.0](https://docs.united-security-providers.ch/usp-core-waap/)

## [2025-05] - 2025-01-29

### Added

- Added scenario `USP Core WAAP csrf protection`

## [2025-04] - 2025-01-20

### Changed

- Updated scenario `USP Core WAAP demo` to use Helm chart version 1.2.0
- Updated scenario `USP Core WAAP manual configuration tuning` to use Helm chart version 1.2.0
- Updated scenario `USP Core WAAP automatic configuration tuning` to use Helm chart version 1.2.0
- Updated scenario `USP Core WAAP information leakage prevention` to use Helm chart version 1.2.0

### Fixed

- Updated scenario `USP Core WAAP automatic configuration tuning` to use [Auto-Learning tool](https://docs.united-security-providers.ch/usp-core-waap/downloads/) in version 1.1.0 (1.0.1 no longer available)

## [2025-03] - 2025-01-17

### Added

- Added scenario `USP Core WAAP Virtual Patch`
- Added scenario `USP Core WAAP OpenAPI validation`

## [2024-51] - 2024-12-17

### Changed

- Changed image URL path accessing `/demo/` repository path (redmine#290297)

### Fixed

- Fixed missing `websocket: true` Core WAAP config for added scenarios in `2024-49` release

## [2024-49] - 2024-12-04

### Changed

- Updated scenario `USP Core WAAP demo` title (previously `USP Core WAAP basic demo`), fixed typos and added icon conventions as well as overview sections in each step

### Added

- Added scenario `USP Core WAAP manual configuration tuning`
- Added scenario `USP Core WAAP automatic configuration tuning`
- Added scenario `USP Core WAAP information leakage prevention`
- Added `structure.json` to control order of scenario list

### Removed

- Removed scenario `Juice Shop` (reason not a USP specific product / feature demo)

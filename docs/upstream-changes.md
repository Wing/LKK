# Imported source changes

Upstream: YahooArchive/KeyKey at the revision in vendor/PROVENANCE.json.

- Normalize legacy source indentation and trailing whitespace.
- Replace umbrella includes with a minimal header set for standalone C++ builds.
- Remove unused CIN/file-service includes from OVDatabaseService.h; retain its interfaces.
- Exclude generated pronunciation-alias data and provide an empty alias map.
- Link ordinary system SQLite and libc++; no crypto-extension stubs are provided.
- Memoize Manjusri fast-walk states within each traversal to avoid repeated suffix evaluation on long compositions; scoring and tie ordering remain unchanged.
- Keep Formosa phonetic parsing and the Manjusri graph, scoring and backoff implementation.

New platform and persistence adapters are maintained in Sources/. Generated assets, dictionary outputs and build logs are excluded from source control.

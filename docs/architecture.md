# Architecture

LKK retains the BSD-licensed Manjusri graph and language model from KeyKey and the MIT-licensed Formosa phonetic parser. A new InputMethodKit adapter and SQLite-backed storage replace legacy platform integration. Upstream files are listed in vendor/PROVENANCE.json. Generated pronunciation aliases and historical databases are excluded.

The initial public model uses separately licensed vocabulary with an empty static bigram table. Manjusri backoff remains active. Candidate overrides are persisted separately. This is not an exact reproduction of the historical statistical model. Only standard-layout smart Bopomofo is currently exposed; unsupported modes are not advertised.

The app does not use global keyboard hooks, Accessibility access, network services, or historical vendor endpoints. User storage is isolated from legacy input methods. No personal dictionary migration is performed automatically.

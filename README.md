# LKK input method

An experimental, native Apple-silicon Bopomofo input method for macOS. LKK retains the Manjusri composition engine from the BSD-licensed KeyKey source and uses a new InputMethodKit adapter with a reproducible public dictionary.

## Status

Development preview. Standard-layout smart Bopomofo, composition editing, numbered candidate selection, candidate paging, persistent candidate preferences, and manual phrase addition are implemented. Static bigrams are not included in the replacement dictionary. Historical candidate ranking is not reproduced exactly. Traditional Bopomofo, Cangjie, Simplex, legacy service integrations, and automatic personal-dictionary migration are not currently supported. The application is ad-hoc signed, not Developer ID signed or notarized.

## Build and test

Requires macOS 14 or later on Apple silicon, Apple Command Line Tools (or Xcode), and Python 3.9 or later. Full UI compatibility is verified separately from engine tests.

```sh
bash scripts/test.sh
bash scripts/build.sh
```

The build downloads only checksum-pinned public dictionary inputs. Output: `build/LKK.app`. No commercial SQLite extension or historical database is required. First build requires network access. Source and data provenance are in `vendor/PROVENANCE.json`, `Resources/data-sources.json`, `NOTICE`, and `Licenses/`.

## Local installation

After reviewing the development-preview limitations, run:

```sh
bash scripts/install.sh
```

Then log out and back in if needed. Add **LKK** under System Settings → Keyboard → Text Input → Edit → Traditional Chinese. The installer uses the current user's Input Methods directory, refuses an existing installation, and does not modify other input methods. To remove LKK, first remove it from the input-source list, log out, and remove `~/Library/Input Methods/LKK.app`. Personal data is stored separately under `~/Library/Application Support/LKK`; it is not removed automatically.

Space opens candidates after a completed reading; 1–9 select candidates, arrows navigate, Space/Page Down advance pages, Escape closes candidates, and Enter commits composition. Caps Lock and system input-source switching remain available. Control, Option, and Command combinations are passed through after committing composition. Punctuation uses literal passthrough in this preview; legacy punctuation shortcuts remain a compatibility task.

Use the input-source menu → LKK settings to add a phrase using readings separated by `-` (for example `ㄋㄧˇ-ㄏㄠˇ`). No existing personal dictionary is read automatically.

## License

New code is BSD-3-Clause. Imported files retain their original BSD or MIT notices. Dictionary data carries separate upstream MIT attribution. LKK is independent and is not endorsed by Yahoo or upstream contributors. See [architecture](docs/architecture.md) and [release checklist](docs/release-checklist.md).

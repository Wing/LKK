#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
import json,pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
provenance=json.loads((ROOT/'vendor/PROVENANCE.json').read_text())
for entry in provenance['files']:
    text=(ROOT/entry['path']).read_text()
    assert 'Permission is hereby granted' in text or 'New BSD License' in text,entry['path']
for path in ROOT.rglob('*'):
    if not path.is_file() or any(p in ['.git','build'] for p in path.relative_to(ROOT).parts):continue
    assert path.suffix.lower() not in ['.db','.sqlite','.sqlite3','.db3','.dmg','.pkg','.p12','.pem','.key'],str(path)
print('Source attribution and excluded-asset audit passed')

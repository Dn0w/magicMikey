#!/usr/bin/env python3
"""
Generate magicMice/Resources/pinyin.db from Google PinyinIME's rawdict.

Dictionary source: rawdict_utf16_65105_freq.txt
  Apache License 2.0 — The Android Open Source Project / Google
  Mirror: https://github.com/libpinyin/ibus-libpinyin/blob/main/data/db/android/rawdict_utf16_65105_freq.txt

Schema:
  candidates(syllable TEXT, character TEXT, frequency INTEGER, script TEXT)
  script = 'hans' (Simplified) or 'hant' (Traditional)
  frequency = rank (0 = most common; lower = higher priority)

Index: idx_syllable ON candidates(syllable, script, frequency)
"""

import sqlite3
import os
import urllib.request

try:
    import opencc
    _cc = opencc.OpenCC("s2t")
    def to_trad(s: str) -> str:
        return _cc.convert(s)
    print("Using opencc for Simplified→Traditional conversion.")
except ImportError:
    print("opencc not found — Traditional Chinese will mirror Simplified.")
    def to_trad(s: str) -> str:
        return s

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
RAWDICT     = os.path.join(SCRIPT_DIR, "rawdict_utf16_65105_freq.txt")
RAWDICT_URL = ("https://raw.githubusercontent.com/libpinyin/ibus-libpinyin/"
               "main/data/db/android/rawdict_utf16_65105_freq.txt")

DB_PATH = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "magicMice", "Resources", "pinyin.db"))

# ---------------------------------------------------------------------------
# Download rawdict if missing
# ---------------------------------------------------------------------------

if not os.path.exists(RAWDICT):
    print(f"Downloading rawdict from GitHub…")
    urllib.request.urlretrieve(RAWDICT_URL, RAWDICT)
    print("Done.")

# ---------------------------------------------------------------------------
# Parse rawdict
# Format per line:  <characters> <freq_float> <flag> <pinyin syllables…>
# Higher freq_float = more common.
# ---------------------------------------------------------------------------

MIN_FREQ = 10.0   # Skip very rare/obscure entries (keeps DB smaller)
MAX_CHARS = 6     # Skip phrases longer than 6 characters (uncommon in typing)

print(f"Parsing rawdict…")
entries = []   # list of (hanzi, pinyin_no_spaces, freq_float)

with open(RAWDICT, encoding="utf-16") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) < 4:
            continue
        hanzi  = parts[0]
        try:
            freq = float(parts[1])
        except ValueError:
            continue
        # parts[2] is a flag (0 or 1), parts[3..] are pinyin syllables
        pinyin = "".join(parts[3:])   # concatenate: "ni hao" → "nihao"

        if freq < MIN_FREQ:
            continue
        if len(hanzi) > MAX_CHARS:
            continue

        entries.append((hanzi, pinyin, freq))

print(f"Loaded {len(entries):,} entries after filtering.")

# Sort by frequency descending, assign integer rank (0 = most common)
entries.sort(key=lambda x: x[2], reverse=True)

# ---------------------------------------------------------------------------
# Build SQLite DB
# ---------------------------------------------------------------------------

if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

conn = sqlite3.connect(DB_PATH)
c = conn.cursor()

c.execute("""
    CREATE TABLE candidates (
        syllable  TEXT NOT NULL,
        character TEXT NOT NULL,
        frequency INTEGER NOT NULL,
        script    TEXT NOT NULL
    )
""")

rows = []
seen_hans: set[tuple[str, str]] = set()
seen_hant: set[tuple[str, str]] = set()

for rank, (hanzi, pinyin, _freq) in enumerate(entries):
    # Simplified
    key_s = (pinyin, hanzi)
    if key_s not in seen_hans:
        seen_hans.add(key_s)
        rows.append((pinyin, hanzi, rank, "hans"))

    # Traditional
    trad = to_trad(hanzi)
    key_t = (pinyin, trad)
    if key_t not in seen_hant:
        seen_hant.add(key_t)
        rows.append((pinyin, trad, rank, "hant"))

c.executemany(
    "INSERT INTO candidates (syllable, character, frequency, script) VALUES (?, ?, ?, ?)",
    rows
)

c.execute("CREATE INDEX idx_syllable ON candidates(syllable, script, frequency)")

conn.commit()
conn.close()

size_kb = os.path.getsize(DB_PATH) / 1024
print(f"Inserted {len(rows):,} rows ({len(rows)//2:,} entries × 2 scripts).")
print(f"DB size: {size_kb:.0f} KB  ({size_kb/1024:.1f} MB)")
print(f"Written to: {DB_PATH}")

#!/usr/bin/env python3
"""
build_packs.py — Download Rime schemas + jQuery.IME rules, package as zips,
                 and upload to a GitHub release.

Usage:
    python3 scripts/build_packs.py [--release packs-v1] [--repo Dn0w/magicMikey]

Requires:
    - Python 3.9+
    - gh CLI installed and authenticated  (brew install gh)
    - curl (ships with macOS)
"""

import argparse, json, os, shutil, subprocess, sys, tempfile, urllib.request, zipfile
from pathlib import Path
from typing import Optional, List

# ─── Config ───────────────────────────────────────────────────────────────────

RELEASE_TAG  = "packs-v1"
GITHUB_REPO  = "Dn0w/magicMikey"
RIME_RAW     = "https://raw.githubusercontent.com/rime/{repo}/master/{file}"
OPENCC_RAW   = "https://raw.githubusercontent.com/BYVoid/OpenCC/master/data/config/{file}"

# OpenCC compiled data files (pre-built binaries included in the rime-prebuilt release)
OPENCC_RELEASE = "https://github.com/rime/rime-prebuilt/releases/latest/download/rime-data.zip"

# ─── File manifests per pack ───────────────────────────────────────────────────

# Each entry: (source_repo_or_url, filename_in_repo, dest_filename_in_zip)
# source_repo: "rime-NAME" → fetched from github.com/rime/rime-NAME
#              "opencc"    → fetched from BYVoid/OpenCC
#              "url:..."   → raw URL

RIME_PACKS = {
    "rime-luna-pinyin": {
        "schema_id": "luna_pinyin",
        "files": [
            ("rime-luna-pinyin",  "luna_pinyin.schema.yaml",  None),
            ("rime-luna-pinyin",  "luna_pinyin.dict.yaml",    None),
            ("rime-stroke",       "stroke.dict.yaml",         None),
        ],
    },
    "rime-luna-pinyin-tw": {
        "schema_id": "luna_pinyin_tw",
        "files": [
            ("rime-luna-pinyin",  "luna_pinyin.schema.yaml",     None),
            ("rime-luna-pinyin",  "luna_pinyin_tw.schema.yaml",  None),
            ("rime-luna-pinyin",  "luna_pinyin.dict.yaml",       None),
            ("rime-stroke",       "stroke.dict.yaml",            None),
            # OpenCC: traditional → Taiwan
            ("opencc",            "t2tw.json",                   None),
        ],
        "opencc_sets": ["t2tw"],
    },
    "rime-bopomofo": {
        "schema_id": "bopomofo",
        "files": [
            ("rime-bopomofo",     "bopomofo.schema.yaml",        None),
            ("rime-terra-pinyin", "terra_pinyin.dict.yaml",      None),
            ("rime-stroke",       "stroke.dict.yaml",            None),
            ("opencc",            "t2s.json",                    None),
            ("opencc",            "t2tw.json",                   None),
        ],
        "opencc_sets": ["t2s", "t2tw"],
    },
    "rime-cangjie": {
        "schema_id": "cangjie5",
        "files": [
            ("rime-cangjie",      "cangjie5.schema.yaml",        None),
            ("rime-cangjie",      "cangjie5.dict.yaml",          None),
            ("rime-luna-pinyin",  "luna_pinyin.dict.yaml",       None),
        ],
    },
    "rime-wubi": {
        "schema_id": "wubi86",
        "files": [
            ("rime-wubi",         "wubi86.schema.yaml",          None),
            ("rime-wubi",         "wubi86.dict.yaml",            None),
            # wubi reverse-lookup uses pinyin_simp
            ("rime-pinyin-simp",  "pinyin_simp.dict.yaml",       None),
            ("rime-pinyin-simp",  "pinyin_simp.schema.yaml",     None),
        ],
    },
    "rime-jyutping": {
        "schema_id": "jyutping",
        "files": [
            ("rime-jyutping",     "jyutping.schema.yaml",        None),
            ("rime-jyutping",     "jyutping.dict.yaml",          None),
            ("rime-luna-pinyin",  "luna_pinyin.dict.yaml",       None),
            ("rime-stroke",       "stroke.dict.yaml",            None),
            ("rime-cangjie",      "cangjie5.dict.yaml",          None),
        ],
    },
}

# OpenCC data files needed per conversion set.
# These are fetched from github.com/BYVoid/OpenCC/data/dictionary/
OPENCC_DATA_FILES = {
    "t2s":  ["STCharacters.txt",  "STPhrases.txt"],
    "t2tw": ["TWVariants.txt",    "TWPhrases.txt"],
}

# ─── jQuery.IME transliteration packs ─────────────────────────────────────────
# Rules are simplified Latin→script mappings.
# Full rules can be imported from https://github.com/wikimedia/jquery.ime

IME_PACKS = {
    "ime-arabic": {
        "label":  "Arabic",
        "schema": "ime-arabic",
        "rules":  [
            # Consonants
            {"from": "b",  "to": "ب"}, {"from": "t",  "to": "ت"},
            {"from": "th", "to": "ث"}, {"from": "j",  "to": "ج"},
            {"from": "H",  "to": "ح"}, {"from": "kh", "to": "خ"},
            {"from": "d",  "to": "د"}, {"from": "dh", "to": "ذ"},
            {"from": "r",  "to": "ر"}, {"from": "z",  "to": "ز"},
            {"from": "s",  "to": "س"}, {"from": "sh", "to": "ش"},
            {"from": "S",  "to": "ص"}, {"from": "D",  "to": "ض"},
            {"from": "T",  "to": "ط"}, {"from": "Z",  "to": "ظ"},
            {"from": "3",  "to": "ع"}, {"from": "gh", "to": "غ"},
            {"from": "f",  "to": "ف"}, {"from": "q",  "to": "ق"},
            {"from": "k",  "to": "ك"}, {"from": "l",  "to": "ل"},
            {"from": "m",  "to": "م"}, {"from": "n",  "to": "ن"},
            {"from": "h",  "to": "ه"}, {"from": "w",  "to": "و"},
            {"from": "y",  "to": "ي"}, {"from": "2",  "to": "ء"},
            # Vowels / long vowels
            {"from": "aa", "to": "ا"}, {"from": "a",  "to": "ا"},
            {"from": "ee", "to": "ي"}, {"from": "oo", "to": "و"},
            {"from": "u",  "to": "و"}, {"from": "i",  "to": "ي"},
            {"from": "e",  "to": "ه"},
            # Common
            {"from": "p",  "to": "ب"}, {"from": "g",  "to": "ج"},
            {"from": "v",  "to": "ف"},
        ],
    },
    "ime-hindi": {
        "label":  "Hindi",
        "schema": "ime-hindi",
        "rules":  [
            # Vowels
            {"from": "a",  "to": "अ"}, {"from": "aa", "to": "आ"},
            {"from": "i",  "to": "इ"}, {"from": "ii", "to": "ई"},
            {"from": "u",  "to": "उ"}, {"from": "uu", "to": "ऊ"},
            {"from": "e",  "to": "ए"}, {"from": "ai", "to": "ऐ"},
            {"from": "o",  "to": "ओ"}, {"from": "au", "to": "औ"},
            {"from": "ri", "to": "ऋ"}, {"from": "am", "to": "अं"},
            {"from": "ah", "to": "अः"},
            # Consonants
            {"from": "k",  "to": "क"}, {"from": "kh", "to": "ख"},
            {"from": "g",  "to": "ग"}, {"from": "gh", "to": "घ"},
            {"from": "ng", "to": "ङ"}, {"from": "ch", "to": "च"},
            {"from": "chh","to": "छ"}, {"from": "j",  "to": "ज"},
            {"from": "jh", "to": "झ"}, {"from": "T",  "to": "ट"},
            {"from": "Th", "to": "ठ"}, {"from": "D",  "to": "ड"},
            {"from": "Dh", "to": "ढ"}, {"from": "N",  "to": "ण"},
            {"from": "t",  "to": "त"}, {"from": "th", "to": "थ"},
            {"from": "d",  "to": "द"}, {"from": "dh", "to": "ध"},
            {"from": "n",  "to": "न"}, {"from": "p",  "to": "प"},
            {"from": "ph", "to": "फ"}, {"from": "b",  "to": "ब"},
            {"from": "bh", "to": "भ"}, {"from": "m",  "to": "म"},
            {"from": "y",  "to": "य"}, {"from": "r",  "to": "र"},
            {"from": "l",  "to": "ल"}, {"from": "v",  "to": "व"},
            {"from": "sh", "to": "श"}, {"from": "Sh", "to": "ष"},
            {"from": "s",  "to": "स"}, {"from": "h",  "to": "ह"},
            {"from": "ksh","to": "क्ष"},{"from": "tr", "to": "त्र"},
            {"from": "gya","to": "ज्ञ"},
        ],
    },
    "ime-greek": {
        "label":  "Greek",
        "schema": "ime-greek",
        "rules":  [
            # ISO 843 transliteration
            {"from": "th", "to": "θ"}, {"from": "Th", "to": "Θ"},
            {"from": "ch", "to": "χ"}, {"from": "Ch", "to": "Χ"},
            {"from": "ph", "to": "φ"}, {"from": "Ph", "to": "Φ"},
            {"from": "ps", "to": "ψ"}, {"from": "Ps", "to": "Ψ"},
            {"from": "a",  "to": "α"}, {"from": "A",  "to": "Α"},
            {"from": "b",  "to": "β"}, {"from": "B",  "to": "Β"},
            {"from": "g",  "to": "γ"}, {"from": "G",  "to": "Γ"},
            {"from": "d",  "to": "δ"}, {"from": "D",  "to": "Δ"},
            {"from": "e",  "to": "ε"}, {"from": "E",  "to": "Ε"},
            {"from": "z",  "to": "ζ"}, {"from": "Z",  "to": "Ζ"},
            {"from": "ee", "to": "η"}, {"from": "EE", "to": "Η"},
            {"from": "i",  "to": "ι"}, {"from": "I",  "to": "Ι"},
            {"from": "k",  "to": "κ"}, {"from": "K",  "to": "Κ"},
            {"from": "l",  "to": "λ"}, {"from": "L",  "to": "Λ"},
            {"from": "m",  "to": "μ"}, {"from": "M",  "to": "Μ"},
            {"from": "n",  "to": "ν"}, {"from": "N",  "to": "Ν"},
            {"from": "x",  "to": "ξ"}, {"from": "X",  "to": "Ξ"},
            {"from": "o",  "to": "ο"}, {"from": "O",  "to": "Ο"},
            {"from": "p",  "to": "π"}, {"from": "P",  "to": "Π"},
            {"from": "r",  "to": "ρ"}, {"from": "R",  "to": "Ρ"},
            {"from": "s",  "to": "σ"}, {"from": "S",  "to": "Σ"},
            {"from": "t",  "to": "τ"}, {"from": "T",  "to": "Τ"},
            {"from": "y",  "to": "υ"}, {"from": "Y",  "to": "Υ"},
            {"from": "oo", "to": "ω"}, {"from": "OO", "to": "Ω"},
            {"from": "h",  "to": "η"}, {"from": "H",  "to": "Η"},
            {"from": "u",  "to": "υ"}, {"from": "U",  "to": "Υ"},
            {"from": "v",  "to": "β"}, {"from": "V",  "to": "Β"},
            {"from": "f",  "to": "φ"}, {"from": "F",  "to": "Φ"},
            {"from": "c",  "to": "κ"}, {"from": "C",  "to": "Κ"},
            {"from": "q",  "to": "κ"}, {"from": "Q",  "to": "Κ"},
            {"from": "w",  "to": "ω"}, {"from": "W",  "to": "Ω"},
        ],
    },
}

# ─── Helpers ───────────────────────────────────────────────────────────────────

def fetch(url: str, dest: Path, label: str = "") -> bool:
    """Download url → dest. Returns True on success."""
    try:
        print(f"  ↓ {label or url}")
        with urllib.request.urlopen(url, timeout=30) as resp, open(dest, "wb") as f:
            f.write(resp.read())
        return True
    except Exception as ex:
        print(f"  ✗ FAILED ({ex}): {url}")
        return False


def rime_url(repo: str, filename: str) -> str:
    """Return raw GitHub URL for a file in a rime/* repo."""
    return f"https://raw.githubusercontent.com/rime/{repo}/master/{filename}"


def opencc_url(filename: str) -> str:
    return f"https://raw.githubusercontent.com/BYVoid/OpenCC/master/data/config/{filename}"


def opencc_dict_url(filename: str) -> str:
    return f"https://raw.githubusercontent.com/BYVoid/OpenCC/master/data/dictionary/{filename}"


def gh(*args) -> subprocess.CompletedProcess:
    return subprocess.run(["gh", *args], capture_output=True, text=True)


def ensure_release(tag: str, repo: str):
    """Create GitHub release if it doesn't exist."""
    r = gh("release", "view", tag, "--repo", repo)
    if r.returncode == 0:
        print(f"✓ Release {tag} already exists")
        return
    print(f"Creating release {tag}…")
    subprocess.run(
        ["gh", "release", "create", tag,
         "--repo", repo,
         "--title", f"Language Packs ({tag})",
         "--notes", "Downloadable input method packs for magicMikey.",
         "--prerelease"],
        check=True,
    )


def upload_asset(path: Path, tag: str, repo: str):
    """Upload a file as a release asset, replacing if it already exists."""
    print(f"  ↑ Uploading {path.name}…")
    # Delete first to allow re-upload
    gh("release", "delete-asset", tag, path.name, "--repo", repo, "--yes")
    r = subprocess.run(
        ["gh", "release", "upload", tag, str(path),
         "--repo", repo, "--clobber"],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        print(f"  ✗ Upload failed: {r.stderr.strip()}")
    else:
        print(f"  ✓ {path.name}")


# ─── Build Rime packs ──────────────────────────────────────────────────────────

def build_rime_pack(pack_id: str, spec: dict, work_dir: Path, out_dir: Path) -> Optional[Path]:
    print(f"\n▸ Building {pack_id}…")
    pack_dir = work_dir / pack_id
    pack_dir.mkdir(parents=True, exist_ok=True)

    ok = True
    for (source, filename, dest_name) in spec["files"]:
        dest = pack_dir / (dest_name or filename)
        if source.startswith("rime-"):
            repo = source  # e.g. "rime-luna-pinyin"
            url  = rime_url(repo, filename)
        elif source == "opencc":
            url = opencc_url(filename)
        elif source.startswith("url:"):
            url = source[4:]
        else:
            print(f"  ? Unknown source: {source}")
            continue
        if not fetch(url, dest, filename):
            ok = False

    # Download OpenCC dictionary data files (plain-text, compiled by librime at runtime)
    for occ_set in spec.get("opencc_sets", []):
        for data_file in OPENCC_DATA_FILES.get(occ_set, []):
            dest = pack_dir / data_file
            url  = opencc_dict_url(data_file)
            if not fetch(url, dest, data_file):
                ok = False

    if not ok:
        print(f"  ⚠ Some files failed — zip will be incomplete")

    # Create zip
    zip_path = out_dir / f"{pack_id}.zip"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for f in sorted(pack_dir.iterdir()):
            zf.write(f, f.name)
    size_mb = zip_path.stat().st_size / 1_048_576
    print(f"  ✓ {zip_path.name} ({size_mb:.1f} MB)")
    return zip_path


# ─── Build IME transliteration packs ──────────────────────────────────────────

def build_ime_pack(pack_id: str, spec: dict, work_dir: Path, out_dir: Path) -> Path:
    print(f"\n▸ Building {pack_id}…")
    schema_id = spec["schema"]

    # Write rule JSON: [{from, to}, ...]
    rules = spec["rules"]
    rule_json = json.dumps(rules, ensure_ascii=False, indent=2)

    pack_dir = work_dir / pack_id
    pack_dir.mkdir(parents=True, exist_ok=True)
    rule_file = pack_dir / f"{schema_id}.json"
    rule_file.write_text(rule_json, encoding="utf-8")
    print(f"  ✓ {rule_file.name} ({len(rules)} rules)")

    zip_path = out_dir / f"{pack_id}.zip"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.write(rule_file, rule_file.name)
    size_kb = zip_path.stat().st_size / 1024
    print(f"  ✓ {zip_path.name} ({size_kb:.0f} KB)")
    return zip_path


# ─── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--release", default=RELEASE_TAG)
    parser.add_argument("--repo",    default=GITHUB_REPO)
    parser.add_argument("--packs",   nargs="*",
                        help="Build only these pack IDs (default: all)")
    parser.add_argument("--no-upload", action="store_true",
                        help="Build zips locally but skip GitHub upload")
    args = parser.parse_args()

    # Verify gh is available
    if subprocess.run(["which", "gh"], capture_output=True).returncode != 0:
        sys.exit("✗ 'gh' CLI not found. Install with: brew install gh")
    if subprocess.run(["gh", "auth", "status"], capture_output=True).returncode != 0:
        sys.exit("✗ 'gh' not authenticated. Run: gh auth login")

    with tempfile.TemporaryDirectory() as tmp:
        work_dir = Path(tmp) / "work"
        out_dir  = Path(tmp) / "out"
        work_dir.mkdir(); out_dir.mkdir()

        # Ensure release exists before uploading
        if not args.no_upload:
            ensure_release(args.release, args.repo)

        built: List[Path] = []

        # Build Rime packs
        for pack_id, spec in RIME_PACKS.items():
            if args.packs and pack_id not in args.packs:
                continue
            path = build_rime_pack(pack_id, spec, work_dir, out_dir)
            if path:
                built.append(path)

        # Build IME packs
        for pack_id, spec in IME_PACKS.items():
            if args.packs and pack_id not in args.packs:
                continue
            path = build_ime_pack(pack_id, spec, work_dir, out_dir)
            built.append(path)

        # Upload
        if not args.no_upload:
            print(f"\n▸ Uploading {len(built)} pack(s) to {args.repo} @ {args.release}…")
            for path in built:
                upload_asset(path, args.release, args.repo)
        else:
            # Copy to local ./packs/dist/ for inspection
            dist = Path("packs/dist")
            dist.mkdir(parents=True, exist_ok=True)
            for path in built:
                shutil.copy(path, dist / path.name)
            print(f"\n✓ Zips saved to packs/dist/ (--no-upload mode)")

    print("\n✓ Done.")


if __name__ == "__main__":
    main()

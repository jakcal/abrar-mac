#!/usr/bin/env python3
"""Build Abrar/Resources/quran.sqlite from the Tanzil Project sources.

The Quran text is copied verbatim from Tanzil (Uthmani). Tanzil's copyright
block is stored unchanged in the `meta` table and must not be removed.

Usage: python3 scripts/build_quran_db.py [--refresh]
"""

import argparse
import re
import sqlite3
import sys
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "scripts" / ".cache"
OUTPUT = ROOT / "Abrar" / "Resources" / "quran.sqlite"

TEXT_URL = (
    "https://tanzil.net/pub/download/index.php"
    "?marks=true&sajdah=true&alef=true&tatweel=true"
    "&quranType=uthmani&outType=xml&agree=true"
)
METADATA_URL = "https://tanzil.net/res/text/metadata/quran-data.xml"

EXPECTED_SURAHS = 114
EXPECTED_AYAHS = 6236


def fetch(url: str, name: str, refresh: bool) -> str:
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / name
    if refresh or not path.exists():
        print(f"Downloading {url}")
        request = urllib.request.Request(url, headers={"User-Agent": "Abrar build script"})
        with urllib.request.urlopen(request) as response:
            path.write_bytes(response.read())
    return path.read_text(encoding="utf-8")


def copyright_block(xml_text: str) -> str:
    match = re.search(r"<!--(.*?)-->", xml_text, re.DOTALL)
    if not match or "Tanzil" not in match.group(1):
        sys.exit("Tanzil copyright block not found in the text source")
    return match.group(1).strip("\n")


def search_key(*names: str) -> str:
    """Lowercased ASCII key so 'fatiha' matches 'Al-Faatiha'."""
    parts = []
    for name in names:
        key = re.sub(r"[^a-z0-9 ]", "", name.lower())
        key = re.sub(r"([aeiou])\1+", r"\1", key)
        parts.append(key)
        parts.append(key.replace(" ", ""))
    return " ".join(parts)


def build(refresh: bool) -> None:
    text_xml = fetch(TEXT_URL, "quran-uthmani.xml", refresh)
    meta_xml = fetch(METADATA_URL, "quran-data.xml", refresh)

    notice = copyright_block(text_xml)
    version = re.search(r"Version\s+([\d.]+)", notice)

    text_root = ET.fromstring(text_xml)
    meta_root = ET.fromstring(meta_xml)
    surah_meta = {int(s.get("index")): s for s in meta_root.find("suras")}

    OUTPUT.unlink(missing_ok=True)
    db = sqlite3.connect(OUTPUT)
    db.executescript(
        """
        PRAGMA journal_mode = DELETE;
        CREATE TABLE meta (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL
        );
        CREATE TABLE surahs (
            id INTEGER PRIMARY KEY NOT NULL,
            name_arabic TEXT NOT NULL,
            name_transliterated TEXT NOT NULL,
            name_english TEXT NOT NULL,
            ayah_count INTEGER NOT NULL,
            revelation_type TEXT NOT NULL,
            revelation_order INTEGER NOT NULL,
            bismillah TEXT,
            search_key TEXT NOT NULL
        );
        CREATE TABLE ayahs (
            surah INTEGER NOT NULL REFERENCES surahs(id),
            number INTEGER NOT NULL,
            text TEXT NOT NULL,
            PRIMARY KEY (surah, number)
        ) WITHOUT ROWID;
        """
    )

    ayah_total = 0
    for sura in text_root.findall("sura"):
        index = int(sura.get("index"))
        meta = surah_meta[index]
        ayahs = sura.findall("aya")
        if len(ayahs) != int(meta.get("ayas")):
            sys.exit(f"Surah {index}: ayah count mismatch")
        bismillah = ayahs[0].get("bismillah")
        db.execute(
            "INSERT INTO surahs VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (
                index,
                sura.get("name"),
                meta.get("tname"),
                meta.get("ename"),
                len(ayahs),
                meta.get("type"),
                int(meta.get("order")),
                bismillah,
                search_key(meta.get("tname"), meta.get("ename")),
            ),
        )
        db.executemany(
            "INSERT INTO ayahs VALUES (?, ?, ?)",
            [(index, int(a.get("index")), a.get("text")) for a in ayahs],
        )
        ayah_total += len(ayahs)

    surah_total = db.execute("SELECT COUNT(*) FROM surahs").fetchone()[0]
    if surah_total != EXPECTED_SURAHS or ayah_total != EXPECTED_AYAHS:
        sys.exit(f"Unexpected totals: {surah_total} surahs, {ayah_total} ayahs")

    db.executemany(
        "INSERT INTO meta VALUES (?, ?)",
        [
            ("tanzil_copyright", notice),
            ("tanzil_version", version.group(1) if version else "unknown"),
            ("tanzil_type", "uthmani"),
            ("source", "https://tanzil.net"),
        ],
    )
    db.commit()
    db.execute("VACUUM")
    db.close()
    print(f"Wrote {OUTPUT.relative_to(ROOT)}: {surah_total} surahs, {ayah_total} ayahs")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--refresh", action="store_true", help="re-download Tanzil sources")
    build(parser.parse_args().refresh)

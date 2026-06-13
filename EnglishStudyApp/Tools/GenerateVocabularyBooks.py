#!/usr/bin/env python3

import csv
import json
import pathlib
import sys


BOOKS = {
    "gk": "high-school",
    "cet4": "cet4",
    "cet6": "cet6",
    "toefl": "toefl",
}


def ranking(row):
    def number(value):
        try:
            parsed = int(value)
            return parsed if parsed > 0 else 10_000_000
        except (TypeError, ValueError):
            return 10_000_000

    return (number(row.get("frq")), number(row.get("bnc")), row["word"].lower())


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: GenerateVocabularyBooks.py ECDICT.csv OUTPUT_DIR")

    source = pathlib.Path(sys.argv[1])
    output = pathlib.Path(sys.argv[2])
    output.mkdir(parents=True, exist_ok=True)
    collected = {tag: [] for tag in BOOKS}

    with source.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            word = (row.get("word") or "").strip()
            translation = (row.get("translation") or "").strip()
            tags = set((row.get("tag") or "").split())
            if not word or not translation:
                continue

            for tag in tags.intersection(BOOKS):
                collected[tag].append(row)

    for tag, filename in BOOKS.items():
        rows = sorted(collected[tag], key=ranking)
        words = [
            {
                "word": row["word"].strip(),
                "exp": row["translation"].strip(),
            }
            for row in rows
        ]
        target = output / f"{filename}.json"
        target.write_text(
            json.dumps(words, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        print(f"{tag}: {len(words)} -> {target}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3

import csv
import json
import pathlib
import sys


BOOKS = {
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
    collected["high-school"] = []

    with source.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            word = (row.get("word") or "").strip()
            translation = (row.get("translation") or "").strip()
            tags = set((row.get("tag") or "").split())
            if not word or not translation:
                continue

            if tags.intersection({"zk", "gk"}):
                collected["high-school"].append(row)

            for tag in tags.intersection(BOOKS):
                collected[tag].append(row)

    outputs = {"high-school": "high-school", **BOOKS}
    for tag, filename in outputs.items():
        rows = sorted(collected[tag], key=ranking)
        words_by_id = {}
        for row in rows:
            item = {
                "word": row["word"].strip(),
                "exp": row["translation"].strip(),
            }
            words_by_id.setdefault(item["word"].lower(), item)
        words = list(words_by_id.values())
        target = output / f"{filename}.json"
        target.write_text(
            json.dumps(words, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        print(f"{tag}: {len(words)} -> {target}")


if __name__ == "__main__":
    main()

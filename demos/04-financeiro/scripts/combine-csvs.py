#!/usr/bin/env python3
"""
combine-csvs.py — gera o CSV long-format usado pelo Quick Sight da Demo 04.

Lê:
  data/budget-2026.csv     (wide: jan-jun)
  data/actuals-q1-2026.csv (wide: jan-mar)

Escreve:
  data/variance-q1-2026.csv (long: regional, categoria, data, tipo, valor)

A coluna `data` usa formato ISO YYYY-MM-DD (primeiro dia do mês) para
o Quick Sight reconhecer como time-series. A coluna `tipo` é budget ou actual.

Uso:
  python3 scripts/combine-csvs.py
"""

import csv
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

MONTH_TO_DATE = {
    "jan": "2026-01-01",
    "fev": "2026-02-01",
    "mar": "2026-03-01",
    "abr": "2026-04-01",
    "mai": "2026-05-01",
    "jun": "2026-06-01",
}


def unpivot(csv_path: Path, tipo: str) -> list[dict]:
    rows = []
    with csv_path.open() as f:
        reader = csv.DictReader(f)
        month_cols = [c for c in reader.fieldnames if c in MONTH_TO_DATE]
        for line in reader:
            for m in month_cols:
                rows.append({
                    "regional": line["regional"],
                    "categoria": line["categoria"],
                    "data": MONTH_TO_DATE[m],
                    "tipo": tipo,
                    "valor": int(line[m]),
                })
    return rows


def main() -> None:
    budget = unpivot(DATA_DIR / "budget-2026.csv", "budget")
    actuals = unpivot(DATA_DIR / "actuals-q1-2026.csv", "actual")
    combined = budget + actuals

    combined.sort(key=lambda r: (r["regional"], r["categoria"], r["data"], r["tipo"]))

    out_path = DATA_DIR / "variance-q1-2026.csv"
    with out_path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["regional", "categoria", "data", "tipo", "valor"])
        writer.writeheader()
        writer.writerows(combined)

    print(f"OK gravadas {len(combined)} linhas em {out_path}")
    print(f"   budget: {len(budget)} linhas (jan-jun, 4 regionais x 3 categorias x 6 meses)")
    print(f"   actual: {len(actuals)} linhas (jan-mar Q1, 4 regionais x 3 categorias x 3 meses)")


if __name__ == "__main__":
    main()

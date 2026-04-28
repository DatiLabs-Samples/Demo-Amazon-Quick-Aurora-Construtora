#!/usr/bin/env python3
"""
teardown-hubspot.py — remove o scaffold criado por setup-hubspot.py

CUIDADO: apaga deals e companies cujo nome bate com o seed.
Pede confirmação interativa antes de prosseguir.

Uso:
  export HUBSPOT_TOKEN=pat-na1-...
  python3 teardown-hubspot.py
"""

import json
import os
import sys
from pathlib import Path
from typing import Optional

import urllib.request
import urllib.error

API_BASE = "https://api.hubapi.com"
SCRIPT_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPT_DIR.parent / "data"

TOKEN = os.environ.get("HUBSPOT_TOKEN")
if not TOKEN:
    print("❌ Defina HUBSPOT_TOKEN: export HUBSPOT_TOKEN=pat-na1-...")
    sys.exit(1)


def api(method: str, path: str, body: Optional[dict] = None) -> dict:
    url = f"{API_BASE}{path}"
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {TOKEN}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        body_text = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {path} -> {e.code}: {body_text}") from e


def confirm() -> None:
    print("⚠️  Você está prestes a APAGAR:")
    print("   - Os 8 deals do scaffold Aurora")
    print("   - As 8 companies do scaffold Aurora")
    print("   (custom properties e stages do pipeline NÃO são removidos)")
    print()
    answer = input("Digite 'apagar' para confirmar: ").strip()
    if answer != "apagar":
        print("❌ Cancelado.")
        sys.exit(1)


def find_id(object_type: str, prop_name: str, value: str) -> Optional[str]:
    body = {
        "filterGroups": [{"filters": [{"propertyName": prop_name, "operator": "EQ", "value": value}]}],
        "properties": [prop_name],
        "limit": 1,
    }
    res = api("POST", f"/crm/v3/objects/{object_type}/search", body=body)
    return res["results"][0]["id"] if res.get("results") else None


def main() -> None:
    confirm()

    with open(DATA_DIR / "deals.json", encoding="utf-8") as f:
        deals = json.load(f)

    print("\n💰 Removendo deals...")
    for d in deals:
        deal_id = find_id("deals", "dealname", d["dealname"])
        if deal_id:
            api("DELETE", f"/crm/v3/objects/deals/{deal_id}")
            print(f"   - {d['dealname']}")
        else:
            print(f"   ✓ Já removido: {d['dealname']}")

    with open(DATA_DIR / "companies.json", encoding="utf-8") as f:
        companies = json.load(f)

    print("\n🏢 Removendo companies...")
    for c in companies:
        company_id = find_id("companies", "domain", c["domain"])
        if company_id:
            api("DELETE", f"/crm/v3/objects/companies/{company_id}")
            print(f"   - {c['name']}")
        else:
            print(f"   ✓ Já removida: {c['name']}")

    print("\n✅ Teardown concluído.")


if __name__ == "__main__":
    main()

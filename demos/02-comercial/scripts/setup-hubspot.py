#!/usr/bin/env python3
"""
setup-hubspot.py — provisiona scaffold de CRM no HubSpot Aurora

Cria/atualiza (idempotente):
  - 5 stages no pipeline default ("Sales Pipeline"):
    Discovery, Qualification, Proposal, Negotiation, Closed Won
  - Custom properties:
    Deal: health_score, last_activity_days, sales_rep,
          regional, aurora_vertical, expected_close_quarter_original
    Company: csat_score, open_tickets
  - 9 companies (data/companies.json) — Aurora carteira-âncora + 2 BA
  - 9 deals (data/deals.json) com associação à company correspondente

Orphan cleanup:
  No final, arquiva (soft-delete) qualquer deal ou company que esteja no
  HubSpot mas não na lista canônica do repo. Permite re-rodar o script
  depois de mudanças sem deixar lixo no HubSpot.

Uso:
  export HUBSPOT_TOKEN=pat-na1-...
  python3 setup-hubspot.py
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


# ──────────────────────────────────────────────────────────────────────
# Pipeline stages
# ──────────────────────────────────────────────────────────────────────

PIPELINE_STAGES = [
    {"label": "Discovery", "displayOrder": 0, "metadata": {"isClosed": "false", "probability": "0.2"}},
    {"label": "Qualification", "displayOrder": 1, "metadata": {"isClosed": "false", "probability": "0.4"}},
    {"label": "Proposal", "displayOrder": 2, "metadata": {"isClosed": "false", "probability": "0.6"}},
    {"label": "Negotiation", "displayOrder": 3, "metadata": {"isClosed": "false", "probability": "0.8"}},
    {"label": "Closed Won", "displayOrder": 4, "metadata": {"isClosed": "true", "probability": "1.0"}},
]


def setup_pipeline() -> dict[str, str]:
    """Atualiza o pipeline default 'default' com stages Aurora.
    Retorna dict {stage_label: stage_id}."""

    print("🔍 Buscando pipeline default 'default'...")
    pipelines = api("GET", "/crm/v3/pipelines/deals")
    default = next((p for p in pipelines["results"] if p["id"] == "default"), None)
    if not default:
        raise RuntimeError("Pipeline 'default' não encontrado")

    existing_stages = {s["label"]: s["id"] for s in default["stages"]}
    print(f"   Stages atuais: {list(existing_stages.keys())}")

    target_labels = {s["label"] for s in PIPELINE_STAGES}
    label_to_id: dict[str, str] = {}

    # Cria stages que faltam
    for stage in PIPELINE_STAGES:
        if stage["label"] in existing_stages:
            label_to_id[stage["label"]] = existing_stages[stage["label"]]
            print(f"   ✓ Stage existe: {stage['label']}")
            continue
        print(f"   + Criando stage: {stage['label']}")
        created = api(
            "POST",
            "/crm/v3/pipelines/deals/default/stages",
            body=stage,
        )
        label_to_id[stage["label"]] = created["id"]

    # Remove stages legados que não estão na lista alvo (best-effort)
    for label, sid in existing_stages.items():
        if label not in target_labels:
            try:
                print(f"   - Removendo stage legado: {label}")
                api("DELETE", f"/crm/v3/pipelines/deals/default/stages/{sid}")
            except RuntimeError as e:
                print(f"   ⚠️  Não removeu '{label}' (pode ter deals): {str(e)[:80]}")

    return label_to_id


# ──────────────────────────────────────────────────────────────────────
# Custom properties
# ──────────────────────────────────────────────────────────────────────

DEAL_PROPERTIES = [
    {
        "name": "health_score",
        "label": "Health Score",
        "type": "number",
        "fieldType": "number",
        "groupName": "dealinformation",
        "description": "Score 0-100 indicando saúde do deal (engagement + risco).",
    },
    {
        "name": "last_activity_days",
        "label": "Last Activity Days",
        "type": "number",
        "fieldType": "number",
        "groupName": "dealinformation",
        "description": "Dias desde a última atividade registrada com o cliente.",
    },
    {
        "name": "sales_rep",
        "label": "Sales Rep",
        "type": "string",
        "fieldType": "text",
        "groupName": "dealinformation",
        "description": "AE responsável pelo deal (Carla, Rodrigo, Patrícia).",
    },
    {
        "name": "regional",
        "label": "Regional",
        "type": "string",
        "fieldType": "text",
        "groupName": "dealinformation",
        "description": "Estado/regional da operação do deal (SP, RJ, MG, BA, RS, PR).",
    },
    {
        "name": "aurora_vertical",
        "label": "Aurora Vertical",
        "type": "string",
        "fieldType": "text",
        "groupName": "dealinformation",
        "description": "Linha de negócio Aurora (Industrial, Predial, Infra, Tech).",
    },
    {
        "name": "expected_close_quarter_original",
        "label": "Expected Close Quarter (Original)",
        "type": "string",
        "fieldType": "text",
        "groupName": "dealinformation",
        "description": "Quarter de fechamento previsto na assinatura do deal (Q1, Q2, Q3, Q4). Comparar com closedate atual revela slippage.",
    },
]

COMPANY_PROPERTIES = [
    {
        "name": "csat_score",
        "label": "CSAT Score",
        "type": "number",
        "fieldType": "number",
        "groupName": "companyinformation",
        "description": "Score CSAT médio (0-5).",
    },
    {
        "name": "open_tickets",
        "label": "Open Tickets",
        "type": "number",
        "fieldType": "number",
        "groupName": "companyinformation",
        "description": "Número de tickets de suporte abertos.",
    },
]


def ensure_property(object_type: str, prop: dict) -> None:
    path_get = f"/crm/v3/properties/{object_type}/{prop['name']}"
    try:
        api("GET", path_get)
        print(f"   ✓ Property existe: {object_type}.{prop['name']}")
        return
    except RuntimeError as e:
        if "404" not in str(e):
            raise

    print(f"   + Criando property: {object_type}.{prop['name']}")
    api("POST", f"/crm/v3/properties/{object_type}", body=prop)


def setup_properties() -> None:
    print("🏷️  Configurando custom properties...")
    for prop in DEAL_PROPERTIES:
        ensure_property("deals", prop)
    for prop in COMPANY_PROPERTIES:
        ensure_property("companies", prop)


# ──────────────────────────────────────────────────────────────────────
# Companies
# ──────────────────────────────────────────────────────────────────────

def find_company_by_domain(domain: str) -> Optional[str]:
    body = {
        "filterGroups": [{"filters": [{"propertyName": "domain", "operator": "EQ", "value": domain}]}],
        "properties": ["name", "domain"],
        "limit": 1,
    }
    res = api("POST", "/crm/v3/objects/companies/search", body=body)
    return res["results"][0]["id"] if res.get("results") else None


def setup_companies() -> dict[str, str]:
    """Retorna dict {company_name: company_id}."""
    with open(DATA_DIR / "companies.json", encoding="utf-8") as f:
        companies = json.load(f)

    print(f"🏢 Configurando {len(companies)} companies...")
    name_to_id: dict[str, str] = {}

    for c in companies:
        existing = find_company_by_domain(c["domain"])
        if existing:
            print(f"   ✓ Existe: {c['name']} (id={existing}) — atualizando")
            api("PATCH", f"/crm/v3/objects/companies/{existing}", body={"properties": c})
            name_to_id[c["name"]] = existing
        else:
            print(f"   + Criando: {c['name']}")
            created = api("POST", "/crm/v3/objects/companies", body={"properties": c})
            name_to_id[c["name"]] = created["id"]

    return name_to_id


# ──────────────────────────────────────────────────────────────────────
# Deals
# ──────────────────────────────────────────────────────────────────────

def find_deal_by_name(name: str) -> Optional[str]:
    body = {
        "filterGroups": [{"filters": [{"propertyName": "dealname", "operator": "EQ", "value": name}]}],
        "properties": ["dealname"],
        "limit": 1,
    }
    res = api("POST", "/crm/v3/objects/deals/search", body=body)
    return res["results"][0]["id"] if res.get("results") else None


def setup_deals(stage_label_to_id: dict[str, str], company_name_to_id: dict[str, str]) -> None:
    with open(DATA_DIR / "deals.json", encoding="utf-8") as f:
        deals = json.load(f)

    print(f"💰 Configurando {len(deals)} deals...")

    for d in deals:
        stage_id = stage_label_to_id.get(d["dealstage_label"])
        if not stage_id:
            raise RuntimeError(f"Stage '{d['dealstage_label']}' não encontrado pra deal '{d['dealname']}'")

        company_id = company_name_to_id.get(d["company_name"])
        if not company_id:
            raise RuntimeError(f"Company '{d['company_name']}' não encontrada pra deal '{d['dealname']}'")

        # Converte close_date para timestamp ms (UTC midnight)
        from datetime import datetime, timezone
        dt = datetime.strptime(d["closedate"], "%Y-%m-%d").replace(tzinfo=timezone.utc)
        closedate_ms = int(dt.timestamp() * 1000)

        properties = {
            "dealname": d["dealname"],
            "amount": d["amount"],
            "dealstage": stage_id,
            "pipeline": "default",
            "closedate": closedate_ms,
            "sales_rep": d["sales_rep"],
            "health_score": d["health_score"],
            "last_activity_days": d["last_activity_days"],
            "regional": d["regional"],
            "aurora_vertical": d["aurora_vertical"],
            "expected_close_quarter_original": d["expected_close_quarter_original"],
        }

        existing = find_deal_by_name(d["dealname"])
        if existing:
            print(f"   ✓ Existe: {d['dealname']} — atualizando")
            api("PATCH", f"/crm/v3/objects/deals/{existing}", body={"properties": properties})
            deal_id = existing
        else:
            print(f"   + Criando: {d['dealname']}")
            payload = {
                "properties": properties,
                "associations": [
                    {
                        "to": {"id": company_id},
                        "types": [{"associationCategory": "HUBSPOT_DEFINED", "associationTypeId": 5}],
                    }
                ],
            }
            created = api("POST", "/crm/v3/objects/deals", body=payload)
            deal_id = created["id"]

        # Garante associação mesmo se deal já existia
        try:
            api(
                "PUT",
                f"/crm/v3/objects/deals/{deal_id}/associations/companies/{company_id}/5",
            )
        except RuntimeError as e:
            print(f"   ⚠️  Não conseguiu associar deal {deal_id} → company {company_id}: {str(e)[:80]}")


# ──────────────────────────────────────────────────────────────────────
# Orphan cleanup — arquiva deals/companies que não estão no repo
# ──────────────────────────────────────────────────────────────────────

def _list_all(object_type: str, properties: list[str]) -> list[dict]:
    """Lista todos os objetos paginando. Retorna lista crua de results."""
    all_results: list[dict] = []
    after: Optional[str] = None
    while True:
        params = f"limit=100&properties={','.join(properties)}"
        if after:
            params += f"&after={after}"
        res = api("GET", f"/crm/v3/objects/{object_type}?{params}")
        all_results.extend(res.get("results", []))
        paging = res.get("paging", {})
        next_page = paging.get("next", {})
        if not next_page or "after" not in next_page:
            break
        after = next_page["after"]
    return all_results


def archive_orphan_records() -> None:
    """Arquiva (soft-delete) deals e companies do HubSpot que não estão
    nas listas canônicas do repo. Preserva idempotência ao re-rodar setup
    depois de mudar deals.json ou companies.json."""

    print("🗑️  Orphan cleanup — checando registros órfãos...")

    with open(DATA_DIR / "deals.json", encoding="utf-8") as f:
        canonical_deal_names = {d["dealname"] for d in json.load(f)}
    with open(DATA_DIR / "companies.json", encoding="utf-8") as f:
        canonical_company_domains = {c["domain"] for c in json.load(f)}

    # Deals
    deals = _list_all("deals", ["dealname", "pipeline"])
    deal_orphans = [
        d for d in deals
        if d["properties"].get("pipeline") == "default"
        and d["properties"].get("dealname") not in canonical_deal_names
    ]
    if deal_orphans:
        print(f"   {len(deal_orphans)} deal(s) órfão(s) — arquivando:")
        for d in deal_orphans:
            name = d["properties"].get("dealname", "(sem nome)")
            print(f"      🗑  {name} (id={d['id']})")
            api("DELETE", f"/crm/v3/objects/deals/{d['id']}")
    else:
        print("   ✓ Nenhum deal órfão")

    # Companies
    companies = _list_all("companies", ["name", "domain"])
    company_orphans = [
        c for c in companies
        if c["properties"].get("domain") not in canonical_company_domains
    ]
    if company_orphans:
        print(f"   {len(company_orphans)} company(ies) órfã(s) — arquivando:")
        for c in company_orphans:
            label = c["properties"].get("name") or c["properties"].get("domain") or "(sem nome)"
            print(f"      🗑  {label} (id={c['id']})")
            api("DELETE", f"/crm/v3/objects/companies/{c['id']}")
    else:
        print("   ✓ Nenhuma company órfã")


# ──────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────

def main() -> None:
    print("🚀 Aurora HubSpot Scaffold\n")

    # Identidade
    me = api("GET", "/account-info/v3/details")
    print(f"📋 HubSpot Hub ID: {me.get('portalId')}")
    print(f"📋 Time zone: {me.get('timeZone')}")
    print()

    stage_ids = setup_pipeline()
    print()

    setup_properties()
    print()

    company_ids = setup_companies()
    print()

    setup_deals(stage_ids, company_ids)
    print()

    archive_orphan_records()
    print()

    print("🎉 Scaffold concluído!")
    print()
    print("Verificar no HubSpot UI:")
    print(f"  Pipeline: https://app.hubspot.com/sales/{me.get('portalId')}/deals/board/view/all/")
    print(f"  Companies: https://app.hubspot.com/contacts/{me.get('portalId')}/companies/list/view/all/")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
setup-clickup.py — provisiona scaffold ClickUp para Demo 03 RH

Cria (idempotente):
  - Space "Operações" no Workspace "Aurora Demo"
  - List "Onboarding TI" dentro do Space "Operações"
  - 5 custom fields:
      Nome do Funcionário (short_text)
      Cargo (short_text)
      Gestor (short_text)
      Equipamentos (labels)
      Status (drop_down: Solicitado, Em Andamento, Entregue)
  - 3 tasks de exemplo (onboardings recentes para encher a list visualmente)

Pré-requisitos:
  1. Workspace "Aurora Demo" criado manualmente em app.clickup.com
  2. Personal Token gerado em Settings → Apps → Generate (começa com pk_...)

Uso:
  export CLICKUP_TOKEN=pk_...
  python3 setup-clickup.py
"""

import json
import os
import sys
from typing import Optional

import urllib.request
import urllib.error

API_BASE = "https://api.clickup.com/api/v2"

TOKEN = os.environ.get("CLICKUP_TOKEN")
if not TOKEN:
    print("❌ Defina CLICKUP_TOKEN: export CLICKUP_TOKEN=pk_...")
    sys.exit(1)


def api(method: str, path: str, body: Optional[dict] = None) -> dict:
    url = f"{API_BASE}{path}"
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": TOKEN,
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
# Discovery / Provisioning
# ──────────────────────────────────────────────────────────────────────

def find_team(name_substring: str = "dati") -> dict:
    """Encontra workspace cujo nome contenha o substring (case-insensitive)."""
    teams = api("GET", "/team").get("teams", [])
    for team in teams:
        if name_substring.lower() in team["name"].lower():
            return team
    available = [t["name"] for t in teams]
    raise RuntimeError(
        f"Workspace contendo '{name_substring}' não encontrado.\n"
        f"   Workspaces disponíveis: {available}"
    )


def find_or_create_space(team_id: str, name: str = "Demo - Aurora") -> dict:
    spaces = api("GET", f"/team/{team_id}/space?archived=false").get("spaces", [])
    for sp in spaces:
        if sp["name"] == name:
            print(f"   ↩ Space '{name}' já existe (id {sp['id']})")
            return sp

    print(f"   + Criando Space '{name}'...")
    return api("POST", f"/team/{team_id}/space", {
        "name": name,
        "multiple_assignees": True,
        "features": {
            "due_dates": {"enabled": True, "start_date": True, "remap_due_dates": True, "remap_closed_due_date": False},
            "time_tracking": {"enabled": False},
            "tags": {"enabled": True},
            "time_estimates": {"enabled": False},
            "checklists": {"enabled": True},
            "custom_fields": {"enabled": True},
            "remap_dependencies": {"enabled": True},
            "dependency_warning": {"enabled": True},
            "portfolios": {"enabled": False},
        },
    })


def find_or_create_list(space_id: str, name: str = "Onboarding TI") -> dict:
    lists = api("GET", f"/space/{space_id}/list?archived=false").get("lists", [])
    for ls in lists:
        if ls["name"] == name:
            print(f"   ↩ List '{name}' já existe (id {ls['id']})")
            return ls

    print(f"   + Criando List '{name}'...")
    return api("POST", f"/space/{space_id}/list", {
        "name": name,
        "content": "Tasks de onboarding de TI — equipamentos para novos colaboradores Aurora",
    })


# ──────────────────────────────────────────────────────────────────────
# Custom fields
# ──────────────────────────────────────────────────────────────────────

CUSTOM_FIELDS = [
    {"name": "Nome do Funcionário", "type": "short_text"},
    {"name": "Cargo", "type": "short_text"},
    {"name": "Gestor", "type": "short_text"},
    {
        "name": "Equipamentos",
        "type": "labels",
        "type_config": {
            "options": [
                {"label": "Notebook"},
                {"label": "Monitor 27\""},
                {"label": "Cadeira"},
                {"label": "Headset"},
                {"label": "Outros"},
            ],
        },
    },
    {
        "name": "Status",
        "type": "drop_down",
        "type_config": {
            "default": 0,
            "options": [
                {"name": "Solicitado",   "color": "#f9d900", "orderindex": 0},
                {"name": "Em Andamento", "color": "#3397dd", "orderindex": 1},
                {"name": "Entregue",     "color": "#2ecd6f", "orderindex": 2},
            ],
        },
    },
]


def get_existing_fields(list_id: str) -> dict:
    return {f["name"]: f for f in api("GET", f"/list/{list_id}/field").get("fields", [])}


def upsert_custom_fields(list_id: str) -> dict:
    """Cria os custom fields que faltarem. Retorna {nome: field_obj} via GET final
    para garantir shape consistente (POST e GET retornam shapes diferentes)."""
    existing = get_existing_fields(list_id)
    created_any = False

    for cf in CUSTOM_FIELDS:
        name = cf["name"]
        if name in existing:
            print(f"   ↩ Custom field '{name}' já existe")
            continue

        print(f"   + Criando custom field '{name}' ({cf['type']})...")
        body = {"name": name, "type": cf["type"]}
        if "type_config" in cf:
            body["type_config"] = cf["type_config"]
        api("POST", f"/list/{list_id}/field", body)
        created_any = True

    # Re-fetch via GET para garantir shape consistente (incluindo "id" e options com ids)
    return get_existing_fields(list_id)


# ──────────────────────────────────────────────────────────────────────
# Seed tasks
# ──────────────────────────────────────────────────────────────────────

# Tasks de exemplo — onboardings recentes da Aurora.
# Os índices em Equipamentos referem-se à ordem em CUSTOM_FIELDS["Equipamentos"]:
# 0=Notebook 1=Monitor 27" 2=Cadeira 3=Headset 4=Outros
SEED_TASKS = [
    {
        "title": "Equipamento para Mariana Santos (Engenheira Civil Pleno)",
        "nome": "Mariana Santos",
        "cargo": "Engenheira Civil Pleno",
        "gestor": "Rafael Tavares (@rafael.tavares)",
        "equipamentos_idx": [0, 1, 2, 3],     # Notebook, Monitor, Cadeira, Headset
        "status_idx": 2,                      # Entregue
        "description": (
            "Onboarding TI da Mariana — pacote padrão da Aurora.\n\n"
            "Entregue em 18/04/2026."
        ),
    },
    {
        "title": "Equipamento para Lucas Oliveira (Analista FP&A)",
        "nome": "Lucas Oliveira",
        "cargo": "Analista FP&A",
        "gestor": "Felipe Monteiro (@felipe.monteiro)",
        "equipamentos_idx": [0, 1, 3],        # Notebook, Monitor, Headset
        "status_idx": 1,                      # Em Andamento
        "description": (
            "Onboarding TI do Lucas — pacote padrão sem cadeira ergonômica "
            "(já tem da posição anterior).\n\n"
            "Aguardando entrega do monitor — previsão 05/05/2026."
        ),
    },
    {
        "title": "Equipamento para Beatriz Almeida (Coordenadora de Compras)",
        "nome": "Beatriz Almeida",
        "cargo": "Coordenadora de Compras",
        "gestor": "Rafael Tavares (@rafael.tavares)",
        "equipamentos_idx": [0, 1, 2, 3, 4],  # Pacote completo + extras
        "status_idx": 0,                      # Solicitado
        "description": (
            "Onboarding TI da Beatriz — solicita também headset premium e "
            "segundo monitor (justificativa: trabalha com BI no dia a dia).\n\n"
            "Aguardando aprovação do gestor."
        ),
    },
]


def seed_tasks(list_id: str, fields_by_name: dict):
    """Cria as 3 tasks de exemplo, idempotente por título."""
    existing_titles = {
        t["name"]
        for t in api("GET", f"/list/{list_id}/task?archived=false").get("tasks", [])
    }

    nome_id = fields_by_name["Nome do Funcionário"]["id"]
    cargo_id = fields_by_name["Cargo"]["id"]
    gestor_id = fields_by_name["Gestor"]["id"]

    equip_field = fields_by_name["Equipamentos"]
    equip_id = equip_field["id"]
    equip_options = {opt["label"]: opt["id"] for opt in equip_field["type_config"]["options"]}

    status_field = fields_by_name["Status"]
    status_id = status_field["id"]
    status_options = status_field["type_config"]["options"]
    # Para drop_down, value é o orderindex (int) das opções
    equip_labels_by_idx = ["Notebook", "Monitor 27\"", "Cadeira", "Headset", "Outros"]

    for spec in SEED_TASKS:
        title = spec["title"]
        if title in existing_titles:
            print(f"   ↩ Task '{title[:60]}...' já existe")
            continue

        equip_ids = [
            equip_options[equip_labels_by_idx[i]] for i in spec["equipamentos_idx"]
        ]

        body = {
            "name": title,
            "description": spec["description"],
            "custom_fields": [
                {"id": nome_id,   "value": spec["nome"]},
                {"id": cargo_id,  "value": spec["cargo"]},
                {"id": gestor_id, "value": spec["gestor"]},
                {"id": equip_id,  "value": {"add": equip_ids}},
                {"id": status_id, "value": spec["status_idx"]},
            ],
        }
        print(f"   + Criando task '{title[:60]}...'")
        api("POST", f"/list/{list_id}/task", body)


# ──────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────

def main():
    print("🚀 ClickUp Aurora Setup\n")

    print("🔍 Localizando workspace 'Dati'...")
    team = find_team()
    print(f"   ✅ Workspace: {team['name']} (id {team['id']})\n")

    print("🏗  Provisionando Space 'Operações'...")
    space = find_or_create_space(team["id"])
    print(f"   ✅ Space id: {space['id']}\n")

    print("📋 Provisionando List 'Onboarding TI'...")
    onboarding_list = find_or_create_list(space["id"])
    list_id = onboarding_list["id"]
    print(f"   ✅ List id: {list_id}\n")

    print("🏷  Custom fields...")
    fields = upsert_custom_fields(list_id)
    print()

    print("🌱 Seed tasks de exemplo...")
    seed_tasks(list_id, fields)
    print()

    print("🎉 Setup concluído!\n")
    print("📍 Para usar nos próximos passos (Quick Suite Flow):")
    print(f"   Workspace ID:  {team['id']}")
    print(f"   Space ID:      {space['id']}")
    print(f"   List ID:       {list_id}")
    print()
    print(f"   URL:  https://app.clickup.com/{team['id']}/v/li/{list_id}")


if __name__ == "__main__":
    main()

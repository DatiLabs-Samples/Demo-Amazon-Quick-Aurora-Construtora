# ClickUp IDs — Demo 03 RH

Referência rápida dos IDs do workspace ClickUp da Aurora Demo. Use ao montar o Quick Flow "Onboarding Equipamento" e o Custom Chat Agent. Atualizado em 2026-05-10.

> **Importante (placeholders):** os IDs abaixo (workspace `9999999999`, space `999999999998`, list `999999999999` e UUIDs de fields/options) são **placeholders**. Após rodar `setup-clickup.py` no seu próprio ClickUp, atualize estes valores pelos IDs reais do output do script.

## Workspace / Space / List

| Recurso | ID | URL |
|---|---|---|
| Workspace (team) `Dati` | `9999999999` | — |
| Space `Demo - Aurora` | `999999999998` | — |
| **List `Onboarding TI`** | **`999999999999`** | https://app.clickup.com/9999999999/v/li/999999999999 |

## Custom fields da Onboarding TI

| Field | Tipo | Field ID |
|---|---|---|
| Nome do Funcionário | short_text | `2b7ae64a-3c32-49e7-b180-c41b549a24e9` |
| Cargo | short_text | `4df00ee5-8126-47e4-bb55-8f30beb7c8aa` |
| Gestor | short_text | `0a1e7844-9182-4b47-87ae-0172bbed5a49` |
| Equipamentos | labels | `e1616db1-a6d6-4946-a618-d94c2908756b` |
| Status | drop_down | `09719f85-06ec-40a6-9632-1a0f14de18a2` |

### Equipamentos (labels) — option IDs

Passar como `{"add": ["<uuid>", ...]}` no value do custom field.

| Label | Option ID |
|---|---|
| Notebook | `979b78f6-4229-454a-8ed2-c0b68763d5ab` |
| Monitor 27" | `4b7e55c1-68d0-4a44-8083-063983c4d356` |
| Cadeira | `d8ade588-f0e4-4543-8365-559f3ab22d3f` |
| Headset | `65b0a6a0-3bf4-4528-91ad-f13de3db41e4` |
| Outros | `1f6a7619-4fdb-4c82-a379-3e6e1a026965` |

### Status (drop_down) — orderindex

Passar como inteiro no value do custom field.

| Status | orderindex |
|---|---|
| Solicitado | `0` |
| Em Andamento | `1` |
| Entregue | `2` |

## Payload de exemplo — create task

POST `https://api.clickup.com/api/v2/list/999999999999/task`
Header `Authorization: pk_111946197_...`

```json
{
  "name": "Equipamento para Maria Silva (Analista Financeira)",
  "description": "Onboarding TI. Pacote padrão Aurora. Gestor avisado via Slack.",
  "custom_fields": [
    {"id": "2b7ae64a-3c32-49e7-b180-c41b549a24e9", "value": "Maria Silva"},
    {"id": "4df00ee5-8126-47e4-bb55-8f30beb7c8aa", "value": "Analista Financeira"},
    {"id": "0a1e7844-9182-4b47-87ae-0172bbed5a49", "value": "Bruno Vilardi (@bruno.vilardi)"},
    {"id": "e1616db1-a6d6-4946-a618-d94c2908756b", "value": {"add": [
      "979b78f6-4229-454a-8ed2-c0b68763d5ab",
      "4b7e55c1-68d0-4a44-8083-063983c4d356",
      "d8ade588-f0e4-4543-8365-559f3ab22d3f",
      "65b0a6a0-3bf4-4528-91ad-f13de3db41e4"
    ]}},
    {"id": "09719f85-06ec-40a6-9632-1a0f14de18a2", "value": 0}
  ]
}
```

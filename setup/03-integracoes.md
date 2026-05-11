# Integrações por demo — Amazon Quick

## Conceito-chave: dois tipos de conector

O Quick Suite distingue duas categorias:

| Tipo | Função | Exemplos |
|---|---|---|
| **Knowledge sources** | Indexar conteúdo no Quick Index para o agente *ler* e responder | S3, SharePoint, Google Drive, Confluence, Notion, HubSpot |
| **Action connectors** | Permitir o agente *executar* ações em sistemas externos | Outlook, HubSpot, Slack, ServiceNow, ClickUp |

Vários conectores são **dual-purpose** (lêem e escrevem), ex.: ClickUp, ServiceNow, SharePoint.

## Matriz mestre — 5 demos

| Integração | Tipo | 01 Jurídico | 02 Comercial | 03 RH | 04 Financeiro | 05 Executivo |
|---|---|:---:|:---:|:---:|:---:|:---:|
| **S3** | Knowledge | ✅ obrig. | ⚪ opcional* | ✅ obrig. | ✅ obrig. | ✅ obrig. |
| **HubSpot** | Knowledge + Action | ⬜ | ✅ obrig. | ⬜ | ⬜ | ✅ obrig. |
| **Outlook** | Action | ✅ envio email | ✅ alert AE | ✅ email gestor | ✅ envio brief | ⬜ |
| **Slack** | Action | ⬜ | ✅ alerta deal | ⬜ | ✅ post leadership | ✅ post leadership |
| **ClickUp** | Action | ⬜ | ⬜ | ✅ criar task | ⬜ | ⬜ |
| **IAM Identity Center** | Auth | ✅ recomendado | ✅ recomendado | ✅ recomendado | ✅ recomendado | ✅ recomendado |
| **Quick Research** | Feature | ⬜ | ⬜ | ⬜ | ✅ obrig. | ✅ obrig. |
| **2 Spaces simultâneos** | Knowledge | ⬜ | ⬜ | ⬜ | ⬜ | ✅ Comercial + Financeiro |

\* S3 na Demo 02 é só um snapshot opcional do pipeline para alimentar Quick Sight com dado estável; fonte de verdade é HubSpot.

## Demo 01 — Jurídico

### Obrigatórias

| Integração | Para quê | Permissões |
|---|---|---|
| **S3** | Armazenar PDFs de contratos | IAM role com `s3:GetObject` no bucket |
| **IAM Identity Center** | Login do usuário `juridico-demo@` | Permission set Quick Suite |

### Usadas no roteiro

| Integração | Para quê | Permissões |
|---|---|---|
| **Outlook** | Quick Flow envia resumo executivo pro time jurídico | OAuth Microsoft com escopo `Mail.Send` |

### Alternativas

| Em vez de | Use |
|---|---|
| S3 | **SharePoint, Google Drive, Box, Dropbox Business** |
| Outlook | **Outlook (M365)** se cliente é Microsoft-centric |

### Setup mínimo

1. Bucket `quick-demo-{conta}` com pasta `juridico/`
2. 3 PDFs subidos
3. Outlook conectado via OAuth (5 min)

**Custo extra de licenças externas:** zero.

---

## Demo 02 — Comercial (HubSpot CRM real)

### Obrigatórias

| Integração | Para quê | Permissões |
|---|---|---|
| **HubSpot Free CRM** | Pipeline + Companies + ações (note, task, property update) | OAuth scopes: `crm.objects.deals.read/write`, `crm.objects.companies.read/write`, `crm.engagements.notes.write`, `crm.engagements.tasks.write` |
| **Quick Sight** (built-in) | Dashboard de pipeline | — |

### Usadas no roteiro

| Integração | Para quê |
|---|---|
| **Outlook** | Email pro AE responsável |
| **Slack** | Alerta no canal `#sales-alerts` |
| **S3** (opcional) | Snapshot CSV de pipeline para alimentar Quick Sight com dado estável | `s3:GetObject` |

### HubSpot é conector nativo

Sem MCP, sem OpenAPI custom — listado em [aws.amazon.com/quick/sales](https://aws.amazon.com/quick/sales/) ao lado de Salesforce. Setup é OAuth direto no Quick Suite.

### Alternativas

| Em vez de HubSpot | Use |
|---|---|
| HubSpot | **Salesforce** (conector nativo, mas requer Developer Edition ou sandbox empresa) |
| HubSpot | **Pipedrive** (trial 14 dias) |
| HubSpot | **Zoho CRM** (free 3 usuários) |
| HubSpot | **Notion como CRM** (free, conector knowledge — action limitada) |
| HubSpot | **Airtable como CRM** (free 1.000 records — visual de planilha) |

### Setup mínimo

1. Conta HubSpot Free (10 min — só email, sem cartão)
2. Customizar pipeline (5 stages) + criar 4 custom properties (5 min)
3. Importar 8 deals + 8 companies via CSV (5 min)
4. Conectar HubSpot no Quick Suite via OAuth (5 min)
5. Slack workspace com canal `#sales-alerts`
6. Dashboard Quick Sight via NL prompt

**Custo extra de licenças externas:** zero (HubSpot Free Forever, Slack Free).

---

## Demo 03 — RH

### Obrigatórias

| Integração | Para quê | Permissões |
|---|---|---|
| **S3** | 4 PDFs de políticas | `s3:GetObject` |
| **ClickUp** | Quick Flow cria task de equipamento | Personal Token ClickUp |
| **Outlook** | Quick Flow envia email pro gestor | OAuth com `Mail.Send` |

### Alternativas

| Em vez de | Use | Notas |
|---|---|---|
| S3 | **SharePoint Online, Google Drive** | Comum em empresas com M365/Workspace |
| ClickUp | **ServiceNow** | Conector nativo Quick |
| ClickUp | **Asana, Linear, Monday** | Conectores disponíveis |
| ClickUp | **Jira Cloud** | Conector nativo (alternativa anterior) |
| Outlook | **Outlook (M365)** | Se cliente em Microsoft |
| Outlook | **Slack DM** | Alternativa de notificação |

### Setup mínimo

1. Bucket S3 com 4 PDFs (10 min)
2. ClickUp Workspace + List "Onboarding TI" com custom fields (15 min)
3. Conector ClickUp configurado (compartilhado com Demo 02)
4. Outlook conectado

**Custo extra de licenças externas:** zero (ClickUp Free serve até 5 membros).

### Pegadinha do ClickUp

Personal Token **não expira automaticamente**, mas é revogado se a senha do usuário ClickUp mudar ou se a conta for desconectada de Workspace. Sempre testar D-1.

---

## Demo 04 — Financeiro

### Obrigatórias

| Integração | Para quê |
|---|---|
| **S3** | CSVs de budget/actuals + PDFs de mercado/ata |
| **Quick Sight** (built-in) | Dataset + Dashboard |
| **Quick Research** (built-in) | Cruzar dados financeiros + PDFs externos com citações |

⚠️ **Quick Research requer plano Enterprise** ($40/usuário/mês) para o autor da demo.

### Usadas no roteiro

| Integração | Para quê | Permissões |
|---|---|---|
| **Outlook** | Email do brief executivo pro CFO | OAuth com `Mail.Send` |
| **Slack** | Post no canal `#financeiro-leadership` | OAuth |

### Alternativas

| Em vez de | Use |
|---|---|
| S3 (PDFs apoio) | **SharePoint, Google Drive** |
| Outlook | **Outlook** |
| Slack | **Teams** |

### Setup mínimo

1. Bucket S3 com 2 CSVs + 2 PDFs (15 min)
2. Outlook + Slack conectados
3. Dataset Quick Sight com calculated fields (`desvio_abs`, `desvio_pct`)
4. Dashboard via NL prompt
5. Chat Agent com **Research tool habilitada** (importante — esquecer este passo é a falha mais comum)

**Custo extra de licenças externas:** zero.

---

## Conectores AWS Quick — catálogo (50+)

### Knowledge sources (indexação)

- **Repositórios de arquivo:** Amazon S3, SharePoint Online, OneDrive, Google Drive, Box, Dropbox Business
- **Wikis:** Confluence, Notion, Coda, Quip
- **Comunicação:** Outlook, Outlook, Slack, Teams (mensagens indexáveis)
- **CRM/ERP:** Salesforce, HubSpot, Dynamics 365, SAP, ServiceNow, Workday
- **Data warehouses:** Redshift, Snowflake, Databricks, BigQuery
- **Marketing/Analytics:** Adobe Analytics, Google Analytics
- **Suporte:** Zendesk, Freshdesk, Intercom

### Action connectors

- **Tickets/PM:** ServiceNow, Asana, Linear, Monday, Jira Cloud (nativo) | ClickUp (via MCP)
- **Email:** Outlook, Outlook
- **Mensageria:** Slack, Teams, Webex
- **CRM (write):** Salesforce, HubSpot, Pipedrive
- **HR:** Workday, BambooHR, ADP
- **Pagamento/Finanças:** Stripe, QuickBooks
- **DevOps:** GitHub, GitLab, PagerDuty, Datadog

### Custom connectors

- **OpenAPI 3.x:** publicar endpoint REST + spec; Quick gera conector
- **MCP (Model Context Protocol):** padrão Anthropic; ~1.000+ servidores compatíveis (ClickUp, Atlassian, Box, Canva, Workato, Zapier)

---

## Checklist de integrações para o webinar

### Antes de começar setup (D-14)

- [ ] Conta AWS com permissão de admin
- [ ] Conta Microsoft (Outlook.com) — pessoal ou M365
- [ ] Workspace Slack (free tier OK) com canais `#sales-alerts` e `#financeiro-leadership`
- [ ] Conta HubSpot Free (Demo 02)
- [ ] Conta ClickUp Free Forever (Demo 03)
- [ ] Domínio fictício para emails (ex.: `aurora-demo.com.br` — pode ser apenas alias do Outlook)

### Setup de conectores (D-12 a D-7)

- [ ] S3 bucket criado com 4 pastas e arquivos sintéticos
- [ ] IAM Identity Center habilitado, 4 usuários demo criados
- [ ] OAuth Outlook autorizado e testado (enviar email manualmente via Quick chat)
- [ ] OAuth Slack autorizado e bot adicionado nos canais
- [ ] HubSpot configurado com pipeline + custom properties + 8 deals/companies importados
- [ ] OAuth HubSpot autorizado no Quick Suite e custom properties visíveis no agente
- [ ] ClickUp Workspace + List "Onboarding TI" configurada
- [ ] Personal Token ClickUp gerado
- [ ] Conector ClickUp (MCP ou OpenAPI) testado com criação de task de teste
- [ ] Quick Research habilitado no agente da Demo 04

### Validação (D-1)

- [ ] Cada conector retesta login (OAuth não expirou)
- [ ] 1 deal de teste no HubSpot recebe note via Quick chat
- [ ] 1 task de teste em ClickUp é criada e deletada
- [ ] 1 email de teste em Outlook é enviado
- [ ] 1 mensagem de teste em Slack é postada
- [ ] Dashboard Quick Sight renderiza
- [ ] Cada Chat Agent responde 3 perguntas-âncora

---

## Diagrama mental — fluxo de dados por demo

```
Demo 01 — Jurídico
S3 (PDFs) ──► Quick Index ──► Chat Agent ──► Quick Flow ──► Outlook

Demo 02 — Comercial (HubSpot CRM real)
HubSpot (deals+companies) ──► Quick Index ──► Chat Agent ──► Quick Flow ──┬─► HubSpot (note + task + property)
S3 snapshot (opcional) ──► Quick Sight ──┘                                  ├─► Outlook
                                                                              └─► Slack

Demo 03 — RH
S3 (PDFs) ──► Quick Index ──► Chat Agent ──► Quick Flow ──┬─► ClickUp (criar task)
                                                            └─► Outlook

Demo 04 — Financeiro
S3 (CSVs+PDFs) ──► Quick Sight + Quick Index ──► Chat Agent ──┬─► Quick Research
                                                                ├─► Quick Flow ──► Outlook
                                                                └─► Quick Flow ──► Slack
```

# Setup AWS — pré-requisitos para gravar/apresentar as demos

## 1. Ativação do Amazon Quick

1. Conta AWS com permissão de admin (ou ao menos `IAMFullAccess` + `quicksuite:*`).
2. Console AWS → buscar **Amazon Quick** → **Get Started**.
3. Escolher plano **Enterprise** (USD 40/usuário/mês, ou trial 30 dias).
   - Enterprise é necessário para **Quick Automate authoring** e **autoria de Quick Sight**.
   - Trial: até 25 usuários, fee de infra (USD 250) é waived.
4. Região: usar **us-east-1** ou **us-west-2** (todos os recursos disponíveis). **sa-east-1 ainda não tem Amazon Quick completo** (verificar em [aws.amazon.com/quick/faqs](https://aws.amazon.com/quick/faqs/)).

## 2. Identidade (escolher uma)

| Opção | Quando usar |
|---|---|
| **IAM Identity Center** (recomendado) | Você já tem IdP corporativo (Google Workspace, Okta, Azure AD). Permite SSO real e Spaces compartilhados. |
| **IAM Federated** | Conta de teste isolada. Mais rápido de configurar mas menos realista. |

Para o webinar, **IAM Identity Center** dá uma demo mais convincente — usuários "fulano@empresa.com" em vez de IDs IAM.

Setup mínimo:
1. Habilitar IAM Identity Center na mesma região do Amazon Quick.
2. Criar 4 usuários teste: `juridico-demo@`, `comercial-demo@`, `rh-demo@`, `financeiro-demo@`.
3. Atribuir cada um a uma **Automation Group** correspondente no Amazon Quick (isola dados por área).

## 3. Conectores necessários por demo

| Demo | Knowledge | Action |
|---|---|---|
| **01 Jurídico** | S3 (PDFs de contratos) | Outlook (envio de resumo) |
| **02 Comercial** | HubSpot (deals + companies) + S3 (snapshot pipeline opcional) | HubSpot (note/task no deal) + Outlook + Slack |
| **03 RH** | S3 (PDFs de políticas) | ClickUp (criar task) + Outlook |
| **04 Financeiro** | S3 (CSVs + PDFs apoio) | Outlook + Slack |

### Como adicionar conector S3 (todas as demos precisam)

1. Amazon Quick → **Data sources** → **Add data source** → **Amazon S3**.
2. Apontar para o bucket `quick-demo-{area}-{conta}` (criar um por área).
3. IAM role: o wizard cria automaticamente; revisar policy pra dar `s3:GetObject` apenas no bucket específico.

### Conector HubSpot (Demo 02)

HubSpot é **conector nativo** do Amazon Quick:

1. Criar conta HubSpot Free em [[br.hubspot.com](https://br.hubspot.com/)]
2. Customizar pipeline (renomear stages para Discovery, Qualification, Proposal, Negotiation, Closed Won)
3. Criar custom properties: `Health Score` (deal), `Last Activity Days` (deal), `CSAT Score` (company), `Open Tickets` (company)
4. Importar 8 deals + 8 companies (CSVs em [01-dados-sinteticos.md](01-dados-sinteticos.md))
5. Amazon Quick → **Actions & Integrations** → **HubSpot** → **Connect**
6. OAuth com escopos: `crm.objects.deals.read/write`, `crm.objects.companies.read/write`, `crm.engagements.notes.write`, `crm.engagements.tasks.write`

### Conector ClickUp (Demo 03)

ClickUp **não está na lista de conectores nativos** do Amazon Quick. Duas opções:

**Opção A — MCP**

1. Gerar Personal Token em ClickUp → Settings → Apps → **Generate**
2. Amazon Quick → **Settings** → **Actions & Integrations** → **Add MCP server**
3. URL: `https://api.clickup.com/mcp` (ou self-hosted via [github.com/clickup/mcp-server-clickup](https://github.com/clickup/mcp-server-clickup))
4. Auth: Personal Token
5. Testar com prompt: `liste as tasks da list Onboarding TI`

**Opção B — Custom OpenAPI connector (recomendada)**

1. Baixar spec OpenAPI da [ClickUp API v2](https://clickup.com/api)
2. **Actions & Integrations** → **Custom action** → upload spec
3. Auth: Bearer (Personal Token ClickUp)
4. Endpoints relevantes:
   - `GET /list/{list_id}/task` — listar
   - `POST /list/{list_id}/task` — criar task
   - `POST /task/{task_id}/comment` — criar comment
   - `PUT /task/{task_id}` — atualizar custom field

### Conector Outlook (todas que enviam email)

1. **Actions & Integrations** → **Outlook** → **Connect**
2. OAuth com conta Microsoft (Outlook.com pessoal ou M365)
3. Permissão necessária: `Mail.Send`

### Conector Slack (Demo 02 e 04)

1. **Actions & Integrations** → **Slack** → **Connect**
2. OAuth com workspace Slack (free tier serve)
3. Permissões: `chat:write`, `channels:read`
4. Adicionar bot manualmente nos canais `#sales-alerts` e `#financeiro-leadership`

## 4. Buckets S3 e dados

```
quick-demo-{conta}/
├── juridico/
│   ├── contrato-prestacao-servicos.pdf
│   ├── nda-fornecedor.pdf
│   └── contrato-locacao.pdf
├── rh/
│   ├── manual-funcionario.pdf
│   ├── politica-ferias.pdf
│   ├── beneficios-2026.pdf
│   └── codigo-conduta.pdf
├── financeiro/
│   ├── budget-2026.csv
│   ├── actuals-q1-2026.csv
│   ├── relatorio-mercado-construcao-q1-2026.pdf
│   └── ata-comite-financeiro-mar-2026.pdf
└── comercial/
    └── pipeline-q2-2026.csv  (snapshot opcional para Quick Sight; dados-fonte vivem no HubSpot)
```

Conteúdo dos arquivos: ver [01-dados-sinteticos.md](01-dados-sinteticos.md).

## 5. Setup HubSpot (Demo 02 — uma vez só)

1. Criar conta HubSpot Free em [free.hubspot.com](https://free.hubspot.com)
2. Customizar Sales Pipeline com stages Discovery / Qualification / Proposal / Negotiation / Closed Won
3. Criar custom properties:
   - **Deal:** `Health Score` (0-100), `Last Activity Days` (number)
   - **Company:** `CSAT Score` (decimal), `Open Tickets` (number)
4. Importar 8 deals + 8 companies via Contacts → Import (CSVs em dados-sinteticos)
5. Verificar Board view (Kanban) do pipeline

## 6. Setup ClickUp (Demo 03 — uma vez só)

1. Criar conta ClickUp Free Forever
2. Criar Workspace `Aurora Demo`
3. Space `Operações` → List `Onboarding TI` (custom fields para equipamento — ver Demo 03)
4. Gerar Personal Token (Settings → Apps → Generate)

## 7. Checklist 1 dia antes do webinar

- [ ] Login funciona em conta limpa (testar em janela anônima)
- [ ] Cada Space carrega documentos sem erro
- [ ] Cada Chat Agent responde 3 perguntas-âncora do roteiro corretamente
- [ ] Conectores Outlook/Slack/HubSpot ainda autorizados (OAuth tokens não expirados)
- [ ] HubSpot custom properties ainda visíveis no agente (testar `liste health score do deal X`)
- [ ] ClickUp Personal Token ainda válido (testar criando 1 task via Quick chat)
- [ ] Quick Flow de cada demo executa end-to-end em <30s
- [ ] Dashboard Quick Sight renderiza em <5s
- [ ] Plano B preparado: screenshots/vídeo gravado de cada demo

## 8. Timeline recomendada

| Quando | O que fazer |
|---|---|
| D-14 | Ativar trial AWS, criar buckets, subir documentos |
| D-12 | Criar conta HubSpot Free, customizar pipeline, importar deals/companies |
| D-12 | Criar conta ClickUp Free, montar List "Onboarding TI" |
| D-10 | Configurar IAM Identity Center, criar usuários demo |
| D-7 | Conectar Outlook/Slack/HubSpot/ClickUp, testar conectores |
| D-5 | Construir Spaces, Chat Agents, Flows de cada demo |
| D-3 | Ensaio completo cronometrado |
| D-1 | Checklist final + gravação backup de cada demo |
| D-0 | Webinar 🎬 |

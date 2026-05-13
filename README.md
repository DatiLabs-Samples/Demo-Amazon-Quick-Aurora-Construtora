# Webinar — Amazon Quick para Áreas de Negócio

Webinar de 45 minutos em PT-BR para usuários de negócio (não-técnicos) das áreas **Jurídico, Comercial, RH e Financeiro**, mostrando como o **Amazon Quick** (anteriormente Quick Suite, originalmente QuickSight) atua como teammate agentic em tarefas do dia a dia.

> **Setup para clonar este sample:** IDs específicos (AWS account, ClickUp workspace/space/list) foram substituídos por placeholders antes da publicação:
> - AWS account `123456789012` — substituir pelo seu account ID em `demos/*/scripts/setup-aws.sh` e em manifests do Quick Sight
> - ClickUp workspace `9999999999`, space `999999999998`, list `999999999999` — substituir pelos IDs reais do output de `setup-clickup.py` em `demos/03-rh/integrations/clickup-ids.md` e `clickup-openapi.json`
> - Tokens (HubSpot `pat-na1-...`, ClickUp `pk_...`) — sempre injetados via env var, nunca versionados

## O que é o Amazon Quick (em 30 segundos)

Workspace agentic da AWS lançado em out/2025. Cinco componentes:

| Componente | Função | Exemplo de uso |
|---|---|---|
| **Quick Sight** | BI / dashboards (o antigo QuickSight) | Dashboard de orçado vs. realizado |
| **Knowledge Base** | Indexação unificada de docs e dados | Manual do funcionário em PDF + dados Salesforce |
| **Quick Research** | Agente de deep research com citações | "Por que a região Sul ficou abaixo do plano?" |
| **Quick Flows** | Workflows agentic no-code | Agente de onboarding cria ticket Jira de equipamento |
| **Quick Automate** | Automação multi-agente cross-departamental | Reconciliação automática de invoices SAP ↔ ServiceNow |

Conectores nativos: SharePoint, Google Drive, Salesforce, ServiceNow, Slack, Outlook, S3, SAP, Snowflake, Redshift, Databricks (50+).

**Trial:** 30 dias, até 25 usuários, fee de infra waived.

## Agenda — 45 min

```
0:00–0:08  Abertura + visão geral Amazon Quick (slides)
0:08–0:13  Tour rápido da interface (live, 5 min)
0:13–0:27  DEMO 1 (~14 min)
0:27–0:41  DEMO 2 (~14 min)
0:41–0:43  Teaser das outras áreas (slides, 2 min)
0:43–0:45  CTA trial + Q&A
```

## Roteiros das 4 demos (testar e escolher 2)

| # | Demo | Persona alvo | Risco ao vivo | Wow factor |
|---|---|---|---|---|
| [01](demos/01-juridico-revisao-contrato.md) | **Jurídico** — Revisão de contrato + extração de cláusulas | Diretor jurídico, advogado interno | Médio | ⭐⭐⭐⭐⭐ |
| [02](demos/02-comercial-account-360.md) | **Comercial** — Account 360 + pipeline forecast (HubSpot CRM Free) | VP Vendas, AE | Baixo (conector nativo) | ⭐⭐⭐⭐ |
| [03](demos/03-rh-onboarding-assistant.md) | **RH** — Assistente de onboarding + Q&A em políticas | Diretor RH, BP | Baixo | ⭐⭐⭐⭐ |
| [04](demos/04-financeiro-variance-analysis.md) | **Financeiro** — Variance analysis + narrativa | CFO, controller, FP&A | Baixo-médio | ⭐⭐⭐⭐⭐ |
| [05](demos/05-executivo-revenue-bridge.md) | **Executivo** — Revenue bridge cross-silo (CRM × Financeiro) | CFO + VP Comercial juntos | Médio | ⭐⭐⭐⭐⭐ |

Recomendação: testar todas e escolher 2 para a versão final. Recomendação inicial = **RH + Financeiro** (menor risco, melhor cobertura dos 5 componentes).

## Setup

- [Pré-requisitos AWS](setup/00-prerequisitos-aws.md)
- [Dados sintéticos PT-BR](setup/01-dados-sinteticos.md)
- [Custos](setup/02-custos.md)
- [Integrações por demo](setup/03-integracoes.md)
- [Empresa-modelo Aurora](setup/04-empresa.md)
- [**Novidades Amazon Quick 2026**](setup/05-novidades-2026.md) ⭐ atualizado 28/04/2026
- [Dados de construtora — contexto setorial](setup/06-dados-construtora.md)

## Referências AWS

- [Página oficial](https://aws.amazon.com/quick/)
- [Pricing](https://aws.amazon.com/quick/pricing/)
- [Jurídico](https://aws.amazon.com/quick/legal/) — [blueprint contract management](https://aws.amazon.com/blogs/machine-learning/build-an-intelligent-contract-management-solution-with-amazon-quick-suite-and-bedrock-agentcore/)
- [Comercial](https://aws.amazon.com/quick/sales/)
- [RH onboarding blog](https://aws.amazon.com/blogs/machine-learning/build-ai-powered-employee-onboarding-agents-with-amazon-quick/)
- [Financeiro](https://aws.amazon.com/quick/finance/)
- [Workshop AWS](https://aws-experience.com/emea/smb/e/91328/amazon-quick-workshop)
- [Starter kit CDK](https://github.com/aws-samples/sample-amazon-quick-suite-starter-kit)

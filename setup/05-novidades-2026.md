# Novidades Amazon Quick — 2026

Linha do tempo dos lançamentos relevantes pro webinar e como cada um se encaixa nas 4 demos. Atualizado em 28/04/2026.

## 28/04/2026 — Quick Desktop App ⭐

> **Lançamento estrutural.** Quick deixa de ser exclusivamente web e vira app nativo Mac/Windows, **proativo** e com knowledge graph local.

| Capacidade | O que muda |
|---|---|
| App desktop nativo | Download Mac/Windows; **não exige conta AWS** para uso pessoal |
| Roda em background | Monitora apps abertos, surge contextualmente |
| **Personal knowledge graph** | Constrói grafo a partir de arquivos locais, calendário, email, apps |
| **Pre-meeting briefings** | Antes da reunião 14h: thread Slack relevante + doc editado ontem + dados do cliente |
| Geração de conteúdo (slides, infográficos, docs) | Direto da conversa, sem editor externo |
| Integrações desktop | Google Workspace, Microsoft 365, Zoom, Salesforce |

**Impacto nas demos:**
- **Demo 02 (Comercial):** abertura nova — "antes da reunião com o Frigorífico Pampa, Quick desktop já te briefa"
- **Demo 04 (Financeiro):** "antes da reunião do comitê, Quick desktop traz variance + ata + relatório de mercado"

[Press release Amazon](https://www.aboutamazon.com/news/aws/amazon-quick-desktop-ai-assistant) | [SiliconANGLE coverage](https://siliconangle.com/2026/04/28/amazon-revamps-quick-proactive-desktop-app-gets-work-done/)

## 28/04/2026 — Snowflake integration for Chat Agents

Chat Agents agora consomem Snowflake nativamente. Útil em qualquer demo cuja fonte primária é data warehouse.

**Impacto:** Demo 04 Financeiro pode mencionar Snowflake como alternativa ao S3 pra dados estruturados em produção.

## 21/04/2026 — Quick Automate trigger/monitor APIs

APIs públicas para disparar e monitorar automation jobs programaticamente.

**Impacto:** valor pro time técnico do cliente — não muda demos diretamente, mas é talking point pra Q&A.

## 14/04/2026 — Visier Vee agent integration (HR)

Quick conecta com Vee, AI assistant do Visier (people analytics), via MCP. HRBPs, finance e ops conseguem dados governados de workforce intelligence direto no Quick chat.

**Impacto:** Demo 03 RH ganha narrativa nova — "se cliente já usa Visier, Vee é citável dentro do Quick chat para perguntas tipo 'qual o turnover do Q1 na regional Nordeste?'"

[AWS announcement](https://aws.amazon.com/about-aws/whats-new/2026/04/amazon-quick-visier-vee/)

## 14/04/2026 — Quick Automate shared file storage

Storage embutido nos automation jobs. Drag-and-drop de arquivos sem precisar S3/conector externo.

**Impacto:** simplifica demos de Automate (não escopo do nosso webinar), mas vale citar.

## 07/04/2026 — Document-level ACLs em S3 Knowledge Bases

Permissões granulares por documento, via:
- **Global ACL config file** (centralizado, controle por pasta)
- **Per-document metadata files** (atualização rápida individual)

**Impacto:** Demo 01 Jurídico pode adicionar bloco curto de "governance":
- "Advogado júnior só vê contratos da carteira dele"
- Permission Checker valida acesso

## 07/04/2026 — ACL Permission Checker

Admin entra com email do usuário + documento, sistema retorna se tem acesso.

**Impacto:** Demo 01 — pode mostrar como wow paralelo de governance.

## 09/03/2026 — User Preferences

Usuário pode persistir preferências de chat: layout, agente default, "como me chamar".

**Impacto:** marginal pras demos, mas vale mencionar pra plateia que pergunta sobre customização.

## 20/01/2026 — SPICE expandido

Tamanho maior, ingestão mais rápida, mais data types em SPICE datasets.

**Impacto:** Demo 04 pode citar como argumento de performance pro CFO.

## 27/01/2026 — Third-party agents (Box, Canva, PagerDuty)

Quick chat invoca agentes especializados de Box, Canva, PagerDuty.

**Impacto:** Q&A — "agente de Canva pra gerar slide do resumo executivo direto da conversa".

## 09/10/2025 — Rebrand QuickSight → Amazon Quick

Lançamento da família agentic. Histórico — base do que estamos demonstrando.

---

## Como usar este arquivo no webinar

1. **Slide de "Novidades 2026"** (~2 min na introdução): timeline visual com 3-4 destaques
2. **Talking points por demo** — cada demo cita uma novidade naturalmente:
   - Demo 02: "antes que vocês perguntem — sim, isso já roda no novo desktop app"
   - Demo 04: "Snowflake nativo desde a semana passada"
   - Demo 03: "Visier? Conectado via MCP"
3. **Q&A reserva**: tabela acima resolve "o que mudou recentemente?"

## Sources

- [April 2026 Amazon Quick events](https://aws.amazon.com/blogs/business-intelligence/april-2026-amazon-quick-events/)
- [What's New AWS — Amazon Quick category](https://aws.amazon.com/about-aws/whats-new/recent/?nc1=h_ls)
- [Amazon Quick desktop launch — aboutamazon.com](https://www.aboutamazon.com/news/aws/amazon-quick-desktop-ai-assistant)

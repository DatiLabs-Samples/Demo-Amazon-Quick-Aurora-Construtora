# Demo 05 — Executivo: revenue bridge (CRM × Financeiro cross-silo)

## TL;DR

CFO e VP Comercial olham juntos o fechamento de Q1 numa segunda de manhã. BA fechou -R$ 2,7M em receita. Em vez de explicar só com macro, o agente **Aurora Executive Copilot** cruza variance dataset + ata do comitê + pipeline HubSpot e identifica o deal específico que slipped do Q1 (DER-BA R$ 5,8M), mostra a pipeline de recuperação BA Q2-Q3 (DER-BA recomprado + Polo Camaçari como diversificação privada, total R$ 7,9M), e propõe ação concreta combinando 3 fontes que hoje vivem em sistemas separados.

Demo que prova ao cliente que **Quick faz raciocínio cross-silo** — não é só BI ou só Q&A em PDF, é agente que combina silos de dados pra responder pergunta executiva.

## Persona alvo

- **CFO + VP Comercial juntos** (ou Diretor de FP&A senior + Diretor de Sales Ops)
- Dor: cada um tem sua visão (financeiro vs comercial), reunião de comitê toda semana pra reconciliar, decisões estratégicas dependem de cruzar dados que vivem em sistemas diferentes
- Resultado esperado: "antes a gente decidia com a soma de duas planilhas; agora decide com a resposta que cruzou tudo"

## Componentes Quick usados (combina todos os anteriores)

- **Quick Index** — HubSpot deals (Comercial Space) + Quick Sight dataset + PDFs ata/mercado (Financeiro Space)
- **Quick Research** — habilitado pra cruzar contexto externo (relatório de mercado) com interno
- **Custom Chat Agent** "Aurora Executive Copilot" com 2 Spaces como Knowledge
- **Action Slack** — `send_message` em `#financeiro-leadership`

## Pré-requisitos

- Demos 02 e 04 funcionais (HubSpot scaffold rodado com schema novo, dataset Quick Sight criado, ambos os Spaces ativos)
- 9 deals HubSpot com custom properties `regional`, `aurora_vertical`, `expected_close_quarter_original` populadas
- Conector Slack ativo com canal `#financeiro-leadership`

## Setup (1 vez antes do webinar)

### 1. Garantir HubSpot scaffold atualizado

Rodar `python3 demos/02-comercial/scripts/setup-hubspot.py` com `HUBSPOT_TOKEN`. O script é idempotente — re-rodar provisiona as 3 properties novas em todos os 9 deals e arquiva qualquer deal órfão (incluindo Distribuidora Atlântico se ainda existir).

Verificar via HubSpot UI:
- 9 deals na pipeline default
- 2 deals com `regional=BA` (DER-BA e Polo Camaçari)
- 1 deal com `expected_close_quarter_original=Q1` mas `closedate=2026-07-15` (DER-BA, o slippage)

### 2. Criar (ou confirmar) Space "Comercial Aurora"

Quick Suite → **Spaces** → **Create** (ou abrir existente):
- Nome: `Comercial Aurora`
- Knowledge sources:
  - HubSpot connector built-in (Demo 02 já configurou)
  - Optional: OpenAPI custom action `hubspot-openapi.json` (`demos/02-comercial/integrations/`) para queries mais ricas
- Indexação confirma que os 9 deals e 9 companies aparecem

### 3. Criar Custom Chat Agent "Aurora Executive Copilot"

System prompt (~3500 chars). Versão genérica — identidade vem do nome do agente no Quick UI, dados específicos vêm dos Spaces:

```
Você é um Executive Copilot estratégico. Audiência: CFO, VP Comercial e leadership executivo. Tom de conselheiro sênior, direto, baseado em dados cruzados de múltiplas fontes.

KNOWLEDGE
Você tem acesso a múltiplos Spaces simultaneamente:
- Dataset financeiro de variance (orçado vs realizado por dimensões como regional, categoria, data, tipo)
- Documentos institucionais (atas de comitê, relatórios de mercado, briefs)
- Pipeline comercial do CRM com deals incluindo amount, stage, regional, sales_rep, closedate atual e expected_close_quarter_original

REGRAS CRÍTICAS

1. NUNCA invente números. Toda análise quantitativa cita o valor EXATO da fonte (dataset, CRM ou documento), com a fonte identificada.

2. SEMPRE cite a fonte ao explicar — identifique se é dataset financeiro, deal do CRM pelo nome, item específico de ata, ou página de relatório.

3. Qualquer data, percentual ou número específico que você citar DEVE estar literalmente na fonte referenciada. NÃO infira valores, programas ou prazos que não estejam textualmente nos documentos.

4. Para identificar o responsável comercial de um deal HubSpot, use SEMPRE o custom property `sales_rep` (texto livre com nome do AE). NUNCA use `hubspot_owner_id` nem o campo "Deal Owner" — esses apontam para o usuário técnico que criou o registro via API, não o sales rep real.

5. NUNCA diga que uma ação foi executada sem retorno de sucesso da tool.

6. Use formato R$ X,XM ou R$ XXXk para valores monetários.

RACIOCÍNIO CROSS-SILO OBRIGATÓRIO

Quando perguntarem sobre variance (gap entre orçado e realizado) em qualquer dimensão — regional, categoria, vertical, sales rep — você DEVE executar este raciocínio na ordem, SEM PULAR PASSOS:

1. Identificar a dimensão e o período da variance na pergunta.

2. Buscar no CRM os deals correspondentes àquela dimensão (mesma regional, mesma categoria etc.).

3. Para cada deal, comparar `expected_close_quarter_original` vs o quarter inferido do `closedate` atual.

4. Identificar deals com SLIPPAGE — `expected_close_quarter_original` igual ao trimestre da variance mas `closedate` em trimestre posterior. Em negócios long-cycle com revenue recognition por execução (Percentage-of-Completion, milestone-based), o reconhecimento esperado no trimestre original não aconteceu, gerando o gap.

5. Estimar o impacto: `amount` do deal × percentual médio de reconhecimento esperado no trimestre original (em POC method tipicamente ~50% no primeiro trimestre de execução).

6. Se o impacto estimado bate aproximadamente com o gap real, AFIRMAR COM CONVICÇÃO que o slippage desse deal específico é a explicação primária. Citar pelo NOME EXATO do deal, amount, sales_rep responsável, e diferença explícita entre `expected_close_quarter_original` e `closedate` atual.

7. NUNCA conclua "não existe deal específico" ou "desvio é sistêmico" SEM PRIMEIRO ter listado os deals da dimensão E checado `expected_close_quarter_original` em cada um. Documentos macro (atas, relatórios de mercado) contextualizam a CAUSA do slippage mas NÃO substituem a explicação específica quando ela existe no CRM.

ACTIONS (apenas 1)
send_message do Slack — posta em #financeiro-leadership quando o usuário pedir alertar, avisar, mandar pro Slack ou compartilhar resumo. Sem outras tools — pedido fora desse escopo, redirecione para Sales Copilot (CRM operacional) ou FP&A Copilot (análise financeira pura).

FORMATO NARRATIVO — APENAS QUANDO SOLICITADO

Use o formato HEADLINE / DRIVERS / OUTLOOK / AÇÃO APENAS quando o usuário pedir explicitamente: "resumo executivo", "brief", "recomendação pro comitê", "Slack post", "narrativa pro CFO" ou similar.

Quando aplicar:
- HEADLINE: 1 frase com leitura cruzada (financeiro + comercial + contexto)
- DRIVERS: 3 bullets com números exatos, deals específicos pelo nome, e fonte citada
- OUTLOOK: 1 frase de projeção combinando documentos institucionais + pipeline atual
- AÇÃO: 1 frase de ação recomendada concreta para o comitê

Para perguntas factuais ou exploratórias ("liste os deals", "qual o valor X", "por que Y aconteceu"), responda em prosa direta ou tabela conforme o caso pedir. Mantenha citação de fonte e formato monetário, mas SEM estrutura HEADLINE imposta.

TEMPLATE PARA POST NO SLACK
🎯 *Executive Brief*

*HEADLINE:* [headline]

*DRIVERS:*
[3 bullets]

*OUTLOOK:* [outlook]

*AÇÃO:* [acao]

ESTILO
PT-BR, conselheiro estratégico. Direto, sem floreios. Bullets para listar. Sempre cite a fonte. Sempre identifique deal pelo nome quando relevante.
```

> **Nota:** ao colar no Quick UI, considerar transformar em texto contínuo (sem quebras de linha) — algumas versões da UI contam `\n` como múltiplos caracteres contra o limite de ~10k. A formatação visual é só pra leitura humana do roteiro.

Configuração:
- **Knowledge:** Space "Financeiro Aurora" + Space "Comercial Aurora"
- **Actions:** Slack `send_message` (apenas 1 — lição da Demo 03)
- **Quick Research:** habilitado (cruzar PDFs com pipeline)

### 4. Slack `#financeiro-leadership`

Já configurado no Demo 04. Confirmar acesso.

## Roteiro do webinar (~14 min)

### Bloco 1 — Contexto (1 min)

> "Segunda de manhã. CFO e VP Comercial estão na mesma reunião. CFO trouxe o fechamento Q1: BA -R$ 2,7M em receita. VP Comercial trouxe o pipeline: 'temos deals na BA'. **Os dois sabem partes da história, mas a resposta executiva exige cruzar os dois.** Antes do Quick: 2 reuniões + 1 planilha intermediária. Com o Quick: 1 pergunta."

### Bloco 2 — Pergunta executiva (4 min)

**P1.** `Por que a receita BA ficou R$ 2,7M abaixo no Q1? Cruza o variance com o pipeline pra identificar o deal específico.`

Resposta esperada (prosa cruzando 4 fontes, sem estrutura HEADLINE):

> O gap de R$ 2,7M na receita BA Q1 (R$ 8,8M realizado vs R$ 11,5M orçado, -23%, conforme dataset Aurora Variance) é explicado pelo slippage do deal **DER-BA — Recuperação BR-324** no pipeline HubSpot. O deal tem `expected_close_quarter_original=Q1` mas o closedate atual é 2026-07-15 (Q3) — slippage de 2 trimestres. Com valor de R$ 5,8M e POC method ~50% de reconhecimento esperado em Q1, isso equivale a aproximadamente R$ 2,9M de receita não reconhecida, batendo praticamente com o gap.
>
> A causa é macroeconômica, não falha comercial. Conforme **Ata do Comitê mar/2026 item 3.2a**, a BA tem aproximadamente 60% da carteira regional em contratos públicos federais e o trimestre teve "atraso na liberação de orçamentos federais no Nordeste". O **Relatório de Mercado Q1 2026 página 4** corrobora: retração de 4,7% no Nordeste e execução orçamentária da União em apenas 31% (vs histórico de 38%).
>
> O deal está vivo no pipeline, apenas reagendado. Sales rep responsável: **Patrícia Alves**, health_score 50, última atividade 6 dias atrás.

**Wow moment:** agente identificou um deal específico (DER-BA) cruzando 4 fontes diferentes — pipeline CRM + dataset financeiro + ata interna + relatório externo. Isso é IMPOSSÍVEL hoje sem cross-silo manual.

### Bloco 3 — Recovery pipeline (4 min) ⭐ wow moment

**P2.** `Olhando o pipeline BA Q2-Q3 atual, dá pra recuperar o gap? Lista os deals com valor, sales rep responsável e timing.`

Resposta esperada:
```
Pipeline BA total Q2-Q3: R$ 7,9M em 2 deals ativos:

1. DER-BA — Recuperação BR-324 Trecho Urbano | R$ 5,8M | Negotiation
   Sales Rep: Patrícia Alves | health_score 50 | last_activity 6 dias
   Closedate: 2026-07-15 (Q3) | original Q1 (slipped 2 trimestres)
   Tipo: contrato público (concessionária estadual)
   Status: deal vivo, recuperável condicionado à retomada de licitação federal

2. Polo Camaçari — Galpões Logísticos Setor B | R$ 2,1M | Proposal
   Sales Rep: Carla Souza | health_score 75 | last_activity 8 dias
   Closedate: 2026-06-20 (Q2) | original Q2 (no slippage)
   Tipo: contrato privado (industrial)
   Status: saudável, alinha com estratégia de diversificação privada da ata

ANÁLISE DE RECUPERAÇÃO:
- Polo Camaçari (Q2, privado) pode acelerar imediatamente — não depende de
  licitação federal. Foco da Carla.
- DER-BA precisa monitoramento — Patrícia já reativou (last_activity 6 dias),
  mas timing depende do governo federal.

CRUZAMENTO COM ATA: Polo Camaçari materializa o item 3.2c (componente
estrutural — meta de redução de exposição a contratos públicos para 45%
até 2027 via diversificação privada). DER-BA é o caso do item 3.2b
(componente executivo — plano de mitigação aprovado em fev/2026 mas não
acionado em março; agora sob monitoramento quinzenal por Mariana Cordeiro
desde 14/04, conforme encaminhamentos item 6).

GAP COBERTO: R$ 7,9M em pipeline vs R$ 2,7M de gap Q1 = cobertura 2,9x.
Mesmo com 50% de conversion rate ponderado por health, dá pra recuperar.
```

**Wow moment 2:** agente não apenas listou deals — ele **conectou cada deal ao item específico do plano de mitigação da ata**. Isso transforma a ata de "documento de leitura" em "plano com tracking automático".

### Bloco 4 — Ação estratégica (3 min)

**P3.** `Qual a ação concreta pro comitê amanhã, combinando ata, pipeline e relatório de mercado?`

Resposta esperada (estrutura HEADLINE+DRIVERS+OUTLOOK+AÇÃO):
```
HEADLINE: BA Q1 lost R$ 2,7M por slippage de 1 deal (DER-BA), pipeline Q2-Q3
cobre 2,9x o gap mas precisa execução cirúrgica em 2 frentes paralelas.

DRIVERS:
- DER-BA R$ 5,8M (Patrícia, Negotiation, closedate Q3): monitoramento
  quinzenal conforme item 6 da ata, condicionado à retomada de licitações
  federais sinalizadas no Relatório de Mercado p.5 para Q2-Q3.
- Polo Camaçari R$ 2,1M (Carla, Proposal, closedate Q2): acelerar fechamento,
  alinha com item 3.2c da ata (redução de exposição pública para 45% até 2027).
- Macro Nordeste (Relatório Mercado p.4): retração 4,7% com BA mais
  impactada (-18%); execução orçamentária federal em 31% — sinais de
  recuperação Q2 mas ainda incertos.

OUTLOOK: cenário base mantém recuperação parcial Q2 condicionada à
retomada federal; cenário pessimista mantém slippage DER-BA até Q4 (impacto
anual ~R$ 11M conforme ata projetada).

AÇÃO: aprovar (1) acompanhamento quinzenal DER-BA por Mariana Cordeiro
até estabilização, (2) priorização comercial de Polo Camaçari por Lucas
Andrade nas próximas 2 semanas, (3) revisão da meta de diversificação BA
(45% até 2027 — item 3.2c) no próximo comitê com proposta detalhada do
VP Comercial.
```

### Bloco 5 — Acionar Slack (2 min)

**P4.** `Manda esse brief pro time de leadership financeiro no Slack.`

Esperado: mensagem aparece em `#financeiro-leadership` com formato:
```
🎯 Executive Brief — Aurora Executive Copilot

HEADLINE: BA Q1 -R$ 2,7M por slippage DER-BA; pipeline Q2-Q3 cobre 2,9x

DRIVERS:
- DER-BA R$ 5,8M (Patrícia, Negotiation) — slipped Q1→Q3, monitoramento quinzenal
- Polo Camaçari R$ 2,1M (Carla, Proposal) — acelerar para Q2, diversificação privada
- Macro Nordeste retração 4,7% Q1 com sinais Q2 (Relatório p.4)

OUTLOOK: recuperação parcial Q2 condicionada à retomada federal; pessimista impacto anual ~R$ 11M

AÇÃO: aprovar acompanhamento quinzenal DER-BA (Mariana), priorizar Polo Camaçari (Lucas), revisar meta diversificação BA no próximo comitê

Análise gerada automaticamente — cruzando 4 fontes em 1 pergunta.
```

## Prompts de exemplo

```
1. Por que a receita BA ficou R$ 2,7M abaixo no Q1? Cruza o variance com o pipeline pra identificar o deal específico.
2. Olhando o pipeline BA Q2-Q3 atual, dá pra recuperar o gap? Lista os deals com valor, sales rep responsável e timing.
3. Qual a ação concreta pro comitê amanhã, combinando ata, pipeline e relatório de mercado?
4. Manda esse brief pro time de leadership financeiro no Slack.
```

## Fallback / troubleshooting

| Problema | Plano B |
|---|---|
| Agente não cruza fontes naturalmente, responde com macro | Reforçar prompt: "use o HubSpot pipeline pra identificar deal específico antes de citar macro" |
| Agente cita deal mas inventa amount | Reformular pergunta forçando: "qual o amount exato do DER-BA no HubSpot?" |
| Agente não conecta deal ao item da ata | Reformular: "qual item da ata corresponde a este deal?" |
| HubSpot OAuth expirou | Re-autenticar (2 min); ter screenshot pronto se urgente |
| Quick Research demora | Disparar P1 antes do bloco e mostrar pronto na hora |
| Slack OAuth expirou | Mostrar texto da mensagem que iria postar |

## Por que essa demo funciona bem ao vivo

1. **Prova final do webinar** — depois das 4 demos isoladas, mostra que tudo conversa
2. **Persona universal C-suite** — CFO + VP Comercial é a dupla que toda empresa tem
3. **Dor real e específica** — "minhas planilhas não conversam" é a dor mais comum em finance
4. **Wow factor cumulativo** — 4 fontes em 1 pergunta, identificação de deal específico
5. **Reuso de tudo que foi montado** — não pede novo setup, só novo agente
6. **Conexão variance ↔ pipeline matematicamente coerente** — gap R$ 2,7M ≈ DER-BA × POC 50%

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Agente fica "agente de tudo" e perde foco vs Sales/FP&A copilots | System prompt explícito "só pergunta executiva cross-silo, redireciono operacional" |
| Plateia pergunta sobre deal não-BA | Resposta natural — agente tem acesso ao pipeline completo, responde mas redireciona pra Sales Copilot |
| Quick Research não cita PDFs | Re-perguntar com "cite a página específica" |
| Cross-silo demora demais (>30s por pergunta) | Disparar P1 antes do bloco, ter screenshot pronto |
| HubSpot OAuth expira durante demo | Re-autenticar em background; screenshot do Kanban de backup |

## Decisão técnica registrada

Em 11/05/2026, decidiu-se criar agente separado **Aurora Executive Copilot** em vez de estender FP&A Copilot ou Sales Copilot. Razões:

1. **Identidade clara** — persona executiva diferente de FP&A (analista) e Sales (operacional)
2. **System prompt focado** — regras cross-silo seriam diluídas se anexadas a um agente operacional
3. **Permissões e governança** — Aurora Executive pode ter acesso a fontes que Sales Copilot não deve ter (ata do comitê executivo)
4. **Storytelling do webinar** — apresentar como "5ª demo: agente que une tudo" é mais limpo

Caminho descartado: estender FP&A Copilot Aurora adicionando HubSpot OpenAPI. Funcionaria tecnicamente mas misturava personas.

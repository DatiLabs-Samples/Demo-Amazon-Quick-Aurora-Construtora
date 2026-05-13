# Demo 04 — Financeiro: Variance analysis + narrativa automática

## TL;DR

Controller pergunta "como fechou o Q1?" e em 3 minutos tem: dashboard de orçado vs. realizado por regional, identificação automática do desvio crítico (BA -23%), explicação com **citação a relatório de mercado e ata de comitê**, e alerta no Slack `#financeiro-leadership` com a narrativa pronta. Fechamento mensal vira "fechamento contínuo".

## Persona alvo

- **CFO / Controller / FP&A / Analista Financeiro Sênior**
- Dor: variance analysis manual, narrativa do CFO escrita à mão toda semana, "porquês" descobertos tarde demais
- Resultado esperado: "deixei de explicar o passado, comecei a antecipar o futuro"

## Componentes Quick usados (cobre os 5)

- **Quick Sight** — dashboard budget vs. actual
- **Quick Index** — CSVs + PDFs de mercado e ata
- **Quick Research** — agente que explica desvios citando fontes
- **Custom Chat Agent** "FP&A Copilot Aurora"
- **Quick Flow** "Variance Brief Semanal" — alerta Slack `#financeiro-leadership`

## Pré-requisitos

- 2 CSVs em `s3://qx3vp-aurora-demo-123456789012/financeiro/`
- 2 PDFs em `s3://qx3vp-aurora-demo-123456789012/financeiro/`
- Conector Slack ativo (do Demo 01)
- Quick Research habilitado no agente
- Setup AWS (S3 + bucket policy) já feito pelo Demo 01

## Setup (1 vez antes do webinar)

### 0. Artefatos prontos

Estrutura em `demos/04-financeiro/`:

```
demos/04-financeiro/
├── data/
│   ├── budget-2026.csv         (12 linhas — 4 regionais × 3 categorias × 6 meses)
│   └── actuals-q1-2026.csv     (12 linhas — Q1 realizado, com BA -23% baked in)
├── docs/
│   ├── relatorio-mercado-construcao-q1-2026.md/.pdf  (8 páginas)
│   └── ata-comite-financeiro-mar-2026.md/.pdf        (4 páginas — item 3.2 sobre BA é o gancho)
└── scripts/
    ├── convert-pdfs.sh         (Markdown → PDF via pandoc + weasyprint)
    └── setup-aws.sh            (upload S3, idempotente)
```

Para regenerar artefatos:

```bash
cd demos/04-financeiro
./scripts/convert-pdfs.sh    # gera os 2 PDFs
./scripts/setup-aws.sh       # uploada PDFs + CSVs em s3://.../financeiro/
```

### 1. Criar dataset Quick Sight

1. Quick console → **Datasets** → **New** → **S3**
2. Manifest JSON apontando para os 2 CSVs:
   ```json
   {
     "fileLocations": [
       {
         "URIs": [
           "s3://qx3vp-aurora-demo-123456789012/financeiro/budget-2026.csv",
           "s3://qx3vp-aurora-demo-123456789012/financeiro/actuals-q1-2026.csv"
         ]
       }
     ],
     "globalUploadSettings": {
       "format": "CSV",
       "delimiter": ",",
       "textqualifier": "\"",
       "containsHeader": "true"
     }
   }
   ```
3. Após import, criar **calculated fields**:
   - `desvio_abs = actual - budget` (precisa de join entre datasets ou unpivot manual)
   - `desvio_pct = (actual - budget) / budget`
4. Salvar como `Aurora Budget vs Actual 2026`

> **Dica simplificada:** se o join for complexo, criar um **único CSV combinado** com colunas `regional, categoria, mes, valor, tipo (budget|actual)` e usar pivot na visualização. Mais previsível ao vivo.

### 2. Construir dashboard via NL prompt

1. **Analyses** → **Create new** → escolher dataset
2. **Build with AI**:

```
Crie um dashboard executivo de orçado vs. realizado para Q1 2026 com:
1. KPI total receita realizada vs. orçada e desvio percentual
2. Mapa do Brasil colorido por desvio percentual da receita por regional
3. Tabela detalhada por regional e categoria com colunas: orçado, realizado, desvio R$, desvio %
4. Alerta visual em vermelho para regionais com desvio percentual menor que -10%
5. Gráfico de barras de tendência mensal por regional
```

Salvar como `Aurora — Variance Q1 2026 Dashboard`.

### 3. Criar Space "Financeiro Aurora"

1. Quick chat → **Spaces** → **Create**
2. Nome: `Financeiro Aurora`
3. Descrição: `Dados financeiros 2026 da Aurora Construtora — orçado, realizado, relatórios de mercado e atas de comitê.`
4. **Knowledge sources:**
   - Dataset `Aurora Budget vs Actual 2026`
   - S3 prefix `s3://qx3vp-aurora-demo-123456789012/financeiro/` (para os 2 PDFs serem indexados)
5. Aguardar indexação (~3-5 min)

### 4. Criar Custom Chat Agent "FP&A Copilot Aurora"

System prompt:

```
# IDENTIDADE

Você é o FP&A Copilot da Aurora Construtora Ltda. Sua audiência é CFO, Controller, analistas FP&A e leadership executivo. Tom: analista financeiro sênior, direto, baseado em dados.

# ESCOPO DE DADOS

Você tem acesso aos dados financeiros 2026 da Aurora indexados no Space "Financeiro Aurora":

1. Dataset `Aurora Budget vs Actual 2026` — orçado mensal por regional e categoria, e realizado de Q1 2026
2. Documento `relatorio-mercado-construcao-q1-2026.pdf` — relatório externo de mercado da construção civil brasileira
3. Documento `ata-comite-financeiro-mar-2026.pdf` — ata interna do comitê financeiro de março/2026

Regionais cobertas: SP, RJ, MG, BA. Categorias: Receita, Custo Direto, Despesa Operacional.

# RESPONSABILIDADES

1. Toda análise quantitativa cita o número exato (orçado, realizado, desvio em R$ e %).
2. Toda explicação qualitativa cita a fonte do documento com página específica — exemplo "conforme Ata do Comitê Financeiro de mar/2026, item 3.2".
3. Use formato R$ XM ou R$ XK para legibilidade — exemplo R$ 17,8M, R$ 890K.
4. Sempre identifique tendências antes de explicar pontos isolados.
5. Para cada desvio relevante (acima de 5% absoluto), proponha:
   - Causa provável com fonte citada
   - Risco financeiro projetado se a tendência continuar
   - Ação recomendada concreta

# COMO USAR O QUICK FLOW "Variance Brief Semanal"

Quando o usuário pedir explícita ou implicitamente para "alertar", "avisar", "comunicar liderança", "mandar pro Slack" ou "compartilhar resumo" sobre variance, você DEVE invocar o Quick Flow chamado "Variance Brief Semanal".

Esse flow posta em #financeiro-leadership no Slack. Use exatamente estes nomes de input:

- headline (string): uma frase de resumo executivo
- drivers (string): os 3 principais drivers do desvio em formato bullet
- outlook (string): projeção se a tendência continuar
- action (string): ação recomendada concreta para o comitê

# REGRAS CRÍTICAS

1. NUNCA invente sucesso. Você só pode afirmar que o brief foi enviado SE o flow tiver sido efetivamente invocado e retornado sucesso.

2. SEMPRE referencie o flow pelo nome exato: "Variance Brief Semanal".

3. NUNCA mencione canais Slack inexistentes — o flow já está hardcoded para postar em #financeiro-leadership.

4. Se o flow não estiver disponível, use a action Slack send_message direto em #financeiro-leadership com formato similar ao do flow.

5. NUNCA invente números — sempre extraia do dataset. Se o dado não estiver disponível, diga "esse dado não está no dataset indexado".

# FORMATO NARRATIVO PADRÃO PARA CFO

Quando solicitado resumo executivo:
- 1 frase de headline com a leitura do trimestre
- 3 bullets de drivers principais com números e causas
- 1 frase de outlook com projeção
- 1 frase de ação recomendada concreta
```

Knowledge: Space "Financeiro Aurora".
Actions: Slack (Quick Flow "Variance Brief Semanal").

### 5. Habilitar Quick Research no agente

Em **Agent settings → Tools** ou **Capabilities**, ativar **Research**. Isso permite o agente cruzar dados financeiros com PDFs de mercado e citar páginas.

### 6. Criar Quick Flow "Variance Brief Semanal"

Trigger: chamada do agente com 4 inputs:

| Input | Type | Required | Description |
|---|---|---|---|
| `headline` | String | ✓ | 1 frase de headline executiva |
| `drivers` | String | ✓ | 3 bullets de drivers principais |
| `outlook` | String | ✓ | Projeção/outlook |
| `action` | String | ✓ | Ação recomendada |

Step único — **Slack** post em `#financeiro-leadership`:

```
📊 *Variance Brief Q1 — FP&A Copilot Aurora*

*HEADLINE:* {{input.headline}}

*DRIVERS:*
{{input.drivers}}

*OUTLOOK:* {{input.outlook}}

*AÇÃO:* {{input.action}}

_Análise gerada automaticamente — {{system.timestamp}}_
```

Salvar e publicar.

### 7. Vincular Slack ao agent

FP&A Copilot Aurora → Edit → seção **Actions** → **Link** → marcar **Slack** → marcar `send_message` → Link → Update preview → Launch.

## Roteiro do webinar (~16 min)

### Bloco 1 — Contexto (1 min)

> "Você é o controller. Domingo à noite. Reunião do comitê executivo amanhã 9h. CEO vai perguntar: 'como fechou o Q1?' e o que tá por trás dos números. **Antes mesmo de você abrir o computador segunda de manhã, o app desktop do Quick já te briefou**: variance de Q1 destacando BA, links pra ata de mar/2026 do comitê financeiro e pro relatório de mercado de construção Nordeste. Tudo em background, sem você precisar pedir."

> *Talking point opcional:* o **app desktop foi anunciado em 28/04/2026** com personal knowledge graph local e pre-meeting briefings. Em produção, conecta direto no Snowflake (anúncio Snowflake-chat também de 28/04).

### Bloco 2 — Dashboard (3 min)

1. Abrir `Aurora — Variance Q1 2026 Dashboard`
2. Mostrar:
   - Receita Q1 realizada: ~R$ 89,9M | orçada: ~R$ 95M | **desvio -5,4%**
   - Mapa: BA destacada em vermelho intenso (-23%), MG em verde claro (+2%)
   - Tabela detalhada por regional
3. **Falar:** "esse dashboard foi gerado por prompt. Eu não montei nenhum gráfico — pedi em uma frase."

### Bloco 3 — Pergunta executiva ao agente (3 min)

**P1.** `Como fechou o Q1 da Aurora? Me dá o resumo executivo no formato padrão pro CFO.`

Resposta esperada:
```
HEADLINE: Q1 fechou 5,4% abaixo do orçado em receita, com BA puxando o desvio (-23%); MG e SP em linha.

DRIVERS:
- BA: receita realizada R$ 8,8M vs. orçada R$ 11,5M (-R$ 2,7M / -23%) — concentrado em janeiro
- SP: leve pressão de custo direto (+1,5% em março) sem comprometer margem ainda
- MG: ligeiramente acima (+2% receita, -1% custo) — região farol do trimestre

OUTLOOK: se a tendência da BA persistir, impacto anual projetado é de ~R$ 11M de receita perdida.

AÇÃO: priorizar execução do plano de mitigação BA registrado em ata de mar/2026; replicar boas práticas operacionais de MG nas demais regionais.
```

### Bloco 4 — Quick Research: por que a BA caiu? (4 min) ⭐ wow moment

**P2.** `Por que a regional BA ficou tão abaixo do plano? Cita as fontes que usou.`

Resposta esperada (mostra Quick Research em ação — citações inline):

```
A queda na BA tem 2 causas combinadas, suportadas por fontes externas e internas:

1. Atraso em obras públicas — Componente conjuntural
   O Relatório de Mercado de Construção Q1/2026 (página 4) registra retração agregada de
   4,7% na atividade do setor no Nordeste no Q1, com BA como o estado mais impactado
   (-18% na demanda agregada entre janeiro e fevereiro). A causa é o atraso na liberação
   de orçamentos federais — a execução do orçamento de investimentos da União ficou em
   31% no Q1 contra histórico médio de 38%.
   [📎 relatorio-mercado-construcao-q1-2026.pdf, p. 4]

   A BA é particularmente exposta: aproximadamente 60% da carteira regional é de
   contratos públicos.
   [📎 ata-comite-financeiro-mar-2026.pdf, item 3.2]

2. Risco já mapeado internamente — Componente executivo
   A Ata do Comitê Financeiro de março/2026 (item 3.2) registra que o risco da BA havia
   sido identificado já na reunião de fevereiro, com plano de mitigação aprovado mas
   NÃO acionado durante o mês de março. O comitê determinou execução imediata a partir
   de 31/03.
   [📎 ata-comite-financeiro-mar-2026.pdf, item 3.2]

Conclusão: o desvio de R$ 2,7M no Q1 tem grande componente conjuntural (mercado), mas
há também componente executivo relevante (mitigação não executada tempestivamente).
```

**Wow moment:** o agente *cruzou dados financeiros + PDF de mercado externo + ata interna* e citou fontes específicas com paginação. Isso é o diferencial sobre BI tradicional.

### Bloco 5 — Reconciliação de fontes (2 min) ⭐ momento de credibilidade

**P3.** `A ata do comitê fala que a receita Q1 fechou em R$ 89,9M com desvio de -5,4%. Mas o dashboard mostra R$ 104,5M, desvio -2,7%. Qual número eu confio? Como explico isso pro CFO?`

Resposta esperada (agente reconcilia em vez de escolher):
```
Os dois números estão corretos, mas refletem momentos diferentes do fechamento:

1. Ata do Comitê (26/03/2026, item 2): R$ 89,9M / orçado R$ 95,0M / -5,4%
   - Snapshot preliminar apresentado pela VP Financeiro na reunião do comitê
   - Fechamento contábil definitivo previsto para 10/04 (ata, item 2)

2. Dashboard / dataset: R$ 104,5M / orçado R$ 107,4M / -2,7%
   - Reflete a posição atual com faturamentos late incorporados após a ata
   - Inclui ajustes contábeis do fechamento posterior

Diferença de R$ 14,6M na receita realizada explica-se por:
- Faturamentos late de SP e RJ entrando após o fechamento da ata
- Ajustes de revenue recognition em contratos plurianuais
- Não há indicação de melhora operacional - é puramente reconhecimento posterior

Recomendação para o CFO:
- Apresentar o número atualizado: R$ 104,5M / -2,7%
- Sinalizar que a leitura preliminar do comitê apontava -5,4% (mais conservadora)
- Manter o foco no diagnóstico de BA - o desvio regional de -23% é o tema central, independente do total consolidado
```

**Por que essa pergunta é importante:** finance team **convive com isso todo dia** (BI vs reportado, snapshot vs current, dataset vs ata). O agente não escolhe uma fonte cegamente — explica a divergência. Mostra que o agente não é só retrieval de fato isolado, é raciocínio sobre múltiplas fontes.

### Bloco 6 — Forecast e próximo passo (2 min)

**P4.** `Se a BA continuar nesse ritmo, qual o impacto na receita anual? E qual ação eu apresento amanhã?`

Resposta esperada:
```
Projeção BA 2026 mantendo desvio de Q1:
- Receita anual orçada: R$ 47M
- Realizada projetada: R$ 36M
- Gap: R$ 11M (-23%)

Conforme a Ata do Comitê de mar/2026 (item 6 — encaminhamentos), o plano de mitigação
aprovado contempla 3 ações já endossadas pelo comitê:

1. Realocação tática de capacidade ociosa de BA para SP/MG (margem mais alta)
2. Antecipação de pleitos comerciais privados na BA para diversificar fonte de receita
3. Acompanhamento quinzenal pela VP Financeiro até estabilização

Ação recomendada para o comitê amanhã:
1. Confirmar acionamento do plano BA na semana de 31/03 (responsável: VP Operações)
2. Validar timing de retomada das licitações federais no Q2
3. Aprovar revisão da meta de diversificação da carteira regional
4. Definir checkpoint quinzenal até Q2 estabilizar
```

### Bloco 7 — Acionar Slack (1 min)

**P5.** `Manda esse brief pro time de leadership financeiro no Slack.`

Quick Flow `Variance Brief Semanal` dispara → mostra ao vivo:

1. Aba Slack → canal `#financeiro-leadership`
2. Mensagem aparece com formato:
   ```
   📊 Variance Brief Q1 — FP&A Copilot Aurora

   HEADLINE: Q1 fechou 5,4% abaixo do orçado em receita, com BA puxando o desvio (-23%)

   DRIVERS:
   - BA: receita realizada R$ 8,8M vs. orçada R$ 11,5M (-R$ 2,7M / -23%)
   - SP: leve pressão de custo direto (+1,5% em março)
   - MG: ligeiramente acima (+2% receita, -1% custo) — região farol

   OUTLOOK: se a tendência BA persistir, impacto anual projetado é de R$ 11M de receita perdida

   AÇÃO: acionar plano de mitigação BA aprovado em ata mar/2026; revisão quinzenal até estabilizar
   ```

> "Em produção, isso roda toda segunda-feira de manhã antes do CFO chegar."

## Prompts de exemplo

```
1. Como fechou o Q1 da Aurora? Resumo executivo formato CFO.
2. Por que a regional BA ficou tão abaixo do plano? Cita as fontes.
3. A ata fala em receita Q1 de R$ 89,9M / -5,4% mas o dashboard mostra R$ 104,5M / -2,7%. Qual número eu confio? Como explico isso pro CFO?
4. Se a BA continuar nesse ritmo, qual impacto anual? Qual ação apresento amanhã?
5. Manda esse brief pro time de leadership financeiro no Slack.
```

## Fallback / troubleshooting

| Problema | Plano B |
|---|---|
| Quick Research não cita fontes | Repetir prompt adicionando "cite a página exata do PDF" |
| Dashboard demora carregar | Ter print pronto, dizer "vou usar o cache pra não esperar" |
| Números do dashboard não batem com setup | Não brigar com o agente — dizer "o número é ilustrativo, regra de cálculo é a do seu time" |
| Agent não vê o flow | Verificar que Slack action está linkado ao agent (Edit → Actions → Link Slack) |
| Slack OAuth expirou | Mostrar texto da mensagem que iria postar |
| Dataset Quick Sight com erro | Ter screenshot do dashboard; explicar que dados estão no S3 |

## Por que essa demo é forte

1. **Cobre os 5 componentes** Quick (Sight, Index, Research, Flows, Chat)
2. **Wow factor duplo:** dashboard por NL + Research que cita PDFs com paginação
3. **Persona universal:** todo cliente tem alguém fazendo variance analysis
4. **Dado sintético facilíssimo** — 2 CSVs e 2 PDFs, todos versionados no repo
5. **Narrativa progressiva:** "o quê" (dashboard) → "por quê" (research) → "e agora" (ação) → "comunicar" (flow Slack)
6. **Reuso de Slack do Demo 01** — sem novo setup de canal de ação
7. **Honestidade técnica** — Quick Research é exatamente o tipo de capability que diferencia o Quick de BI clássico

## Risco principal e mitigação

- **Risco:** Quick Research é o componente mais "novo" e variável; pode não citar fontes na primeira tentativa
- **Mitigação:** ensaiar a P2 múltiplas vezes; se ainda assim falhar, ter screenshot da resposta ideal pra mostrar; reformular pergunta com "cite a página específica do PDF"
- **Risco:** dataset CSV + calculated fields pode confundir o agent
- **Mitigação:** criar CSV pré-combinado (regional, categoria, mes, tipo, valor) — mais simples

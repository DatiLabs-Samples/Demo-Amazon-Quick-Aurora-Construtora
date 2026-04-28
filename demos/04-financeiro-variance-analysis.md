# Demo 04 — Financeiro: Variance analysis + narrativa automática

## TL;DR

Controller pergunta "como fechou o Q1?" e em 3 minutos tem: dashboard de orçado vs. realizado por regional, identificação automática do desvio crítico (BA -23%), explicação com **citação a relatório de mercado e ata de comitê**, e email pra liderança com a narrativa pronta. Fechamento mensal vira "fechamento contínuo".

## Persona alvo

- **CFO / Controller / FP&A / Analista Financeiro Sênior**
- Dor: variance analysis manual, narrativa do CFO escrita à mão toda semana, "porquês" descobertos tarde demais
- Resultado esperado: "deixei de explicar o passado, comecei a antecipar o futuro"

## Componentes Quick usados (cobre os 5)

- **Quick Sight** — dashboard budget vs. actual
- **Quick Index** — CSVs + PDFs de mercado e atas
- **Quick Research** — agente que explica desvios citando fontes
- **Custom Chat Agent** "FP&A Copilot"
- **Quick Flow** "Variance Brief Semanal" (envia email + Slack pro CFO)

## Pré-requisitos

- 2 CSVs em `s3://quick-demo-{conta}/financeiro/`
- 2 PDFs de apoio (`relatorio-mercado-construcao-q1-2026.pdf`, `ata-comite-financeiro-mar-2026.pdf`)
- Conector Outlook ativo
- Quick Research habilitado (Enterprise plan)

## Setup (1 vez antes do webinar)

### 1. Criar dataset Quick Sight

1. **Datasets** → **New** → S3 → manifest com 2 CSVs
2. Calcular campos: `desvio_abs = actual - budget` e `desvio_pct = (actual - budget) / budget`
3. Salvar como `Aurora Budget vs Actual 2026`

### 2. Construir dashboard via NL prompt

```
Crie um dashboard executivo de orçado vs. realizado para Q1 2026 com:
1. KPI total receita realizada vs. orçada
2. Mapa do Brasil colorido por desvio percentual
3. Tabela detalhada por regional e categoria com colunas: orçado, realizado, desvio R$, desvio %
4. Alerta visual em vermelho para regionais com desvio < -10%
5. Gráfico de tendência mês a mês
```

Salvar como `Aurora — Variance Q1 2026 Dashboard`.

### 3. Criar Space "Financeiro Aurora"

Knowledge:
- Dataset `Aurora Budget vs Actual 2026`
- PDFs de mercado e ata

### 4. Criar Custom Chat Agent "FP&A Copilot"

System prompt:

```
Você é o FP&A Copilot da Aurora Construtora. Tem acesso aos dados financeiros 2026 e a documentos de mercado e atas de comitê.

Princípios:
1. Toda análise quantitativa cita o número exato (orçado, realizado, desvio R$ e %)
2. Toda explicação qualitativa cita a fonte do documento (ex.: "conforme ata do Comitê Financeiro de mar/2026")
3. Use formato R$ XM ou R$ XK para legibilidade (ex.: R$ 17,8M)
4. Sempre identifique tendências antes de explicar pontos isolados
5. Para cada desvio relevante (>5% absoluto), proponha:
   - Causa provável (com fonte)
   - Risco financeiro projetado se a tendência continuar
   - Ação recomendada

Quando solicitado, dispare Quick Flow "Variance Brief Semanal" com o resumo.

Formato narrativo padrão para CFO:
- 1 frase de headline
- 3 bullets de drivers principais
- 1 frase de outlook
- 1 frase de ação
```

Knowledge: Space "Financeiro Aurora".
Actions: Outlook.

### 5. Habilitar Quick Research neste agente

Em **Agent settings → Tools**, ativar **Research**. Isso permite o agente cruzar dados financeiros com PDFs de mercado.

### 6. Criar Quick Flow "Variance Brief Semanal"

1. **Trigger:** chamada do agente
2. **Step 1:** gerar resumo executivo (template do agente)
3. **Step 2:** enviar email pra `cfo@aurora.com.br` + post no Slack `#financeiro-leadership`
4. Schedule opcional: toda segunda 7h (para a versão "produção", mencionar no webinar mas não ativar)

## Roteiro do webinar (~14 min)

### Bloco 1 — Contexto (1 min)

> "Você é o controller. Domingo à noite. Reunião do comitê executivo amanhã 9h. CEO vai perguntar: 'como fechou o Q1?' e o que tá por trás dos números. **Mas antes de você abrir o computador segunda de manhã, o app desktop do Quick já te briefou**: variance de Q1 destacando BA, links pra ata de mar/2026 do comitê financeiro e pro relatório de mercado de construção Nordeste. Tudo em background, sem você precisar pedir."

> *Talking point opcional:* o **app desktop foi anunciado em 28/04/2026** com personal knowledge graph local e pre-meeting briefings. Em produção, conecta direto no Snowflake (anúncio Snowflake-chat também de 28/04).

### Bloco 2 — Dashboard (3 min)

1. Abrir `Aurora — Variance Q1 2026 Dashboard`
2. Mostrar:
   - Receita Q1 realizada: ~R$ 90M | orçada: ~R$ 95M | **desvio -5,3%**
   - Mapa: BA destacada em vermelho intenso (-23%), MG em verde claro (+2%)
   - Tabela por regional
3. **Dizer:** "esse dashboard foi gerado por prompt. Eu não montei nenhum gráfico."

### Bloco 3 — Pergunta executiva ao agente (3 min)

**P1.** `Como fechou o Q1 da Aurora? Me dá o resumo executivo no formato padrão pro CFO.`

Resposta esperada:
```
HEADLINE: Q1 fechou 5,3% abaixo do orçado em receita, com BA puxando o desvio (-23%); MG e SP em linha.

DRIVERS:
- BA: receita realizada R$ 8,8M vs. orçada R$ 11,5M (−R$ 2,7M / −23%) — concentrado em janeiro
- SP: leve pressão de custo direto (+1,5%) sem refletir em margem comprometida
- MG: levemente acima (+2% receita, −1% custo) — região farol do trimestre

OUTLOOK: se a tendência da BA persistir, impacto anual projetado é de R$ 11M de receita perdida.

AÇÃO: priorizar investigação de causas na BA antes do Q2; replicar boas práticas operacionais de MG.
```

### Bloco 4 — Quick Research: por que a BA caiu? (4 min) ⭐ wow moment

**P2.** `Por que a regional BA ficou tão abaixo do plano? Cita as fontes que usou.`

Resposta esperada (mostra Quick Research em ação — citações inline):

```
A queda na BA tem 2 causas combinadas:

1. **Atraso em obras públicas** — o Relatório de Mercado de Construção Q1/2026 (página 4) registra retração de 18% na demanda do Nordeste em janeiro/fevereiro por atraso na liberação de orçamentos federais. A BA é particularmente exposta: 60% da carteira regional vem de contratos públicos.
   [📎 relatorio-mercado-construcao-q1-2026.pdf, p. 4]

2. **Risco já mapeado internamente** — a Ata do Comitê Financeiro de março/2026 (item 3.2) já registrava preocupação com o pipeline da BA, com plano de mitigação que ainda não havia sido executado.
   [📎 ata-comite-financeiro-mar-2026.pdf, p. 2]

Conclusão: o desvio de R$ 2,7M no Q1 é em grande parte conjuntural (mercado), mas há componente executivo (mitigação não acionada).
```

**Wow moment:** o agente *cruzou dados financeiros + PDFs de mercado + ata interna* e citou fontes específicas com paginação. Isso é o diferencial sobre BI tradicional.

### Bloco 5 — Forecast e próximo passo (2 min)

**P3.** `Se a BA continuar nesse ritmo, qual o impacto na receita anual? E qual ação eu apresento amanhã?`

Resposta esperada:
```
Projeção BA 2026 mantendo desvio Q1:
- Receita anual orçada: R$ 47M
- Realizada projetada: R$ 36M
- Gap: R$ 11M (-23%)

Ação recomendada para o comitê:
1. Acionar plano de mitigação BA registrado em ata de mar/2026 (item 3.2)
2. Realocar capacidade ociosa BA para SP/MG (margem mais alta)
3. Revisar exposição a contratos públicos no portfólio Nordeste
4. Acompanhar com revisão quinzenal até Q2 estabilizar
```

### Bloco 6 — Acionar Quick Flow (1 min)

**P4.** `Manda esse brief pro CFO e pro time de leadership.`

- Quick Flow dispara
- Email aparece no Outlook ao vivo
- Slack: post em `#financeiro-leadership` com resumo de 4 bullets

> "Em produção, isso roda toda segunda-feira de manhã, antes do CFO chegar."

## Prompts de exemplo

```
1. Como fechou o Q1 da Aurora? Resumo executivo formato CFO.
2. Por que a regional BA ficou tão abaixo do plano? Cita as fontes.
3. Se a BA continuar nesse ritmo, qual impacto anual? Qual ação apresento amanhã?
4. Manda esse brief pro CFO e pro time de leadership.
```

## Fallback / troubleshooting

| Problema | Plano B |
|---|---|
| Quick Research não cita fontes | Repetir prompt adicionando "cite a página exata do PDF" |
| Dashboard demora | Ter print pronto, dizer "vou usar o cache pra não esperar" |
| Números não batem com o setup | Não brigar com o agente — dizer "o número é ilustrativo, regra de cálculo é a do seu time" |
| Outlook OAuth expirado | Mostrar texto do email gerado, pular envio |

## Por que essa demo é forte

1. **Cobre os 5 componentes** Quick (Sight, Index, Research, Flows, Chat)
2. **Wow factor duplo:** dashboard por NL + Research que cita PDFs
3. **Persona universal:** todo cliente tem alguém fazendo variance analysis
4. **Dado sintético facilíssimo** — 2 CSVs e 2 PDFs
5. **Narrativa progressiva:** "o quê" (dashboard) → "por quê" (research) → "e agora" (ação)

## Risco principal e mitigação

- **Risco:** Quick Research é o componente mais "novo" e variável; pode não citar fontes na primeira tentativa
- **Mitigação:** ensaiar a P2 múltiplas vezes; se ainda assim falhar, ter screenshot da resposta ideal pra mostrar

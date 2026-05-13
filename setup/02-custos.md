# Custos das demos — Amazon Quick

Câmbio de referência: USD 1 ≈ R$ 5,00 (abr/2026).

## Modelo de pricing — Amazon Quick

| Item | Valor (USD) | Observação |
|---|---|---|
| **Plano Professional** | $20 / usuário / mês | Chat agents, Spaces, Quick Sight (read), Quick Research, Quick Flows. 2h de Research + 2h de Flows/Automate inclusos/mês. 25 GB/usuário. |
| **Plano Enterprise** | $40 / usuário / mês | Tudo do Pro + **autoria** de Quick Sight e Quick Automate. 4h + 4h agent-hours. 50 GB/usuário. |
| **Infra fee** | $250 / conta / mês | **Waived nos 30 dias de trial**. |
| **SPICE storage** | $0,38 / GB / mês | Cache in-memory do Quick Sight. |
| **Reports pixel-perfect** | $1 / report unit / mês | Mínimo 500 reports. |
| **Overage Flows/Automate** | $3 / agent-hour | Após cota inclusa. |
| **Overage Research** | $6 / agent-hour | Research é mais caro porque consome mais compute. |

**Trial:** 30 dias, até 25 usuários, **infra fee gratuita**, agent-hours inclusas. Crédito de overage: zero (cliente é cortado se exceder).

## Cenário 1 — Custo pra gravar/apresentar o webinar

Você cria conta, ativa trial, grava as 4 demos uma vez. Custo **zero** se ficar dentro do trial e dentro das cotas.

Consumo estimado por ensaio completo de cada demo (5-7 perguntas + 1 flow):

| Demo | Agent-h Chat | Agent-h Research | Agent-h Flow | Storage |
|---|---|---|---|---|
| 01 Jurídico | ~0,1 h | 0 | ~0,02 h | ~5 MB |
| 02 Comercial | ~0,1 h | 0 | ~0,02 h | ~1 MB SPICE |
| 03 RH | ~0,15 h | 0 | ~0,05 h (2 ações) | ~10 MB |
| 04 Financeiro | ~0,15 h | **~0,3 h** | ~0,02 h | ~5 MB |

5 ensaios + 1 webinar ao vivo de cada demo = ~6× os números acima. Mesmo assim:
- **Chat:** ~3,3 agent-hours total (≪ 4h Enterprise inclusas)
- **Research:** ~1,8 agent-hours (≪ 4h Enterprise)
- **Flows:** ~0,7 agent-hours (≪ 4h Enterprise)

**Conclusão:** trial cobre tudo. Custo direto AWS = **R$ 0**.

## Cenário 2 — Custo recorrente de produção (cliente adota)

Premissas para um cliente médio que adota a Demo X em produção:
- 1 autor + 5-50 usuários consumidores

### Demo 01 — Jurídico (uso por equipe jurídica de ~5 advogados)

| Item | Quantidade | Custo USD/mês | BRL/mês |
|---|---|---|---|
| Plano Professional | 5 usuários | $100 | R$ 500 |
| Infra fee | 1 conta | $250 | R$ 1.250 |
| Storage S3 (contratos) | < 5 GB | < $1 | < R$ 5 |
| Agent-hours Chat | ~3h/mês | dentro cota | R$ 0 |
| Agent-hours Flows | ~0,5h/mês | dentro cota | R$ 0 |
| **Total mensal** | | **~$351** | **~R$ 1.755** |
| **Por usuário** | | $70 | R$ 351 |

**Não precisa de Enterprise** (sem autoria de dashboard nem Automate).

### Demo 02 — Comercial (time de vendas ~20 pessoas, 1 sales ops autor) — com HubSpot

| Item | Quantidade | Custo USD/mês | BRL/mês |
|---|---|---|---|
| Plano Enterprise (autor SalesOps) | 1 | $40 | R$ 200 |
| Plano Professional (AEs/SDRs) | 19 | $380 | R$ 1.900 |
| Infra fee | 1 conta | $250 | R$ 1.250 |
| SPICE (pipeline + 360) | ~2 GB | $0,76 | R$ 4 |
| Agent-hours Chat | ~10h/mês | dentro cota | R$ 0 |
| Agent-hours Flows | ~3h/mês | dentro cota | R$ 0 |
| **Total mensal** | | **~$671** | **~R$ 3.355** |
| **Por usuário** | | $34 | R$ 168 |

**Custo externo a considerar:** HubSpot Free Forever (sem custo até 1M contacts) ou plano pago se cliente já estiver em Sales Hub Starter (USD 15/usuário). Slack: geralmente já existe.

### Demo 03 — RH (~800 funcionários consumidores, 2 RH autores)

| Item | Quantidade | Custo USD/mês | BRL/mês |
|---|---|---|---|
| Plano Professional (RH + funcionários) | 800 | $16.000 | R$ 80.000 |
| Infra fee | 1 conta | $250 | R$ 1.250 |
| Storage S3 (políticas) | < 1 GB | < $1 | < R$ 5 |
| Agent-hours Chat | ~150h/mês | overage ~50h × $3 | $150 |
| Agent-hours Flows | ~30h/mês | overage 10h × $3 | $30 |
| ClickUp Free (até 5 membros) ou Unlimited ($7/usuário) | — | $0 ou ~$7/usuário | $0 ou ~R$ 35 |
| **Total mensal** | | **~$16.430** | **~R$ 82.150** |
| **Por usuário** | | $20,5 | R$ 102 |

⚠️ **Atenção:** RH escala com headcount. Para 800 pessoas o custo absoluto é alto, mas o **custo por funcionário é R$ 102/mês**. Comparar com:
- Custo médio de helpdesk de RH: R$ 8-15/atendimento
- Estimativa de 1-2 atendimentos/funcionário/mês = R$ 8-30
- **Payback** se Quick reduzir 50% dos atendimentos.

**Otimização possível:** licenciar apenas RH + gestores (~50 usuários) e expor o Chat Agent via **embed em Slack/Teams** — funcionários consultam sem licença Quick. Custo cai pra ~$1.250/mês (~R$ 6.250).

### Demo 04 — Financeiro (FP&A ~10 pessoas, 2 autores)

| Item | Quantidade | Custo USD/mês | BRL/mês |
|---|---|---|---|
| Plano Enterprise (autores) | 2 | $80 | R$ 400 |
| Plano Professional (FP&A + leadership) | 8 | $160 | R$ 800 |
| Infra fee | 1 conta | $250 | R$ 1.250 |
| SPICE (financial datasets) | ~5 GB | $1,90 | R$ 10 |
| Agent-hours Chat | ~5h/mês | dentro cota | R$ 0 |
| Agent-hours **Research** | ~8h/mês | overage 4h × $6 | $24 |
| Agent-hours Flows | ~1h/mês | dentro cota | R$ 0 |
| **Total mensal** | | **~$516** | **~R$ 2.580** |
| **Por usuário** | | $52 | R$ 258 |

⚠️ **Research é o item mais caro** ($6/h overage). Em produção real, monitorar. Se time abusar (analista executa research 30x/dia), conta cresce. Cota Enterprise cobre uso "estratégico", não operacional.

## Resumo comparativo (mensal, em produção)

| Demo | Usuários | Custo total/mês | Por usuário | Plano necessário | Custo externo? |
|---|---|---|---|---|---|
| **01 Jurídico** | 5 | R$ 1.755 | R$ 351 | Professional | Não |
| **02 Comercial** | 20 | R$ 3.355 | R$ 168 | Mix Enterprise/Pro | Salesforce (já existe) |
| **03 RH (full headcount)** | 800 | R$ 82.150 | R$ 102 | Professional | ClickUp Free (até 5) ou Unlimited (~R$ 35/usuário) |
| **03 RH (otimizado)** | 50 + embed | R$ 6.250 | R$ 125 | Professional | Mesmo |
| **04 Financeiro** | 10 | R$ 2.580 | R$ 258 | Mix Enterprise/Pro | Não |

## Observações pra apresentar no webinar

1. **Trial 30 dias é gratuito** — call-to-action óbvio. Cliente testa sem comprometer orçamento.
2. **Infra fee de $250/conta** é o item que pega cliente pequeno desprevenido. Vale destacar.
3. **Research é o componente que mais gera overage** — explicar que é compute-intensivo.
4. **Para demos com grande headcount (RH)**, padrão recomendado é licenciar autores + expor agente em canal corporativo (Slack/Teams) — reduz licenças.
5. **Comparação com QuickSight standalone (legado):** QuickSight Reader era $5/usuário, Author $24. Amazon Quick Professional ($20) é mais caro que Reader mas inclui Chat/Research/Flows que antes não existiam — argumento de valor agregado.

## Cálculo rápido de ROI (slide opcional)

Para a demo de RH (mais escalável):

- Custo médio HR helpdesk no Brasil: R$ 12/atendimento
- 800 funcionários × 1,5 atendimento/mês = 1.200 atendimentos/mês = R$ 14.400/mês
- Amazon Quick captura 50% (autoatendimento): economia R$ 7.200/mês
- Custo Quick (otimizado, 50 licenças + embed): R$ 6.250/mês
- **Payback: imediato. Margem mensal: R$ 950 + tempo liberado do RH.**

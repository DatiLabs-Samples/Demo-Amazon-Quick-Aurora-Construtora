# Custos das demos — Amazon Quick

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
- 1 autor + 3-15 usuários consumidores (mix SMB)

### Demo 01 — Jurídico (uso por equipe jurídica de ~3 advogados)

| Item | Quantidade | Custo USD/mês |
|---|---|---|
| Plano Professional | 3 usuários | $60 |
| Infra fee | 1 conta | $250 |
| Storage S3 (contratos) | < 5 GB | < $1 |
| Agent-hours Chat | ~2h/mês | dentro cota |
| Agent-hours Flows | ~0,3h/mês | dentro cota |
| **Total mensal** | | **~$311** |
| **Por usuário** | | ~$104 |

**Não precisa de Enterprise** (sem autoria de dashboard nem Automate).

### Demo 02 — Comercial (time de vendas ~8 pessoas, 1 sales ops autor) — com HubSpot

| Item | Quantidade | Custo USD/mês |
|---|---|---|
| Plano Enterprise (autor SalesOps) | 1 | $40 |
| Plano Professional (AEs/SDRs) | 7 | $140 |
| Infra fee | 1 conta | $250 |
| SPICE (pipeline + 360) | ~2 GB | $0,76 |
| Agent-hours Chat | ~5h/mês | dentro cota |
| Agent-hours Flows | ~1,5h/mês | dentro cota |
| **Total mensal** | | **~$431** |
| **Por usuário** | | ~$54 |

**Custo externo a considerar:** HubSpot Free Forever (sem custo até 1M contacts) ou plano pago se cliente já estiver em Sales Hub Starter (USD 15/usuário). Slack: geralmente já existe.

### Demo 03 — RH (~100 funcionários consumidores, 2 RH autores)

| Item | Quantidade | Custo USD/mês |
|---|---|---|
| Plano Professional (RH + funcionários) | 100 | $2.000 |
| Infra fee | 1 conta | $250 |
| Storage S3 (políticas) | < 1 GB | < $1 |
| Agent-hours Chat | ~20h/mês | dentro cota |
| Agent-hours Flows | ~5h/mês | dentro cota |
| ClickUp Free (até 5 membros) | — | $0 |
| **Total mensal** | | **~$2.250** |
| **Por usuário** | | ~$23 |

⚠️ **Atenção:** RH escala com headcount. Para 100 pessoas o custo absoluto é alto, mas o **custo por funcionário é ~$23/mês**. Comparar com:
- Custo médio de helpdesk de RH: USD 1,60-3 por atendimento
- Estimativa de 1-2 atendimentos/funcionário/mês = USD 1,60-6
- **Payback** se Quick reduzir 50% dos atendimentos.

**Otimização possível:** licenciar apenas RH + gestores (~10 usuários) e expor o Chat Agent via **embed em Slack/Teams** — funcionários consultam sem licença Quick. Custo cai pra ~$450/mês.

### Demo 04 — Financeiro (FP&A ~5 pessoas, 2 autores)

| Item | Quantidade | Custo USD/mês |
|---|---|---|
| Plano Enterprise (autores) | 2 | $80 |
| Plano Professional (FP&A + leadership) | 3 | $60 |
| Infra fee | 1 conta | $250 |
| SPICE (financial datasets) | ~3 GB | $1,14 |
| Agent-hours Chat | ~3h/mês | dentro cota |
| Agent-hours **Research** | ~5h/mês | overage 1h × $6 | $6 |
| Agent-hours Flows | ~0,5h/mês | dentro cota |
| **Total mensal** | | **~$397** |
| **Por usuário** | | ~$79 |

⚠️ **Research é o item mais caro** ($6/h overage). Em produção real, monitorar. Se time abusar (analista executa research 30x/dia), conta cresce. Cota Enterprise cobre uso "estratégico", não operacional.

## Resumo comparativo (mensal, em produção)

| Demo | Usuários | Custo total/mês (USD) | Por usuário (USD) | Plano necessário | Custo externo? |
|---|---|---|---|---|---|
| **01 Jurídico** | 3 | $311 | ~$104 | Professional | Não |
| **02 Comercial** | 8 | $431 | ~$54 | Mix Enterprise/Pro | HubSpot Free (já existe) |
| **03 RH (full headcount)** | 100 | $2.250 | ~$23 | Professional | ClickUp Free (até 5 membros) |
| **03 RH (otimizado)** | 10 + embed | $450 | ~$45 | Professional | Mesmo |
| **04 Financeiro** | 5 | $397 | ~$79 | Mix Enterprise/Pro | Não |

## Observações pra apresentar no webinar

1. **Trial 30 dias é gratuito** — call-to-action óbvio. Cliente testa sem comprometer orçamento.
2. **Infra fee de $250/conta** é o item que pega cliente pequeno desprevenido. Vale destacar.
3. **Research é o componente que mais gera overage** — explicar que é compute-intensivo.
4. **Para demos com grande headcount (RH)**, padrão recomendado é licenciar autores + expor agente em canal corporativo (Slack/Teams) — reduz licenças.
5. **Comparação com QuickSight standalone (legado):** QuickSight Reader era $5/usuário, Author $24. Amazon Quick Professional ($20) é mais caro que Reader mas inclui Chat/Research/Flows que antes não existiam — argumento de valor agregado.

## Cálculo rápido de ROI (slide opcional)

Para a demo de RH (mais escalável):

- Custo médio HR helpdesk: ~$2,40/atendimento
- 100 funcionários × 1,5 atendimento/mês = 150 atendimentos/mês = $360/mês
- Amazon Quick captura 50% (autoatendimento): economia $180/mês
- Custo Quick (otimizado, 10 licenças + embed): $450/mês
- **Payback: imediato. Margem mensal: R$ 950 + tempo liberado do RH.**

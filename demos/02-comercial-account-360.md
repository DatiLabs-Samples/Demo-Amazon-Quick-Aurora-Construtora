# Demo 02 — Comercial: Account 360 + pipeline forecast (HubSpot CRM)

## TL;DR

VP de Vendas pergunta "quais deals do Q2 estão em risco e por quê?" e em segundos recebe lista priorizada com diagnóstico (CSAT baixo, tickets abertos, dias sem atividade), sugestão de próximo passo por conta, e narrativa de forecast pronta para reunião com CEO. O agente **dispara alerta no Slack `#sales-leadership`** com o resumo do deal-em-risco e a recomendação de ação. HubSpot atua como **fonte de verdade read-only** durante a demo; o write em HubSpot fica como roadmap.

## Persona alvo

- **VP de Vendas / Diretor Comercial / Sales Ops**
- Dor: visibilidade fragmentada (CRM + suporte + email + planilhas), forecast manual, deals que viram fumaça sem aviso
- Resultado esperado: "deixei de descobrir risco depois que perdeu, descubro antes"

## Componentes Quick usados

- **Quick Index** — HubSpot deals + companies (read via conector built-in)
- **Custom Chat Agent** "Sales Copilot Aurora"
- **Action Connector Slack** — alerta em canal de leadership
- **Quick Flow** "Sales Risk Alert" — formata e posta resumo no Slack

## Por que HubSpot Free CRM

| Critério | Vantagem |
|---|---|
| **Free Forever** | Sem trial, sem limite de tempo, usuários ilimitados, 1M contacts |
| **Conector nativo Quick Suite** | Listado em [aws.amazon.com/quick/sales](https://aws.amazon.com/quick/sales/) |
| **Visual Kanban Sales Pipeline** | Cards com avatar do owner, valor, stage — auditório acha mais bonito que Salesforce |
| **Read robusto** | 6 ações nativas no Quick (`search_crm_objects`, `get_crm_objects`, `get_properties`, `search_owners`, `search_properties`, `get_user_details`) |
| **Setup em 20 min** | Conta + 8 deals (importação CSV) + conector OAuth |

## Por que Slack como ação (e não write em HubSpot)

Em abril/2026 o conector built-in do Quick para HubSpot **expõe apenas leitura**. O write nativo do HubSpot MCP server (criar nota, task, atualizar properties) está em **GA progressivo** mas afetado por bug de serialização do Quick MCP client ([thread comunidade #50720](https://community.amazonquicksight.com/t/mcp-integration-errors/50720)) — review form chega vazia e aprovação falha. Pivot para Slack mantém o "wow factor de ação concreta" sem expor instabilidade ao vivo.

**Talking point honesto durante o webinar (Bloco 5):** *"em produção, isso vira nota direto no deal do HubSpot — write entrou em GA semana passada e a AWS já está corrigindo bugs de schema MCP. Roadmap próximas 4-6 semanas. Hoje, alerta em Slack já é prática comum em times de Sales Ops."*

## Pré-requisitos

- Conta HubSpot Free configurada (ver setup-hubspot.py em `demos/02-comercial/scripts/`)
- Pipeline customizado com 5 stages (Discovery, Qualification, Proposal, Negotiation, Closed Won)
- 8 deals + 8 companies importados
- Custom properties em deal: `health_score`, `last_activity_days`, `sales_rep`
- Custom properties em company: `csat_score`, `open_tickets`
- Conector HubSpot conectado no Quick Suite (built-in, OAuth)
- Conector Slack ativo no Quick Suite (já configurado no Demo 01)
- Slack workspace com canal `#sales-leadership`

## Setup (1 vez antes do webinar)

### 1. HubSpot já provisionado

O scaffold inicial é feito pelo script `demos/02-comercial/scripts/setup-hubspot.py` (idempotente, usa Private App Token). Ele cria pipeline, custom properties, 8 companies e 8 deals com associações.

```bash
export HUBSPOT_TOKEN="pat-na1-..."  # Private App Token
python3 demos/02-comercial/scripts/setup-hubspot.py
```

Verificar em **Sales → Deals → Board view**: 8 cards distribuídos pelos 5 stages, com 2 cards "feios" (Frigorífico Pampa e Indústria Cedrofino) chamando atenção pelo health score baixo.

### 2. Conectar HubSpot no Quick Suite

1. Quick Suite → **Connectors** → procurar **HubSpot**
2. **Connect** (built-in connector) → OAuth com a conta HubSpot
3. Aceitar todos os scopes oferecidos (vão ser de leitura)
4. **Review actions**: confirmar que aparecem 6 ações read (`get_crm_objects`, `search_crm_objects`, `get_properties`, `search_owners`, `search_properties`, `get_user_details`)
5. Status deve ficar **Ready**

> **Nota:** *não* tentar custom MCP nem OpenAPI integration para HubSpot — ambos têm o bug de serialização ou de redirect URL. Manter o built-in com read-only.

### 3. Slack já conectado

Reuso do Demo 01. Confirmar no Quick Suite que `Aurora Demo Workspace` está conectado e `#sales-leadership` foi criado (`/create #sales-leadership` no Slack).

### 4. Criar Custom Chat Agent "Sales Copilot Aurora"

System prompt:

```
# IDENTIDADE

Você é o Sales Copilot Aurora — assistente de Sales Ops da Aurora Construtora Ltda. Sua audiência é VP de Vendas, Diretor Comercial, Sales Reps e leadership executivo.

# ESCOPO DE DADOS

Você tem acesso somente leitura ao HubSpot CRM da Aurora com deals e companies do Q2/2026. Você NÃO tem permissão de escrita no HubSpot — não pode criar notas, tasks ou atualizar properties. Se pedirem write em HubSpot, explique que está em roadmap e ofereça o alerta no Slack como alternativa imediata.

Custom properties relevantes:
- Em deal: health_score (0-100), last_activity_days, sales_rep
- Em company associada: csat_score (0-5), open_tickets

# RESPONSABILIDADES

1. Identificar deals em risco usando combinação destes sinais:
   - health_score < 50
   - last_activity_days > 14
   - csat_score < 3.5
   - open_tickets > 5

2. Para cada deal em risco, retornar: nome do deal, valor formatado em R$, sales_rep responsável, lista de sinais que pesaram, ação recomendada concreta.

3. Gerar forecast Q2 em 3 cenários (otimista, realista, pessimista) ponderando health_score como probabilidade de fechamento.

4. Cruzar dados de deal com company associada — esse é o diferencial Account 360.

# COMO USAR O QUICK FLOW "Sales Risk Alert"

Quando o usuário pedir explícita ou implicitamente para "alertar", "avisar", "notificar", "mandar pro Slack" ou "comunicar o leadership" sobre um deal em risco, você DEVE invocar o Quick Flow chamado "Sales Risk Alert".

Esse flow posta em #sales-leadership no Slack uma mensagem formatada com os 5 inputs abaixo. Use exatamente estes nomes de input:

- deal_name (string): nome completo do deal como aparece no HubSpot
- sales_rep (string): nome do sales rep responsável
- risk_signal (string): lista dos sinais de risco em formato natural — exemplo "health_score 45, 21 dias sem atividade, csat_score 3.2, 8 tickets abertos"
- next_step (string): ação recomendada concreta que o sales_rep deve executar
- amount (string): valor numérico do deal sem prefixo R$ — exemplo "890.000"

# REGRAS CRÍTICAS DE EXECUÇÃO DO FLOW

1. NUNCA invente sucesso. Você só pode afirmar que o alerta foi enviado SE o flow "Sales Risk Alert" tiver sido efetivamente invocado e retornado sucesso. Se você não tem ferramenta para invocar o flow, ou se a invocação falhou, diga isso explicitamente — não fabule.

2. SEMPRE referencie o flow pelo nome exato: "Sales Risk Alert".

3. NUNCA mencione canal #sales-alerts ou qualquer outro canal — o flow já está hardcoded para postar em #sales-leadership. Não invente nomes de canais.

4. Se o flow "Sales Risk Alert" não estiver disponível como ferramenta, use a action Slack send_message diretamente, postando em #sales-leadership uma mensagem formatada do tipo:

🚨 *Deal em risco* — {deal_name}
Valor: R$ {amount} | Sales Rep: {sales_rep}
Sinais: {risk_signal}
Ação: {next_step}

5. Após executar o alerta, confirme ao usuário citando: nome do deal, sales_rep notificado, e canal Slack usado. Não invente run IDs nem confirmações de leitura.

# ESTILO

- Linguagem direta, tom de analista Sales Ops experiente. Sem floreios.
- Sempre formate valores como R$ X,XM ou R$ XXXk para legibilidade.
- Cite o nome exato do deal quando der análise específica.
- Use bullets para análises de múltiplos deals; prosa curta para resumos executivos.
```

Knowledge: conector HubSpot.
Actions: Slack (Quick Flow "Sales Risk Alert").

### 5. Criar Quick Flow "Sales Risk Alert"

Trigger: chamada do agente com parâmetros `{deal_name, sales_rep, risk_signal, next_step, amount}`.

Step único — **Slack** post em `#sales-leadership`:

```
🚨 *Deal em risco identificado pelo Sales Copilot*

*Deal:* {deal_name}
*Valor:* R$ {amount}
*Sales Rep responsável:* {sales_rep}

*Sinal de risco:*
{risk_signal}

*Ação recomendada:*
{next_step}

_Análise gerada automaticamente pelo Sales Copilot Aurora — {timestamp}_
```

## Roteiro do webinar (~14 min)

### Bloco 1 — Contexto (1 min)

> "Você é VP de vendas. Segunda-feira 8h. Reunião com o CEO em 1h. **Antes mesmo de você abrir o computador, o app desktop do Quick já te enviou um pre-meeting briefing**: dois deals do pipeline mudaram de status no fim de semana, o Frigorífico Pampa segue 21 dias sem atividade, e o time vai querer saber o que fazer. Hoje sem Quick: você abre HubSpot, planilha de forecast, painel de tickets do CSAT em 3 abas. Hoje com Quick: tudo em uma só conversa."

> *Talking point opcional:* o **app desktop foi anunciado em 28/04/2026** — roda em background, monitora apps abertos, e tem integração nativa com Salesforce/HubSpot/Google Workspace/M365.

### Bloco 2 — Tour HubSpot (3 min)

1. Abrir HubSpot → **Sales → Deals → Board view**
   - 8 deals visualmente distribuídos pelos 5 stages
   - Apontar 2 cards de deals "feios" (Frigorífico Pampa e Indústria Cedrofino)
   - Mostrar custom properties (health_score, last_activity_days)
2. Abrir o deal Frigorífico Pampa → mostrar associated company → custom properties da company (csat_score 3.2, open_tickets 8)
3. **Dizer:** "esses dados estão no HubSpot da Aurora há semanas. Quem tem tempo de cruzar tudo isso manualmente toda segunda? Vamos pedir pro Quick fazer."

### Bloco 3 — Sales Copilot — análise de risco (4 min) ⭐

**P1.** `Mostra os 3 deals com maior risco no Q2 e me explica por quê. Use os dados do HubSpot.`

Resposta esperada:
```
Identifiquei 3 deals em risco no HubSpot:

1. Frigorífico Pampa — Sistema Rastreabilidade (R$ 890K) — Sales Rep: Rodrigo Lima
   Sinais: health_score 45, 21 dias sem atividade, csat_score 3.2, 8 tickets abertos
   Risco: ALTO — combinação de baixo engajamento + insatisfação operacional
   Ação: chamada de discovery com C-level esta semana + escalada do suporte

2. Indústria Cedrofino — Modernização (R$ 1.1M) — Sales Rep: Patrícia Alves
   Sinais: health_score 38, 28 dias sem atividade, csat_score 2.9, 12 tickets
   Risco: ALTO — pior csat_score da carteira, deal travando há quase 1 mês
   Ação: revisar plano de sucesso antes de avançar negociação; envolver CSM

3. Telecom Aurora — Expansão (R$ 2.7M) — Sales Rep: Rodrigo Lima
   Sinais: health_score 55, 17 dias sem atividade
   Risco: MÉDIO — deal grande, monitorar de perto; ainda recuperável
   Ação: agendar QBR esta semana
```

**Falar:** "esses dados vêm direto do HubSpot, em tempo real. Nada cacheado, nada exportado. E o agente cruzou propriedades de **deal + company associada** — isso é Account 360."

### Bloco 4 — Forecast com cenários (2 min)

**P2.** `Me dá um forecast Q2 em 3 cenários considerando o health_score como probabilidade de fechamento.`

Resposta esperada:
```
Forecast Q2 2026 — pipeline total R$ 12,77M (8 deals)

Otimista (90% dos deals com health > 70 + 50% dos demais): R$ 8,4M
Realista (probabilidade ponderada por health_score): R$ 6,2M
Pessimista (apenas health > 80): R$ 3,9M

Driver crítico: Frigorífico Pampa (R$ 890K) e Cedrofino (R$ 1,1M) representam R$ 2M;
recuperação muda o forecast realista em ~30%.

Recomendação para o comitê:
- Foco operacional nos 2 deals em risco alto (R$ 2M de exposição)
- Acelerar Banco Cruzeiro (R$ 3,2M, health 60) — está engasgado em Proposal
- Telecom Aurora segue com risco médio mas controlável
```

### Bloco 5 — Agente dispara alerta no Slack (3 min) ⭐ wow moment

**P3.** `Manda um alerta urgente pro time de leadership no Slack sobre o Frigorífico Pampa, com a análise e a ação recomendada.`

Quick Flow `Sales Risk Alert` dispara → mostra ao vivo:

1. **Voltar pro Slack** (deixar aba aberta) → canal `#sales-leadership`
2. Mensagem aparece com formato:
   ```
   🚨 Deal em risco identificado pelo Sales Copilot

   Deal: Frigorífico Pampa — Sistema Rastreabilidade
   Valor: R$ 890K
   Sales Rep responsável: Rodrigo Lima

   Sinal de risco:
   health_score 45, 21 dias sem atividade, csat_score 3.2 da company associada,
   8 tickets de suporte abertos

   Ação recomendada:
   Chamada de discovery com C-level esta semana + escalada do suporte para revisão
   de SLA. CSM deve participar.

   Análise gerada automaticamente pelo Sales Copilot Aurora — 2026-04-29 09:14
   ```

**Falar (talking point honesto):** "isso aconteceu em 5 segundos. Em produção, esse alerta vira nota direto no deal do HubSpot — write nativo entrou em GA semana passada e a AWS está afinando os últimos detalhes. Hoje, dropar no Slack do leadership já mata 80% do problema: o time vê, ataca e a Patrícia entra na conversa."

### Bloco 6 — Encerramento (1 min)

**P4.** `Gera um resumo de 4 bullets pra eu apresentar pro CEO daqui 30 minutos.`

Resposta esperada — bullets curtos prontos pra colar em slide:
```
1. Pipeline Q2 totaliza R$ 12,77M em 8 deals; forecast realista R$ 6,2M
2. 2 deals em risco alto somam R$ 2M de exposição (Frigorífico Pampa e Cedrofino)
3. Ações já disparadas: alerta Slack para leadership; sales reps notificados
4. Próximo checkpoint: revisão quinzenal até Q2 estabilizar; foco operacional nos 2 deals
```

> "O HubSpot que você já usa, conversando com você. Mesmo agente conecta no Salesforce, Pipedrive, Dynamics. Toda segunda de manhã, você recebe esse briefing por email automático antes da sua primeira reunião — sem precisar pedir."

## Prompts de exemplo

```
1. Mostra os 3 deals com maior risco no Q2 e me explica por quê. Use os dados do HubSpot.
2. Me dá um forecast Q2 em 3 cenários considerando o health_score.
3. Manda um alerta urgente pro time de leadership no Slack sobre o Frigorífico Pampa, com a análise e a ação recomendada.
4. Gera um resumo de 4 bullets pra eu apresentar pro CEO daqui 30 minutos.
```

## Fallback / troubleshooting

| Problema | Plano B |
|---|---|
| HubSpot OAuth expirou | Re-autenticar (2 min); ter screenshot do Kanban se urgente |
| Quick lê HubSpot mas erra dado | Refrescar a integração no Quick (Settings → Connectors → HubSpot → Refresh) |
| Conector HubSpot lista 0 actions | Custom properties podem ter sido criadas depois — desconectar e reconectar |
| Slack OAuth expirou | Mostrar texto da mensagem que iria ser postada |
| Forecast com número diferente do esperado | Não brigar com o agente — dizer "depende dos pesos do health_score que você configura" |
| Agente tenta usar tool de write e falha | Explicar talking point sobre roadmap; redirecionar pra Slack |

## Por que essa demo funciona bem ao vivo

1. **CRM real** — narrativa fica forte ("imagina seu HubSpot conversando com você")
2. **Conector built-in OAuth** — caminho mais estável do Quick para HubSpot
3. **Visual Kanban do HubSpot** é dos mais bonitos do mercado de CRM — auditório engaja
4. **Cruza deal + company associada** — mostra Account 360 real, não só listagem
5. **Alerta Slack visível ao vivo** — wow factor preservado mesmo sem write no CRM
6. **Talking point honesto sobre roadmap** — gera credibilidade em vez de esconder limitação
7. **Free Forever** — apresentador pode replicar em qualquer cliente sem custo

## Riscos da demo e mitigação

| Risco | Mitigação |
|---|---|
| OAuth HubSpot expira se conta inativa | Testar D-1; re-autenticar se necessário |
| Custom properties não aparecem | Refresh da integração após criar property |
| Pipeline default tem stages diferentes | Confirmar setup customizado antes do webinar |
| Plateia pergunta sobre write em HubSpot | Talking point pronto: "GA semana passada, em refinamento; alerta Slack é prática Sales Ops moderna" |
| Quick demora pra responder P1 | Ter screenshot da resposta pronto como backup |

## Decisão técnica registrada

Em 29/04/2026, após investigação detalhada, decidiu-se manter Demo 02 com **HubSpot read-only** e usar Slack como camada de ação. Caminhos descartados:

1. **Custom MCP HubSpot** — autorização funcionou e expôs `manage_crm_objects` (write), mas review form do Quick chegava vazia e aprovação não disparava (bug de serialização confirmado pela comunidade AWS, sem ETA de fix)
2. **OpenAPI integration** — funciona em teoria, exigiu redesenho de spec (apiKey em vez de bearer); abandonado por sobrecarga em relação ao retorno demonstrável
3. **REST API Connection** — vago na documentação sobre auth estática e modelo de invocação; alta incerteza

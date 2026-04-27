# Demo 02 — Comercial: Account 360 + pipeline forecast (HubSpot CRM)

## TL;DR

VP de Vendas pergunta "quais deals do Q2 estão em risco e por quê?" e em segundos recebe lista priorizada com diagnóstico (CSAT baixo, tickets abertos, dias sem atividade), sugestão de próximo passo por conta, e narrativa de forecast atualizada. O agente **cria nota direto no deal do HubSpot**, atualiza o health score como custom property, dispara Gmail pro AE e alerta no Slack — pronto pra reunião com CEO.

## Persona alvo

- **VP de Vendas / Diretor Comercial / Sales Ops**
- Dor: visibilidade fragmentada (CRM + suporte + email + planilhas), forecast manual, deals que viram fumaça sem aviso
- Resultado esperado: "deixei de descobrir risco depois que perdeu, descubro antes"

## Componentes Quick usados

- **Quick Sight** (dashboard de pipeline, opcionalmente lendo HubSpot direto ou snapshot S3)
- **Quick Index** (HubSpot deals + companies)
- **Custom Chat Agent** "Sales Copilot"
- **Quick Flow** "Follow-up de deal em risco" (atualiza HubSpot + Gmail + Slack)

## Por que HubSpot Free CRM

| Critério | Vantagem |
|---|---|
| **Free Forever** | Sem trial, sem limite de tempo, usuários ilimitados, 1M contacts |
| **Conector nativo Quick Suite** | Listado em [aws.amazon.com/quick/sales](https://aws.amazon.com/quick/sales/) |
| **Visual Kanban Sales Pipeline** | Cards com avatar do owner, valor, stage — auditório acha mais bonito que Salesforce |
| **Read + Write** | Agente lê deals/companies e escreve notes/tasks via mesmo OAuth |
| **Setup em 20 min** | Conta + 8 deals (importação CSV) + conector OAuth |

## Pré-requisitos

- Conta HubSpot Free (free.hubspot.com — só precisa de email)
- Pipeline customizado com 5 stages (Discovery, Qualification, Proposal, Negotiation, Closed Won)
- 8 deals + 8 companies importados (ver setup)
- Custom properties: `Health Score` (deal), `Last Activity Days` (deal), `CSAT Score` (company), `Open Tickets` (company), `Industry` (company)
- Conector HubSpot ativo no Quick Suite
- Conector Gmail ativo
- Slack workspace com canal `#sales-alerts`

## Setup (1 vez antes do webinar)

### 1. Configurar HubSpot

#### 1.1 Criar conta + customizar pipeline

1. Criar conta em [free.hubspot.com](https://free.hubspot.com) (não precisa cartão)
2. **Settings** → **Objects** → **Deals** → **Pipelines** → editar o "Sales Pipeline" default
3. Renomear stages para:
   - Discovery
   - Qualification
   - Proposal
   - Negotiation
   - Closed Won

#### 1.2 Criar custom properties

**Em Deal:**
- `Health Score` (Number, range 0-100)
- `Last Activity Days` (Number)

**Em Company:**
- `CSAT Score` (Number, decimal)
- `Open Tickets` (Number)
- (`Industry` já existe como standard)

#### 1.3 Importar dados

Criar 2 CSVs e importar via **Contacts → Import** (escolher Companies ou Deals):

**`hubspot-companies.csv`**
```csv
Name,Industry,Number of Employees,Annual Revenue,CSAT Score,Open Tickets
Mineradora Itacolomi,Mining,3200,890000000,4.5,2
Frigorífico Pampa,Food Production,1800,450000000,3.2,8
Hospital São Lucas,Healthcare,950,210000000,4.8,1
Banco Cruzeiro,Financial Services,12000,8900000000,4.1,4
Varejo Mil Cores,Retail,2400,680000000,4.6,0
Indústria Cedrofino,Manufacturing,1500,380000000,2.9,12
Distribuidora Atlântico,Wholesale,420,95000000,4.3,1
Telecom Aurora,Telecommunications,8900,3400000000,3.8,6
```

**`hubspot-deals.csv`**
```csv
Deal Name,Pipeline,Deal Stage,Amount,Close Date,Deal Owner,Associated Company,Health Score,Last Activity Days
ACC-001 — Mineradora Itacolomi - Implementação ERP,Sales Pipeline,Proposal,2400000,2026-06-15,Carla Souza,Mineradora Itacolomi,72,8
ACC-002 — Frigorífico Pampa - Sistema Rastreabilidade,Sales Pipeline,Negotiation,890000,2026-05-30,Rodrigo Lima,Frigorífico Pampa,45,21
ACC-003 — Hospital São Lucas - Plataforma Gestão,Sales Pipeline,Discovery,1500000,2026-07-20,Carla Souza,Hospital São Lucas,88,3
ACC-004 — Banco Cruzeiro - Automação Backoffice,Sales Pipeline,Proposal,3200000,2026-06-30,Patrícia Alves,Banco Cruzeiro,60,14
ACC-005 — Varejo Mil Cores - Renovação,Sales Pipeline,Closed Won,560000,2026-04-10,Rodrigo Lima,Varejo Mil Cores,100,1
ACC-006 — Indústria Cedrofino - Modernização,Sales Pipeline,Negotiation,1100000,2026-06-05,Patrícia Alves,Indústria Cedrofino,38,28
ACC-007 — Distribuidora Atlântico - Piloto,Sales Pipeline,Discovery,420000,2026-08-15,Carla Souza,Distribuidora Atlântico,75,5
ACC-008 — Telecom Aurora - Expansão,Sales Pipeline,Proposal,2700000,2026-05-25,Rodrigo Lima,Telecom Aurora,55,17
```

> Nota: HubSpot Free não suporta múltiplos owners (cada user precisa de assento). Para a demo basta ter um único user e usar o nome do owner como **tag** ou no início do título.

#### 1.4 Verificar Kanban view

Abrir **Sales → Deals** → **Board view**. Deve aparecer 8 cards distribuídos pelos 5 stages. Esse é o "frame" visual da demo.

### 2. Conectar HubSpot no Quick Suite

1. Quick Suite → **Settings** → **Actions & Integrations** → **HubSpot** → **Connect**
2. OAuth com a conta HubSpot
3. Selecionar scopes:
   - `crm.objects.deals.read` + `.write`
   - `crm.objects.companies.read` + `.write`
   - `crm.objects.contacts.read`
   - `crm.engagements.notes.write` (criar notes nos deals)
   - `crm.engagements.tasks.write` (criar tasks)
4. Em **Knowledge sources** do Space "Comercial Aurora", adicionar o HubSpot recém-conectado
5. Testar: abrir Quick chat e perguntar `liste os 3 maiores deals do meu HubSpot`

### 3. Criar dataset Quick Sight (opcional — para o dashboard)

Duas opções:

**Opção A — direto do HubSpot (cleaner)**
1. **Datasets** → **New** → **HubSpot** → autenticar
2. Selecionar objetos: Deals, Companies
3. Salvar como `Pipeline Aurora Q2 2026`

**Opção B — snapshot CSV em S3 (mais previsível na demo)**
1. Exportar deals do HubSpot como CSV (mensal/diário em produção; manual pra demo)
2. Subir em `s3://quick-demo-{conta}/comercial/pipeline-q2-2026.csv`
3. Dataset Quick Sight aponta pro S3

Recomendação: **Opção B** pra evitar latência de API durante apresentação ao vivo.

### 4. Construir dashboard via NL prompt

1. **Analyses** → **Create new** → escolher dataset
2. **Build with AI**:

```
Crie um dashboard de pipeline comercial com:
1. KPI total pipeline em R$
2. Pipeline por stage (barra horizontal)
3. Top 5 deals por valor (tabela)
4. Health score médio por owner (donut)
5. Deals com health_score < 50 destacados em vermelho
```

3. Salvar como `Pipeline Aurora Q2 2026 — Dashboard`

### 5. Criar Space "Comercial Aurora"

Knowledge:
- Conector HubSpot (Deals + Companies)
- Dataset/Dashboard Quick Sight

### 6. Criar Custom Chat Agent "Sales Copilot"

System prompt:

```
Você é o Sales Copilot da Aurora Construtora. Tem acesso ao HubSpot CRM com deals e companies do Q2/2026.

Suas responsabilidades:
1. Identificar deals em risco com base em sinais combinados:
   - health_score < 50 (custom property no deal)
   - last_activity_days > 14 (custom property no deal)
   - csat_score < 3.5 (custom property na company)
   - open_tickets > 5 (custom property na company)
2. Para cada deal em risco, indicar: qual sinal pesou, qual ação recomendada, owner responsável (do campo Deal Owner)
3. Gerar forecast de fechamento Q2 com 3 cenários (otimista, realista, pessimista) baseados em health_score
4. Sempre falar em R$ formatado (ex.: R$ 2,4M)
5. Linguagem direta, como um analista de Sales Ops experiente

Quando solicitado, dispare o Quick Flow "Follow-up de deal em risco" passando: deal_id, deal_name, owner_email, risk_signal, next_step, amount.
```

Knowledge: Space "Comercial Aurora".
Actions: HubSpot + Gmail + Slack.

### 7. Criar Quick Flow "Follow-up de deal em risco"

Trigger: chamada do agente.

Steps:
1. **HubSpot** — buscar deal pelo `deal_name` ou `deal_id`
2. **HubSpot** — criar **Note** no deal:
   ```
   🤖 Sales Copilot — Análise automática
   Risco identificado: {risk_signal}
   Ação sugerida: {next_step}
   ```
3. **HubSpot** — atualizar `Health Score` do deal (se análise indicar mudança)
4. **HubSpot** — criar **Task** no deal:
   - Title: `Follow-up urgente: {next_step}`
   - Due date: hoje + 1 dia útil
   - Owner: `{owner_email}`
5. **Gmail** — enviar email para owner:
   ```
   Assunto: Atenção — deal {deal_name} em risco
   Body: {analysis_summary} + link do deal no HubSpot
   ```
6. **Slack** — postar em `#sales-alerts`:
   ```
   🚨 Deal em risco: {deal_name}
   Owner: {owner}
   Sinal: {risk_signal}
   Ação: {next_step}
   Valor: R$ {amount}
   ```

## Roteiro do webinar (~14 min)

### Bloco 1 — Contexto (1 min)

> "Você é VP de vendas. Segunda-feira de manhã. Reunião com o CEO em 1h. Pergunta clássica: 'me mostra o pipeline e o que tá em risco'. Hoje você abre 3 abas: HubSpot, planilha de forecast, painel do CSAT. Vamos fazer em uma."

### Bloco 2 — Tour HubSpot + Dashboard (3 min)

1. Abrir HubSpot → **Sales → Deals → Board view**
   - 8 deals visualmente distribuídos pelos 5 stages
   - Apontar 2 cards de deals "feios" (ACC-002, ACC-006)
2. Abrir dashboard `Pipeline Aurora Q2 2026 — Dashboard`
   - Pipeline total: ~R$ 12,77M
   - Health score médio por owner (donut)
   - Deals em vermelho destacados
3. **Dizer:** "esse dashboard foi gerado por prompt — eu não montei gráfico, eu pedi. E os dados vêm direto do HubSpot."

### Bloco 3 — Sales Copilot — análise (4 min)

**P1.** `Mostra os 3 deals com maior risco no Q2 e me explica por quê.`

Resposta esperada:
```
Identifiquei 3 deals em risco no HubSpot:

1. ACC-002 Frigorífico Pampa (R$ 890K) — Owner: Rodrigo Lima
   Sinais: Health Score 45, 21 dias sem atividade, CSAT 3.2, 8 tickets abertos
   Risco: ALTO — combinação de baixo engajamento + insatisfação
   Ação: chamada de discovery com C-level + escalada do suporte

2. ACC-006 Indústria Cedrofino (R$ 1.1M) — Owner: Patrícia Alves
   Sinais: Health Score 38, 28 dias sem atividade, CSAT 2.9, 12 tickets
   Risco: ALTO — pior CSAT da carteira
   Ação: revisar plano de sucesso antes de avançar negociação

3. ACC-008 Telecom Aurora (R$ 2.7M) — Owner: Rodrigo Lima
   Sinais: Health Score 55, 17 dias sem atividade
   Risco: MÉDIO — deal grande, monitorar
```

### Bloco 4 — Forecast com cenários (2 min)

**P2.** `Me dá um forecast Q2 em 3 cenários considerando o health score.`

Resposta esperada:
```
Forecast Q2 2026 — pipeline R$ 12,77M

Otimista (90% dos deals com score >70 + 50% dos demais): R$ 8,4M
Realista (probabilidade ponderada por health): R$ 6,2M
Pessimista (apenas health > 80): R$ 3,9M

Driver crítico: ACC-002 e ACC-006 representam R$ 2M; recuperação muda forecast em ~30%.
```

### Bloco 5 — Agente atua no HubSpot (3 min) ⭐ wow moment

**P3.** `Cria uma nota no HubSpot pro Frigorífico Pampa com a ação sugerida, abre uma task pro Rodrigo com prazo amanhã, manda email pra ele e alerta o time no Slack.`

Quick Flow dispara, **4 ações em sequência:**

1. **Voltar pro HubSpot** (deixar aba aberta) → clicar no deal ACC-002 → mostrar:
   - **Note** novo aparecendo na timeline:
     ```
     🤖 Sales Copilot — Análise automática
     Risco: Health Score 45, 21 dias sem atividade, CSAT 3.2
     Ação sugerida: chamada de discovery com C-level + escalada do suporte
     ```
   - **Task** nova: "Follow-up urgente: chamada com C-level" — Due tomorrow
   - **Health Score** atualizado (se aplicável)
2. **Abrir Gmail** → email recebido por Rodrigo
3. **Abrir Slack** → mensagem em `#sales-alerts`

**Falar:** "isso é Sales Ops em tempo real. O agente registra a análise no CRM como note, abre task pro responsável, avisa por email, dá visibilidade pro time. Tudo a partir de uma frase."

### Bloco 6 — Encerramento (1 min)

**P4.** `Gera um resumo de 4 bullets pra eu apresentar pro CEO daqui 30min.`

Resposta esperada — bullets curtos, prontos pra colar em slide.

> "O HubSpot que você já usa, conversando com você. Mesmo agente conecta no Salesforce, Pipedrive, Dynamics ou qualquer CRM que você prefira. Toda segunda de manhã, você recebe esse briefing por email automático antes da sua primeira reunião."

## Prompts de exemplo

```
1. Mostra os 3 deals com maior risco no Q2 e me explica por quê.
2. Me dá um forecast Q2 em 3 cenários considerando o health score.
3. Cria uma nota no HubSpot pro Frigorífico Pampa, abre task pro Rodrigo com prazo amanhã, manda email e alerta no Slack.
4. Gera resumo de 4 bullets pra eu apresentar pro CEO em 30 minutos.
```

## Fallback / troubleshooting

| Problema | Plano B |
|---|---|
| HubSpot OAuth expirou | Re-autenticar (2 min); ter screenshot do Kanban se urgente |
| Note não aparece no HubSpot na hora | Refresh da página; mostrar a Activity timeline com filtro "Notes" |
| Quick Sight não pega dado novo do HubSpot | Usar Opção B do setup (snapshot CSV) — dado é estático mas previsível |
| Gmail/Slack OAuth expirou | Mostrar texto do que iria mandar |
| Forecast com número diferente | Não brigar com o número, dizer "depende dos pesos do agente — você ajusta as regras" |

## Por que essa demo funciona bem ao vivo

1. **CRM real** — narrativa fica forte ("imagina seu HubSpot conversando com você")
2. **Conector nativo Quick Suite** — menor risco do que MCP/OpenAPI customizado
3. **Visual Kanban do HubSpot** é dos mais bonitos do mercado de CRM — auditório engaja
4. **Demo cobre 4 ações concretas no CRM** (note + task + property update + view) — alta densidade
5. **Free Forever** — apresentador pode replicar em qualquer cliente sem custo

## Riscos da demo

- **OAuth HubSpot pode expirar** se a conta ficar inativa muitos dias — testar D-1
- **Custom properties podem não aparecer** no agente se o conector não foi atualizado depois de criá-las — refresh da integração após criar property
- **Pipeline default do HubSpot** tem stages diferentes; se esquecer de customizar, agente fala em "Appointment Scheduled" em vez de "Discovery"

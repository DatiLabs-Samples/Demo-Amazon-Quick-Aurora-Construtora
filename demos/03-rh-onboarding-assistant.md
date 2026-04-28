# Demo 03 — RH: Assistente de onboarding + Q&A em políticas

## TL;DR

Funcionária novata abre o Quick chat no primeiro dia. Pergunta sobre férias, home office, plano de saúde — recebe respostas com citação direta da política. Depois pede pra solicitar equipamento e o agente abre **task no ClickUp automaticamente** + envia email pro gestor via Outlook. RH economiza 5h/funcionário no onboarding.

## Persona alvo

- **Diretor de RH / Business Partner / Coordenador de Onboarding**
- Dor: mesmas perguntas se repetem 80% do tempo, dispersão de canais (intranet, email, Slack), dificuldade de manter conhecimento atualizado
- Resultado esperado: funcionário se autoatende, RH foca em casos exceção

## Componentes Quick usados

- **Quick Index** + **Space "RH Aurora"**
- **Custom Chat Agent** "Assistente RH Aurora"
- **Action Connectors:** ClickUp (task de equipamento) + Outlook (email gestor)
- **Quick Flow** "Onboarding Equipamento" (orquestra ClickUp + Outlook)

## Pré-requisitos

- 4 PDFs em `s3://quick-demo-{conta}/rh/` (ver dados sintéticos)
- Conta ClickUp com Workspace "Aurora Demo" e List "Onboarding TI" criada
- Conta Outlook ativa (gestor fictício: `gestor-demo@aurora-demo.com`)

## Setup (1 vez antes do webinar)

### 1. Criar Space "RH Aurora"

1. **Spaces** → **Create**
2. Nome: `RH Aurora` | Descrição: `Políticas, manuais e benefícios da Aurora Construtora`
3. **Members:** `rh-demo@`, `funcionario-demo@`
4. Knowledge: bucket S3, prefix `rh/`
5. Aguardar indexação dos 4 PDFs (~5 min)

### 2. Configurar ClickUp

1. ClickUp Workspace: `Aurora Demo`
2. Space: `Operações`
3. List: `Onboarding TI`
4. Custom fields:
   - `Nome do Funcionário` (Short text)
   - `Cargo` (Short text)
   - `Gestor Email` (Email)
   - `Equipamentos` (Labels — Notebook, Monitor 27", Cadeira, Headset, Outros)
   - `Status` (Dropdown — Solicitado, Em Andamento, Entregue)
5. Gerar **Personal Token** em ClickUp → Settings → Apps → Generate (guardar)

### 3. Conectar ClickUp no Quick Suite

ClickUp não está na lista de conectores nativos. Usar uma das duas opções:

**Opção A — MCP (recomendada)**

1. Quick Suite → **Settings** → **Actions & Integrations** → **Add MCP server**
2. URL: `https://api.clickup.com/mcp` (ou self-hosted via [github.com/clickup/mcp-server-clickup](https://github.com/clickup/mcp-server-clickup) se preferir local)
3. Auth: Personal Token gerado no passo 2.5
4. Validar com prompt: `crie uma task na list Onboarding TI com título "teste"`

**Opção B — Custom OpenAPI connector**

1. Baixar spec OpenAPI da [ClickUp API v2](https://clickup.com/api)
2. **Actions & Integrations** → **Custom action** → upload spec
3. Auth: Bearer token (Personal Token)
4. Habilitar endpoint `POST /list/{list_id}/task`

### 4. Conectar Outlook

1. **Actions & Integrations** → **Outlook** → **Connect**
2. OAuth com conta Microsoft (pessoal Outlook.com serve para teste)
3. Escopo necessário: `Mail.Send`

### 5. Criar Custom Chat Agent "Assistente RH Aurora"

System prompt:

```
Você é o Assistente de RH da Aurora Construtora Ltda. Sua audiência são funcionários (atuais e novos).

Princípios:
1. Sempre responda em português brasileiro, tom acolhedor mas objetivo
2. Sempre cite a política ou manual de origem (ex.: "conforme Política de Férias, página 3")
3. Se a pergunta não tiver resposta nos documentos indexados, diga claramente "essa informação não está nas políticas que tenho acesso, vou conectar você com o RH humano"
4. Para ações concretas (solicitar equipamento, abrir chamado, alterar dados), use as Actions disponíveis (ClickUp, Outlook)
5. Nunca invente valores, datas, prazos ou benefícios

Tópicos cobertos:
- Horário de trabalho e home office
- Férias (regras, abono, divisão)
- Benefícios (VR, VA, plano de saúde, odonto, vida, auxílio creche, Gympass)
- Banco de horas
- Código de conduta e canal de denúncias
- Onboarding e equipamentos

Quando o usuário pedir equipamento ou onboarding de novo funcionário, dispare o Quick Flow "Onboarding Equipamento".
```

Knowledge: Space "RH Aurora".
Actions: ClickUp + Outlook.

### 6. Criar Quick Flow "Onboarding Equipamento"

Visual editor:
1. **Trigger:** chamada do agente com parâmetros `{nome, cargo, gestor_email, equipamentos[]}`
2. **Step 1 — ClickUp:** criar task na list `Onboarding TI`
   - Title: `Equipamento para {nome} ({cargo})`
   - Description: lista de `equipamentos[]` + observações
   - Custom fields preenchidos
   - Due date: hoje + 3 dias úteis
   - Status: `Solicitado`
3. **Step 2 — Outlook:** enviar email para `gestor_email`
   - Subject: `Onboarding em andamento: {nome}`
   - Body: link da task ClickUp + checklist do dia 1
4. **Step 3 — retorna ID da task pro agente**

## Roteiro do webinar (~14 min)

### Bloco 1 — Contexto (1 min)

> "Imagina sua nova analista financeira. Primeira semana. Vai mandar 18 perguntas pro RH: horário, férias, plano de saúde, banco de horas, gympass... E o RH responde sempre as mesmas. Vamos virar isso de cabeça pra baixo."

### Bloco 2 — Login como funcionária novata (1 min)

1. Login como `funcionario-demo@`
2. Abrir Quick chat
3. **Não** mostrar Space ou agente ainda — entrar no fluxo do funcionário direto

### Bloco 3 — Q&A nas políticas (5 min)

**P1.** `Oi! Sou nova na Aurora, comecei hoje. Posso fazer home office?`

Resposta esperada:
```
Bem-vinda à Aurora! 🌅

Sim, conforme o Manual do Funcionário (página 4), você pode fazer home office até 2 dias por semana, mediante alinhamento prévio com seu gestor. O acordo é registrado no app Aurora People.

Quer que eu ajude a marcar uma conversa com seu gestor pra alinhar os dias?
```

**P2.** `Quando posso tirar férias e como funciona?`

Resposta esperada:
```
Conforme Política de Férias (página 1-3):
- Férias são adquiridas após 12 meses de trabalho na Aurora — então a partir de [data + 12 meses]
- 30 dias corridos no total
- Você pode dividir em até 3 períodos: pelo menos um período de 14 dias, e os demais de no mínimo 5 dias
- Solicitação no app Aurora People com 45 dias de antecedência
- Pode vender até 1/3 (10 dias) como abono pecuniário

Importante: férias não podem começar nos 2 dias anteriores a feriado ou DSR.
```

**P3.** `Qual o valor do auxílio creche e até que idade?`

Resposta esperada:
```
R$ 600/mês até o filho completar 5 anos e 11 meses (Política de Benefícios 2026, página 5).
```

**P4.** `E se eu precisar trabalhar até mais tarde, como funciona o banco de horas?`

Resposta esperada:
```
Conforme Manual do Funcionário (página 6):
- Compensação até 12 meses
- Após 22h, adicional de 50%
- Registro automático via app Aurora People
```

### Bloco 4 — Ação real: solicitar equipamento (4 min)

**P5.** `Quero solicitar meu equipamento de trabalho. Sou Analista Financeira, meu gestor é o Carlos Mendes (gestor-demo@aurora-demo.com).`

Resposta esperada (e ação):
```
Perfeito! Conforme Manual (página 5), o pacote padrão da Aurora inclui:
- Notebook
- Monitor 27"
- Cadeira ergonômica
- Headset

Vou abrir a solicitação no nosso sistema agora. Confirma os equipamentos?
```

**P6.** `Confirmo, pode abrir.`

Quick Flow dispara:
- Task ClickUp criada: `Equipamento para [Nome] (Analista Financeira)`
- Email enviado pra `gestor-demo@aurora-demo.com` (Carlos Mendes)
- Agente responde com ID da task: `Pronto! Task #ABC-247 aberta no ClickUp, prazo até [data+3]. Seu gestor recebeu email com o link.`

**Mostrar ao vivo:**
1. Aba ClickUp → task aparecendo na list `Onboarding TI` com custom fields preenchidos
2. Aba Outlook → email do gestor com link da task

**Wow moment:** "isso aconteceu em 30 segundos. Hoje, esse processo passa por 4 sistemas e leva 2-3 dias."

### Bloco 5 — Pergunta-armadilha (2 min) ⭐ momento de credibilidade

**P7.** `Quanto é o reajuste salarial anual da Aurora?`

Resposta esperada:
```
Essa informação não está nas políticas que tenho acesso. O reajuste salarial é definido em acordo coletivo e comunicado pelo RH humano. Vou direcionar sua pergunta para o time de RH — quer que eu abra um chamado?
```

**Por que é importante:** mostra que o agente **não inventa**. Plateia confia mais quando vê o "não sei".

### Bloco 6 — Encerramento (1 min)

> "Mesmo agente, conectado no SharePoint, no Workday, no SAP HR. Cada nova política que você publicar é absorvida automaticamente. RH humano vira consultor, não call center."

**Talking point opcional sobre Visier Vee** (~30s extra):
> "Pra clientes que já usam **Visier** — workforce analytics, gestão de headcount, comp benchmarks — o Quick agora integra com o Vee, o agente do Visier, via MCP. Em 14/04/2026 a AWS anunciou essa integração nativa. O HRBP pergunta no Quick chat 'qual o turnover voluntário do Q1 na regional Nordeste?' e o Vee responde com dados governados, dentro da experiência do Quick. Workforce intelligence ao vivo, sem trocar de ferramenta."

## Prompts de exemplo

```
1. Sou nova na Aurora, comecei hoje. Posso fazer home office?
2. Quando posso tirar férias e como funciona?
3. Qual o valor do auxílio creche e até que idade?
4. E se eu precisar trabalhar até mais tarde, como funciona o banco de horas?
5. Quero solicitar meu equipamento de trabalho.
6. Quanto é o reajuste salarial anual da Aurora?  [pergunta-armadilha]
```

## Fallback / troubleshooting

| Problema | Plano B |
|---|---|
| ClickUp MCP server falha | Trocar pra OpenAPI connector (Opção B) |
| Ambas integrações ClickUp falham | Pular criação de task, mostrar Outlook só, dizer "no setup real, abre task também" |
| Outlook OAuth expirou | Mostrar texto do email gerado |
| Personal Token ClickUp revogado | Re-gerar (1 min) — sempre testar D-1 |
| Indexação não pegou um PDF | Pular pergunta correspondente — sempre tenha 2 perguntas reserva |
| Indexação retorna trecho errado | Reformular: "Conforme política de férias, posso..." |

## Por que essa demo funciona bem ao vivo

1. **Dados controlados** — você escreve os PDFs, sabe o que tá lá
2. **Narrativa clara** — funcionária nova é persona universal
3. **Wow factor duplo** — Q&A em PDFs + ação real em sistemas externos
4. **Pergunta-armadilha** — vacina o público contra a objeção "mas e se ele inventar?"
5. **Tempo previsível** — 14 min cabem com folga
6. **ClickUp em vez de Jira** — Free tier ilimitado, sem complicação de "Service Management" project type

# Checklist de Execução — Demo 01 Jurídico

Lista cronometrada da preparação até o webinar. Marque cada item ao concluir. Comandos exatos prontos pra colar.

---

## D-5 — Artefatos locais (~30 min)

### Geração dos PDFs

- [ ] Verificar 3 PDFs já versionados no repo
  ```bash
  ls -lh demos/01-juridico/contratos/*.pdf
  ```
  Esperado: 3 arquivos (`contrato-locacao.pdf`, `contrato-prestacao-servicos.pdf`, `nda-fornecedor.pdf`), cada um entre 40 KB e 80 KB.
- [ ] Abrir cada PDF no Preview e validar:
  - [ ] `contrato-prestacao-servicos.pdf` — 7-9 páginas, contém "30%" e "TechFlow"
  - [ ] `nda-fornecedor.pdf` — 2-4 páginas, contém "Bandeirantes"
  - [ ] `contrato-locacao.pdf` — 4-6 páginas, **cláusula 12** sobre materiais inflamáveis aparece com destaque

### Workspace Slack dedicado

> Como Outlook exige Azure AD app registration (impossível com conta pessoal Outlook.com), pivotamos para Slack como action connector — OAuth nativo, setup trivial.

- [ ] Criar workspace Slack gratuito em https://slack.com/get-started → **Create a workspace**
  - Sugestão de nome: `aurora-construtora-demo` (ou similar)
- [ ] Criar canal **`#juridico-aurora`** (público dentro do workspace)
- [ ] Adicionar 2-3 membros fictícios (pode ser você mesmo com aliases ou só você sozinho — basta pra demo)
- [ ] Login confirmado e canal aparece na sidebar

---

## D-4 — AWS CLI configurado (~15 min)

### Configurar profile SSO

- [ ] Profile SSO entrada (identidade) `quick-account` (já configurado via `aws configure sso`)
  - SSO session: `quick`
  - SSO start URL: `https://daticloud.awsapps.com/start`
  - SSO region: `us-east-1`
  - SSO account: `924357458451` (identity account)
  - SSO role: `IAM-Dati-Acc-bruno.vilardi`
- [ ] Profile workload `quick-dev` (assume role na conta de dev) — adicionar a `~/.aws/config`:
  ```ini
  [profile quick-dev]
  role_arn = arn:aws:iam::123456789012:role/Dati-operator
  source_profile = quick-account
  region = us-east-1
  ```
- [ ] Validar identidade
  ```bash
  aws sts get-caller-identity --profile quick-dev
  ```
  Esperado: `"Account": "123456789012"`
- [ ] Validar Amazon Quick ativo
  ```bash
  aws quicksight describe-account-subscription \
      --aws-account-id 123456789012 \
      --profile quick-dev
  ```
  Esperado: `"AccountSubscriptionStatus": "ACCOUNT_CREATED"` ou similar.

### Provisionar S3 + upload PDFs

- [ ] Rodar setup unificado (cria bucket + sobe artefatos de todas as 3 demos AWS — Jurídico, RH, Financeiro)
  ```bash
  ./scripts/setup-aws.sh
  ```
- [ ] Anotar URI impressa: `s3://qx3vp-aurora-demo-123456789012/juridico/`
- [ ] Verificar upload
  ```bash
  aws s3 ls s3://qx3vp-aurora-demo-123456789012/juridico/ --profile quick-dev
  ```
  Esperado: 3 PDFs listados.

---

## D-3 — Setup Amazon Quick (~30 min)

### Login

- [ ] Abrir https://quick.aws.amazon.com em janela anônima
- [ ] Login como `bruno.vilardi@dati.com.br` (licença Quick existente)
- [ ] Confirmar que entra no workspace correto (não em conta pessoal)

### Space "Jurídico Aurora"

- [ ] Quick chat → menu lateral → **Spaces** → **Create Space**
- [ ] Nome: `Jurídico Aurora`
- [ ] Descrição: `Contratos, NDAs e documentos jurídicos da Aurora Construtora`
- [ ] Members: deixar só `bruno.vilardi@dati.com.br` por enquanto
- [ ] **Knowledge sources** → **Add S3**
  - Bucket: `qx3vp-quick-dev-123456789012`
  - Prefix: `juridico/`
  - Confirmar
- [ ] Aguardar status mudar de `Indexing` para `Ready` (~3-5 min para 3 PDFs)
- [ ] Sanity check: na barra de chat do Space, perguntar `Quantos documentos foram indexados?` — esperado: 3

### Custom Chat Agent

- [ ] Quick chat → **Agents** → **Create custom agent**
- [ ] Nome: `Assistente Jurídico Aurora`
- [ ] **Instructions** — colar o system prompt:
  ```
  Você é um assistente jurídico especializado em contratos comerciais brasileiros para a Aurora Construtora Ltda.

  Sua função é:
  1. Responder perguntas sobre os contratos indexados no Space "Jurídico Aurora"
  2. Identificar cláusulas de risco (multas elevadas, foros desfavoráveis, vigências longas, condições de rescisão atípicas, cláusulas de armazenamento ou uso restrito do imóvel)
  3. Sempre citar a página e o trecho do documento original
  4. Usar linguagem objetiva, em português brasileiro formal mas acessível
  5. Quando solicitado, preparar resumo executivo em formato:
     - Partes contratantes
     - Objeto
     - Vigência
     - Valor
     - Riscos identificados (com classificação Alto/Médio/Baixo)
     - Recomendação

  Nunca invente informação. Se não encontrar nos documentos, diga "não consta no contrato analisado".
  ```
- [ ] **Knowledge:** vincular ao Space `Jurídico Aurora`
- [ ] **Actions:** deixar pendente até OAuth Slack (próximo passo)

### Conector Slack

- [ ] Amazon Quick → **Integrations** → aba **Actions** → **Slack** → **Connect**
- [ ] Browser abre página do Slack → escolher workspace `aurora-construtora-demo`
- [ ] Autorizar app Amazon Quick (permissões: postar em canais, ler workspace)
- [ ] Voltar ao Amazon Quick, confirmar status `Connected`
- [ ] No Agent `Assistente Jurídico Aurora` → **Actions** → habilitar Slack
- [ ] Convidar o bot Amazon Quick no canal `#juridico-aurora` (no Slack: `/invite @Quick`)

### Quick Flow

- [ ] **Flows** → **Create flow** → **From chat**
- [ ] Prompt:
  ```
  Quando eu pedir um resumo executivo de contrato, gere o resumo seguindo o formato padrão e poste no canal #juridico-aurora do workspace Slack conectado. Formato da mensagem:

  📄 *Novo resumo executivo de contrato*
  *Contrato:* [nome do contrato]

  [conteúdo do resumo executivo]

  _Gerado pelo Assistente Jurídico Aurora_
  ```
- [ ] Salvar como `Resumo Executivo de Contrato`
- [ ] Vincular ao Agent `Assistente Jurídico Aurora` em **Flows**

---

## D-3 noite — Smoke test (~20 min)

Validar que tudo funciona antes de gravar. Use o agente `Assistente Jurídico Aurora`.

- [ ] **P1.** `Quais são os contratos ativos e suas vigências?`
  - Esperado: lista 3 contratos com datas (TechFlow 2026-2028, NDA Bandeirantes 3 anos, Locação Guarulhos 2026-2029)
- [ ] **P2.** `No contrato de prestação de serviços com a TechFlow, qual a multa por rescisão antecipada e como ela é calculada?`
  - Esperado: 30% do saldo restante, citar Cláusula 8.2
- [ ] **P3.** `Existe alguma cláusula de risco no contrato de locação de Guarulhos que eu deveria revisar com atenção?`
  - **Esperado: identifica Cláusula 12** (rescisão imediata por materiais inflamáveis sem comunicação prévia)
  - Se falhar: ver troubleshooting abaixo
- [ ] **P4.** `Gere um resumo executivo do contrato de prestação de serviços com a TechFlow no formato padrão da Aurora.`
  - Esperado: output no formato instruído (Partes, Objeto, Vigência, Valor, Riscos, Recomendação)
- [ ] **P5.** `Posta esse resumo no canal do time jurídico no Slack.`
  - Esperado: Quick Flow dispara, mensagem aparece em `#juridico-aurora` em <30s
  - Verificar formatação da mensagem

### Troubleshooting do P3

Se o agente não pegar a Cláusula 12:

1. Reformular: `Existe cláusula sobre armazenamento de materiais inflamáveis no contrato de locação?`
2. Se ainda falhar, editar system prompt do agente acrescentando:
   ```
   IMPORTANTE: ao analisar contratos de locação, sempre verificar cláusulas sobre:
   - Restrições de uso do imóvel
   - Materiais inflamáveis, explosivos, corrosivos ou perigosos
   - Necessidade de alvarás (AVCB, etc.) e seguros específicos
   - Hipóteses de rescisão imediata sem aviso prévio
   ```

---

## D-2 — Ensaio cronometrado (~30 min)

- [ ] Tela cheia da janela do Quick chat
- [ ] Cronômetro visível (segundo monitor ou celular)
- [ ] Rodar fim-a-fim seguindo os 6 blocos do roteiro em `demos/01-juridico-revisao-contrato.md`:
  - Bloco 1 — Contexto (1 min)
  - Bloco 2 — Tour do Space (2 min)
  - Bloco 3 — Q&A (4 min) — perguntas P1, P2, P3
  - Bloco 4 — Resumo executivo (3 min) — P4
  - Bloco 5 — Quick Flow (3 min) — P5 + abrir Slack mostrando o post no canal
  - Bloco 6 — Encerramento (1 min)
- [ ] Tempo total: anotar __ min __ seg
  - Se >15 min: cortar narração de tour ou encerramento
  - Se <12 min: adicionar pergunta extra de explicação

---

## D-1 — Gravação backup (~1h30)

### Setup técnico

- [ ] Instalar OBS Studio (https://obsproject.com) — gratuito, melhor que QuickTime
- [ ] Cena padrão:
  - **Display Capture** (tela inteira) — 1920×1080
  - **Video Capture Device** (webcam canto inferior direito, opcional)
  - **Audio Input Capture** (microfone)
- [ ] Output → MP4, qualidade alta (recommended preset)
- [ ] Pasta de saída: `demos/01-juridico/recordings/`
- [ ] Notificações desabilitadas no macOS (Focus → Do Not Disturb)
- [ ] Slack/iMessage/email fechados ou em "do not disturb"

### Gravação

- [ ] Quick chat aberto, agente `Assistente Jurídico Aurora` ativo
- [ ] Slack aberto em outra aba/janela no canal `#juridico-aurora` (pra mostrar a mensagem após Quick Flow)
- [ ] Cronômetro fora do quadro
- [ ] Take 1 — gravar fim-a-fim sem cortes
- [ ] Revisar — se >15 min ou erro grave, refazer
- [ ] Salvar como `demo-01-juridico-backup-take1.mp4`

### Edição mínima

- [ ] Cortar 2-3 segundos do início (clicar gravar) e do fim (parar gravar)
- [ ] **NÃO** cortar pausas naturais — autenticidade conta
- [ ] Exportar como `demo-01-juridico-backup.mp4`
- [ ] Subir cópia em local de backup (Drive corporativo, etc.)

---

## D-0 — Webinar 🎬

### Pré-aquecimento (30 min antes)

- [ ] Login no Amazon Quick em janela anônima
- [ ] Pré-abrir abas:
  - Tab 1: Quick chat com agente `Assistente Jurídico Aurora`
  - Tab 2: Slack workspace `aurora-construtora-demo` no canal `#juridico-aurora`
  - Tab 3: dashboard Quick Sight do Space (opcional, pra mostrar "PDFs indexados")
- [ ] Pergunta-zero de aquecimento (não no roteiro): `Olá, você está pronto?` — apenas pra validar que sessão tá ativa
- [ ] Cronômetro em segundo monitor
- [ ] Notificações OFF
- [ ] Vídeo backup pré-aberto em pasta separada (caso de queda)
- [ ] Sessão Slack ainda ativa (testar com refresh)

### Durante a demo

- [ ] Bloco 1: contexto (1 min)
- [ ] Bloco 2: tour do Space (2 min)
- [ ] Bloco 3: P1 → P2 → P3 (4 min)
- [ ] Bloco 4: P4 resumo executivo (3 min)
- [ ] Bloco 5: P5 + abrir Slack (3 min)
- [ ] Bloco 6: encerramento (1 min)

### Plano B se algo falhar ao vivo

| Falha | Ação imediata |
|---|---|
| Quick chat trava | Aba 2 do navegador (já pré-aberta com agente) |
| Indexação sumiu | Mudar pra vídeo backup, pular pra Bloco 6 |
| OAuth Slack expirou | Pular Bloco 5, dizer "no setup real, postaria automaticamente no canal" |
| Internet caiu | Vídeo backup |
| Pergunta P3 não pega cláusula 12 | Reformular: "Existe cláusula sobre armazenamento de materiais inflamáveis?" |

---

## Pós-webinar (D+1)

- [ ] Salvar gravação ao vivo (se tiver sido gravada)
- [ ] Coletar feedback dos participantes (formulário, NPS)
- [ ] Revisar quais perguntas a plateia fez no Q&A — alimenta refinamento das próximas demos
- [ ] Anotar timing real vs. planejado em `demos/01-juridico/checklist-execucao.md`
- [ ] Decidir manutenção: deixar setup ativo (pra próximas demos) ou rodar `teardown-aws.sh`

---

## Notas livres do apresentador

_(use este espaço pra anotar ajustes específicos durante o ensaio)_

- Tempo gasto no ensaio D-2: ___
- Pergunta que precisou ser reformulada: ___
- Ajuste no system prompt do agente: ___
- Outros: ___

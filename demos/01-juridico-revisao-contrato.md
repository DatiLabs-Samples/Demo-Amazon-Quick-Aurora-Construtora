# Demo 01 — Jurídico: Revisão de contrato + extração de cláusulas

## TL;DR

Advogado interno recebe um contrato novo. Em vez de ler 8 páginas, ele faz upload no Quick Suite, pergunta em linguagem natural sobre vigência, multas e riscos, e o agente entrega um **resumo executivo + flags de risco + post automático no canal do time jurídico no Slack** em 2 minutos.

## Persona alvo

- **Diretor jurídico** ou advogado interno de empresa média (50-500 funcionários)
- Dor: alto volume de contratos, baixa padronização, risco de cláusulas escondidas
- Resultado esperado: "horas viram minutos"

## Componentes Quick usados

- **Quick Index** + **Space "Jurídico Aurora"**
- **Custom Chat Agent** "Assistente Jurídico"
- **Quick Flow** "Resumo Executivo de Contrato" (posta no canal Slack `#juridico-aurora`)

## Pré-requisitos

- 3 PDFs em `s3://quick-demo-{conta}/juridico/` (ver [01-dados-sinteticos.md](../setup/01-dados-sinteticos.md))
- Conector Slack ativo (workspace e canal `#juridico-aurora` criados)
- Chat Agent já criado e testado com as 3 perguntas-âncora

## Setup (1 vez antes do webinar)

### 1. Criar Space "Jurídico Aurora"

1. Quick chat → **Spaces** → **Create Space**
2. Nome: `Jurídico Aurora` | Descrição: `Contratos, NDAs e documentos jurídicos da Aurora Construtora`
3. **Members:** apenas `juridico-demo@`
4. **Knowledge sources** → Add S3 → bucket `quick-demo-{conta}`, prefix `juridico/`
5. Aguardar indexação (~3-5 min para 3 PDFs)

### 2. Criar Custom Chat Agent

1. **Agents** → **Create custom agent**
2. Nome: `Assistente Jurídico Aurora`
3. **Instructions** (prompt do agente):

```
Você é um assistente jurídico especializado em contratos comerciais brasileiros para a Aurora Construtora Ltda.

Sua função é:
1. Responder perguntas sobre os contratos indexados no Space "Jurídico Aurora"
2. Identificar cláusulas de risco (multas elevadas, foros desfavoráveis, vigências longas, condições de rescisão atípicas)
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

4. **Knowledge:** vincular ao Space "Jurídico Aurora"
5. **Actions:** ativar Slack (para a Flow conseguir postar no canal no final)

### 3. Criar Quick Flow "Resumo Executivo de Contrato"

1. **Flows** → **Create flow** → **From chat**
2. Prompt: `Quando eu pedir, gere um resumo executivo do contrato selecionado e poste no canal Slack #juridico-aurora começando com "📄 Novo resumo executivo:" seguido do nome do contrato e do conteúdo do resumo formatado.`
3. Salvar como `Resumo Executivo de Contrato`

## Roteiro do webinar (~14 min)

### Bloco 1 — Contexto (1 min)

> "Imagina que você é o jurídico da Aurora Construtora. Chegou agora um contrato de locação de galpão. 5 páginas. Você tem 14 outros contratos na fila. O que você faz hoje? Lê tudo, anota, manda pra revisão? Vamos fazer diferente."

### Bloco 2 — Tour do Space (2 min)

1. Login como `juridico-demo@`
2. Abrir Space **Jurídico Aurora**
3. Mostrar os 3 documentos indexados
4. Highlight: "esses PDFs estão no S3, mas eu pergunto direto, sem precisar abrir um por um"

### Bloco 3 — Q&A em linguagem natural (4 min)

Perguntas ao agente, **na ordem** (cada uma constrói a próxima):

**P1.** `Quais são os contratos ativos e suas vigências?`
- Resposta esperada: lista 3 contratos com datas
- **Por que perguntar isso primeiro:** estabelece confiança ("ele lê os documentos")

**P2.** `No contrato de prestação de serviços com a TechFlow, qual a multa por rescisão antecipada e como ela é calculada?`
- Resposta esperada: 30% do saldo restante, cita cláusula
- **Por que:** mostra extração de número específico + citação

**P3.** `Existe alguma cláusula de risco no contrato de locação de Guarulhos que eu deveria revisar com atenção?`
- Resposta esperada: identifica a cláusula 12 (rescisão por materiais inflamáveis)
- **Por que:** este é o "wow moment" — a cláusula está escondida, o agente acha

### Bloco 4 — Resumo executivo (3 min)

**P4.** `Gere um resumo executivo do contrato de prestação de serviços com a TechFlow no formato padrão da Aurora.`

Resposta esperada (formato instruído no system prompt):
```
RESUMO EXECUTIVO

Partes: Aurora Construtora Ltda (contratante) | TechFlow Sistemas Ltda (contratada)
Objeto: Desenvolvimento de software de gestão de obras
Vigência: 24 meses (01/03/2026 — 28/02/2028), renovação automática 12 meses
Valor: R$ 1.200.000,00 (24 parcelas mensais de R$ 50.000,00)

Riscos identificados:
- ALTO: Multa de 30% do saldo em caso de rescisão antecipada (cláusula 8.3)
- MÉDIO: Renovação automática se não houver denúncia em 90 dias (cláusula 4.2)
- BAIXO: Reajuste por IPCA anual (cláusula 6.1)

Recomendação: Atenção à multa de rescisão. Considerar negociar gatilho de revisão semestral.
```

### Bloco 5 — Acionar Quick Flow (3 min)

**P5.** `Posta esse resumo no canal do time jurídico no Slack.`

- Quick Flow é acionado
- Mostrar a confirmação ("Mensagem postada em #juridico-aurora")
- Abrir Slack ao vivo e mostrar o post no canal
- **Wow moment 2:** "isso aqui é trabalho que tomava 2h, em 4 minutos. E o time inteiro vê em tempo real."

### Bloco 6 — Encerramento da demo (1 min)

> "Esse mesmo agente pode ser conectado ao SharePoint, ao Google Drive, à pasta de contratos do seu time. Toda vez que entrar contrato novo, ele lê, classifica risco e aciona o workflow. O jurídico foca em decisão, não em leitura."

## Prompts de exemplo (cola em slide ou crachá do apresentador)

```
1. Quais são os contratos ativos e suas vigências?
2. No contrato com a TechFlow, qual a multa por rescisão antecipada?
3. Existe cláusula de risco no contrato de locação que eu deveria revisar?
4. Gere um resumo executivo do contrato com a TechFlow.
5. Posta esse resumo no canal do time jurídico no Slack.
```

## Fallback / troubleshooting

| Problema | Plano B |
|---|---|
| Agente não encontra cláusula 12 | Reformular: "Existe alguma cláusula sobre materiais inflamáveis ou armazenamento de risco?" |
| Quick Flow falha (Slack OAuth expirado) | Pular o post, mostrar copy/paste do resumo |
| PDF não indexou | Ter screenshot do Space populado pronto pra colar |
| Internet cai | Vídeo gravado de 90s da demo completa pré-renderizado |

## Métricas de sucesso (para próximo webinar)

- Tempo total da demo: **alvo 14 min**, máximo 15
- Quantas perguntas a plateia faz sobre Jurídico no Q&A
- Cliques no link do trial após o webinar

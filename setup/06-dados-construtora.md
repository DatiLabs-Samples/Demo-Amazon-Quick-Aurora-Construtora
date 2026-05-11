# Aurora Construtora — contexto de negócio e estrutura de dados

Referência sobre como funciona uma construtora civil de médio porte no Brasil e por que os dados sintéticos da Aurora têm o formato que têm. Útil para o apresentador entender as perguntas que podem surgir da plateia e para enriquecer Knowledge dos agentes Quick (se promovido para S3).

## O que é a Aurora

Construtora civil de médio porte brasileira, fundada em 2008, sede em São Paulo com filiais em RJ, MG e BA. 824 funcionários, R$ 487M de receita em 2025. Atua em 4 linhas de negócio (Industrial, Predial, Infra e Tech) e em 4 regionais (SP, RJ, MG, BA + projetos pontuais em PR/PE).

A particularidade do negócio é que a Aurora **não é só uma construtora** — ela combina obras tradicionais com vertical de tecnologia (Aurora Tech, criada em 2024 para IoT em canteiros) e tem entrada relevante em obras públicas via Aurora Infra. Esse mix explica boa parte das tensões financeiras vistas nas demos.

## Tipos de contrato no setor

Construção civil no Brasil opera com 4 grandes modalidades contratuais. Aurora tem exposição a todas elas:

### 1. Empreitada por preço global (lump sum)

O contratante paga um valor fixo total. Risco de custo é integralmente do construtor. Margem maior mas exige precisão extrema no orçamento. Comum em **obras predial privada** (~30% do faturamento Aurora).

Exemplo: Hospital São Lucas contrata Aurora por R$ 28M para construir nova ala. Se materiais subirem, é problema da Aurora.

### 2. Empreitada por preço unitário

Pagamento baseado em quantidades efetivamente executadas (m³ de concreto, m² de alvenaria, km de pavimento). Comum em **obras de infraestrutura**, especialmente pública. Risco de quantidades pode ser do contratante.

Exemplo: DER-BA contrata Aurora para duplicar 12 km de rodovia. Cada item tem preço unitário e mede-se mensalmente o executado.

### 3. Administração / cost-plus

Aurora administra a obra e cobra um fee fixo ou percentual sobre os custos. Cliente assume os custos diretos. Margem menor mas baixíssimo risco. Comum em **clientes recorrentes que confiam na Aurora** (carteira-âncora).

Exemplo: Mineradora Itacolomi contrata Aurora para reformar planta industrial em modelo cost-plus 8%. Materiais e mão-de-obra reembolsados, Aurora recebe 8% sobre o total.

### 4. PPP / concessão (parceria público-privada)

Aurora constrói e opera obra pública por décadas, recebendo do poder concedente ou via tarifa do usuário. Ciclo longo, exposição a risco regulatório. Aurora não tem PPPs atualmente — está em estudo para 2027+.

## Modelo de revenue recognition (POC method)

Construção é **long-cycle**: contratos de 6 a 36 meses são normais. Por isso, o setor reconhece receita pelo **Percentage-of-Completion (POC) method** — não no recebimento, não na entrega, mas na **execução física da obra**.

Reconhece-se receita proporcionalmente ao progresso, medido por:

- **% custo incorrido** (mais usado) — se já gastou 40% do custo orçado, reconhece 40% da receita
- **% físico medido** — engenheiro fiscal mede execução in loco

Implicação prática: o número de receita reportado num determinado mês depende de **estimativas atualizadas de custo total**. Revisão dessas estimativas no fechamento contábil **muda receita reconhecida retroativamente**. Esse é exatamente o mecanismo por trás da divergência da Demo 04 entre ata (R$ 89,9M, preliminar) e dataset (R$ 104,5M, atualizado).

## Estrutura de custos típica

Custo de uma obra média no Brasil decompõe-se aproximadamente em:

| Categoria | % do custo total | Notas |
|---|---|---|
| Materiais | 45-55% | Aço, cimento, agregados — sensível a câmbio (aço plano importado) |
| Mão-de-obra direta | 25-35% | Operários no canteiro + encarregados |
| Equipamentos | 8-15% | Locação ou depreciação de máquinas pesadas |
| Subempreiteiros | 5-10% | Serviços especializados (elétrica, hidráulica, esquadrias) |
| Despesa indireta de canteiro | 3-8% | Encarregados, segurança, ferramentas perdidas, EPI |

No dataset da Aurora, esse detalhamento é simplificado em 3 categorias:

- **Receita** — faturamento da regional
- **Custo Direto** — soma de materiais + mão-de-obra direta + equipamentos + subempreiteiros
- **Despesa Operacional** — overhead da regional (gestão, comercial, administrativo)

A margem operacional típica do setor é **8-12%** — Aurora opera com média de **9,2%**, o que é razoável.

## Por que regionais importam muito em construtora

Diferentemente de tecnologia ou varejo, construtora **não pode atender Salvador a partir de São Paulo**. A obra é física, exige equipe local, fornecedores próximos, conhecimento do mercado regional (legislação municipal, sindicatos, fornecedores de areia/brita confiáveis).

Por isso a Aurora tem 4 filiais com **autonomia operacional**. Cada regional é praticamente uma "construtora dentro da construtora" com:

- VP regional ou Diretor regional próprio
- Pipeline comercial próprio
- Carteira de fornecedores própria
- P&L próprio

A consolidação só acontece na sede. Isso explica por que o desvio da BA na Demo 04 é tão concentrado — uma regional inteira pode ir mal sem contaminar as outras.

## Por que BA é o gancho da Demo 04

A BA tem 3 características que a tornam vulnerável:

1. **Concentração em contratos públicos federais** (~60% da carteira regional). Quando Brasília atrasa a liberação de orçamento, a BA para.
2. **Mercado privado regional pequeno** comparado a SP. Menos opções de pivot rápido.
3. **Equipe regional menor** — ~70 funcionários vs. ~400 em SP. Menos colchão para reagir a choques.

Quando o cenário macro do Nordeste se complica (atraso na execução orçamentária da União, como aconteceu Q1 2026), BA é a primeira a sentir. Isso é capturado no relatório de mercado da Demo 04 e contextualiza a discussão do comitê na ata.

## Aspectos tributários relevantes (regime Aurora)

Aurora opera em **Lucro Real** (obrigatório acima de R$ 78M de receita anual). Isso significa:

- **PIS/Cofins** não-cumulativos (1,65% + 7,6% sobre receita, com créditos)
- **IRPJ + CSLL** sobre lucro efetivo (15% + 10% sobre faixa adicional + 9% CSLL = ~34% nominal)
- **ISS** municipal (2-5% conforme o município da obra) — varia por regional
- **INSS sobre folha** + retenção previdenciária de 11% pelo tomador em obras

Carga tributária consolidada típica: **30-35% sobre receita líquida** no setor de construção, dependendo de planejamento.

> **Implicação para a Demo 04:** o "Resultado operacional" no dataset é antes de IRPJ/CSLL. A margem líquida da Aurora gira em torno de 5-6% — saudável, mas estreita para o setor.

## Como esse contexto aparece nas demos

| Demo | Pista contextual |
|---|---|
| **01 Jurídico** | Contratos de TechFlow, Logística Bandeirantes e Imobiliária Galpões Brasil — todos fornecedores típicos de construtora |
| **02 Comercial** | Pipeline tem clientes de mineração, saúde, telecom — diversidade típica de uma construtora multi-vertical |
| **03 RH** | Manual menciona "equipe de canteiro vs. equipe administrativa" — distinção universal no setor |
| **04 Financeiro** | Ata cita "execução física da obra" para revenue recognition; relatório de mercado fala em "atraso de execução orçamentária federal" |

## Perguntas que podem surgir da plateia

| Pergunta | Resposta curta |
|---|---|
| Por que receita do dataset ≠ ata? | Revenue recognition em construção é POC, ajustado no fechamento — explicado na P3 da Demo 04 |
| Por que regionais são separadas? | Construção é física, exige equipe local e fornecedores próximos |
| Aurora tem PPP? | Não atualmente, em estudo para 2027 |
| Como Aurora reconhece receita de obra pública? | POC method com medição mensal de execução; recebimento pode atrasar mas receita já foi reconhecida |
| Margem de 9% é boa? | Sim, está na média do setor (8-12%) |
| Por que BA é tão vulnerável? | 60% da carteira em contratos públicos federais + mercado privado regional pequeno |

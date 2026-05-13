# Dados sintéticos PT-BR para as demos

Todos os dados aqui são **fictícios**. Empresa-modelo: **Construtora Aurora Ltda**, médio porte, sede em São Paulo, escritórios em SP/RJ/MG/BA, ~800 funcionários.

> **Artefatos prontos no repo:** os 9 PDFs e o CSV combinado já estão versionados em `demos/01-juridico/contratos/`, `demos/03-rh/politicas/`, `demos/04-financeiro/docs/` e `demos/04-financeiro/data/`. Sem etapa de regeneração — o [`scripts/setup-aws.sh`](../scripts/setup-aws.sh) já faz upload direto.

## Demo 01 — Jurídico

### `contrato-prestacao-servicos.pdf` (8 páginas)

Contrato entre **Aurora Construtora Ltda** (contratante) e **TechFlow Sistemas Ltda** (contratada) para desenvolvimento de software de gestão de obras.

Cláusulas-chave a inserir (para a extração funcionar):
- **Vigência:** 24 meses a partir de 01/03/2026, renovação automática por 12 meses salvo denúncia com 90 dias.
- **Valor:** R$ 1.200.000,00 em 24 parcelas mensais de R$ 50.000,00.
- **Multa por rescisão antecipada:** 30% do saldo restante.
- **Confidencialidade:** 5 anos pós-término.
- **Foro:** Comarca de São Paulo/SP.
- **Reajuste:** IPCA anual.
- **SLA:** 99,5% disponibilidade, multa de 2% por ponto percentual abaixo.
- **Propriedade intelectual:** código-fonte é da Aurora.

### `nda-fornecedor.pdf` (3 páginas)

NDA bilateral com **Logística Bandeirantes S.A.** para análise de proposta de transporte. Cláusulas: confidencialidade 3 anos, exceções padrão (info pública, ordem judicial), foro SP.

### `contrato-locacao.pdf` (5 páginas)

Locação de galpão em Guarulhos. **R$ 85.000,00/mês**, 36 meses, reajuste IGPM, multa 3 aluguéis. **Cláusula 12: rescisão imediata se locatária armazenar materiais inflamáveis sem aviso prévio de 30 dias** ← gancho para a demo achar um risco.

## Demo 02 — Comercial

### `pipeline-q2-2026.csv`

```csv
account_id,account_name,owner,stage,amount_brl,close_date,health_score,last_activity_days
ACC-001,Mineradora Itacolomi,Carla Souza,Proposta,2400000,2026-06-15,72,8
ACC-002,Frigorífico Pampa,Rodrigo Lima,Negociação,890000,2026-05-30,45,21
ACC-003,Hospital São Lucas,Carla Souza,Discovery,1500000,2026-07-20,88,3
ACC-004,Banco Cruzeiro,Patrícia Alves,Proposta,3200000,2026-06-30,60,14
ACC-005,Varejo Mil Cores,Rodrigo Lima,Closed Won,560000,2026-04-10,100,1
ACC-006,Indústria Cedrofino,Patrícia Alves,Negociação,1100000,2026-06-05,38,28
ACC-007,Distribuidora Atlântico,Carla Souza,Discovery,420000,2026-08-15,75,5
ACC-008,Telecom Aurora,Rodrigo Lima,Proposta,2700000,2026-05-25,55,17
```

### `accounts-360.csv`

```csv
account_id,industry,employees,annual_revenue_brl,csat_score,open_tickets,renewal_date
ACC-001,Mineração,3200,890000000,4.5,2,2027-01-15
ACC-002,Alimentos,1800,450000000,3.2,8,N/A
ACC-003,Saúde,950,210000000,4.8,1,N/A
ACC-004,Financeiro,12000,8900000000,4.1,4,2026-09-30
ACC-005,Varejo,2400,680000000,4.6,0,2027-04-10
ACC-006,Indústria,1500,380000000,2.9,12,N/A
ACC-007,Distribuição,420,95000000,4.3,1,N/A
ACC-008,Telecom,8900,3400000000,3.8,6,2026-11-20
```

Combinação interessante: ACC-002 (Frigorífico Pampa) tem health_score baixo, CSAT 3.2, 8 tickets abertos, 21 dias sem atividade — agente identifica como "deal at risk".

## Demo 03 — RH

### `manual-funcionario.pdf` (24 páginas)

Estrutura:
1. Boas-vindas
2. Estrutura organizacional (CEO → 4 VPs → 12 diretores)
3. **Horário de trabalho:** 09h-18h, flex 1h, segunda a sexta, 1h almoço
4. **Home office:** até 2 dias/semana mediante alinhamento com gestor
5. Código de vestimenta (smart casual, social às terças)
6. Equipamentos: notebook + monitor 27" + cadeira ergonômica fornecidos
7. **Ponto:** registro via app Aurora People, tolerância 10 min
8. **Banco de horas:** compensação até 12 meses, 50% adicional após 22h
9. Treinamentos obrigatórios (segurança, LGPD, código de conduta)
10. Canal de denúncias

### `politica-ferias.pdf` (6 páginas)

- 30 dias corridos após 12 meses de trabalho
- Pode dividir em até 3 períodos (mínimo 14 dias um deles, demais ≥ 5)
- Solicitação no app **com 45 dias de antecedência mínima**
- Abono pecuniário: até 1/3 (10 dias)
- Não pode iniciar férias 2 dias antes de feriado ou DSR
- Aprovação: gestor direto + RH

### `beneficios-2026.pdf` (10 páginas)

- VR R$ 38/dia, VA R$ 800/mês
- Plano de saúde Bradesco Top Premium (titular gratuito, dependentes 50%)
- Plano odontológico OdontoPrev (titular e até 2 dependentes gratuitos)
- Seguro de vida 24x salário
- **Auxílio creche:** R$ 600/mês até 5 anos e 11 meses do filho
- **Gympass:** plano básico gratuito, planos superiores subsidiados 70%
- PLR: até 3 salários conforme metas (50% individual + 50% empresa)

### `codigo-conduta.pdf` (12 páginas)

Padrão: anticorrupção, conflito de interesses, presentes (limite R$ 200), uso de redes sociais, relacionamento com fornecedores, política de denúncias e não-retaliação.

## Demo 04 — Financeiro

### `budget-2026.csv`

```csv
regional,categoria,jan,fev,mar,abr,mai,jun
SP,Receita,18000000,17500000,19000000,18500000,19500000,20000000
SP,Custo Direto,9000000,8800000,9500000,9300000,9800000,10000000
SP,Despesa Operacional,3600000,3500000,3800000,3700000,3900000,4000000
RJ,Receita,8500000,8200000,9000000,8800000,9200000,9500000
RJ,Custo Direto,4500000,4300000,4800000,4700000,4900000,5050000
RJ,Despesa Operacional,1700000,1640000,1800000,1760000,1840000,1900000
MG,Receita,5200000,5000000,5500000,5300000,5600000,5800000
MG,Custo Direto,2700000,2600000,2900000,2800000,2950000,3050000
MG,Despesa Operacional,1040000,1000000,1100000,1060000,1120000,1160000
BA,Receita,3800000,3700000,4000000,3900000,4100000,4200000
BA,Custo Direto,2000000,1950000,2100000,2050000,2150000,2210000
BA,Despesa Operacional,760000,740000,800000,780000,820000,840000
```

### `actuals-q1-2026.csv` (com desvios propositais)

```csv
regional,categoria,jan,fev,mar
SP,Receita,17800000,17600000,18900000
SP,Custo Direto,9100000,8900000,9650000
SP,Despesa Operacional,3650000,3520000,3850000
RJ,Receita,8400000,8100000,8800000
RJ,Custo Direto,4520000,4350000,4900000
RJ,Despesa Operacional,1710000,1660000,1830000
MG,Receita,5300000,5100000,5650000
MG,Custo Direto,2680000,2580000,2880000
MG,Despesa Operacional,1020000,990000,1080000
BA,Receita,2900000,2800000,3100000
BA,Custo Direto,2050000,2000000,2200000
BA,Despesa Operacional,790000,770000,830000
```

**Insights propositais para a demo destacar:**
- **BA:** receita -23% vs. orçado (R$ 2,9M vs. R$ 3,8M em Jan) → narrativa: gancho da demo
- **MG:** levemente acima do plano em receita (+2%), abaixo em custo (-1%) → "região farol"
- **SP:** custo direto +1.5% em março → "monitoramento"

### Documentos de apoio (PDFs em `financeiro/` para Quick Research citar)

- `relatorio-mercado-construcao-q1-2026.pdf` (sintético) — menciona "queda de demanda no Nordeste em Q1/2026 por atraso em obras públicas".
- `ata-comite-financeiro-mar-2026.pdf` — registra discussão sobre risco BA.

A demo de Financeiro fica forte porque o agente de Research consegue **explicar** o desvio da BA citando o relatório de mercado + a ata.

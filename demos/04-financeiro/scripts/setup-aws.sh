#!/usr/bin/env bash
# setup-aws.sh — uploada artefatos da Demo 04 Financeiro no bucket compartilhado
#
# Reusa o bucket criado pelo setup do Demo 01 (qx3vp-aurora-demo-913567437118)
# e suas policies. Aqui apenas faz upload em financeiro/ prefix.
#
# Pré-requisitos:
#   - Demo 01 setup-aws.sh já rodado (bucket + policies)
#   - PDFs gerados (./scripts/convert-pdfs.sh)
#   - CSVs em demos/04-financeiro/data/
#
# Uso:
#   ./scripts/setup-aws.sh

set -euo pipefail

PROFILE="quick-dev"
ACCOUNT_ID="913567437118"
BUCKET="qx3vp-aurora-demo-${ACCOUNT_ID}"
PREFIX="financeiro"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="${SCRIPT_DIR}/../docs"
DATA_DIR="${SCRIPT_DIR}/../data"

echo "🔍 Validando profile e identidade..."
IDENTITY=$(aws sts get-caller-identity --profile "${PROFILE}" --output json)
CURRENT_ACCOUNT=$(echo "${IDENTITY}" | grep -o '"Account": "[0-9]*"' | cut -d'"' -f4)

if [[ "${CURRENT_ACCOUNT}" != "${ACCOUNT_ID}" ]]; then
    echo "❌ Profile ${PROFILE} aponta para account ${CURRENT_ACCOUNT}, esperado ${ACCOUNT_ID}"
    echo "   Rode: aws sso login --profile ${PROFILE}"
    exit 1
fi
echo "✅ Identidade OK: ${CURRENT_ACCOUNT}"

# Validar que o bucket existe (criado pelo Demo 01)
if ! aws s3api head-bucket --bucket "${BUCKET}" --profile "${PROFILE}" 2>/dev/null; then
    echo "❌ Bucket ${BUCKET} não existe — rode primeiro o setup-aws.sh do Demo 01"
    exit 1
fi
echo "✅ Bucket ${BUCKET} existe"
echo ""

# Upload dos PDFs
echo "📤 Uploading PDFs em s3://${BUCKET}/${PREFIX}/ ..."
PDFS=(
    "relatorio-mercado-construcao-q1-2026.pdf"
    "ata-comite-financeiro-mar-2026.pdf"
)

for pdf in "${PDFS[@]}"; do
    LOCAL="${DOCS_DIR}/${pdf}"
    if [[ ! -f "${LOCAL}" ]]; then
        echo "   ⚠️  ${LOCAL} não existe — rode primeiro ./scripts/convert-pdfs.sh"
        continue
    fi

    aws s3 cp "${LOCAL}" "s3://${BUCKET}/${PREFIX}/${pdf}" \
        --profile "${PROFILE}" \
        --content-type "application/pdf" \
        --metadata "demo=04-financeiro,empresa=aurora"
    echo "   ✅ ${pdf}"
done

# Upload do CSV combinado (long-format) usado pelo Quick Sight dataset.
# Os CSVs originais budget-2026.csv e actuals-q1-2026.csv ficam só no repo
# como fonte. O Quick Sight consome o variance-q1-2026.csv gerado por
# scripts/combine-csvs.py.
echo ""
echo "📤 Uploading CSV combinado em s3://${BUCKET}/${PREFIX}/ ..."
CSV="variance-q1-2026.csv"
LOCAL="${DATA_DIR}/${CSV}"

if [[ ! -f "${LOCAL}" ]]; then
    echo "   ❌ ${LOCAL} não existe."
    echo "      Rode primeiro: python3 scripts/combine-csvs.py"
    exit 1
fi

aws s3 cp "${LOCAL}" "s3://${BUCKET}/${PREFIX}/${CSV}" \
    --profile "${PROFILE}" \
    --content-type "text/csv" \
    --metadata "demo=04-financeiro,empresa=aurora"
echo "   ✅ ${CSV}"

echo ""
echo "🎉 Upload concluído!"
echo ""
echo "📍 URI para colar no Quick Suite Space (Knowledge → Add S3):"
echo "   s3://${BUCKET}/${PREFIX}/"
echo ""
echo "📋 Arquivos no bucket:"
aws s3 ls "s3://${BUCKET}/${PREFIX}/" --profile "${PROFILE}" --human-readable

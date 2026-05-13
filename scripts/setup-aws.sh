#!/usr/bin/env bash
# setup-aws.sh — provisiona toda a infraestrutura AWS das 5 demos Aurora
#
# Único script de setup AWS. Cria (idempotente):
#   - Bucket S3: qx3vp-aurora-demo-${ACCOUNT_ID}
#   - Bucket policy: leitura para o serviço Amazon Quick
#   - Encryption AES256 + Versioning + Public access block
#   - Inline policy AuroraDemoQuickAccess no service role do Amazon Quick
#   - Upload dos 10 artefatos em 3 prefixos:
#       juridico/   → 3 PDFs de contratos
#       rh/         → 4 PDFs de políticas
#       financeiro/ → 2 PDFs (ata + relatório) + 1 CSV (variance Q1)
#
# Pré-requisitos:
#   - AWS CLI v2 instalado
#   - Profile quick-dev configurado (aws configure sso)
#   - Substitua ACCOUNT_ID abaixo pelo seu account ID real (placeholder
#     123456789012 vem do release público no DatiLabs-Samples)
#
# Uso:
#   ./scripts/setup-aws.sh

set -euo pipefail

# Configuração
PROFILE="quick-dev"
ACCOUNT_ID="123456789012"   # ← substituir pelo seu AWS account ID
REGION="us-east-1"
BUCKET="qx3vp-aurora-demo-${ACCOUNT_ID}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔍 Validando profile e identidade..."
IDENTITY=$(aws sts get-caller-identity --profile "${PROFILE}" --output json)
CURRENT_ACCOUNT=$(echo "${IDENTITY}" | grep -o '"Account": "[0-9]*"' | cut -d'"' -f4)

if [[ "${CURRENT_ACCOUNT}" != "${ACCOUNT_ID}" ]]; then
    echo "❌ Profile ${PROFILE} aponta para account ${CURRENT_ACCOUNT}, esperado ${ACCOUNT_ID}"
    echo "   Edite ACCOUNT_ID neste script ou rode: aws sso login --profile ${PROFILE}"
    exit 1
fi
echo "✅ Identidade OK: ${CURRENT_ACCOUNT}"
echo ""

# 1. Criar bucket (idempotente)
echo "📦 Criando bucket s3://${BUCKET}/ ..."
if aws s3api head-bucket --bucket "${BUCKET}" --profile "${PROFILE}" 2>/dev/null; then
    echo "   ℹ️  Bucket já existe — pulando criação"
else
    if [[ "${REGION}" == "us-east-1" ]]; then
        aws s3api create-bucket \
            --bucket "${BUCKET}" \
            --profile "${PROFILE}" \
            --region "${REGION}"
    else
        aws s3api create-bucket \
            --bucket "${BUCKET}" \
            --profile "${PROFILE}" \
            --region "${REGION}" \
            --create-bucket-configuration LocationConstraint="${REGION}"
    fi
    echo "   ✅ Bucket criado"
fi

# 2. Bloquear acesso público
echo "🔒 Bloqueando acesso público no bucket..."
aws s3api put-public-access-block \
    --bucket "${BUCKET}" \
    --profile "${PROFILE}" \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "   ✅ Public access bloqueado"

# 3. Versionamento (defesa contra delete acidental)
echo "🔄 Habilitando versionamento..."
aws s3api put-bucket-versioning \
    --bucket "${BUCKET}" \
    --profile "${PROFILE}" \
    --versioning-configuration Status=Enabled
echo "   ✅ Versionamento habilitado"

# 4. Criptografia padrão AES256
echo "🔐 Habilitando criptografia AES256..."
aws s3api put-bucket-encryption \
    --bucket "${BUCKET}" \
    --profile "${PROFILE}" \
    --server-side-encryption-configuration '{
        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'
echo "   ✅ Criptografia habilitada"

# 5. Bucket policy — template oficial Amazon Quick
echo "📜 Aplicando bucket policy para Amazon Quick..."
POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAmazonQuickS3Access",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${ACCOUNT_ID}:role/service-role/aws-quicksight-service-role-v0"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetObjectVersion",
        "s3:ListBucketVersions"
      ],
      "Resource": [
        "arn:aws:s3:::${BUCKET}",
        "arn:aws:s3:::${BUCKET}/*"
      ]
    }
  ]
}
EOF
)

aws s3api put-bucket-policy \
    --bucket "${BUCKET}" \
    --profile "${PROFILE}" \
    --policy "${POLICY}"
echo "   ✅ Bucket policy aplicada"

# 6. Inline policy no service role do Amazon Quick
echo "🔧 Anexando inline policy AuroraDemoQuickAccess em aws-quicksight-service-role-v0..."
ROLE_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AuroraDemoBucketAccess",
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetBucketLocation", "s3:ListBucketMultipartUploads", "s3:ListBucketVersions"],
      "Resource": "arn:aws:s3:::${BUCKET}"
    },
    {
      "Sid": "AuroraDemoObjectAccess",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:GetObjectVersion"],
      "Resource": "arn:aws:s3:::${BUCKET}/*"
    }
  ]
}
EOF
)
aws iam put-role-policy \
    --role-name aws-quicksight-service-role-v0 \
    --policy-name AuroraDemoQuickAccess \
    --policy-document "${ROLE_POLICY}" \
    --profile "${PROFILE}"
echo "   ✅ Inline policy aplicada"

# 7. Upload de artefatos por demo
echo ""
echo "📤 Uploading artefatos..."

# 7.1 Jurídico — 3 PDFs de contratos
echo ""
echo "── juridico/ ──"
JURIDICO_PDFS=(
    "contrato-prestacao-servicos.pdf"
    "nda-fornecedor.pdf"
    "contrato-locacao.pdf"
)
for pdf in "${JURIDICO_PDFS[@]}"; do
    LOCAL="${REPO_ROOT}/demos/01-juridico/contratos/${pdf}"
    if [[ ! -f "${LOCAL}" ]]; then
        echo "   ⚠️  ${LOCAL} não existe — pulando"
        continue
    fi
    aws s3 cp "${LOCAL}" "s3://${BUCKET}/juridico/${pdf}" \
        --profile "${PROFILE}" \
        --content-type "application/pdf" \
        --metadata "demo=01-juridico,empresa=aurora" >/dev/null
    echo "   ✅ ${pdf}"
done

# 7.2 RH — 4 PDFs de políticas
echo ""
echo "── rh/ ──"
RH_PDFS=(
    "manual-funcionario.pdf"
    "politica-ferias.pdf"
    "beneficios-2026.pdf"
    "codigo-conduta.pdf"
)
for pdf in "${RH_PDFS[@]}"; do
    LOCAL="${REPO_ROOT}/demos/03-rh/politicas/${pdf}"
    if [[ ! -f "${LOCAL}" ]]; then
        echo "   ⚠️  ${LOCAL} não existe — pulando"
        continue
    fi
    aws s3 cp "${LOCAL}" "s3://${BUCKET}/rh/${pdf}" \
        --profile "${PROFILE}" \
        --content-type "application/pdf" \
        --metadata "demo=03-rh,empresa=aurora" >/dev/null
    echo "   ✅ ${pdf}"
done

# 7.3 Financeiro — 2 PDFs + 1 CSV
echo ""
echo "── financeiro/ ──"
FINANCEIRO_PDFS=(
    "relatorio-mercado-construcao-q1-2026.pdf"
    "ata-comite-financeiro-mar-2026.pdf"
)
for pdf in "${FINANCEIRO_PDFS[@]}"; do
    LOCAL="${REPO_ROOT}/demos/04-financeiro/docs/${pdf}"
    if [[ ! -f "${LOCAL}" ]]; then
        echo "   ⚠️  ${LOCAL} não existe — pulando"
        continue
    fi
    aws s3 cp "${LOCAL}" "s3://${BUCKET}/financeiro/${pdf}" \
        --profile "${PROFILE}" \
        --content-type "application/pdf" \
        --metadata "demo=04-financeiro,empresa=aurora" >/dev/null
    echo "   ✅ ${pdf}"
done

CSV="variance-q1-2026.csv"
LOCAL_CSV="${REPO_ROOT}/demos/04-financeiro/data/${CSV}"
if [[ -f "${LOCAL_CSV}" ]]; then
    aws s3 cp "${LOCAL_CSV}" "s3://${BUCKET}/financeiro/${CSV}" \
        --profile "${PROFILE}" \
        --content-type "text/csv" \
        --metadata "demo=04-financeiro,empresa=aurora" >/dev/null
    echo "   ✅ ${CSV}"
else
    echo "   ⚠️  ${LOCAL_CSV} não existe — pulando"
fi

echo ""
echo "🎉 Setup AWS concluído!"
echo ""
echo "📍 URIs para colar nos Spaces do Amazon Quick (Knowledge → Add S3):"
echo "   Demo 01 Jurídico:   s3://${BUCKET}/juridico/"
echo "   Demo 03 RH:         s3://${BUCKET}/rh/"
echo "   Demo 04 Financeiro: s3://${BUCKET}/financeiro/"
echo ""
echo "📋 Listing final:"
aws s3 ls "s3://${BUCKET}/" --recursive --profile "${PROFILE}" --human-readable

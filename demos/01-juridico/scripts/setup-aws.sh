#!/usr/bin/env bash
# setup-aws.sh — provisiona infraestrutura AWS para a Demo 01 Jurídico
#
# Cria (idempotente):
#   - Bucket S3: qx3vp-aurora-demo-913567437118
#   - Bucket policy: leitura para o serviço Quick Suite
#   - Encryption AES256 + Versioning + Public access block
#   - Upload dos 3 PDFs em juridico/
#
# Pré-requisitos:
#   - AWS CLI v2 instalado
#   - Profile aurora-demo configurado (aws configure sso)
#   - PDFs gerados em demos/01-juridico/contratos/*.pdf
#
# Uso:
#   ./scripts/setup-aws.sh

set -euo pipefail

# Configuração
PROFILE="quick-dev"
ACCOUNT_ID="913567437118"
REGION="us-east-1"
BUCKET="qx3vp-aurora-demo-${ACCOUNT_ID}"
PREFIX="juridico"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTRATOS_DIR="${SCRIPT_DIR}/../contratos"

echo "🔍 Validando profile e identidade..."
IDENTITY=$(aws sts get-caller-identity --profile "${PROFILE}" --output json)
CURRENT_ACCOUNT=$(echo "${IDENTITY}" | grep -o '"Account": "[0-9]*"' | cut -d'"' -f4)

if [[ "${CURRENT_ACCOUNT}" != "${ACCOUNT_ID}" ]]; then
    echo "❌ Profile ${PROFILE} aponta para account ${CURRENT_ACCOUNT}, esperado ${ACCOUNT_ID}"
    echo "   Rode: aws sso login --profile ${PROFILE}"
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
        # us-east-1 não aceita LocationConstraint
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

# 2. Bloquear acesso público (boa prática)
echo "🔒 Bloqueando acesso público no bucket..."
aws s3api put-public-access-block \
    --bucket "${BUCKET}" \
    --profile "${PROFILE}" \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "   ✅ Public access bloqueado"

# 3. Habilitar versionamento (defesa contra delete acidental)
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

# 5. Bucket policy — template oficial Quick Suite (docs.aws.amazon.com/quick/latest/userguide/s3-admin-setup.html)
echo "📜 Aplicando bucket policy para Quick Suite..."
POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowQuickSuiteS3Access",
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

# 5b. Inline policy no service role do Quick Suite (sem mexer em policies de outros times)
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

# 6. Upload dos PDFs
echo ""
echo "📤 Uploading PDFs em s3://${BUCKET}/${PREFIX}/ ..."
PDFS=(
    "contrato-prestacao-servicos.pdf"
    "nda-fornecedor.pdf"
    "contrato-locacao.pdf"
)

for pdf in "${PDFS[@]}"; do
    LOCAL="${CONTRATOS_DIR}/${pdf}"
    if [[ ! -f "${LOCAL}" ]]; then
        echo "   ⚠️  ${LOCAL} não existe — rode primeiro ./scripts/convert-pdfs.sh"
        continue
    fi

    aws s3 cp "${LOCAL}" "s3://${BUCKET}/${PREFIX}/${pdf}" \
        --profile "${PROFILE}" \
        --content-type "application/pdf" \
        --metadata "demo=01-juridico,empresa=aurora"
    echo "   ✅ ${pdf}"
done

echo ""
echo "🎉 Setup AWS concluído!"
echo ""
echo "📍 URI para colar no Quick Suite Space (Knowledge → Add S3):"
echo "   s3://${BUCKET}/${PREFIX}/"
echo ""
echo "📋 Arquivos no bucket:"
aws s3 ls "s3://${BUCKET}/${PREFIX}/" --profile "${PROFILE}" --human-readable

#!/usr/bin/env bash
# teardown-aws.sh — remove a infraestrutura AWS criada por setup-aws.sh
#
# CUIDADO: apaga todo o conteúdo do bucket (todos os prefixos: juridico/,
# rh/, financeiro/) e o bucket em si. Pede confirmação interativa.
#
# Uso:
#   ./scripts/teardown-aws.sh

set -euo pipefail

PROFILE="quick-dev"
ACCOUNT_ID="123456789012"   # ← substituir pelo seu AWS account ID
BUCKET="qx3vp-aurora-demo-${ACCOUNT_ID}"

echo "⚠️  Você está prestes a APAGAR:"
echo "   - Todo o conteúdo de s3://${BUCKET}/ (juridico/ + rh/ + financeiro/)"
echo "   - Todas as versões de objetos (versionamento está habilitado)"
echo "   - O bucket s3://${BUCKET}/"
echo "   - A inline policy AuroraDemoQuickAccess no service role do Amazon Quick"
echo ""
read -rp "Digite 'apagar' para confirmar: " confirm
if [[ "${confirm}" != "apagar" ]]; then
    echo "❌ Cancelado."
    exit 1
fi

echo ""
echo "🔍 Verificando se bucket existe..."
if ! aws s3api head-bucket --bucket "${BUCKET}" --profile "${PROFILE}" 2>/dev/null; then
    echo "ℹ️  Bucket ${BUCKET} não existe — nada a fazer no S3."
else
    echo "🗑️  Apagando objetos correntes..."
    aws s3 rm "s3://${BUCKET}/" --recursive --profile "${PROFILE}" || true

    echo "🗑️  Apagando todas as versões..."
    VERSIONS=$(aws s3api list-object-versions \
        --bucket "${BUCKET}" \
        --profile "${PROFILE}" \
        --output json \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' 2>/dev/null || echo '{"Objects":[]}')

    if [[ "$(echo "${VERSIONS}" | grep -c '"Key"' || true)" -gt 0 ]]; then
        echo "${VERSIONS}" > /tmp/quick-demo-versions.json
        aws s3api delete-objects \
            --bucket "${BUCKET}" \
            --profile "${PROFILE}" \
            --delete file:///tmp/quick-demo-versions.json > /dev/null
        rm -f /tmp/quick-demo-versions.json
    fi

    echo "🗑️  Apagando delete markers..."
    MARKERS=$(aws s3api list-object-versions \
        --bucket "${BUCKET}" \
        --profile "${PROFILE}" \
        --output json \
        --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' 2>/dev/null || echo '{"Objects":[]}')

    if [[ "$(echo "${MARKERS}" | grep -c '"Key"' || true)" -gt 0 ]]; then
        echo "${MARKERS}" > /tmp/quick-demo-markers.json
        aws s3api delete-objects \
            --bucket "${BUCKET}" \
            --profile "${PROFILE}" \
            --delete file:///tmp/quick-demo-markers.json > /dev/null
        rm -f /tmp/quick-demo-markers.json
    fi

    echo "🗑️  Apagando bucket policy..."
    aws s3api delete-bucket-policy --bucket "${BUCKET}" --profile "${PROFILE}" 2>/dev/null || true

    echo "🗑️  Apagando bucket..."
    aws s3api delete-bucket --bucket "${BUCKET}" --profile "${PROFILE}"
fi

echo "🗑️  Removendo inline policy do service role..."
aws iam delete-role-policy \
    --role-name aws-quicksight-service-role-v0 \
    --policy-name AuroraDemoQuickAccess \
    --profile "${PROFILE}" 2>/dev/null || true

echo ""
echo "✅ Teardown concluído."

#!/usr/bin/env bash
# teardown-aws.sh — remove a infraestrutura AWS criada por setup-aws.sh
#
# CUIDADO: apaga todo o conteúdo do bucket e o bucket em si.
# Pede confirmação interativa antes de prosseguir.
#
# Uso:
#   ./scripts/teardown-aws.sh

set -euo pipefail

PROFILE="aurora-demo"
ACCOUNT_ID="913567437118"
BUCKET="qx3vp-aurora-demo-${ACCOUNT_ID}"

echo "⚠️  Você está prestes a APAGAR:"
echo "   - Todo o conteúdo de s3://${BUCKET}/"
echo "   - Todas as versões de objetos (versionamento está habilitado)"
echo "   - O bucket s3://${BUCKET}/"
echo ""
read -rp "Digite 'apagar' para confirmar: " confirm
if [[ "${confirm}" != "apagar" ]]; then
    echo "❌ Cancelado."
    exit 1
fi

echo ""
echo "🔍 Verificando se bucket existe..."
if ! aws s3api head-bucket --bucket "${BUCKET}" --profile "${PROFILE}" 2>/dev/null; then
    echo "ℹ️  Bucket ${BUCKET} não existe — nada a fazer."
    exit 0
fi

echo "🗑️  Apagando todas as versões de objetos..."
# Apagar objetos correntes
aws s3 rm "s3://${BUCKET}/" --recursive --profile "${PROFILE}" || true

# Apagar versões (necessário porque versionamento está habilitado)
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

# Apagar markers de delete
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

echo ""
echo "✅ Teardown concluído. Bucket ${BUCKET} removido."

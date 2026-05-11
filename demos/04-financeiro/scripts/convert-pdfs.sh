#!/usr/bin/env bash
# convert-pdfs.sh — converte os 2 documentos de apoio Demo 04 Financeiro em PDF
#
# Pré-requisitos:
#   brew install pandoc
#   brew install --cask weasyprint  (preferido)
#   ou: brew install --cask wkhtmltopdf
#
# Uso:
#   ./scripts/convert-pdfs.sh
#
# Saída:
#   demos/04-financeiro/docs/*.pdf

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="${SCRIPT_DIR}/../docs"
CSS_FILE="${DOCS_DIR}/style.css"

cd "${DOCS_DIR}"

if ! command -v pandoc &> /dev/null; then
    echo "❌ pandoc não encontrado. Instale com: brew install pandoc"
    exit 1
fi

PDF_ENGINE=""
if command -v weasyprint &> /dev/null; then
    PDF_ENGINE="weasyprint"
elif command -v wkhtmltopdf &> /dev/null; then
    PDF_ENGINE="wkhtmltopdf"
else
    echo "❌ nem weasyprint nem wkhtmltopdf encontrados."
    echo "   Instale com: brew install --cask weasyprint"
    exit 1
fi

echo "📄 Engine selecionada: ${PDF_ENGINE}"
echo "🎨 CSS: ${CSS_FILE}"
echo ""

DOCS=(
    "relatorio-mercado-construcao-q1-2026"
    "ata-comite-financeiro-mar-2026"
)

for doc in "${DOCS[@]}"; do
    INPUT="${doc}.md"
    OUTPUT="${doc}.pdf"

    if [[ ! -f "${INPUT}" ]]; then
        echo "⚠️  ${INPUT} não encontrado — pulando"
        continue
    fi

    echo "🔄 Convertendo ${INPUT} → ${OUTPUT}"

    if [[ "${PDF_ENGINE}" == "weasyprint" ]]; then
        pandoc "${INPUT}" \
            --from=markdown \
            --to=html5 \
            --standalone \
            --css="${CSS_FILE}" \
            --pdf-engine=weasyprint \
            --metadata=lang:pt-BR \
            -o "${OUTPUT}"
    else
        pandoc "${INPUT}" \
            --from=markdown \
            --to=html5 \
            --standalone \
            --css="${CSS_FILE}" \
            --pdf-engine=wkhtmltopdf \
            --pdf-engine-opt=--enable-local-file-access \
            --pdf-engine-opt=--margin-top --pdf-engine-opt=25mm \
            --pdf-engine-opt=--margin-bottom --pdf-engine-opt=25mm \
            --pdf-engine-opt=--margin-left --pdf-engine-opt=25mm \
            --pdf-engine-opt=--margin-right --pdf-engine-opt=25mm \
            --pdf-engine-opt=--footer-center --pdf-engine-opt='[page] de [topage]' \
            --pdf-engine-opt=--footer-font-size --pdf-engine-opt=9 \
            --metadata=lang:pt-BR \
            -o "${OUTPUT}"
    fi

    echo "✅ ${OUTPUT} ($(du -h "${OUTPUT}" | cut -f1))"
done

echo ""
echo "🎉 Conversão concluída. PDFs em: ${DOCS_DIR}/"
ls -lh *.pdf

#!/usr/bin/env bash
# convert-pdfs.sh — converte os 3 contratos Markdown em PDF
#
# Pré-requisitos:
#   brew install pandoc
#   brew install --cask wkhtmltopdf
#   (alternativa: brew install --cask weasyprint)
#
# Uso:
#   ./scripts/convert-pdfs.sh
#
# Saída:
#   demos/01-juridico/contratos/*.pdf

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTRATOS_DIR="${SCRIPT_DIR}/../contratos"
CSS_FILE="${CONTRATOS_DIR}/style.css"

cd "${CONTRATOS_DIR}"

# Validar dependências
if ! command -v pandoc &> /dev/null; then
    echo "❌ pandoc não encontrado. Instale com: brew install pandoc"
    exit 1
fi

# Escolher engine de PDF (preferência: weasyprint > wkhtmltopdf)
PDF_ENGINE=""
if command -v weasyprint &> /dev/null; then
    PDF_ENGINE="weasyprint"
elif command -v wkhtmltopdf &> /dev/null; then
    PDF_ENGINE="wkhtmltopdf"
else
    echo "❌ nem weasyprint nem wkhtmltopdf encontrados."
    echo "   Instale com: brew install --cask weasyprint"
    echo "   ou:          brew install --cask wkhtmltopdf"
    exit 1
fi

echo "📄 Engine selecionada: ${PDF_ENGINE}"
echo "🎨 CSS: ${CSS_FILE}"
echo ""

# Lista de contratos
CONTRATOS=(
    "contrato-prestacao-servicos"
    "nda-fornecedor"
    "contrato-locacao"
)

for contrato in "${CONTRATOS[@]}"; do
    INPUT="${contrato}.md"
    OUTPUT="${contrato}.pdf"

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
        # wkhtmltopdf não suporta @page direito; usamos HTML intermediário
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
echo "🎉 Conversão concluída. PDFs em: ${CONTRATOS_DIR}/"
ls -lh *.pdf

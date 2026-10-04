#!/usr/bin/env bash
# Kiểm tra toàn bộ tài liệu: markdownlint, Mermaid render, OpenAPI lint.
set -euo pipefail
cd "$(dirname "$0")/.."

# mermaid-cli 12 cần Node >= 22.13 (xem .nvmrc). Node cũ làm mmdc thoát lỗi mà không in gì.
node_ver="$(node -p 'process.versions.node')"
IFS=. read -r major minor _ <<<"$node_ver"
if (( major < 22 || (major == 22 && minor < 13) )); then
  echo "Cần Node >= 22.13 (đang dùng $node_ver). Chạy: nvm use" >&2
  exit 2
fi

echo "== markdownlint =="
npx --yes markdownlint-cli2 "**/*.md"

echo "== mermaid =="
tmp="$(mktemp -d)"
while IFS= read -r -d '' f; do
  if grep -q '```mermaid' "$f"; then
    echo "  render $f"
    npx --yes -p @mermaid-js/mermaid-cli mmdc -q \
      -p scripts/puppeteer-config.json \
      -i "$f" -o "$tmp/$(basename "$f")" >/dev/null
  fi
done < <(find docs -name '*.md' -not -path 'docs/superpowers/*' -print0)

echo "== openapi =="
if [ -f docs/05-api/openapi.yaml ]; then
  npx --yes @redocly/cli lint docs/05-api/openapi.yaml
else
  echo "  (chưa có openapi.yaml — bỏ qua)"
fi

echo "ALL DOC CHECKS PASSED"

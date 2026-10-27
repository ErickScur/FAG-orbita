#!/usr/bin/env bash
set -u

usage() {
  cat <<'EOF'
uso: tools/gen_image.sh --prompt=<arquivo.txt> --out=<destino.png> [opções]

Gera uma imagem com a geração de imagem do Codex CLI (codex exec) e copia o PNG bruto
para --out. O arquivo de prompt contém só o prompt de arte (o mesmo da ficha do ASSETS.md);
o script acrescenta as instruções para o Codex só gerar a imagem e devolver o caminho.

  --prompt=FILE     prompt de arte (texto em inglês, template do ASSET-PIPELINE §3)
  --out=FILE        destino do PNG bruto (fora do repo: scratchpad; o fatiador grava o final)
  --ref=FILE        imagem de referência de estilo (repetível)
  --variants=N      gera N variações: <out>_1.png .. <out>_N.png (padrão 1)
  --timeout=N       segundos por imagem (padrão 300)

Sai 0 se todas as imagens foram geradas e copiadas.
EOF
}

prompt_file=""
out=""
refs=()
variants=1
limit=300
for argument in "$@"; do
  case "$argument" in
    --prompt=*) prompt_file="${argument#--prompt=}" ;;
    --out=*) out="${argument#--out=}" ;;
    --ref=*) refs+=("${argument#--ref=}") ;;
    --variants=*) variants="${argument#--variants=}" ;;
    --timeout=*) limit="${argument#--timeout=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "GEN ABORT: opção desconhecida $argument"; usage; exit 64 ;;
  esac
done
[ -n "$prompt_file" ] && [ -n "$out" ] || { usage; exit 64; }
[ -f "$prompt_file" ] || { echo "GEN ABORT: prompt não encontrado: $prompt_file"; exit 64; }
command -v codex >/dev/null || { echo "GEN ABORT: codex CLI não encontrado no PATH"; exit 69; }
for ref in "${refs[@]+"${refs[@]}"}"; do
  [ -f "$ref" ] || { echo "GEN ABORT: referência não encontrada: $ref"; exit 64; }
done

work="$(mktemp -d "${TMPDIR:-/tmp}/orbita-gen.XXXXXX")"
mkdir -p "$(dirname "$out")"
image_args=()
for ref in "${refs[@]+"${refs[@]}"}"; do
  cp "$ref" "$work/"
  image_args+=(--image "$work/$(basename "$ref")")
done

{
  echo "Use your image generation tool to create ONE image. Do not write code, do not run"
  echo "shell commands, do not edit files."
  [ ${#refs[@]} -gt 0 ] && echo "The attached image(s) are the style reference."
  echo
  cat "$prompt_file"
  echo
  echo "When done, reply with only the absolute path of the saved image file."
} > "$work/prompt.txt"

failed=0
for index in $(seq 1 "$variants"); do
  if [ "$variants" -eq 1 ]; then target="$out"; else target="${out%.png}_$index.png"; fi
  events="$work/events_$index.jsonl"
  stamp="$work/stamp_$index"
  touch "$stamp"
  started=$(date +%s)
  perl -e "alarm $limit; exec @ARGV" codex exec --skip-git-repo-check -s read-only --json \
    -C "$work" "${image_args[@]+"${image_args[@]}"}" - < "$work/prompt.txt" \
    > "$events" 2> "$work/stderr_$index.txt"
  code=$?
  generated=$(python3 -I - "$events" <<'PY'
import json, os, re, sys
found = ""
for line in open(sys.argv[1], encoding="utf-8"):
    try:
        event = json.loads(line)
    except ValueError:
        continue
    item = event.get("item") or {}
    if item.get("type") == "agent_message":
        for path in re.findall(r"/\S+?\.png", item.get("text") or ""):
            if os.path.isfile(path):
                found = path
print(found)
PY
)
  if [ -z "$generated" ]; then
    generated=$(find "$HOME/.codex/generated_images" -type f -name '*.png' -newer "$stamp" \
      2>/dev/null | tail -1)
  fi
  elapsed=$(( $(date +%s) - started ))
  if [ -z "$generated" ]; then
    echo "GEN FAIL variação $index (exit $code, ${elapsed}s) — nenhuma imagem; veja $work"
    tail -3 "$work/stderr_$index.txt"
    failed=1
    continue
  fi
  cp "$generated" "$target"
  size=$(sips -g pixelWidth -g pixelHeight "$target" 2>/dev/null \
    | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w "x" h}')
  echo "GEN OK $target ($size, ${elapsed}s)"
done

[ $failed -eq 0 ] && rm -rf "$work"
exit $failed

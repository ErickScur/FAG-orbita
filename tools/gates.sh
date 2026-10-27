#!/usr/bin/env bash
set -u

GODOT="${GODOT:-/Users/BRScurPaEr/Downloads/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.." || exit 1

skip_smoke=0
for argument in "$@"; do
  case "$argument" in
    --skip-smoke) skip_smoke=1 ;;
    -h|--help)
      echo "uso: tools/gates.sh [--skip-smoke]"
      echo "Portões na ordem do CLAUDE.md §6; para no primeiro que falhar."
      exit 0 ;;
    *) echo "opção desconhecida: $argument"; exit 64 ;;
  esac
done

log_dir="${TMPDIR:-/tmp}/orbita-gates"
mkdir -p "$log_dir"
error_pattern="SCRIPT ERROR|Parse Error|ERROR:"
noise_pattern="resources still in use at exit|core/io/resource\.cpp"

fail() {
  echo "PORTÃO FALHOU: $1"
  [ $# -ge 2 ] && echo "log completo: $2"
  exit 1
}

echo "[1/4] import"
perl -e 'alarm 300; exec @ARGV' "$GODOT" --headless --path . --import > "$log_dir/import.log" 2>&1
errors=$(grep -E "$error_pattern" "$log_dir/import.log" | grep -vE "$noise_pattern")
if [ -n "$errors" ]; then
  echo "$errors" | head -10
  fail "import" "$log_dir/import.log"
fi

echo "[2/4] testes"
perl -e 'alarm 600; exec @ARGV' "$GODOT" --headless --path . -s res://tests/run_tests.gd \
  > "$log_dir/tests.log" 2>&1
code=$?
grep -E "^FAIL" "$log_dir/tests.log" | head -15
grep -E "^[0-9]+ passed" "$log_dir/tests.log"
compile_errors=$(grep -E "Parse Error|Failed to load script" "$log_dir/tests.log")
if [ $code -ne 0 ] || [ -n "$compile_errors" ]; then
  echo "$compile_errors" | head -10
  fail "testes (exit $code)" "$log_dir/tests.log"
fi

if [ $skip_smoke -eq 0 ]; then
  echo "[3/4] smoke"
  tools/smoke.sh > "$log_dir/smoke.log" 2>&1
  code=$?
  tail -1 "$log_dir/smoke.log"
  if [ $code -ne 0 ]; then
    grep -A5 "SMOKE FAIL" "$log_dir/smoke.log" | head -20
    fail "smoke" "$log_dir/smoke.log"
  fi
else
  echo "[3/4] smoke PULADO (--skip-smoke) — não declare a feature concluída assim"
fi

echo "[4/4] varreduras"
problems=0
found=$(grep -rnE "Node3D|Camera3D|MeshInstance3D|Body3D|Area3D" \
  --include='*.gd' --include='*.tscn' --include='*.tres' . | grep -v "^./.godot/")
[ -n "$found" ] && { echo "nó/recurso 3D:"; echo "$found" | head; problems=1; }
found=$(grep -rnE "^\s*#" --include='*.gd' . | grep -v "^./.godot/")
[ -n "$found" ] && { echo "comentário em .gd:"; echo "$found" | head; problems=1; }
found=$(grep -rn "font_size = " --include='*.tscn' --include='*.tres' scenes assets \
  | grep -vE "font_size = (16|32|48)$")
[ -n "$found" ] && { echo "fonte fora de múltiplo de 16:"; echo "$found" | head; problems=1; }
found=$(grep -rnE 'font_size_override\("[a-z_]+", *[0-9]+\)' --include='*.gd' scenes autoload \
  | grep -vE ', *(16|32|48)\)')
[ -n "$found" ] && { echo "fonte fora de múltiplo de 16 (código):"; echo "$found" | head; problems=1; }
found=$(git status --short | grep -E "\.godot/|\.DS_Store|settings\.local\.json")
[ -n "$found" ] && { echo "lixo no git status:"; echo "$found"; problems=1; }
found=$(git ls-files | grep -E "\.(dmg|exe|zip|pck|app)$|^builds/")
[ -n "$found" ] && echo "AVISO build versionado (decisão do humano): $found"
[ $problems -eq 0 ] || fail "varreduras"

echo "PORTÕES VERDES"

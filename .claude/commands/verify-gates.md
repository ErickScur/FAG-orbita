---
description: Roda os portões de qualidade do ÓRBITA na ordem estrita — import → testes → smoke → varreduras — parando no primeiro que falhar.
---

# Portões de qualidade (verify-gates)

Todo comando `$GODOT` vai com limite de tempo (`perl -e 'alarm 120; exec @ARGV' "$GODOT" ...`) — o macOS não tem `timeout`. Rode **nesta ordem** e pare no primeiro que falhar. Qualquer `SCRIPT ERROR`, `Parse Error`, `ERROR:` ou `WARNING:` de script novo no output reprova.

1. **Import / compilação**
   `"$GODOT" --headless --path . --import 2>&1 | tee .godot/orbita-import.log; grep -nE "SCRIPT ERROR|Parse Error|ERROR:" .godot/orbita-import.log`
2. **Testes de lógica** (runner próprio, ADR-007)
   `"$GODOT" --headless --path . -s res://tests/run_tests.gd` → exit code 0 e resumo "N passed, 0 failed".
3. **Smoke de cenas**
   `tools/smoke.sh` → carrega cada cena de `tests/scenes.txt` headless; 0 erros.
4. **Varreduras de regra dura**
   - 2D: `grep -rnE "Node3D|Camera3D|MeshInstance3D|Body3D|Area3D" --include=*.gd --include=*.tscn --include=*.tres . | grep -v "^./.godot"` → vazio.
   - Sem comentários: `grep -rnE "^\s*#|[^\"']#[^\"']*$" --include=*.gd autoload scenes scripts tests tools` → revisar; nenhum comentário real permitido.
   - Fonte: `grep -rn "font_size = " --include='*.tscn' --include='*.tres' scenes assets | grep -vE "font_size = (16|32|48)$"` → vazio (cenas de jogador; sondas de QA em `tests/` são exceção).
   - Git: `git status --short` não pode listar lixo (`.godot/`, `.DS_Store`, builds) nem `.claude/settings.local.json`.
5. **QA visual** (quando a feature tem UI/gameplay): skill `godot-qa` com o roteiro da seção 10 da feature.

Só declare concluído com **todos verdes**. Se um portão ainda não existe (ex.: antes da F06), registre no log da feature qual foi pulado e por quê.

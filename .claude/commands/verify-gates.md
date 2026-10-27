---
description: Roda os portões de qualidade do ÓRBITA na ordem estrita — import → testes → smoke → varreduras — parando no primeiro que falhar.
---

# Portões de qualidade (verify-gates)

```bash
tools/gates.sh
```

O script roda, nesta ordem, e para no primeiro que falhar (logs completos em
`$TMPDIR/orbita-gates/`):

1. **Import / compilação** — `--import` headless; qualquer `SCRIPT ERROR`, `Parse Error` ou
   `ERROR:` reprova (o ruído "resources still in use at exit" é ignorado).
2. **Testes de lógica** — `tests/run_tests.gd`; exit 0 e "N passed, 0 failed". Inclui a
   paridade GDD-P ↔ `Balance` (`test_gdd_parity`), a alcançabilidade das fases e o limite de
   luzes por janela.
3. **Smoke de cenas** — `tools/smoke.sh` (cada cena de `tests/scenes.txt`).
4. **Varreduras de regra dura** — nó/recurso 3D, comentário em `.gd`, fonte fora de múltiplo de
   16 (em `.tscn`/`.tres` e em `add_theme_font_size_override` no código), lixo no `git status`
   (`.godot/`, `.DS_Store`, `settings.local.json`). Build versionado sai como **AVISO**.

`tools/gates.sh --skip-smoke` serve para iterar rápido; **nunca** declare uma feature concluída
sem a rodada completa.

5. **QA visual** (quando a feature tem UI/gameplay): skill `godot-qa`, com `tools/qa.sh` e
   roteiro com marcos.

Só declare concluído com **todos verdes**. Portão pulado → registre no log da feature qual e por
quê.

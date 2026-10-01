---
name: godot-qa
description: Roda o ÓRBITA (ou uma cena) com janela real, injeta inputs roteirizados, captura screenshots e o log de erros, e o agente LÊ as imagens para validar a feature visualmente. Use para QA visual de qualquer feature com UI/gameplay, "teste no jogo", "veja se está aparecendo", ou ao fechar uma feature.
---

# godot-qa — QA visual por screenshot

Depende da F06 (autoload `QACapture`). Antes dela existir, faça só o smoke headless.

## 1. Roteiro
Crie `tests/qa/<feature>_<caso>.json`:
```json
{
  "scene": "res://scenes/levels/core_hub.tscn",
  "steps": [
    {"frame": 30, "screenshot": "01_inicio"},
    {"frame": 31, "action": "move_right", "pressed": true},
    {"frame": 90, "action": "move_right", "pressed": false},
    {"frame": 91, "action": "jump", "pressed": true},
    {"frame": 100, "action": "jump", "pressed": false},
    {"frame": 110, "screenshot": "02_no_ar"},
    {"frame": 200, "quit": true}
  ]
}
```

## 2. Execução (janela real — o renderer precisa existir para capturar)

> **A janela de QA vai para o segundo monitor e não rouba o foco.** O `QACapture` lê `ORBITA_QA_SCREEN` (já definida como `1` em `.claude/settings.json`) ou a flag `--qa-screen=N`, centraliza a janela naquela tela e liga `WINDOW_FLAG_NO_FOCUS`. Nunca rode QA na tela primária sem necessidade: o humano está trabalhando nela.
Saída no **scratchpad da sessão** (nunca no repo):
```bash
OUT="<scratchpad>/qa/<feature>"; mkdir -p "$OUT"
"$GODOT" --path . --fixed-fps 60 -- --qa --qa-script=res://tests/qa/<arquivo>.json --qa-out="$OUT" 2>&1 | tee "$OUT/log.txt"
```
Rode em background se passar de ~20 s; mate o processo ao final (sem órfão).

## 3. Análise
1. `grep -nE "SCRIPT ERROR|ERROR:|Parse Error" "$OUT/log.txt"` → deve ser vazio.
2. **Leia cada PNG** com a ferramenta Read e compare com o que a seção 10 da feature diz que deve aparecer (posição do personagem, HUD, luz, texto em pt-BR com acentos, sem sprites faltando, sem nós 3D).
3. Problema → descreva o que viu vs. o esperado, corrija (ou devolva ao subagente) e rode de novo.
4. Registre no log da feature: roteiro usado, resultado, screenshots-chave (caminho do scratchpad não é versionado — descreva o que viu).

## Dicas
- Frames a 60 fps: 60 = 1 s. Deixe ~30 frames após trocar de cena antes de capturar (fade + loading).
- Para testar UI de menu, use `ui_down`/`ui_accept` nas ações.
- Para testar morte/game over rapidamente, o roteiro pode chamar `{"frame": N, "call": "GameState.apply_damage", "args": [100]}` se a F06 implementou `call` (confira no `qa_capture.gd`).

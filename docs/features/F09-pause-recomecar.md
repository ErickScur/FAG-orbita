---
id: F09
title: Pause & recomeçar
status: done
scope: demo
block: 1
priority: P0
rubric: ["Botão de pause", "Botão de recomeçar jogo", "Ajuste de volume (dentro do jogo)"]
depends_on: ["F03", "F07", "F08"]
unblocks: ["F14", "F15"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F09 — Pause & recomeçar

## 1. Contexto e objetivo

Esc (ou Start) congela a estação: a árvore pausa, o timer do reator para ([GDD-2.5 Timer](../design/GDD.md#gdd-2-5-timer)) e abre o menu de pause com **RETOMAR / OPÇÕES / RECOMEÇAR / SAIR PARA O MENU**. RECOMEÇAR oferece voltar ao último backup (doca) ou reiniciar o jogo do início. Opções abre a mesma tela da [F08](F08-opcoes-dificuldade.md), cumprindo "volume dentro do jogo".

Serve ao pilar **ESCASSEZ** ([GDD pilares](../design/GDD.md#gdd-pilares)) de forma justa: pausar nunca custa estabilidade. Aparece em qualquer fase.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (tela 3: RETOMAR / MAPA / ARQUIVO DE LOGS / OPÇÕES / SAIR PARA O MENU; "congela o timer do reator") · [GDD-2.5 Timer](../design/GDD.md#gdd-2-5-timer) · [GDD-2.4 Controles](../design/GDD.md#gdd-2-4) (`pause` = Esc / Start)
- **Parâmetros:** nenhum
- **ADRs:** [ADR-009](../DECISIONS.md#adr-009) · [ADR-010](../DECISIONS.md#adr-010)

## 3. Critério de avaliação atendido

- **Botão de pause** ([ENTREGAS §3.2](../ENTREGAS.md#rubrica)): o avaliador aperta Esc no meio da Estufa; tudo congela (SR-3, esporos, barra do reator) e o menu aparece.
- **Botão de recomeçar jogo**: RECOMEÇAR → DO INÍCIO volta ao Núcleo Central com estado zerado; DO ÚLTIMO BACKUP volta à última doca.
- **Ajuste de volume (dentro do jogo)** ([ENTREGAS §3.1](../ENTREGAS.md#rubrica)): OPÇÕES no pause abre os sliders.

## 4. Escopo

### Inclui
- `scenes/ui/pause_menu.tscn` (+ `pause_menu.gd`), `CanvasLayer` (layer 50), `process_mode = ALWAYS`, instanciado **uma vez** como filho do `SceneManager` (ADR-F09-001).
- Abre/fecha com a ação `pause`, só quando a cena atual é jogável (`ScenePaths.is_level(scene_file_path)` ou grupo `&"gameplay"`) e o `SceneManager` não está em transição.
- `get_tree().paused = true/false` + `EventBus.game_paused.emit(bool)`.
- Submenu RECOMEÇAR (painel próprio) com **DO ÚLTIMO BACKUP** (desabilitado sem save), **DO INÍCIO** (confirmação) e **CANCELAR**.
- SAIR PARA O MENU com confirmação ("O progresso desde o último backup será perdido.").
- Auto-pause quando a janela perde o foco (`NOTIFICATION_APPLICATION_FOCUS_OUT`) durante gameplay.
- `tests/qa/scenes/pause_sandbox.tscn` (grupo `gameplay`) para testar antes das fases existirem.

### Não inclui
- **MAPA** (F47 — Final) e **ARQUIVO DE LOGS** ([F33](F33-arquivo-logs.md), stretch — se feita, adiciona o botão aqui).
- Pausar durante a tela de loading, splash ou menus.
- Mostrar estatísticas no pause (vão para a F10).

## 5. Critérios de aceite

- [x] Em uma fase, Esc/Start abre o pause: fundo escurecido, título "PAUSA", 4 botões, foco em RETOMAR; `get_tree().paused == true`; `EventBus.game_paused(true)` emitido.
- [x] Com o pause aberto, `GameState.is_timer_frozen() == true` e a Estabilidade do Reator não muda (conferido em screenshot antes/depois de 5 s).
- [x] Esc/Start/`ui_cancel` ou RETOMAR fecham; `paused == false`; `game_paused(false)` emitido; o personagem não pula/interage com a tecla que fechou o menu (input marcado como tratado).
- [x] OPÇÕES abre `options_menu.tscn` por cima; alterar volume funciona com a árvore pausada; VOLTAR retorna o foco a OPÇÕES.
- [x] RECOMEÇAR → painel; sem save, DO ÚLTIMO BACKUP está desabilitado.
- [~] DO ÚLTIMO BACKUP → `SaveManager.load_game()` → `SceneManager.goto(GameState.checkpoint.scene)`. *Ligado e testável, mas inalcançável até a [F11](F11-salvar-carregar.md): o `SaveManager` é esqueleto (`has_save()` falso), então o botão fica desabilitado.*
- [x] DO INÍCIO → confirmação → `SaveManager.delete_save()`, `GameState.new_game()`, `SceneManager.goto("res://scenes/levels/core_hub.tscn")`.
- [x] SAIR PARA O MENU → confirmação → `SceneManager.goto("res://scenes/ui/main_menu.tscn")`, árvore despausada.
- [x] Esc no menu principal, no splash ou no loading não abre o pause.
- [~] Alt-Tab durante a fase abre o pause automaticamente. *Implementado por `NOTIFICATION_APPLICATION_FOCUS_OUT`; não dá para roteirizar no `QACapture` — verificação fica para o playtest humano.*
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/pause_menu.tscn (+ pause_menu.gd)
autoload/scene_manager.gd          (+ instancia PauseMenu no _ready)
tests/qa/scenes/pause_sandbox.tscn (+ pause_sandbox.gd)
```

### Árvore de `pause_menu.tscn`
```
PauseMenu (CanvasLayer, layer 50, process_mode ALWAYS, visible false, script pause_menu.gd)
└─ Root (Control, full rect)
   ├─ Dim (ColorRect, #000000 alpha 0.6)
   ├─ Main (PanelContainer, centro, largura 160)
   │  └─ VBox
   │     ├─ Title (Label, "PAUSA")
   │     ├─ ResumeButton ("RETOMAR")
   │     ├─ OptionsButton ("OPÇÕES")
   │     ├─ RestartButton ("RECOMEÇAR")
   │     └─ QuitButton ("SAIR PARA O MENU")
   ├─ RestartPanel (PanelContainer, centro, oculto)
   │  └─ VBox
   │     ├─ Title (Label, "RECOMEÇAR")
   │     ├─ FromBackupButton ("DO ÚLTIMO BACKUP")
   │     ├─ FromStartButton ("DO INÍCIO")
   │     └─ CancelButton ("CANCELAR")
   └─ Overlay (Control, full rect: options_menu / confirm_dialog)
```

### `pause_menu.gd`
```gdscript
extends CanvasLayer

var is_open: bool = false

func open() -> void
func close() -> void
func can_pause() -> bool
```
- `_unhandled_input(event)`: `event.is_action_pressed(&"pause")` → `close()` se aberto (e sem overlay), senão `open()` se `can_pause()`; `set_input_as_handled()`. `ui_cancel` com painel/overlay aberto volta um nível.
- `can_pause()`: `not SceneManager.is_transitioning()` e cena atual existe e (`ScenePaths.is_level(scene.scene_file_path)` ou `scene.is_in_group(&"gameplay")`).
- `open()`: `visible = true`, `get_tree().paused = true`, `EventBus.game_paused.emit(true)`, `AudioManager.play_sfx(&"ui_confirm")`, foco em RETOMAR, `FromBackupButton.disabled = not SaveManager.has_save()`.
- `close()`: esconde painéis, `get_tree().paused = false`, `EventBus.game_paused.emit(false)`, `AudioManager.play_sfx(&"ui_back")`.
- Qualquer ação que troca de cena chama `close()` antes de `SceneManager.goto(...)`.
- `_notification(what)`: `NOTIFICATION_APPLICATION_FOCUS_OUT` e `can_pause()` e não aberto → `open()`.
- Usa `confirm_dialog.tscn` da [F07](F07-menu-principal.md) para DO INÍCIO e SAIR PARA O MENU.

### `SceneManager` (acréscimo)
- `_ready()`: `add_child(preload("res://scenes/ui/pause_menu.tscn").instantiate())` (se o arquivo existir). Ao iniciar qualquer `goto`, chama `pause_menu.close()` se aberto.

### `pause_sandbox.tscn`
`Node2D` no grupo `gameplay` com `Label` exibindo `GameState.reactor_percent` e um contador que incrementa em `_process` (prova visual de que o jogo congela).

### Autoloads / sinais do EventBus
- Emite `EventBus.game_paused(paused: bool)`. `GameState` (F02) já escuta para `is_timer_frozen()`.

### Dados (`data/`)
- Nenhum.

### Input actions / camadas de colisão
- `pause` (Esc / Start), `ui_*`.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SFX-PACK](../ASSETS.md#sfx-pack) | `ui_confirm`, `ui_back`, `ui_move` | Beeps (F05) |
| [UI-FONT](../ASSETS.md#ui-font) | Textos | Tema da F05 |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `pause_menu.tscn` + `.gd` com painel principal.
- [x] **Passo 2** — Instanciar no `SceneManager`; `can_pause()`.
- [x] **Passo 3** — Painel RECOMEÇAR + confirmações + integração com `SaveManager`/`GameState` (`load_game` real chega na [F11](F11-salvar-carregar.md); até lá, DO ÚLTIMO BACKUP fica desabilitado porque `has_save()` é falso).
- [x] **Passo 4** — OPÇÕES via `options_menu.tscn`.
- [x] **Passo 5** — `pause_sandbox.tscn`; `tests/scenes.txt` += `pause_menu.tscn`, `pause_sandbox.tscn`; roteiro QA.
- [x] **Passo 6** — Portões; commit `feat(F09): menu de pause com opções e recomeçar`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** `test_scene_paths.gd` (F03) ganha caso para cenas jogáveis. Resto coberto por QA.
- **Smoke:** `res://scenes/ui/pause_menu.tscn`, `res://tests/qa/scenes/pause_sandbox.tscn`.
- **Roteiro godot-qa:** cena `pause_sandbox.tscn`, roteiro `f09_pause.json`:
  - frame 30 screenshot `f09_running` (contador ~30).
  - frame 40 `pause` press; frame 41 release; frame 50 screenshot `f09_paused` (painel PAUSA com 4 botões, foco em RETOMAR, contador parado ~40).
  - frame 200 screenshot `f09_still_paused` (contador idêntico ao anterior).
  - `ui_down` ×2 (RECOMEÇAR), `ui_accept`; screenshot `f09_restart_panel` (3 opções, DO ÚLTIMO BACKUP cinza sem save).
  - `ui_cancel`; `ui_up` ×1 (OPÇÕES), `ui_accept`; screenshot `f09_options_in_pause` (tela de opções sobre o pause).
  - `ui_cancel`; `pause`; screenshot `f09_resumed` (sem painel, contador voltou a subir).
  - Segundo roteiro `f09_quit.json`: abrir pause → SAIR PARA O MENU → SIM; screenshot `f09_back_to_menu` (menu principal).
- **Playtest humano (opcional):** pausar no meio de um pulo e retomar; conferir que nada "pula" sozinho.

## 11. ADRs locais

### ADR-F09-001 — Pause como filho do `SceneManager`
- **Contexto:** a lista de autoloads é fechada e o pause precisa existir em toda fase sem cada fase instanciá-lo.
- **Decisão:** o `SceneManager` instancia `pause_menu.tscn` uma vez; o menu decide se pode abrir olhando a cena atual (`ScenePaths.is_level` ou grupo `gameplay`).
- **Consequências:** fases não precisam conhecer o pause; `level_base.tscn` ([F21](F21-construtor-fases-ascii.md)) não o inclui. **Data:** 2026-09-19.

### ADR-F09-002 — RECOMEÇAR com duas opções
- **Contexto:** a rubrica pede "recomeçar jogo"; o GDD tem saves por doca.
- **Decisão:** RECOMEÇAR → DO ÚLTIMO BACKUP ou DO INÍCIO (apaga o save após confirmação).
- **Consequências:** cobre tanto "tentar de novo" quanto "reiniciar a partida". **Data:** 2026-09-19.

### ADR-F09-003 — `pause` tratado antes de `ui_cancel` no mesmo evento
- **Contexto:** a ação `pause` e a `ui_cancel` compartilham a tecla Esc, então um único `InputEvent` satisfaz as duas.
- **Decisão:** `pause_menu.gd` testa `pause` primeiro em `_unhandled_input`, chama `set_input_as_handled()` e **retorna**; só um evento que não seja `pause` chega ao ramo de `ui_cancel`.
- **Consequências:** Esc abre e fecha o pause sem "pular um nível" de painel de uma vez só. Dentro das sobreposições (opções/confirmação) o `ui_cancel` é consumido pelo nó mais profundo antes de chegar aqui. **Data:** 2026-09-19.

### ADR-F09-004 — Cena de prova `pause_sandbox` no lugar de uma fase
- **Contexto:** nenhuma fase existe ainda (F28/F29), mas o pause precisa ser exercitado.
- **Decisão:** `tests/qa/scenes/pause_sandbox.tscn` (`Node2D` no grupo `gameplay`) com contador por `_process`, marcador que se move e a "Estabilidade do Reator" na tela, entrando no `tests/scenes.txt`.
- **Consequências:** o congelamento vira prova visual (contador idêntico entre dois screenshots); quando as fases existirem a cena continua servindo de regressão barata. **Data:** 2026-09-19.

### ADR-F09-005 — `SceneManager` fecha o pause em toda troca de cena
- **Contexto:** o plano pedia que "qualquer ação que troca de cena chame `close()`", o que é fácil de esquecer em features futuras.
- **Decisão:** além de o próprio pause fechar antes de navegar, `SceneManager.goto`/`goto_with_loading`/`goto_instant` chamam `_close_pause()`; `SceneManager.pause_menu()` expõe a instância.
- **Consequências:** nenhuma cena nova pode herdar a árvore pausada por engano. **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.8 (tela 3) · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `scenes/ui/pause_menu.tscn`/`.gd` (`CanvasLayer` layer 50, `process_mode = ALWAYS`, oculto), instanciado uma única vez por `SceneManager._ready()` (ADR-F09-001), mais `tests/qa/scenes/pause_sandbox.tscn`/`.gd`. `can_pause()` exige `not SceneManager.is_transitioning()` e cena de fase (`ScenePaths.is_level`) ou grupo `gameplay`; `open()`/`close()` mexem em `get_tree().paused` e emitem `EventBus.game_paused(bool)` — o `GameState.is_timer_frozen()` da F02 já escuta, nada foi duplicado. Painel RECOMEÇAR com DO ÚLTIMO BACKUP / DO INÍCIO / CANCELAR, confirmações pelo `confirm_dialog` da F07 e OPÇÕES pela cena da F08.
- **`SceneManager`**: `PAUSE_MENU_SCENE`, `_spawn_pause_menu()`, `pause_menu()` e `_close_pause()` em `goto`/`goto_with_loading`/`goto_instant` (ADR-F09-005).
- **Portões**: `--import` limpo · 99 testes · smoke 12/12 (inclui `pause_menu.tscn` e `pause_sandbox.tscn`) · varreduras vazias.
- **QA visual** (`tests/qa/f09_pause.json`, janela real, `--qa-scale=3`): `c0_jogando` CONTADOR 40; `c_pause_sobre_a_cena` (frame 66) painel PAUSA sobre a cena escurecida, foco em RETOMAR, CONTADOR **50**; `c2_pause_congelado` (frame 170) CONTADOR ainda **50** e marcador imóvel — 104 frames congelados; `c3_painel_recomecar` com DO ÚLTIMO BACKUP cinza (sem save) e foco em DO INÍCIO; `c4_voltou_ao_pause` após `ui_cancel`; `c5_opcoes_no_pause` com as opções por cima; `d_retorno_ao_jogo` CONTADOR 66 sem painel; `d2_contador_voltou_a_subir` CONTADOR 134.
- **Próximo passo**: com a [F11](F11-salvar-carregar.md), habilitar e testar DO ÚLTIMO BACKUP; com a [F28](F28-fase-nucleo-central.md), repetir o QA dentro de uma fase de verdade.

### 2026-09-19 — Correção: foco escapava do modal de confirmação (relato do jogador)
- **Sintoma**: no pause → SAIR PARA O MENU, o modal "O progresso desde o último backup será perdido." abria, mas as **setas moviam o foco para os botões do pause atrás**, tornando impossível confirmar em SIM pelo teclado/controle. Com mouse funcionava — por isso não apareceu no QA anterior.
- **Causa**: os botões do modal não tinham `focus_neighbor_*`; o Godot então busca o vizinho **espacialmente** e encontra os controles da tela de baixo, que continuavam focáveis.
- **Correção**: `scripts/core/focus_trap.gd` (`class_name FocusTrap`) — ao abrir a sobreposição, desliga `focus_mode` de todo `Control` fora dela e liga os botões permitidos em ciclo nas quatro direções; ao fechar, restaura o modo original de cada um. Aplicado no `confirm_dialog.gd` e no `options_menu.gd` (que tinha o mesmo risco ao ser aberto por cima do pause).
- **Verificação**: `tests/test_focus_trap.gd` (2 casos: desliga/restaura o fundo, e o ciclo de vizinhos) + roteiro de regressão `tests/qa/f09_focus_trap.json` — screenshots mostram o foco alternando só entre SIM e NÃO após ←, ↑, ↑, e o SIM confirmando.
- **Regra registrada** no `/CLAUDE.md` §9 para toda sobreposição futura (HUD, terminal de energia, arquivo de logs).


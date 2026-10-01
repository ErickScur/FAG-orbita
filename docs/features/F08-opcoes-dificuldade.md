---
id: F08
title: Opções & dificuldade ajustável
status: done
scope: demo
block: 1
priority: P0
rubric: ["Ajuste de volume (dentro do jogo)", "Dificuldade ajustável"]
depends_on: ["F02", "F04", "F07"]
unblocks: ["F09", "F13", "F14"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F08 — Opções & dificuldade ajustável

## 1. Contexto e objetivo

A tela de opções reúne o que a rubrica pede e o que o GDD promete como acessibilidade: volumes separados (geral, música, efeitos, voz), **dificuldade Fácil/Normal/Difícil** ([AJ-003](../design/GDD.md#gdd-ajustes)), **modo sem timer** (desliga a queda do reator) e tela cheia. É uma única cena reutilizada no menu principal ([F07](F07-menu-principal.md)) e no pause ([F09](F09-pause-recomecar.md)), com efeito imediato e persistência em `user://settings.cfg`.

Serve ao pilar **ESCASSEZ** ([GDD pilares](../design/GDD.md#gdd-pilares)) calibrado ao jogador: quem quer pressão joga no Difícil; quem quer só a história liga o modo sem timer.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (tela 2: volume, "modo sem timer") · [Multiplicadores de dificuldade](../design/GDD.md#gdd-p-dificuldade) · [GDD-2.5 Timer](../design/GDD.md#gdd-2-5-timer)
- **Parâmetros:** `Balance.DIFFICULTY_DAMAGE_MULT`, `Balance.DIFFICULTY_REACTOR_MULT` (ADR-F02-001), aplicados por `Settings.damage_multiplier()` / `Settings.reactor_decay_multiplier()` ([F02](F02-autoloads-nucleo.md))
- **Ajustes:** [AJ-003](../design/GDD.md#gdd-ajustes)
- **ADRs:** [ADR-009](../DECISIONS.md#adr-009) (telas da rubrica nunca são cortadas)

## 3. Critério de avaliação atendido

- **Ajuste de volume (dentro do jogo)** ([ENTREGAS §3.1](../ENTREGAS.md#rubrica)): sliders **Geral / Música / Efeitos / Voz** no menu **e** no pause; o avaliador arrasta e ouve na hora (cada slider toca um SFX de teste ao soltar).
- **Dificuldade ajustável** ([ENTREGAS §3.2](../ENTREGAS.md#rubrica)): seletor Fácil/Normal/Difícil com descrição do efeito; na apresentação, trocar para Difícil e tomar dano de uma SR-3 (15 em vez de 10).

## 4. Escopo

### Inclui
- `scenes/ui/options_menu.tscn` (+ `options_menu.gd`), `process_mode = ALWAYS`, com `signal closed`.
- 4 `HSlider` (0..1, passo 0,05) → `AudioManager.set_bus_volume`.
- `OptionButton` de dificuldade com texto explicativo abaixo (dano recebido e velocidade do reator em %).
- `CheckBox` "Modo sem timer" e `CheckBox` "Tela cheia".
- Botão **VOLTAR** (e `ui_cancel`) → `Settings.save_settings()` → `closed.emit()` → `queue_free()`.
- Troca de dificuldade durante a partida vale imediatamente (multiplicadores lidos a cada uso).

### Não inclui
- Remapeamento de teclas, tamanho de legenda, modo daltônico (F51 — Final).
- Escolha de dificuldade num passo separado ao iniciar NOVO SISTEMA (a opção fica só aqui).
- Resolução/vsync (Final).

## 5. Critérios de aceite

- [x] Abrir OPÇÕES no menu mostra os valores atuais de `Settings` (sliders nas posições salvas, dificuldade selecionada, checkboxes corretos).
- [x] Mover o slider **Música** muda o volume da trilha em tempo real; no 0 fica mudo; o valor aparece em % à direita ("80%").
- [x] Soltar o slider **Efeitos** toca `ui_confirm`; soltar **Voz** toca `ui_confirm` pelo bus `Voice` (via `play_voice` com o stream placeholder).
- [x] Dificuldade exibe: Fácil — "Dano recebido 50% · Reator cai 50% mais devagar"; Normal — "Valores originais"; Difícil — "Dano recebido 150% · Reator cai 50% mais rápido". Os números vêm de `Balance`, não do texto fixo (formatados com `%d%%`).
- [x] Modo sem timer ligado → `Settings.reactor_decay_multiplier() == 0.0` e rótulo "O reator não perde estabilidade com o tempo".
- [x] Tela cheia alterna imediatamente o modo da janela.
- [x] VOLTAR/Esc/botão B salvam e fecham; reabrir o jogo mantém tudo.
- [x] Navegação completa por teclado/controle (↑/↓ entre linhas, ←/→ ajustam slider e dificuldade).
- [x] Funciona com a árvore pausada (aberta pelo pause).
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/options_menu.tscn (+ options_menu.gd)
scripts/core/difficulty_text.gd     class_name DifficultyText (lógica pura de formatação)
```

### Árvore de `options_menu.tscn`
```
OptionsMenu (Control, full rect, process_mode ALWAYS, script options_menu.gd)
├─ Dim (ColorRect, #000000 alpha 0.7)
└─ Panel (PanelContainer, centro, 300×190)
   └─ VBox (separation 3)
      ├─ Title (Label, "OPÇÕES")
      ├─ MasterRow (HBox: Label "GERAL" 70px · HSlider %MasterSlider · Label %MasterValue)
      ├─ MusicRow  (… "MÚSICA" … %MusicSlider …)
      ├─ SfxRow    (… "EFEITOS" … %SfxSlider …)
      ├─ VoiceRow  (… "VOZ" … %VoiceSlider …)
      ├─ DifficultyRow (HBox: Label "DIFICULDADE" · OptionButton %DifficultyOption [FÁCIL, NORMAL, DIFÍCIL])
      ├─ DifficultyHint (Label %DifficultyHint, autowrap, cor #8A9BA8)
      ├─ NoTimerCheck (CheckBox %NoTimerCheck, "MODO SEM TIMER")
      ├─ FullscreenCheck (CheckBox %FullscreenCheck, "TELA CHEIA")
      └─ BackButton (Button %BackButton, "VOLTAR")
```

### `options_menu.gd`
```gdscript
extends Control

signal closed

const DIFFICULTIES: Array[StringName] = [&"easy", &"normal", &"hard"]
```
- `_ready()`: preenche controles de `Settings`; conecta `value_changed` → `AudioManager.set_bus_volume(&"Master" | &"Music" | &"SFX" | &"Voice", v)` e atualiza `%…Value`; `drag_ended` dos sliders de Efeitos/Voz toca o som de teste; `item_selected` → `Settings.difficulty = DIFFICULTIES[i]` + `DifficultyHint.text = DifficultyText.describe(Settings.difficulty)`; `toggled` do NoTimer → `Settings.no_timer`; Fullscreen → `Settings.fullscreen` + `Settings.apply_display()`; foco inicial em `%MasterSlider`.
- `close()`: `Settings.save_settings()`, `AudioManager.play_sfx(&"ui_back")`, `closed.emit()`, `queue_free()`.
- `_unhandled_input`: `ui_cancel` → `close()` e `get_viewport().set_input_as_handled()`.

### `DifficultyText` (lógica pura)
```gdscript
class_name DifficultyText
extends RefCounted

static func describe(difficulty: StringName) -> String
static func no_timer_hint() -> String
```
`describe(&"hard")` → `"Dano recebido 150% · Reator cai 50% mais rápido"` calculado de `Balance.difficulty_damage_multiplier` e `difficulty_reactor_multiplier`; `&"normal"` → `"Valores originais do jogo"`.

### Autoloads / sinais do EventBus
- Usa `Settings` e `AudioManager`. Nenhum sinal do EventBus (as leituras de multiplicador são feitas por quem aplica: `GameState.apply_damage` e reator da [F14](F14-estabilidade-reator.md)).

### Dados (`data/`)
- Nenhum.

### Input actions / camadas de colisão
- `ui_up/down/left/right`, `ui_accept`, `ui_cancel`.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SFX-PACK](../ASSETS.md#sfx-pack) | `ui_move`, `ui_confirm`, `ui_back` e som de teste | Beeps (F05) |
| [UI-FONT](../ASSETS.md#ui-font) | Textos | Tema da F05 |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `tests/test_difficulty_text.gd` (falha) → `scripts/core/difficulty_text.gd`.
- [x] **Passo 2** — `options_menu.tscn` + `.gd`.
- [x] **Passo 3** — Habilitar o botão OPÇÕES do menu principal (F07) e ligar o `closed`.
- [x] **Passo 4** — `tests/scenes.txt` += `options_menu.tscn`; roteiro de QA.
- [x] **Passo 5** — Portões; atualizar a linha "Dificuldade ajustável" e "Ajuste de volume" em `ENTREGAS.md` quando a F09 também estiver pronta; commit `feat(F08): tela de opções com volumes, dificuldade e modo sem timer`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** `test_difficulty_text.gd` — textos das 3 dificuldades batem com os multiplicadores do `Balance`; `test_settings.gd` (da F02) ganha caso: mudar `difficulty` para `&"hard"` → `damage_multiplier() == 1.5`; `no_timer = true` → `reactor_decay_multiplier() == 0.0`.
- **Smoke:** `res://scenes/ui/options_menu.tscn`.
- **Roteiro godot-qa:** cena `options_menu.tscn`, roteiro `f08_options.json`:
  - frame 20 screenshot `f08_default` (painel centralizado, 4 sliders, NORMAL, checkboxes desmarcados, foco no slider GERAL).
  - frame 30 `ui_down` (MÚSICA); frames 35–60: `ui_left` press/release ×4; frame 65 screenshot `f08_music_down` (slider Música mais à esquerda, valor "60%").
  - `ui_down` ×3 até DIFICULDADE; `ui_accept` abre a lista; `ui_down` ×1; `ui_accept`; screenshot `f08_hard` (DIFÍCIL selecionado, dica "Dano recebido 150% · Reator cai 50% mais rápido").
  - `ui_down` até MODO SEM TIMER; `ui_accept`; screenshot `f08_no_timer` (checkbox marcado).
  - Depois, rodar de novo a cena com um roteiro só de screenshot: `f08_persisted` deve mostrar os valores alterados (persistência).
- **Playtest humano (opcional):** mexer nos volumes com a música do menu tocando e dizer se a resposta é imediata.

## 11. ADRs locais

### ADR-F08-001 — Dificuldade pode mudar a qualquer momento
- **Contexto:** o GDD não restringe quando mudar.
- **Decisão:** sem trava; multiplicadores são lidos no momento do dano/decaimento.
- **Consequências:** simples, e permite demonstrar ao vivo na apresentação. Estatísticas de fim não registram dificuldade (Final se desejado). **Data:** 2026-09-19.

### ADR-F08-002 — Tela única reutilizada no menu e no pause
- **Decisão:** `options_menu.tscn` é instanciada como overlay com `process_mode = ALWAYS` e sinal `closed`.
- **Consequências:** um único lugar para manter; atende "volume no menu **e** no pause". **Data:** 2026-09-19.

### ADR-F08-003 — Dificuldade também muda com ←/→
- **Contexto:** o critério pede ←/→ para ajustar a dificuldade, mas o `OptionButton` do Godot só responde a clique/`ui_accept` (abrindo um `PopupMenu`, que é uma `Window` e se comporta mal com a árvore pausada).
- **Decisão:** `options_menu.gd` trata `ui_left`/`ui_right` em `_input()` quando o `OptionButton` tem foco e troca o item sem abrir o popup; `item_selected` continua ligado para mouse.
- **Consequências:** teclado e controle nunca precisam do popup; o popup segue disponível para o mouse. **Data:** 2026-09-19.

### ADR-F08-004 — Painel de opções ocupa quase a tela inteira
- **Contexto:** a árvore previa um painel de 300×190, dimensionado para a fonte padrão de 10 px. Com a m5x7 em 16 px (ADR-F07-005) as linhas ficam mais altas e a dica da dificuldade tem 254 px.
- **Decisão:** o `PanelContainer` é ancorado em tela cheia com margens de 12 px na horizontal e 6 px na vertical (360×204) e a `VBox` usa `separation = 1`.
- **Consequências:** tudo cabe sem cortar, inclusive a dica extra do modo sem timer; a tela de opções cobre o menu por completo (o `Dim` atrás continua). **Data:** 2026-09-19.

### ADR-F08-005 — Som de teste também no ajuste por teclado
- **Contexto:** `drag_ended` só dispara em arrasto de mouse; navegando por teclado o jogador nunca ouviria o efeito.
- **Decisão:** os sliders EFEITOS e VOZ tocam a amostra em `value_changed` quando **não** há arrasto em curso (`drag_started`/`drag_ended` controlam a flag) e uma vez ao soltar o arrasto.
- **Consequências:** um bipe por passo no teclado, um bipe por arrasto no mouse — sem spam. **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.8 (tela 2) e AJ-003 · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `scripts/core/difficulty_text.gd` (`DifficultyText.describe`/`no_timer_hint`, textos calculados a partir de `Balance.DIFFICULTY_*`), `tests/test_difficulty_text.gd` (6 casos) e `scenes/ui/options_menu.tscn`/`.gd` com `process_mode = ALWAYS` e sinal `closed`. Sliders GERAL/MÚSICA/EFEITOS/VOZ (0..1, passo 0,05) gravam por `AudioManager.set_bus_volume` — que já escreve em `Settings` — e mostram o valor em %; `OptionButton` de dificuldade; `MODO SEM TIMER` e `TELA CHEIA`; `VOLTAR`/`ui_cancel` salvam em `user://settings.cfg` e fecham.
- **Reuso:** a mesma cena é instanciada pelo menu principal (F07) e pelo pause (F09) — ADR-F08-002 confirmado na prática.
- **Portões**: `--import` limpo · 99 testes · smoke 12/12 (inclui `options_menu.tscn`) · varreduras vazias.
- **QA visual** (`tests/qa/f07_menu.json` e `f09_pause.json`): `b0_opcoes_padrao` mostra os valores de `Settings` e o foco no slider GERAL; `b_opcoes_dificil_musica_60` mostra MÚSICA em 60% depois de 4× ←, DIFÍCIL selecionado e a dica "Dano recebido 150% · Reator cai 50% mais rápido"; `b2_opcoes_sem_timer` mostra o checkbox marcado e "O reator não perde estabilidade com o tempo"; `c5_opcoes_no_pause` mostra a mesma tela **sobre o pause**, com os valores persistidos da execução anterior (prova de persistência + funcionamento com a árvore pausada).
- **Próximo passo**: a coluna "Dificuldade ajustável"/"Ajuste de volume" do `ENTREGAS.md` fica para quem fechar o bloco (F09 também já está pronta).

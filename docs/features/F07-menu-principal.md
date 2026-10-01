---
id: F07
title: Menu principal
status: done
scope: demo
block: 1
priority: P0
rubric: ["Menu"]
depends_on: ["F03", "F04", "F05"]
unblocks: ["F08", "F09", "F10", "F11"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F07 — Menu principal

## 1. Contexto e objetivo

A tela inicial é o primeiro contato com o tom do ÓRBITA: espaço escuro, estação ao longe, **sem música, só ruído de rádio** ([GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas), tela 1). Ela dá acesso a continuar a partida salva, começar um novo sistema, abrir as opções e sair. É uma cena de UI pura, navegável por mouse, teclado e controle.

Serve ao pilar **AUSÊNCIA** ([GDD pilares](../design/GDD.md#gdd-pilares)). O jogador chega aqui depois do splash ([F03](F03-cenas-splash-loading.md)) e ao sair de uma partida pelo pause ou pelas telas de fim.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (tela 1: CONTINUAR / NOVO SISTEMA / OPÇÕES / ARQUIVO / SAIR) · [GDD-2.9 Música](../design/GDD.md#gdd-2-9-musica) · [GDD-2.9 Paleta](../design/GDD.md#gdd-2-9-paleta)
- **Parâmetros:** nenhum de gameplay
- **Jornada:** [Ideia principal](../design/JORNADA-DO-HEROI.md#jh-ideia) · [Etapa 1 — Mundo Comum](../design/JORNADA-DO-HEROI.md#jh-1) (NOVO SISTEMA leva ao despertar no Núcleo Central)
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) · [ADR-009](../DECISIONS.md#adr-009)

## 3. Critério de avaliação atendido

**Menu** ([ENTREGAS §3.1](../ENTREGAS.md#rubrica)): "Tela inicial com Continuar/Novo/Opções/Sair". O avaliador vê o logo sobre o espaço em parallax lento, navega com setas/controle (foco visível) e ouve o ruído de rádio.

## 4. Escopo

### Inclui
- `scenes/ui/main_menu.tscn` (+ `main_menu.gd`): fundo BG-SPACE com rolagem lenta, logo, versão, 4 botões.
- **CONTINUAR** — habilitado só se `SaveManager.has_save()`; carrega e vai ao checkpoint.
- **NOVO SISTEMA** — se já existe save, pede confirmação ("O backup atual será apagado."); `GameState.new_game()` → `SceneManager.goto("res://scenes/levels/core_hub.tscn")`.
- **OPÇÕES** — abre `options_menu.tscn` como sobreposição ([F08](F08-opcoes-dificuldade.md)); desabilitado enquanto a F08 não existir.
- **SAIR** — `get_tree().quit()`.
- Música `&"menu"` e SFX `ui_move`/`ui_confirm`/`ui_back`.
- Painel de confirmação reutilizável `scenes/ui/confirm_dialog.tscn` (usado também por F09/F10).

### Não inclui
- **ARQUIVO** (codex): o botão não aparece na Demo; entra se a [F33](F33-arquivo-logs.md) (stretch) for feita.
- Estação girando — o GDD pede "estação girando devagar"; na Demo é a camada `near` do parallax deslizando (estação girando como sprite animado fica para o Final).
- Tela de créditos (créditos ficam no `README.md` e na F10 "FIM DA DEMO").
- Remapeamento e seleção de idioma (Final).

## 5. Critérios de aceite

- [x] Do splash o jogo chega aqui com fade; `AudioManager.current_music() == &"menu"`.
- [x] O foco inicial está em CONTINUAR (se habilitado) ou NOVO SISTEMA; ↑/↓ e o analógico movem o foco com som `ui_move`; Enter/Espaço/botão A confirmam com `ui_confirm`.
- [x] Sem `user://save.json`, CONTINUAR aparece desabilitado (cor `#56606A`) e é pulado na navegação.
- [~] NOVO SISTEMA sem save → fade → fase. Com save → confirmação com **SIM** / **NÃO** (foco em NÃO); SIM apaga o save e inicia; NÃO/Esc volta ao menu. *A tela de loading "NÚCLEO CENTRAL" só aparece quando `scenes/levels/core_hub.tscn` existir ([F28](F28-fase-nucleo-central.md)): hoje o alvo é a cena de prova, que não é fase e por contrato do `SceneManager` usa transição direta.*
- [x] CONTINUAR → `SaveManager.load_game()` → `SceneManager.goto(GameState.checkpoint.scene)`; se o save for inválido, mostra "BACKUP CORROMPIDO" por 2 s e desabilita CONTINUAR.
- [x] OPÇÕES abre a tela de opções por cima; ao fechar, o foco volta ao botão OPÇÕES.
- [x] SAIR fecha o jogo.
- [x] Textos em pt-BR com acentos; nenhuma string de UI dentro de lógica fora da cena/JSON.
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/main_menu.tscn (+ main_menu.gd)
scenes/ui/confirm_dialog.tscn (+ confirm_dialog.gd)
```

### Árvore de `main_menu.tscn`
```
MainMenu (Control, full rect, script main_menu.gd)
├─ Background (Parallax2D ×3 com Sprite2D: space_far / space_mid / space_near via AssetResolver;
│               autoscroll x = -2, -5, -10 px/s)   ou instância de scenes/world/space_parallax.tscn se a F26 já existir
├─ Logo (TextureRect, UI-LOGO 192×48, topo centro, y = 24)
├─ Buttons (VBoxContainer, centro, y ≈ 100, separation 4, largura 120)
│  ├─ ContinueButton (Button, "CONTINUAR")
│  ├─ NewGameButton (Button, "NOVO SISTEMA")
│  ├─ OptionsButton (Button, "OPÇÕES")
│  └─ QuitButton (Button, "SAIR")
├─ Version (Label, canto inferior direito, "DEMO v0.1", cor #56606A)
├─ Toast (Label, centro inferior, oculto)
└─ Overlay (Control, full rect, recebe options_menu/confirm_dialog)
```
`Parallax2D` é nó 2D; dentro de um `Control` use um `CanvasLayer` com `layer = -1` como pai do fundo.

### `main_menu.gd`
- `_ready()`: `AudioManager.play_music(&"menu")`; `ContinueButton.disabled = not SaveManager.has_save()`; foca o primeiro habilitado; conecta `pressed` e `focus_entered` (→ `AudioManager.play_sfx(&"ui_move")`).
- `_on_new_game()`: se `has_save()` abre `confirm_dialog` com texto "O backup atual será apagado. Iniciar um novo sistema?"; confirmado → `SaveManager.delete_save()`, `GameState.new_game()`, `SceneManager.goto("res://scenes/levels/core_hub.tscn")`.
- `_on_continue()`: `if SaveManager.load_game(): SceneManager.goto(GameState.checkpoint.get("scene", "res://scenes/levels/core_hub.tscn"))`.
- `_on_options()`: instancia `res://scenes/ui/options_menu.tscn` em `Overlay`, conecta o sinal `closed` para refocar.
- `_unhandled_input`: `ui_cancel` com overlay aberto fecha o overlay.

### `confirm_dialog.tscn` (reutilizável)
```
ConfirmDialog (Control, full rect, process_mode ALWAYS, script confirm_dialog.gd)
├─ Dim (ColorRect, #000000 alpha 0.6)
└─ Panel (PanelContainer, centro, largura 240)
   └─ VBox
      ├─ Message (Label, autowrap)
      └─ Row (HBoxContainer, centro)
         ├─ YesButton ("SIM")
         └─ NoButton ("NÃO")
```
API: `signal answered(confirmed: bool)`; `func open(message: String, yes_text: String = "SIM", no_text: String = "NÃO") -> void`; foco inicial em NÃO; `ui_cancel` = NÃO; libera-se após responder.

### Autoloads / sinais do EventBus
- Usa `SceneManager`, `AudioManager`, `SaveManager`, `GameState`. Nenhum sinal do EventBus.

### Dados (`data/`)
- Nenhum (textos na cena).

### Input actions / camadas de colisão
- `ui_up`, `ui_down`, `ui_accept`, `ui_cancel` (padrão do Godot, já com teclado e controle).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-LOGO](../ASSETS.md#ui-logo) | Logo | Blocos "ÓRBITA" (F05) |
| [BG-SPACE](../ASSETS.md#bg-space) | Fundo animado | Estrelas/nebulosa geradas (F05) |
| [MUS-MENU](../ASSETS.md#mus-menu) | Ruído de rádio | Drone + ruído (F05) |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `ui_move`, `ui_confirm`, `ui_back` | Beeps (F05) |
| [UI-FONT](../ASSETS.md#ui-font) | Botões | Tema da F05 |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `confirm_dialog.tscn` + `.gd`.
- [x] **Passo 2** — `main_menu.tscn` + `.gd` com fundo parallax e botões.
- [x] **Passo 3** — Se `scenes/levels/core_hub.tscn` ainda não existe, NOVO SISTEMA leva a `res://tests/qa/scenes/loading_target.tscn` da F03 **apenas** via constante `FIRST_LEVEL` no topo do script; trocar para `core_hub` quando a F28 existir (registrar no log).
- [x] **Passo 4** — `tests/scenes.txt` += `main_menu.tscn`, `confirm_dialog.tscn`; roteiros de QA.
- [x] **Passo 5** — Portões; commit `feat(F07): menu principal com continuar, novo sistema, opções e sair`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** lógica trivial; sem suíte própria. (A regra "CONTINUAR habilitado ⇔ `has_save()`" é coberta no QA.)
- **Smoke:** `res://scenes/ui/main_menu.tscn`, `res://scenes/ui/confirm_dialog.tscn`.
- **Roteiro godot-qa:**
  1. `f07_menu.json`, cena `main_menu.tscn`, sem save (apagar `user://save.json` antes): frame 30 screenshot `f07_menu_nosave` (logo no topo, 4 botões, CONTINUAR cinza, foco destacado em NOVO SISTEMA, estrelas); frame 40 `ui_down` press/release; frame 45 screenshot `f07_focus_options` (foco em OPÇÕES); frame 50 `ui_up` ×1; frame 60 `ui_accept`; frame 150 screenshot `f07_new_game_loading` (tela de loading ou a fase).
  2. `f07_confirm.json` com save existente (a skill cria um `user://save.json` mínimo antes): frame 30 screenshot `f07_menu_withsave` (CONTINUAR habilitado e focado); `ui_down`, `ui_accept`; frame 60 screenshot `f07_confirm` (painel "O backup atual será apagado…", foco em NÃO); `ui_cancel`; frame 80 screenshot `f07_confirm_closed` (menu de volta, foco em NOVO SISTEMA).
- **Playtest humano (opcional):** navegar só com o controle e dizer se o foco é sempre visível.

## 11. ADRs locais

### ADR-F07-001 — ARQUIVO fora do menu da Demo
- **Contexto:** o GDD lista ARQUIVO na tela inicial, mas o codex é stretch (F33).
- **Decisão:** o botão não é criado; a F33, se feita, o adiciona entre OPÇÕES e SAIR.
- **Consequências:** nenhum botão "morto" na apresentação. **Data:** 2026-09-19.

### ADR-F07-002 — NOVO SISTEMA apaga o save após confirmação
- **Contexto:** há um único slot de save.
- **Decisão:** confirmação explícita; ao confirmar, `SaveManager.delete_save()` antes de `new_game()`.
- **Consequências:** CONTINUAR nunca aponta para uma run antiga misturada à nova. **Data:** 2026-09-19.

### ADR-F07-003 — `FIRST_LEVEL` resolvido em tempo de execução
- **Contexto:** `scenes/levels/core_hub.tscn` (F28) ainda não existe e o plano previa apontar o botão para a cena de prova por constante, trocando à mão depois.
- **Decisão:** `main_menu.gd` e `pause_menu.gd` têm `FIRST_LEVEL` (core_hub) e `FALLBACK_LEVEL` (`res://tests/qa/scenes/loading_target.tscn`); `_first_level()` devolve o primeiro que `ResourceLoader.exists()`.
- **Consequências:** quando a F28 criar o `core_hub.tscn`, o menu e o pause passam a apontar para a fase **sem edição de código** e a tela de loading "NÚCLEO CENTRAL" aparece sozinha. Enquanto isso, o fallback não é fase e a transição é direta. **Data:** 2026-09-19.

### ADR-F07-004 — Textos longos da UI como `@export` da cena
- **Contexto:** a regra 5 do `/CLAUDE.md` proíbe string de jogador dentro de lógica, mas a pergunta do `confirm_dialog` precisa vir de quem o abre.
- **Decisão:** `main_menu.tscn` e `pause_menu.tscn` guardam as perguntas em propriedades `@export` (`new_game_question`, `corrupted_message`, `restart_question`, `quit_question`) definidas no `.tscn`.
- **Consequências:** o texto vive na cena, o script só o repassa. **Data:** 2026-09-19.

### ADR-F07-005 — Fonte pixel m5x7 em tamanho 16
- **Contexto:** a fonte definitiva (UI-FONT) chegou durante esta feature; o tema usava a fonte padrão do Godot em 10 px (e 8 px na ProgressBar).
- **Decisão:** `assets/ui/theme.tres` recebe `default_font` = `assets/fonts/ui_font.ttf` e **todos** os `font_size` do tema passam a **16** (tamanho nativo da m5x7). Medido: altura de linha 13 px, "SAIR PARA O MENU" = 95 px — cabe nos painéis de 384×216.
- **Consequências:** 8 px não é usado em lugar nenhum do tema (a m5x7 borra fora de múltiplos de 16). `scenes/boot/splash.tscn` e `loading.tscn` já foram alinhados a 16/32 em paralelo. Restam `tests/qa/scenes/input_probe.tscn` e `audio_probe.tscn` (F06) com overrides de 8/10/12 px — cenas só de QA, divergência reportada e não corrigida aqui. **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.8 (tela 1) · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `scenes/ui/main_menu.tscn`/`.gd` e `scenes/ui/confirm_dialog.tscn`/`.gd`. Fundo com três `Parallax2D` (autoscroll −2/−5/−10 px/s) num `CanvasLayer` de `layer = -1`, texturas resolvidas pelo `AssetResolver` (placeholders `space_far/mid/near`); logo `assets/ui/logo.png` com fallback para o rótulo "ÓRBITA"; CONTINUAR desabilitado por `SaveManager.has_save()`; toast "BACKUP CORROMPIDO" (2 s) quando `load_game()` falha; OPÇÕES como sobreposição da F08 com foco de volta no botão; SFX `ui_move`/`ui_confirm`/`ui_back`/`ui_error`; música `&"menu"`.
- **Fonte**: a UI-FONT (m5x7) foi integrada ao `theme.tres` nesta sessão (ADR-F07-005) e a ficha do `ASSETS.md` foi para `integrado`, com crédito no `ASSETS.md` e no `README.md`.
- **Portões**: `--import` limpo · 99 testes (91 antigos + 6 de `test_difficulty_text` + 2 de `test_scene_paths`) · smoke 12/12 · varreduras 3D e de comentários vazias.
- **QA visual** (`tests/qa/f07_menu.json`, janela real, `--qa-scale=3`): `a_menu_foco_inicial` mostra logo, espaço em parallax, CONTINUAR cinza, foco ciano em NOVO SISTEMA e "DEMO v0.1"; `a2_menu_foco_opcoes` confirma a navegação por ↓; `b3_voltou_ao_menu` mostra o foco de volta em OPÇÕES depois de fechar as opções; `a3_novo_sistema` mostra a troca de cena.
- **Próximo passo**: quando a [F28](F28-fase-nucleo-central.md) criar `core_hub.tscn`, conferir que o loading "NÚCLEO CENTRAL" aparece (ADR-F07-003) e marcar o critério que ficou `[~]`.

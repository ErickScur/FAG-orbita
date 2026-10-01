---
id: F03
title: SceneManager, Splash & Loading
status: done
scope: demo
block: 0
priority: P0
rubric: ["Tela de loading / splash screen"]
depends_on: ["F02", "F05"]
unblocks: ["F07", "F09", "F10", "F11"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F03 — SceneManager, Splash & Loading

## 1. Contexto e objetivo

O jogo precisa de uma porta de entrada (splash com o logo) e de transições limpas entre menu e fases (fade + tela de loading com barra). Esta feature implementa o autoload `SceneManager` — **único** caminho de troca de cena do projeto ([`/CLAUDE.md` §4.2](../../CLAUDE.md), regra 7) — e as cenas `scenes/boot/splash.tscn` e `scenes/boot/loading.tscn`.

Serve ao pilar **AUSÊNCIA** ([GDD pilares](../design/GDD.md#gdd-pilares)) pelo tom: tela preta, logo frio, silêncio. O jogador vê o splash ao abrir o jogo e o loading toda vez que entra numa fase.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) · [GDD-2.9 Estilo visual](../design/GDD.md#gdd-2-9-visual) · [GDD-2.9 Paleta](../design/GDD.md#gdd-2-9-paleta) (Núcleo Central: azul frio esverdeado)
- **Parâmetros:** nenhum da GDD-P atual; os tempos de UI são propostos no ADR-F03-001 (seção 11): `Balance.SCENE_FADE_TIME`, `Balance.SPLASH_TIME`, `Balance.LOADING_MIN_TIME`
- **Jornada:** [Ideia principal](../design/JORNADA-DO-HEROI.md#jh-ideia) · [Contexto](../design/JORNADA-DO-HEROI.md#jh-contexto) (subtítulo "Estação Espacial de Pesquisa ARTEMIS")
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) · [ADR-005](../DECISIONS.md#adr-005)

## 3. Critério de avaliação atendido

**Tela de loading / splash screen** ([ENTREGAS §3.1](../ENTREGAS.md#rubrica)): ao abrir o jogo o avaliador vê o splash com o logo ÓRBITA; ao clicar em NOVO SISTEMA/CONTINUAR vê o fade e a tela "CARREGANDO SETOR — NÚCLEO CENTRAL" com barra de progresso e uma dica.

## 4. Escopo

### Inclui
- `SceneManager` completo: fade preto, loading threaded para cenas em `res://scenes/levels/`, bloqueio de chamadas durante transição, despausar a árvore ao trocar.
- `splash.tscn` (substitui o stub da F01): logo, subtítulo, fade-in, pular com qualquer tecla, segue para o menu.
- `loading.tscn`: nome do setor, `ProgressBar`, dica aleatória.
- `data/ui/loading.json` com nomes de setor e dicas.
- `scripts/core/scene_paths.gd` (lógica pura) + teste.

### Não inclui
- Menu principal ([F07](F07-menu-principal.md)) — até lá, o splash segue para `main_menu.tscn` se existir, senão fica parado.
- Pausa ([F09](F09-pause-recomecar.md)) e telas de fim ([F10](F10-telas-fim-de-jogo.md)) — só usam o `SceneManager`.
- Transições temáticas (glitch, varredura CRT) e estação girando no splash — Final.
- Som no splash (a música do menu começa no menu).

## 5. Critérios de aceite

- [x] Abrir o jogo mostra o splash: fundo preto, logo UI-LOGO centralizado com fade-in, subtítulo "ESTAÇÃO ESPACIAL DE PESQUISA ARTEMIS" abaixo.
- [x] Após `Balance.SPLASH_TIME` (ou ao apertar qualquer tecla/botão depois de 0,5 s) o splash faz fade e vai para `res://scenes/ui/main_menu.tscn`.
- [x] `SceneManager.goto("res://scenes/levels/…")` mostra fade-out → `loading.tscn` com `ProgressBar` avançando → fade-in na fase. A tela de loading fica visível no mínimo `Balance.LOADING_MIN_TIME`.
- [x] `SceneManager.goto()` para cenas fora de `res://scenes/levels/` faz só fade-out/fade-in, sem loading.
- [x] Chamar `goto` durante uma transição é ignorado (sem cena dupla); `is_transitioning()` reflete isso.
- [x] Ao trocar de cena, `get_tree().paused` volta a `false`.
- [x] Caminho inexistente: `push_error` com o caminho e a transição é cancelada (fade volta), sem travar.
- [x] Nenhum `get_tree().change_scene_to_*` fora de `scene_manager.gd` (grep) — exceção documentada: `QACapture` ([F06](F06-testes-portoes-qa.md)).
- [ ] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
autoload/scene_manager.gd
scenes/boot/splash.tscn (+ splash.gd)
scenes/boot/loading.tscn (+ loading.gd)
scripts/core/scene_paths.gd      class_name ScenePaths
data/ui/loading.json
```

### `SceneManager` (autoload, `process_mode = PROCESS_MODE_ALWAYS`)
- `_ready()`: cria `CanvasLayer` (`layer = 100`) com `ColorRect` preto full-rect, `mouse_filter = MOUSE_FILTER_IGNORE`, `modulate.a = 0`.
- API pública:
  - `goto(path: String) -> void` — se `ScenePaths.is_level(path)` usa loading, senão troca direta.
  - `goto_with_loading(path: String) -> void` — força a tela de loading (usado em QA).
  - `goto_instant(path: String) -> void` — sem fade/loading (testes).
  - `is_transitioning() -> bool`.
  - `pending_path: String` — lido por `loading.gd`.
  - `finish_loading(packed: PackedScene) -> void` — chamado por `loading.gd`: `change_scene_to_packed` + fade-in.
- Fluxo com loading: `_transitioning = true` → tween do overlay 0→1 em `Balance.SCENE_FADE_TIME` → `get_tree().paused = false` → `change_scene_to_file("res://scenes/boot/loading.tscn")` → fade-in do overlay → `loading.gd` faz `ResourceLoader.load_threaded_request(pending_path)` e em `_process` lê `ResourceLoader.load_threaded_get_status(pending_path, progress)`; `ProgressBar.value = progress[0] * 100`. Quando `THREAD_LOAD_LOADED` e o tempo mínimo passou, fade-out → `SceneManager.finish_loading(ResourceLoader.load_threaded_get(pending_path))` → fade-in → `_transitioning = false`. `THREAD_LOAD_FAILED`/`INVALID_RESOURCE` → `push_error` e volta ao menu.
- Tweens criados com `create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)`.

### `ScenePaths` (lógica pura)
```gdscript
class_name ScenePaths
extends RefCounted

const LEVELS_DIR := "res://scenes/levels/"
const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const LOADING := "res://scenes/boot/loading.tscn"

static func is_level(path: String) -> bool:
	return path.begins_with(LEVELS_DIR) and path.ends_with(".tscn")

static func level_key(path: String) -> String:
	return path.get_file().get_basename()
```

### `splash.tscn`
```
Splash (Control, full rect, script splash.gd)
├─ Background (ColorRect, cor #000000, full rect)
├─ Center (VBoxContainer, anchors center, alignment center, separation 8)
│  ├─ Logo (TextureRect, 192×48, stretch_mode KEEP_CENTERED, texture = AssetResolver.texture("res://assets/ui/logo.png"))
│  └─ Subtitle (Label, "ESTAÇÃO ESPACIAL DE PESQUISA ARTEMIS", horizontal_alignment center, cor #7FD6C8)
└─ Timer (Timer, one_shot, wait_time = Balance.SPLASH_TIME)
```
`splash.gd`: `Center.modulate.a` 0→1 em `Balance.SCENE_FADE_TIME`; `_unhandled_input` aceita `InputEventKey`/`InputEventJoypadButton`/`InputEventMouseButton` pressionado após 0,5 s; `Timer.timeout` ou input → `SceneManager.goto(ScenePaths.MAIN_MENU)` (se o arquivo não existir ainda, não faz nada).

### `loading.tscn`
```
Loading (Control, full rect, script loading.gd)
├─ Background (ColorRect, #05080C)
├─ Title (Label, "CARREGANDO SETOR", topo centro)
├─ SectorName (Label, ex.: "NÚCLEO CENTRAL", abaixo do título, cor #7FD6C8)
├─ Bar (ProgressBar, largura 192, centro, show_percentage false, min 0 max 100)
└─ Tip (Label, autowrap, largura 320, base da tela, cor #8A9BA8)
```

### Dados (`data/ui/loading.json`)
```json
{
  "sector_names": {
    "core_hub": "NÚCLEO CENTRAL",
    "greenhouse": "ESTUFA"
  },
  "tips": [
    "Ligar um sistema desliga outro. Não existe estado em que tudo está ligado.",
    "A lanterna consome Carga. Apague-a quando não precisar enxergar.",
    "Docas de recarga guardam um backup do chassi.",
    "O reator não perde estabilidade enquanto o jogo está pausado.",
    "Cada log lido devolve um pouco de estabilidade ao reator."
  ]
}
```
Chave de setor = `ScenePaths.level_key(pending_path)`; ausente → só "CARREGANDO SETOR".

### Autoloads / sinais do EventBus
- Usa `Balance`, `AssetResolver` ([F05](F05-pipeline-assets-placeholders.md)). Não emite sinais do EventBus.

### Input actions / camadas de colisão
- Nenhuma nova. Splash aceita qualquer tecla/botão.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-LOGO](../ASSETS.md#ui-logo) | Logo no splash | "ÓRBITA" em blocos gerado por `make_placeholders.gd` (192×48) |
| [UI-FONT](../ASSETS.md#ui-font) | Subtítulo, loading | Fonte padrão do Godot via `theme.tres` até a fonte chegar |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `tests/test_scene_paths.gd` (falha) → `scripts/core/scene_paths.gd`.
- [x] **Passo 2** — Adicionar `SCENE_FADE_TIME`, `SPLASH_TIME`, `LOADING_MIN_TIME` à GDD-P + Ajustes (ver ADR-F03-001) e a `balance.gd`.
- [x] **Passo 3** — Preencher `autoload/scene_manager.gd` (overlay, tweens, fluxo com/sem loading).
- [x] **Passo 4** — `loading.tscn` + `loading.gd` + `data/ui/loading.json`.
- [x] **Passo 5** — `splash.tscn` + `splash.gd` sobrescrevendo o stub da F01.
- [x] **Passo 6** — Cena de QA `tests/qa/scenes/loading_probe.tscn` (Node com script que, no `_ready`, chama `SceneManager.goto_with_loading("res://tests/qa/scenes/loading_target.tscn")`; o alvo é um `Node2D` com `Label` "ALVO").
- [ ] **Passo 7** — `tests/scenes.txt` += splash, loading; portões; QA; commit `feat(F03): SceneManager com fade, splash e tela de loading`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** `test_scene_paths.gd` — `is_level("res://scenes/levels/greenhouse.tscn") == true`, `is_level("res://scenes/ui/main_menu.tscn") == false`, `level_key(...) == "greenhouse"`; `data/ui/loading.json` carrega e tem `tips` não vazio.
- **Smoke:** `res://scenes/boot/splash.tscn`, `res://scenes/boot/loading.tscn` (com `pending_path` vazio o loading não pode dar erro: mostra só o título).
- **Roteiro godot-qa:**
  1. `--qa-scene=res://scenes/boot/splash.tscn`, sem inputs. Screenshot frame 5 `f03_splash_start` (quase preto, logo começando a aparecer); frame 60 `f03_splash_full` (logo e subtítulo nítidos, centralizados, sem borrão).
  2. Mesmo roteiro com `{"frame": 40, "action": "ui_accept", "pressed": true}`, `{"frame": 42, "action": "ui_accept", "pressed": false}`; screenshot frame 90 `f03_splash_skip` (menu principal, ou tela preta se F07 ainda não existe — anotar no log).
  3. `--qa-scene=res://tests/qa/scenes/loading_probe.tscn`: screenshot frame 30 `f03_loading` (título "CARREGANDO SETOR", barra visível, dica na base) e frame 150 `f03_loading_done` (Label "ALVO" visível, sem overlay preto).
- **Playtest humano (opcional):** abrir o jogo e dizer se o splash parece "frio e silencioso" e se o tempo é confortável.

## 11. ADRs locais

### ADR-F03-001 — Tempos de transição
- **Contexto:** o GDD não define duração de fade, splash ou tempo mínimo de loading.
- **Decisão:** propor `SCENE_FADE_TIME = 0.4` s, `SPLASH_TIME = 2.5` s, `LOADING_MIN_TIME = 0.6` s. **Adicionar à tabela [GDD-P](../design/GDD.md#gdd-p) (origem "UI / F03") e registrar em [Ajustes](../design/GDD.md#gdd-ajustes) antes de usar**, depois espelhar em `balance.gd`.
- **Consequências:** loading nunca "pisca" em cenas leves; valores ajustáveis num só lugar. **Data:** 2026-09-19.

### ADR-F03-002 — Loading só para fases
- **Contexto:** menus são leves; loading entre menu e opções seria irritante.
- **Decisão:** `goto` usa loading apenas para `res://scenes/levels/*.tscn`; o resto só faz fade.
- **Consequências:** regra centralizada em `ScenePaths.is_level`. **Data:** 2026-09-19.

### ADR-F03-003 — Logo do splash é um `Label` até o `AssetResolver` existir
- **Contexto:** a seção 6 pede `TextureRect` com `AssetResolver.texture("res://assets/ui/logo.png")`, mas a [F05](F05-pipeline-assets-placeholders.md) (que cria o `AssetResolver` e os placeholders) está `not-started` e não há nenhum PNG em `assets/`.
- **Decisão:** o nó `Center/Logo` é um `Label` com o texto "ÓRBITA" (fonte padrão, tamanho 24) no lugar do `TextureRect`. A troca para UI-LOGO é substituir esse nó por um `TextureRect` quando a F05 e o asset existirem.
- **Consequências:** o splash já é apresentável e não bloqueia a F03; fica um TODO visual para a F05. **Data:** 2026-09-19.

### ADR-F03-004 — Janela de input do splash = `Balance.SCENE_FADE_TIME`
- **Contexto:** a seção 6 diz "aceita input depois de 0,5 s", mas 0,5 s não existe na [GDD-P](../design/GDD.md#gdd-p) e a regra do projeto proíbe número solto em script.
- **Decisão:** o splash ignora input enquanto `_elapsed < Balance.SCENE_FADE_TIME` (0,4 s), ou seja, até o fade-in do logo terminar. Nenhuma constante nova foi inventada.
- **Consequências:** comportamento equivalente ao descrito (não dá para pular antes de ver o logo) sem tocar na GDD-P. **Data:** 2026-09-19.

### ADR-F03-005 — `LOADING_MIN_TIME` vale 0,8 s (GDD-P), não 0,6 s
- **Contexto:** o ADR-F03-001 propunha 0,6 s, mas a tabela GDD-P já registra `LOADING_MIN_TIME = 0.8` (origem AJ-006), assim como `SCENE_FADE_TIME = 0.4` e `SPLASH_TIME = 2.5`.
- **Decisão:** o código espelha a GDD-P (0,8 s). Nenhuma alteração foi feita no GDD.
- **Consequências:** o Passo 2 do plano já estava cumprido antes desta feature começar. **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.8 e do contrato do SceneManager · **Próximo passo**: implementação.

### 2026-09-19 — Implementação
- **Quem**: agente de implementação (Claude) · **O que**: `scripts/core/scene_paths.gd` (`is_level`, `level_key`, caminhos canônicos), `autoload/scene_manager.gd` completo (overlay `CanvasLayer` 100 + `ColorRect` preto, `process_mode = ALWAYS`, tweens com `TWEEN_PAUSE_PROCESS`, `goto`/`goto_with_loading`/`goto_instant`/`is_transitioning`/`finish_loading`/`abort_loading`, despausa a árvore em toda troca, `push_error` e cancelamento em caminho inexistente), `scenes/boot/loading.tscn` + `loading.gd` (carregamento threaded, `ProgressBar` 0..100, nome do setor e dica de `data/ui/loading.json`), `scenes/boot/splash.tscn` + `splash.gd` substituindo o stub da F01, `data/ui/loading.json`, cenas-sonda `tests/qa/scenes/loading_probe.tscn` e `loading_target.tscn`, `tests/scenes.txt` e `tests/test_scene_paths.gd`.
- **Decisões**: ADR-F03-003 (logo como `Label` até a F05), ADR-F03-004 (janela de input do splash = `SCENE_FADE_TIME`), ADR-F03-005 (`LOADING_MIN_TIME` = 0,8 s da GDD-P).
- **Validação**: `--import` e `--path .` limpos; cada cena nova carregada headless por 180 frames sem erro; um script `SceneTree` temporário (removido) dirigiu o `SceneManager` e confirmou a sequência `splash → loading → alvo` com `is_transitioning()` correto, `goto` durante transição ignorado, `paused` de volta a `false` e `push_error` sem travamento em caminho inválido; a transição direta (fora de `scenes/levels/`) não passa pelo loading. Screenshots do splash e do loading capturadas e conferidas (texto centralizado, acentos corretos, barra e dica visíveis).
- **Pendente**: o roteiro `godot-qa` da seção 10 depende do `QACapture` da F06; o logo definitivo (UI-LOGO) depende da F05; `main_menu.tscn` (F07) ainda não existe, então o splash apenas não avança ao terminar o tempo — o caminho de troca já está implementado.
- **Próximo passo**: F06 (QA por screenshot e portões) e F07 (menu principal) para fechar o fluxo do splash.

### 2026-09-19 — Redesenho do boot (retorno do playtest)
- **Quem**: agente (feature-loop Dia 1), após o usuário apontar que a tela de carregamento ficava feia na resolução grande.
- **O que foi feito**: (1) causa raiz da tipografia borrada — a m5x7 só é nítida em múltiplos de 16 e as telas usavam 8/12/24; padronizado 16/32 e `keep_rounding_remainders=false` no `.import` (regra agora no `/CLAUDE.md` §5 e nos portões). (2) `loading.tscn` redesenhado na linguagem do menu: fundo estelar, painel com moldura ciana, barra emoldurada e **quatro linhas de status da estação** (`[OK] SUPORTE DE VIDA`, `SENSORES INTERNOS`, `DISTRIBUIÇÃO DE ENERGIA`, `MAPA DO SETOR`) que acendem conforme o progresso — a estação religando sistema por sistema, coerente com a Jornada etapa 1. (3) `LOADING_MIN_TIME` 0,8 → 1,6 s ([AJ-017](../design/GDD.md#gdd-ajustes)), porque em 0,8 s ninguém lê a tela.
- **Decisões**: as linhas acendem pelo **menor** valor entre progresso real e tempo decorrido, para nunca mentirem sobre o carregamento.
- **Próximo passo**: quando a F28 criar `scenes/levels/core_hub.tscn`, verificar a tela com carregamento real (hoje só cenas de `scenes/levels/` passam pela tela de loading).


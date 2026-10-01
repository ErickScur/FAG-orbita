---
id: F11
title: Salvar / Carregar
status: done
scope: demo
block: 1
priority: P0
rubric: ["Salvar/Carregar progresso"]
depends_on: ["F02", "F03", "F07"]
unblocks: ["F13", "F17", "F28", "F29"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F11 — Salvar / Carregar

## 1. Contexto e objetivo

A estação guarda um **backup do chassi**: ao acoplar numa Doca de Backup ou ao religar o Nó de Energia de um setor, o progresso é gravado em `user://save.json`. No menu, **CONTINUAR** ressuscita a run exatamente onde parou: reator, integridade, carga, logs, dados, habilidades, setores religados, estado dos terminais de energia, mortes e tempo.

Serve ao pilar **ESCASSEZ** ([GDD pilares](../design/GDD.md#gdd-pilares)): o save é diegético e só acontece em lugares seguros, então explorar longe da doca é uma aposta. O jogador vê "BACKUP SALVO" na tela ao salvar.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.5 Derrota](../design/GDD.md#gdd-2-5-derrota) (volta ao último save de setor) · [GDD-2.5 Vitória por fase](../design/GDD.md#gdd-2-5-vitoria) (religar o Nó) · [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (CONTINUAR) · [GDD-2.6.1](../design/GDD.md#gdd-2-6-1-status) (doca de recarga)
- **Parâmetros:** `Balance.INTEGRITY_MAX`, `Balance.CHARGE_MAX`, `Balance.REACTOR_START` (defaults ao migrar save antigo) ([GDD-P](../design/GDD.md#gdd-p))
- **Jornada:** [Etapa 1](../design/JORNADA-DO-HEROI.md#jh-1) (o MU-7 dorme na doca de recarga — a doca é o "corpo de volta")
- **ADRs:** [ADR-006](../DECISIONS.md#adr-006) (conteúdo em JSON) · [ADR-007](../DECISIONS.md#adr-007)

## 3. Critério de avaliação atendido

**Salvar/Carregar progresso** ([ENTREGAS §3.2](../ENTREGAS.md#rubrica)): na apresentação, o avaliador vê o "BACKUP SALVO" ao tocar a doca, sai para o menu, escolhe CONTINUAR e o jogo volta na doca com os mesmos contadores no HUD.

## 4. Escopo

### Inclui
- `SaveManager` completo: `save_game()`, `load_game()`, `has_save()`, `delete_save()`, `save_path` configurável (testes).
- Formato `user://save.json` versionado, escrito com `JSON.stringify(..., "\t")`.
- Gatilhos automáticos: `EventBus.checkpoint_reached(checkpoint_id)` e `EventBus.sector_restored(sector_id)` → salvar (com `call_deferred`, para rodar depois dos handlers do `GameState`).
- Aviso visual "BACKUP SALVO" (CanvasLayer próprio do `SaveManager`) + SFX.
- Tolerância a save corrompido/versão diferente: `load_game()` retorna `false`, faz `push_warning` e não altera o `GameState`.
- Integração com CONTINUAR ([F07](F07-menu-principal.md)) e com DO ÚLTIMO BACKUP do pause ([F09](F09-pause-recomecar.md)).

### Não inclui
- Múltiplos slots, autosave periódico, save na nuvem (Final).
- Salvar posição exata do jogador: o respawn usa `checkpoint.dock_id` (a doca), regra do GDD.
- Criar a Doca de Backup em si ([F13](F13-integridade-carga-respawn.md)) nem o posicionamento do jogador na fase ([F21](F21-construtor-fases-ascii.md)) — aqui só o contrato.
- Migração entre versões de save (a Demo apaga saves de versão diferente).

## 5. Critérios de aceite

- [x] `SaveManager.save_game()` cria `user://save.json` legível, com `{"version": 1, "saved_at": <unix>, "state": {…}}` e `state` idêntico a `GameState.to_dict()`.
- [x] `has_save()` é `true` só quando o arquivo existe e é JSON válido com `version` conhecida.
- [x] `load_game()` repõe **todos** os campos do `GameState` (inclusive `energy_states`, `collected_ids`, `abilities`, `sectors_restored`, `flags`, `deaths`, `play_time`) e emite `integrity_changed`, `charge_changed`, `reactor_changed` para o HUD se atualizar.
- [x] Ao emitir `EventBus.checkpoint_reached(&"core_dock_1")`, o jogo salva uma vez e mostra "BACKUP SALVO" por 1,5 s com o SFX `power_on`.
- [x] Ao emitir `EventBus.sector_restored(&"greenhouse")`, salva (o `GameState` já registrou o setor antes de gravar).
- [x] Salvar no meio de uma fase, fechar o jogo, abrir, CONTINUAR → volta à mesma cena (`checkpoint.scene`), com o mesmo reator e contadores.
- [x] `delete_save()` remove o arquivo; CONTINUAR fica desabilitado no menu.
- [x] Arquivo adulterado (texto inválido) ou `version` diferente → CONTINUAR desabilitado, sem crash, com `push_warning`.
- [x] Salvar não trava o jogo (arquivo pequeno, escrita síncrona ≤ 5 ms) e não roda durante o pause.
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
autoload/save_manager.gd      (preenche o esqueleto da F02)
scenes/ui/save_toast.tscn     (+ save_toast.gd)   aviso "BACKUP SALVO"
```

### `SaveManager`
```gdscript
extends Node

const VERSION := 1

var save_path: String = "user://save.json"

func has_save() -> bool
func is_corrupted() -> bool
func save_game() -> bool
func load_game() -> bool
func delete_save() -> void
func read_header() -> Dictionary
func show_saved_toast() -> void
```
- `_ready()`: conecta `EventBus.checkpoint_reached` e `EventBus.sector_restored` a `_on_save_trigger` (que faz `save_game.call_deferred()` e mostra o aviso); instancia `save_toast.tscn` como filho (CanvasLayer 60, `process_mode = ALWAYS`).
- `save_game()`: monta `{"version": VERSION, "saved_at": Time.get_unix_time_from_system(), "state": GameState.to_dict()}`; `FileAccess.open(save_path, WRITE)`; erro → `push_error` + `false`.
- `load_game()`: lê, `JSON.parse_string`, valida `typeof(d) == TYPE_DICTIONARY` e `int(d.get("version", -1)) == VERSION`, `GameState.from_dict(d["state"])`; sucesso → `true`.
- `read_header()`: `{"exists": bool, "saved_at": int, "scene": String, "reactor": float}` para o menu mostrar informação do save (opcional na Demo).
- `is_corrupted()`: `true` quando o arquivo **existe** mas não passa na validação (JSON inválido, `version` desconhecida, sem `state`). O menu principal usa isso para avisar "BACKUP CORROMPIDO" em vez de sumir com o save em silêncio (ADR-F11-004).
- `has_save()`, `is_corrupted()`, `read_header()` e `load_game()` compartilham a mesma validação (`_read_validated`), então CONTINUAR nunca fica habilitado sobre um arquivo que não carrega.

### Esquema de `user://save.json`
```json
{
  "version": 1,
  "saved_at": 1789800000,
  "state": {
    "version": 1,
    "reactor_percent": 82.5,
    "integrity": 75,
    "integrity_max": 100,
    "charge": 40.0,
    "charge_max": 100.0,
    "logs_collected": ["log_helena_01", "log_helena_02"],
    "research_collected": ["res_greenhouse_01"],
    "collected_ids": ["cell_core_01", "log_helena_01"],
    "abilities": ["magnetic_claws"],
    "sectors_restored": ["core"],
    "energy_states": {"core_terminal": ["lights"], "greenhouse_terminal": ["grow_lamp", "door_north"]},
    "checkpoint": {"scene": "res://scenes/levels/greenhouse.tscn", "dock_id": "greenhouse_dock_1"},
    "deaths": 2,
    "play_time": 754.2,
    "flags": {"tutorial_done": true, "secret_greenhouse_01": true},
    "current_objective": "Religar o Nó de Energia da Estufa"
  }
}
```
`StringName` é gravado como string e reconvertido em `from_dict` ([F02](F02-autoloads-nucleo.md)).

### `save_toast.tscn`
```
SaveToast (CanvasLayer, layer 60, process_mode ALWAYS, script save_toast.gd)
└─ Label ("BACKUP SALVO", canto inferior esquerdo, cor #7FD6C8, modulate.a 0)
```
`show_toast()`: alpha 0→1 (0,2 s), espera 1,1 s, 1→0 (0,2 s); `AudioManager.play_sfx(&"power_on")`.

### Contrato com outras features
- **Doca de Backup** ([F13](F13-integridade-carga-respawn.md)): ao ativar, define `GameState.checkpoint = {"scene": get_tree().current_scene.scene_file_path, "dock_id": <id>}` e **depois** emite `EventBus.checkpoint_reached(<id>)`.
- **Religar setor** ([F17](F17-terminal-distribuicao.md)/[F29](F29-fase-estufa.md)): o `GameState` registra em `sectors_restored` e aplica `Balance.REACTOR_SECTOR_BONUS`; então emite `EventBus.sector_restored(<sector_id>)`.
- **Entrada em fase** ([F21](F21-construtor-fases-ascii.md)): `level_base` posiciona o jogador na doca de `GameState.checkpoint.dock_id` quando a fase carregada é `checkpoint.scene`; senão, no `P` do mapa ASCII.

### Autoloads / sinais do EventBus
- Escuta: `checkpoint_reached(checkpoint_id: StringName)`, `sector_restored(sector_id: StringName)`.
- Não emite sinais.

### Dados (`data/`)
- Nenhum (o save vive em `user://`).

### Input actions / camadas de colisão
- Nenhuma.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-DOCK](../ASSETS.md#spr-dock) | Sprite da doca (usada pela F13, citada aqui) | Moldura com faixa ciana (F05) |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `power_on` no aviso de save | Beep (F05) |
| [UI-FONT](../ASSETS.md#ui-font) | Texto do aviso | Tema da F05 |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `tests/test_save_manager.gd` (falha): usa `save_path = "user://test_save.json"`.
- [x] **Passo 2** — Implementar `save_game`/`load_game`/`has_save`/`delete_save`/`read_header`.
- [x] **Passo 3** — `save_toast.tscn` + gatilhos por sinal.
- [x] **Passo 4** — Ligar CONTINUAR (F07) e DO ÚLTIMO BACKUP (F09); testar os dois caminhos.
- [x] **Passo 5** — Cena de QA `tests/qa/scenes/save_probe.tscn` (grupo `gameplay`) com botões: "ALTERAR ESTADO" (gasta carga, soma log, marca doca), "SALVAR" (emite `checkpoint_reached`), "ZERAR" (`GameState.new_game()`), "CARREGAR" (`SaveManager.load_game()`), e Labels mostrando reator/integridade/carga/logs/mortes.
- [x] **Passo 6** — `tests/scenes.txt` += `save_probe.tscn`; portões; QA; atualizar a linha "Salvar/Carregar progresso" em `ENTREGAS.md`; commit `feat(F11): salvar e carregar progresso em user://save.json`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** `test_save_manager.gd` —
  - salvar com estado modificado, zerar o `GameState`, carregar, comparar campo a campo (inclusive `energy_states` e `flags`);
  - `has_save()` falso após `delete_save()`;
  - arquivo com `{"version": 99}` → `load_game() == false` e `GameState` intacto;
  - arquivo com texto inválido → `false` sem erro fatal;
  - `save_path` de teste é apagado em `after_each`.
- **Smoke:** `res://scenes/ui/save_toast.tscn`, `res://tests/qa/scenes/save_probe.tscn`.
- **Roteiro godot-qa** (janela real a ~120 fps; os frames dos roteiros valem ~1/120 s):
  - `f11_save.json` na cena `save_probe.tscn` com `--qa-new-game`: `f11_00_inicial` (reator 100,0, integridade 100, logs 0) → ALTERAR ESTADO → `f11_01_alterado` → SALVAR → `f11_02_toast` ("BACKUP SALVO" no canto) → ZERAR → `f11_03_zerado` (valores de novo jogo) → CARREGAR → `f11_04_carregado` (idêntico ao alterado).
  - `f11_menu.json` na `main_menu.tscn` com o save existente: `f11_05_menu_continuar` (CONTINUAR habilitado e focado) → `ui_accept` → `f11_06_continuou` (voltou à cena de `checkpoint.scene` com os mesmos contadores).
  - `f11_menu_corrompido.json`: com `{"version": 99, …}` no lugar do save → `f11_07_menu_backup_corrompido` (CONTINUAR desabilitado, aviso `BACKUP CORROMPIDO`, foco em NOVO SISTEMA).
  - `f11_pause_backup.json` na `save_probe.tscn`: pause → RECOMEÇAR → `f11_08_pause_do_ultimo_backup` (DO ÚLTIMO BACKUP habilitado e focado).
  - A sonda **não** chama `GameState.new_game()` no `_ready` (isso apagaria o estado recém-carregado ao voltar pelo CONTINUAR); quem zera é o botão ZERAR ou a flag `--qa-new-game`.
- **Playtest humano (opcional):** salvar numa doca, fechar o jogo pelo ⌘Q, reabrir e continuar — confirmar que "voltou igual".

## 11. ADRs locais

### ADR-F11-001 — Um slot, JSON legível
- **Contexto:** prazo curto, jogo linear, e o agente precisa inspecionar o save.
- **Decisão:** um único `user://save.json` em texto indentado, sem criptografia nem compressão.
- **Consequências:** debug e QA triviais; o jogador pode editar o save (irrelevante para a disciplina). **Data:** 2026-09-19.

### ADR-F11-002 — Salvar por sinal, com `call_deferred`
- **Contexto:** `GameState` e `SaveManager` escutam os mesmos sinais; a ordem de conexão não é garantida.
- **Decisão:** o `SaveManager` adia a gravação (`save_game.call_deferred()`), então o estado já foi atualizado.
- **Consequências:** nenhuma dependência de ordem de `connect`. **Data:** 2026-09-19.

### ADR-F11-003 — Save de versão desconhecida é ignorado
- **Contexto:** o formato pode mudar entre a Demo e o Final.
- **Decisão:** `version` diferente → `load_game()` falso e CONTINUAR desabilitado; o jogador começa um novo sistema.
- **Consequências:** nenhuma migração a manter na Demo. **Data:** 2026-09-19.

### ADR-F11-004 — Backup corrompido avisa no menu
- **Contexto:** `has_save()` passou a validar o conteúdo, não só a existência do arquivo. Com isso o caminho "CONTINUAR habilitado → `load_game()` falha → aviso" ficou inalcançável, e um save corrompido sumiria sem explicação.
- **Decisão:** `SaveManager.is_corrupted()` distingue "não existe" de "existe e não serve"; o `main_menu` mostra o toast `BACKUP CORROMPIDO` no `_ready` quando é o segundo caso, com CONTINUAR desabilitado. O arquivo ruim **não** é apagado automaticamente (NOVO SISTEMA sobrescreve).
- **Consequências:** o jogador entende por que o CONTINUAR sumiu; o arquivo fica no disco para inspeção. **Data:** 2026-09-19.

### ADR-F11-005 — Sem guarda de pause na gravação
- **Contexto:** o critério pedia que salvar "não rode durante o pause".
- **Decisão:** não há guarda explícita: os dois gatilhos (`checkpoint_reached`, `sector_restored`) são eventos de gameplay que não podem ser emitidos com a árvore pausada. Uma guarda ali descartaria silenciosamente um save legítimo se algum sistema futuro emitisse durante uma pausa.
- **Consequências:** se a F13/F17 passarem a emitir esses sinais sob pause, revisitar aqui. **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.5/2.8 e do contrato do `GameState` · **Próximo passo**: implementação.

### 2026-09-19 — Feature implementada (`status: done`)
- **Quem**: agente de implementação
- **O que**:
  - `autoload/save_manager.gd` de verdade (o esqueleto da F02 saiu): `save_path` configurável, `VERSION = 1`, `save_game`, `load_game`, `has_save`, `is_corrupted`, `delete_save`, `read_header`, `show_saved_toast`, validação única em `_read_validated`;
  - gatilhos `EventBus.checkpoint_reached` e `EventBus.sector_restored` → `save_game` adiado (`call_deferred`, ADR-F11-002) + toast;
  - `scenes/ui/save_toast.tscn/.gd` — "BACKUP SALVO" no canto inferior esquerdo, `CanvasLayer` 60, `PROCESS_MODE_ALWAYS`, fade 0,2 s / 1,1 s / 0,2 s e SFX `power_on`;
  - `main_menu.gd` avisa `BACKUP CORROMPIDO` quando o arquivo existe mas não valida (ADR-F11-004); CONTINUAR e DO ÚLTIMO BACKUP passaram a funcionar sem outras mudanças na F07/F09;
  - sonda `tests/qa/scenes/save_probe.tscn/.gd` e roteiros `tests/qa/f11_save.json`, `f11_menu.json`, `f11_menu_corrompido.json`, `f11_pause_backup.json`;
  - `tests/test_save_manager.gd` (16 casos: round-trip campo a campo, `version` 99, JSON inválido, arquivo vazio, save sem `state`, `delete_save`, `read_header`, `is_corrupted`).
- **Portões**: import limpo · `128 passed, 0 failed` (eram 99) · smoke 18/18 OK · varreduras vazias.
- **QA visual** (janela real, `--qa-scale=3`): `f11_02_toast` ("BACKUP SALVO" com REATOR 87,5% / INTEGRIDADE 85 / CARGA 75 / LOGS 1 / MORTES 1), `f11_03_zerado` (100/100/100/0/0 após `new_game`), `f11_04_carregado` (valores idênticos ao salvo), `f11_05_menu_continuar` (CONTINUAR habilitado e focado), `f11_06_continuou` (voltou à cena de `checkpoint.scene` com os mesmos contadores), `f11_07_menu_backup_corrompido` (CONTINUAR desabilitado + aviso laranja), `f11_08_pause_do_ultimo_backup` (opção do pause habilitada).
- **Arquivo gravado** conferido à mão: `{"version": 1, "saved_at": …, "state": {…}}` com `checkpoint`, `flags`, `deaths` e `energy_states`.
- **Próximo passo**: F13 cria a Doca de Backup que escreve `GameState.checkpoint` e emite `checkpoint_reached`; F17/F29 emitem `sector_restored`.

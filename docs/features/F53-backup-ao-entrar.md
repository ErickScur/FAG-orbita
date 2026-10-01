---
id: F53
title: Backup automático ao entrar numa fase
status: done
scope: demo
block: 6
priority: P0
rubric: ["Salvar/Carregar progresso"]
depends_on: ["F11", "F13", "F21"]
unblocks: []
estimate: 1h
last_updated: 2026-09-20
---

# F53 — Backup automático ao entrar numa fase

## 1. Contexto e objetivo

O checkpoint só existia quando o MU-7 **encostava** numa Doca de Backup ([F11](F11-salvar-carregar.md),
[F13](F13-integridade-carga-respawn.md)). Só que as duas fases nascem o jogador **ao lado** da doca,
não dentro dela: no Núcleo Central o `P` está 3 tiles à direita de `core_dock_01`, na Estufa 2 tiles
à direita de `gh_dock_01`. Quem entra na Estufa e segue em frente — o movimento natural — **nunca**
registra a doca de entrada.

Consequência observada pelo humano: entrar na Estufa, morrer antes de tocar a doca e o jogo tratar
o Núcleo como último backup. O CONTINUAR do menu, o DO ÚLTIMO BACKUP da pausa e o FIM DE JOGO por
reator zerado mandavam todos de volta para a **fase anterior**; e o respawn dentro da Estufa caía
num `fallback` arbitrário (a primeira doca que aparecesse no grupo `backup_dock`, que tanto podia
ser a `gh_dock_01` quanto a `gh_dock_02` no meio da fase). Parecia bug, e era injusto: ninguém
espera ter de **andar para trás** para o jogo começar a proteger o progresso.

Esta feature grava o backup **ao carregar a fase**, na doca de entrada, como se o jogador já
tivesse acoplado nela.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.5 Derrota](../design/GDD.md#gdd-2-5-derrota) (volta ao último backup de setor) ·
  [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (CONTINUAR)
- **Jornada:** [Etapa 1](../design/JORNADA-DO-HEROI.md#jh-1) — a doca é "o corpo de volta"; chegar a
  um setor novo **é** chegar à doca daquele setor.
- **Parâmetros:** nenhum novo (nada de número novo no `Balance`).
- **ADRs:** [ADR-F11-002](F11-salvar-carregar.md#adr-f11-002) · [ADR-F13-008](F13-integridade-carga-respawn.md#adr-f13-008)

## 3. Critério de avaliação atendido

**Salvar/Carregar progresso** ([ENTREGAS §3.2](../ENTREGAS.md#rubrica)): o avaliador entra na Estufa,
morre sem andar e reaparece **na Estufa**; se sair para o menu e escolher CONTINUAR, o jogo carrega a
**Estufa**, não o Núcleo.

## 4. Escopo

### Inclui
- `GameState.register_entry_checkpoint(scene_path, dock_id) -> bool` — regra pura de não-rebaixamento.
- `level_base.gd`: encontra a doca de entrada (a mais próxima do `P` da fase) e registra o checkpoint
  no fim do `_ready()`; quando o checkpoint muda, chama `SaveManager.save_game()`.
- `tests/test_game_state_checkpoint.gd` (6 casos).
- Roteiros `tests/qa/f53_entrada_estufa.json`, `f53_continuar.json`, `f53_portal_saida.json`,
  `f53_porta_comum.json` e a sonda `tests/qa/scenes/f53_probe_exit.tscn`.
- Evento `call` no `QACapture` (previsto pela skill `godot-qa`, faltava implementar) — necessário para
  matar o MU-7 no roteiro sem andar até um perigo.

### Não inclui
- Campo novo no JSON da fase (ADR-F53-002).
- Mudança no `backup_dock.gd` / no aviso `BACKUP SALVO` (ADR-F53-003).
- Mudança na posição de nascimento do jogador: o `P` do ASCII continua mandando (ADR-F53-004).

## 5. Critérios de aceite

- [x] Ao carregar uma fase sem checkpoint nenhum, o checkpoint passa a ser `{scene, dock_id}` da doca
      mais próxima do ponto de nascimento, e `user://save.json` é escrito.
- [x] Ao entrar numa fase vindo de **outra** fase, o checkpoint muda para a doca de entrada da fase nova.
- [x] Ao recarregar uma fase cujo checkpoint **já é dela** (CONTINUAR, DO ÚLTIMO BACKUP, ir e voltar
      entre setores), o checkpoint é preservado — nunca rebaixa da `gh_dock_02` para a `gh_dock_01`.
- [x] Fase sem doca nenhuma não grava nada (nem checkpoint, nem arquivo).
- [x] O salvamento automático **não** mostra o aviso `BACKUP SALVO` nem toca `power_on`.
- [x] Morrer logo ao entrar na Estufa reaparece na Estufa, na `gh_dock_01`.
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### `GameState` (extensão do contrato do CLAUDE.md §4.3)
```gdscript
func register_entry_checkpoint(scene_path: String, dock_id: String) -> bool
```
- `scene_path` ou `dock_id` vazios → `false`, nada muda.
- `checkpoint.scene` **já é** `scene_path` → `false`, nada muda (regra de não-rebaixamento).
- Caso contrário grava `{"scene": scene_path, "dock_id": dock_id}` e devolve `true`.

É lógica pura de dicionário, sem nó e sem `get_tree()`, então a suíte headless cobre a regra inteira.

### `level_base.gd`
```gdscript
const DOCK_GROUP: StringName = &"backup_dock"

func _register_entry_checkpoint() -> void   # último passo do _ready()
func _entry_dock() -> BackupDock            # doca mais próxima de start_position()
```
- `_entry_dock()` percorre o grupo `backup_dock`, ignora quem não for descendente desta fase (sondas
  de QA montam a fase dentro de outra cena) e devolve a doca de menor distância ao `start_position()`
  — o `P` do ASCII, não a posição de respawn.
- `_register_entry_checkpoint()` roda **depois** de `_spawn_player()`, então não muda onde o jogador
  nasce; e só chama `SaveManager.save_game()` quando `register_entry_checkpoint` devolveu `true`.

### Autoloads / sinais do EventBus
- Nenhum sinal novo. O salvamento automático **não** emite `checkpoint_reached` (ADR-F53-003).
- Usa: `GameState.register_entry_checkpoint`, `SaveManager.save_game`.

### Dados (`data/`)
- Nenhum arquivo novo e nenhum campo novo (ADR-F53-002).

## 7. Assets necessários

Nenhum.

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `tests/test_game_state_checkpoint.gd` (regra de não-rebaixamento).
- [x] **Passo 2** — `GameState.register_entry_checkpoint`.
- [x] **Passo 3** — `_entry_dock()` + `_register_entry_checkpoint()` no `level_base.gd`.
- [x] **Passo 4** — Evento `call` no `QACapture` (matar o MU-7 pelo roteiro).
- [x] **Passo 5** — Roteiros de QA + portões.

## 10. Verificação

- **Testes (`tests/test_game_state_checkpoint.gd`):** grava quando não há checkpoint; grava ao trocar
  de fase; **não** regrava na mesma fase (preserva `gh_dock_02`); ignora cena vazia; ignora fase sem
  doca; `new_game()` limpa.
- **Smoke:** `tools/smoke.sh` (77 cenas) — inclui `core_hub.tscn` e `greenhouse.tscn`, que agora
  gravam o backup ao carregar.
- **Roteiros godot-qa** (`--fixed-fps 60`, `--qa-screen=1`, `user://save.json` apagado antes de cada
  execução):
  - `f53_entrada_estufa.json` na `greenhouse.tscn` com `--qa-new-game` — entra, pula a fala, **não
    anda**, morre por `{"call": "GameState.apply_damage", "args": [999]}` e reaparece.
  - `f53_continuar.json` na `main_menu.tscn` **sem** `--qa-new-game`, usando o save deixado pelo
    roteiro anterior — CONTINUAR tem de carregar a Estufa.
  - `f53_portal_saida.json` / `f53_porta_comum.json` (`--qa-scale=3`) — portal de saída e porta comum
    lado a lado.
- **Playtest humano:** entrar na Estufa e morrer de propósito antes de andar.

## 11. ADRs locais

### ADR-F53-001 — A fase nunca rebaixa um checkpoint dela mesma
- **Contexto:** a Demo já prevê ir e voltar entre setores. Se entrar numa fase sempre regravasse a
  doca de entrada, voltar ao Núcleo e retornar à Estufa jogaria o jogador de volta à `gh_dock_01`
  mesmo que ele já tivesse acoplado na `gh_dock_02`, lá no meio da fase.
- **Decisão:** `register_entry_checkpoint` só grava quando `checkpoint.scene` **é de outra fase** (ou
  está vazio). O checkpoint dentro da fase atual é sempre mais recente e mais avançado que a entrada
  dela — quem manda é a doca, não o carregamento.
- **Consequências:** a regra é "checkpoint de entrada só para fase que você não tem"; progresso
  registrado (logs, dados, energia, setores) nunca é tocado, porque o que se grava é só `{scene,
  dock_id}` — o resto do `GameState` já é o estado corrente. **Data:** 2026-09-20.

### ADR-F53-002 — A doca de entrada é a mais próxima do `P`, sem campo novo no JSON
- **Contexto:** uma fase pode ter mais de uma doca (o Núcleo tem `core_dock_01` e `hab_dock_01`; a
  Estufa tem `gh_dock_01` e `gh_dock_02`). Precisávamos saber qual é "a de entrada".
- **Decisão:** derivar do dado que já existe — a doca de menor distância ao ponto de nascimento (`P`
  do ASCII, `start_position()`). Nas duas fases da Demo isso dá exatamente a doca que o jogador vê ao
  chegar (`core_dock_01` a 3 tiles, `gh_dock_01` a 2 tiles).
- **Consequências:** nenhum campo novo em `data/levels/*.json` para manter em sincronia, e fases
  futuras ganham o comportamento de graça. Se algum dia uma fase nascer o jogador longe da doca de
  entrada **de propósito**, aí sim vale um campo `entry_dock` no JSON — registrar aqui quando
  acontecer. **Data:** 2026-09-20.

### ADR-F53-003 — O salvamento de entrada é silencioso
- **Contexto:** o gatilho existente (`EventBus.checkpoint_reached`) faz o `SaveManager` gravar **e**
  mostrar `BACKUP SALVO` com o SFX `power_on`.
- **Decisão:** o `level_base` chama `SaveManager.save_game()` direto, sem emitir `checkpoint_reached`.
  Sem aviso e sem som.
- **Motivo:** (1) o instante da entrada já está lotado — fade de loading, fala de abertura da ÓRBITA,
  banner de OBJETIVO ATUALIZADO, cutscene de setor; um toast por cima disputa atenção no pior momento
  possível; (2) `BACKUP SALVO` é a resposta a uma **ação** do jogador (acoplar na doca) e é assim que
  ele aprende para que serve a doca — disparar o mesmo aviso em todo carregamento de fase o esvazia e
  vira ruído; (3) o feedback que resolve a queixa não é o aviso, é o jogo não mandar mais o jogador
  para a fase anterior. Quem acoplar na doca continua vendo o aviso normalmente.
- **Consequências:** o gatilho por sinal fica exclusivo da doca (o [ADR-F11-002](F11-salvar-carregar.md#adr-f11-002)
  segue valendo para ela). **Data:** 2026-09-20.

### ADR-F53-004 — Registrar depois de nascer, não antes
- **Contexto:** `level_base.spawn_position()` usa a doca do checkpoint quando ele é desta fase. Se o
  registro rodasse **antes** de `_spawn_player()`, o jogador passaria a nascer **dentro** da doca em
  vez do `P` autoral, mudando o enquadramento de chegada das duas fases e o `start_position()` que a
  cutscene de setor usa.
- **Decisão:** `_register_entry_checkpoint()` é o último passo do `_ready()`, depois de `_spawn_player()`
  e de `_apply_progress()`.
- **Consequências:** entrar numa fase não muda nada do que se vê; só o backup muda. **Data:** 2026-09-20.

### ADR-F53-005 — NOVO SISTEMA passa a sobrescrever o save na hora
- **Contexto:** com o backup de entrada, carregar o `core_hub.tscn` grava `user://save.json` logo no
  `_ready()`. Antes, um save antigo sobrevivia até o jogador tocar a primeira doca.
- **Decisão:** aceitar. O jogo tem **um slot** ([ADR-F11-001](F11-salvar-carregar.md#adr-f11-001)) e
  NOVO SISTEMA já pede confirmação antes de começar do zero; a diferença é de segundos.
- **Consequências:** rodar `tools/smoke.sh` ou um roteiro de QA que carregue uma fase **também**
  sobrescreve o `user://save.json` da máquina — quem estiver jogando deve guardar uma cópia antes de
  rodar os portões. **Data:** 2026-09-20.

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-20 — Feature criada e implementada (`status: done`)
- **Quem**: agente SAVE.
- **O que**: `GameState.register_entry_checkpoint` (regra de não-rebaixamento), `_entry_dock()` e
  `_register_entry_checkpoint()` no `level_base.gd`, evento `call` no `QACapture`, suíte
  `tests/test_game_state_checkpoint.gd` e quatro roteiros de QA.
- **Portões**: import limpo · **681 testes passando, 0 falhas** · smoke 77/77 cenas · varreduras 3D e
  de comentário vazias.
- **QA visual** (capturas lidas pelo agente, `--fixed-fps 60`, save apagado antes de cada execução):
  - `f53_01_entrada_estufa` / `f53_02_parado_sem_andar` — jogador no tile **4,62** (o `P`), sem andar.
  - `f53_03_chassi_perdido` — tela SINAL DO CHASSI PERDIDO após o `call` de dano letal.
  - `f53_04_renasceu_na_estufa` — **de volta na Estufa**, tile **2,62** (a `gh_dock_01`), 2 de 4
    células de Integridade, mesmo objetivo "Religar o Nó da Estufa".
  - `user://save.json` depois da entrada: `checkpoint = {"scene": ".../greenhouse.tscn", "dock_id":
    "gh_dock_01"}`, `deaths: 0` — gravado **na entrada**, antes da morte.
  - `f53_05_menu_continuar` → `f53_06_carregando_estufa` (CARREGANDO SETOR **ESTUFA**) →
    `f53_07_continuou_na_estufa` (MU-7 na doca da Estufa, tile 2,62). Antes do conserto o CONTINUAR
    levava ao Núcleo Central.
- **Pendência reportada ao humano**: `scenes/world/level_exit.gd` (quadro 4 de 32×48) e o estado
  **aberto** de `scenes/world/door.gd` usam **o mesmo quadro do mesmo sheet** (`door_sheet.png`,
  160×48 = 5 quadros). O portal aparece inteiro e legível, mas é o sprite da porta comum aberta com
  uma luz verde por cima — a porta do Habitat (tile 60) e o portal de saída (tile 76) ficam iguais no
  mesmo corredor. Precisa de arte própria (quadro novo no sheet ou sheet separado).

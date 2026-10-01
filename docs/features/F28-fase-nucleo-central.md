---
id: F28
title: Fase 0 — Núcleo Central (tutorial/hub)
status: done
scope: demo
block: 4
priority: P0
rubric: ["Música (trilha sonora)"]
depends_on: ["F12", "F13", "F14", "F15", "F16", "F17", "F18", "F19", "F20", "F21", "F22", "F26"]
unblocks: ["F29", "F30"]
estimate: 3h
last_updated: 2026-09-19
---

# F28 — Fase 0 — Núcleo Central (tutorial/hub)

## 1. Contexto e objetivo

A primeira fase da Demo e **a porta de entrada do jogador humano no jogo**. ÓRBITA acorda no
**Núcleo Central**, acopla-se ao **MU-7** parado na doca e executa o que ela chama de
*"calibração do chassi"* — que é o tutorial ([Jornada etapa 1](../design/JORNADA-DO-HEROI.md#jh-1)).
Em sequência, sem nenhuma caixa dizendo "aperte X para pular", ela ensina:
**mover → pausar → pular → descer de plataforma → interagir/ler log → lanterna → Terminal de Distribuição (3 sistemas / 1 energia) → a porta abre**, cada passo ensinado por um cartão de tecla e cobrado por um obstáculo ([F36](F36-tutorial-briefing.md)).

Ao atravessar a porta, o **alarme do reator** dispara: o timer global começa a cair
([Jornada etapa 2](../design/JORNADA-DO-HEROI.md#jh-2), [GDD-2.5](../design/GDD.md#gdd-2-5-timer)).
O corredor seguinte é o **Setor Habitacional**, a Travessia do Limiar
([etapa 4](../design/JORNADA-DO-HEROI.md#jh-4)): a **doca de backup**, o **primeiro corpo** (traje vazio,
registrado por ÓRBITA como "anomalia biológica") e a **primeira SR-3**. Depois dele, a saída.

> **Origem desta versão:** o jogador humano testou as bancadas de desenvolvimento (`scenes/dev/*`) e
> relatou: *"não sei o que preciso fazer, qual a ordem, objetivo"* e *"se eu abro a porta não tem nada
> à frente"*. Esta fase é a resposta: uma ordem explícita no HUD, consequência física em cada escolha
> e um destino no fim do corredor.

Duração alvo: **~5 min** lendo tudo (na QA, pulando todo o texto, o percurso direto deu **29 s** de
`play_time`). Dificuldade 1/10. A parte tutorial não tem dano possível; o Habitacional tem a SR-3.

## 2. Referências de design

- **GDD:** [GDD-2.7-F0](../design/GDD.md#gdd-2-7-f0) · [GDD-2.3 loop](../design/GDD.md#gdd-2-3-macro) ·
  [GDD-2.5 timer](../design/GDD.md#gdd-2-5-timer) · [GDD-2.9 paleta](../design/GDD.md#gdd-2-9-paleta) ·
  [AJ-013](../design/GDD.md#gdd-ajustes) (o timer só começa no alarme) ·
  [AJ-015](../design/GDD.md#gdd-ajustes) (queda no escuro não mata na Demo)
- **Jornada:** [1 — Mundo Comum](../design/JORNADA-DO-HEROI.md#jh-1) ·
  [2 — Chamado](../design/JORNADA-DO-HEROI.md#jh-2) ·
  [4 — Travessia do Limiar](../design/JORNADA-DO-HEROI.md#jh-4)
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) · [ADR-006](../DECISIONS.md#adr-006) ·
  [ADR-011](../DECISIONS.md#adr-011) · [ADR-012](../DECISIONS.md#adr-012) · [ADR-013](../DECISIONS.md#adr-013)
- **Features vizinhas:** [F21](F21-construtor-fases-ascii.md) (construtor + legenda),
  [F17](F17-terminal-distribuicao.md), [F18](F18-luz-lanterna.md), [F19](F19-dialogo-logs.md),
  [F14](F14-estabilidade-reator.md), [F22](F22-inimigo-sr3.md), [F26](F26-parallax.md),
  [F29](F29-fase-estufa.md) (destino do `E`).

## 3. Critério de avaliação atendido

- **Música (trilha sonora)**: a fase toca `MUS-CORE` em loop desde o `_ready`
  (`music: "core"` no JSON → `AudioManager.play_music`).
- Vitrine integrada do resto da rubrica na ordem do roteiro: **Diálogo** (F19), **HUD** e
  **Missões primárias** (F15), **Puzzle** (F17), **Luz/Sombra** (F18), **Coleta/Score** (F20),
  **Life skills** (F13), timer do reator (F14) e o primeiro inimigo (F22).

## 4. Escopo

### Inclui
- `data/levels/core_hub.txt` — mapa ASCII **72×15 tiles** (1152×240 px), horizontal, seção 6.1.
- `data/levels/core_hub.json` — metadados no esquema canônico da [F21](F21-construtor-fases-ascii.md).
- `data/energy/core_hub.json` — terminal `core_hub`: **3 sistemas, 1 energia** desde a [F36](F36-tutorial-briefing.md) (soma `lift_core`, elevador opcional para o Dado de Pesquisa).
- `data/logs/core_hub.json` — acrescentado `log_hab_02` (o fragmento do Habitacional).
- `data/dialogue/core_hub.json` — nenhuma fala nova; **retirados** os campos `objective` de
  `core_log_hint`, `core_lights_off` e `core_alarm` (ver [ADR-F28-004](#adr-f28-004)).
- `scenes/levels/core_hub.tscn` — cena herdada de `level_base.tscn` com `level_id = "core_hub"`.
- `scenes/levels/core_hub.gd` — nó `Narrative`: avança o objetivo quando o puzzle é resolvido.
- `scenes/world/level_exit.tscn` + `level_exit.gd` — a saída `E`, que a legenda da F21 já apontava
  mas ninguém tinha implementado ([ADR-F28-003](#adr-f28-003)).
- `tests/test_level_core_hub.gd` — 15 testes de dados da fase.
- `tests/qa/f28_core_hub.json` — roteiro `godot-qa` que joga a fase inteira (30 capturas).

### Não inclui
- Voltar da Estufa para o Núcleo (hub bidirecional) — Final.
- Viagem rápida, mapa (TAB), salas extras, portas por Chave de Acesso — Final.
- Área secreta no Núcleo (a única da Demo é a da [F27](F27-area-secreta.md), na Estufa).
- Música adaptativa por camadas (F50).

## 5. Critérios de aceite

- [x] Do `_ready` ao `E`, a fase é jogável sem erro no console e sem o jogador sair do mapa.
- [x] O MU-7 nasce ao lado da doca (`P` em `5,11`), com a sala iluminada pelas lâmpadas `@`.
- [x] Os objetivos aparecem na ordem da seção 6.4 e **nunca andam para trás**.
- [x] O degrau de 1 tile (col 12) e o de 2 tiles (col 15) exigem `jump` e não são transponíveis andando.
- [x] O terminal de log `L` (`23,8`) abre `log_core_01`, congela o timer e conta `LOGS 01/24`.
- [x] O túnel (cols 29–46) não tem lâmpada: fica visivelmente escuro e a lanterna (`F`) revela o `r`.
- [x] O Terminal de Distribuição mostra **3 sistemas e 1 energia** ([F36](F36-tutorial-briefing.md)); ligar `door_habitat`
      apaga `lights_core` (o Núcleo escurece na hora) e abre a porta em `54,11`.
- [x] Resolver o puzzle **avança o objetivo do HUD** para *"Atravessar o Setor Habitacional até a Estufa"*.
- [x] Atravessar a porta dispara o alarme: fala da ÓRBITA + `ESTABILIDADE DO REATOR: 100% descendo`
      no HUD. Antes disso `GameState.is_reactor_online()` é `false`.
- [x] A doca `D` (`57,11`) salva (`BACKUP SALVO`) antes do perigo.
- [x] O traje (`o` em `60,11`) é interagível (`[E] EXAMINAR TRAJE`) e abre `log_hab_01`.
- [x] A SR-3 em `64,11` patrulha entre o batente (col 62) e a plataforma (col 67) e causa dano por contato.
- [x] Os 4 coletáveis da fase entram no HUD: célula (`33,11`), dado (`37,12`), kit (`65,11`),
      fragmento de log (`68,10`).
- [x] Encostar no `E` em `70,10` leva à Estufa; como `greenhouse.tscn` ainda não existe, emite
      `EventBus.demo_completed` e a F10 troca para `FIM DA DEMO` ([ADR-F28-003](#adr-f28-003)).
- [x] `tests/test_level_core_hub.gd` verde; `core_hub.tscn` e `level_exit.tscn` no smoke.
- [x] Portões do `/CLAUDE.md` §6 verdes (import limpo, 487 testes, 60 cenas no smoke).
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### 6.1 Mapa ASCII — `data/levels/core_hub.txt` (72 × 15)

```
########################################################################
########################################################################
#              #########################################################
#                            ##################    WW ##################
#       WW                   ##################    WW ##################
#       WW                   ##################       #                #
#                @    @                               #WW              #
#                                                     #WW              #
#                      L #                            #                #
#   @     @    ############                     @  @       @           #
#              ############                                         l E#
# D  P      #################    c                  T |  D  o # Sk #####
#################################### r #################################
########################################################################
########################################################################
```

Leitura, da esquerda para a direita:

| Cols | Trecho | Função |
|---|---|---|
| 1–11 | Doca (`D` 2,11), spawn (`P` 5,11), lâmpadas (4,9 / 10,9), janela (8–9 / 4–5) | Acordar, andar |
| 12–14 | Piso 1 tile acima | Ensina o **pulo curto** (parede intransponível andando) |
| 15–24 | Piso 2 tiles acima, lâmpadas (17,6 / 22,6) | Ensina o **pulo longo** (32 px < `JUMP_HEIGHT` 40) |
| 23 | Terminal de registro `L` (23,8) | Ensina `interact`; `log_core_01` (Helena explica o Terminal) |
| 25 | Batente de 1 tile | Faz o jogador **parar ao lado do `L`** andando para a direita |
| 26–28 | Descida em dois degraus (9 → 11 → 12) | Volta ao piso térreo, reversível |
| 29–46 | **Túnel sem lâmpada**, teto baixo | Ensina a **lanterna** (`F`); célula `c` (33,11) repõe a Carga |
| 36–38 | Vala de 1 tile com o dado `r` (37,12) | Recompensa opcional, só visível com luz |
| 47–53 | Sala do Terminal, lâmpadas, janela | **Puzzle 3 sistemas / 1 energia** — mapa reescrito pela [F36](F36-tutorial-briefing.md) |
| 54 | Porta de energia `\|` (54,11), parede sólida até a linha 8 | Abre quando `door_habitat` recebe energia |
| 55–70 | **Setor Habitacional**: janela (55–56 / 6–7), doca (`D` 57,11), luz de emergência âmbar (59,9), traje `o` (60,11), batente (62), SR-3 `S` (64,11), kit `k` (65,11), plataforma (67–70) com `l` (68,10) e saída `E` (70,10) | Travessia do Limiar |

Geometria: teto/chão com 2+ tiles de espessura, **piso contínuo (nenhum vão)**, degraus de no máximo
**2 tiles**, altura livre mínima de 4 tiles. Todas essas regras são verificadas por teste.

### 6.2 Metadados — `data/levels/core_hub.json`

Esquema da F21: `id`, `name`, `tileset` (caminho `.tres`), `ambient_color`, `parallax`, `floor_sfx`,
`music` (id do `AudioManager`), `reactor_online: false`, `objective`, `on_enter_dialogue`,
`terminals: ["core_hub"]`, `entities{"x,y": {...}}`, `triggers[]`.

- Lâmpadas: `terminal_id`/`system_id`/`group` conforme [ADR-011](../DECISIONS.md#adr-011), com
  `radius: 160` e `energy: 1.6` por lâmpada ([ADR-F28-002](#adr-f28-002)).
- A luz de emergência do Habitacional (`59,9`) **não tem** `terminal_id`: fica sempre acesa, âmbar,
  e é o farol que mostra o traje e a doca no escuro.
- `ambient_color: "#5a757f"` ([ADR-F28-002](#adr-f28-002)).

### 6.3 Puzzle de energia — `data/energy/core_hub.json`

Inalterado: `budget: 1`, sistemas `lights_core` (tag VISÃO, inicial ligado) e `door_habitat`
(tag META). **Não existe estado em que tudo está ligado**: abrir a porta apaga a luz — e é por isso
que a lanterna foi ensinada dois trechos antes.

### 6.4 Sequência de objetivos e falas

| # | Disparo | Objetivo no HUD | Fala |
|---|---|---|---|
| 1 | `_ready` da fase | `Calibrar o chassi MU-7` | `core_wake` (bloqueante) |
| 2 | gatilho `core_t_move` (9,7) | (mantém) | `core_calib_move` (ambiente) |
| 3 | gatilho `core_t_log` (20,4) | `Acessar o terminal de registros do Núcleo` | — |
| 4 | `interact` no `L` | (mantém) | `log_core_01` (log, congela o timer) |
| 5 | gatilho `core_t_dark` (31,7) | `Abrir a porta do Setor Habitacional no Terminal de Distribuição` | `core_flashlight_hint` |
| 6 | gatilho `core_t_terminal` (46,7) | (mantém) | `core_terminal_first` (bloqueante) |
| 7 | `energy_changed(core_hub, door_habitat, true)` | `Atravessar o Setor Habitacional até a Estufa` | `core_bark_door_on` |
| 8 | gatilho `core_t_alarm` (55,7) | (reafirma o mesmo) | `core_alarm` → `flags.reactor_online` |
| 9 | gatilho `core_t_body` (59,7) | (mantém) | `hab_body` (bloqueante) |
| 10 | `interact` no traje | (mantém) | `log_hab_01` |
| 11 | gatilho `core_t_sr3` (61,7) | (mantém) | `hab_first_sr3` (ambiente) |
| 12 | encostar em `E` | — | `SceneManager.goto` ou `EventBus.demo_completed` |

**Só gatilho muda objetivo** ([ADR-F28-004](#adr-f28-004)) e **nenhum objetivo se repete** — os dois
fatos são cobertos por teste.

### 6.5 Cenas e scripts

```
scenes/levels/core_hub.tscn      herda level_base.tscn, level_id = "core_hub"
  └─ Narrative (Node)            scenes/levels/core_hub.gd
scenes/world/level_exit.tscn     Area2D + Sprite2D (porta aberta) + PointLight2D verde
  └─ scenes/world/level_exit.gd  class_name LevelExit
```

`core_hub.gd` tem um único trabalho: ouvir `EventBus.energy_changed` e, quando `door_habitat`
recebe energia, chamar `GameState.set_objective(goal_objective)`. Os três ids são `@export`.

`level_exit.gd`: `@export var target: String`; ao encostar o jogador, vai para o alvo pelo
`SceneManager` **se ele existir**, senão emite `EventBus.demo_completed` (a F10 decide a tela,
[ADR-013](../DECISIONS.md#adr-013)).

## 7. Assets necessários

Todos ainda em **placeholder** — nenhum bloqueia a fase.

| Asset id | Uso | Observação da QA |
|---|---|---|
| [TIL-CORE](../ASSETS.md#til-core) | Tileset da fase | Tiles muito escuros (base `#1D3037`); só ficam legíveis com `ambient_color` claro — ver [ADR-F28-002](#adr-f28-002) |
| [MUS-CORE](../ASSETS.md#mus-core) | Trilha da fase | Placeholder gerado toca em loop |
| [SPR-PROPS](../ASSETS.md#spr-props) | Traje caído (`60,11`) | Hoje é uma caixa cinza; **não se lê como um corpo** |
| [SPR-TERMINAL](../ASSETS.md#spr-terminal) | Terminal de distribuição e de log | Lê bem (tela ciano) |
| [SPR-DOOR](../ASSETS.md#spr-door) | Porta de energia e saída | Faixa amarela/preta; lê bem |
| [SPR-DOCK](../ASSETS.md#spr-dock) | Docas (`2,11`, `57,11`) | Lê bem |
| [SPR-PICKUPS](../ASSETS.md#spr-pickups) | Célula, dado, kit, fragmento | Losangos coloridos, legíveis |
| [SPR-SR3](../ASSETS.md#spr-sr3) | SR-3 (`64,11`) | Oval laranja com luz âmbar; muito visível no escuro |
| [BG-SPACE](../ASSETS.md#bg-space) | Parallax pelas janelas | `parallax: true` |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `step_metal`, `jump`, `interact`, `terminal_breaker`, `power_on/off`, `door_open`, `reactor_alarm`… | Beeps gerados |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `data/levels/core_hub.txt` (72×15) com geometria conferida por teste.
- [x] **Passo 2** — `data/levels/core_hub.json`, `log_hab_02` em `data/logs/core_hub.json`.
- [x] **Passo 3** — `scenes/levels/core_hub.tscn` + `core_hub.gd`.
- [x] **Passo 4** — `scenes/world/level_exit.tscn` + `level_exit.gd` (a legenda da F21 apontava para ela).
- [x] **Passo 5** — Sequência de objetivos e gatilho do alarme.
- [x] **Passo 6** — `tests/test_level_core_hub.gd` (15 casos) + `tests/scenes.txt`.
- [x] **Passo 7** — `godot-qa` com o roteiro completo; três rodadas de ajuste (luz, ritmo das falas,
      ancoragem das paradas em parede).
- [x] **Passo 8** — Portões do `/CLAUDE.md` §6.

## 10. Verificação

### Testes — `tests/test_level_core_hub.gd` (15 casos, todos verdes)

`test_map_parses_without_errors` · `test_map_is_tall_enough_for_the_viewport` (≥14 linhas, largura
regular) · `test_single_spawn_and_single_exit` (1 `P`, 1 `E`, 1 `T`, 1 `|`, 1 `S`) ·
`test_tutorial_has_one_of_each_pickup` (1 `c`, 1 `k`, 1 `r`, 1 `l`, 2 `D`) ·
`test_floor_is_continuous_and_climbable` (degraus ≤ 2 tiles, vãos ≤ 3 tiles) ·
`test_entity_keys_point_to_entity_cells` · `test_every_entity_is_described_in_the_json` ·
`test_objective_and_dialogue_ids_exist` · `test_log_ids_exist` ·
`test_objectives_never_repeat_along_the_route` · `test_triggers_fit_inside_the_map` ·
`test_terminals_and_systems_match_the_energy_file` ·
`test_puzzle_is_two_systems_one_unit_and_solvable` · `test_exit_falls_back_to_the_demo_end` ·
`test_scene_and_data_agree`.

### Portões (saída real, 2026-09-19)

```
IMPORT exit=0                       (nenhum SCRIPT ERROR / Parse Error / ERROR:)
487 passed, 1 failed                (a falha é test_asset_resolver, do sprite final do MU-7 — não é desta feature)
60 cena(s) verificada(s)            tools/smoke.sh, incluindo core_hub.tscn e level_exit.tscn
grep de comentários em .gd: vazio
grep de nós 3D: vazio
```

### QA visual — `tests/qa/f28_core_hub.json`

30 capturas percorrendo a fase inteira, com `--fixed-fps 60` e `--qa-screen=1`. Nenhum
`SCRIPT ERROR`/`ERROR:` no log. Percurso direto: `TEMPO 00:29`, `LOGS 3/24`, `DADOS 1/12`,
`MORTES 0` na tela de FIM DA DEMO.

Momentos confirmados: despertar na doca · degrau de 1 e de 2 tiles · `[E] LER REGISTRO` e o log da
Helena · corredor escuro · lanterna e `+40 CARGA` · `DADO DE PESQUISA 01/12` na vala ·
`[E] ACESSAR TERMINAL` · UI com `ORÇAMENTO DE ENERGIA: 1/1 EM USO` e as duas linhas VISÃO/META ·
`META CUMPRIDA` ao ligar a porta · Núcleo no escuro com o corredor âmbar à frente ·
`ESTABILIDADE DO REATOR: 100% descendo` no alarme · `BACKUP SALVO` na doca ·
`[E] EXAMINAR TRAJE` e `LOG PESSOAL 07` · SR-3 patrulhando · `+25 INTEGRIDADE` · `LOGS 03/24` ·
saída iluminada · `FIM DA DEMO`.

## 11. ADRs locais

<a id="adr-f28-001"></a>
### ADR-F28-001 — O timer do reator só começa no alarme, depois da porta
- **Contexto:** [AJ-013](../design/GDD.md#gdd-ajustes) já decidiu que o decaimento começa no alarme da
  Fase 0. Faltava decidir **onde** o alarme fica.
- **Decisão:** o gatilho `core_t_alarm` está em `55,7`, **depois** da porta do Habitacional. A fase
  carrega com `reactor_online: false`; a fala `core_alarm` grava a flag em `set_flags`.
- **Consequências:** todo o tutorial (andar, pular, ler, lanterna, puzzle) é seguro; o Chamado para a
  Aventura vira um evento que o jogador **vê** no HUD ("ESTABILIDADE DO REATOR: 100% descendo"), no
  mesmo instante em que passa o ponto sem volta.
- **Data:** 2026-09-19

<a id="adr-f28-002"></a>
### ADR-F28-002 — A fase é clara por padrão; o escuro vem da ausência de lâmpada
- **Contexto:** com `ambient_color` escuro (`#191d26`, como nas bancadas) o `CanvasModulate` multiplica
  também a contribuição das luzes, e os tiles placeholder do Núcleo são muito escuros (`#1D3037`,
  borda `#6794 98`). O resultado medido nas primeiras capturas: **o jogador não distinguia chão de
  parede de fundo em lugar nenhum** — exatamente a queixa "não sei para onde ir".
- **Decisão:** `ambient_color: "#5a757f"` (claro) e lâmpadas fortes (`radius 160`, `energy 1.6`)
  nos trechos iluminados. O contraste "aceso × apagado" passa a ser **a presença das lâmpadas**, não o
  ambiente. O túnel (cols 29–46) e o corredor Habitacional não têm lâmpada de sistema; o Habitacional
  tem uma luz de emergência âmbar fixa (`59,9`) para o traje e a doca não sumirem.
- **Consequências:** a fase é legível de ponta a ponta e o apagão do puzzle continua visível na hora
  (capturas 17 → 18). A causa raiz — tileset placeholder escuro demais para o modelo de luz — fica
  registrada como pendência de [TIL-CORE](../ASSETS.md#til-core); quando a arte definitiva chegar, o
  `ambient_color` pode voltar a escurecer.
- **Data:** 2026-09-19

<a id="adr-f28-003"></a>
### ADR-F28-003 — A saída `E` cai no FIM DA DEMO quando a fase-alvo não existe
- **Contexto:** a legenda do `LevelBuilder` já apontava `E` para `res://scenes/world/level_exit.tscn`
  (marcada como F28), mas a cena nunca foi criada; e `res://scenes/levels/greenhouse.tscn` ([F29](F29-fase-estufa.md))
  ainda não existe, então a fase terminaria em erro ou em nada.
- **Decisão:** `level_exit.gd` guarda `target`. Se `ResourceLoader.exists(target)` → `SceneManager.goto`.
  Senão → `EventBus.demo_completed.emit()` e **quem troca de cena é a F10** ([ADR-013](../DECISIONS.md#adr-013)).
  A saída também carrega uma `PointLight2D` verde: no corredor escuro ela é o farol que responde ao
  "se eu abro a porta não tem nada à frente".
- **Consequências:** a fase fecha sozinha hoje e passa a levar para a Estufa no dia em que a F29
  criar a cena, **sem tocar em nada da F28**.
- **Data:** 2026-09-19

<a id="adr-f28-004"></a>
### ADR-F28-004 — Objetivo muda no gatilho, nunca no fim de uma fala
- **Contexto:** as sequências `core_log_hint`, `core_lights_off` e `core_alarm` traziam o campo
  `objective`, aplicado pelo `DialogueManager` **quando a fala termina**. Falas ambientes entram numa
  fila FIFO de 4–9 s cada; na primeira QA a fila acumulou e o objetivo do HUD **andou para trás**
  (voltou para "Acessar o terminal de registros" depois de já pedir "Abrir a porta") — a mesma
  confusão que o jogador relatou.
- **Decisão:** o campo `objective` foi removido dessas três sequências. Quem muda objetivo é o
  `objective` do gatilho (`dialogue_trigger.gd`, aplicado no instante em que o jogador entra na área)
  ou o `core_hub.gd` (quando o puzzle é resolvido). Além disso, a fase usa **no máximo uma fala
  ambiente pendente por vez**: com duas ou mais na fila, uma fala bloqueante nova fica presa atrás
  delas e trava o jogo por vários segundos.
- **Consequências:** o objetivo do HUD é sempre o próximo passo real; teste
  `test_objectives_never_repeat_along_the_route` protege a regra. A limitação do `DialogueManager`
  (bloqueante não fura a fila de ambientes) continua existindo — está anotada como pendência da
  [F19](F19-dialogo-logs.md).
- **Data:** 2026-09-19

<a id="adr-f28-005"></a>
### ADR-F28-005 — Toda parada importante encosta numa parede
- **Contexto:** num roteiro de QA por frames, parar o jogador num ponto exato é impossível de calibrar
  — e um jogador humano segurando "direita" também passa direto do que importa.
- **Decisão:** cada ponto de interação tem uma parede logo depois: o `L` (23,8) tem o batente da col 25,
  o Terminal (52,11) tem a porta fechada da col 54, o traje (60,11) tem o batente da col 62, a SR-3
  tem a plataforma da col 67 e a saída tem a parede da col 71.
- **Consequências:** o roteiro de QA virou determinístico e, no jogo, quem só anda para a direita
  **para exatamente em cima de cada coisa que precisa usar**.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial com mapa ASCII 48×14, JSON de
  metadados, puzzle 2/1, sequência de objetivos e conteúdo narrativo · **Próximo passo**: implementação.

### 2026-09-19 — Implementada e validada
- **Quem**: agente de implementação (F28)
- **Origem**: retorno do jogador humano nas bancadas de desenvolvimento — *"não sei o que preciso
  fazer, qual a ordem, objetivo"* e *"se eu abro a porta não tem nada à frente"*.
- **O que**: mapa refeito para **72×15** (o de 48×14 não dava espaço para o ritmo pedido e deixava o
  fundo vazio na parte de baixo da tela); `core_hub.json`, `core_hub.tscn` + `core_hub.gd`,
  `level_exit.tscn` + `level_exit.gd`, `log_hab_02`, 15 testes de dados, roteiro de QA com 30 capturas.
- **Correções encontradas jogando** (três rodadas de `godot-qa`):
  1. **Fase ilegível.** Com ambiente escuro nada se distinguia. Resolvido em [ADR-F28-002](#adr-f28-002).
  2. **Objetivo andando para trás.** Falas ambientes aplicando `objective` no fim da fila.
     Resolvido em [ADR-F28-004](#adr-f28-004).
  3. **Jogo travado por vários segundos.** Fila de falas ambientes segurando uma fala bloqueante.
     Mitigado reduzindo a 4 as falas ambientes da fase e espaçando os gatilhos.
  4. **Paradas imprevisíveis.** Resolvido em [ADR-F28-005](#adr-f28-005).
  5. **A saída não existia.** `level_exit.tscn` criado ([ADR-F28-003](#adr-f28-003)).
- **Pendências**:
  - [TIL-CORE](../ASSETS.md#til-core): tiles placeholder escuros demais para o modelo de luz da F18 —
    a arte definitiva deve ter base clara para o `ambient_color` poder escurecer de novo.
  - [SPR-PROPS](../ASSETS.md#spr-props): o traje (`frame: 1`) não se lê como um corpo; hoje quem conta
    a cena é a fala `hab_body`.
  - [F19](F19-dialogo-logs.md): uma fala **bloqueante** deveria furar a fila de falas ambientes em vez
    de esperar atrás delas.
  - [F29](F29-fase-estufa.md): ao criar `res://scenes/levels/greenhouse.tscn`, a saída passa a levar
    para lá sozinha — nada a mudar aqui.
- **Próximo passo**: playtest humano cronometrado (alvo ~5 min) e a Estufa ([F29](F29-fase-estufa.md)).

### 2026-09-20 — reescrita pela [F36](F36-tutorial-briefing.md)
- O mapa ASCII foi refeito (80×15) para virar tutorial explícito: cada cartão de tecla é seguido de um obstáculo que obriga a usar o controle (um bloco que só passa pulando, uma passarela de onde só se sai descendo). O terminal foi de 2 para 3 sistemas e ganhou o elevador opcional para o Dado de Pesquisa.

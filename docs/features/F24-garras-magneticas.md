---
id: F24
title: Garras Magnéticas (habilidade)
status: done
scope: demo
block: 3
priority: P0
rubric: ["Habilidades"]
depends_on: ["F02", "F12", "F16", "F19", "F21"]
unblocks: ["F29"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F24 — Garras Magnéticas (habilidade)

## 1. Contexto e objetivo

As **Garras Magnéticas** são o upgrade da Estufa: permitem ao MU-7 **escalar paredes metálicas marcadas** (painéis com listras magnéticas). É a habilidade que a Demo precisa mostrar funcionando para pontuar em "Habilidades" e é a prova mecânica do pilar **DESCOBERTA**: o jogador só consegue subir até o Nó do setor depois de ler o log da Dra. Helena que destrava as garras.

**Atenção ao design:** no [GDD-2.6.1](../design/GDD.md#gdd-2-6-1-habilidades) as Garras são o upgrade **ganho ao religar o Nó da Estufa** — o que, numa demo que **termina** no religamento, deixaria a habilidade invisível. Esta feature propõe (ADR-F24-001 + ajuste de design a ser adicionado ao GDD) **antecipar** a entrega: a Helena deixou as garras destravadas num terminal de log no meio da Estufa, e a subida final até o Nó **exige** as garras. A recompensa narrativa do Mentor ([Jornada etapa 3](../design/JORNADA-DO-HEROI.md#jh-3)) continua intacta — "cada upgrade chega com um pedaço da verdade".

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.1 Habilidades — Garras Magnéticas](../design/GDD.md#gdd-2-6-1-habilidades) · [GDD-2.7-F1 — Estufa](../design/GDD.md#gdd-2-7-f1) · [GDD-2.6.1 Status base](../design/GDD.md#gdd-2-6-1-status) · [GDD-2.7 curva (upgrade derruba a dificuldade)](../design/GDD.md#gdd-2-7-curva)
- **Parâmetros:** `Balance.WALK_SPEED`, `Balance.JUMP_HEIGHT`, `Balance.GRAVITY`, `Balance.TILE_SIZE` — [GDD-P](../design/GDD.md#gdd-p). **Novos (ADR-F24-002):** `Balance.CLAW_CLIMB_SPEED`, `Balance.CLAW_JUMP_PUSH`.
- **Jornada:** [Etapa 3 — Mentor](../design/JORNADA-DO-HEROI.md#jh-3) · [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) · [ADR-010](../DECISIONS.md#adr-010)
- **Features vizinhas:** [F12 — Movimento do MU-7](F12-movimento-mu7.md) (máquina de estados e `velocity`), [F19 — Diálogo e logs](F19-dialogo-logs.md) (o log que destrava), [F29 — Estufa](F29-fase-estufa.md) (onde as paredes `M` ficam), [F11 — Salvar/Carregar](F11-salvar-carregar.md) (a habilidade entra no save).

## 3. Critério de avaliação atendido

**Habilidades** ([rubrica](../ENTREGAS.md#rubrica)). Na apresentação: o jogador lê o log da Helena no terminal da Estufa, aparece a fala "GARRAS MAGNÉTICAS — ONLINE" e o objetivo muda para *"Escale a parede magnética"*; em seguida o MU-7 **gruda na parede listrada e sobe** (animação `climb`) até o andar do Nó — algo que ele comprovadamente não conseguia fazer antes (a mesma parede foi vista no caminho de ida). É o momento "eu fiquei mais forte" da curva do GDD.

## 4. Escopo

### Inclui
- Estado `CLIMB` no `mu7.gd` (F12): grudar, subir/descer, parar na parede e pular para fora.
- Detecção por `RayCast2D` frontal contra nós do grupo `"magnetic"`.
- `scenes/world/magnetic_wall.tscn` + `magnetic_wall.gd`: bloco sólido 16×16 escalável, no grupo `"magnetic"`, instanciado pelo caractere `M`.
- Destravar a habilidade: `GameState.unlock_ability(&"magnetic_claws")` + `EventBus.ability_unlocked`, disparado pelo fechamento do log com `grants_ability` no JSON da fase.
- Fala da ÓRBITA + `objective_changed` no momento do destrave.
- Lógica pura `scripts/core/climb_logic.gd` com testes.
- Persistência: a habilidade está em `GameState.abilities` e entra no save ([F11](F11-salvar-carregar.md)).
- Animação `climb` (SPR-MU7, linha 8) e SFX de agarrar.

### Não inclui
- Escalar qualquer parede (só as marcadas com `M`) — decisão do GDD.
- Wall jump repetido em ziguezague entre duas paredes (a Demo tem uma parede única e reta).
- Pulo duplo / Propulsor, Dissipador, Núcleo Aquecido, Acesso Root — Final.
- Tela de habilidades/upgrades — F49 (Final). Aqui o feedback é diálogo + objetivo.

## 5. Critérios de aceite

- [x] **Antes** de ler o log: encostar na parede `M` não faz nada (o MU-7 escorrega/cai normalmente). — QA `f24_01_sem_garras`
- [x] Ao fechar o log `log_gh_03`: `EventBus.ability_unlocked(&"magnetic_claws")` é emitido uma única vez e `GameState.abilities` contém `&"magnetic_claws"`. — `tests/test_abilities.gd`. **A fala da ÓRBITA e a troca de objetivo ficam com a F29** (ver ADR-F24-006).
- [x] **Depois** de destravar: encostar na parede `M` em queda ou andando contra ela, com `move_up` ou a direção apontando para a parede, gruda (gravidade desligada, animação `climb`). — QA `f24_03_grudado`
- [x] Grudado: `move_up` sobe a `Balance.CLAW_CLIMB_SPEED`, `move_down` desce na mesma velocidade, sem input fica parado na parede. — QA `f24_04_subindo` / `f24_06_parado_na_parede`
- [x] `jump` na parede solta o MU-7 com impulso para **longe** da parede (`Balance.CLAW_JUMP_PUSH`) e altura normal de pulo. — QA `f24_07_pulo_da_parede` (ver ADR-F24-005)
- [x] Ao chegar ao topo da parede (o raio perde o contato), o MU-7 sai do estado e pode cair/pular para a plataforma vizinha. — QA `f24_08_na_plataforma`
- [x] Salvar numa doca depois de destravar, sair para o menu e **Continuar** mantém as garras. — `test_ability_survives_save_round_trip`
- [x] Escalar **não** consome Carga (o GDD não prevê custo). — o estado `CLIMB` não chama `spend_charge`
- [x] `tests/test_climb_logic.gd` verde.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/world/magnetic_wall.tscn (+ magnetic_wall.gd)
  MagneticWall (StaticBody2D)      collision_layer = 1 (world) · grupo "magnetic"
  ├─ CollisionShape2D              RectangleShape2D 16×16
  └─ Sprite2D                      tile de parede magnética do TIL-GREENHOUSE (listras)
scenes/player/mu7.tscn (+ mu7.gd)  (+ ClawProbe, estado CLIMB)
  └─ ClawProbe (RayCast2D)         position (0,-14), target_position (10,0) espelhado pelo facing, mask = 1 (world)
scripts/core/climb_logic.gd        class_name ClimbLogic (RefCounted, só static)
```

> **Implementado assim** (divergências registradas nos ADRs locais 004–006): duas sondas (`ClawProbeTop` em `(0,-20)` e `ClawProbeBottom` em `(0,-4)`, alcance 10 px espelhado pelo `facing`, máscara 1 `world`); o destrave entra pelo campo `unlock_ability` do próprio log (`data/logs/greenhouse.json`, já existente) e o `DialogueManager` chama `GameState.unlock_ability()`; o impulso do pulo de parede sobrevive até o pouso (ADR-F24-005).

`scripts/core/climb_logic.gd`:
```gdscript
class_name ClimbLogic
extends RefCounted

static func can_grab(has_ability: bool, touching_magnetic: bool, input_x: float, facing: int,
        input_up: bool) -> bool: ...
    # has_ability and touching_magnetic and (input_up or sign(input_x) == facing)
static func climb_velocity(input_y: float, speed: float) -> Vector2: ...   # Vector2(0, input_y * speed)
static func jump_off_velocity(facing: int, push: float, jump_speed: float) -> Vector2: ...
    # Vector2(-facing * push, -jump_speed)
static func should_release(touching_magnetic: bool, has_ability: bool) -> bool: ...
```
`input_y` = `Input.get_axis("move_up", "move_down")` (positivo = descer).

Integração no `mu7.gd` (F12 é dona da máquina de estados; esta feature acrescenta um estado):
- `_physics_process`: se `state == CLIMB`: `velocity = ClimbLogic.climb_velocity(input_y, Balance.CLAW_CLIMB_SPEED)`; sem gravidade; `move_and_slide()`; se `Input.is_action_just_pressed("jump")` → `velocity = ClimbLogic.jump_off_velocity(facing, Balance.CLAW_JUMP_PUSH, jump_speed)` e volta ao estado aéreo; se `ClimbLogic.should_release(_touching_magnetic(), _has_claws())` → estado aéreo.
- Fora do CLIMB: se `ClimbLogic.can_grab(...)` → entra em CLIMB, `velocity = Vector2.ZERO`, `sprite.play("climb")`, `AudioManager.play_sfx("claw_grab")`.
- `_touching_magnetic()`: `claw_probe.is_colliding() and claw_probe.get_collider().is_in_group("magnetic")`.
- `_has_claws()`: `GameState.abilities.has(&"magnetic_claws")`.
- `jump_speed` = velocidade de pulo derivada de `Balance.JUMP_HEIGHT`/`Balance.GRAVITY` (já existente na F12).

Destrave (quem chama): o objeto de log (`log_object.tscn` / `terminal.tscn` da [F19](F19-dialogo-logs.md)) recebe do JSON da fase o campo `grants_ability`. Ao emitir `EventBus.log_closed(log_id)`, ele chama:
```gdscript
GameState.unlock_ability(&"magnetic_claws")
```
`GameState.unlock_ability(id: StringName) -> void` (adição pequena ao contrato, ADR-F24-003): se `abilities` já contém, retorna; senão adiciona, emite `EventBus.ability_unlocked(id)`. A fase ([F29](F29-fase-estufa.md)) escuta `ability_unlocked` e dispara a fala `gh_claws` + `EventBus.objective_changed("Escale a parede magnética (encoste e segure ↑)")`.

### Autoloads / sinais do EventBus
- **Escuta:** `log_closed(log_id)` (no objeto de log), `ability_unlocked(ability_id)` (na fase, para fala/objetivo).
- **Emite:** `ability_unlocked(&"magnetic_claws")`, `objective_changed(text)`, `dialogue_started`/`dialogue_finished` (via `DialogueManager`).
- `GameState.abilities` entra em `to_dict()`/`from_dict()` ([F11](F11-salvar-carregar.md)) — conferir que o array de `StringName` é serializado como strings.

### Dados (`data/`)
- Fase ([F29](F29-fase-estufa.md)): caractere `M` para cada tile de parede magnética; o terminal de log que destrava:
```json
{ "entities": {
  "36,17": { "log_id": "log_gh_03", "grants_ability": "magnetic_claws" }
} }
```
- `data/logs/greenhouse.json`: `log_gh_03` (Helena) com o texto que explica as garras.
- `data/dialogue/greenhouse.json`: `gh_claws` — fala da ÓRBITA ao destravar.

### Input actions / camadas de colisão
- Usa `move_up`, `move_down`, `move_left`, `move_right`, `jump` (já no [ADR-010](../DECISIONS.md#adr-010)). **Nenhuma ação nova.**
- `magnetic_wall`: layer 1 `world` (é parede de verdade) + grupo `"magnetic"`. `ClawProbe`: mask 1 `world`.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-MU7](../ASSETS.md#spr-mu7) | Linha `climb` (4f) do sprite sheet | Retângulo cinza-azulado com cor própria da animação |
| [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Tile de **parede metálica marcada para garras** (listras) | Verde-musgo com listras amarelas |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `claw_grab` (**novo**, ver seção 11) | Clique magnético gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `Balance.CLAW_CLIMB_SPEED` (70) / `CLAW_JUMP_PUSH` (90) já no `Balance`; [AJ-011](../design/GDD.md#gdd-ajustes) já registrado no GDD.
- [x] **Passo 2** — `tests/test_climb_logic.gd` + `scripts/core/climb_logic.gd`.
- [x] **Passo 3** — `scenes/world/magnetic_wall.tscn` + tile listrado do TIL-GREENHOUSE; legenda `M` já no `LevelBuilder`.
- [x] **Passo 4** — `ClawProbeTop`/`ClawProbeBottom` + estado `CLIMB` no `mu7.gd`; animação `climb` (linha 7 da SPR-MU7).
- [x] **Passo 5** — `GameState.unlock_ability()`; o `DialogueManager` passou a chamá-la ao aplicar o `unlock_ability` do log.
- [ ] **Passo 6** — Fala `gh_claws` e `objective_changed` na fase — **fora do escopo desta execução** (arquivos de diálogo/objetivo em uso por outro agente, ver ADR-F24-006).
- [x] **Passo 7** — Sala de QA `tests/qa/scenes/claw_sandbox.tscn` + roteiro `tests/qa/f24_garras.json`; antes/depois do destrave verificados por captura.
- [ ] **Passo 8** — commit (o agente desta execução não commita).

## 10. Verificação

- **Testes (`tests/test_climb_logic.gd`):**
  - `test_no_ability_no_grab`: `can_grab(false, true, 1.0, 1, false) == false`.
  - `test_grab_pressing_into_wall`: `can_grab(true, true, 1.0, 1, false) == true`.
  - `test_grab_pressing_up`: `can_grab(true, true, 0.0, 1, true) == true`.
  - `test_no_wall_no_grab`: `can_grab(true, false, 1.0, 1, true) == false`.
  - `test_climb_up_is_negative_y`: `climb_velocity(-1.0, 60.0) == Vector2(0, -60)`.
  - `test_idle_on_wall`: `climb_velocity(0.0, 60.0) == Vector2.ZERO`.
  - `test_jump_off_pushes_away`: `jump_off_velocity(1, 110.0, 280.0) == Vector2(-110, -280)`.
  - `test_release_when_wall_ends` / `test_release_when_ability_lost`.
- **Smoke:** `res://scenes/world/magnetic_wall.tscn` em `tests/scenes.txt`.
- **Roteiro godot-qa** (`tests/qa/f24_claws.json`) — sala `tests/qa/levels/qa_claws.txt` com `P`, um terminal de log `L` (com `grants_ability`) e uma parede `M` de 8 tiles com uma plataforma no topo:

  | Frame | Input / ação | Screenshot | Deve mostrar |
  |---|---|---|---|
  | 30 | segurar `move_right` até a parede | `01_no_claws.png` (f120) | MU-7 encostado na parede listrada, **no chão**, sem grudar |
  | 121–150 | soltar; ir até `L` (`move_left`) | — | — |
  | 180 | `interact` | `02_log.png` | caixa de log da Helena aberta (timer do reator congelado) |
  | 240 | `ui_accept` (fechar log) | `03_unlocked.png` | fala "GARRAS MAGNÉTICAS — ONLINE" e objetivo novo no HUD |
  | 300–380 | segurar `move_right` até a parede | `04_grabbed.png` (f380) | MU-7 grudado na parede, animação `climb`, sem cair |
  | 381–500 | segurar `move_up` | `05_climbing.png` (f440) · `06_top.png` (f500) | MU-7 subindo; no topo, acima da plataforma |
  | 505 | `jump` (ainda na parede, se aplicável) | `07_jump_off.png` | MU-7 impulsionado para **longe** da parede |
- **Playtest humano (opcional):** subir 8 tiles parece bom (nem lento demais nem "voando")? A parede listrada é reconhecível como escalável **antes** de ter as garras?

## 11. ADRs locais

### ADR-F24-001 — Garras entregues no meio da Estufa (ajuste de design proposto ao GDD)
- **Contexto:** o GDD-2.6.1 lista "Garras Magnéticas — Upgrade da Estufa", e o loop macro do GDD-2.3 entrega o upgrade **depois** de religar o Nó. A Demo **termina** ao religar o Nó da Estufa ([AJ-004](../design/GDD.md#gdd-ajustes)); a habilidade ficaria ganha e nunca usada, e a rubrica "Habilidades" ficaria sem demonstração.
- **Decisão:** na Estufa, a Dra. Helena deixou as garras destravadas num terminal de log no meio do setor (`log_gh_03`). O jogador as recebe ali (`ability_unlocked`) e **precisa** delas na seção final para escalar a parede `M` até o Nó. O upgrade continua sendo "o upgrade da Estufa" e continua chegando pela voz da mentora.
- **Consequências:** exige **ajuste no GDD** (linha em [Ajustes de implementação](../design/GDD.md#gdd-ajustes) e nota em GDD-2.6.1/2.7-F1) — o orquestrador deve registrar: *"AJ-xxx · 2.6.1 / 2.7-F1 · Garras Magnéticas entregues num log da Helena no meio da Estufa, não ao religar o Nó; a subida final até o Nó exige as garras · a Demo termina no religamento e a habilidade precisa ser jogável"*. Nas fases seguintes (Final) os outros upgrades seguem a regra original.
- **Data:** 2026-09-19

### ADR-F24-002 — Números das garras
- **Contexto:** o GDD não dá velocidade de escalada nem impulso ao soltar.
- **Decisão:** `Balance.CLAW_CLIMB_SPEED = 60` (px/s — mais lento que andar, coerente com "chassi pesado") e `Balance.CLAW_JUMP_PUSH = 110` (px/s, igual a `WALK_SPEED`). **Entradas propostas no [GDD-P](../design/GDD.md#gdd-p)** (origem 2.6.1) + linha em Ajustes.
- **Consequências:** subir 8 tiles (128 px) leva ~2,1 s.
- **Data:** 2026-09-19

### ADR-F24-003 — `GameState.unlock_ability()` como único caminho de destrave
- **Contexto:** o contrato tem `GameState.abilities` e `EventBus.ability_unlocked`, mas não diz quem escreve.
- **Decisão:** `GameState.unlock_ability(id)` é o único ponto que escreve em `abilities` e emite o sinal, e é idempotente (reler o log não re-emite).
- **Consequências:** F31 (dash/feixe) e o Final reusam a mesma porta de entrada; o save nunca duplica habilidade.
- **Data:** 2026-09-19

### ADR-F24-004 — Duas sondas de garra em vez de uma
- **Contexto:** uma sonda única em `(0,-14)` faz o MU-7 largar a parede quando ainda está meio corpo abaixo do topo — ele cai de volta em vez de chegar ao fim da subida.
- **Decisão:** duas `RayCast2D` (`ClawProbeTop` em `(0,-20)` e `ClawProbeBottom` em `(0,-4)`), alcance 10 px espelhado pelo `facing`. Basta **uma** encostar em nó do grupo `magnetic` para grudar/continuar.
- **Consequências:** o agarre em queda é generoso (a sonda de cima pega cedo) e a subida vai até os pés ficarem rentes ao topo da parede. O MU-7 não "toppa" sozinho: no topo ele fica pendurado e sai dali pulando (`jump`) para a plataforma vizinha — que é como a Estufa vai ser desenhada.
- **Data:** 2026-09-19

### ADR-F24-005 — O impulso do pulo de parede só se perde ao pousar
- **Contexto:** `jump_off_velocity` dá `CLAW_JUMP_PUSH` na horizontal, mas o `_apply_horizontal` da F12 desacelera a 840 px/s² quando não há direção apertada — o impulso sumia em ~6 frames e o MU-7 caía colado na parede (visto na primeira rodada de QA).
- **Decisão:** o MU-7 guarda o impulso em `_wall_push` e mantém `velocity.x` nesse valor **enquanto estiver no ar e sem direção apertada**. O impulso zera ao pousar, ao o jogador apertar uma direção, ao voltar a grudar, na morte e no respawn.
- **Consequências:** nenhum número novo (a regra é "até pousar ou até o jogador assumir o controle"), e o jogador pode cortar o impulso apertando a direção contrária — comportamento esperado num plataforma.
- **Data:** 2026-09-19

### ADR-F24-006 — O destrave entra pelo `unlock_ability` do log, não por um `grants_ability` novo
- **Contexto:** a seção 6 previa um campo `grants_ability` no JSON da fase lido pelo objeto de log. O `data/logs/greenhouse.json` **já traz** `"unlock_ability": "magnetic_claws"` no `log_gh_03` e o `DialogueManager` já aplicava esse campo ao fechar o log.
- **Decisão:** reaproveitar o caminho existente e só trocar o corpo do efeito por `GameState.unlock_ability()`, que é idempotente (ADR-F24-003). Nenhum campo novo no JSON da fase.
- **Consequências:** reler o log não reemite `ability_unlocked` nem duplica a habilidade no save. A **fala `gh_claws` e a troca de objetivo** continuam pendentes: moram em `data/dialogue/greenhouse.json` e `data/objectives.json`, que estavam em edição por outro agente nesta sessão — entram com a [F29](F29-fase-estufa.md).
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `scripts/core/climb_logic.gd` (lógica pura) + estado `CLIMB` no `mu7.gd` com duas sondas de garra, `scenes/world/magnetic_wall.{tscn,gd}` (grupo `magnetic`, tile listrado do TIL-GREENHOUSE), `GameState.unlock_ability()` idempotente e `DialogueManager` passando por ela. 18 testes em `tests/test_climb_logic.gd` + 6 em `tests/test_abilities.gd`.
- **Portões**: import sem erro · **488 passed, 0 failed** · smoke 60 cenas OK · varreduras de comentário e de 3D vazias.
- **QA visual** (`tests/qa/f24_garras.json` + `tests/qa/scenes/claw_sandbox.tscn`, `--fixed-fps 60 --qa-screen=1`): `01_sem_garras` MU-7 encostado na parede listrada segurando direita+cima, **no chão**, "GARRAS BLOQUEADAS / ESTADO NORMAL"; `03_grudado` grudado ao pé da parede com "ESTADO ESCALANDO"; `04_subindo` ALTURA 75 no meio da parede; `05_topo_da_parede` ALTURA ~123, no topo; `06_parado_na_parede` sem input, parado no topo; `07_pulo_da_parede` no ar, jogado para longe da parede; `08_na_plataforma` ALTURA 104, **em pé na plataforma vizinha**.
- **Correção durante o QA**: o impulso do pulo de parede era apagado pela desaceleração aérea da F12 (ADR-F24-005).
- **Próximo passo**: F29 liga a fala `gh_claws` e o objetivo novo ao sinal `ability_unlocked`.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial + proposta de ajuste de design (garras no meio da Estufa) · **Próximo passo**: implementação.

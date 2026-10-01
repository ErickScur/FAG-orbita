---
id: F32
title: Obstáculos ambientais (vapor, piso elétrico)
status: not-started
scope: stretch
block: 5
priority: P2
rubric: ["Efeitos visuais/sonoros"]
depends_on: ["F13", "F17", "F23", "F29"]
unblocks: []
estimate: 1h
last_updated: 2026-09-19
---

# F32 — Obstáculos ambientais (vapor, piso elétrico)

## 1. Contexto e objetivo

O "clima" do tema ESTAÇÃO em forma de obstáculo ([GDD-2.6.2-E](../design/GDD.md#gdd-2-6-2-e)). Dois deles cabem na Demo e já têm lugar reservado no mapa da Estufa ([ADR-F29-003](F29-fase-estufa.md)):

- **Jato de vapor** (`v`, em `15,7`): ciclo fixo de **3 s ligado / 2 s desligado**, **20 de dano** por toque. Ensina leitura de ritmo — e é atravessável com dash ([F31](F31-dash-feixe.md)).
- **Piso eletrificado** (`z`, em `20,8`–`23,8`): **8 de dano por segundo** enquanto estiver energizado, e **desligável**. Na Estufa ele está na mesma linha do **ELEVADOR DE CARGA**: desligar o elevador no console do andar do Nó desarma o piso. É o puzzle de energia resolvendo o obstáculo, como manda a [CX-2 do GDD](../design/GDD.md#gdd-2-6-2-b) ("o Terminal resolve combate melhor que o Feixe").

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.2-E — Obstáculos ambientais](../design/GDD.md#gdd-2-6-2-e) · [GDD-2.6.1 Redirecionamento de energia](../design/GDD.md#gdd-2-6-1-redirecionamento) · [GDD-2.9 estética (luz = energia = algo funcionando)](../design/GDD.md#gdd-2-9-visual) · [GDD-2.7 curva (eixo "Ambiente")](../design/GDD.md#gdd-2-7-curva)
- **Parâmetros:** `Balance.STEAM_DAMAGE` (20), `Balance.STEAM_ON_TIME` (3,0), `Balance.STEAM_OFF_TIME` (2,0), `Balance.ELECTRIC_FLOOR_DPS` (8) — [GDD-P](../design/GDD.md#gdd-p). **Novo (ADR-F32-002):** `Balance.STEAM_WARN_TIME`.
- **Jornada:** [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-002](../DECISIONS.md#adr-002) (partículas em Compatibility) · [ADR-004](../DECISIONS.md#adr-004) · [ADR-009](../DECISIONS.md#adr-009)
- **Features vizinhas:** [F23](F23-esporos-status.md) (`DotAccumulator`, imunidade no dash), [F17](F17-terminal-distribuicao.md) (grupo `"powered"`), [F13](F13-integridade-carga-respawn.md) (dano/i-frames), [F29](F29-fase-estufa.md) (posições `v` e `z`), [F31](F31-dash-feixe.md) (`is_dashing()`).

## 3. Critério de avaliação atendido

**Efeitos visuais/sonoros** ([rubrica](../ENTREGAS.md#rubrica)): jato de vapor com partículas, chiado e telegrafia antes de disparar; piso elétrico com faíscas, luz azul pulsante e zumbido — e o silêncio/escuridão característicos quando o jogador corta a energia. Reforça **Puzzle** e **Life skills** já pontuados por outras features.

## 4. Escopo

### Inclui
- `scenes/world/steam_jet.tscn` + `steam_jet.gd`: ciclo `STEAM_ON_TIME`/`STEAM_OFF_TIME` com aviso visual nos últimos `Balance.STEAM_WARN_TIME` do intervalo desligado; `Area2D` de dano (`Balance.STEAM_DAMAGE` por ativação) e `CPUParticles2D` verticais.
- `scenes/world/electric_floor.tscn` + `electric_floor.gd`: tile sólido com `Area2D` rasa por cima; dano contínuo `Balance.ELECTRIC_FLOOR_DPS` via `DotAccumulator` enquanto energizado; no grupo `"powered"` com `system_id`/`terminal_id`.
- Lógica pura `scripts/core/cycle_timer.gd` (fase ligado/desligado/aviso) com testes.
- Imunidade durante o dash ([F31](F31-dash-feixe.md)), conforme o GDD.
- Legenda `v` e `z` apontando para as cenas novas no `LevelBuilder` (os caracteres já estão no mapa da [F29](F29-fase-estufa.md)).
- SFX em loop posicional: `steam_hiss` e `electric_buzz` (novos, seção 11).

### Não inclui
- Gelo fino, vácuo e escuridão letal ([GDD-2.6.2-E](../design/GDD.md#gdd-2-6-2-e)) — fases 3 e 4, Final.
- Status DESCARGA ao tomar choque (o framework da [F23](F23-esporos-status.md) já o define, mas nada o aplica na Demo — F48).
- Vapor empurrando o jogador (knockback) ou quebrando plataformas.
- Novos obstáculos no Núcleo Central (a Fase 0 continua sem dano ambiental).

## 5. Critérios de aceite

- [ ] O jato dispara por 3 s, para por 2 s e repete, com ritmo estável e visível.
- [ ] Nos últimos `Balance.STEAM_WARN_TIME` antes de disparar, aparece um "cuspe" curto de partículas (telegrafia) sem causar dano.
- [ ] Tocar no jato ativo causa 20 de dano **uma vez por ativação** (ficar dentro não causa 20/frame) e respeita as i-frames da [F13](F13-integridade-carga-respawn.md).
- [ ] Passar de dash pelo jato ativo **não** causa dano ([F31](F31-dash-feixe.md)).
- [ ] O piso `z` só machuca (8/s) quando o sistema `lift` está energizado; desligado, é piso comum, sem faísca, sem luz e sem som.
- [ ] Ao carregar a fase, o piso já nasce no estado correto conforme `GameState.energy_states`.
- [ ] Ambos são sólidos/atravessáveis como no mapa: o piso continua caminhável (é chão), o jato não bloqueia a passagem.
- [ ] Sem as duas cenas (feature cortada), a fase continua jogável com `z` como piso comum e `v` como vazio ([ADR-F29-003](F29-fase-estufa.md)).
- [ ] `tests/test_cycle_timer.gd` verde.
- [ ] Portões do `/CLAUDE.md` §6 verdes
- [ ] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/world/steam_jet.tscn (+ steam_jet.gd)
  SteamJet (Node2D)
  ├─ Hazard (Area2D)         collision_layer = 5 (hazard) · collision_mask = 2 (player) · monitoring alternado pelo ciclo
  │   └─ CollisionShape2D    RectangleShape2D 12×32, position (0,-16)
  ├─ Jet (CPUParticles2D)    direction (0,-1), lifetime 0.6, amount 30, emitting conforme a fase
  └─ Hiss (AudioStreamPlayer2D)  `steam_hiss` (loop), volume ligado/desligado pelo ciclo
scenes/world/electric_floor.tscn (+ electric_floor.gd)
  ElectricFloor (StaticBody2D)   collision_layer = 1 (world) · grupo "powered"
  ├─ CollisionShape2D            RectangleShape2D 16×16
  ├─ Sprite2D                    tile de piso do TIL-GREENHOUSE (modulate pulsante quando ligado)
  ├─ Surface (Area2D)            collision_layer = 5 (hazard) · collision_mask = 2 (player)
  │   └─ CollisionShape2D        RectangleShape2D 16×6, position (0,-5)
  ├─ Sparks (CPUParticles2D)     emitting só quando ligado
  ├─ Glow (PointLight2D)         azul, energy 0 quando desligado
  └─ Buzz (AudioStreamPlayer2D)  `electric_buzz` (loop)
scripts/core/cycle_timer.gd      class_name CycleTimer (RefCounted, pura)
```
```gdscript
class_name CycleTimer
extends RefCounted

enum Phase { OFF, WARN, ON }

var on_time: float
var off_time: float
var warn_time: float

func _init(p_on: float, p_off: float, p_warn: float, offset: float = 0.0) -> void: ...
func tick(delta: float) -> int: ...       # devolve a Phase atual
func phase() -> int: ...
func just_turned_on() -> bool: ...
```
- `steam_jet.gd`: `@export var phase_offset: float`; `_physics_process` chama `tick`; em `just_turned_on()` habilita a `Area2D` e as partículas; em `Phase.WARN` emite um burst curto sem dano; ao sair de `ON`, desabilita. O dano é aplicado **uma vez por ativação** por corpo (lista `_hit_this_cycle`, limpa a cada novo `ON`), ignorando quem estiver dando dash.
- `electric_floor.gd`: contrato `"powered"` idêntico ao da [F25](F25-plataformas-moveis-planta.md) (estado inicial lido de `GameState.energy_states`, atualização por `EventBus.energy_changed`); `_physics_process` usa `DotAccumulator` ([F23](F23-esporos-status.md)) com `Balance.ELECTRIC_FLOOR_DPS` para os corpos sobrepostos.

### Autoloads / sinais do EventBus
- **Escuta:** `energy_changed` (piso).
- **Usa:** `GameState.apply_damage` (com o multiplicador de dificuldade aplicado lá).
- SFX: `steam_hiss` e `electric_buzz` em `AudioStreamPlayer2D` dentro das cenas (posicionais e contínuos), no bus de efeitos da [F04](F04-audio-volume.md).

### Dados (`data/`)
Já previstos no JSON da [F29](F29-fase-estufa.md):
```json
{ "entities": {
  "15,7": { "phase_offset": 0.0 },
  "20,8": { "terminal_id": "greenhouse", "system_id": "lift" },
  "21,8": { "terminal_id": "greenhouse", "system_id": "lift" },
  "22,8": { "terminal_id": "greenhouse", "system_id": "lift" },
  "23,8": { "terminal_id": "greenhouse", "system_id": "lift" }
} }
```
`phase_offset` permite defasar vários jatos no Final sem código novo.

### Input actions / camadas de colisão
- Sem input. Hazards na layer 5 `hazard` com mask 2 `player`; o piso mantém a layer 1 `world` para continuar sendo chão.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Tile de piso do trecho eletrificado (variação com contatos metálicos) | Bloco com listras |
| [SPR-SPORE](../ASSETS.md#spr-spore) | Textura de partícula reaproveitada para vapor/faísca (recolorida) | Círculos gerados |
| [FX-LIGHT](../ASSETS.md#fx-light) | Brilho azul do piso | Gradiente radial |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `steam_hiss`, `electric_buzz` (**novos**, seção 11) | Ruídos gerados |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [ ] **Passo 1** — `Balance.STEAM_WARN_TIME` + proposta de linha no GDD-P e em Ajustes.
- [ ] **Passo 2** — `tests/test_cycle_timer.gd` + `scripts/core/cycle_timer.gd`.
- [ ] **Passo 3** — `steam_jet.tscn`/`.gd` com telegrafia e dano por ativação.
- [ ] **Passo 4** — `electric_floor.tscn`/`.gd` com o contrato `"powered"` e `DotAccumulator`.
- [ ] **Passo 5** — Legenda `v` e `z` apontando para as cenas; conferir que o mapa da F29 não precisou mudar.
- [ ] **Passo 6** — QA (roteiro da seção 10) e `/verify-gates`; commit `feat(F32): jato de vapor e piso eletrificado`.

## 10. Verificação

- **Testes (`tests/test_cycle_timer.gd`):**
  - `test_starts_off`: fase inicial `OFF`.
  - `test_turns_on_after_off_time`: com 3/2/0,5 → após 2 s, `ON`.
  - `test_warn_before_on`: em 1,6 s (0,4 antes de ligar) a fase é `WARN`.
  - `test_stays_on_for_on_time` e `test_cycles_forever` (5 ciclos completos, soma de tempo correta).
  - `test_offset_shifts_phase`: dois timers com offsets diferentes não ligam juntos.
  - `test_just_turned_on_is_edge`: verdadeiro só no frame da virada.
- **Smoke:** `res://scenes/world/steam_jet.tscn` e `res://scenes/world/electric_floor.tscn` em `tests/scenes.txt`.
- **Roteiro godot-qa** (`tests/qa/f32_hazards.json`) — sala `tests/qa/levels/qa_hazards.txt` com `P`, `v`, `z` (ligado ao sistema `qa_power`) e um `T`:

  | Frame | Input / ação | Screenshot | Deve mostrar |
  |---|---|---|---|
  | 40 | — | `01_steam_off.png` | jato desligado, passagem livre |
  | 100 | — | `02_steam_warn.png` | cuspe curto de aviso, ainda sem dano |
  | 130 | — | `03_steam_on.png` | jato ativo, partículas altas |
  | 135–200 | `move_right` para encostar | `04_steam_hit.png` (f150) | Integridade 80/100 e MU-7 afastado |
  | 260 | `dash` atravessando o jato ativo | `05_dash_through.png` | MU-7 do outro lado com Integridade **intacta** |
  | 320 | `move_right` até o piso `z` energizado | `06_electric_on.png` | faíscas, luz azul, Integridade caindo ~8/s |
  | 380 | `interact` no `T` e desligar o sistema | `07_terminal_off.png` | UI do terminal com o sistema desligado |
  | 420 | andar sobre o piso | `08_electric_off.png` | piso apagado e silencioso, Integridade estável |
- **Playtest humano (opcional):** dá para ler o ritmo do jato **antes** de tomar o primeiro dano? (é para isso que existe o `STEAM_WARN_TIME`.)

## 11. ADRs locais

### ADR-F32-001 — O piso elétrico da Estufa fica na linha do elevador
- **Contexto:** o GDD pede um obstáculo "contínuo enquanto energizado; desligável", mas a Estufa já tem 5 sistemas e o orçamento de 2 unidades não comporta um sexto ([GDD-2.5](../design/GDD.md#gdd-2-5-energia)).
- **Decisão:** o piso `z` é alimentado pelo sistema **`lift`** (a mesma linha de força do poço). No andar do Nó, o jogador quase sempre precisa liberar uma unidade para a PORTA DO NÓ — e desligar o elevador desarma o piso de quebra. Sistema nenhum é criado.
- **Consequências:** o obstáculo vira consequência de uma decisão que o jogador já ia tomar; a stretch não muda o puzzle nem o mapa. Anotar em [Ajustes](../design/GDD.md#gdd-ajustes) se for implementada.
- **Data:** 2026-09-19

### ADR-F32-002 — Telegrafia do jato (`STEAM_WARN_TIME`)
- **Contexto:** 20 de dano (1 célula inteira de Integridade) sem aviso é injusto numa fase 3/10.
- **Decisão:** `Balance.STEAM_WARN_TIME = 0.5` (s) de aviso visual/sonoro antes de cada ativação, **dentro** dos 2 s desligado (não altera o ciclo do GDD). **Entrada proposta no [GDD-P](../design/GDD.md#gdd-p)** (origem 2.6.2-E) + linha em Ajustes.
- **Consequências:** o ciclo continua 3/2 como no GDD; o jogador tem como aprender.
- **Data:** 2026-09-19

### ADR-F32-003 — `steam_hiss` e `electric_buzz` são SFX novos
- **Contexto:** não existem na lista do [SFX-PACK](../ASSETS.md#sfx-pack).
- **Decisão:** pedir as duas entradas (fontes CC0 sugeridas: Freesound "steam hiss" e "electric hum"); placeholder gerado até lá.
- **Consequências:** duas linhas novas no `ASSETS.md`.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.6.2-E, aproveitando os tiles `v` e `z` já reservados na F29 · **Próximo passo**: só depois do Bloco 4 inteiro `[x]`.

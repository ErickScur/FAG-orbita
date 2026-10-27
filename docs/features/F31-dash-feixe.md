---
id: F31
title: Dash magnético & Feixe de Manutenção
status: done
scope: stretch
block: 5
priority: P2
rubric: ["Habilidades", "Combate (não-letal)"]
depends_on: ["F12", "F13", "F22", "F23", "F29"]
unblocks: []
estimate: 1.5h
last_updated: 2026-10-27
---

# F31 — Dash magnético & Feixe de Manutenção

## 1. Contexto e objetivo

Duas habilidades que o [GDD-2.4](../design/GDD.md#gdd-2-4) marca como **iniciais** (fazem parte dos controles base) e que ficaram fora do caminho crítico da Demo ([ADR-009](../DECISIONS.md#adr-009), ordem de corte):

- **Dash magnético** (`SHIFT`): impulso horizontal de `Balance.DASH_SPEED` por `Balance.DASH_TIME`, custando `Balance.DASH_COST` de Carga, com `Balance.DASH_COOLDOWN` de recarga. Atravessa nuvens de esporos e jatos de vapor sem tomar dano.
- **Feixe de Manutenção** (`Q`): reinicia uma máquina a curta distância. Em inimigos, **DESLIGA por `Balance.BEAM_SHUTDOWN_TIME`** (4 s) — custa `Balance.BEAM_COST`. Não destrói nada.

É a tradução mecânica da regra de design mais importante do GDD: *"nenhum botão é 'atacar'. O botão de agressão do jogo é um botão de manutenção. ÓRBITA não sabe destruir, só sabe consertar e desligar."*

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.4 Controles (dash, feixe e a regra de design)](../design/GDD.md#gdd-2-4) · [GDD-2.6.1 Status base](../design/GDD.md#gdd-2-6-1-status) · [GDD-2.6.1 Habilidades](../design/GDD.md#gdd-2-6-1-habilidades) · [GDD-2.6.2 (inimigos só são desligados)](../design/GDD.md#gdd-2-6-2) · [GDD-2.6.2-D (atravessar esporos de dash)](../design/GDD.md#gdd-2-6-2-d) · [GDD-2.6.2-E (dash atravessa jato de vapor)](../design/GDD.md#gdd-2-6-2-e) · [GDD-2.9 SFX (feixe = chiado + gemido descendente)](../design/GDD.md#gdd-2-9-sfx)
- **Parâmetros:** `Balance.DASH_SPEED` (320), `Balance.DASH_TIME` (0,25), `Balance.DASH_COST` (20), `Balance.DASH_COOLDOWN` (1,0), `Balance.BEAM_COST` (25), `Balance.BEAM_SHUTDOWN_TIME` (4,0) — [GDD-P](../design/GDD.md#gdd-p). **Novo (ADR-F31-001):** `Balance.BEAM_RANGE`.
- **Jornada:** [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-009](../DECISIONS.md#adr-009) (stretch) · [ADR-010](../DECISIONS.md#adr-010) (ações `dash` e `beam` já mapeadas)
- **Features vizinhas:** [F12](F12-movimento-mu7.md), [F13](F13-integridade-carga-respawn.md) (Carga, `spend_charge`), [F22](F22-inimigo-sr3.md) (`shutdown()`, grupo `"beam_target"`), [F23](F23-esporos-status.md) (`is_dashing()`), [F32](F32-obstaculos-ambientais.md) (vapor), [F29](F29-fase-estufa.md) (onde se usa).

## 3. Critério de avaliação atendido

- **Habilidades** e **Combate (não-letal)** ([rubrica](../ENTREGAS.md#rubrica)).
- Na apresentação: o MU-7 **atravessa a nuvem de esporos num dash** sem perder Integridade (a barra de Carga cai 20) e, diante de uma SR-3, aperta `Q` — a aranha **apaga a luz, dobra as pernas e para por 4 s** com um "gemido" descendente, e o jogador passa por cima dela. Nada explode, nada morre.

## 4. Escopo

### Inclui
- Estado `DASH` no `mu7.gd`: horizontal, sem gravidade, com cooldown e custo de Carga; `is_dashing() -> bool` público (usado por [F23](F23-esporos-status.md) e [F32](F32-obstaculos-ambientais.md)).
- Feixe: `RayCast2D` frontal de `Balance.BEAM_RANGE`, atinge o primeiro nó do grupo `"beam_target"` e chama `shutdown(Balance.BEAM_SHUTDOWN_TIME)`.
- Custos e bloqueios: `GameState.spend_charge(v) -> bool` (sem Carga, a habilidade não sai e toca um som seco); bloqueio por DESCARGA (`GameState.statuses.blocks_abilities()`, [F23](F23-esporos-status.md)).
- Feedback visual: rastro do dash (`CPUParticles2D` curto) e `Line2D` do feixe por 0,1 s + luz piscando.
- Marcação de custo na barra de Carga do HUD ([GDD-2.8](../design/GDD.md#gdd-2-8-hud): "com marcação do custo da próxima habilidade") — se a [F15](F15-hud-objetivos.md) já tiver o slot.
- As duas habilidades entram em `GameState.abilities` (`&"dash"`, `&"beam"`) já no `new_game()`, porque o GDD as define como iniciais.
- Dicas contextuais na Estufa: falas curtas ao ver a primeira SR-3 e a primeira nuvem (gatilhos novos no JSON da [F29](F29-fase-estufa.md)).
- Lógica pura `scripts/core/dash_logic.gd` com testes.

### Não inclui
- Pulo duplo / Propulsor (`DOUBLE_JUMP_COST`) — upgrade das Docas, Final.
- Feixe consertando máquinas amigas, abrindo portas ou sobrecarregando terminais (Acesso Root) — Final.
- Dash vertical/diagonal ou dash no ar encadeado.
- Inimigos que reagem ao barulho do dash (V-9) — Final.

## 5. Critérios de aceite

- [x] `SHIFT` com Carga ≥ 20 dispara o dash: o MU-7 avança rápido por 0,25 s na direção que está olhando, gastando 20 de Carga.
- [x] Durante o dash o MU-7 **não** toma dano de esporos nem de vapor, e o `is_dashing()` retorna `true`.
- [x] O dash respeita o cooldown de 1 s (segundo `SHIFT` imediato não faz nada).
- [x] Com Carga < 20, o dash não acontece e toca um som de recusa; a Carga não fica negativa.
- [x] `Q` com Carga ≥ 25 dispara o feixe: a SR-3 a até `Balance.BEAM_RANGE` na frente desliga por 4 s (animação `off`, luz apagada, sem dano por contato) e volta sozinha depois.
- [x] O feixe **não** atravessa parede (o `RayCast2D` colide com `world` também) e não afeta inimigos atrás do MU-7.
- [x] Nenhum inimigo é destruído: depois dos 4 s ele volta a patrulhar.
- [x] Com DESCARGA ativa (se algum dia houver fonte), dash e feixe ficam bloqueados.
- [x] `tests/test_dash_logic.gd` verde.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/player/mu7.tscn (+ mu7.gd)
  ├─ BeamRay (RayCast2D)     position (0,-14) · target_position (±Balance.BEAM_RANGE, 0) · mask = 1 (world) | 3 (enemy)
  ├─ BeamLine (Line2D)       2 pontos, visible = false, cor ciano
  └─ DashTrail (CPUParticles2D)  emitting = false, one_shot
scripts/core/dash_logic.gd   class_name DashLogic (RefCounted, só static)
```
```gdscript
class_name DashLogic
extends RefCounted

static func can_use(charge: float, cost: float, cooldown_left: float, blocked: bool) -> bool: ...
static func dash_velocity(facing: int, speed: float) -> Vector2: ...   # Vector2(facing * speed, 0)
```
No `mu7.gd`:
- `_physics_process`: `_dash_cooldown = maxf(0.0, _dash_cooldown - delta)`; se `state == DASH`, `_dash_left -= delta`, `velocity = _dash_velocity`, sem gravidade, `move_and_slide()`; ao acabar, volta ao estado normal e inicia o cooldown.
- Entrada do dash: `Input.is_action_just_pressed("dash")` e `DashLogic.can_use(GameState.charge, Balance.DASH_COST, _dash_cooldown, GameState.statuses.blocks_abilities())` e `GameState.spend_charge(Balance.DASH_COST)`.
- Feixe: `Input.is_action_just_pressed("beam")` → mesma checagem com `Balance.BEAM_COST`; `BeamRay.force_raycast_update()`; se o colisor está no grupo `"beam_target"` e tem o método `shutdown` → `collider.shutdown(Balance.BEAM_SHUTDOWN_TIME)`; `AudioManager.play_sfx("beam")`; `BeamLine` visível por 0,1 s.
- `is_dashing() -> bool` → `state == DASH`.

### Autoloads / sinais do EventBus
- **Usa:** `GameState.spend_charge(v) -> bool` (emite `charge_changed`), `GameState.statuses.blocks_abilities()`, `GameState.abilities`.
- **Emite:** `charge_changed` (via `GameState`), `ability_unlocked(&"dash")` e `ability_unlocked(&"beam")` se optarmos por anunciá-las no `new_game()` (ver ADR-F31-002).
- SFX: `dash` e `beam` (**novos** no SFX-PACK, ver seção 11) + `sr3_shutdown` (já existe, tocado pela [F22](F22-inimigo-sr3.md)).

### Dados (`data/`)
- Gatilhos/falas novos em `data/levels/greenhouse.json` e `data/dialogue/greenhouse.json`:
```json
{ "triggers": [
  { "id": "gh_t_beam_hint", "rect": [11, 36, 2, 2], "dialogue": "gh_beam_hint", "once": true },
  { "id": "gh_t_dash_hint", "rect": [22, 36, 2, 2], "dialogue": "gh_dash_hint", "once": true }
] }
```
```json
{
  "gh_beam_hint": ["Unidade de reparo ativa. Não me reconhece.", "O feixe de manutenção (Q) desliga uma máquina por alguns segundos."],
  "gh_dash_hint": ["Impulso magnético (SHIFT) atravessa a nuvem antes que ela reaja."]
}
```

### Input actions / camadas de colisão
- `dash` (SHIFT / B) e `beam` (Q / Y) — já definidas no [ADR-010](../DECISIONS.md#adr-010); **nenhuma nova**.
- `BeamRay` mascara `world` (1) e `enemy` (3) para não atravessar parede.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-MU7](../ASSETS.md#spr-mu7) | Reuso dos frames de `walk`/`interact` (sem linha nova) | — |
| [FX-LIGHT](../ASSETS.md#fx-light) | Brilho do feixe e rastro do dash | Gradiente radial |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `dash`, `beam` (**novos**), `sr3_shutdown` (existente) | Beeps gerados |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `Balance.BEAM_RANGE` + proposta de linha no GDD-P e em Ajustes.
- [x] **Passo 2** — `tests/test_dash_logic.gd` + `scripts/core/dash_logic.gd`.
- [x] **Passo 3** — Estado `DASH` + `is_dashing()` no `mu7.gd`.
- [x] **Passo 4** — Feixe (raycast, `shutdown`, `Line2D`, SFX).
- [x] **Passo 5** — `&"dash"` e `&"beam"` em `GameState.new_game()`; marcação de custo no HUD (se houver slot).
- [x] **Passo 6** — Gatilhos e falas de dica na Estufa.
- [x] **Passo 7** — QA (roteiro da seção 10) e `/verify-gates`; commit `feat(F31): dash magnético e feixe de manutenção`.

## 10. Verificação

- **Testes (`tests/test_dash_logic.gd`):**
  - `test_can_use_with_charge_and_no_cooldown`: `can_use(100, 20, 0.0, false) == true`.
  - `test_blocked_by_cooldown`: `can_use(100, 20, 0.5, false) == false`.
  - `test_blocked_by_low_charge`: `can_use(10, 20, 0.0, false) == false`.
  - `test_blocked_by_status`: `can_use(100, 20, 0.0, true) == false`.
  - `test_exact_charge_is_enough`: `can_use(20, 20, 0.0, false) == true`.
  - `test_dash_velocity_follows_facing`: `dash_velocity(-1, 320) == Vector2(-320, 0)`.
- **Smoke:** nenhuma cena nova (a `mu7.tscn` já está listada pela F12).
- **Roteiro godot-qa** (`tests/qa/f31_dash_beam.json`) — sala `tests/qa/levels/qa_dash.txt` com `P`, uma nuvem `~` e uma SR-3 `S`:

  | Frame | Input / ação | Screenshot | Deve mostrar |
  |---|---|---|---|
  | 30 | — | `01_start.png` | Carga 100/100, nuvem à direita |
  | 60 | `move_right` + `dash` | `02_dashing.png` | MU-7 dentro da nuvem com rastro, **Integridade intacta**, Carga 80 |
  | 90 | — | `03_after_dash.png` | MU-7 do outro lado, sem ícone de CORROSÃO |
  | 100 | `dash` de novo | `04_cooldown.png` | nada acontece (cooldown), Carga ainda 80 |
  | 220 | `dash` | `05_dash_ok.png` | dash sai de novo (cooldown terminado), Carga 60 |
  | 300 | `beam` mirando a SR-3 | `06_beam.png` | linha ciano até a SR-3, Carga 35 |
  | 320 | — | `07_sr3_off.png` | SR-3 dobrada e apagada |
  | 340–420 | `move_right` por cima dela | `08_pass.png` (f420) | MU-7 passou sem tomar dano |
  | 560 | — | `09_sr3_awake.png` | SR-3 andando de novo (não foi destruída) |
- **Playtest humano (opcional):** o dash parece "magnético" (curto e seco) e não um pulo lateral? O feixe dá a sensação de **desligar**, não de atacar?

## 11. ADRs locais

### ADR-F31-001 — Alcance do feixe
- **Contexto:** o GDD diz "curta distância" sem número.
- **Decisão:** `Balance.BEAM_RANGE = 32` (px = 2 tiles ≈ 2 m pela conversão do [AJ-002](../design/GDD.md#gdd-ajustes)). **Entrada proposta no [GDD-P](../design/GDD.md#gdd-p)** (origem 2.4) + linha em Ajustes.
- **Consequências:** obriga o jogador a chegar perto — o feixe continua sendo arriscado, como manda o GDD ("o jogo pune o confronto").
- **Data:** 2026-09-19

### ADR-F31-002 — Dash e Feixe são habilidades iniciais registradas em `abilities`
- **Contexto:** o GDD-2.6.1 lista as duas como iniciais, mas o contrato do `GameState` guarda habilidades destravadas num array.
- **Decisão:** `new_game()` já inclui `&"dash"` e `&"beam"` em `abilities` (sem emitir `ability_unlocked`, que é reservado a destraves narrativos como as Garras). Se a feature for cortada, o array simplesmente não as terá e nada quebra.
- **Consequências:** o save é consistente com ou sem a stretch; a [F24](F24-garras-magneticas.md) continua sendo o único destrave com cena.
- **Data:** 2026-09-19

### ADR-F31-003 — `dash` e `beam` são SFX novos no SFX-PACK
- **Contexto:** o [GDD-2.9 SFX](../design/GDD.md#gdd-2-9-sfx) descreve os dois sons, mas a lista do [SFX-PACK](../ASSETS.md#sfx-pack) não tem as linhas.
- **Decisão:** pedir as entradas `dash` ("pulso magnético curto e agudo") e `beam` ("chiado elétrico") no `ASSETS.md`; placeholder gerado até lá.
- **Consequências:** duas linhas novas na ficha do SFX-PACK (skill `asset-request`).
- **Data:** 2026-09-19

### ADR-F31-004 — O feixe custa Carga mesmo quando erra
- **Contexto:** o GDD dá o custo (`BEAM_COST`) sem dizer se um disparo no vazio é cobrado.
- **Decisão:** `Q` com Carga suficiente sempre dispara e sempre cobra 25, acertando ou não; sem Carga
  (ou com DESCARGA) não sai e toca `ui_error`. Mesmo critério do dash.
- **Consequências:** o feixe pede chegar perto e mirar (alcance de 2 tiles), como o GDD quer; o cartão
  `tut_beam` completa ao primeiro `Q` mesmo longe da SR-3, e o disparo de teste custa 25.
- **Data:** 2026-10-27

### ADR-F31-005 — Geometria do ensino no Habitacional
- **Contexto:** o cartão de tecla fica no centro inferior da tela; no corredor do Núcleo ele cobre a
  faixa do piso. Um túnel rebaixado escondia a SR-3 (10 px de altura) atrás do cartão. Um vão aberto
  de 4–5 tiles se pula com coyote time saindo da borda (até ~87 px), então só um vão de 6 tiles
  barraria o pulo, e o dash no chão (80 px) não cobre 6.
- **Decisão:** (1) **túnel elevado** de 2 tiles de altura (colunas 70–79, piso na linha 11), com
  poços abertos de 2 colunas nas pontas; a SR-3 vira nos degraus e patrulha o túnel inteiro; a folga
  de 8 px não deixa pular os 12 px da SR-3. (2) **duto baixo** (teto de 2 tiles, colunas 84–92) sobre
  um vão de **4 tiles** (87–90): o teto corta o pulo (inclusive com coyote), o dash no chão cobre.
  A borda de decolagem é plataforma fina (84–86) e embaixo dela há degrau (coluna 84, linha 14):
  quem cai no fosso volta pela plataforma; do fundo (48 px) não se sobe do outro lado. (3) O mapa
  ganhou **uma linha** no fundo (16 linhas) para o fosso ter 3 de profundidade; o limite da câmera
  desceu 16 px e o Núcleo inteiro aparece 16 px mais alto na tela (o cartão cobre menos o MU-7).
  (4) Doca nova `hab_dock_02` depois do vão: a revisita (`revisit.spawn_dock`) nasce nela e não
  refaz o tutorial; `hab_dock_01` continua antes do túnel e recarrega a Carga entre tentativas.
- **Consequências:** `tests/test_level_core_hub.gd` prova túnel, vão, saída do fosso e revisita;
  passar a SR-3 tomando o golpe (10 de Integridade, 0,8 s de invulnerabilidade) continua possível,
  como punição, não como solução.
- **Data:** 2026-10-27

### ADR-F31-006 — Alcançabilidade com dash
- **Contexto:** o vão do tutorial só se cruza com dash; o teste de alcançabilidade reprovaria a fase.
- **Decisão:** `LevelReachability` simula **um** dash por trajetória (o cooldown de 1 s é maior que
  qualquer salto): no chão (do centro do tile e da borda), depois de pular (quadros 4/10/17/24 no
  ar) e depois de sair da borda (1/4/8). Durante o dash: sem gravidade, `DASH_SPEED` por
  `DashLogic.frames(DASH_TIME)`; ao fim, a velocidade volta a `WALK_SPEED`, igual ao `mu7.gd`. O
  perfil aceita `dash_enabled = false` para provar o que só o dash alcança.
- **Consequências:** o pulo continua sem coyote no modelo (conservador); o teste de sobreposição de
  plataformas finas roda sem dash, porque com dash o coletável é pego no ar.
- **Data:** 2026-10-27

### ADR-F31-007 — Raio do feixe rente ao chão e alvo por corpo
- **Contexto:** a SR-3 tem 10 px de altura; um raio na altura do peito (−14 px) passava por cima. A
  CX-2 é `Node2D` sem colisão. Áreas de gatilho (camada 1 padrão) bloqueariam um raio que visse áreas.
- **Decisão:** `BeamRay` a 8 px do pé, máscara `world | enemy`, **só corpos**. A CX-2 ganhou um
  `StaticBody2D` (`Mount/BeamBody`, camada enemy, máscara 0) e `BeamLogic.resolve_target` sobe até 4
  pais até achar o nó do grupo `beam_target` com `shutdown()`. O MU-7 não colide com a camada enemy.
- **Consequências:** para desligar a SR-3 do túnel é preciso subir no poço (no corredor o raio passa
  por cima); torre no teto fica fora do alcance horizontal (só a de parede baixa ou de dentro da
  escalada).
- **Data:** 2026-10-27

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.4 · **Próximo passo**: só depois do Bloco 4 inteiro `[x]` ([AGENTS §3.1](../AGENTS.md)).

### 2026-10-27 — Retomada antes da Enfermaria (orquestrador)
- **Quem**: orquestrador (feature-loop) · **Decisão do humano**: "F31 inteira antes" da F61 — a V-9
  precisa do Feixe como uma das saídas. **Escopo revisto** contra o jogo de hoje ([AJ-042](../design/GDD.md#gdd-ajustes)):
  - **Ensino** passa das falas na Estufa (seção 6, dados) para o **Habitacional do Núcleo**:
    cartões `tut_beam` e `tut_dash` (`data/tutorial.json`), cada um seguido de um obstáculo que só a
    habilidade resolve — SR-3 num túnel baixo onde não dá para pular por cima (Feixe) e um vão
    largo demais para o pulo, sobre um fosso raso com saída (Dash). Nenhuma fala da ÓRBITA.
  - **Sem marcação de custo na barra de Carga** (HUD magra, AJ-028): o custo vai para o Terminal do Chassi.
  - **Feixe** vale para todo o grupo `beam_target`: SR-3, **CX-2** (precisa de `shutdown()`), e a V-9 da F61.
  - **Dash no ar uma vez por salto**; imune a esporos e vapor (a F32 parcial da F60 já tem o vapor).
  - **DESCARGA** (AJ-040) bloqueia dash e feixe além das garras.
  - Rótulo `ability_dash` "PROPULSOR DE IMPULSO" colide com o Propulsor das Docas → "IMPULSO MAGNÉTICO";
    `ability_beam` "FEIXE DE MANUTENÇÃO".
  - `dash`/`beam` em `abilities` no `new_game()` e **também ao carregar save antigo** (ADR-F31-002).
  - Alcançabilidade (`scripts/core/level_reachability.gd`) aprende o dash: o obstáculo do tutorial depende dele.
  - SFX `dash`/`beam`: procurar o pacote Kenney Sci-Fi Sounds na máquina; se não houver, fica o
    placeholder sintetizado e a ficha segue pendente.
  - Os passos 6 (falas na Estufa) e o roteiro da seção 10 em sala própria são substituídos pelo
    roteiro `tests/qa/f31_dash_beam.json` no Núcleo.
- **Próximo passo**: subagente de implementação.


### 2026-10-27 — Dash e Feixe jogáveis, ensinados no Habitacional (implementação)
- **Quem**: agente de implementação · **O que**:
  - `scripts/core/dash_logic.gd` e `scripts/core/beam_logic.gd` (lógica pura: custo, recarga, uma vez
    no ar, duração em quadros, alvo do feixe subindo do colisor até o nó do grupo `beam_target`).
  - `mu7.gd`/`mu7.tscn`: estado `DASH` (horizontal, sem gravidade, `DASH_TIME`, recarga começa no fim,
    sai da parede para o lado oposto, uma vez por salto, renova no chão ou ao agarrar), `is_dashing()`,
    rastro `CPUParticles2D`, animação `dash`; feixe `BeamRay` (8 px do pé, `world | enemy`) com
    `Line2D` ciano e uma `PointLight2D` piscando por 0,1 s. Os dois saem só com a habilidade na lista,
    sem DESCARGA, sem entrada travada; sem Carga tocam `ui_error`. Golpe com empurrão, diálogo e
    morte cancelam o dash.
  - Imunidade: `DamageArea.dash_passable` (esporo e jato de vapor); contato de SR-3/CX-2 e calor seguem.
  - CX-2: `shutdown(duração)` com fase `SHUTDOWN` (cone e luz apagados, sem trava, volta sozinha);
    desligada pelo terminal tem prioridade; `Mount/BeamBody` na camada enemy para o raio achar a torre.
  - `GameState`: `dash` e `beam` no `new_game()` e garantidos no `from_dict` (save antigo).
  - Terminal do Chassi: "IMPULSO MAGNÉTICO 20 CARGA" e "FEIXE DE MANUTENÇÃO 25 CARGA"; habilidades em
    grade de 2 colunas (com as 4 habilidades o painel passava de 216 px), painel de 344 para 368 px.
  - Núcleo (`core_hub.txt` 88×15 → 112×16): túnel elevado com a SR-3 (`tut_beam` na coluna 66), duto
    baixo com vão de 4 tiles sobre fosso de 3 com volta pela plataforma (`tut_dash` na coluna 82),
    doca `hab_dock_02` depois do vão (nasce a revisita), saídas e comporta deslocadas para leste.
    Nenhuma fala nova (`hab_first_sr3` só mudou de lugar).
  - `LevelReachability` simula o dash (ADR-F31-006); testes novos: `test_dash_logic`, `test_beam_logic`,
    `test_dash_immunity`, CX-2 `shutdown`, `abilities` no new_game/save antigo, painel do chassi cabendo,
    e no Núcleo: túnel sem pulo, vão só com dash, saída do fosso, revisita depois do vão.
- **QA**: `tests/qa/f31_dash_beam.json` 10/10 marcos em duas rodadas (feixe desliga a SR-3 no túnel,
  Carga 75 no chassi, MU-7 passa por ela apagada, ela acorda e volta a patrulhar, dash cruza o vão,
  segundo SHIFT imediato não sai, Carga 55 no chassi, doca da revisita). `f60_hub_return.json` refeito
  para o mapa novo (9/9, duas rodadas); `f29_greenhouse.json` 27/27 (duas rodadas verdes; uma terceira,
  rodada em paralelo com `tools/gates.sh`, perdeu o trilho no começo da Estufa e não se repetiu);
  `f60_lab.json` 17/17.
- **Pendências**: SFX `dash`/`beam` seguem placeholder (pacote Kenney Sci-Fi Sounds não está na máquina);
  a linha `dash` da folha do MU-7 tem rastro magenta forte, que destoa da paleta (revisar na arte).
- **Próximo passo**: playtest do humano no Habitacional; F61 (V-9 entra no grupo `beam_target`).

### 2026-10-27 — Verificação e fechamento (orquestrador)
- **Quem**: orquestrador · **O que**: portões completos verdes por mim (805 testes, 83 cenas);
  `f31_dash_beam.json` 10/10 em duas rodadas minhas e duas do agente; capturas lidas (cartão do
  feixe com a SR-3 visível, SR-3 apagada e o MU-7 passando, dash sobre o vão, Terminal do Chassi
  com os custos). Os passos 5 (marcação no HUD) e 6 (falas na Estufa) foram substituídos pelo
  escopo revisto (custo no Terminal do Chassi; cartões no Habitacional).
- **Correção minha — arte**: a linha `dash` da folha do MU-7 tinha **rastro roxo-magenta pintado**
  (375 px, sobra de fundo de recorte que passou desde a demo porque a animação nunca tocava).
  Removidos o violeta saturado e os pontos soltos só nessa linha (as outras linhas têm ≤5 px
  assim); o rastro é a partícula ciano. Conferido no jogo depois de reimportar.
- **Mecanismo novo**: `tools/qa.sh` roda `--import` antes de abrir o jogo (~1,5 s quando nada
  mudou). Sem isso, a primeira captura depois da troca de arte mostrou a **textura antiga em cache**
  e quase aprovou o defeito como corrigido.
- **Pendências**: sons definitivos `dash`/`beam` (pacote Kenney Sci-Fi Sounds não está na máquina;
  placeholders sintetizados tocam).


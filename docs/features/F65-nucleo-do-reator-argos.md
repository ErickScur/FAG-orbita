---
id: F65
title: Fase 6 — Núcleo do Reator / batalha final ARGOS
status: done
scope: final
block: 6
priority: P0
rubric: ["Chefão de nível (Boss)", "Efeitos naturais", "Puzzle", "Inimigos", "Plataformas que se movimentam", "Luz/Sombra"]
depends_on: ["F62", "F66", "F68", "F69"]
unblocks: []
estimate: 2d
last_updated: 2026-11-21
---

# F65 — Fase 6 — Núcleo do Reator / batalha final ARGOS

## 1. Contexto e objetivo

Última fase do jogo e a batalha final (rubrica: **Chefão de nível**). "O reator chega ao limite e
sobra energia para uma última ação. Para chegar ao terminal de comando, ÓRBITA atravessa o núcleo
do reator em colapso enfrentando ARGOS" ([Jornada 8](../design/JORNADA-DO-HEROI.md#jh-8)). ARGOS é
a contenção do reator ainda cumprindo a ordem de não deixar ninguém passar: **três torres CX-2
blindadas em volta de um núcleo instável, plataformas que sobem e descem pelo calor; vence-se
sobrecarregando os 3 acopladores com o Acesso Root, sob timer de 90 s e Verão constante**
([GDD-2.6.2-I](../design/GDD.md#gdd-2-6-2-i)). Dificuldade 9/10 que cai a 0/10: depois de ARGOS,
silêncio, e a F66 assume (sala de comando → escolha → finais → créditos).

Pilares: **energia é escolha** (duas unidades para três linhas e a refrigeração; a sobrecarga
Root do console é a aposta de 20 s) e **o mundo muda de estado** (cada acoplador queimado racha o
núcleo, derruba um anel e acelera o calor).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.2-I — ARGOS](../design/GDD.md#gdd-2-6-2-i) ·
  [GDD-2.7 F6 — Núcleo do Reator](../design/GDD.md#gdd-2-7-f6) ·
  [GDD-2.6.2-B — CX-2](../design/GDD.md#gdd-2-6-2-b) ·
  [GDD-2.6.2-E/F — piso eletrificado, SUPERAQUECIMENTO, DESCARGA](../design/GDD.md#gdd-2-6-2-f) ·
  [GDD-2.6.1 — Dissipador, Acesso Root](../design/GDD.md#gdd-2-6-1-habilidades) ·
  [GDD-2.9 paleta (Reator: vermelho e branco estourado)](../design/GDD.md#gdd-2-9-paleta)
- **Parâmetros:** `Balance.ARGOS_*`, `ROOT_OVERLOAD_*`, `HEAT_SINK_DAMAGE_MULT`, `OVERHEAT_DPS`,
  `FURNACE_DPS`, `ELECTRIC_FLOOR_DPS`, `LOGS_TOTAL`, `RESEARCH_TOTAL` ([GDD-P](../design/GDD.md#gdd-p));
  ajustes [AJ-068 … AJ-071](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Etapa 8 — Batalha Final](../design/JORNADA-DO-HEROI.md#jh-8)
- **Referência viva:** [F60](F60-fase-laboratorio.md) (CX-2, calor), [F62](F62-fase-docas.md)
  (acopladores, pulo duplo), [F69](F69-upgrades-root.md) (API do Root e da sobrecarga),
  [F68](F68-status-restantes.md) (piso eletrificado), [F66](F66-finais-epilogo-creditos.md)
  (`argos_defeated`), [F45](F45-ida-e-volta.md) §6.4 (vaga 146,5)

## 3. Critério de avaliação atendido

- **Chefão de nível (Boss):** ARGOS, com três fases, timer de 90 s, falha e vitória.
- **Efeitos naturais:** Verão extremo constante (SUPERAQUECIMENTO), fornalha no núcleo, piso
  eletrificado (DESCARGA), jatos de vapor.
- **Puzzle:** linhas de energia dos acopladores (orçamento 2 para 4 sistemas) + sobrecarga Root.
- **Inimigos:** três torres blindadas que varrem a arena.
- **Plataformas que se movimentam:** plataformas térmicas que sobem com o calor do núcleo.

Na apresentação: cair na arena, ver o núcleo com as 9 lâmpadas, ligar as linhas no console,
atordoar a torre com o Feixe, `[E] SOBRECARGA ROOT`, ver o anel cair; no terceiro, o núcleo
apaga em silêncio e a sala de comando abre.

## 4. Escopo

### Inclui
- Fase `reactor_core` (sector `reactor`, prefixo `rc_`): aproximação curta + arena vertical.
- ARGOS (`scenes/bosses/argos_encounter.gd`): núcleo animado por código (folha de 8 quadros,
  3 anéis que giram e caem, 9 lâmpadas de timer, luz e brasas), timer, fases, alarme, falha,
  reset e vitória com câmera no núcleo.
- Torre blindada `Cx2Armored` (estende `Cx2`), acoplador `RootCoupler` (estende `Coupler`, sem
  editar `coupler.*`), plataforma `ThermalPlatform` (estende `MovingPlatform`).
- Hub: vaga 146,5 ligada (linha 5 do `core_hub.txt`, entrada movida de `reserved_exits`).
- Arte por IA: TIL-REACTOR, SPR-ARGOS, SPR-CX2-ARMORED, SPR-ROOT-COUPLER, SPR-THERMAL-PLATFORM.

### Não inclui
- Música própria (MUS-REACTOR pendente): a fase entra em silêncio e usa o alarme do reator.
- Remover o fluxo `FIM DA DEMO` das Docas (integração final, F64/F66).

## 4.1 O encontro no papel

**Aproximação** (corredor em colapso, ~1–2 min; checkpoint automático na entrada):

| Trecho | Exige | Prova |
|---|---|---|
| Fornalha do corredor (x 10–15) | **Dissipador** (12+3 dano/s sem ele) | — (status) |
| Jato de vapor (17,44) | dash ou espera | — |
| Vão de 6 tiles sob teto de 2 tiles, fosso de 7 (letal) | **Dash** | `test_claws_double_jump_and_dash_guard_the_arena` (`dash_enabled=false`) |
| Poço com parede magnética (x 30, linhas 27–40) | **Garras** | idem, perfil sem `magnetic_claws` |
| Bloco de 4 tiles no corredor 2 | **Propulsor** (pulo duplo) | idem, perfil sem `thruster` |
| Escada de plataformas finas → corredor 3 → doca `rc_dock_02` | — | alcançabilidade |
| Desvio: chaminé magnética + fornalha → `log_rc_01` | garras + dissipador | alcançável com tudo |

**Arena** (x 37–62, linhas 3–44; entrada por um buraco ao lado da parede magnética oeste):

| Peça | Onde | Papel |
|---|---|---|
| Núcleo ARGOS | (800, 472) px, centro da arena (AJ-078: desceu 2 tiles) | 9 lâmpadas = 90 s em ferradura **abaixo** do núcleo; fornalha 4×4 em volta |
| Calor de Verão | a arena inteira (`h` warm) | SUPERAQUECIMENTO constante (0,9/s com Dissipador) |
| Console B | plataforma oeste L1 (39,31) | primeira escolha de energia |
| Console A | piso oeste L0 (39,44) | segunda escolha |
| Acoplador 2 (`line_2`) | poleiro oeste (42,27), 3 tiles acima de L1 | torre 1 (parede, 38,26) varre o poleiro |
| Acoplador 1 (`line_1`) | piso leste (60,44) | torre 3 (parede, 62,44) varre o piso |
| Acoplador 3 (`line_3`) | plataforma alta R2 (56,8), só pela parede magnética leste | torre 2 (teto, 55,5) acima dele; Feixe só no pulo |
| Plataformas térmicas | x 46 e 52, sobem 9 tiles, ciclo 6 s, defasadas meio ciclo | levam do piso às plataformas L1/R1 |
| Piso eletrificado | x 44–54 | DESCARGA trava Feixe, dash e Propulsor |
| Ilhas frias (`coolant`) | L0 e R1 | descanso do calor enquanto a refrigeração tiver energia |
| Dado `data_rc_01` | (50,5), 3 tiles acima e à esquerda de R2 | pulo duplo debaixo da torre 2, com o relógio correndo |
| Célula `cell_rc_02` | R1 (59,31) | 40 de Carga, uma vez |

**Terminal `reactor_core`, orçamento 2, inicial `[coolant]`** (mudo: título, objetivo, orçamento):

| id | Nome | Custo | Ligado | Desligado | Onde se vê |
|---|---|:-:|---|---|---|
| `coolant` | REFRIGERAÇÃO DE EMERGÊNCIA | 1 | ilhas frias em L0 e R1 | somem | L0 (console A), R1 |
| `line_1` | LINHA DO ACOPLADOR 1 | 1 | acoplador do piso aceso (ciano) | apagado | piso leste |
| `line_2` | LINHA DO ACOPLADOR 2 | 1 | acoplador oeste aceso | apagado | poleiro oeste (ao lado do console B) |
| `line_3` | LINHA DO ACOPLADOR 3 | 1 | acoplador do alto aceso | apagado | R2 |

As torres e o piso **não** estão no terminal (blindados; AJ-069).

**Sequência que resolve** (duas trocas): B: refrigeração fora, linhas 1 e 2 → acoplador 2 (Feixe
na torre 1, `[E]`, 1,5 s) → piso leste pelas plataformas → acoplador 1 (Feixe na torre 3) →
A: linha 2 fora (o acoplador já queimado não precisa dela), linha 3 → plataformas → R1 → parede
magnética → R2 → pulo + Feixe na torre 2 → acoplador 3 → ARGOS apaga.
**Atalho Root:** no console, `[Q]` dá +1 unidade por 20 s (25 de Carga): as três linhas ao mesmo
tempo, mas a última ligada cai quando a sobrecarga acaba.

**Por que a ingênua falha:** "ligar as três linhas" não cabe (2 unidades); manter a refrigeração
deixa uma linha só por vez; ir direto ao acoplador sem linha mostra `ACOPLADOR SEM ENERGIA`;
sobrecarregar debaixo do cone sem o Feixe: o pulso derruba (15 + DESCARGA) e a carga cancela.

**Fases:** cada acoplador queimado racha o núcleo (quadros 4, 5), derruba um anel, dá tremor e
acelera em 25 % o ciclo das plataformas e a varredura das torres. O alarme toca a cada 2 s e a
0,6 s nos últimos 20 s, quando a arena pulsa em vermelho; uma lâmpada apaga a cada 10 s.

**Falha:** tempo zero → o núcleo estoura (clarão, tremor) e o chassi cai pelo fluxo normal
(`SINAL DO CHASSI PERDIDO`, −3 % de reator). Morte por qualquer causa também. Ao reaparecer
(doca `rc_dock_02`), o encontro volta limpo: relógio cheio, acopladores intactos, energia inicial,
torres no ritmo base. Se o terminal estiver aberto no zero, o estouro espera ele fechar.

**Vitória:** o MU-7 trava, a câmera vai ao núcleo, as lâmpadas apagam uma a uma, o núcleo racha,
escurece e morre em 4 s; torres, piso e calor desligam, plataformas param, a música e o alarme
cessam; 3 s de silêncio; `reactor` entra em `sectors_restored`, flag `argos_defeated`, save, e
`EventBus.argos_defeated` leva à sala de comando (F66). Quem entrar no Reator depois disso vai
direto para a sala.

## 5. Critérios de aceite

- [x] Aproximação exige dash, garras e pulo duplo (provado no modelo) e o Dissipador (calor)
- [x] Arena com núcleo, 3 torres blindadas, plataformas térmicas, Verão constante, piso eletrificado
- [x] Timer de 90 s diegético (lâmpadas, alarme, vermelho), sem HUD nova
- [x] Acopladores Root: linha + Acesso Root + 1,5 s perto; queimam e ficam
- [x] Falha por tempo e por morte voltam à doca com o encontro limpo
- [x] Vitória: ARGOS apaga, silêncio, `argos_defeated` → sala de comando; não emite `demo_completed`
- [x] Hub: vaga 146,5 ligada; volta ao hub pelo portal `rc_exit_core`
- [x] +1 log, +1 dado (`LOGS_TOTAL`/`RESEARCH_TOTAL` 11)
- [x] Portões verdes; sem comentários; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/argos_logic.gd              ArgosLogic (puro): estado, relógio, fases, ciclo térmico, lâmpadas, alarme
scenes/bosses/argos_encounter.gd         ArgosEncounter: lê o bloco "argos" da fase, monta o núcleo, roda a luta
scenes/enemies/cx2_armored.tscn (+ .gd)  Cx2Armored extends Cx2: arte blindada, Feixe só 2,5 s, varredura escalável
scenes/world/root_coupler.tscn (+ .gd)   RootCoupler extends Coupler: painel [E], carga 1,5 s, queima
scenes/world/thermal_platform.tscn (+gd) ThermalPlatform extends MovingPlatform: posição pelo ciclo térmico
scenes/levels/reactor_core.tscn          level_base + nó Argos
```
- As peças entram pelo `"scene"` do JSON (`X`, `A`, `m`), sem letra nova na legenda.
- API pública do encontro (QA/testes): `state_name()`, `time_left()`, `phase()`,
  `overloaded_count()`, `lit_segments()`, `heat_clock()`, `coupler_fed(id)`,
  `coupler_overloaded(id)`, `overload_coupler(id)`, `reset_encounter()`; sinais
  `encounter_started`, `phase_changed`, `encounter_failed`, `encounter_reset`, `defeated`.

### Autoloads / sinais do EventBus
- Usa `argos_defeated` (F66), `player_died`, `player_respawned`. Nenhum sinal novo.
- `GameState.flags["argos_defeated"]`, `sectors_restored += reactor` na vitória.

### Dados (`data/`)
- `data/levels/reactor_core.{txt,json}` (64 × 52; bloco `"argos"`: terminal, núcleo, arena, grupos)
- `data/energy/reactor_core.json`, `data/logs/reactor_core.json` (`log_rc_01`),
  `data/dialogue/reactor_core.json` (`rc_enter`, `rc_argos`), `data/objectives.json` (`obj_reactor`)
- `data/levels/core_hub.{txt,json}`: `E` em 146,5 e `core_hub_exit_reactor` em `entities`

### Input actions / camadas de colisão
- Painel do acoplador na camada 4 (`interactable`); sem input novo.

## 7. Assets necessários

| Asset id | Uso | Status |
|---|---|---|
| TIL-REACTOR | tileset do Reator | integrado (IA) |
| SPR-ARGOS | núcleo, 8 quadros 64×64 | integrado (IA) |
| SPR-CX2-ARMORED | torre blindada, 8 quadros 32×32 | integrado (IA) |
| SPR-ROOT-COUPLER | acoplador Root, 4 estados | integrado (IA) |
| SPR-THERMAL-PLATFORM | plataforma térmica, 4 quadros 48×16 | integrado (IA) |
| FX de calor/brasas | partículas por código (`Embers`, `ambient_motes`, brilho da fornalha) | código |
| MUS-REACTOR | trilha do Reator | pendente (silêncio + alarme) |

## 8. 🧑 Ação humana

Nenhuma. Pendente: MUS-REACTOR.

## 9. Plano de execução

- [x] **Passo 1** — GDD-P + AJ-068..071; Balance
- [x] **Passo 2** — Arte por IA em paralelo com o mapa
- [x] **Passo 3** — Lógica pura, torre, acoplador, plataforma, encontro
- [x] **Passo 4** — Mapa, JSONs, textos, hub
- [x] **Passo 5** — Testes, portões, QA com marcos, checklist §4.7, docs

## 10. Verificação

- **Testes:** `test_argos_logic.gd` (timer, fases, reset, vitória que não volta, lâmpadas, alarme,
  ciclo térmico), `test_argos_scenes.gd` (acoplador: linha + Root, carga, cancela, queima e fica;
  torre: 2,5 s e arte; plataforma; encontro: reset e vitória com torres/piso/calor/plataformas),
  `test_level_reactor.gd` (contagens, entrada F45, peças, alcançabilidade, dash/garras/pulo duplo
  guardam a arena, garras para o acoplador do alto, energia: troca ou Root), mais as listas de
  `test_light_crowding`, `test_light_darkness`, `test_level_tileset`, `test_arrival_route`,
  `test_objectives`, `test_balance`, `test_dialogue_*`, `test_level_core_hub`.
- **Smoke:** `cx2_armored`, `root_coupler`, `thermal_platform`, `reactor_core`.
- **Roteiros** (gerador `tests/qa/gen/f65.py`):
  - `f65_reactor.json` — hub com Memória + Root → comporta ROOT → portal → fala → vão com dash →
    bloco com pulo duplo → doca → queda na arena → console B (linhas 1 e 2) → pulo duplo ao poleiro →
    Feixe na torre → `[E]` acoplador 2 → piso leste: Feixe + acoplador 1 → console A (linha 3) →
    R2: pulo + Feixe + acoplador 3 → ARGOS apaga → sala de comando. 31 marcos.
  - `f65_falha_tempo.json` — 90 s na ilha fria: 5 e 2 lâmpadas, estouro, volta à doca limpo, recomeça.
  - `f65_morte.json` — linha e acoplador mudados, morte, volta limpa (fase 1, energia inicial).
  - `f65_tour.json` — visita por teleporte de cada trecho e das três fases.
- **Playtest humano:** os 90 s apertam sem ser injustos? O Feixe na torre do alto (no pulo) é
  legível? As lâmpadas e o alarme bastam como relógio? 9/10?

## 11. ADRs locais

### ADR-F65-001 — O encontro é um nó da fase que lê o bloco `"argos"` do JSON
- **Contexto:** o núcleo não é entidade de grade (64×64, sem colisão, não interativo) e a luta
  precisa de posições (núcleo, arena) e grupos.
- **Decisão:** `ArgosEncounter` é filho da cena da fase, configura-se em `call_deferred` (a fase
  ainda não está montada no `_ready` do filho) e acha torres, piso, calor e acopladores por grupo,
  só entre os descendentes da fase. Torres, acopladores e plataformas entram pela letra existente
  com `"scene"` no JSON, como o Nó do setor.
- **Data:** 2026-11-21.

### ADR-F65-002 — Torres e piso fora do terminal; acoplador sem custo de Carga
- **Contexto:** a ideia era um sistema `ARGOS` travado e ligado no terminal; o `EnergyGrid` não liga
  sistema travado (nem no estado inicial). E três sobrecargas a 25 de Carga mais Feixe e pulo
  duplo passavam de 100.
- **Decisão:** torres e piso são do encontro (ligados até a vitória, `system_id: ""`); o terminal
  tem só refrigeração e as três linhas (orçamento 2). A sobrecarga no acoplador não gasta Carga
  (AJ-069); a do console continua a da F69.
- **Data:** 2026-11-21.

### ADR-F65-003 — Falha pelo fluxo de morte, não por tela própria
- **Contexto:** "tempo zero = falha → volta à doca com o encontro limpo".
- **Decisão:** no zero o encontro aplica dano letal; o `SINAL DO CHASSI PERDIDO` e o reaparecimento
  são os de sempre, e o encontro se limpa no `player_respawned`. Morte por outra causa no meio da
  luta faz o mesmo. Custo: −3 % de reator, como toda morte.
- **Data:** 2026-11-21.

### ADR-F65-004 — `reactor` em `sectors_restored` sem `sector_restored`
- **Contexto:** o mapa (F67) lê `sectors_restored`, mas o sinal `sector_restored` dispara a
  cutscene de religamento, +15 % de reator e o `SectorNarrative` (que emitiria `demo_completed`).
- **Decisão:** a vitória acrescenta `reactor` direto no `GameState` e salva; nada de cutscene F42.
- **Data:** 2026-11-21.

### ADR-F65-005 — Propulsor provado na aproximação; na arena ele encurta
- **Contexto:** o modelo de alcançabilidade não simula pulo duplo saindo de plataforma móvel, e a
  arena aberta deixa tudo alcançável caindo de cima.
- **Decisão:** o pulo duplo é obrigatório no bloco de 4 tiles que guarda a arena (provado) e, na
  arena, é o caminho de L1 ao poleiro do acoplador 2 e o único até o dado do alto. Garras são
  provadas para o acoplador do alto; o Feixe é exigido pela carga de 1,5 s dentro do cone.
- **Data:** 2026-11-21.

## 12. Log de evolução

### 2026-11-21 — Feature criada e construída (agente de fase/chefe, worktree)
- **Quem**: agente F65.
- **O que**: puzzle e encontro no papel; GDD-P + AJ-068..071 → `Balance` (`ARGOS_*`, totais 11/11);
  `ArgosLogic`; `Cx2Armored`, `RootCoupler`, `ThermalPlatform`, `ArgosEncounter`; fase
  `reactor_core` (64×52) com JSONs de fase, energia, log, falas e objetivo; hub 146,5 ligado.
- **Arte por IA** (Codex, 2 variações cada, nenhuma regerada): TIL-REACTOR (1ª), SPR-ARGOS (1ª),
  SPR-CX2-ARMORED (1ª), folha de máquinas do Reator (2ª: acoplador Root + plataforma térmica).
  Montagem por script (chave por magentice, redução por média pré-multiplicada, alfa binário).
- **Ajustes vindos do modelo e do QA:**
  - sistema travado não liga nem no estado inicial → torres/piso saíram do terminal (ADR-F65-002);
  - fosso do vão de 3 tiles: o modelo conta o fundo do mapa como chão e o pulo duplo saía dele →
    fosso de 7 (mapa 48 → 52 linhas);
  - a parede magnética leste não subia com R2 encostado (chaminé de 2 tiles) → R2 recuou 1 coluna;
  - o bloco da torre 1 virou degrau para o poleiro; torres 1 e 3 viraram de parede, na altura do
    peito do MU-7 (o Feixe é horizontal a −8 px do pé), e a 2 desceu para um bloco a 2 tiles de R2;
  - 15 luzes numa janela → 2 lâmpadas a menos e piso eletrificado de 13 para 11 placas;
  - a câmera não mostrava o núcleo na vitória → câmera própria que vai ao núcleo;
  - Carga acabava antes do 3º Feixe no roteiro → célula em R1; o roteiro recarrega na doca.
- **QA:** `f65_reactor` 31/31, `f65_falha_tempo` 13/13, `f65_morte` 13/13, `f65_tour` 8/8.
- **Checklist §4.7:** ver relatório; portões completos verdes.

### 2026-11-21 — Integração sobre a `main` com a F64 (Memória) e fim de jogo definitivo
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: diff da F65 (feito sobre
  `99317ee`) aplicado sobre `1d8dea1` com 19 conflitos, quase todos "os dois lados acrescentaram"
  (skills, CLAUDE.md, ASSETS, GDD-P, `balance.gd`, objetivos, `scenes.txt`, testes de contagem).
- **Reconciliações:**
  - totais finais **`LOGS_TOTAL` 13 / `RESEARCH_TOTAL` 12** (GDD-P → `Balance`; AJ-071 corrigido
    para 12→13 e 11→12); soma por setor conferida por `test_campaign_has_eight_long_logs` (13) e
    `test_the_campaign_has_exactly_eight_research_data` (12, agora com o JSON do Reator);
  - hub: a vaga 146,5 virou `core_hub_exit_reactor` em `entities` e o bloco `reserved_exits`
    saiu (as três vagas foram consumidas); 6 portais; revisita termina em `memory`;
  - objetivos: `obj_memory`, `obj_core_reactor` ("Religar o Reator", no hub) e `obj_reactor`
    ("Desligar o ARGOS", na fase) convivem;
  - `test_arrival_route`: um mapa só, `SECTOR_OF_LEVEL` (`memory_core` → `memory`,
    `reactor_core` → `reactor`); `test_light_crowding` cobre Memória e Reator;
  - contagens reais: 36 sequências e 13 logs no `DialogueManager`;
  - **`RootCoupler` x `Coupler` da F63**: a F63 deu ao `Coupler` um `_actor` (acoplador de
    segurar) e a subclasse da F65 declarava o mesmo nome → `Parse Error: The member "_actor" already
    exists in parent class` derrubava `test_argos_scenes`. O da F65 virou `_charger`; o soquete e os
    pips do acoplador de segurar ficam desligados/escondidos no acoplador Root.
  - `f65.py`: o save do hub ganhou as flags da Memória (`dlg_core_return_memory` e cia., lição F64)
    e o objetivo `obj_core_reactor`; roteiro novo `f65_mapa_fim` (mapa depois de ARGOS:
    `RELIGADOS 7/7`, os seis setores `restored`).
- **Fim de jogo**: `FIM DA DEMO` removido (ADR-F66-009, AJ-075); o único fim de vitória é este.
- **QA:** `f65_reactor` 31/31, `f65_falha_tempo` 13/13, `f65_morte` 13/13, `f65_tour` 8/8,
  `f65_mapa_fim` 9/9; `f64_memory` 31/31, `f64_hub_volta` 10/10, `f64_hub_entrada` 8/8, `f64_morte`
  13/13, `f62_docks` 41/41, `f62_hub_docks` 9/9, `f63_serralheiro` 25/25, `f66_semeadura` 23/23,
  `f66_transmissao` 22/22, `f69_c_comporta_reator` 6/6, `f67_map_hub` 23/23, `f45_c_ala_selada` 6/6.

### 2026-11-21 — Revisão de design: relógio legível, fala fora do caminho, dificuldade (grupo B1)
- **P2 — relógio de 90 s:** as 9 lâmpadas eram pontos de 2–3 px que liam como brasas. Agora são
  `ArgosTimerLamps` (`scenes/bosses/argos_timer_lamps.gd`): lâmpada de 6 px num soquete de 10 px,
  brilho por `Sprite2D` aditivo (nenhuma `PointLight2D` nova, limite de luzes intacto), clarão branco
  quando uma apaga. No núcleo ficam numa **ferradura de 200° abaixo** dele (nenhuma no alto, perto da
  HUD), e o núcleo desceu 2 tiles (`core` 440 → 472, fornalha `rc_heat_core` 26 → 28): do alto da
  plataforma térmica o centro do núcleo fica a ~52 px do topo e as lâmpadas abaixo de 40 px. Duas
  **cópias do mostrador** em placa com borda âmbar ficam no piso L0 (`argos.gauges`: x 680 e 920,
  3,5 tiles acima do piso): do console A, da ilha fria e do acoplador 1 um painel inteiro aparece
  (`test_every_floor_station_sees_a_whole_timer_gauge`). Nos últimos 20 s (`ArgosLogic.is_urgent`)
  as lâmpadas acesas piscam em vermelho e a **vinheta da fase pulsa vermelha** a cada alarme
  (`Vignette.apply`, sem camada nova); volta ao normal no reset e na vitória.
- **P3 — texto empilhado:** `rc_argos` dispara no pé da escada da aproximação (gatilho `rc_t_argos`,
  x 5–10, linhas 19–25), ~28 tiles antes da `rc_dock_02`: termina antes do `BACKUP SALVO`
  (`test_the_reactor_line_plays_before_the_dock`). O `_start` do encontro ainda chama a fala, mas
  `has_played` a pula; só roteiro que teleporta direto para a doca a vê na arena. O Terminal de
  Distribuição segura a fala ambiente enquanto aberto (`DialogueManager.hold_ambient`): a caixa
  some e o relógio da fala para; ao fechar, ela volta de onde parou (`tests/test_dialogue_hold.gd`).
- **P5 — ARGOS fácil demais? Não mexi em número.** O roteiro vence em ~15 s porque teleporta e
  conhece tudo. A solução pede: 1ª leitura do console B (mudo, o relógio corre: ~5–8 s), Feixe na
  torre 1 + 1,5 s de sobrecarga no poleiro (~5 s), descer pelas plataformas (ciclo de 6 s, até 6 s
  de espera) e atravessar o piso eletrificado ou contorná-lo (~6–8 s), Feixe na torre 3 + 1,5 s
  (~4 s), voltar ao console A e trocar as linhas (~6–8 s), subir pela plataforma, R1 e a parede
  magnética até R2 (~22 linhas, ~8–10 s) e acertar o Feixe no pulo sob a torre 2 (~4 s). Soma de um
  humano que **já sabe** a solução: ~45–60 s, com SUPERAQUECIMENTO de 0,9/s o tempo todo (54 de
  Integridade em 60 s, mais 15 por pulso de torre). A primeira tentativa tende a falhar (descobrir a
  troca de linhas e a parede do leste), e a segunda fecha com folga curta: é o 9/10 da curva sem
  ser injusto. Endurecer (ex.: 75 s ou torres mais rápidas) tiraria a folga de quem aprende; fica
  para o playtest humano decidir, com `ARGOS_TIME` e `ARGOS_PHASE_SPEEDUP` como alavancas.
- **Testes:** `tests/test_boss_framing.gd` (ferradura, painéis do piso, urgência, núcleo abaixo da
  HUD do alto da plataforma), `tests/test_dialogue_hold.gd`.
- **QA:** `f65_falha_tempo` com marcos novos (`painel_do_piso_na_metade` = 5, `ultimos_20_s_em_vermelho`,
  `painel_leste_com_duas` = 2) e capturas `03_alarme_vermelho`/`03b_alarme_pulso` (borda vermelha e
  lâmpadas vermelhas no painel do piso); `f65_tour` passa pela escada (`fala_do_argos_na_escada`,
  `fala_acabou_antes_da_doca`, `arena_sem_fala_empilhada`); `f65_reactor` ganha
  `terminal_sem_legenda_por_cima`.

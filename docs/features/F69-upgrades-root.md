---
id: F69
title: Upgrades permanentes (Núcleo de Capacitor, Placa de Blindagem) e mecanismo do Acesso Root
status: done
scope: final
block: 8
priority: P0
rubric: ["Nível (progressão)", "Recompensas"]
depends_on: ["F20", "F27", "F45", "F67", "F44", "F37"]
unblocks: ["F62", "F64", "F65"]
estimate: 1d
last_updated: 2026-11-21
---

# F69 — Upgrades permanentes e Acesso Root

## 1. Contexto e objetivo

O jogo final precisa de **progressão permanente do chassi** e de **recompensa por explorar**: oito
upgrades escondidos (4 Núcleos de Capacitor, +25 de Carga máxima; 4 Placas de Blindagem, +25 de
Integridade máxima) que pedem **volta** a setores antigos com uma habilidade nova (metroidvania,
possível graças à F45), e o **Acesso Root**, a chave do ato final: abre portas seladas há 200
anos e sobrecarrega qualquer Terminal de Distribuição. Serve aos pilares de exploração e de
energia (GDD-2.2): o setor velho fica mais fácil (GDD-2.7, "upgrade faz o conteúdo antigo ficar
fácil") e cada volta tem algo visível para buscar.

Esta feature entrega o **mecanismo** do Root (habilidade, portas, comporta do Reator, mapa,
sobrecarga). A fase que dá o Root (Núcleo de Memória) é da F64; a ARGOS que usa a sobrecarga é da
F65.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.3 Itens](../design/GDD.md#gdd-2-6-3) (Capacitor/Placa, 4 de cada, escondidos),
  [GDD-2.6.1 Habilidades](../design/GDD.md#gdd-2-6-1-habilidades) (Acesso Root), [GDD-2.7 curva](../design/GDD.md#gdd-2-7),
  [GDD-2.8 HUD](../design/GDD.md#gdd-2-8), [GDD-2.6.2-I ARGOS](../design/GDD.md#gdd-2-6-2-i).
- **Parâmetros:** `Balance.CAPACITOR_BONUS`, `ARMOR_PLATE_BONUS`, `CAPACITORS_TOTAL`,
  `ARMOR_PLATES_TOTAL`, `INTEGRITY_PER_CELL`, `ROOT_OVERLOAD_UNITS`, `ROOT_OVERLOAD_TIME`,
  `ROOT_OVERLOAD_COST` ([GDD-P](../design/GDD.md#gdd-p)); ajustes AJ-065, AJ-066, AJ-067.
- **Jornada:** etapa 7 — Recompensa: "acesso total, inclusive às áreas seladas há 200 anos".
- **Features:** [F45](F45-ida-e-volta.md) §6.4 (comporta `door_reactor` 143,5), [F67](F67-mapa-estacao.md)
  (pendência `requires_ability`), [F27](F27-area-secreta.md), [F43](F43-estufa-viva.md),
  [F44](F44-terminal-do-chassi.md), [F37](F37-legibilidade-hud.md).

## 3. Critério de avaliação atendido

- **Nível (progressão):** a Integridade e a Carga máximas crescem de forma permanente e visível
  (célula nova na HUD, barra de Carga mais longa, contagem `x/4` no Terminal do Chassi), e o
  Acesso Root abre regiões que estavam seladas desde a primeira visita.
- **Recompensas:** explorar fora da rota (sala secreta, parede magnética, porta ROOT) paga com um
  upgrade permanente; o aviso curto mostra o ganho e a contagem.

Como o avaliador vê: no Núcleo Central, de volta da Estufa com as garras, a parede magnética que
estava ao lado da doca desde o tutorial leva a um cofre com uma Placa; a HUD ganha a 5ª célula.

## 4. Escopo

### Inclui
- Coletável **Placa de Blindagem** (`B` no ASCII, `kind` `armor_plate`), arte gerada (linha 6 do
  `pickups_sheet.png`); o Capacitor passa a **encher** a Carga ao ser pego.
- 3 Placas novas nos setores velhos (tabela abaixo); os 3 Capacitores dos setores velhos ficam
  onde a F27/F60/F61 os puseram.
- Habilidade `root_access`; `Door.requires_ability` (porta ROOT com placa desenhada e convite);
  comporta do Reator exige Memória **e** Root; `station.json` com `requires_ability`.
- Sobrecarga ROOT: lógica pura em `EnergyGrid`, API em `EnergyNetwork`/`DistributionTerminal`,
  tecla no Terminal de Distribuição.
- HUD de células por Integridade máxima no mesmo espaço; barra de Carga cresce por capacitor;
  Terminal do Chassi com `x/4` de capacitores e placas.
- Modelo de alcançabilidade com **perfil de habilidades** (garras, Núcleo Aquecido, Root).

### Não inclui
- A fase que dá o Root (F64) nem a ARGOS (F65).
- O 4º Capacitor é o `capacitor_dk_01` da F62. A 4ª Placa entrou na integração com a F63.
- Som próprio de upgrade (usa `pickup` + `power_on`; trilha nova fora do escopo desta rodada).

### Onde está cada upgrade

| Item | id | Setor | Célula (col,lin) | Rota até ele | Exige (habilidade de) |
|---|---|---|---|---|---|
| Placa de Blindagem | `plate_core_01` | Núcleo Central | 99,4 | da doca `hab_dock_02` (95,11) pular e agarrar a parede magnética (col 92), subir a chaminé (cols 93-94) até o cofre acima do corredor | Garras Magnéticas (Estufa) |
| Placa de Blindagem | `plate_gh_01` | Estufa | 26,55 | sala de entrada: patamar da trepadeira → `====` (13-16,56) → laje nova (17-19,56) → porta ROOT `gh_root_door` (20,55) → cofre (21-28, 53-55) | Acesso Root (Memória) |
| Placa de Blindagem | `plate_lab_01` | Laboratório | 33,15 | sala secreta do sótão quente (F60) → porta ROOT `lab_root_door` (37,15) no fundo dela → cofre (32-36, 13-15) | Acesso Root (Memória) |
| Núcleo de Capacitor | `capacitor_gh_01` | Estufa | 2,51 | parede falsa `gh_secret_01` (F43) | — (segredo) |
| Núcleo de Capacitor | `capacitor_lab_01` | Laboratório | 41,15 | sótão quente + parede falsa `lab_secret_01` (F60) | — (segredo) |
| Núcleo de Capacitor | `capacitor_inf_01` | Enfermaria | 67,5 | desvio gelado: parede de gelo + parede falsa `inf_secret_01` (F61) | Núcleo Aquecido (da própria Enfermaria) |
| Núcleo de Capacitor | `capacitor_dk_01` | Docas | 81,20 | F62 | — (alcançável com todas as habilidades) |
| Placa de Blindagem | `plate_dk_01` | Docas | 32,40 | hangar: piso oeste, junto do console A → porta ROOT `dk_root_door` (35,40) na parede oeste → cofre (31-34, 38-40) | Acesso Root (Memória) |

Provas: `tests/test_level_upgrades.gd` (cada um alcançável com todas as habilidades e **inalcançável
sem a habilidade da tabela**; 4 placas e 4 capacitores nos mapas; placas novas pedem habilidade de
setor posterior; ≥ 3 atrás de ROOT, uma porta ROOT em Estufa, Laboratório e Docas; Reator fechado
sem Root; Nó da Estufa, do Laboratório e das Docas alcançáveis sem Root).

## 5. Critérios de aceite

- [x] Pegar Capacitor: +25 Carga máxima, enche a Carga, salvo, não reaparece; aviso `CARGA MÁXIMA +25  n/4`.
- [x] Pegar Placa: +25 Integridade máxima, enche a Integridade, 5ª..8ª célula na HUD sem crescer o espaço.
- [x] Terminal do Chassi mostra capacitores e placas `x/4` e o Acesso Root na lista de habilidades.
- [x] Porta ROOT: sem Root `[E] PORTA SELADA` → interagir mostra `SELADA - ACESSO ROOT`; com Root
  `[E] ACESSO ROOT` abre e fica aberta (flag no save).
- [x] `door_reactor` exige Memória religada **e** Root; o mapa mostra `SELADO - EXIGE ACESSO ROOT`.
- [x] Sobrecarga ROOT no Terminal de Distribuição: `[Q]`, +1 unidade por 20 s, 25 de Carga; ao fim
  desliga o último sistema ligado.
- [x] Teste de alcançabilidade com perfil de habilidades.
- [x] Portões do `/CLAUDE.md` §6 verdes; sem comentários; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/upgrade_rules.gd       UpgradeRules (contagens, células, barra, flag de porta ROOT)
scenes/world/root_plate.gd          RootPlate: placa "ROOT" pixel a pixel + LED (unshaded)
scenes/world/door.gd                requires_ability, door_id, painel Interactable, try_root_access()
scenes/world/collectible.gd         armor_plate; capacitor via GameState.install_capacitor()
scripts/core/energy_grid.gd         overload_units/overload_left, start/tick/end_overload, effective_budget
scenes/world/energy_network.gd      can_overload/overload/end_overload/is_overloaded + signal overload_changed
scenes/world/distribution_terminal.gd  can_overload()/overload()/is_overloaded()
scenes/ui/energy_terminal_ui.gd     [Q] SOBRECARGA ROOT, medidor com a unidade extra em violeta
scenes/ui/hud.gd(.tscn)             células por Integridade máx. em 72 px; barra de Carga 60→72 px
scenes/ui/chassis_menu.gd(.tscn)    ícone + x/4 de placas e capacitores
scripts/core/station_map_model.gd   requires_ability, missing_ability, sealed_by_ability_only
scripts/core/level_reachability.gd  perfil "abilities": M/I/porta ROOT viram parede sem a habilidade
```

### API do Acesso Root (para F64/F65)
- **Dar o Root:** `GameState.unlock_ability(&"root_access")` (ou `UpgradeRules.ROOT_ABILITY`).
  Pelo log que fecha a Memória: `"unlock_ability": "root_access"` no JSON do log (mesmo mecanismo
  das garras/dissipador/núcleo aquecido). Emite `EventBus.ability_unlocked`; portas ROOT e o mapa
  atualizam sozinhos.
- **Perguntar:** `GameState.has_ability(&"root_access")`.
- **Porta selada ROOT numa fase nova:** `|` no ASCII com `{"id": "<id>", "requires_ability": "root_access"}`
  no JSON (pode somar `sealed_until_sector`). Estado: `GameState.is_root_door_open(id)`.
- **Sobrecarga (acopladores da ARGOS):**
  - `EnergyNetwork.can_overload(terminal_id) -> bool` / `overload(terminal_id) -> bool` /
    `end_overload(terminal_id)` / `is_overloaded(terminal_id)` / `overload_left(terminal_id)` e o
    sinal `overload_changed(terminal_id, active)`.
  - Atalho no console: `DistributionTerminal.can_overload()` / `overload()` / `is_overloaded()`.
  - Lógica pura: `EnergyGrid.start_overload(units, duration)`, `tick_overload(delta)`,
    `end_overload() -> Array[StringName]` (sistemas desligados), `effective_budget()`.
  - Números: `Balance.ROOT_OVERLOAD_UNITS` (1), `ROOT_OVERLOAD_TIME` (20 s), `ROOT_OVERLOAD_COST` (25).
    A F65 pode registrar números próprios (AJ-068..071) se o acoplador pedir outro tempo.

### Autoloads / sinais do EventBus
- `GameState`: `install_capacitor()`, `expand_integrity_max(v)`, `capacitors_installed()`,
  `plates_installed()`, `is_root_door_open(id)`, `open_root_door(id)`. Contagens derivam de
  `charge_max`/`integrity_max` (o save não muda de formato).
- Nenhum sinal novo no EventBus.

### Dados (`data/`)
- `data/levels/{core_hub,greenhouse,lab}.{txt,json}` (cofres, `B`, portas ROOT, `requires_ability`
  no `door_reactor`), `data/levels/test_room.txt` (`B`), `data/map/station.json`,
  `data/ui/station_map.json` (`sealed_root_hint`), `data/hud_texts.json`, `data/ui/chassis_menu.json`.

### Input actions / camadas de colisão
- Sobrecarga usa a ação `beam` (Q) só dentro do Terminal de Distribuição; o painel da porta ROOT é
  `Interactable` na camada 4 (`interactable`).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| SPR-PICKUPS (linha 6) | Placa de Blindagem, 4 quadros 16×16 | `assets/placeholder/sprites/pickups/pickups_sheet.png` (64×96) |
| — | Placa "ROOT" da porta e LED | desenhada em código (`RootPlate`) |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] Números no GDD-P + AJ-065..067 → `Balance`.
- [x] `UpgradeRules`, `GameState`, `PickupRules`, `Collectible`, legenda `B`.
- [x] Porta ROOT (`Door` + `RootPlate`), comporta do Reator, mapa.
- [x] Sobrecarga (grade, rede, terminal, UI).
- [x] HUD e Terminal do Chassi.
- [x] Mapas (cofres) + alcançabilidade com habilidades.
- [x] Testes, QA, docs.

## 10. Verificação

- **Testes:** `tests/test_upgrades_root.gd` (números, contagens, células e barra, placa/capacitor
  enchem e salvam, porta ROOT com e sem habilidade, comporta do Reator, sobrecarga pura e na rede,
  mapa, HUD com 8 células em 72 px, Terminal do Chassi), `tests/test_level_upgrades.gd`
  (alcançabilidade por habilidade). Ajustes: `test_collectible`, `test_pickup_rules`,
  `test_level_parser`, `test_level_greenhouse`, `test_level_lab`, `test_hud_chassis`.
- **QA:** `tests/qa/f69_a_placa_nucleo.json` (escala real das garras até o cofre do hub; 5ª célula;
  chassi), `f69_b_porta_root_estufa.json` (porta ROOT sem e com Root, placa, chassi),
  `f69_c_comporta_reator.json` (Memória religada sem Root: comporta fechada, mapa
  `SELADO - EXIGE ACESSO ROOT`; com Root abre e passa), `f69_d_sobrecarga_root.json` (orçamento
  2/2 com 1 de base, fim da sobrecarga desliga a iluminação), `f69_e_capacitor_estufa.json`
  (capacitor: barra maior e chassi 1/4). `f69_a` sai de `tests/qa/gen/f69_a.py <saída> [trace]`
  (`trace` grava uma captura a cada 4–6 quadros para recalibrar).
  Regressão: `f29_greenhouse` 27/27, `f60_lab` 17/17, `f31_dash_beam` 10/10 (roteiro consertado).
- **Playtest humano:** a parede magnética ao lado da doca convida a voltar? A porta violeta "ROOT"
  lê como "volte depois" e não como bug? As 8 células ficam legíveis?

### Checklist `level-design` §4.7 (só os cofres)
- [x] Nenhum texto explica solução (a porta só diz `PORTA SELADA` / `ACESSO ROOT`).
- [x] ÓRBITA não ganhou fala.
- [x] Recompensa fora da rota; cofres visíveis de onde o jogador passa (teaser).
- [x] Cada interativo distinguível: porta ROOT violeta com placa ≠ comporta de setor vermelha ≠ porta de energia.
- [x] HUD com os mesmos elementos (só mais células no mesmo espaço).
- [x] Roteiros de QA chegam ao fim com marcos OK.

## 11. ADRs locais

### ADR-F69-001 — Capacitores velhos ficam; as placas é que pedem volta
- **Contexto:** os três capacitores dos setores velhos já existiam em salas secretas testadas
  (F27/F43, F60, F61) e as Docas (F62) puseram o 4º. Mover os capacitores quebraria esses puzzles e
  passaria do total de 4.
- **Decisão:** os capacitores ficam; as **3 placas novas** são as que pedem habilidade de setor
  posterior (garras no hub; Root na Estufa e no Laboratório). O capacitor da Enfermaria já pede o
  Núcleo Aquecido (gelo do desvio).
- **Consequências:** 4 dos 6 pedem habilidade; 2 atrás de porta ROOT. Data: 2026-11-21.

### ADR-F69-002 — HUD: célula de 25 em espaço fixo de 72 px (AJ-066)
- **Decisão:** uma célula por 25 de Integridade máxima; o espaço passa de 68 para 72 px e as
  células encolhem (16 → 13 → 11 → 9 px, recortando a arte de 9 px da célula) em vez de empurrar o
  rótulo; a barra de Carga vai de 60 a 72 px, 3 px por capacitor.
- **Consequências:** a placa aparece como célula nova; a HUD não cresce (F37/F44).

### ADR-F69-003 — Porta ROOT abre por interação e fica aberta para sempre
- **Decisão:** o Root não abre todas as portas sozinho: o jogador aperta `[E] ACESSO ROOT` (momento
  de recompensa), e a abertura vira flag `root_door_open_<id>` no save.
- **Consequências:** a comporta do Reator pede o mesmo gesto; a F64 só precisa dar a habilidade.

### ADR-F69-004 — Sobrecarga é +1 por tempo, não "liga tudo"
- **Decisão:** +1 unidade por 20 s por 25 de Carga, uma de cada vez; ao fim desliga o último
  sistema ligado (nunca um selado).
- **Consequências:** a regra de energia continua valendo com o Root; a ARGOS tem um recurso
  temporizado para usar sob pressão.

### ADR-F69-005 — Alcançabilidade com perfil de habilidades
- **Decisão:** `LevelReachability.profile_with_abilities()` fecha `M` sem garras, `I` sem
  aquecedor/sistema sem Núcleo Aquecido e `|` com `requires_ability` (porta + antepara até o teto)
  sem a habilidade. Sem a chave `abilities` o modelo continua generoso (comportamento antigo).

## 12. Log de evolução

### 2026-11-21 — Feature criada e implementada (agente de progressão)
- **O que:** tudo da seção 4. Arte da Placa gerada pelo Codex (`gen-image`, 2 variações, escolhida
  a 1; referência: a própria folha de coletáveis), fatiada em 16×14 e centrada em 16×16, alfa
  limiarizado.
- **Mapas:** hub (M em 92,2-9; chaminé 93-94; cofre 93-101 × 2-4), Estufa (laje 17-29,56; porta
  ROOT 20,55; cofre 21-28 × 53-55), Laboratório (porta ROOT 37,15; cofre 32-36 × 13-15).
- **QA:** a, b, c, d, e verdes; capturas lidas (porta violeta com placa ROOT e convite; 5 células;
  chassi `1/4`; mapa com o Reator `SELADO - EXIGE ACESSO ROOT`; terminal `ORÇAMENTO: 2/2 - ROOT 19s`).
  O `f31_dash_beam` estava quebrado desde a F67 (o 2º `[TAB]` abre o mapa): fechamento trocado por
  `ui_cancel`.
- **Armadilha nova:** no ASCII a porta é **uma célula** (a do pé), mas o corpo dela tem 3 tiles e uma
  antepara até o teto. Fechar só a célula do `|` no modelo deixou o MU-7 "passar por cima" da porta
  ROOT do Laboratório; o modelo fecha a coluna toda até o teto (`_close_gate`).
- **Pendências:** 4ª Placa nas Docas (F62; o orquestrador integra); a F64 dá o Root
  (`unlock_ability`); a F65 usa a sobrecarga; som próprio de upgrade.
- **Integração com as Docas:** o capacitor das Docas usa `kind` `capacitor` (legenda `C`) e entra
  na contagem sozinho (contagem deriva de `charge_max`). Se as Docas usarem um id fora do padrão,
  nada muda aqui; o `test_level_upgrades` aceita até 4 `C` e 4 `B` nas fases da campanha e pede
  ≥ 3 de cada.

### 2026-11-21 — Integração sobre a main com F62 (Docas) e F66 (finais) (agente de integração)
- **Colisão de letra:** a F69 e a F62 pegaram o `A` ao mesmo tempo (o dicionário `LEGEND` tinha
  a chave duas vezes e o acoplador vencia). O acoplador fica com `A`; a **Placa passou para `B`**
  (`level_builder`, `LevelReachability.PICKUP_SYMBOLS`, mapas `core_hub`/`greenhouse`/`lab`/
  `test_room`, testes, F21). Mecanismo: `test_no_legend_letter_is_declared_twice` lê o `LEGEND` do
  código-fonte e reprova letra repetida ou que também seja tile.
- **Conflitos:** `balance.gd`/GDD-P ficaram com os números da F69 e `LOGS_TOTAL`/`RESEARCH_TOTAL`
  = 10 (AJ-048 da F62); Ajustes AJ-065..067 antes de AJ-072..074; `HudModel.ABILITY_COSTS` com o
  Propulsor (15) **e** o Root (25); `chassis_menu.json` com `ability_thruster` e
  `ability_root_access`; `level_reachability` com vácuo/pulo duplo **e** o perfil de habilidades;
  testes de legenda e do chassi com as duas listas.
- **Perfil de habilidades × Propulsor:** `profile_with_abilities()` liga o pulo duplo só com o
  `thruster` (em qualquer fase, como no `mu7.gd`); sem o perfil continua valendo o `"reach"` do
  JSON da fase. O `capacitor_dk_01` entrou na tabela e conta como o 4º capacitor
  (`test_upgrade_totals_never_pass_the_gdd` agora exige 4).
- **Terminal do Chassi com 7 habilidades** estourou (226 px > 216, a lição F61 de novo): saiu o
  título `ESTAÇÃO ARTEMIS` do bloco de mapa/setores (as linhas `MAPA DA ESTAÇÃO [TAB]` e
  `SETORES RELIGADOS` se explicam sozinhas); sobram 17 px.
- **QA** (`tools/qa.sh`, capturas lidas): `f69_a` 4/4, `f69_b` 8/8, `f69_c` 6/6, `f69_d` 4/4,
  `f69_e` 5/5, `f62_docks` 22/22, `f62_hub_docks` 9/9, `f66_semeadura` 23/23, `f31_dash_beam` 10/10.
  O `f69_c` reprovou na 1ª rodada: com Docas e Memória religadas, as falas `core_return_infirmary` e
  `core_return_docks` (F62) travavam o MU-7 antes da comporta; o roteiro marca as duas como vistas.
  Capturas: comporta violeta com `[E] SELADA - ACESSO ROOT`; mapa com o Reator
  `SELADO - EXIGE ACESSO ROOT` e `RELIGADOS 6/7`; Terminal do Chassi com placas `1/4`, capacitores
  `0/4` e logs `0/10`.
- **Pendência:** a **4ª Placa nas Docas** fica para depois da F63 (que edita `data/levels/docks.*`);
  até lá `test_upgrade_totals_never_pass_the_gdd` aceita 3 placas ("só a das Docas pode faltar").

### 2026-11-21 — 4ª Placa nas Docas (integração com a F63)
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: `plate_dk_01` (`B` em
  32,40) num cofre x 31–34 × 38–40 cavado na parede oeste do hangar, atrás da porta ROOT
  `dk_root_door` (`|` em 35,40, `requires_ability: root_access`). Fora da rota principal, mas à
  vista: quem cai no hangar pela primeira vez passa ao lado da porta violeta `SELADA - ACESSO ROOT`
  a caminho do console A. A volta com o Root é curta (galeria → brecha → corredor → hangar). O cofre
  fica fora dos dois vácuos (brecha x 24–29, hangar x 36–78).
- **Testes**: `test_level_upgrades` exige 4 placas (era "só a das Docas pode faltar"), ≥ 3 upgrades
  atrás de ROOT e uma porta ROOT nas Docas também; o Nó das Docas segue alcançável sem Root.
  `test_level_docks` conta 4 `|` e 1 `B`.
- **QA**: `f69_f_placa_docas` 9/9 (novo; save com Root e 3 placas → porta barra o MU-7 em 36,40 →
  abre com `[E] ACESSO ROOT` → placa → `plates_installed` 4, Integridade máxima 200, HUD com 8
  células, Terminal do Chassi `4/4 200/200`). Capturas lidas.
- **Pendência fechada**: a 4ª Placa. Continua: a F64 dá o Root (`unlock_ability`).

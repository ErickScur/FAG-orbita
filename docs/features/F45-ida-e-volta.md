---
id: F45
title: Ir e voltar entre setores (portas de mão dupla e ala de setores do hub)
status: done
scope: demo
block: 8
priority: P1
rubric: ["Missões primárias", "Desenvolvimento de fases", "Salvar/Carregar"]
depends_on: ["F21", "F28", "F53", "F54", "F60", "F61"]
unblocks: ["F62", "F64", "F65", "F67", "F69"]
estimate: 6h
last_updated: 2026-11-21
---

# F45 — Ir e voltar entre setores

## 1. Contexto e objetivo

Até aqui a estação era uma linha: o Núcleo levava a um setor, o setor só devolvia o jogador
ao Núcleo depois de religado (bloco `revisit`, contorno registrado no ADR-F60-003) e a saída
daquele setor **fechava**. O GDD pede outra coisa: um **hub radial** em que "o jogador sempre
volta ao centro e, a cada volta, o centro está mais iluminado" ([GDD-2.7](../design/GDD.md#gdd-2-7-mapa))
e em que cada setor religado "vira ponto de viagem rápida"
([GDD-2.5](../design/GDD.md#gdd-2-5-vitoria)). A F69 vai esconder upgrades nos setores já
religados, então eles precisam continuar abertos.

A F45 entrega:
1. **Mão dupla.** Todo setor tem, na entrada, uma porta de volta ao Núcleo, que funciona a
   qualquer momento. Quem volta aparece **na frente da porta daquele setor** no hub.
2. **Setor religado continua acessível** e reabre no estado religado.
3. **Ala de setores do hub** pronta para o jogo inteiro: portas seladas e placas das Docas, do
   Núcleo de Memória e do Núcleo do Reator, com a vaga da saída reservada atrás de cada uma.
4. **Save** coerente com a mão dupla: o backup ao entrar (F53) e o Continuar caem no lugar certo.

## 2. Referências de design

- **GDD:** [GDD-2.7 hub radial](../design/GDD.md#gdd-2-7-mapa) · [GDD-2.5 vitória por fase](../design/GDD.md#gdd-2-5-vitoria) · [GDD-2.9 paleta por setor](../design/GDD.md#gdd-2-9-paleta)
- **Ajustes:** AJ-050, AJ-051 (este documento) · AJ-041/AJ-045 (volta ao Núcleo depois de religar)
- **Features:** [F53](F53-backup-ao-entrar.md) (backup ao entrar) · [F54](F54-porta-e-doca.md) (porta, doca e portal) · [F60](F60-fase-laboratorio.md) ADR-F60-003 · [F61](F61-fase-enfermaria.md) §4 A
- **Contrato da rodada:** mapa da estação (Estufa → Laboratório → Enfermaria → Docas → Memória → Reator)
- **Parâmetros:** nenhum número novo de jogo (sem linha nova na GDD-P).

## 3. Critério de avaliação atendido

- **Missões primárias / Desenvolvimento de fases:** o avaliador vê o hub como centro de verdade:
  entra na Estufa, volta pela porta, aparece na porta da Estufa, entra no Laboratório; vê no fim
  da ala as portas seladas das Docas, da Memória (embaixo) e do Reator (em cima), cada uma com a
  placa do setor.
- **Salvar/Carregar:** sair de um setor pela porta e escolher Continuar devolve ao hub, na doca
  da ala.

## 4. Escopo

### Inclui
- `LevelExit` vira **portal de interação** (`interagir` na frente dele), com placa e luz na cor
  do setor e convite próprio ("ENTRAR NA ESTUFA", "VOLTAR AO NÚCLEO"...). Não fecha mais depois
  de religar (o recurso `closes_after_sector` continua no código, sem uso nos dados).
- **Roteamento de chegada por origem**: `GameState.enter_level()` guarda a fase anterior; a fase
  nova procura a saída cujo `target` é a fase de onde o jogador veio e o põe nela.
- Porta de volta ao Núcleo (`E`, `sector: core`) na entrada da Estufa, do Laboratório e da
  Enfermaria; a doca de entrada de cada setor andou alguns tiles para a direita para dar lugar ao
  portal (o ponto `P` não mudou).
- Bloco `revisit` em cada setor (`after_sector` = ele mesmo): ambiente `ambient_restored`,
  objetivo e fala de entrada vazios.
- Ala de setores do hub (largura 122 → 150): comporta das Docas, rotunda com o Núcleo do Reator
  em cima e o Núcleo de Memória embaixo, doca da rotunda, duas luminárias, vagas reservadas.
- Placa de setor (`SectorPlate`) em portais e comportas: ícone 7×7 desenhado a 2×, na cor do
  setor, sem sombreamento (lê no escuro), com LED verde quando o setor já foi religado.
- Catálogo `data/sectors.json` (nome, convite, cena, cor, ícone) e `SectorCatalog`.

### Não inclui
- As fases Docas/Memória/Reator (F62/F64/F65) e a ligação delas (tabela da §6.4).
- Exigir Acesso Root na comporta do Reator (F69: ver §6.4).
- Console de teleporte (ADR-F45-003).
- Mudar o `sector_narrative.gd` (a volta automática depois do religamento continua como está e
  já chega na porta certa pelo roteamento de origem).

## 5. Critérios de aceite

- [x] Da entrada da Estufa, do Laboratório e da Enfermaria dá para voltar ao Núcleo a qualquer
      momento; no hub o MU-7 aparece na frente da porta daquele setor.
- [x] Depois de religar, a porta do setor no hub continua aberta e o setor reabre claro, com o Nó
      religado, a energia como foi deixada, coletáveis já pegos sumidos e sem repetir fala.
- [x] Docas (até Enfermaria), Memória (até Docas) e Reator (até Memória) aparecem seladas, com
      placa, e cada comporta de fato impede chegar à vaga da saída (teste com a porta murada).
- [x] Backup ao entrar e Continuar funcionam com a mão dupla (teste de cena + QA).
- [x] Portões do `CLAUDE.md` §6 verdes; sem comentários; nada 3D.

## 6. Definição técnica

### 6.1 Cenas e scripts
```
scripts/core/arrival_route.gd   ArrivalRoute: exit_toward(meta, origem), exits, reserved_exits, next_origin
scripts/core/sector_catalog.gd  SectorCatalog: lê data/sectors.json (nome, convite, cena, cor, ícone, hub)
scenes/world/sector_plate.gd    SectorPlate (Node2D): placa 18×18 + LED de religado, unshaded
scenes/world/level_exit.gd/.tscn  agora extends Interactable (camada 4 interactable), param `sector`
scenes/world/door.gd            param `sector` → placa sobre a antepara
scenes/levels/level_base.gd     arrival_point(), entry_position(); start_position() prefere a chegada
autoload/game_state.gd          enter_level(path) -> origem, current_level(); zera em new_game/from_dict
```
`level_base._spawn_player` usa `entry_position()`: chegada por porta > doca do checkpoint >
`start_position()` (doca de revisita > `P`). O `_entry_dock()` do F53 usa `start_position()`, que
agora é a porta de chegada; logo o backup ao entrar grava a **doca mais perto da porta**.

### 6.2 Dados
- `data/sectors.json`: `core`, `greenhouse`, `lab`, `infirmary`, `docks`, `memory`, `reactor`.
- `data/levels/core_hub.json`: saídas com `sector`, comportas com `sector`, `reserved_exits`.
- `data/levels/{greenhouse,lab,infirmary}.json`: `<x>_exit_core` e o bloco `revisit` próprio.

### 6.3 Mapa da ala (hub, colunas 92–149)
```
     9999999999000000000011111111112222222222333333333344444444
     2345678901234567890123456789012345678901234567890123456789
  2  ########################################          ########
  3  ########################################                 #
  4  ########################################  @              #   Reator: | 143,5  vaga 146,5
  5  ########################################           |     #
  6  ########################################     =====########
  7  #                                                 ########
  8  #      WW                          WW      ====   ########
  9  #                                                 ########
 10                                        =======     ########
 11     D  k  E   |   E   |   E   |       D            ########   Docas: | 121,11  vaga 125,11
 12  ########################################       @         #
 13  ########################################===              #
 14  ########################################           |     #   Memória: | 143,14  vaga 146,14
 15  ##########################################################
```
Corredor (piso 12) com os portais da Estufa (101), Laboratório (109) e Enfermaria (117), cada
comporta antes do seu portal. Depois da comporta das Docas, a **rotunda** (colunas 132–141): poço
raso até o piso 15, com o túnel da Memória à direita embaixo e, por três plataformas finas
(10, 8, 6; 2 colunas de sobreposição), o túnel do Reator em cima. A primeira (linha 10,
colunas 130–136) começa sobre o fim do corredor: subir 2 tiles até plataforma fina exige 2 colunas
de sobreposição também com o piso de partida (validação no Godot, 2026-11-21).

### 6.4 Como ligar uma fase nova ao hub

| Setor | Cena | Comporta (selada até) | Vaga da saída (x,y) | Doca que recebe o backup |
|---|---|---|---|---|
| Docas | `res://scenes/levels/docks.tscn` | `door_docks` 121,11 (`infirmary`) | ~~125,11~~ **ligada** (2026-11-21) | `core_dock_wing` 129,11 |
| Núcleo de Memória | `res://scenes/levels/memory_core.tscn` | `door_memory` 143,14 (`docks`) | ~~146,14~~ **ligada** (F64, 2026-11-21) | `core_dock_wing` 129,11 |
| Núcleo do Reator | `res://scenes/levels/reactor_core.tscn` | `door_reactor` 143,5 (`memory`) | ~~146,5~~ **ligada** (F65, 2026-11-21) | `core_dock_wing` 129,11 |

Passos, para cada fase nova (o teste `test_reserved_exits_wait_for_their_scenes` **reprova** o
`gates.sh` enquanto a cena existir e a vaga não estiver ligada):

1. **Hub, ASCII** (`data/levels/core_hub.txt`): troque o espaço da vaga por `E`
   (linha `y`, coluna `x`, contando de 0).
2. **Hub, JSON** (`data/levels/core_hub.json`): **mova** a entrada da vaga de `reserved_exits`
   para `entities`, sem mudar nada:
   - Docas: `"125,11": {"id": "core_hub_exit_docks", "target": "res://scenes/levels/docks.tscn", "sector": "docks"}`
   - Memória: `"146,14": {"id": "core_hub_exit_memory", "target": "res://scenes/levels/memory_core.tscn", "sector": "memory"}`
   - Reator: `"146,5": {"id": "core_hub_exit_reactor", "target": "res://scenes/levels/reactor_core.tscn", "sector": "reactor"}`
3. **Fase nova**: um `E` na entrada, junto do `P` (até 4 colunas, mesmo piso), com
   `{"id": "<prefixo>_exit_core", "target": "res://scenes/levels/core_hub.tscn", "sector": "core"}`,
   uma doca a ≥ 3 colunas do portal (o sprite dele tem 32 px) e um bloco
   `"revisit": [{"after_sector": "<id>", "ambient_color": "<ambient_restored>", "objective": "", "on_enter_dialogue": ""}]`.
4. **Testes**: acrescente o setor em `HUB_EXITS`/`SECTOR_RETURNS` de `tests/test_arrival_route.gd`
   e em `CAMPAIGN_LEVELS`/`PLAYABLE_LEVELS` se for o caso. O `SECTOR_CHAIN` de
   `tests/test_level_core_hub.gd` já cobre as três vagas.
5. **Reator + Acesso Root (F69)**: a comporta `door_reactor` abre só por `sealed_until_sector:
   memory`. Para exigir também o Acesso Root, a F69 acrescenta à `Door` uma condição de
   habilidade (`requires_ability: root_access`, feito) e a põe no JSON da comporta; o desenho do
   hub não muda. A F64 concede o Root ao religar a Memória (`GameState.unlock_ability`).
6. **Hub mais claro**: a F62 acrescenta só a entrada `revisit` `after_sector: docks` com
   `ambient_color` mais claro que a do Laboratório (`#3b5266`); o teste de luma em
   `test_level_core_hub` exige a ordem crescente.

## 7. Assets necessários

Nenhum arquivo novo: o portal continua no quadro 5 de `door_sheet.png` (F54). A placa e o LED são
desenhados por código a partir de `data/sectors.json` (ícone 7×7 por setor, cor da paleta do
GDD-2.9), no mesmo espírito da antepara da F54.

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] Portal de interação + placa de setor; catálogo de setores.
- [x] Roteamento de chegada por origem (`ArrivalRoute`, `GameState.enter_level`).
- [x] Portas de volta nas três fases; `revisit` próprio de cada setor.
- [x] Ala de setores do hub, vagas reservadas, testes de geometria e de chegada.
- [x] Roteiros de QA f45 e conserto dos roteiros do hub.

## 10. Verificação

- **Testes:** `tests/test_arrival_route.gd` (rota, catálogo, origem em `GameState`),
  `tests/test_hub_round_trip.gd` (cena real: volta pela porta, Continuar, setor religado,
  saídas abertas e comportas seladas com placa), `tests/test_level_core_hub.gd` (cadeia de
  comportas, porta murada bloqueia a vaga, vagas esperando a cena, rotunda radial).
- **QA:** `tests/qa/f45_a_volta_pela_porta.json`, `f45_b_estufa_religada.json`,
  `f45_c_ala_selada.json` (gerados por `tests/qa/gen/f45.py`).
- **Playtest humano:** voltar da Estufa no meio dela, pegar o Laboratório, voltar à Estufa
  religada e achar a ala legível (placa de cada setor e LED).

### Checklist `level-design` §4.7 (a ala não é fase de puzzle; vale o que se aplica)
- [x] Nenhum texto explica solução: a ala só tem placas (ícone) e o convite de interação.
- [x] ÓRBITA não ganhou fala: nenhuma fala nova; as de entrada não repetem na revisita.
- [ ] Duas trocas de energia obrigatórias — N/A (corredor de ligação, sem terminal novo).
- [ ] Rota opcional com recompensa e segredo — N/A aqui; a F69 os põe nos setores religados.
- [x] Escuro de verdade: a rotunda só tem duas luminárias âmbar fracas e a luz dos portais.
- [x] Silhueta: portal (quadro 5, túnel), comporta (folhas + antepara) e doca (cápsula) seguem
      distintos; a placa é um quadrado de 18 px com ícone próprio por setor.
- [x] HUD igual: o convite usa o aviso de interação que já existia.
- [x] Roteiros de QA com marcos (§10).
- [ ] Cutscene de religamento — N/A (nenhum Nó novo).

## 11. ADRs locais

### ADR-F45-001 — Portal por interação, não por contato
- **Contexto:** com as saídas abertas para sempre, o corredor da ala passa por cima de vários
  portais; por contato, andar até o Laboratório levaria à Estufa. Chegar na frente de um portal
  de contato também o dispararia de novo.
- **Decisão:** `LevelExit` estende `Interactable`: atravessa com `interagir`, mostra o convite no
  aviso de interação que já existe (HUD não cresce).
- **Consequências:** os roteiros de QA que andavam para dentro da saída passaram a apertar
  `interagir`; a chegada pode pôr o MU-7 exatamente sobre o portal.
- **Data:** 2026-11-20.

### ADR-F45-002 — Chegada pela porta de onde se veio
- **Contexto:** "aparecer na frente da porta daquele setor" vale tanto para a porta quanto para a
  volta automática depois do religamento (`sector_narrative`, que não é deste agente).
- **Decisão:** o `GameState` guarda a fase anterior (em memória, fora do save); a fase nova acha a
  saída com `target` igual a ela. Sem origem (jogo novo, Continuar, recarregar a mesma fase) vale
  o que já existia: doca do checkpoint, doca de revisita, `P`.
- **Consequências:** não há id de chegada em dado nenhum; a volta automática da Estufa já chega
  na porta da Estufa; o `spawn_dock` do `revisit` do hub virou só o caso do Continuar sem doca.
- **Data:** 2026-11-20.

### ADR-F45-003 — Viagem rápida é a própria ala
- **Contexto:** o GDD pede "setor vira ponto de viagem rápida"; um console de teleporte cresceria
  UI (`scenes/ui`) e duplicaria o que o hub já faz.
- **Decisão:** sem console. Todo portal fica na ala (≈ 1,5 tela), a chegada é na porta do setor de
  origem e todo setor religado continua aberto; ir de um setor a outro é porta → ala → porta.
- **Consequências:** de dentro de um setor, sair pede voltar à entrada. Se o playtest pedir, o
  próximo passo é um portal de volta junto do Nó religado (fora da área deste agente).
- **Data:** 2026-11-20.

### ADR-F45-004 — Setor religado reabre religado, com patrulhas
- **Decisão:** reabrir religado = bloco `revisit` do próprio setor (ambiente `ambient_restored`,
  sem objetivo e sem fala), Nó já religado (lido de `sectors_restored`), energia como ficou
  (`energy_states`), coletáveis pegos não voltam, cutscene não repete (só dispara no religamento).
  Os inimigos voltam a patrulhar: a ARGOS ainda manda neles e a F69 esconde upgrades ali, então a
  revisita precisa de risco.
- **Data:** 2026-11-20.

### ADR-F45-005 — Rotunda radial dentro da altura atual do hub
- **Contexto:** crescer o mapa para baixo mudaria o limite da câmera no hub inteiro e o
  enquadramento de todos os cartões de tutorial (lição F31).
- **Decisão:** a ala cresce só para a direita (122 → 150 colunas). Reator em cima (túnel no topo
  da rotunda), Memória embaixo (túnel no fundo do poço), Docas no corredor.
- **Data:** 2026-11-20.

## 12. Log de evolução

### 2026-11-20 — Feature criada e implementada
- **Quem**: agente de mundo (rodada "jogo completo") · **O que**: escopo definido pelo
  orquestrador; portal de interação com placa, roteamento de chegada, portas de volta nos três
  setores, revisita religada, ala de setores com rotunda e vagas reservadas, testes e QA.
- **Armadilha nova:** `Godot --version` sem `perl alarm` ficou pendurado meia hora nesta máquina
  (dois processos órfãos); até a checagem de versão vai com limite de tempo.

### 2026-11-21 — Validação com Godot
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: primeira execução com
  o Godot 4.7.2. Os scripts novos não tinham erro de tipagem nem de parse: o import e os
  930 testes passaram de primeira, menos um (abaixo). `tools/gates.sh` completo verde.
- **Quebrado:** `test_each_sealed_door_really_guards_its_exit` — a vaga do Reator era
  inalcançável mesmo com a comporta aberta. A primeira plataforma fina da rotunda (linha 10,
  colunas 133–136) ficava 2 tiles acima do fim do corredor (coluna 131) sem sobreposição: subir
  2 tiles até plataforma fina pede 2 colunas de sobreposição também com o piso de partida (regra
  da F43, ADR-F43-002). **Conserto:** a plataforma começa na coluna 130 (130–136), sobre o fim do
  corredor; `tools/level_reach.gd` mostra o Reator alcançável.
- **QA com marcos (todos OK):** `f45_a_volta_pela_porta` (7), `f45_b_estufa_religada` (8),
  `f45_c_ala_selada` (6), `f60_hub_return` (10), `f61_hub_return` (11), `f60_lab` (17),
  `f61_infirmary` (15), `f29_greenhouse` (27, duas rodadas seguidas; a primeira perdeu o trilho
  por dano de inimigo, timing), `f53_entrada_estufa` (5) e `f53_continuar` (3) reescritos com
  marcos (nascem no `P` 4,62 e voltam na doca da entrada 6,62; o `f53_continuar` grava o próprio
  save, porque o `user://save.json` é dividido com outras worktrees). `f45_c` e `f61_hub_return`
  só passaram depois do conserto de ordem de eventos no `QACapture` (ver log da F67).
- **Olho de playtest:** placas legíveis no escuro (cruz branca da Enfermaria, âncora laranja das
  Docas, ícone rosa da Memória, vermelho do Reator, folha verde da Estufa); convite claro
  (`[E] ENTRAR NA ESTUFA`, `[E] VOLTAR AO NÚCLEO`); portal (túnel com luzes e placa) não se
  confunde com a doca apagada ao lado. Capturas: `f45_a/02_porta_de_volta_ao_nucleo`,
  `f45_a/03_chegou_na_porta_da_estufa`, `f45_c/02_comporta_das_docas_selada`,
  `f45_c/04_memoria_e_reator_selados`.
- **Fora do alcance:** `f28_core_hub`, `f36_tutorial`, `f53_portal_saida` e `f53_porta_comum` são
  roteiros antigos sem marco (só capturas, dependem de `--scene`); o trecho do hub que eles cobrem
  não mudou. A sonda `f53_probe_exit.tscn` hoje enquadra o Habitacional, não o portal.

### 2026-11-21 — Integração com as Docas (F62)
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: a F62 foi feita sobre a
  `main` anterior à F45 e chegou com o `docks.tscn` pronto; `test_reserved_exits_wait_for_their_scenes`
  reprovou como previsto. Ligação pela §6.4: `E` em 125,11 no `core_hub.txt`, entrada movida de
  `reserved_exits` para `entities` (`core_hub_exit_docks`, `sector: docks`), Docas em
  `HUB_EXITS`/`SECTOR_RETURNS`. **A vaga 125,11 foi consumida**; restam 146,14 (Memória) e 146,5 (Reator).
- **Revisita do hub**: criada a entrada `after_sector: infirmary` (objetivo `obj_core_docks`,
  `#4a637a`, fala `core_return_infirmary`) entre a do Laboratório (`#3b5266`) e a das Docas
  (`#58748a`, `obj_core_memory`); ordem de luma crescente conferida pelo teste.
- **QA**: `f45_c_ala_selada` atualizado (o 2º trecho tem a Enfermaria religada: objetivo das Docas
  e a captura `03_docas_abertas_saida_viva` mostra a comporta aberta e o portal com a placa da
  âncora); `f45_a`/`f45_b` regenerados (só a flag da fala nova) e verdes; roteiro novo
  `f62_hub_docks` (hub → Docas → hub).

### 2026-11-21 — Integração com o Reator (F65): a última vaga
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: `E` em 146,5 no
  `core_hub.txt` e `core_hub_exit_reactor` (`sector: reactor`) em `entities`. **Todas as vagas
  foram consumidas**: o bloco `reserved_exits` saiu do `core_hub.json` (o `ArrivalRoute` lê
  ausência como `{}`; `test_reserved_exits_wait_for_their_scenes` continua valendo se um setor novo
  aparecer). O hub tem 6 portais (`test_single_spawn_and_one_exit_per_sector`). Reator em
  `HUB_EXITS`/`SECTOR_RETURNS`, e o mapa de id de fase → setor do teste ficou um só
  (`SECTOR_OF_LEVEL`: `memory_core` → `memory`, `reactor_core` → `reactor`).
- **Revisita**: a última entrada continua `after_sector: memory` (objetivo "Religar o Reator"); o
  Reator não volta ao hub, termina em `argos_defeated` → sala de comando (F66).

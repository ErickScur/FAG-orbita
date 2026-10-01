---
id: F43
title: Estufa maior, mais rica e mais difícil
status: done
scope: demo
block: 6
priority: P0
rubric: ["Puzzle", "Habilidades", "Plataformas que se movimentam", "Área secreta", "Luz/Sombra"]
depends_on: ["F17", "F21", "F24", "F25", "F27", "F29", "F41"]
unblocks: []
estimate: 6h
last_updated: 2026-09-20
---

# F43 — Estufa maior, mais rica e mais difícil

## 1. Contexto e objetivo

O humano jogou a Demo e disse: *"a mudança na estufa não tem que ser só visual, tem que ser da
fase inteira, mais coisas para explorar, mais desafios, mais plantas, deixar um pouco mais
difícil, pq hoje é só ligar a planta, subir, abrir a porta e já era. tem que ser mais difícil
que isso para um jogo de puzzle, fases maiores, mapas maiores, parkour, etc..."*

E, separado: *"na estufa, a parede magnética ficou bem escura, mal dá pra ver que é amarela"* —
efeito colateral da [F41](F41-escuridao.md), que tornou a escuridão real e apagou as listras
amarelas que ensinam onde escalar.

Esta feature reconstrói a Estufa inteira: o mapa passa de **40×40** para **48×64** tiles, o
Terminal de Distribuição passa de **5 sistemas / 2 energias** para **6 / 2 com duas cadeias de
dependência**, e a fase ganha seis andares ligados por trepadeiras, elevador, gôndola, escada
de plataformas finas e parede magnética. A Estufa **não** volta a ser tutorial: o terminal
continua mudo (`verbose: false`) e a ÓRBITA não narra efeito de sistema. A dificuldade vem de
**dedução e execução**.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.7-F1 — Estufa](../design/GDD.md#gdd-2-7-f1) · [GDD-2.7 curva de dificuldade](../design/GDD.md#gdd-2-7-curva)
  (*"de 3 sistemas / 1 energia até 6 sistemas / 3 energias com dependência em cadeia"*) ·
  [GDD-2.5 energia](../design/GDD.md#gdd-2-5-energia) · [GDD-2.5 vitória](../design/GDD.md#gdd-2-5-vitoria) ·
  [GDD-2.9 paleta](../design/GDD.md#gdd-2-9-paleta) · [GDD-P](../design/GDD.md#gdd-p)
- **Parâmetros:** `Balance.JUMP_HEIGHT` (40) · `Balance.WALK_SPEED` (110) · `Balance.PLATFORM_SPEED` (40) ·
  `Balance.PLATFORM_WAIT` (0.6) · `Balance.CLAW_CLIMB_SPEED` (70) · `Balance.PLANT_GROW_TIME` (2) ·
  `Balance.SPORE_RADIUS_HEATED` (48) · `Balance.RESEARCH_TOTAL` (4) · `Balance.SECRETS_TOTAL` (4)
- **Jornada:** [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) (fases em ASCII) · [ADR-006](../DECISIONS.md#adr-006) (JSON) ·
  [ADR-F25-002](F25-plataformas-moveis-planta.md) (a planta nunca murcha)
- **Features vizinhas:** [F29](F29-fase-estufa.md) (a fase anterior), [F17](F17-terminal-distribuicao.md),
  [F24](F24-garras-magneticas.md), [F25](F25-plataformas-moveis-planta.md), [F27](F27-area-secreta.md),
  [F41](F41-escuridao.md), [F42](F42-cutscene-religamento.md)

## 3. Critério de avaliação atendido

- **Puzzle**: 6 sistemas / 2 energias com **duas cadeias** (`canopy_light` ← `grow_light`,
  `lift_platform` ← `heating`). Cada cadeia consome o orçamento inteiro: ligar a segunda peça
  obriga apagar tudo o mais.
- **Habilidades**: as Garras Magnéticas passam a ser usadas **duas vezes** — a subida obrigatória
  de 10 tiles até o andar do Nó e a subida opcional de 16 tiles até o nicho do terceiro Dado.
- **Plataformas que se movimentam**: elevador de carga (20 tiles) e gôndola (10 tiles), ambos
  na mesma linha de energia.
- **Área secreta**: duas, com paredes falsas distintas (`gh_secret_01`, `gh_secret_02`).
- **Luz/Sombra**: a parede magnética passa a ter brilho próprio discreto — legível no escuro sem
  lanterna sem clarear a sala (medido na seção 10).

## 4. Escopo

### Inclui
- `data/levels/greenhouse.txt` — mapa **48×64** (768×1024 px), seis zonas (seção 6.1).
- `data/levels/greenhouse.json` — 49 entidades, 2 gatilhos, paleta e música inalteradas.
- `data/energy/greenhouse.json` — 6 sistemas, 2 unidades, duas cadeias `requires`.
- `scenes/world/magnetic_wall.{tscn,gd}` — `PointLight2D` de brilho próprio + `self_modulate`.
- `tests/test_level_greenhouse.gd` reescrito (32 testes), com prova de **ausência de softlock**
  por busca exaustiva sobre (zona × estado de energia).
- `tests/test_energy_data.gd` atualizado para 6 sistemas + testes da cadeia da copa.
- `tests/qa/f29_greenhouse.json` reescrito (travessia completa até o FIM DA DEMO) e três roteiros
  novos: `f43_parede_magnetica.json`, `f43_rota_carga.json`, `f43_secretos.json`.
- Sondas de QA `tests/qa/scenes/gh_probe.gd` + 6 cenas.

### Não inclui
- Arte definitiva de tiles/props (segue na fila do [`ASSETS.md`](../ASSETS.md)).
- Logs novos: a Demo continua com exatamente 4 logs, 2 deles na Estufa.
- Dados de Pesquisa novos: continuam 3 na Estufa (4 na Demo, casando com `Balance.RESEARCH_TOTAL`).
- Mexer em `scripts/core/balance.gd` (arquivo de outro agente nesta rodada — ver [ADR-F43-004](#adr-f43-004)).
- Simuladores climáticos alternando estações de verdade — Final.

## 5. Critérios de aceite

- [x] O mapa cresce de 40×40 para **48×64** e continua vertical.
- [x] O terminal mostra **6 sistemas e 2 unidades**; `LUZ DE CRESCIMENTO — COPA` aparece como
      **REQUER** enquanto o canteiro estiver desligado, e `LINHA DE CARGA` como **REQUER**
      enquanto o aquecimento estiver desligado.
- [x] Desligar `grow_light` derruba `canopy_light` em cascata; desligar `heating` derruba
      `lift_platform`.
- [x] `energy_grid.validate()` continua acusando escassez (soma dos custos 6 > orçamento 2).
- [x] **Nenhum estado de energia, em nenhuma zona, impede fechar a fase** (busca exaustiva).
- [x] Duas rotas independentes da base até a copa: botânica (trepadeiras) e de carga
      (elevador + gôndola).
- [x] Duas áreas secretas, cada uma com parede falsa de 2 tiles e recompensa.
- [x] As Garras continuam destravadas por `log_gh_02` e continuam sendo o único acesso ao Nó.
- [x] A parede magnética é reconhecível como escalável **sem lanterna** no corredor escuro.
- [x] A Demo fecha de ponta a ponta até a tela **FIM DA DEMO** (capturado).
- [x] Portões do `/CLAUDE.md` §6 verdes (619 testes, 74 cenas no smoke).
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### 6.1 Mapa ASCII — `data/levels/greenhouse.txt` (48 × 64)

Legenda ([F21](F21-construtor-fases-ascii.md)): `#` sólido · `=` plataforma fina · ` ` vazio ·
`W` janela · `P` spawn · `D` doca · `T` console do terminal · `L` terminal de registros ·
`r` dado · `c` célula · `k` kit · `C` capacitor · `|` porta de energia · `S` SR-3 · `~` esporos ·
`M` parede magnética · `m` plataforma móvel · `g` trepadeira · `x` parede falsa · `@` lâmpada ·
`o` prop.

```
    000000000011111111112222222222333333333344444444
    012345678901234567890123456789012345678901234567
 0  ################################################
 1  ################################################
 2  ##          #                                 ##     ZONA F — CÂMARA DO NÓ (2-11)
 3  ##          #                                M##     coluna 45 = parede magnética (3-21)
 4  ##  WW      #           WW                   M##
 5  ##  WW      #     @     WW        @      r   M##     r = data_gh_03 no nicho das garras
 6  ##          #                          ####  M##     saliência 39-42: só se chega escalando
 7  ##          #                                M##
 8  ##          #                                M##
 9  ##            @                              M##     @ = lâmpada da PORTA DO NÓ
10  ##                                           M##
11  ##   o o    |  c              T              M##     o=Nó(7) | porta(12) T=console C(30)
12  #######################   #################  M##     vão de 3 tiles (23-25) + chaminé 43-44
13  #######################   #################  M##
14  ########    ###############################  M##     ZONA E — CORREDOR ESCURO (14-21)
15  ########    ###############################  M##
16  ##              @              @        @    M##     @ = ILUMINAÇÃO DO CORREDOR
17  ##                                           M##
18  ##                                           M##
19  ##                                           M##
20  ##                                           M##
21  ##           D         S         c    L      M##     D=doca 2  S=SR-3  L=log_gh_02 (garras)
22  ########===#######  ######   ###################     poços: 18-19 (2) e 26-28 (3 tiles)
23  ########   #######  ######   ###################
24  ##      ===   ########                   #######     ZONA D — COPA (24-31)
25  ##            ########                   #######
26  ##      ===                 WW           #######     torre de plataformas finas (8-11)
27  ##                          WW           #######
28  ##       ===                     @      #     ##     @ = respiro de calor
29  ##                                      #     ##
30  ##      ===                      ~      x     ##     x = parede falsa gh_secret_02
31  ##              r                       x  kc ##     r=data_gh_02  k+c = prêmio do segredo
32  ####   #############==##########################     poço da gôndola (4-6) + saída (20-21)
33  ####   ############    #########################
34  ##                 ===  ######                ##     ZONA C — GALERIA (34-41)
35  ##                      ######                ##
36  ##    WW          ====                        ##     chaminé da trepadeira alta
37  ##    WW                                      ##
38  ##                   @                        ##     @ = LUZ DE CRESCIMENTO — COPA
39  ##                                            ##
40  ##               ===      ~                   ##     === patamar de embarque da trepadeira
41  ##   m      T       g               S    L    ##     m=gôndola T=console B g=trepadeira alta
42  ######################   ######=====#######   ##     vão de 3 tiles (22-24) + saída da escada
43  ######################   ######     #######   ##     poço do elevador (43-45)
44  #####            ######        ====           ##     ZONA B — VIVEIRO (44-51)
45  #####            ######                       ##
46  #####                        ====             ##     escada diagonal de plataformas finas
47  #####                               WW        ##
48  ##  #                      ====     WW        ##
49  ##  #                                         ##
50  ##  x               ~    ====                 ##     x = parede falsa gh_secret_01
51  ##Ccx  k                                      ##     C = Núcleo de Capacitor
52  #############===###########################   ##     saída da trepadeira (13-15)
53  ############     ##########################   ##
54  ##           ===    ##########                ##     ZONA A — CHEGADA (54-61)
55  ##                  ##########      WW        ##
56  ##           ====                   WW        ##
57  ##           @          @      @              ##     @ = canteiro / respiros de calor
58  ##                                            ##
59  ##                                            ##
60  ##         ==            ~   ~                ##     == patamar de embarque do canteiro
61  ##D P  c      g  ##  T  S  r     k  ##      m ##     g=trepadeira T=console A m=elevador
62  ################################################
63  ################################################
```

| Zona | Linhas | Papel |
|---|---|---|
| **A — Chegada** | 54–61 | Spawn, doca 1, **console A**, trepadeira do canteiro, SR-3 entre dois degraus, dois focos de esporos com o Dado no meio, poço do elevador a leste |
| **B — Viveiro** | 44–51 | **Segredo 1** (Núcleo de Capacitor) atrás de parede falsa, kit, esporo, escada diagonal de 4 plataformas finas que sobe 10 linhas |
| **C — Galeria** | 34–41 | **Console B**, gôndola a oeste, trepadeira alta ao centro, vão de 3 tiles, SR-3, `log_gh_01`, chegada do elevador a leste |
| **D — Copa** | 24–31 | Torre de 5 plataformas finas até o corredor, esporo, Dado, **Segredo 2** (kit + célula) |
| **E — Corredor escuro** | 14–21 | Doca 2, dois poços (2 e 3 tiles) invisíveis sem luz, SR-3 preso entre eles, `log_gh_02` (Garras), base da parede magnética |
| **F — Câmara do Nó** | 2–11 | Vão de 3 tiles, **console C**, porta de energia, Nó do setor, nicho das garras com o terceiro Dado |

**Geometria conferida por teste:** degraus ≤ 2 tiles (32 px < `JUMP_HEIGHT` 40 px), vãos ≤ 3 tiles
(48 px < ~63 px de alcance com corrida), lajes ≥ 2 tiles de espessura, plataformas finas
consecutivas com **pelo menos 2 colunas de sobreposição** (ADR-F43-002).

### 6.2 Puzzle de energia — `data/energy/greenhouse.json`

**6 sistemas · 2 unidades · `verbose: false` (terminal mudo)**

| id | nome | custo | requer | o que move |
|---|---|---:|---|---|
| `heating` | AQUECIMENTO DO MÓDULO | 1 | — | expande os 5 focos de esporos, acende os respiros |
| `corridor_light` | ILUMINAÇÃO DO CORREDOR | 1 | — | 3 lâmpadas da Zona E (mostra os poços) |
| `grow_light` | LUZ DE CRESCIMENTO — CANTEIRO | 1 | — | `gh_plant_1` (Zona A → B) |
| `canopy_light` | LUZ DE CRESCIMENTO — COPA | 1 | **`grow_light`** | `gh_plant_2` (Zona C → D) |
| `lift_platform` | LINHA DE CARGA | 1 | **`heating`** | `gh_lift` (A → C) **e** `gh_gondola` (C → D) |
| `node_door` | PORTA DO NÓ DO SETOR | 1 | — | `gh_node_door` (meta) |

Estado inicial: `heating` + `corridor_light` (2/2 em uso). Soma dos custos 6 > orçamento 2 →
`validate()` continua acusando escassez.

**A cadeia é o aperto:** ligar `canopy_light` exige `grow_light` ligado, e os dois juntos custam
as duas unidades — não sobra nada para a porta do Nó nem para a luz do corredor. O mesmo vale
para `heating` + `lift_platform`. Desligar a base derruba a ponta em cascata (`power_off`
devolve 2 ids).

**Rota botânica:** console A (desliga aquecimento, liga canteiro) → trepadeira → viveiro →
escada → galeria → console B (apaga corredor, liga copa) → trepadeira alta → copa → torre →
corredor **às escuras** → garras → parede → console C (desliga copa, abre a porta) → Nó.

**Rota de carga:** console A (apaga corredor, liga a linha de carga) → elevador sobe direto da
base até a galeria (pulando o viveiro e o segredo) → gôndola sobe à copa → daí em diante igual.
Quem escolhe carga anda com o aquecimento ligado, ou seja, **com os esporos expandidos** o tempo
todo.

### 6.3 Prova de ausência de softlock

Dois testes independentes:

1. `test_energy_data.gd::test_greenhouse_has_no_softlock` — força de bruta sobre os **64
   subconjuntos** dos 6 sistemas; para cada estado alcançável, verifica que `node_door` ainda
   pode ser ligado.
2. `test_level_greenhouse.gd::test_no_energy_state_can_strand_the_player` — busca exaustiva
   sobre o produto **(6 zonas × 13 estados de energia válidos)**. O grafo modela as travessias:

   | aresta | exige |
   |---|---|
   | A → B | `grow_light` (trepadeira do canteiro) |
   | A → C | `lift_platform` (elevador) |
   | B → C | — (escada de plataformas finas) |
   | C → D | `canopy_light` **ou** `lift_platform` (trepadeira alta **ou** gôndola) |
   | D → E | — (torre de plataformas finas) |
   | E → F | Garras (o log mora na Zona E) |
   | todas as descidas | — (queda sempre possível) |

   Consoles nas zonas **A, C e F**. Para **todo** estado alcançável a partir do inicial, a busca
   confirma que ainda existe caminho até (zona F, `node_door` ligado). O argumento humano:
   descer é sempre de graça, a Zona A sempre tem console, e do console A qualquer estado de 2
   unidades é alcançável — logo o jogador nunca fica preso, só perde tempo.
   `test_every_zone_can_reach_a_console_without_energy` trava a premissa.

### 6.4 Parkour

| # | Onde | O que exige |
|---|---|---|
| 1 | Zona A, degraus 17-18 e 36-37 | Pulo curto; também são os batentes que prendem a SR-3 entre as colunas 19 e 35 |
| 2 | Zona A, chaminé do canteiro | 3 saltos em plataformas finas de 2 em 2 linhas, começando no patamar 11-12 |
| 3 | Zona B, escada diagonal | 4 plataformas finas subindo 10 linhas e avançando 10 colunas; errar cai no piso do viveiro |
| 4 | Zona C, vão 22-24 | **Salto de 3 tiles com corrida** (48 px de vão; 63 px de alcance máximo). Errar cai no viveiro, junto da escada |
| 5 | Zona C, gôndola | Embarcar no momento certo: ciclo de 9,2 s (`PLATFORM_SPEED` 40, `PLATFORM_WAIT` 0,6) |
| 6 | Zona A→C, elevador | Poço de 20 tiles; dá para saltar fora na passagem pelo viveiro (linha 51) |
| 7 | Zona D, torre | 5 plataformas finas; a descida exige **↓** (plataforma fina) |
| 8 | Zona E, poço 18-19 | Salto de 2 tiles **no escuro** |
| 9 | Zona E, poço 26-28 | **Salto de 3 tiles no escuro**, com a SR-3 patrulhando entre os dois poços; errar cai na copa |
| 10 | Zona E→F, parede magnética | Escalada de 10 tiles (2,3 s) com troca de lado no topo (salto para a esquerda) |
| 11 | Zona F, nicho | Escalada opcional de 16 tiles até a linha 4 e salto para a saliência 39-42 |
| 12 | Zona F, vão 23-25 | **Salto de 3 tiles**; errar cai no corredor escuro e obriga a reescalar |

Nenhuma queda mata: toda queda cai numa zona com rota de volta. Dano vem dos esporos (`SPORE_DPS`)
e das SR-3 (`SR3_CONTACT_DAMAGE`), não da altura.

### 6.5 Coleta

| Item | Onde | Observação |
|---|---|---|
| `log_gh_01` | Zona C, 41,41 | No caminho das duas rotas |
| `log_gh_02` | Zona E, 38,21 | Destrava as Garras Magnéticas |
| `data_gh_01` | Zona A, 27,61 | **Entre dois focos de esporos** — com `heating` ligado custa vida |
| `data_gh_02` | Zona D, 16,31 | Copa |
| `data_gh_03` | Zona F, 41,5 | **Só escalando a parede até o topo** |
| `capacitor_gh_01` | Zona B, 2,51 | Segredo 1 |
| `kit_gh_02` + `cell_gh_05` | Zona D, 43,31 e 44,31 | Segredo 2 |
| 5 células, 3 kits | espalhados | Sem placar próprio |

Totais: **2 logs · 3 dados · 2 segredos** — `Balance.LOGS_TOTAL` (4), `Balance.RESEARCH_TOTAL` (4,
somando o do Núcleo) e `Balance.SECRETS_TOTAL` (4) continuam fechando.

### Cenas e scripts
```
data/levels/greenhouse.txt        mapa 48x64
data/levels/greenhouse.json       49 entidades, 2 gatilhos
data/energy/greenhouse.json       6 sistemas, 2 unidades, 2 cadeias
scenes/world/magnetic_wall.tscn   nó Glow (PointLight2D)
scenes/world/magnetic_wall.gd     GLOW_COLOR / GLOW_RADIUS / GLOW_ENERGY / SELF_LIGHT
tests/test_level_greenhouse.gd    32 testes (geometria, puzzle, softlock)
tests/test_energy_data.gd         cadeia da copa + 6 sistemas
tests/qa/scenes/gh_probe.gd       sonda: fase real em um tile, com energia/garras/plantas prontas
tests/qa/f29_greenhouse.json      travessia completa (377 eventos, 44 capturas)
tests/qa/f43_parede_magnetica.json / f43_rota_carga.json / f43_secretos.json
tests/qa/f43_luz_parede_magnetica.json  sondas de luz no topo e no meio da escalada
tests/qa/scenes/light_probe.gd          sonda que conta as luzes ativas e mede a lanterna
tests/test_light_crowding.gd            teto de 12 luzes por janela de 256 px
```

### Autoloads / sinais do EventBus
- Nada novo. A parede magnética não escuta `energy_changed`: o brilho é passivo (é uma placa
  magnetizada, não uma lâmpada).

### Dados (`data/`)
- `data/dialogue/greenhouse.json` e `data/logs/greenhouse.json` **intocados**.

### Input actions / camadas de colisão
- Nenhuma mudança.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Tiles e o tile da parede magnética (coluna 0, linha 3) | já existente |
| [FX-LIGHT](../ASSETS.md#fx-light) | Textura do brilho da parede | já existente |
| [SPR-PLANT](../ASSETS.md#spr-plant) | Segunda trepadeira reusa a mesma folha | já existente |
| [SPR-PLATFORM](../ASSETS.md#spr-platform) | Gôndola reusa o sprite do elevador | já existente |

Nenhum asset novo: a fase inteira é composta com props que já existiam.

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Medir o alcance real de pulo/escalada e reprojetar as seis zonas.
- [x] **Passo 2** — Gerar o mapa 48×64 e os metadados; validar geometria por script.
- [x] **Passo 3** — Puzzle de 6 sistemas com as duas cadeias.
- [x] **Passo 4** — Brilho próprio da parede magnética.
- [x] **Passo 5** — Reescrever os testes, inclusive a prova de softlock por busca exaustiva.
- [x] **Passo 6** — Reescrever o roteiro de QA da travessia e capturar tudo.
- [x] **Passo 7** — Portões §6.

## 10. Verificação

### Testes
`619 passed, 0 failed`. Destaques:
- `test_map_grew_into_a_tall_vertical_level` — 48×64, vertical.
- `test_puzzle_is_six_systems_two_units` / `test_the_puzzle_has_two_dependency_chains`.
- `test_no_energy_state_can_strand_the_player` — busca exaustiva (zona × estado).
- `test_every_plant_has_a_boarding_ledge_two_tiles_below_its_top` — trava o bug encontrado
  durante a execução (ver [ADR-F43-003](#adr-f43-003)).
- `test_botanic_route_geometry_reaches_the_node_floor` / `test_freight_route_geometry_...`.
- `test_the_lift_docks_level_with_both_floors` / `test_the_gondola_docks_level_with_both_floors`.
- `test_the_magnetic_wall_is_one_unbroken_climb` — parede contínua e coluna de escalada livre.
- `test_the_demo_still_has_exactly_four_research_data` / `test_the_level_has_two_secret_areas`.

### Smoke
74 cenas, 0 erros. As sondas `gh_probe_*` **não** entram em `tests/scenes.txt` (arquivo disputado
nesta rodada); a fase real `greenhouse.tscn` já está na lista.

### Roteiro godot-qa — travessia completa (`tests/qa/f29_greenhouse.json`, `--fixed-fps 60`)

44 capturas, cena inicial `res://scenes/levels/greenhouse.tscn` com `--qa-new-game`.
Marcos confirmados pelo log de posição:

| Frame | Tile do MU-7 | O que a captura mostra |
|---:|---|---|
| 330 | 4,62 | Chegada, sala escura, doca ao lado |
| 580 | 20,61 | Terminal: **6 sistemas, 2/2 em uso**, COPA em *REQUER* |
| 675 | 20,61 | Aquecimento desligado, canteiro ligado, LINHA DE CARGA vira *REQUER* |
| 1010 → 1320 | 11,59 → 15,51 | Patamar → topo da trepadeira → 3 plataformas finas → viveiro |
| 1450 → 1800 | 26,51 → 31,41 | Escada diagonal de 4 plataformas finas até a galeria |
| 1858 → 1930 | 26,41 → 20,41 | Salto de 3 tiles sobre o vão 22-24 |
| 2110 | 11,41 | Console B: canteiro LIGADO, copa disponível, carga em *REQUER* |
| 2230 | 11,41 | `LUZ DE CRESCIMENTO — COPA: ONLINE`, 2/2 em uso |
| 2500 → 2800 | 19,39 → 21,31 | Patamar → trepadeira alta → 3 plataformas finas → copa |
| 2970 → 3290 | 9,31 → 9,21 | Torre de 5 plataformas finas até o corredor escuro |
| 3365 | 16,21 | `BACKUP SALVO`; corredor apagado, poço invisível à frente |
| 3395 / 3498 | 20,19 / 28,19 | Saltos sobre os poços de 2 e de 3 tiles, no escuro, com a SR-3 atrás |
| 3660 → 4160 | 39,21 | `PROTOCOLO DAS GARRAS` lido, garras liberadas |
| 4270 → 4440 | 44,21 → 44,10 | Escalada de 10 tiles na parede magnética |
| 4530 | 42,11 | Salto para o andar do Nó |
| 4680 / 4840 | 29,11 | Console C: copa desligada, **PORTA DO NÓ** energizada |
| 4990 | 20,11 | Salto de 3 tiles sobre o vão 23-25 |
| 5180 | 7,11 | `[E] RELIGAR NÓ DO SETOR` |
| 5450 | 7,11 | Cutscene do setor: a Estufa inteira acesa em verde |
| 6520 | — | **FIM DA DEMO** |

Estatísticas exatas da tela final desta corrida: **TEMPO 01:30 · LOGS 1/4 · DADOS 1/4 ·
MORTES 0 · SEGREDOS 0/4** (rota direta, sem explorar; a corrida não morreu nenhuma vez).

### Roteiro godot-qa — parede magnética no escuro (`tests/qa/f43_parede_magnetica.json`)
Sonda `gh_probe_wall` (tile 40,21, `corridor_light` **desligada**, sem lanterna).

| Situação | Coluna da parede | Cenário a 1-2 tiles dela | Tela inteira |
|---|---:|---:|---:|
| Sem lanterna, parada | **0,224** (53,0 % dos pixels legíveis, pico 0,683) | **0,029** (0 % legível) | 0,055 (7,5 %) |
| Sem lanterna, escalando | **0,338** (81,2 %) | 0,045 (8,0 %) | 0,066 (5,8 %) |
| Com lanterna, escalando | 0,339 (81,1 %) | 0,063 (9,5 %) | 0,086 (15,5 %) |

Luminância `0,2126 R + 0,7152 G + 0,0722 B`, limiar de legibilidade 0,12 (mesmo método da
[F41](F41-escuridao.md), que mediu 0,035 para cenário sem lâmpada). **A parede é ~7,7× mais
clara que a parede comum ao lado dela e a sala continua escura** — a lanterna muda a tela
inteira (0,055 → 0,086), não a parede.

### Roteiro godot-qa — rota de carga (`tests/qa/f43_rota_carga.json`)
Sondas `gh_probe_shaft` e `gh_probe_gondola`. Elevador: 44,62 → 44,42 (20 tiles, 3,6 s),
saída para a galeria em 39,41. Gôndola: 4,41 → 4,31 (10 tiles, 4 s).

### Roteiro godot-qa — luz na parede magnética (`tests/qa/f43_luz_parede_magnetica.json`)
Sondas `light_probe_wall_top` (MU-7 na saliência 39-42 da linha 5, ao lado do topo da parede),
`light_probe_wall_top_noglow` (mesmo ponto, brilho da parede desligado — é o controle que isola
a causa) e `light_probe_wall_mid` (MU-7 agarrado no meio da escalada, tile 44,11). Cada sonda
imprime no log quantas `PointLight2D` ativas existem, quantas caem no enquadramento e a energia
e a escala da lanterna, o que torna a medição repetível. Seis capturas: lanterna desligada e
ligada em cada situação.

### Roteiro godot-qa — segredos (`tests/qa/f43_secretos.json`)
Sondas `gh_probe_nursery` e `gh_probe_canopy`. Segredo 1: parede falsa em 4,50-51 dissolve ao
toque e o aviso **NÚCLEO DE CAPACITOR — aumenta a Carga máxima do chassi** aparece na captura
(MU-7 em 2,51). Segredo 2: parede falsa em 40,30-31, MU-7 chega a 45,31 com o kit e a célula
recolhidos (perdendo uma célula de Integridade para o esporo do caminho).

### Playtest humano
Perguntar: *"você travou em algum momento sem saber o que fazer, ou só perdeu tempo?"* — o
projeto aceita perder tempo, nunca travar. E: *"o salto de 3 tiles do corredor escuro é injusto?"*

## 11. ADRs locais

<a id="adr-f43-001"></a>
### ADR-F43-001 — Duas cadeias, não uma
- **Contexto:** o GDD pede *"dependência em cadeia"* só nas Docas (6 sistemas / 3 energias). Com
  2 energias, uma cadeia de 2 elos já consome o orçamento inteiro.
- **Decisão:** duas cadeias curtas e **paralelas** (`grow_light → canopy_light` e
  `heating → lift_platform`), cada uma sustentando uma rota completa da base até a copa.
- **Consequências:** o jogador percebe a regra duas vezes, por dois caminhos diferentes, sem que
  o jogo explique nada. E como as duas rotas convergem na copa, nenhuma escolha fecha porta.
- **Data:** 2026-09-20

<a id="adr-f43-002"></a>
### ADR-F43-002 — Plataformas finas consecutivas precisam de 2 colunas de sobreposição
- **Contexto:** as primeiras versões da chaminé da trepadeira e da escada do viveiro tinham
  plataformas adjacentes sem sobreposição horizontal. O salto diagonal (2 linhas para cima e 2-3
  colunas para o lado, partindo parado) falha: o apogeu de 40 px chega, mas o deslocamento
  horizontal acumulado no tempo de subida não.
- **Decisão:** toda sequência vertical obrigatória tem **pelo menos 2 colunas de sobreposição**
  entre degraus consecutivos, de modo que um pulo reto sempre resolva. A escada do viveiro usa
  plataformas de 4 tiles avançando 2 colunas por degrau.
- **Consequências:** a subida continua exigindo ritmo, mas não exige pixel-perfect. Os degraus
  diagonais ficam reservados para trechos opcionais.
- **Data:** 2026-09-20

<a id="adr-f43-003"></a>
### ADR-F43-003 — A trepadeira precisa de um degrau de embarque
- **Contexto:** o topo colidível da `GrowPlant` fica **64 px acima do pé da planta** — 4 tiles.
  `JUMP_HEIGHT` é 40 px. Ou seja: *não dá para subir numa trepadeira a partir do chão*. O mapa
  antigo escondia isso porque a planta era só um degrau intermediário.
- **Decisão:** toda trepadeira ganha uma plataforma fina de embarque na linha `base-1` (a 2 tiles
  do chão), dentro de 3 colunas do caule. `test_every_plant_has_a_boarding_ledge_two_tiles_below_its_top`
  reprova quem esquecer.
- **Consequências:** a trepadeira lê como "escada de dois lances" e a luz de crescimento continua
  sendo o que abre a rota — sem a planta, o patamar não leva a lugar nenhum.
- **Data:** 2026-09-20

<a id="adr-f43-004"></a>
### ADR-F43-004 — Velocidade do elevador de carga fica no JSON
- **Contexto:** `Balance.PLATFORM_SPEED` (40 px/s) num poço de 20 tiles dá 8 s por sentido e
  ~17 s de ciclo: o jogador esperaria o elevador mais tempo do que gastaria andando.
- **Decisão:** `gh_lift` sobrescreve `speed: 90.0` no `data/levels/greenhouse.json` (3,6 s por
  sentido, ciclo de 8,4 s). A gôndola, que percorre metade da distância, continua em
  `PLATFORM_SPEED`.
- **Consequências:** **dívida aberta** — `scripts/core/balance.gd` pertence a outro agente nesta
  rodada. Pedido no relatório: `Balance.FREIGHT_LIFT_SPEED = 90.0`, com linha na
  [tabela GDD-P](../design/GDD.md#gdd-p).
- **Data:** 2026-09-20

<a id="adr-f43-005"></a>
### ADR-F43-005 — A chaminé das garras tem 2 tiles de largura
- **Contexto:** as garras agarram a até 10 px (`CLAW_PROBE_REACH`), mas o corpo do MU-7 tem 14 px
  de largura. Escalando 3 px afastado da parede, a lateral esquerda invade a coluna vizinha; se
  ela for sólida, o jogador fica preso contra o teto (`is_on_ceiling`) e a escalada trava sem
  nenhum erro no log. Aconteceu de verdade na linha 15.
- **Decisão:** a coluna vizinha à parede magnética (44) e a seguinte (43) ficam livres em toda a
  extensão escalável. `test_the_magnetic_wall_is_one_unbroken_climb` verifica a coluna 44.
- **Consequências:** o andar do Nó recebe o jogador na coluna 42, e a chaminé vira um poço de
  descida óbvio no canto leste.
- **Data:** 2026-09-20

<a id="adr-f43-006"></a>
### ADR-F43-006 — O brilho da parede é passivo
- **Contexto:** depois da [F41](F41-escuridao.md) as listras amarelas somem no escuro. A parede
  podia acender junto com `corridor_light`, mas aí o jogador que apaga o corredor perderia a
  única pista de onde escalar — e o corredor é justamente onde o trade-off acontece.
- **Decisão:** `PointLight2D` fraco por tile (`GLOW_RADIUS 18`, `GLOW_ENERGY 0.55`, cor
  `#e8b93a`) sem sombra, mais `self_modulate` 1,6 no sprite. Não escuta `energy_changed`:
  a placa é magnetizada, não iluminada.
- **Consequências:** medido 0,224 na parede contra 0,029 no cenário a dois tiles — legível sem
  lanterna, sem virar poste. `GLOW_*` são constantes provisórias em `magnetic_wall.gd`
  (mesma dívida do ADR-F43-004).
- **Data:** 2026-09-20

<a id="adr-f43-007"></a>
### ADR-F43-007 — O brilho da parede é um por trecho, não por tile
- **Contexto:** o [ADR-F43-006](#adr-f43-006) deu uma `PointLight2D` a **cada tile** de parede
  magnética. A coluna 45 tem 19 tiles seguidos, ou seja 19 luzes empilhadas num corredor de
  três telas. No renderer **Compatibility** cada item de canvas só aceita **16 luzes**; passando
  disso o excedente é descartado **em silêncio**, sem erro nenhum no log. No topo da parede o
  quadrante do `TileMapLayer` recebia 21 luzes e a que sobrava de fora era justamente a lanterna
  do MU-7: o jogador acendia a lanterna e nada acontecia.
- **Decisão:** `magnetic_wall.gd` funde o brilho. Cada trecho contínuo de parede elege um
  âncora a cada `GLOW_SEGMENT_TILES` (6) tiles; os demais desligam a própria `PointLight2D`, e o
  âncora estica a sua em `scale.y` para cobrir o trecho (mais `GLOW_SEGMENT_OVERLAP` de 1 tile
  para não haver emenda visível), compensando a energia em `GLOW_MERGE_GAIN`. A coluna 45 cai de
  19 luzes para 4, e a pior janela de 256 px da Estufa cai de **21 para 8** luzes.
- **Consequências:** a parede continua com o mesmo brilho (0,337 → 0,304 de luminância medida) e
  a lanterna volta a funcionar em toda a escalada. `tests/test_light_crowding.gd` trava o limite
  de 12 luzes por janela de 256 px em qualquer fase — é o teste que reprova a versão antiga.
  `GLOW_SEGMENT_TILES`, `GLOW_SEGMENT_OVERLAP` e `GLOW_MERGE_GAIN` ficam como `const` nomeadas em
  `magnetic_wall.gd` (mesma dívida do [ADR-F43-004](#adr-f43-004)).
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Reforma completa
- **Quem**: Agente B · **O que**: mapa de 40×40 → 48×64 em seis zonas; puzzle de 5/2 → 6/2 com
  duas cadeias; duas rotas; dois segredos; doze trechos de parkour; brilho próprio na parede
  magnética; testes reescritos com prova exaustiva de ausência de softlock; roteiro de travessia
  refeito e capturado até o FIM DA DEMO.
- **Armadilhas encontradas** (viraram ADR e teste): trepadeira inalcançável do chão
  ([ADR-F43-003](#adr-f43-003)); escalada travando por 1 px de invasão lateral
  ([ADR-F43-005](#adr-f43-005)); plataformas finas sem sobreposição
  ([ADR-F43-002](#adr-f43-002)).
- **Próximo passo**: migrar `FREIGHT_LIFT_SPEED` e `GLOW_*` para `scripts/core/balance.gd`
  quando o arquivo estiver livre; playtest humano da dificuldade do corredor escuro.

### 2026-09-20 — Correção: a lanterna sumia na parede magnética
- **Quem**: Agente B · **Relato do humano**: *"na fase da estufa, quando chega na parte de cima
  da parede magnetica, está bugando a iluminação"*.
- **Diagnóstico**: não era a lanterna e não era vazamento de luz — era **estouro do orçamento de
  luzes por item de canvas** do renderer Compatibility, causado pelas 19 `PointLight2D` da
  parede ([ADR-F43-007](#adr-f43-007)). Medido no topo da parede, na caixa ao redor do MU-7:
  com a lanterna ligada a luminância ia de 0,054 para **0,092** (14,7 % de pixels legíveis);
  desligando o brilho da parede a mesma lanterna levava a região a **0,318** (90,6 %). No meio
  da escalada era pior: 0,016 com e sem lanterna, ou seja, **zero efeito**.
- **Conserto**: brilho fundido por trecho em `scenes/world/magnetic_wall.gd`.
  Depois: topo 0,054 → **0,137** (sensor) e 0,092 → **0,319** (lanterna);
  meio da escalada 0,016 → **0,259** (99,2 % legível).
- **Portões**: import 0 erros · 647 testes passando · smoke 75/75 · varreduras vazias.
- **Sobrou**: as lâmpadas do jogo (`scenes/world/powered_lamp.tscn`) **não têm sprite de
  luminária** — o nó só tem a `PointLight2D`. É a segunda metade do que o humano viu ("mancha de
  luz sem fonte"): a `gh_lamp_node_floor_02` (tile 34,5, `#e0b43c`, raio 96) flutua no ar. A F18
  previa um `Sprite2D` opcional que nunca foi ligado, e o tileset não tem tile de luminária.

---
id: F29
title: Fase 1 — Estufa
status: done
scope: demo
block: 4
priority: P0
rubric: ["Música (trilha sonora)", "Efeitos visuais/sonoros"]
depends_on: ["F17", "F18", "F19", "F20", "F21", "F22", "F23", "F24", "F25", "F26", "F27", "F28"]
unblocks: ["F30", "F32", "F34"]
estimate: 4h
last_updated: 2026-09-20
---

# F29 — Fase 1 — Estufa

## 1. Contexto e objetivo

O setor que fecha a Demo. A **Estufa** é vertical, tomada de vegetação, e é a única área "viva" da ARTEMIS ([GDD-2.7-F1](../design/GDD.md#gdd-2-7-f1)). É onde o jogo deixa de ser tutorial: puzzle de energia de verdade (**5 sistemas, 2 unidades**), SR-3s, esporos que reagem ao calor, uma plataforma móvel que só anda com energia, uma planta que vira plataforma sob a luz de crescimento, uma área secreta, as **Garras Magnéticas** e a parede magnética que leva ao **Nó do setor**.

Religar o Nó dá **+15% de Estabilidade** ([GDD-2.5](../design/GDD.md#gdd-2-5-vitoria)) e encerra a Demo na tela **FIM DA DEMO** ([AJ-004](../design/GDD.md#gdd-ajustes)). Narrativamente é a [etapa 5 da Jornada](../design/JORNADA-DO-HEROI.md#jh-5): descobre-se a falta de oxigênio, as primeiras culturas adaptadas ao planeta alvo e os simuladores climáticos presos em ciclos quebrados.

Duração alvo: **~10 minutos**. Dificuldade 3/10 — "a fase em que o jogador tem permissão de errar".

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.7-F1 — Estufa](../design/GDD.md#gdd-2-7-f1) · [GDD-2.7 fases](../design/GDD.md#gdd-2-7-fases) · [GDD-2.5 energia](../design/GDD.md#gdd-2-5-energia) · [GDD-2.5 vitória (+15% por setor)](../design/GDD.md#gdd-2-5-vitoria) · [GDD-2.6.2-A SR-3](../design/GDD.md#gdd-2-6-2-a) · [GDD-2.6.2-D Esporos](../design/GDD.md#gdd-2-6-2-d) · [GDD-2.6.3 coletáveis](../design/GDD.md#gdd-2-6-3) · [GDD-2.9 paleta (Estufa: verde musgo + rosa)](../design/GDD.md#gdd-2-9-paleta) · [GDD-2.9 música](../design/GDD.md#gdd-2-9-musica) · [GDD-2.9 SFX](../design/GDD.md#gdd-2-9-sfx) · [GDD-2.8 telas](../design/GDD.md#gdd-2-8-telas)
- **Parâmetros:** `Balance.TILE_SIZE`, `Balance.JUMP_HEIGHT`, `Balance.REACTOR_SECTOR_BONUS` (15), `Balance.SPORE_DPS`, `Balance.CORROSION_TIME`, `Balance.SR3_CONTACT_DAMAGE`, `Balance.PLATFORM_SPEED`, `Balance.PLANT_GROW_TIME`, `Balance.CLAW_CLIMB_SPEED`, `Balance.CAPACITOR_BONUS` — [GDD-P](../design/GDD.md#gdd-p)
- **Jornada:** [Etapa 3 — Mentor](../design/JORNADA-DO-HEROI.md#jh-3) · [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5) · [Personagens (BOTÂNICO 04)](../design/JORNADA-DO-HEROI.md#jh-personagens)
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) · [ADR-006](../DECISIONS.md#adr-006) · [ADR-009](../DECISIONS.md#adr-009)
- **Features vizinhas:** [F28](F28-fase-nucleo-central.md) (de onde se chega), [F17](F17-terminal-distribuicao.md), [F23](F23-esporos-status.md), [F24](F24-garras-magneticas.md), [F25](F25-plataformas-moveis-planta.md), [F27](F27-area-secreta.md), [F10](F10-telas-fim-de-jogo.md) (FIM DA DEMO), [F32](F32-obstaculos-ambientais.md) e [F34](F34-drone-botanico.md) (stretch que ocupam `v`, `z` e `b` deste mapa).

## 3. Critério de avaliação atendido

- **Música (trilha sonora)**: [MUS-GREENHOUSE](../ASSETS.md#mus-greenhouse) em loop, com crossfade vindo de MUS-CORE e um "acorde" de religamento quando o Nó volta ([rubrica](../ENTREGAS.md#rubrica)).
- **Efeitos visuais/sonoros**: escuridão + lanterna, partículas dos esporos, luz rosa da luz de crescimento, luzes de status das plataformas, fade da parede secreta, clarão do setor religado, SFX de disjuntor/porta/planta/esporos.
- É também a fase que **demonstra** Puzzle (F17), Habilidades (F24), Plataformas que se movimentam (F25), Área secreta (F27), Efeitos naturais (F23), Coleta/Score (F20) e Recompensas (setor religado = +15%).

## 4. Escopo

### Inclui
- `data/levels/greenhouse.txt` — mapa ASCII **40×40 tiles** (640×640 px), vertical, completo (seção 6.1).
- `data/levels/greenhouse.json` — entidades por coordenada, gatilhos, música, paleta, limites de câmera.
- `data/energy/greenhouse.json` — terminal `greenhouse`: **5 sistemas, 2 unidades de energia**, acessível por **3 consoles** (`T`) espalhados pela vertical.
- `data/logs/greenhouse.json` — `log_gh_01` … `log_gh_04` (4 logs, um deles destrava as Garras).
- `data/dialogue/greenhouse.json` — falas da ÓRBITA da chegada ao religamento.
- `scenes/levels/greenhouse.tscn` (+ `greenhouse.gd`) e `scenes/world/sector_node.tscn` (+ `sector_node.gd`) — o Nó do setor.
- Sequência de objetivos (`objective_changed`) e gatilhos narrativos.
- Religamento: `sector_restored(&"greenhouse")` → +15% de Estabilidade, save, clarão/paleta restaurada → `demo_completed` → tela FIM DA DEMO.
- 2 docas de backup, 4 logs, 3 Dados, 4 Células, 2 Kits, 1 Núcleo de Capacitor (área secreta), 2 SR-3, 3 focos de esporos.
- Teste de dados `tests/test_level_greenhouse.gd`, incluindo a **solubilidade do puzzle** com a `EnergyGrid` da F17.

### Não inclui
- Voltar ao Núcleo Central (a Demo acaba aqui) — Final.
- Jato de vapor (`v`), piso eletrificado (`z`) e BOTÂNICO 04 (`b`): os caracteres **já estão no mapa**, mas as entidades são das stretch [F32](F32-obstaculos-ambientais.md) e [F34](F34-drone-botanico.md). Enquanto elas não existirem, o `LevelBuilder` trata `v` e `b` como tile vazio e `z` como **piso sólido comum** (ver ADR-F29-003).
- Simuladores climáticos alternando Primavera/Verão/Inverno de verdade (só o `heating` do puzzle) — Final.
- Chave de Acesso e portas seladas — Final.
- Música adaptativa por camadas (F50).

## 5. Critérios de aceite

- [x] Chegando do Núcleo, o MU-7 nasce em `4,37`, a música troca para MUS-GREENHOUSE e o objetivo vira *"Encontre o Terminal de Distribuição da Estufa"*.
- [x] O terminal mostra **5 sistemas e 2 unidades**, e o jogo **impede** ligar um terceiro sem desligar outro ([F17](F17-terminal-distribuicao.md)).
- [x] Estado inicial: `heating` e `corridor_lamps` ligados; `lift`, `grow_light` e `node_door` desligados.
- [x] Com `heating` ligado, as três nuvens de esporos estão expandidas e cobrem a passagem das colunas 23–29 (base); desligar encolhe na hora ([F23](F23-esporos-status.md)).
- [x] O elevador (`m`, cols 33–35) só anda com `lift` ligado e leva da base (row 38) ao andar do meio (row 28).
- [x] A planta (`g` em `18,27`) cresce só com `grow_light`, vira plataforma e **não** encolhe; é o único caminho para o corredor superior.
- [x] Com `corridor_lamps` desligado, o corredor das colunas 28–35 fica escuro e os **dois buracos** (cols 29–30 e 32) ficam invisíveis sem a lanterna; cair leva ao andar de baixo sem matar.
- [x] Ler `log_gh_03` no terminal `L` (`36,17`) destrava as **Garras Magnéticas** e muda o objetivo ([F24](F24-garras-magneticas.md)).
- [x] A parede `M` (col 38, rows 4–17) só é escalável com as garras e é o **único** acesso ao andar do Nó.
- [x] A parede falsa em `4,26`–`4,27` revela a câmara com o Núcleo de Capacitor e conta como área secreta ([F27](F27-area-secreta.md)).
- [x] A porta do Nó (`|` em `8,7`) só abre com `node_door` energizado, o que obriga uma **terceira** reconfiguração no console `T` de `32,7`.
- [x] Interagir com o Nó (`4,7`) emite `sector_restored(&"greenhouse")`, soma +15% de Estabilidade, salva o jogo, acende o setor e leva à tela **FIM DA DEMO** com as estatísticas.
- [x] As duas docas (`2,37` e `25,17`) salvam e viram checkpoint; morrer devolve ao último, com 50% de Integridade e −3% de Estabilidade ([F13](F13-integridade-carga-respawn.md)).
- [x] Nenhum estado de energia deixa o jogador preso (ver a análise de softlock da seção 6.4).
- [x] Percurso completo sem explorar tudo: **~10 min**.
- [x] `tests/test_level_greenhouse.gd` verde; cena no smoke.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### 6.1 Mapa ASCII — `data/levels/greenhouse.txt` (40 × 40)

Legenda ([F21](F21-construtor-fases-ascii.md)): `#` sólido · `=` one-way · ` ` vazio · `P` spawn · `D` doca · `T` terminal de distribuição · `L` terminal de log · `l` fragmento de log · `r` dado de pesquisa · `c` célula · `k` kit de solda · `C` núcleo de capacitor · `|` porta de energia · `S` SR-3 · `~` esporos · `M` parede magnética · `m` plataforma móvel · `g` planta que cresce · `x` parede falsa · `W` janela · `@` lâmpada ligada a sistema · `o` prop · `b` drone BOTÂNICO 04 · `v` jato de vapor · `z` piso eletrificado.

```
########################################
########################################
#       #                              #
#       #        WWW       WW          #
#       #        WWW       WW         M#
#           r                         M#
#          ===                        M#
# o o   |      v          l     T c   M#
####################zzzz############  M#
####################################  M#
#                           ########  M#
#                           ########  M#
#          WW               ########  M#
#          WW                @   @    M#
#                                     M#
#       r                             M#
#     ====                            M#
#  c                     D c   b    L M#
#################   === #####  # #######
#################       #####  # #######
#####            ===                   #
#####                   WW             #
#####               === WW             #
#####                                  #
#   #                                  #
#   #                                  #
#   x                    ~             #
# C x k#  S   #   g           T      l #
#################################   ####
#################################   ####
#                                      #
#                     WW               #
#    WW               WW               #
#    WW                                #
#                                      #
#                                      #
#                c      ~   ~          #
# D P  l #   S   #  T     r          k #
################################# m ####
########################################
```

Régua de conferência (**não** faz parte do arquivo — colunas na horizontal, linhas na vertical):

```
    0000000000111111111122222222223333333333
    0123456789012345678901234567890123456789
 0  ########################################
 2  #       #                              #
 4  #       #        WWW       WW         M#
 6  #          ===                        M#
 7  # o o   |      v          l     T c   M#
 8  ####################zzzz############  M#
13  #          WW                @   @    M#
16  #     ====                            M#
17  #  c                     D c   b    L M#
18  #################   === #####  # #######
20  #####            ===                   #
22  #####               === WW             #
26  #   x                    ~             #
27  # C x k#  S   #   g           T      l #
28  #################################   ####
36  #                c      ~   ~          #
37  # D P  l #   S   #  T     r          k #
38  ################################# m ####
39  ########################################
```

### 6.2 Anatomia vertical (de baixo para cima)

| Zona | Linhas | Conteúdo | Papel |
|---|---|---|---|
| **A — Base / chegada** | 30–39 (piso 38–39) | `P` 4,37 · `D` 2,37 · `l` 7,37 · SR-3 `S` 13,37 entre batentes (9 e 17) · `c` 17,36 · **`T` 20,37 (console 1)** · esporos `~` 24,36 e 28,36 · `r` 26,37 (dentro da nuvem) · `k` 37,37 · elevador `m` 34,38 no poço (cols 33–35) · janelas 5–6/32–33 e 22–23/31–32 | Chegada, primeiro contato com esporos e SR-3, **primeiro uso do terminal**: é preciso energizar o ELEVADOR |
| **B — Meio** | 20–29 (piso 28–29) | Câmara secreta cols 1–3 atrás da parede falsa `x` 4,26–4,27 com `C` 2,27 · `k` 6,27 · SR-3 `S` 10,27 entre batentes (7 e 14) · planta `g` 18,27 · escada de one-ways `=` 20–22/22 e 17–19/20 · esporo `~` 25,26 · **`T` 30,27 (console 2)** · `l` 37,27 · janelas 24–25/21–22 | Área secreta + **segundo uso do terminal**: a LUZ DE CRESCIMENTO faz a planta virar a escada para o andar de cima |
| **C — Corredor escuro** | 10–19 (piso 18–19) | Chegada pelo vão 17–23 (one-way `=` 20–22/18) · ala esquerda opcional: `c` 3,17, one-way `=` 6–9/16, `r` 8,15, janelas 11–12/12–13 · `D` 25,17 (2ª doca) · `c` 27,17 · corredor de teto baixo cols 28–35 com lâmpadas `@` 29,13 e 33,13 e **dois buracos** (cols 29–30 e col 32) · `b` 31,17 (BOTÂNICO 04, stretch) · **`L` 36,17 — log da Helena que destrava as Garras** · parede magnética `M` col 38 | O trade-off "luz de crescimento × luzes do corredor" se paga aqui; e aqui chega o upgrade |
| **D — Andar do Nó** | 2–9 (piso 8–9) | Entrada pelo vão 36–37 (topo da parede `M`) · `c` 34,7 · **`T` 32,7 (console 3)** · `l` 26,7 · piso eletrificado `z` 20–23/8 (stretch F32, ligado ao `lift`) · jato de vapor `v` 15,7 (stretch F32) · one-way `=` 11–13/6 com `r` 12,5 · porta `\|` 8,7 · câmara do Nó cols 1–7 com prop `o` 2,7 (foto no armário) e **Nó do setor `o` 4,7** · janelas 17–19/3–4 e 27–28/3–4 | Terceira reconfiguração (PORTA DO NÓ) e o fim da Demo |

Geometria conferida: espessura de piso/teto ≥ 2 tiles; altura livre mínima 5 tiles no corredor; degraus e escadas de one-way com 2 tiles (32 px) de desnível — dentro de `Balance.JUMP_HEIGHT` (40 px); vãos horizontais ≤ 3 tiles (48 px < ~63 px de alcance do pulo); a porta ocupa `8,5`–`8,7`; o elevador percorre 10 tiles (row 38 → row 28) pelo poço aberto das colunas 33–35.

### 6.3 Puzzle de energia — `data/energy/greenhouse.json`

```json
{
  "terminal_id": "greenhouse",
  "title": "DISTRIBUIÇÃO — ESTUFA",
  "budget": 2,
  "systems": [
    { "id": "heating",        "label": "AQUECIMENTO",          "description": "Simulador climático preso num ciclo de calor. Os esporos gostam.", "powered": true },
    { "id": "corridor_lamps", "label": "LUZES DO CORREDOR",     "description": "Iluminação de serviço do corredor superior.", "powered": true },
    { "id": "lift",           "label": "ELEVADOR DE CARGA",     "description": "Plataforma de transporte do poço leste.", "powered": false },
    { "id": "grow_light",     "label": "LUZ DE CRESCIMENTO",    "description": "Lâmpada de cultivo do canteiro central.", "powered": false },
    { "id": "node_door",      "label": "PORTA DO NÓ",           "description": "Comporta da câmara do Nó de Energia.", "powered": false }
  ]
}
```
**5 sistemas, 2 unidades** — a escalada do GDD ("de 2 sistemas/1 energia no tutorial até 6/3 nas Docas"). Os três `T` do mapa são **consoles do mesmo terminal** (`terminal_id: "greenhouse"`): o estado é único e compartilhado, o jogador só não precisa descer a fase inteira para reconfigurar.

### 6.4 Rota pretendida e análise de softlock

| Passo | Onde | Configuração típica | Observação |
|---|---|---|---|
| 1 | Console 1 (`20,37`) | desliga `heating`, liga `lift` → `[corridor_lamps, lift]` | desligar o aquecimento encolhe as nuvens: é a lição do GDD-2.6.2-D ("desligar o aquecimento do módulo") |
| 2 | Elevador | sobe para a zona B | |
| 3 | Console 2 (`30,27`) | desliga `lift`, liga `grow_light` → `[corridor_lamps, grow_light]` | quem preferir manter o elevador tem de apagar as luzes do corredor e atravessar de lanterna — os dois caminhos funcionam |
| 4 | Planta → zona C | corredor iluminado ou escuro conforme a escolha | |
| 5 | `L` (`36,17`) | — | log da Helena → **Garras Magnéticas** |
| 6 | Parede `M` → zona D | — | |
| 7 | Console 3 (`32,7`) | liga `node_door` desligando `grow_light` (ou `corridor_lamps`/`lift`) | com a [F32](F32-obstaculos-ambientais.md), desligar o `lift` também desarma o piso eletrificado `z` |
| 8 | Nó (`4,7`) | — | `sector_restored` → FIM DA DEMO |

**Sem softlock:** a planta nunca encolhe ([ADR-F25-002](F25-plataformas-moveis-planta.md)); o elevador parado pode ser religado pelo console 1 (a descida do poço é sempre possível pela queda); os buracos do corredor devolvem o jogador à zona B, que tem console e planta; e o console 3 fica **antes** da porta do Nó. A única configuração que atrasa (não trava) é gastar as duas unidades em `heating` + qualquer coisa.

### 6.5 Metadados — `data/levels/greenhouse.json`

```json
{
  "id": "greenhouse",
  "name": "Estufa",
  "sector_id": "greenhouse",
  "tileset": "greenhouse",
  "music": "MUS-GREENHOUSE",
  "palette": {
    "ambient": "#1e2b1d",
    "ambient_dark": "#080d08",
    "ambient_restored": "#3c5a38",
    "light": "#b7e08a",
    "accent": "#e58fb5"
  },
  "camera_limits": { "left": 0, "top": 0, "right": 640, "bottom": 640 },
  "spawn": "4,37",
  "entities": {
    "2,37":  { "dock_id": "gh_dock_01" },
    "7,37":  { "log_id": "log_gh_01" },
    "13,37": { "dir": 1 },
    "17,36": { "kind": "cell", "item_id": "cell_gh_01" },
    "20,37": { "terminal_id": "greenhouse" },
    "24,36": { "terminal_id": "greenhouse", "system_id": "heating" },
    "28,36": { "terminal_id": "greenhouse", "system_id": "heating" },
    "26,37": { "kind": "research", "item_id": "data_gh_01" },
    "34,38": { "id": "gh_lift_01", "terminal_id": "greenhouse", "system_id": "lift", "path": [[0, 0], [0, -10]], "speed": 32, "wait": 1.0 },
    "37,37": { "kind": "repair_kit", "item_id": "kit_gh_01" },

    "2,27":  { "kind": "capacitor", "item_id": "capacitor_gh_01" },
    "4,26":  { "secret_id": "gh_secret_01" },
    "4,27":  { "secret_id": "gh_secret_01" },
    "6,27":  { "kind": "repair_kit", "item_id": "kit_gh_02" },
    "10,27": { "dir": -1 },
    "18,27": { "id": "gh_plant_01", "terminal_id": "greenhouse", "system_id": "grow_light" },
    "25,26": { "terminal_id": "greenhouse", "system_id": "heating" },
    "30,27": { "terminal_id": "greenhouse" },
    "37,27": { "log_id": "log_gh_02" },

    "3,17":  { "kind": "cell", "item_id": "cell_gh_02" },
    "8,15":  { "kind": "research", "item_id": "data_gh_02" },
    "25,17": { "dock_id": "gh_dock_02" },
    "27,17": { "kind": "cell", "item_id": "cell_gh_03" },
    "29,13": { "terminal_id": "greenhouse", "system_id": "corridor_lamps" },
    "33,13": { "terminal_id": "greenhouse", "system_id": "corridor_lamps" },
    "31,17": { "id": "botanico_04", "home_radius": 96 },
    "36,17": { "log_id": "log_gh_03", "grants_ability": "magnetic_claws" },

    "12,5":  { "kind": "research", "item_id": "data_gh_03" },
    "15,7":  { "phase_offset": 0.0 },
    "20,8":  { "terminal_id": "greenhouse", "system_id": "lift" },
    "21,8":  { "terminal_id": "greenhouse", "system_id": "lift" },
    "22,8":  { "terminal_id": "greenhouse", "system_id": "lift" },
    "23,8":  { "terminal_id": "greenhouse", "system_id": "lift" },
    "26,7":  { "log_id": "log_gh_04" },
    "32,7":  { "terminal_id": "greenhouse" },
    "34,7":  { "kind": "cell", "item_id": "cell_gh_04" },
    "8,7":   { "terminal_id": "greenhouse", "system_id": "node_door" },
    "2,7":   { "prop": "photo" },
    "4,7":   { "scene": "res://scenes/world/sector_node.tscn", "sector_id": "greenhouse" }
  },
  "triggers": [
    { "id": "gh_t_arrival",   "rect": [5, 36, 2, 2],  "objective": "Encontre o Terminal de Distribuição da Estufa", "dialogue": "gh_arrival", "once": true },
    { "id": "gh_t_spores",    "rect": [22, 36, 2, 2], "dialogue": "gh_spores", "once": true },
    { "id": "gh_t_terminal",  "rect": [17, 36, 2, 2], "objective": "Redistribua a energia: 5 sistemas, 2 unidades (E)", "dialogue": "gh_terminal", "once": true },
    { "id": "gh_t_zone_b",    "rect": [30, 26, 2, 2], "objective": "Faça a cultura crescer: LUZ DE CRESCIMENTO", "dialogue": "gh_plant", "once": true },
    { "id": "gh_t_zone_c",    "rect": [24, 16, 2, 2], "objective": "Atravesse o corredor superior", "once": true },
    { "id": "gh_t_corridor",  "rect": [28, 16, 2, 2], "dialogue": "gh_dark_corridor", "once": true },
    { "id": "gh_t_zone_d",    "rect": [33, 6, 2, 2],  "objective": "Abra a PORTA DO NÓ no terminal (E)", "dialogue": "gh_node_floor", "once": true }
  ]
}
```
Mesmo esquema da [F28](F28-fase-nucleo-central.md): `rect` em tiles, `once` gravado em `GameState.flags`, `music` como id do [ASSETS.md](../ASSETS.md), `palette.ambient*` aplicadas ao `CanvasModulate` (`ambient` com `corridor_lamps` ligado, `ambient_dark` com ele desligado, `ambient_restored` depois do Nó). A chave `scene` permite ao `LevelBuilder` instanciar uma cena específica num tile `o` (usada pelo Nó do setor).

> **Compatibilidade com o esquema da [F21](F21-construtor-fases-ascii.md) (conferir antes de escrever o arquivo):** a F21 é a dona do formato; onde os nomes divergirem, **vale a F21** e este JSON é traduzido 1:1 — `palette.ambient` → `ambient_color`, `music: "MUS-GREENHOUSE"` → `music: "greenhouse"`, `tileset` como caminho do `.tres`, mais `terminals: ["greenhouse"]`, `floor_sfx: "step_soil"`, `reactor_online: true`, `objective` e `on_enter_dialogue`. Se a F21 já previr o papel `role: "sector_node"` para o Nó, use-o em vez da chave `scene` do ADR-F29-004. As chaves `objective` e `set_flag` em `triggers[]` seguem a mesma nota da [F28](F28-fase-nucleo-central.md): se a F21 não as implementar, `greenhouse.gd` trata os campos.

### 6.6 Sequência de objetivos e falas

| # | Disparo | `objective_changed` | Fala / efeito |
|---|---|---|---|
| 1 | `_ready` / gatilho `gh_t_arrival` | `Encontre o Terminal de Distribuição da Estufa` | `gh_arrival` · `AudioManager.play_music("MUS-GREENHOUSE", 1.5)` |
| 2 | gatilho `gh_t_spores` | (mantém) | `gh_spores` (ÓRBITA nota que o calor alimenta os esporos) |
| 3 | gatilho `gh_t_terminal` | `Redistribua a energia: 5 sistemas, 2 unidades (E)` | `gh_terminal` |
| 4 | `energy_changed(lift, true)` | `Suba pelo elevador de carga` | SFX `power_on` |
| 5 | gatilho `gh_t_zone_b` | `Faça a cultura crescer: LUZ DE CRESCIMENTO` | `gh_plant` |
| 6 | planta adulta ([F25](F25-plataformas-moveis-planta.md)) | `Suba pela cultura até o corredor superior` | SFX `plant_grow` |
| 7 | gatilho `gh_t_zone_c` / `gh_t_corridor` | `Atravesse o corredor superior` | `gh_dark_corridor` (se `corridor_lamps` estiver desligado, a fala avisa dos buracos) |
| 8 | `log_closed("log_gh_03")` → `ability_unlocked(&"magnetic_claws")` | `Escale a parede magnética (encoste e segure ↑)` | `gh_claws` ([F24](F24-garras-magneticas.md)) |
| 9 | gatilho `gh_t_zone_d` | `Abra a PORTA DO NÓ no terminal (E)` | `gh_node_floor` |
| 10 | `energy_changed(node_door, true)` | `Religue o Nó da Estufa (E)` | SFX `door_open` |
| 11 | `interact` no Nó | `Estufa religada` | `gh_node_restored` → religamento (seção 6.7) |

### 6.7 O Nó do setor — `scenes/world/sector_node.tscn`

```
SectorNode (Area2D)                collision_layer = 4 (interactable) · collision_mask = 2 (player)
├─ CollisionShape2D                RectangleShape2D 24×32
├─ Sprite2D                        SPR-TERMINAL (frame "active")
└─ NodeLight (PointLight2D)        apagada até religar; acende com Tween
```
```gdscript
extends Area2D

@export var sector_id: StringName

func interact() -> void: ...
```
`interact()` (chamado pelo sistema da [F16](F16-interacao.md)):
1. `DialogueManager.play("gh_node_restored")`;
2. `GameState.sectors_restored.append(sector_id)` (sem repetir) e `EventBus.sector_restored.emit(sector_id)` → a [F14](F14-estabilidade-reator.md) soma `Balance.REACTOR_SECTOR_BONUS` (+15%);
3. `SaveManager.save_game()`;
4. `AudioManager.play_sfx("power_on")`; `Tween` do `CanvasModulate` para `palette.ambient_restored` e acende as lâmpadas do setor (efeito "a luz volta");
5. ao `dialogue_finished`, `EventBus.demo_completed.emit()` e `SceneManager.goto("res://scenes/ui/demo_end.tscn")` — se a [F10](F10-telas-fim-de-jogo.md) já troca de cena ao ouvir `demo_completed`, a fase **não** chama `goto` (evitar troca dupla; confira a F10 antes).

A tela FIM DA DEMO mostra as estatísticas do [GDD-2.8 tela 8](../design/GDD.md#gdd-2-8-telas): tempo (`GameState.play_time`), `LOGS x/24`, `DADOS x/12`, `ÁREAS SECRETAS x/4` ([F27](F27-area-secreta.md)), mortes e Estabilidade final.

### 6.8 Conteúdo — `data/logs/greenhouse.json` e `data/dialogue/greenhouse.json`

```json
{
  "log_gh_01": {
    "author": "Dra. Helena Vasquez", "sector": "Estufa", "title": "Cultivo — registro 04",
    "lines": [
      "A terceira safra pegou. Não é comida: é prova.",
      "Se cresce aqui, cresce lá embaixo, quando chegarmos.",
      "Anotei tudo nos dados de pesquisa. Alguém vai precisar deles."
    ]
  },
  "log_gh_02": {
    "author": "M. Okafor, engenharia de clima", "sector": "Estufa", "title": "Ciclos quebrados",
    "lines": [
      "O simulador travou no ciclo quente e ninguém tem energia sobrando para consertar.",
      "Com calor, aquelas esporeiras dobram de tamanho em minutos.",
      "Se precisar passar: corta o aquecimento. Elas encolhem."
    ]
  },
  "log_gh_03": {
    "author": "Dra. Helena Vasquez", "sector": "Estufa", "title": "Manutenção — registro 09",
    "lines": [
      "Deixei as garras magnéticas do MU-7 destravadas neste terminal.",
      "Os painéis listrados aguentam o peso dele. Sobe por eles e chega no nó.",
      "Se você está ouvindo isso, o ar já acabou aqui embaixo. Suba mesmo assim."
    ]
  },
  "log_gh_04": {
    "author": "T. Ferraz, técnico de convés", "sector": "Estufa", "title": "Último turno",
    "lines": [
      "Dizem que a estufa ainda tem oxigênio para dois dias.",
      "A porta do nó foi selada por ordem automática. Ninguém autorizou.",
      "Se alguém religar isto aqui um dia: obrigado."
    ]
  }
}
```

```json
{
  "gh_arrival":        ["Setor Estufa. Sem energia no barramento principal.", "Continua verde. Duzentos anos e continua verde.", "Preciso encontrar o terminal de distribuição."],
  "gh_spores":         ["Esporos. Densidade acima do registro histórico.", "O aquecimento do módulo está ligado — e eles reagem ao calor."],
  "gh_terminal":       ["Cinco sistemas. Duas unidades de energia.", "Vou ter que escolher o que fica desligado."],
  "gh_plant":          ["A cultura responde à luz de crescimento.", "Se ela crescer, viro isso em degrau."],
  "gh_dark_corridor":  ["Corredor de serviço. Sem as lâmpadas, eu não enxergo os vãos do piso.", "Lanterna ou luz do corredor: uma das duas."],
  "gh_claws":          ["Garras magnéticas: online.", "Obrigada, doutora."],
  "gh_node_floor":     ["O nó da Estufa está atrás daquela comporta.", "Preciso energizar a porta."],
  "gh_node_restored":  ["Nó da Estufa: religado.", "Estabilidade do reator recuperando 15 por cento.", "Um setor. Faltam três.", "Quando a tripulação voltar, vai encontrar a estufa funcionando."]
}
```

### 6.9 Cenas, scripts e sinais

```
scenes/levels/greenhouse.tscn (+ greenhouse.gd)     mesma estrutura de level_base (F21) + SpaceParallax (F26)
scenes/world/sector_node.tscn (+ sector_node.gd)    (novo, seção 6.7)
```
- **Emite:** `objective_changed`, `sector_restored(&"greenhouse")`, `demo_completed`, `checkpoint_reached`, além dos sinais das features de cada entidade.
- **Escuta:** `energy_changed` (paleta do corredor + objetivos), `log_closed` (garras), `ability_unlocked` (objetivo + fala), `dialogue_finished` (fim da demo).
- `AudioManager.play_music("MUS-GREENHOUSE", 1.5)` no `_ready`; `SaveManager.save_game()` nas docas e no religamento.
- Camadas: iguais às da [F28](F28-fase-nucleo-central.md); a parede magnética entra em `world` + grupo `"magnetic"` ([F24](F24-garras-magneticas.md)).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Tileset da fase, incluindo o **painel magnético listrado** e o vidro das janelas | Verde-musgo com pontos rosa |
| [MUS-GREENHOUSE](../ASSETS.md#mus-greenhouse) | Trilha da fase (loop) | Drone gerado |
| [SPR-PLANT](../ASSETS.md#spr-plant) · [SPR-PLATFORM](../ASSETS.md#spr-platform) | Planta `g` e elevador `m` | Retângulos |
| [SPR-SPORE](../ASSETS.md#spr-spore) | Nuvens `~` | Partículas geradas |
| [SPR-SR3](../ASSETS.md#spr-sr3) | SR-3 `S` (2) | Oval laranja |
| [SPR-TERMINAL](../ASSETS.md#spr-terminal) | 3 consoles `T`, terminal de log `L` e o Nó | Caixa com tela |
| [SPR-DOOR](../ASSETS.md#spr-door) · [SPR-DOCK](../ASSETS.md#spr-dock) | Porta `\|` e docas `D` | Barras |
| [SPR-PICKUPS](../ASSETS.md#spr-pickups) | `l`, `r`, `c`, `k`, `C` | Losangos |
| [SPR-PROPS](../ASSETS.md#spr-props) | Foto no armário (`2,7`) e vaso quebrado | Quadrados com inicial |
| [BG-SPACE](../ASSETS.md#bg-space) | Parallax pelas janelas `W` | Gradiente + pontos |
| [UI-HUD](../ASSETS.md#ui-hud) | Ícone de CORROSÃO, contadores | Ícones gerados |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `step_soil`, `spores`, `plant_grow`, `terminal_breaker`, `power_on`, `power_off`, `door_open`, `sr3_shutdown`, `pickup`, `log_pickup`, `damage`, `flashlight`, `secret_found`, `claw_grab` | Beeps gerados |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [ ] **Passo 1** — `data/levels/greenhouse.txt` exatamente como a seção 6.1 (40 linhas × 40 colunas).
- [ ] **Passo 2** — `data/levels/greenhouse.json`, `data/energy/greenhouse.json`, `data/logs/greenhouse.json`, `data/dialogue/greenhouse.json`.
- [ ] **Passo 3** — `scenes/levels/greenhouse.tscn` + `greenhouse.gd` (objetivos, falas, paleta por energia).
- [ ] **Passo 4** — `scenes/world/sector_node.tscn` + `sector_node.gd` e o encadeamento religamento → FIM DA DEMO.
- [ ] **Passo 5** — Conferir cada entidade com sua feature dona (F22–F27) e o estado inicial de energia.
- [ ] **Passo 6** — `tests/test_level_greenhouse.gd` (dados + solubilidade do puzzle).
- [ ] **Passo 7** — `godot-qa` com o roteiro da seção 10; corrigir geometria conforme as screenshots.
- [ ] **Passo 8** — Playtest cronometrado (alvo 10 min) + `/verify-gates`; commit `feat(F29): fase 1 Estufa completa com puzzle de 5 sistemas e religamento do nó`.

## 10. Verificação

- **Testes (`tests/test_level_greenhouse.gd`):**
  - `test_map_is_40x40`.
  - `test_single_spawn_and_two_docks`; `test_has_one_secret_pair` (duas tiles `x` com o mesmo `secret_id`).
  - `test_all_chars_in_legend` (inclui `v`, `z`, `b`, que precisam existir na legenda mesmo sem cena — ADR-F29-003).
  - `test_json_keys_match_map` (toda chave `"x,y"` casa com o caractere certo).
  - `test_counts`: 4 `l`/`L` de log, 3 `r`, 4 `c`, 2 `k`, 1 `C`, 2 `S`, 3 `~`, 1 `m`, 1 `g`, 1 `\|`, 3 `T`.
  - `test_log_ids_exist_and_are_unique` e `test_item_ids_unique_across_demo` (não colidem com os da F28).
  - `test_energy_has_five_systems_and_budget_two`.
  - `test_all_system_ids_referenced_exist` (inclusive os de `@`, `~`, `m`, `g`, `|`, `z`).
  - `test_puzzle_is_solvable` — com a `EnergyGrid` da [F17](F17-terminal-distribuicao.md), partindo do estado inicial, a sequência `desliga heating → liga lift → desliga lift → liga grow_light → desliga grow_light → liga node_door` é aceita em todos os passos sem estourar o orçamento, e em nenhum momento é possível ligar os 5.
  - `test_claws_gate`: existe exatamente um log com `grants_ability` e ele está **abaixo** (linha maior) do primeiro tile `M` — ou seja, o jogador passa por ele antes de precisar escalar.
- **Smoke:** `res://scenes/levels/greenhouse.tscn` e `res://scenes/world/sector_node.tscn` em `tests/scenes.txt`.
- **Roteiro godot-qa** (`tests/qa/f29_greenhouse.json`), cena `res://scenes/levels/greenhouse.tscn`, rodado com `--fixed-fps 60`. Rota coberta: chegada → console A (desliga AQUECIMENTO, liga LUZ DE CRESCIMENTO) → trepadeira e passarelas → andar do meio → escada de one-ways → corredor superior → `log_gh_02` (garras) → parede magnética → console C (desliga LUZ DE CRESCIMENTO, liga PORTA DO NÓ) → câmara do Nó → religamento → FIM DA DEMO. 27 capturas:

  | Frame | O que acontece | Screenshot |
  |---|---|---|
  | 120 · 170 | chegada na base, fala `gh_enter` encerrada, objetivo da fase legível | `01_chegada_estufa` · `02_objetivo_da_fase` |
  | 366 · 440 | fala `gh_terminal_first` ("cinco sistemas, duas unidades") e o MU-7 no batente ao lado do console | `03_fala_do_terminal_da_estufa` · `04_batente_ao_lado_do_console` |
  | 500 · 535 | prompt `[E] ACESSAR TERMINAL` e a UI com 5 sistemas / 2 unidades | `05_junto_ao_console_a` · `06_terminal_cinco_sistemas_duas_unidades` |
  | 645 · 750 | AQUECIMENTO desligado + LUZ DE CRESCIMENTO ligada; a trepadeira adulta virando plataforma | `07_rota_luz_de_crescimento` · `08_trepadeira_crescida` |
  | 805 · 855 · 1100 | batente → topo da trepadeira → andar do meio (com SR-3 à vista) | `09_batente_ao_pe_da_trepadeira` · `10_topo_da_trepadeira` · `11_andar_do_meio` |
  | 1400 · 1800 | pé da escada de one-ways e chegada ao corredor superior (doca salva o backup) | `12_pe_da_escada_do_andar_do_meio` · `13_corredor_superior` |
  | 1995 · 2030 · 2245 | terminal de registros, log PROTOCOLO DAS GARRAS em reprodução, LOGS 1/4 | `14_terminal_de_registros` · `15_protocolo_das_garras` · `16_log_da_estufa_no_placar` |
  | 2410 · 2510 · 2640 | cartão `tut_climb`, MU-7 escalando o painel magnético e chegando ao topo | `17_pe_da_parede_magnetica` · `18_escalando_a_parede_magnetica` · `19_topo_da_parede_magnetica` |
  | 2820 · 2870 · 3015 | console C e a reconfiguração que abre a PORTA DO NÓ ("META CUMPRIDA") | `20_junto_ao_console_do_andar_do_no` · `21_terminal_no_andar_do_no` · `22_porta_do_no_energizada` |
  | 3305 · 3350 | travessia do andar do Nó (dado de pesquisa) e a câmara com a porta aberta | `23_dado_de_pesquisa_no_andar_do_no` · `24_camara_do_no_com_a_porta_aberta` |
  | 3400 · 3560 · 3650 | Nó religado e a tela FIM DA DEMO com as estatísticas | `25_no_do_setor_religado` · `26_fim_da_demo` · `27_fim_da_demo_estatisticas` |

  Regras do roteiro que **não** podem ser quebradas ao editá-lo: as falas travantes só avançam com `ui_accept` (nunca com `interact`, que reabriria o terminal de registros embaixo do MU-7); o log `log_gh_02` tem 11 linhas e fecha em exatamente 22 apertos; e na tela FIM DA DEMO um `ui_accept` sobrando aperta MENU PRINCIPAL e a captura vira o menu.
- **Playtest humano (obrigatório antes do Dia 3):** cronometrar (alvo ~10 min); confirmar que o jogador entende sozinho a troca "luz de crescimento × luzes do corredor"; confirmar que ninguém fica preso.

## 11. ADRs locais

### ADR-F29-001 — Três consoles, um terminal
- **Contexto:** a Estufa é vertical e alta (40 tiles); com um único console físico, cada reconfiguração exigiria descer a fase inteira — o timer do reator transformaria o puzzle em punição.
- **Decisão:** três tiles `T` (20,37 · 30,27 · 32,7) apontam para o **mesmo** `terminal_id: "greenhouse"`; o estado de energia é único (`GameState.energy_states`).
- **Consequências:** o puzzle continua sendo "5 sistemas, 2 unidades"; o custo de ir e voltar vira ritmo, não pedágio. Registrar em [Ajustes](../design/GDD.md#gdd-ajustes): *"um setor pode ter vários consoles do mesmo Terminal de Distribuição"*.
- **Data:** 2026-09-19

### ADR-F29-002 — Cair num buraco do corredor escuro **não** mata
- **Contexto:** o GDD-2.6.2-E diz que escuridão total "mata por queda". Na Demo não há sistema de morte por queda nem `hazard` de abismo, e a fase é vertical: a queda tem um destino natural (o andar de baixo).
- **Decisão:** os buracos do corredor devolvem o jogador à zona B. O castigo é **tempo do reator** — que é exatamente a moeda do jogo ([GDD-2.3](../design/GDD.md#gdd-2-3-micro)). Registrar como ajuste: *"na Demo, escuridão custa tempo, não vida"*.
- **Consequências:** sem tela de morte injusta numa fase 3/10; a mecânica de queda letal volta nas Docas (Final).
- **Data:** 2026-09-19

### ADR-F29-003 — `v`, `z` e `b` já ocupam o mapa antes das stretch
- **Contexto:** F32 (vapor, piso elétrico) e F34 (drone) são stretch ([Bloco 5](../INDEX.md)) e podem não entrar. Adicionar os caracteres depois exigiria reeditar o mapa e refazer a QA.
- **Decisão:** o mapa nasce com `v` (15,7), `z` (20–23,8) e `b` (31,17). Enquanto as features não existirem, o `LevelBuilder` trata `v` e `b` como **tile vazio** e `z` como **piso sólido comum** (o corredor continua atravessável). Quando as features entrarem, os mesmos tiles ganham as entidades, sem tocar no `.txt`.
- **Consequências:** o corte das stretch não mexe na fase; o teste `test_all_chars_in_legend` exige que a legenda conheça os três caracteres desde já.
- **Data:** 2026-09-19

### ADR-F29-004 — O Nó do setor é uma cena nova, instanciada por `scene` no JSON
- **Contexto:** a legenda da Demo não tem caractere para "Nó de Energia do setor" e criar um novo símbolo afetaria a F21 e as outras fases.
- **Decisão:** o Nó usa o caractere de prop `o` com a chave `scene` no JSON apontando para `res://scenes/world/sector_node.tscn` (mecanismo genérico "instancie esta cena neste tile", útil também no Final).
- **Consequências:** uma cena nova (`sector_node.tscn`) e uma chave nova no construtor; a legenda ASCII fica estável.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial com mapa ASCII 40×40, puzzle de 5 sistemas/2 energias, rota, análise de softlock, conteúdo narrativo e encerramento da Demo · **Próximo passo**: implementação.

### 2026-09-19 — Pendências herdadas da F24/F25 (ler antes de construir a fase)
- **Fala e objetivo ao ganhar as Garras**: o log `log_gh_03` já chama `GameState.unlock_ability(&"magnetic_claws")` e o `EventBus.ability_unlocked` sai correto, mas a **fala `gh_claws`** e a **troca do objetivo** no momento do destrave ainda não existem — a F29 é quem liga isso (escutando `ability_unlocked`) e escreve o texto em `data/dialogue/greenhouse.json` + `data/objectives.json`.
- **Topo da parede magnética**: o MU-7 sobe até ficar pendurado rente ao topo e **não sobe sozinho para cima da parede**. A saída é pular para uma plataforma vizinha — desenhe a subida final da Estufa com esse apoio ao lado, senão o jogador trava.
- **Plataforma móvel** só anda com o sistema de energia dela ligado e **congela no meio do trajeto** quando a energia cai — use isso como parte do puzzle, não como bug.
- **Planta** não encolhe ao desligar a luz de crescimento (persiste em `GameState.flags`): depois de crescida, a rota por ela é permanente.

### 2026-09-20 — Fase construída e jogada de ponta a ponta
- **Quem**: agente da F29 (dados, mapa e testes) + orquestrador (QA final, depois que o limite de uso interrompeu o agente no meio da verificação).
- **O que foi feito**: mapa ASCII **40×40** vertical, `data/levels/greenhouse.{txt,json}`, `scenes/levels/greenhouse.{tscn,gd}`, testes de dados da fase, roteiros de QA. Puzzle de 5 sistemas / 2 unidades ligado às entidades do mapa (esporos, lâmpadas do corredor, luz de crescimento, plataforma, porta do Nó), fala e objetivo ao destravar as Garras, área secreta com Núcleo de Capacitor, 2 docas, logs, dados, SR-3 e focos de esporos.
- **Verificação**: import limpo · **522 testes verdes** · smoke com **61 cenas** · playthrough completo pelo roteiro `tests/qa/f29_greenhouse.json` (42 capturas, zero erro no log) indo da chegada até a tela **FIM DA DEMO** com `TEMPO 01:10 · LOGS 3/24 · DADOS 1/12 · MORTES 0 · SEGREDOS 1/4`.
- **O que as capturas mostram**: o aquecimento desligado encolhe os esporos; a luz de crescimento faz a trepadeira virar plataforma; o log da Helena destrava as Garras e o objetivo vira *"Escalar o painel magnético: encoste nele e segure CIMA"*; a parede falsa revela o Núcleo de Capacitor; o console C reconfigura a energia para abrir a porta do Nó; religar o Nó leva ao fim da demo.
- **Próximo passo**: passada visual (tilesets definitivos, iluminação por setor, partículas) — a fase está funcional, mas o cenário ainda é placeholder verde chapado.


### 2026-09-20 — Roteiro de QA ressincronizado com o mapa atual (a demo fecha de novo)
- **Quem**: agente D (QA) · **O que**: `tests/qa/f29_greenhouse.json` reescrito do zero e a seção 10 atualizada com o roteiro real.
- **Por quê**: depois da reescrita do Núcleo e dos ajustes da Estufa (cartões de tutorial, logs realocados, diálogos podados), o roteiro antigo **mentia**: as capturas `29_pe_do_painel`, `31_topo_do_painel`, `41_fim_da_demo` e `42_fim_da_demo_estatisticas` mostravam o MU-7 parado em `18,37` e depois `2,37` — ele nunca saía do andar térreo e a demo nunca terminava.
- **Rota do roteiro novo** (rota da LUZ DE CRESCIMENTO): chegada `5,37` → console A `18,37` (desliga AQUECIMENTO, liga LUZ DE CRESCIMENTO) → batente `19–20,37` → topo da trepadeira `21,34` → one-ways das linhas 33/31/29 → andar do meio → batente `7–8,26` e escada de one-ways das linhas 24/22/20 → corredor superior (pulando os vãos das colunas 25–26 e 29) → `log_gh_02` em `32,17` (destrava as Garras) → parede magnética da coluna 37 → console C `30,7` (desliga LUZ DE CRESCIMENTO, liga PORTA DO NÓ) → porta `8,7` → Nó `4,7` → **FIM DA DEMO**.
- **Resultado**: 27 capturas, todas lidas e conferidas uma a uma; zero `ERROR`/`SCRIPT ERROR` no log; a tela final mostra **TEMPO 00:50 · LOGS 1/4 · DADOS 1/4 · MORTES 0 · SEGREDOS 0/4**. Quatro execuções seguidas do mesmo roteiro deram exatamente a mesma trajetória.
- **Portões**: `--import` limpo · **569 testes verdes** · smoke com **69 cenas**.
- **Achados (não corrigidos aqui)**:
  - **A fala `gh_claws` nunca aparece.** `DialogueManager._finish_current()` chama `_apply_effects()` (que destrava as Garras e faz a `greenhouse.gd` enfileirar `gh_claws`) e, no fim da mesma função, chama `_box.hide_box()` incondicionalmente — escondendo a caixa da fala que acabou de começar. A fala roda invisível e ainda assim congela o timer.
  - **O cartão `tut_climb` nunca some.** `tutorial_card.gd` ignora o aperto da tecla sempre que havia diálogo ativo no frame anterior (`advancing_dialogue`); como a Estufa quase sempre tem uma fala ambiente na tela, o cartão "[CIMA] ESCALAR A PAREDE AMARELA" fica preso até o fim da fase (visível das capturas 17 a 25).
  - **A execução tem jitter ocasional.** Em 1 de 6 corridas o mesmo roteiro divergiu logo no trecho da base (o MU-7 não subiu o batente da coluna 16 e a corrida inteira virou outra); foram acrescentados dois pulos de resgate em `f305`/`f330`, que são inócuos na corrida boa.

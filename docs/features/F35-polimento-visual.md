---
id: F35
title: Polimento visual da Demo
status: done
scope: stretch
block: 5
priority: P2
rubric: ["Efeitos visuais", "Efeitos naturais", "HUD", "Paralax"]
depends_on: ["F12","F15","F18","F20","F26","F28","F29"]
unblocks: []
estimate: 3h
last_updated: 2026-09-20
---

# F35 — Polimento visual da Demo

## 1. Contexto e objetivo

A Demo já é jogável de ponta a ponta (menu → Núcleo Central → Estufa → FIM DA DEMO), mas
as capturas de QA das F28/F29 mostravam **um protótipo**: ambiente chapado (um único tom
de azul no Núcleo, um único tom de verde na Estufa), fundo e chão com o mesmo valor, nenhum
retorno de impacto ao tomar dano ou pousar, HUD que saltava em vez de animar e o fim de setor
resolvido em 0,15 s sem nenhum peso dramático.

Esta feature **não muda regra de jogo nenhuma**. Ela ataca só a camada de apresentação, com
o que dá para fazer sem arte nova: contraste e profundidade (vinheta, fundo escurecido,
lâmpadas pulsando), retorno de impacto (tremor de câmera, flash branco, partículas),
parallax com separação real entre camadas, transições com respiro e animações curtas no HUD.
Serve o pilar visual do [GDD-2.9](../design/GDD.md#gdd-2-9-visual) — *"a luz não é decoração,
é informação"* — e a direção de arte *"uma estação bonita que ninguém está usando"*.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 — Estilo visual](../design/GDD.md#gdd-2-9-visual) · [GDD-2.9 — Paleta por setor](../design/GDD.md#gdd-2-9-paleta) · [GDD-2.8 — HUD](../design/GDD.md#gdd-2-8-hud)
- **Parâmetros:** todas as constantes novas da seção 6.2 ([GDD-P](../design/GDD.md#gdd-p))
- **Jornada:** [Etapa 4 — o primeiro setor religado](../design/JORNADA-DO-HEROI.md) (o "respiro" do Nó do Setor)
- **ADRs:** [ADR-F28-002](F28-fase-nucleo-central.md#adr-f28-002) (por que as fases são claras) · [ADR-003](../DECISIONS.md#adr-003) (384×216, escala inteira) · [ADR-000](../DECISIONS.md#adr-000) (2D)

## 3. Critério de avaliação atendido

| Item da rubrica | Como o avaliador vê |
|---|---|
| Efeitos visuais | Flash branco no MU-7 ao levar dano, tremor de câmera, poeira ao pousar, faíscas ao coletar item, clarão ao religar o setor |
| Efeitos naturais | Esporos flutuando no ar da Estufa (ambiente, sem dano) |
| HUD | Barra de Carga desliza, célula de Integridade perdida dá um estalo vermelho, avisos entram e saem deslizando |
| Paralax | Três camadas com velocidade e brilho claramente diferentes (visível no `parallax_sandbox` e pelas janelas) |

## 4. Escopo

### Inclui
- Tremor de câmera (dano, pouso pesado, setor religado) com lógica pura testável.
- Flash branco no sprite do MU-7 via shader de `canvas_item`.
- Partículas: poeira ao pousar, faíscas ao coletar, pulso de energia ao ligar/desligar lâmpada.
- Vinheta suave por shader montada em toda fase.
- `TileMapLayer` de fundo escurecido/esfriado para dar profundidade.
- Pulsação fraca e fora de fase nas lâmpadas ligadas.
- Parallax: três `scroll_scale` com separação real, componente vertical mais lenta que a horizontal, camadas distantes escurecidas.
- Fade de cena com *easing* senoidal; "respiro" (clarão + assentamento) ao religar o Nó do Setor.
- HUD: barra de Carga que desliza, célula de Integridade que estala ao ser perdida, toast que entra/sai deslizando.
- Cadência de animação do MU-7 revisada (fps por animação em `Balance`).
- Partículas de esporos de ambiente na Estufa.

### Não inclui
- Qualquer mudança de mapa (`data/levels/*.txt` intocados) ou de lógica de gameplay.
- Arte nova (tilesets, sprites, fundos) — continua tudo placeholder onde já era.
- Música adaptativa ([F50](../INDEX.md)) e mapa do setor ([F47](../INDEX.md)).

## 5. Critérios de aceite

- [x] Tomar dano produz flash branco no chassi **e** tremor curto de câmera.
- [x] Pousar de queda alta levanta poeira e sacode a câmera; pulo curto não.
- [x] Coletar item solta faíscas na posição do item.
- [x] Ligar/desligar um sistema solta um pulso na cor da lâmpada afetada.
- [x] Fundo e chão têm valores distintos em ambas as fases; as bordas da tela escurecem.
- [x] Lâmpadas ligadas respiram (pulso fraco, cada uma em fase diferente).
- [x] As três camadas de parallax andam em velocidades visivelmente diferentes.
- [x] Religar o Nó do Setor dá um clarão e assenta na cor de setor restaurado.
- [x] Barra de Carga desliza; célula perdida estala; toast entra e sai deslizando sem cortar texto.
- [x] Portões do `/CLAUDE.md` §6 verdes (532 testes, 66 cenas).
- [x] Sem comentários no código (`.gd` e `.gdshader`); nada 3D.

## 6. Definição técnica

### 6.1 Cenas e scripts

```
scripts/core/screen_shake.gd      class_name ScreenShake — matemática pura do tremor
scripts/core/light_math.gd        + LightMath.pulse() — respiração da lâmpada
scenes/fx/fx.gd                   class_name Fx — instancia e dispara um burst num pai
scenes/fx/hit_flash.gdshader      mistura o sprite com a cor do flash
scenes/fx/vignette.gdshader       máscara radial nas bordas
scenes/fx/vignette.tscn (+ .gd)   CanvasLayer 5 — entre o mundo (0) e o HUD (10)
scenes/fx/dust_puff.tscn          poeira do pouso      (script spark_burst.gd)
scenes/fx/pickup_sparkle.tscn     faíscas da coleta    (script spark_burst.gd)
scenes/fx/power_pulse.tscn        pulso de energia     (script spark_burst.gd)
scenes/world/ambient_motes.tscn (+ .gd)  esporos de ambiente que seguem a câmera
```

Modificados: `scenes/player/mu7.gd`, `scenes/ui/hud.gd`, `scenes/world/powered_lamp.gd`,
`scenes/world/collectible.gd`, `scenes/world/space_parallax.gd`, `scenes/levels/level_base.gd`,
`scenes/levels/greenhouse.gd`, `autoload/scene_manager.gd`, `scripts/core/balance.gd`.

### 6.2 Constantes novas em `Balance` (espelhar na [GDD-P](../design/GDD.md#gdd-p))

| Constante | Valor | Para que serve |
|---|---|---|
| `SHAKE_TIME` | `0.25` | duração de qualquer tremor de câmera (s) |
| `SHAKE_FREQUENCY` | `24.0` | frequência do tremor (Hz) |
| `SHAKE_DAMAGE` | `4.0` | amplitude do tremor ao tomar dano (px) |
| `SHAKE_LAND` | `2.0` | amplitude do tremor ao pousar pesado (px) |
| `SHAKE_SECTOR` | `3.0` | amplitude do tremor ao religar um setor (px) |
| `LAND_SHAKE_SPEED` | `260.0` | velocidade de queda a partir da qual o pouso é "pesado" (px/s) |
| `HIT_FLASH_TIME` | `0.12` | duração do flash branco no chassi (s) |
| `HIT_FLASH_COLOR` | `#fff4e0` | cor do flash |
| `LAMP_PULSE_HZ` | `0.45` | frequência da respiração da lâmpada (Hz) |
| `LAMP_PULSE_DEPTH` | `0.12` | profundidade da respiração (fração da energia) |
| `VIGNETTE_STRENGTH` | `0.55` | opacidade máxima da vinheta |
| `VIGNETTE_INNER` | `0.45` | raio normalizado onde a vinheta começa |
| `VIGNETTE_OUTER` | `1.0` | raio normalizado onde a vinheta satura |
| `VIGNETTE_COLOR` | `#06090f` | cor das bordas |
| `BACKGROUND_TINT` | `#6b7a8c` | multiplicador do `TileMapLayer` de fundo (profundidade) |
| `AMBIENT_MOTE_AMOUNT` | `28` | partículas de ambiente por tela |
| `AMBIENT_MOTE_LIFETIME` | `7.0` | vida de cada partícula de ambiente (s) |
| `AMBIENT_MOTE_SPEED` | `5.0` | velocidade inicial máxima (px/s) |
| `AMBIENT_MOTE_RISE` | `-3.0` | "gravidade" das partículas (sobem devagar) |
| `PARALLAX_FAR_SCALE` | `(0.04, 0.02)` | velocidade da camada distante |
| `PARALLAX_MID_SCALE` | `(0.18, 0.09)` | velocidade da camada do meio |
| `PARALLAX_NEAR_SCALE` | `(0.55, 0.28)` | velocidade da camada próxima |
| `PARALLAX_FAR_DIM` | `0.45` | brilho da camada distante |
| `PARALLAX_MID_DIM` | `0.7` | brilho da camada do meio |
| `SECTOR_FLASH_TIME` | `0.12` | subida do clarão ao religar o setor (s) |
| `SECTOR_SETTLE_TIME` | `1.2` | descida do clarão até a cor restaurada (s) |
| `SECTOR_FLASH_COLOR` | `#e8f4ff` | cor do clarão |
| `HUD_BAR_SLIDE_TIME` | `0.25` | tempo para a barra de Carga cruzar o valor cheio (s) |
| `HUD_CELL_LOST_TIME` | `0.35` | estalo da célula de Integridade perdida (s) |
| `HUD_CELL_LOST_SCALE` | `1.5` | escala do estalo |
| `HUD_TOAST_SLIDE` | `8.0` | deslocamento vertical de entrada/saída do toast (px) |
| `HUD_TOAST_SLIDE_TIME` | `0.18` | tempo da entrada do toast (s) |
| `MU7_FPS_IDLE` | `3.0` | cadência de `idle` (antes 4.0) |
| `MU7_FPS_WALK` | `8.0` | cadência de `walk` (antes 10.0) |
| `MU7_FPS_JUMP` | `9.0` | cadência de `jump` (antes 8.0) |
| `MU7_FPS_FALL` | `6.0` | cadência de `fall` (antes 8.0) |
| `MU7_FPS_LAND` | `10.0` | cadência de `land` (antes 12.0) |
| `MU7_FPS_HURT` | `8.0` | cadência de `hurt` (antes 10.0) |
| `MU7_FPS_INTERACT` | `6.0` | cadência de `interact` (antes 8.0) |
| `MU7_FPS_CLIMB` | `5.0` | cadência de `climb` (antes 8.0) |
| `MU7_FPS_DEATH` | `4.0` | cadência de `death` (antes 8.0) |
| `MU7_FPS_DASH` | `12.0` | cadência de `dash` (inalterada) |

`HUD_TOAST_TIME`, `HUD_PULSE_HZ`, `LOW_INTEGRITY_BEEP_INTERVAL`, `PICKUP_BOB_AMPLITUDE` e
`PICKUP_BOB_SPEED` já existiam mas **não estavam cobertos** por `test_balance.gd`; foram
acrescentados à tabela `EXPECTED` na mesma passada.

### 6.3 Autoloads / sinais do EventBus

Nenhum sinal novo. O MU-7 passou a escutar `player_damaged` (flash + tremor) e
`sector_restored` (tremor). Nada foi removido do contrato do `/CLAUDE.md` §4.3.

### 6.4 Dados (`data/`)

- `data/levels/greenhouse.json`: chave nova `"ambient_motes": "#a8d98a"` (cor dos esporos de
  ambiente). Ausente = sem partículas, que é o caso do Núcleo Central.
- **Nenhum** `data/levels/*.txt` foi tocado.

### 6.5 Input actions / camadas de colisão

Inalterados. As partículas são `CPUParticles2D` sem colisão.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-MU7](../ASSETS.md#spr-mu7) | cadência das 10 animações revisada; material de flash aplicado | já é definitivo |
| [SPR-SPORE](../ASSETS.md#spr-spore) (`spore.png`) | textura das partículas de ambiente da Estufa | placeholder (reaproveitado, nada novo) |
| [BG-SPACE](../ASSETS.md#bg-space) | três camadas de parallax com brilho diferenciado | placeholder |

Nenhum asset novo foi pedido — os dois shaders (`hit_flash`, `vignette`) são código nosso e
moram em `scenes/fx/`, não em `assets/`.

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Capturar o "antes" nas duas fases com os roteiros F28/F29 ampliados.
- [x] **Passo 2** — `Balance` + `ScreenShake` + `LightMath.pulse` + testes.
- [x] **Passo 3** — Shaders, cenas de FX e helper `Fx`.
- [x] **Passo 4** — MU-7 (tremor/flash/poeira/cadência), HUD, lâmpada, coletável, parallax.
- [x] **Passo 5** — `level_base` (vinheta, fundo, esporos), `greenhouse` (respiro), fade.
- [x] **Passo 6** — Portões + QA "depois" pareado com o "antes".

## 10. Verificação

- **Testes:** `tests/test_screen_shake.gd` (6 casos: amplitude, decaimento quadrático, offset
  em pixel inteiro e dentro da amplitude, limiar de queda), `tests/test_light_math.gd`
  (+2 casos de `pulse`), `tests/test_balance.gd` (+41 constantes na `EXPECTED`, +2 casos:
  cores de polimento e ordenação das camadas de parallax). **532 passed, 0 failed.**
- **Smoke:** 66 cenas — acrescentadas `dust_puff`, `pickup_sparkle`, `power_pulse`,
  `vignette` e `ambient_motes` a `tests/scenes.txt`.
- **Roteiros godot-qa** (novos, em `tests/qa/`):
  - `f35_core_hub.json` — o roteiro da F28 com janelas densas no pouso e no toque da SR-3.
  - `f35_greenhouse.json` — o roteiro da F29 com janela densa no religar do Nó do Setor.
  - `f35_dano.json` — `damage_sandbox`, contato determinístico, 1 captura por quadro.
  - `f35_pouso.json` / `f35_pouso_zoom.json` — `mu7_sandbox`, queda do patamar (×3 no zoom).
  - `f35_parallax.json` — `parallax_sandbox`, passo de câmera + autoscroll.
- **Comparação antes/depois:** o "antes" foi rodado sobre uma cópia limpa da `main`
  (`git archive HEAD` extraído no scratchpad), com **os mesmos roteiros**, para que a única
  variável fosse o código desta feature.
- **Playtest humano:** confirmar se o tremor de 4 px no dano não incomoda em tela cheia e se
  os esporos de ambiente da Estufa não são confundidos com o Enxame de Esporos (que machuca).

## 11. ADRs locais

### ADR-F35-001 — O contraste vem da vinheta e do fundo escurecido, não de baixar o `ambient_color`
- **Contexto:** a queixa era "a Estufa é verde chapado, o Núcleo é azul chapado". O reflexo
  seria escurecer o `CanvasModulate` — exatamente o que a [ADR-F28-002](F28-fase-nucleo-central.md#adr-f28-002)
  proíbe, porque os tiles placeholder são escuros demais e a fase fica ilegível.
- **Decisão:** manter `ambient_color` como está e criar contraste por **dois** meios que não
  mexem na legibilidade do chão: (1) `Background.modulate = BACKGROUND_TINT` (o `TileMapLayer`
  de fundo fica mais escuro e mais frio que o sólido) e (2) uma vinheta suave num `CanvasLayer`
  entre o mundo e o HUD.
- **Consequências:** o fundo deixou de competir com o chão e as bordas pararam de "vazar" — o
  olho vai para o centro. Continua valendo a pendência de [TIL-CORE](../ASSETS.md#til-core):
  quando a arte definitiva chegar, o `ambient_color` pode escurecer e a `BACKGROUND_TINT`
  provavelmente sobe de volta para perto de branco.
- **Data:** 2026-09-20

### ADR-F35-002 — O tremor de câmera mora no `offset` da `Camera2D` e é arredondado a pixel inteiro
- **Contexto:** a câmera do MU-7 já usa `position.x` para o *look-ahead* e `position.y` para o
  deslocamento vertical fixo. Somar o tremor ali brigaria com o `lerp` do look-ahead. Em
  384×216 com escala inteira, um offset fracionário produz meio pixel — o mesmo tipo de
  borrão que a lição da F05 registrou nas fontes.
- **Decisão:** `ScreenShake.offset()` (lógica pura, em `scripts/core/`) devolve um `Vector2`
  já arredondado, e o MU-7 escreve só em `_camera.offset`. A amplitude decai com o quadrado do
  tempo restante; um tremor novo nunca enfraquece um tremor em curso (`amplitude_for`).
- **Consequências:** o tremor é testável headless (não precisa de nó nem de câmera) e nunca
  produz pixel quebrado. `shake(amplitude)` ficou público no MU-7 para futuras features
  (explosão do reator, mini boss).
- **Data:** 2026-09-20

### ADR-F35-003 — O "respiro" do Nó do Setor precisa de `TWEEN_PAUSE_PROCESS`
- **Contexto:** religar o setor dispara, no mesmo quadro, o clarão do ambiente e uma fala
  **bloqueante** da ÓRBITA. `DialogueManager` pausa a árvore durante fala bloqueante, e um
  `Tween` criado num nó comum é `TWEEN_PAUSE_BOUND` — ou seja, congela junto. Nas capturas o
  clarão simplesmente não acontecia (e o antigo `tween` de 0,15 s da F29 já sofria disso sem
  que ninguém tivesse notado, porque 0,15 s é invisível).
- **Decisão:** o tween do `_light_the_sector` passa a usar `set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)`
  e a rodar em duas pernas: clarão em `SECTOR_FLASH_TIME` e assentamento em `SECTOR_SETTLE_TIME`.
- **Consequências:** o clarão acontece **por cima** da fala "Estufa religada. Estabilidade
  subindo." — que é exatamente o momento dramático. Padrão a repetir em qualquer efeito visual
  que acompanhe fala bloqueante.
- **Data:** 2026-09-20

### ADR-F35-004 — Partículas de ambiente seguem a câmera em espaço de mundo, não em `CanvasLayer`
- **Contexto:** esporos flutuando precisam cobrir a tela inteira e acompanhar o jogador pela
  Estufa (que é vertical, 40 tiles de altura). A solução barata seria um `CanvasLayer` com
  partículas em espaço de tela.
- **Decisão:** `AmbientMotes` é um `Node2D` dentro do mundo que copia a cada quadro o centro
  da câmera e emite num retângulo do tamanho da viewport, com `local_coords = false`.
- **Consequências:** as partículas recebem o `CanvasModulate` da fase (ficam verdes na Estufa,
  como o resto) e ficam **atrás** do HUD sem depender de ordem de `CanvasLayer`. A cor vem do
  `data/levels/<fase>.json`, mas o alfa é forçado pelo script para não deixar um erro de JSON
  encher a tela de partículas opacas.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Feature criada e implementada
- **Quem**: agente de polimento · **O que**: F35 inteira (constantes, shaders, FX, HUD,
  parallax, atmosfera, transições, cadência do MU-7) · **Próximo passo**: espelhar as 41
  constantes novas na [GDD-P](../design/GDD.md#gdd-p).
- **Portões**: import limpo · 532 passed, 0 failed · 66 cenas no smoke · varreduras de
  comentário/3D vazias.
- **QA antes/depois** (scratchpad, não versionado) — o que cada par mostrou:
  1. **Núcleo Central, primeira tela** — antes: painel de fundo e chão no mesmo azul, imagem
     plana até os cantos. Depois: o fundo recuou (mais escuro e mais frio), o chão ficou o
     elemento mais claro e as bordas escurecem; parece um corredor, não um papel de parede.
  2. **Núcleo no escuro (lâmpadas desligadas)** — antes: o "apagão" ainda desenhava todos os
     painéis do fundo. Depois: só a poça da lanterna e as bordas pretas; a escolha de desligar
     a iluminação no terminal passou a ter preço visível.
  3. **Dano da SR-3 (`damage_sandbox`, quadro do contato)** — antes: o chassi apenas pisca e
     some (invulnerabilidade). Depois: por ~7 quadros ele vira uma silhueta **branca** e a
     tela inteira desloca alguns pixels; medido: 20 → 289 pixels claros no quadro do impacto,
     decaindo a 20 em 6 quadros.
  4. **Pouso de queda alta (`mu7_sandbox`, ×3)** — antes: o robô só encosta no chão. Depois:
     levanta uma nuvenzinha pálida nos pés e a linha do chão sacode; o MU-7 finalmente parece
     pesar alguma coisa.
  5. **Coleta do Dado de Pesquisa (Núcleo Central)** — antes: o item some e aparece o texto.
     Depois: um estouro de faíscas amarelas no lugar do item; a coleta tem um "onde" e não só
     um "quanto".
  6. **Estufa, chegada** — antes: verde uniforme, parede e passarela indistinguíveis. Depois:
     esporos claros flutuando no ar e o fundo recuado; a fase parece habitada e úmida.
  7. **Estufa, corredor superior** — antes: um tapete verde. Depois: motes passando na frente
     da câmera e o fundo escuro fazendo as passarelas saltarem.
  8. **Religar o Nó do Setor** — antes: a cor mudava em 0,15 s durante uma pausa de fala, isto
     é, **não mudava** (medido: brilho médio 36,0 → 36,6 ao longo de 2 s). Depois: a sala toma
     um banho de luz quase branca e desce em 1,2 s até o verde restaurado, por cima da fala
     "Estufa religada. Estabilidade subindo." (medido: 40,5 → 32,9 em 72 quadros).
  9. **Parallax (`parallax_sandbox`)** — antes: as três camadas praticamente juntas e com o
     mesmo brilho. Depois: o campo de estrelas quase parado e esmaecido, a nébula intermediária
     média e as antenas da estação bem à frente — dá para ler três distâncias.
  10. **HUD** — o toast entra subindo com fade e sai subindo; a barra de Carga percorre o
      caminho em vez de pular; a célula perdida dá um estalo vermelho antes de começar a piscar.
- **Achados registrados** (viram lição no `/CLAUDE.md` §9):
  - `Tween` em nó comum congela durante fala bloqueante ([ADR-F35-003](#adr-f35-003)).
  - A primeira versão do toast usava `clip_contents` + deslize horizontal e **cortava o texto**
    ("DADO DE PESQUISA 01/1"), porque o `VBoxContainer` do HUD tem largura fixa de 240 px.
    Trocado por deslize vertical sem recorte.
- **Pendências que só melhoram com arte nova** (viram pedido de asset):
  - [TIL-CORE](../ASSETS.md#til-core) e [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse): continuam escuros demais para o
    `ambient_color` poder escurecer; hoje o contraste vem da vinheta e do fundo escurecido.
  - [BG-SPACE](../ASSETS.md#bg-space): o parallax fica **invisível dentro das fases** porque o
    `TileMapLayer` de fundo cobre a tela inteira nos dois mapas. Só aparece de verdade quando
    houver tiles de janela/vazio no fundo (mapa ou tileset).
  - [SPR-SPORE](../ASSETS.md#spr-spore) / FX novo: as partículas de poeira, faísca e pulso são o mesmo quadrado
    de 8×8 recolorido; uma folha de FX com poeira, faísca e anel de energia daria outro nível.
  - [SPR-MU7](../ASSETS.md#spr-mu7): a cadência foi ajustada dentro do que a folha permite
    (2 a 6 quadros por ação); `land` com 2 quadros não tem como dar squash de verdade.

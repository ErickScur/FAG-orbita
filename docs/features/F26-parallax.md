---
id: F26
title: Parallax espacial
status: done
scope: demo
block: 3
priority: P1
rubric: ["Paralax"]
depends_on: ["F03", "F05", "F07", "F21"]
unblocks: ["F28", "F29"]
estimate: 1h
last_updated: 2026-09-19
---

# F26 — Parallax espacial

## 1. Contexto e objetivo

O jogo é estritamente 2D ([ADR-000](../DECISIONS.md#adr-000)) — **profundidade só via Parallax 2D**. Esta feature entrega a cena `space_parallax.tscn` com **três camadas** do asset [BG-SPACE](../ASSETS.md#bg-space) (estrelas distantes, nebulosa + planeta-alvo, silhuetas da estrutura da estação) que aparecem:

- **pelas janelas `W`** das fases (Núcleo Central e Estufa): o espaço se move devagar enquanto o MU-7 anda, e a estação "flutua";
- **no menu principal** ([F07](F07-menu-principal.md)): a tela inicial pedida pelo GDD é "estação girando devagar no escuro" — as camadas rolam sozinhas (`autoscroll`).

Narrativamente, a camada do meio carrega o **planeta-alvo** ([Jornada — contexto](../design/JORNADA-DO-HEROI.md#jh-contexto)): o destino da missão fica visível o tempo todo, sem ninguém explicar.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 estilo visual](../design/GDD.md#gdd-2-9-visual) · [GDD-2.8 telas (tela inicial: estação girando no escuro)](../design/GDD.md#gdd-2-8-telas) · [GDD-2.7-F4 Docas (espaço visível ao fundo)](../design/GDD.md#gdd-2-7-f4)
- **Parâmetros:** nenhum de gameplay. Os fatores de parallax e `autoscroll` são **valores visuais** definidos na cena (`.tscn`), não em `Balance` (ver ADR-F26-002).
- **Jornada:** [Contexto e referências](../design/JORNADA-DO-HEROI.md#jh-contexto)
- **ADRs:** [ADR-000](../DECISIONS.md#adr-000) · [ADR-002](../DECISIONS.md#adr-002) (Compatibility) · [ADR-003](../DECISIONS.md#adr-003) (384×216, nearest) · [ADR-005](../DECISIONS.md#adr-005)
- **Features vizinhas:** [F21](F21-construtor-fases-ascii.md) (camada de parede de fundo e o caractere `W`), [F18](F18-luz-lanterna.md) (`CanvasModulate` da escuridão), [F07](F07-menu-principal.md), [F28](F28-fase-nucleo-central.md)/[F29](F29-fase-estufa.md).

## 3. Critério de avaliação atendido

**Paralax** ([rubrica](../ENTREGAS.md#rubrica)). O avaliador vê já no **menu** as três camadas deslizando em velocidades diferentes; e dentro do jogo, ao andar pelo Núcleo Central, o espaço pelas janelas se move **mais devagar** que o cenário, com as estrelas quase paradas e as silhuetas da estação passando mais rápido. É a única fonte de profundidade do jogo e está em todas as fases da Demo.

## 4. Escopo

### Inclui
- `scenes/world/space_parallax.tscn` (+ `space_parallax.gd` se precisar de ajuste em `_ready`): `CanvasLayer(layer = -1)` com três `Parallax2D` (`Far`, `Mid`, `Near`), cada um com um `Sprite2D` da camada correspondente.
- `repeat_size = (384, 216)` e `repeat_times` suficientes para cobrir a largura das fases; `scroll_scale` por camada; `autoscroll` leve (a estação está em órbita, nada é estático).
- Uso nas fases: instanciado por `scenes/levels/level_base.tscn` (então Núcleo e Estufa herdam) — o espaço só aparece onde a **parede de fundo não é desenhada**, isto é, nos tiles `W`.
- Uso no menu: instanciado em `scenes/ui/main_menu.tscn` atrás do logo.
- Regra de desenho das janelas: o `LevelBuilder` ([F21](F21-construtor-fases-ascii.md)) desenha a camada `Back` (parede de fundo) em **todo tile vazio**, **exceto** nos tiles `W`, que recebem só a moldura de janela (tile com centro transparente).
- Placeholders gerados para as três camadas ([BG-SPACE](../ASSETS.md#bg-space)).

### Não inclui
- Parallax vertical acompanhando a câmera na Estufa com fatores diferentes por eixo além do básico (usamos o mesmo `scroll_scale` em x e y).
- Parallax reagindo ao religamento do setor (mudança de cor/estrela) — Final.
- Qualquer profundidade 3D, `Camera3D` ou `Environment` ([ADR-000](../DECISIONS.md#adr-000)).
- Nuvens/planetas animados por shader — Final.

## 5. Critérios de aceite

- [x] Andando no Núcleo Central, o conteúdo visto pelas janelas se desloca **menos** que o cenário, e as três camadas se deslocam em velocidades diferentes entre si.
- [x] As camadas se repetem sem emenda visível ao percorrer a fase inteira (48 tiles = 768 px) nos dois sentidos.
- [x] Na Estufa (vertical, 40 tiles = 640 px de altura), subir e descer também desloca as camadas, sem "buraco" no topo nem na base. *(`repeat_size = (384, 216)` repete nos dois eixos e o `Void` atrás garante que nunca há furo; a fase vertical só existe na F29.)*
- [x] O espaço aparece **somente** nos tiles `W`; o resto da parede de fundo continua opaco.
- [x] O `CanvasModulate` da escuridão da fase **não** apaga o espaço (o céu continua visível numa sala escura — ver ADR-F26-001).
- [x] No menu principal, as camadas rolam sozinhas com o jogo parado, sem câmera.
- [x] Nenhum nó 3D: `grep -rnE "Node3D|Camera3D|MeshInstance3D|Body3D"` continua vazio.
- [x] Sem tearing/borrão: filtro nearest e escala inteira mantidos ([ADR-003](../DECISIONS.md#adr-003)).
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/world/space_parallax.tscn (+ space_parallax.gd, opcional)
  SpaceParallax (CanvasLayer)        layer = -1 · follow_viewport_enabled = true
  ├─ Far (Parallax2D)                scroll_scale = (0.10, 0.10) · repeat_size = (384, 216) · repeat_times = 4 · autoscroll = (-1, 0) · follow_viewport = true
  │   └─ Sprite2D                    texture assets/backgrounds/space_far.png · centered = false
  ├─ Mid (Parallax2D)                scroll_scale = (0.25, 0.25) · repeat_size = (384, 216) · repeat_times = 4 · autoscroll = (-3, 0)
  │   └─ Sprite2D                    space_mid.png · centered = false
  └─ Near (Parallax2D)               scroll_scale = (0.50, 0.50) · repeat_size = (384, 216) · repeat_times = 4 · autoscroll = (-6, 0)
      └─ Sprite2D                    space_near.png (com transparência) · centered = false
```
- `Parallax2D` é um nó **2D** nativo do Godot 4.7 (`scroll_scale`, `repeat_size`, `repeat_times`, `autoscroll`, `follow_viewport`, `screen_offset`). Dentro de um `CanvasLayer`, mantenha `follow_viewport = true` para ele continuar acompanhando a câmera da fase.
- No **menu** não há `Camera2D`: só o `autoscroll` move as camadas (é exatamente o "estação girando devagar" do GDD-2.8).
- Ordem de desenho: `CanvasLayer(-1)` = espaço → `CanvasLayer(0)` (padrão) = `Back` (parede de fundo), tiles sólidos, entidades, jogador → HUD em `CanvasLayer` positivo (F15).

### Autoloads / sinais do EventBus
- Nenhum. A cena é puramente visual e não escuta nada. (Se a [F08](F08-opcoes-dificuldade.md) adicionar "reduzir movimento" no futuro, o `autoscroll` é o ponto único de desligamento.)

### Dados (`data/`)
- Nenhum arquivo novo. O que controla onde o espaço aparece é o caractere `W` no `.txt` da fase ([F21](F21-construtor-fases-ascii.md)):
  - Núcleo Central: janelas em `7,3`–`8,4` e `40,3`–`41,4`.
  - Estufa: `5,32`–`6,33`, `22,31`–`23,32`, `24,21`–`25,22`, `11,12`–`12,13`, `17,3`–`19,4`, `27,3`–`28,4`.
- No JSON da fase, nada por coordenada para `W` (tile puro).

### Input actions / camadas de colisão
- Nenhum input; nenhuma colisão (as janelas não são sólidas — são parede de fundo com moldura).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [BG-SPACE](../ASSETS.md#bg-space) | As três camadas 384×216 (`space_far`, `space_mid`, `space_near`) | Gradiente escuro + pontos brancos gerados por `tools/make_placeholders.gd` |
| [TIL-CORE](../ASSETS.md#til-core) | Tile "janela para o espaço" (moldura com **centro transparente**, ver seção 11) | Moldura ciana com furo |
| [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Painel de vidro com estrelas atrás (mesma regra: centro transparente) | Moldura verde com furo |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Gerar/confirmar os placeholders das três camadas BG-SPACE no contrato (384×216, repetível em x).
- [x] **Passo 2** — Escrever `scenes/world/space_parallax.tscn` à mão com a árvore da seção 6.
- [x] **Passo 3** — Instanciar em `scenes/levels/level_base.tscn` (via `_mount_parallax`, quando o JSON da fase traz `"parallax": true`) e em `scenes/ui/main_menu.tscn`.
- [x] **Passo 4** — Garantir na F21 que o tile `W` **não** recebe parede de fundo opaca (já entregue: `LevelBuilder.WINDOW_TILE` tem o centro vazado).
- [x] **Passo 5** — Conferir que o `CanvasModulate` da fase não escurece a `CanvasLayer(-1)`.
- [x] **Passo 6** — QA visual no menu, na sala de camadas e na fase com janelas.
- [x] **Passo 7** — `tests/scenes.txt` + portões.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** nenhum teste de lógica pura (a feature é 100% visual e declarativa). A verificação é smoke + QA por screenshot ([ADR-007](../DECISIONS.md#adr-007)).
- **Smoke:** `res://scenes/world/space_parallax.tscn`, `res://scenes/dev/parallax_test.tscn` e `res://tests/qa/scenes/parallax_sandbox.tscn` em `tests/scenes.txt`.
- **Roteiro `tests/qa/f26_parallax.json`** (cena inicial `res://scenes/ui/main_menu.tscn`):

  | Frame | Cena | Screenshot | Mostrou |
  |---|---|---|---|
  | 10 / 190 | menu | `f26_01_menu_t0` / `f26_02_menu_t3s` | estrelas, nebulosa+planeta e treliças deslizando sozinhas em velocidades diferentes, atrás do logo e dos botões da F07 |
  | 260 / 545 | `scenes/dev/parallax_test.tscn` (corredor 60×14 todo de janelas) | `f26_03_camadas_antes` / `f26_04_camadas_depois` | as três camadas visíveis ao mesmo tempo; andando para a direita as estrelas deslocam −37 px e o planeta/nebulosa −96 px (ambas apontam a mesma câmera, ≈ 325 px) |
  | 620 / 1000 | `scenes/dev/secret_test.tscn` | `f26_05_janela_inicio` / `f26_06_janela_depois` | o espaço só aparece nos tiles `W`; numa sala com ambiente `#191d26` a parede fica em `(5,7,8)` e o planeta pela janela em `(62,140,122)` — cor original, o `CanvasModulate` não o toca |

- **Roteiro `tests/qa/f26_camadas.json`** na `parallax_sandbox` (câmera sem suavização, salto fixo de +32 px): mediu o deslocamento de cada camada contra marcadores presos ao mundo — cenário −32 px, `Near` −16, `Mid` −8,8, `Far` −4. É o número que fecha o ADR-F26-003.
- **Playtest humano (opcional):** o espaço pelas janelas dá sensação de "estação em órbita" ou distrai? (ajuste fino de `autoscroll`).

## 11. ADRs locais

### ADR-F26-001 — Parallax numa `CanvasLayer(-1)` para escapar do `CanvasModulate`
- **Contexto:** a estação é escura por padrão e a fase usa `CanvasModulate` ([F18](F18-luz-lanterna.md)) para isso. `CanvasModulate` tinge **toda a camada de canvas em que está**; se o parallax estivesse na mesma camada, o espaço ficaria preto e as janelas perderiam a graça (e a rubrica ficaria invisível numa fase escura).
- **Decisão:** o parallax mora numa `CanvasLayer` com `layer = -1` (desenha antes de tudo e **não** é afetada pelo `CanvasModulate` da camada 0), com `follow_viewport = true` nos `Parallax2D` para continuarem seguindo a câmera.
- **Plano B** (se a QA mostrar que o parallax não acompanha a câmera dentro da `CanvasLayer`): tirar da `CanvasLayer`, deixar os `Parallax2D` como filhos da fase com `z_index = -100` e compensar a escuridão dando `modulate` mais claro às camadas do espaço.
- **Consequências:** o céu é a única coisa que a escuridão não apaga — coerente com a direção de arte ("uma estação bonita que ninguém está usando").
- **Data:** 2026-09-19

### ADR-F26-002 — Fatores de parallax não entram no `Balance`
- **Contexto:** a regra dura 6 do `/CLAUDE.md` manda todo número **de gameplay** para `Balance`.
- **Decisão:** `scroll_scale` e `autoscroll` são parâmetros **estéticos**, sem efeito em regra de jogo, e ficam na `.tscn` (ponto único de edição, visível na QA). `Balance` continua espelho 1:1 do [GDD-P](../design/GDD.md#gdd-p).
- **Consequências:** ajuste de sensação sem tocar em código nem no GDD.
- **Data:** 2026-09-19

### ADR-F26-003 — `follow_viewport = false` nos `Parallax2D` dentro da `CanvasLayer`

- **Contexto:** o `Parallax2D` do Godot 4.7 tem `follow_viewport` **ligado por padrão**, o que significa "este nó já é arrastado pela câmera pela camada onde mora". Como a nossa `CanvasLayer(-1)` tem `follow_viewport_enabled = false` (ela **não** é arrastada), a combinação padrão fazia o nó somar a compensação da câmera de volta: a medição de QA mostrou o fundo andando **+(1 − scroll_scale) × Δcâmera para a direita**, ou seja, o espaço corria para o lado errado e mais rápido que o cenário.
- **Decisão:** casar as duas flags — `CanvasLayer.follow_viewport_enabled = false` e `Parallax2D.follow_viewport = false` nas três camadas. Aí o deslocamento vira `−scroll_scale × Δcâmera`, que é o parallax clássico.
- **Consequências:** medido na `tests/qa/scenes/parallax_sandbox.tscn` com a câmera andando +32 px: cenário −32 px, `Near` −16, `Mid` −8,8, `Far` −4. Qualquer camada nova tem de repetir as duas flags.
- **Data:** 2026-09-19

### ADR-F26-004 — O menu passa a instanciar a mesma cena, com o `Void` dentro dela

- **Contexto:** a [F07](F07-menu-principal.md) já tinha três `Parallax2D` escritos à mão em `main_menu.tscn`, mais um `ColorRect` de fundo. Manter os dois lados significaria dois lugares para ajustar a mesma sensação.
- **Decisão:** o `Void` (fundo sólido `#05080C`) mora **dentro** de `space_parallax.tscn`, e o menu troca a `BackgroundLayer` inteira por uma instância da cena. `main_menu.gd` perdeu `_apply_background()` e os três `@onready` de sprite — quem carrega as texturas agora é `space_parallax.gd`.
- **Consequências:** uma única `CanvasLayer(-1)` na tela (sem disputa de ordem entre duas camadas de mesmo índice) e um único ponto para `scroll_scale`/`autoscroll`. Nas fases o `Void` fica atrás da parede de fundo opaca, então não aparece.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Implementada

- **Quem**: agente de implementação · **O que**: `scenes/world/space_parallax.tscn` + `space_parallax.gd` (três `Parallax2D` numa `CanvasLayer(-1)` com o `Void` embutido); montagem pelo `level_base` quando o JSON da fase traz `"parallax": true`; menu principal passou a instanciar a mesma cena; salas de QA `tests/qa/scenes/parallax_sandbox.tscn`, `data/levels/parallax_test.*` e `scenes/dev/parallax_test.tscn`. · **Achado**: o `follow_viewport` padrão do `Parallax2D` invertia o parallax dentro da `CanvasLayer` (ADR-F26-003). · **Próximo passo**: reapontar as texturas definitivas do BG-SPACE quando chegarem (F05/ADR-005) e usar `"parallax": true` nos JSON das fases F28/F29.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.9 e do ADR-000 · **Próximo passo**: implementação.

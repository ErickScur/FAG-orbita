---
id: F27
title: Área secreta
status: done
scope: demo
block: 3
priority: P0
rubric: ["Área secreta"]
depends_on: ["F13", "F20", "F21"]
unblocks: ["F29"]
estimate: 1h
last_updated: 2026-09-19
---

# F27 — Área secreta

## 1. Contexto e objetivo

Uma **parede falsa** (`x`) na Estufa: ao encostar nela, ela perde a colisão e fica **translúcida**, revelando uma câmara escondida com um **Núcleo de Capacitor** (`C`) — upgrade permanente de **+25 de Carga máxima** ([GDD-2.6.3](../design/GDD.md#gdd-2-6-3): "4 no jogo, escondidos fora da rota principal").

É a recompensa do pilar **DESCOBERTA** para quem gasta tempo do reator explorando: o jogo pergunta *"vale a pena procurar mais um segredo?"* ([GDD-2.3](../design/GDD.md#gdd-2-3-micro)). Encontrar a área conta nas **estatísticas** do fim da demo ("ÁREAS SECRETAS 1/4"), junto com logs, dados, tempo e mortes ([GDD-2.8 tela 8](../design/GDD.md#gdd-2-8-telas)).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.3 — Itens e coletáveis (Núcleo de Capacitor)](../design/GDD.md#gdd-2-6-3) · [GDD-2.3 — Core loop / o que prende o jogador](../design/GDD.md#gdd-2-3-micro) · [GDD-2.8 telas (estatísticas no fim)](../design/GDD.md#gdd-2-8-telas) · [GDD-2.9 estética](../design/GDD.md#gdd-2-9-visual)
- **Parâmetros:** `Balance.CAPACITOR_BONUS` (25 de Carga máx.), `Balance.CHARGE_MAX` — [GDD-P](../design/GDD.md#gdd-p). **Novos (ADR-F27-002):** `Balance.SECRET_WALL_FADE_TIME`, `Balance.SECRET_WALL_ALPHA`, `Balance.SECRETS_TOTAL`.
- **Jornada:** [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) · [ADR-006](../DECISIONS.md#adr-006)
- **Features vizinhas:** [F20 — Coletáveis & contadores](F20-coletaveis-contadores.md) (o `C` é um `collectible`), [F13 — Integridade/Carga](F13-integridade-carga-respawn.md) (aplica `charge_max`), [F10 — Telas de fim de jogo](F10-telas-fim-de-jogo.md) (estatísticas), [F11](F11-salvar-carregar.md) (flags no save), [F29](F29-fase-estufa.md) (onde fica).

## 3. Critério de avaliação atendido

**Área secreta** ([rubrica](../ENTREGAS.md#rubrica)). Na apresentação, na Estufa: o apresentador anda para a esquerda num corredor aparentemente sem saída, encosta na parede — ela **desaparece com um fade e fica fantasma** —, entra na câmara, pega o Núcleo de Capacitor roxo e **a barra de Carga do HUD fica visivelmente maior** (100 → 125). No fim da demo, a tela de estatísticas mostra `ÁREAS SECRETAS 1/4`.

## 4. Escopo

### Inclui
- `scenes/world/secret_wall.tscn` + `secret_wall.gd`: bloco sólido 16×16 com `Area2D` de detecção; ao ser tocado pelo MU-7, revela **todas** as paredes do mesmo `secret_id` (fade para `Balance.SECRET_WALL_ALPHA`, colisão desativada).
- Registro do segredo: `GameState.flags["secrets_found"]` (array de ids, sem repetição) + persistência no save.
- Permanência: reentrar na fase (ou carregar o save) com o segredo já achado já nasce com a parede revelada.
- Suporte ao coletável `C` (Núcleo de Capacitor) com `kind = &"capacitor"`: `+Balance.CAPACITOR_BONUS` em `GameState.charge_max` e `charge_changed` emitido (a barra do HUD cresce).
- Dica visual de que a parede é falsa (tile com rachadura/variação) e som ao revelar.
- Linha `ÁREAS SECRETAS x/{Balance.SECRETS_TOTAL}` na tela FIM DA DEMO (se a [F10](F10-telas-fim-de-jogo.md) ainda não tiver o slot, esta feature o adiciona).

### Não inclui
- Mapa/scanner que marque segredos — F47 (Final).
- Mais de uma área secreta na Demo (a do Núcleo Central fica de fora: a Fase 0 é tutorial sem dano e sem desvio).
- Placa de Blindagem (+25 Integridade máx.) e os outros 3 capacitores — Final ([F49](../INDEX.md)).
- Paredes falsas que precisam de habilidade (dash/feixe) para abrir — Final.

## 5. Critérios de aceite

- [x] A parede `x` é sólida: o MU-7 **não** atravessa antes de encostar (`collision_layer = 1` até o contato; coberto por `tests/test_secrets.gd`).
- [x] Ao encostar, **todas** as tiles do mesmo `secret_id` ficam translúcidas (`Balance.SECRET_WALL_ALPHA = 0.25`) em `Balance.SECRET_WALL_FADE_TIME = 0.3 s` e perdem a colisão; toca `secret_found`.
- [x] O MU-7 entra na câmara, pega o `C` e a Carga máxima vai de 100 para 125 (`charge_changed(current, 125)`), com a barra do HUD maior.
- [x] O `C` sai do mundo e não volta ao reentrar na fase (`GameState.collected_ids`, [F20](F20-coletaveis-contadores.md)).
- [x] O segredo é registrado exatamente uma vez, mesmo encostando várias vezes (`GameState.register_secret` é idempotente).
- [x] Salvar, voltar ao menu e **Continuar**: parede continua revelada e a Carga máxima continua 125 (`flags` já entram no `to_dict`/`from_dict` da [F11](F11-salvar-carregar.md)).
- [x] A tela FIM DA DEMO mostra `SEGREDOS 1/4` quando o segredo foi achado e `0/4` quando não.
- [x] Morrer depois de achar o segredo não reverte nada (o registro mora em `flags`, que `revive()` não toca).
- [x] `tests/test_secrets.gd` verde (12 casos).
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/world/secret_wall.tscn (+ secret_wall.gd)
  SecretWall (StaticBody2D)        collision_layer = 1 (world)
  ├─ CollisionShape2D              RectangleShape2D 16×16
  ├─ Sprite2D                      tile sólido do TIL-GREENHOUSE com variação de rachadura
  └─ Touch (Area2D)                collision_layer = 4 (interactable) · collision_mask = 2 (player)
      └─ CollisionShape2D          RectangleShape2D 20×20 (2 px além da parede em cada lado)
scenes/world/collectible.tscn      (F20 — ramo kind = &"capacitor")
```

`secret_wall.gd`:
```gdscript
extends StaticBody2D

@export var secret_id: StringName

@onready var sprite: Sprite2D = $Sprite2D
@onready var touch: Area2D = $Touch

func _ready() -> void: ...
func reveal(instant: bool) -> void: ...
func _on_touch_body_entered(body: Node2D) -> void: ...
```
- `_ready()`: `add_to_group("secret_" + secret_id)`; se `GameState.has_secret(secret_id)` → `reveal(true)`; senão conecta `touch.body_entered`.
- `_on_touch_body_entered`: ignora quem não está no grupo `"player"`; `if GameState.register_secret(secret_id):` toca `AudioManager.play_sfx("secret_found")` e, para cada nó do grupo `"secret_" + secret_id`, chama `reveal(false)`.
- `reveal(instant)`: `set_deferred("collision_layer", 0)` e `$CollisionShape2D.set_deferred("disabled", true)`; `touch.set_deferred("monitoring", false)`; alfa vai a `Balance.SECRET_WALL_ALPHA` — direto se `instant`, senão por `create_tween()` em `Balance.SECRET_WALL_FADE_TIME`.

`GameState` (adições pequenas, ADR-F27-001):
```gdscript
func has_secret(id: StringName) -> bool: ...
func register_secret(id: StringName) -> bool: ...   # false se já existia; true e grava em flags["secrets_found"] se é nova
func secrets_found() -> int: ...
```
`flags["secrets_found"]` é um `Array` de `String` (serializável em JSON pelo [F11](F11-salvar-carregar.md)).

Coletável `C` ([F20](F20-coletaveis-contadores.md)): `kind = &"capacitor"` →
```gdscript
GameState.charge_max += Balance.CAPACITOR_BONUS
GameState.add_charge(Balance.CAPACITOR_BONUS)
EventBus.collectible_picked.emit(&"capacitor", item_id)
```
(o `add_charge` respeita a CORROSÃO da [F23](F23-esporos-status.md); o aumento do **máximo** acontece de qualquer jeito).

### Autoloads / sinais do EventBus
- **Emite:** `collectible_picked(&"capacitor", item_id)`, `charge_changed(current, maximum)` (via `GameState`).
- **Escuta:** nada. A tela FIM DA DEMO lê `GameState.secrets_found()` no `_ready`.
- `AudioManager.play_sfx("secret_found")` — **novo nome** no SFX-PACK (ver seção 11).

### Dados (`data/`)
No JSON da [F29](F29-fase-estufa.md), por coordenada (as duas tiles compartilham o mesmo `secret_id`):
```json
{ "entities": {
  "4,26": { "secret_id": "gh_secret_01" },
  "4,27": { "secret_id": "gh_secret_01" },
  "2,27": { "kind": "capacitor", "item_id": "capacitor_gh_01" }
} }
```

### Input actions / camadas de colisão
- Sem input (revelar é por **contato**, não por `interact` — o jogador não sabe que há algo ali para interagir).
- Parede: layer 1 `world`; `Touch`: layer 4 `interactable`, mask 2 `player`. Coletável: layer 6 `pickup`.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Tile sólido com rachadura (dica visual da parede falsa) | Bloco verde-musgo com risco mais claro |
| [SPR-PICKUPS](../ASSETS.md#spr-pickups) | Linha 5: **Núcleo de Capacitor** (16×16, 4f de brilho) | Losango roxo |
| [UI-HUD](../ASSETS.md#ui-hud) | Barra de Carga redimensionada (100 → 125) | Moldura 9-slice gerada |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `secret_found` (**novo**, ver seção 11) | Acorde curto gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Constantes do ADR-F27-002 em `Balance` (`SECRET_WALL_FADE_TIME`, `SECRET_WALL_ALPHA`, `SECRETS_TOTAL`) — já estavam lá.
- [x] **Passo 2** — `GameState.has_secret/register_secret/secrets_found` + `tests/test_secrets.gd`.
- [x] **Passo 3** — `scenes/world/secret_wall.tscn` + `secret_wall.gd`; a legenda `x` do `LevelBuilder` já apontava para a cena.
- [x] **Passo 4** — Ramo `capacitor` do coletável ([F20](F20-coletaveis-contadores.md)) conferido: `GameState.expand_charge_max(Balance.CAPACITOR_BONUS)`.
- [x] **Passo 5** — Linha `SEGREDOS x/N` na tela FIM DA DEMO: já vinha de `RunStats.summary_rows` (F10), agora com número real.
- [x] **Passo 6** — HUD redesenha a barra de Carga com o novo máximo (confirmado por captura).
- [x] **Passo 7** — Sala de QA (`data/levels/secret_test.*` + `scenes/dev/secret_test.tscn`), roteiro `tests/qa/f27_secret.json`, `tests/scenes.txt` e portões.

## 10. Verificação

- **Testes (`tests/test_secrets.gd`)** — instancia o script do `GameState` direto (`load("res://autoload/game_state.gd").new()`): registro novo devolve `true`; o mesmo id duas vezes devolve `false` e mantém `secrets_found() == 1`; id vazio é ignorado; dois ids contam separado; `to_dict()` → JSON → `from_dict()` preserva o segredo; `new_game()` zera; `get_stats()` entrega `secrets`/`secrets_total` e a linha `SEGREDOS   1/4`; duas paredes com o mesmo `secret_id` caem no mesmo grupo `secret_<id>` e uma terceira com outro id não; `reveal(true)` marca `is_revealed()` e leva o alfa a `Balance.SECRET_WALL_ALPHA`; o capacitor leva `charge_max` de `CHARGE_MAX` para `CHARGE_MAX + CAPACITOR_BONUS`.
- **Smoke:** `res://scenes/world/secret_wall.tscn` e `res://scenes/dev/secret_test.tscn` em `tests/scenes.txt`.
- **Roteiro `tests/qa/f27_secret.json`** — sala `data/levels/secret_test.txt` (corredor de 48 tiles, parede falsa de 3 tiles em `4,9`–`4,11`, câmara com o `C` em `2,11`):

  | Frame | Ação | Screenshot | Mostrou |
  |---|---|---|---|
  | 60 | — | `f27_01_parede_solida` | as três tiles falsas bem mais claras que a parede em volta, com a rachadura; o `C` roxo no nicho atrás |
  | 70–110 | `move_left` | `f27_02_parede_translucida` (f150) | as três tiles fantasmas de uma vez (a parede de fundo aparece através delas), o MU-7 em cima de onde era sólido, `C` ainda no chão |
  | 160–205 | `move_left` | `f27_03_capacitor_coletado` (f240) | toast `CAPACIDADE MÁXIMA +25`, `C` sumiu e a barra de Carga do HUD visivelmente mais comprida (com o traço do custo de dash) |
  | 270 | recarrega a cena | `f27_04_persistiu` (f340) | a parede **nasce** translúcida e o `C` não reapareceu |
  | 370 | vai para `demo_end` | `f27_05_fim_da_demo` | `SEGREDOS 1/4` na tabela de estatísticas |

- **Playtest humano (opcional):** a rachadura chama atenção o suficiente para o jogador tentar, sem entregar o segredo de graça?

## 11. ADRs locais

### ADR-F27-001 — Revelar por contato, contar no `GameState`, persistir em `flags`
- **Contexto:** a parede podia exigir `interact`, mas o jogador não tem motivo para apertar E numa parede; e o contador de segredos precisa sobreviver a morte, troca de cena e save.
- **Decisão:** revelação por **contato** (`Area2D` 2 px maior que o bloco). O registro é `GameState.register_secret(id)`, idempotente, gravando em `flags["secrets_found"]` (já serializado pelo save da F11). Cada tile `x` é um nó independente, agrupado por `"secret_" + secret_id`, para que paredes de vários tiles sumam juntas.
- **Consequências:** funciona igual para paredes de 1, 2 ou 10 tiles; nenhuma cena nova além de `secret_wall.tscn`.
- **Data:** 2026-09-19

### ADR-F27-002 — Números da parede secreta e total de segredos
- **Contexto:** o GDD não define a estética da revelação nem quantas áreas secretas existem; define 4 Núcleos de Capacitor escondidos fora da rota principal.
- **Decisão:** `Balance.SECRET_WALL_FADE_TIME = 0.4` (s), `Balance.SECRET_WALL_ALPHA = 0.25`, `Balance.SECRETS_TOTAL = 4` (uma área secreta por Núcleo de Capacitor do jogo completo; a Demo tem 1 das 4, exatamente como `LOGS_TOTAL = 24` com 6 na Demo). **Entradas propostas no [GDD-P](../design/GDD.md#gdd-p)** (origem 2.6.3) + linha em [Ajustes](../design/GDD.md#gdd-ajustes): *"a parede falsa fica translúcida em vez de sumir, para o jogador entender o que aconteceu"*.
- **Consequências:** o contador de estatísticas do fim usa a mesma convenção dos outros (`x/total do jogo`).
- **Data:** 2026-09-19

### ADR-F27-003 — `secret_found` é um SFX novo no SFX-PACK
- **Contexto:** o [SFX-PACK](../ASSETS.md#sfx-pack) não tem som de descoberta.
- **Decisão:** pedir a inclusão de `secret_found` na ficha do SFX-PACK (sugestão de fonte: Kenney Interface Sounds, CC0); até lá, placeholder gerado por `tools/make_placeholders.gd`.
- **Consequências:** uma linha nova no `ASSETS.md` (a ser feita pelo orquestrador/skill `asset-request`).
- **Data:** 2026-09-19

### ADR-F27-004 — O registro de segredo usa a convenção `flags["secret_<id>"]` já lida pela F10

- **Contexto:** a seção 6 propunha `flags["secrets_found"]` como **array** de ids. Mas a [F10](F10-telas-fim-de-jogo.md) já tinha entregue `RunStats.secrets_found(state)`, que conta as chaves de `flags` com prefixo `secret_` e valor verdadeiro — e é essa função que monta a linha `SEGREDOS x/4` da tela FIM DA DEMO e a de `GameState.get_stats()`.
- **Decisão:** manter a convenção existente. `register_secret(id)` grava `flags[RunStats.SECRET_PREFIX + id] = true` e devolve `false` se a chave já existia; `has_secret(id)` lê a mesma chave; `secrets_found()` delega para `RunStats`. Nada de array paralelo.
- **Consequências:** zero mudança na F10, zero migração de save (`flags` já é serializado como dicionário pelo [F11](F11-salvar-carregar.md)), e um segredo continua impossível de contar duas vezes porque a chave é única. Em troca, a seção 6 acima está desatualizada nesse ponto — vale este ADR.
- **Data:** 2026-09-19

### ADR-F27-005 — A parede falsa desenha o próprio tile, com rachadura vetorial

- **Contexto:** o [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) ainda não tem uma variação "bloco rachado", e a cena não pode depender do `TileSet` da fase (a mesma cena serve ao Núcleo e à Estufa).
- **Decisão:** `secret_wall.tscn` monta um `Sprite2D` com `AssetResolver.atlas(tiles_path, 16×16, tile_column, tile_row)` — por padrão o bloco cheio da folha da Estufa — mais um `Line2D` de 1 px em zigue-zague como rachadura. `tiles_path`, `tile_column` e `tile_row` são `@export`, então o JSON da fase troca a folha numa linha quando a parede for de outro setor.
- **Consequências:** a dica visual existe sem esperar arte, e some junto com a parede (o `modulate` do `StaticBody2D` propaga para os dois filhos). Quando o tile rachado definitivo chegar, basta apontar `tile_column`/`tile_row` para ele e apagar o `Line2D`.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Implementada

- **Quem**: agente de implementação · **O que**: `scenes/world/secret_wall.tscn` + `secret_wall.gd` (revelação por contato, agrupamento por `secret_id`, fade para `SECRET_WALL_ALPHA`, colisão desligada); `GameState.has_secret/register_secret/secrets_found`; sala de QA `data/levels/secret_test.*` + `scenes/dev/secret_test.tscn`; `tests/test_secrets.gd` (12 casos). · **Achado**: a F10 já lia os segredos por prefixo em `flags`, então o registro seguiu essa convenção (ADR-F27-004). · **Próximo passo**: mover a parede e o `C` para o canto real da Estufa na [F29](F29-fase-estufa.md) (`"4,26"`/`"4,27"` + `"2,27"`) e aposentar a sala de QA.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.6.3 · **Próximo passo**: implementação.

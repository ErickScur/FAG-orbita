---
name: level-design
description: Desenha e constrói uma fase do ÓRBITA — Laboratório (F60), Enfermaria (F61), Docas (F62), Núcleo de Memória (F64), Núcleo do Reator (F65), arenas de chefe — ou reformula uma existente. Cobre o puzzle de energia no papel, o mapa ASCII, os JSONs de fase e de terminal, luz, rotas, segredos, a checagem de alcançabilidade e o roteiro de QA com marcos. Use em "faça a fase X", "a fase está fácil/curta/confusa", ou antes de qualquer edição em data/levels/ ou data/energy/.
---

# level-design — Fase nova sem retrabalho

Por que esta skill existe: na demo, **12 rodadas de retrabalho** vieram do playtest humano, não
de bug — e quase todas diziam a mesma coisa: informação demais, desafio de menos. Além disso, a
F43 achou quatro armadilhas de geometria que **não aparecem em log nenhum**. Esta skill põe as
duas coisas antes do primeiro tile.

## 1. Regras de design (aprendidas no playtest — valem para toda fase fora do tutorial)

| Regra | Origem (fala do humano) |
|---|---|
| **Só o Núcleo Central explica.** Fora dele o terminal mostra título, objetivo e orçamento — sem etiqueta por sistema, sem "AO LIGAR", sem "EXIGE DESLIGAR". O JSON de energia **não** leva `"verbose": true`. | F40: *"é um jogo de puzzle, o jogador só vai saber o objetivo e tem que se virar"* |
| **ÓRBITA fala só em marco**: entrada da fase, descoberta-chave (upgrade), religamento. Nada de comentário ambiente, dica ou `bark` repetido. | F38/F39: *"muito diálogo e pouca gameplay"* |
| **História em poucos fragmentos grandes e difíceis de achar** (logs/dados atrás de parkour, segredo ou escolha de energia cara). | F38: *"menos fragmentos, com mais conteúdo, mais difíceis"* |
| **Fase grande e não linear.** Proibido o formato "liga, sobe, abre a porta e já era". | F43: *"fases maiores, mapas maiores, parkour"* |
| **Toda escolha de energia muda algo visível de onde o jogador está.** Porta que abre para o vazio é defeito. | F28: *"se eu abro a porta não tem nada à frente"* |
| **Escuro é escuro**: `ambient_color` escuro de verdade; a lanterna é necessária. Quem garante legibilidade é o tileset de brilho médio, não o ambiente. | F41: *"não precisa da lanterna"* |
| **Cada interativo tem silhueta própria** (porta do chão ao teto ≠ doca ≠ terminal). Nada de dois objetos com o mesmo vocabulário visual lado a lado. | F54: *"a doca está muito igual à porta"* |
| **HUD não cresce.** Fase nova não põe elemento permanente na tela; informação extra vai para o Terminal do Chassi (F44). | F37/F44: *"muita informação na HUD"* |
| **Checkpoint na entrada é automático** (F53) e há doca antes de cada trecho difícil. | F53: *"tem que dar uns passos para trás para salvar"* |
| **Habilidade nova se ensina com uma sala segura** em que só ela resolve, sem dano, com no máximo um cartão de tecla curto na primeira vez (como as garras na Estufa). | F36 |
| **Religar o Nó termina em cutscene** (F42): o caminho de volta tem lâmpadas, portas e plantas que reagem à energia. Se a fase nova não tem nada energizável no caminho, a cutscene fica vazia. | F42 |

Curva de dificuldade ([GDD-2.7-curva](../../../docs/design/GDD.md#gdd-2-7-curva)): suba **um** eixo por vez — densidade de inimigos, clima com dano, ou complexidade do puzzle (3 sistemas/1 energia no tutorial até 6/3 com dependência em cadeia nas Docas). A Estufa é 3/10 e mesmo assim ficou fácil demais na primeira versão: **calibre para cima**.

## 2. Geometria (fonte: `Balance` + lições da F43)

| Restrição | Valor | Consequência no ASCII |
|---|---|---|
| Altura do pulo (`JUMP_HEIGHT`) | 40 px | degrau de **2 tiles** sobe; 3 tiles não |
| Vão horizontal no mesmo nível | ~62 px (110 px/s × 0,57 s) | vão de até **3 tiles**; 4 só com ajuda |
| Topo colidível da `GrowPlant` | 64 px acima do pé | precisa de **patamar de embarque a 2 tiles do topo**; não se escala do chão |
| Corpo do MU-7 × alcance das garras | 14 px × 10 px | chaminé de escalada com **2 tiles de largura** |
| Plataformas finas empilhadas | — | pelo menos **2 colunas de sobreposição** horizontal |
| Descer de plataforma fina | só ↓ (GDD-2.4) | não exija ↓+pulo |

A autoridade é o teste `tests/test_level_reachability.gd` (lógica em `scripts/core/level_reachability.gd`), que simula a física do `mu7.gd` quadro a quadro a partir do spawn e reprova coletável, terminal, log, doca, saída ou Nó inalcançável, com o motivo provável. Toda fase em `data/levels/*.txt` entra sozinha no teste (só a sandbox `test_room` está isenta). As regras 1 e 2 saem da física; a 3 é regra de design (ADR-F43-002), porque fisicamente 1 coluna de sobreposição até passa num pulo reto, mas é injusta para o jogador.

Para **ver** o mapa marcado (`_` onde o MU-7 fica de pé, `.` onde o corpo passa):
`perl -e 'alarm 200; exec @ARGV' "$GODOT" --headless --path . -s res://tools/level_reach.gd -- --level=<fase>`

O modelo é generoso com energia (toda porta aberta, toda planta crescida, garras sempre ativas, plataforma móvel em qualquer ponto do trilho) e ignora inimigos, perigos e a ordem do puzzle — ele prova que **a geometria** não trava, não que o puzzle tem solução. A ordem do puzzle se prova no papel (§4.2) e no roteiro de QA.

## 3. Luz e sombra
- **No máximo 12 luzes por janela de 256 px** (`tests/test_light_crowding.gd`). No renderer Compatibility, da 17ª luz por item em diante ela é descartada **em silêncio**, e a primeira a sumir costuma ser a lanterna. Brilho repetido por tile (parede magnética, faixas) é **fundido por trecho**.
- Oclusão é o **contorno da ilha sólida** com `cull_mode`, nunca um `OccluderPolygon2D` por tile (o bloco faz sombra na própria face, F50).
- Fundo de parallax: confira onde o assunto da arte cai **depois** de aplicar `scroll_scale` à largura da fase (F49).

## 4. Fluxo

1. **Ler**: a feature (ou crie-a com `plan-feature`), [GDD-2.7](../../../docs/design/GDD.md#gdd-2-7) da fase, o inimigo e o status novos (GDD-2.6.2), a etapa da Jornada, e a Estufa como referência viva (`data/levels/greenhouse.{txt,json}`, `data/energy/greenhouse.json`, `docs/features/F43-estufa-viva.md`).
2. **Puzzle no papel, antes do mapa.** Escreva na seção 4 da feature:
   - tabela de sistemas (id, custo, efeito ligado, efeito desligado, onde o efeito é visível);
   - a **sequência de estados de energia** que resolve a fase (quantas trocas o jogador faz);
   - **por que a solução ingênua falha** (se ligar tudo o que parece óbvio resolve, não é puzzle);
   - onde estão os fragmentos difíceis e o segredo.
3. **ASCII + JSON.** Legenda em `scripts/core/level_builder.gd` (`LEGEND`); esquema de fase da F21/ADR-012 (`terminals`, `entities`, `triggers` com `once`); esquema de energia da F17 (`budget`, `goal_text`, `goal_systems`, `initial`, `systems[]` com `cost`/`requires`/`locked`/`effects`). Entidades com parâmetro usam id no JSON, nunca número mágico no `.gd`.
4. **Alcançabilidade**: `tools/gates.sh --skip-smoke` (roda os testes, inclusive o de alcançabilidade) até verde. Se existir `tools/level_reach.gd`, use-o para ver o mapa marcado.
5. **Portões completos**: `tools/gates.sh`.
6. **Roteiro de QA com marcos** (skill `godot-qa`, modelo `tests/qa/f29_greenhouse.json`): carrega a própria cena no frame 1, `expect_tile` em repouso depois de cada trecho, `expect_scene` no fim. Rode com `tools/qa.sh` e **leia** as capturas.
7. **Checklist antes de chamar o humano para jogar** (todos "sim"):
   - [ ] Fora do tutorial, nenhum texto explica a solução?
   - [ ] ÓRBITA fala no máximo nos marcos?
   - [ ] Existem pelo menos duas trocas de energia obrigatórias e a solução ingênua falha?
   - [ ] Há rota opcional difícil com recompensa (dado/log) e um segredo?
   - [ ] Escuro de verdade em pelo menos um trecho que exige a lanterna?
   - [ ] Cada interativo é distinguível pela silhueta numa captura sem HUD?
   - [ ] A HUD tem os mesmos elementos que tinha antes da fase?
   - [ ] O roteiro de QA chega ao fim com todos os marcos OK?
   - [ ] A cutscene de religamento tem o que mostrar?
8. **Docs**: `/update-feature-docs`; armadilha nova vai para a §5 abaixo.

## 5. Armadilhas conhecidas
- **(F43)** Planta sem patamar de embarque, chaminé de 1 tile e plataforma fina com 1 coluna de sobreposição travam o jogador **sem erro no log** (detalhes na §2).
- **(F54)** Raycast contra `TileMapLayer` falha na primeira física depois do `_ready()`: espere **2 quadros de física** antes de medir o mundo (porta nasceu enfiada na parede).
- **(F47)** Coordenada crua de atlas (`LevelBuilder.ONE_WAY_TILE`, `MagneticWall.TILE_COLUMN/ROW`, `SecretWall.tile_column/row`) é contrato com a arte; tileset novo passa por `tests/test_level_tileset.gd`.
- **(F22)** Sonda de borda de inimigo usa a **mesma máscara de colisão do corpo**, senão o inimigo anda para fora de plataforma fina e cai da fase.
- **(F36)** Mexeu no mapa → os roteiros de QA da fase ficaram falsos. Refaça os marcos.
- **(F60)** Troca forçada de energia some se houver console **depois** da comporta que precisa
  ficar ligada: o jogador a desliga pelas costas. Último console antes dela (ADR-F60-001),
  provado por flood fill em `tests/test_level_lab.gd`.
- **(F60)** Luz fria dentro de zona quente grande some na imagem (o laranja aditivo apaga o azul
  claro): a ilha fria lia como lâmpada branca até a cor ir para `#4aa8ff` com energia 1,2.
  Confira contraste de zona dentro de zona na captura.
- **(F60)** Parede magnética na saída de uma prateleira agarra o MU-7 quando ele só anda para
  fora: use escada de plataforma fina onde a garra não é a intenção.
- **(F60)** Elevador que nasce estacionado no destino e **desce** quando ligado dá consequência
  visível no console e é a única forma de embarcar: bom padrão para "ligar mostra algo".

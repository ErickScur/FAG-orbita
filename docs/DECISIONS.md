# DECISIONS.md — ADRs cross-cutting

> Decisões que afetam o projeto inteiro. Decisão local de uma feature vai na seção 11 dela (`ADR-F<id>-NNN`). Append-only: para mudar uma decisão, crie uma nova que a **substitui** e marque a antiga como `Substituída por ADR-XXX`.

| ADR | Título | Status | Data |
|---|---|:--:|---|
| [000](#adr-000) | Jogo estritamente 2D | Aceita | 2026-09-19 |
| [001](#adr-001) | Godot 4.7.2 + GDScript tipado | Aceita | 2026-09-19 |
| [002](#adr-002) | Renderer Compatibility | Aceita | 2026-09-19 |
| [003](#adr-003) | Resolução 384×216 pixel-perfect, tiles 16 px | Aceita | 2026-09-19 |
| [004](#adr-004) | Fases construídas a partir de ASCII | Aceita | 2026-09-19 |
| [005](#adr-005) | Placeholder-first com contrato de asset | Aceita | 2026-09-19 |
| [006](#adr-006) | Conteúdo narrativo e puzzles em JSON | Aceita | 2026-09-19 |
| [007](#adr-007) | Runner de testes próprio + smoke de cenas + QA por screenshot | Aceita | 2026-09-19 |
| [008](#adr-008) | Git: main, commit por feature, sem co-autor, docs fora do repo | Aceita | 2026-09-19 |
| [009](#adr-009) | Escopo da Demo e ordem de cortes | Aceita | 2026-09-19 |
| [010](#adr-010) | Input Map e camadas de colisão definidos em `project.godot` pelo agente | Aceita | 2026-09-19 |
| [011](#adr-011) | Nós energizados: grupo `powered` + `terminal_id`/`system_id` exportados | Aceita | 2026-09-19 |
| [012](#adr-012) | Esquema do JSON de fase: vale o da F21 | Aceita | 2026-09-19 |
| [013](#adr-013) | Quem troca de cena no fim da demo é a F10 | Aceita | 2026-09-19 |

---

<a id="adr-000"></a>
## ADR-000 — Jogo estritamente 2D

- **Contexto:** o GDD define plataforma 2D lateral em pixel art. O projeto foi criado com Forward+ e `3d/physics_engine="Jolt Physics"` (padrão do Godot). A rubrica lista "3D" e "Elementos de FPS" como mecânicas opcionais.
- **Decisão:** o jogo é **2D, sem exceção**. Só nós 2D/UI. Remover a configuração de física 3D do `project.godot`. Profundidade só via `Parallax2D`. Itens "3D" e "Elementos de FPS" da rubrica ficam `[-]`.
- **Consequências:** arquitetura mais simples; nenhum agente deve propor 3D para ganhar ponto. Varredura de nós 3D é portão de qualidade.

<a id="adr-001"></a>
## ADR-001 — Godot 4.7.2 + GDScript tipado

- **Contexto:** projeto criado no Godot 4.7.2 stable (`~/Downloads/Godot.app`). O humano não programa em Godot; os agentes precisam de feedback rápido por CLI.
- **Decisão:** GDScript com tipagem estática em tudo. Sem C#/.NET, sem GDExtension. Binário acessado por `$GODOT` (env em `.claude/settings.json`). Addons de terceiros só com ADR.
- **Consequências:** `--headless` permite importar, testar e fazer smoke sem editor. Tipagem pega erros no `--import`.

<a id="adr-002"></a>
## ADR-002 — Renderer Compatibility

- **Contexto:** Forward+ é o padrão, mas é pensado para 3D e exige GPU com Vulkan/Metal moderno. A apresentação pode rodar em PC da faculdade.
- **Decisão:** `rendering/renderer/rendering_method="gl_compatibility"` (e `.mobile` idem). `Light2D` com sombras e `CanvasModulate` funcionam nele.
- **Consequências:** roda em hardware fraco; permite export Web no futuro. Alguns efeitos avançados (SDF/GI 2D) ficam indisponíveis — não usamos.

<a id="adr-003"></a>
## ADR-003 — Resolução 384×216 pixel-perfect, tiles 16 px

- **Contexto:** GDD-2.9 pede pixel art em 384×216 escalada por inteiro para 1920×1080, sprites 32×32.
- **Decisão:** `display/window/size/viewport_width=384`, `viewport_height=216`, `window_width_override=1280`, `window_height_override=720`, `stretch/mode="viewport"`, `stretch/aspect="keep"`, `stretch/scale_mode="integer"`, `rendering/textures/canvas_textures/default_texture_filter=0` (nearest), `rendering/2d/snap/snap_2d_transforms_to_pixel=true`. **Tile = 16 px** (ver [AJ-001](design/GDD.md#gdd-ajustes)). UI desenhada na mesma resolução com fonte pixel.
- **Consequências:** 24×13,5 tiles por tela; câmera com `limit_*` por fase. Todo asset segue esses tamanhos (contrato no `ASSETS.md`).

<a id="adr-004"></a>
## ADR-004 — Fases construídas a partir de ASCII

- **Contexto:** pintar `TileMapLayer` exige o editor (o humano não sabe usá-lo) e é difícil para um agente editar o formato binário/compactado de tiles no `.tscn`.
- **Decisão:** cada fase é um `data/levels/<fase>.txt` (uma linha = uma linha de tiles) + `data/levels/<fase>.json` (metadados: ids de terminal, logs, portas, trilha, paleta). `scripts/core/level_builder.gd` lê o texto e, em `_ready()` da cena da fase, preenche o `TileMapLayer` (com `set_cells_terrain_connect` ou atlas coords diretas) e instancia entidades por caractere. A `TileSet` é um `.tres` escrito pelo agente.
- **Consequências:** o agente desenha e ajusta fases como texto e verifica por screenshot. O editor pode mostrar a fase vazia até rodar (aceitável). Legenda documentada em [F21](features/F21-construtor-fases-ascii.md).

<a id="adr-005"></a>
## ADR-005 — Placeholder-first com contrato de asset

- **Contexto:** 3 dias de prazo; arte/som dependem de busca gratuita ou geração no Nano Banana Pro pelo humano.
- **Decisão:** toda entidade nasce com placeholder gerado por `tools/make_placeholders.gd` (formas simples na paleta do setor, tamanho final correto) em `assets/placeholder/`. O `ASSETS.md` define o **contrato** (caminho final, dimensão, frames, grade do spritesheet). Trocar arte = colocar o arquivo definitivo no caminho final e apontar a cena para ele (1 linha). Áudio placeholder = silêncio/beep gerado.
- **Consequências:** desenvolvimento nunca bloqueia em arte. Risco: a demo ficar "feia" se não houver tempo de troca → Dia 3 reserva um bloco para assets.

<a id="adr-006"></a>
## ADR-006 — Conteúdo narrativo e puzzles em JSON

- **Contexto:** textos (logs da Helena, falas da ÓRBITA) e configurações de terminais mudam muito e devem ser editáveis sem mexer em código.
- **Decisão:** `data/logs/*.json`, `data/dialogue/*.json`, `data/energy/*.json`, carregados via `FileAccess` + `JSON.parse_string`. Esquemas documentados nas features F17 e F19.
- **Consequências:** o agente escreve conteúdo sem tocar em cena; testes validam que todo JSON carrega e referencia ids existentes.

<a id="adr-007"></a>
## ADR-007 — Runner de testes próprio + smoke de cenas + QA por screenshot

- **Contexto:** GUT/gdUnit4 são addons pesados e com risco de incompatibilidade com 4.7.2; o prazo é curto.
- **Decisão:** `tests/run_tests.gd` (`extends SceneTree`) descobre `tests/test_*.gd`, executa métodos `test_*` e sai com código ≠ 0 em falha. `tools/smoke.sh` carrega cada cena de `tests/scenes.txt` headless por alguns frames. A skill `godot-qa` roda o jogo com janela usando o autoload `QACapture` (ativo só com `-- --qa`) para injetar inputs roteirizados e salvar PNGs que o agente lê.
- **Consequências:** zero dependência externa; o agente enxerga o jogo. Testes cobrem só lógica pura em `scripts/core/`.

<a id="adr-008"></a>
## ADR-008 — Git: main, commit por feature, sem co-autor, docs fora do repo

- **Contexto:** um único desenvolvedor; a doc viva é para os agentes; o repositório é público e avaliado.
- **Decisão:** branch única `main`; um commit por feature (ou fatia), mensagem pt-BR `<tipo>(F<id>): <resumo>`; **nunca** `Co-Authored-By`/menção a IA; `.gitignore` exclui `CLAUDE.md`, `.claude/`, `docs/*` exceto `docs/design/`. Repositório **público** no GitHub. Push só com autorização do humano.
- **Consequências:** o histórico conta a evolução do jogo feature a feature (bom para a apresentação). Design (GDD/Jornada) fica visível no repo.

<a id="adr-009"></a>
## ADR-009 — Escopo da Demo e ordem de cortes

- **Contexto:** 1ª entrega = demo com ~30% do jogo, em 3 dias de trabalho focado. Avaliação por rubrica (ver [`ENTREGAS.md`](ENTREGAS.md)).
- **Decisão:** Demo = **Fase 0 Núcleo Central + Fase 1 Estufa**, jogáveis do menu à tela "FIM DA DEMO", com **todas** as telas da rubrica (menu, splash/loading, fim de jogo, volume, pause, recomeçar) e as mecânicas dos Blocos 0–4 do INDEX. Stretch (Bloco 5) só após o Bloco 4. **Ordem de corte** se o tempo apertar: F34 → F33 → F32 → F31 → F26 → planta da F25 → F23. **Nunca cortar:** F17 (Terminal) e as telas da rubrica.
- **Consequências:** o Final herda todos os sistemas prontos e foca em conteúdo (fases 2–6, bosses, finais).

<a id="adr-010"></a>
## ADR-010 — Input Map e camadas de colisão definidos em `project.godot` pelo agente

- **Contexto:** configurar Input Map pelo editor exige muitos cliques do humano.
- **Decisão:** o agente escreve a seção `[input]` do `project.godot` (eventos `InputEventKey`/`InputEventJoypadButton`/`InputEventJoypadMotion` serializados) e `[layer_names]` (camadas do `/CLAUDE.md` §4.2). Validação: `--import` sem erro + teste que confere `InputMap.has_action()` para todas as ações do GDD-2.4.
- **Consequências:** zero ação humana para input; remapeamento em runtime fica para a F51.

<!--
<a id="adr-0NN"></a>
## ADR-0NN — <título>
- **Contexto:** …
- **Decisão:** …
- **Consequências:** …
-->

<a id="adr-011"></a>
## ADR-011 — Nós energizados: grupo `powered` + `terminal_id`/`system_id`

- **Contexto:** a [F21](features/F21-construtor-fases-ascii.md) previa agrupar os nós que reagem a energia por **nome de grupo** escrito no JSON da fase (`group: "gh_spores"`), enquanto as features F17–F34 usam o contrato do `/CLAUDE.md` §4.3: grupo `"powered"` + `@export var terminal_id: StringName` e `system_id: StringName`, reagindo a `EventBus.energy_changed`.
- **Decisão:** vale o **contrato** (`powered` + ids exportados). O `LevelBuilder` passa `terminal_id`/`system_id` como parâmetros vindos do JSON da fase ao instanciar `@`, `m`, `g`, `~`, `|`, `z`. Nenhum nó descobre seu estado por nome de grupo.
- **Consequências:** um `system_id` pode alimentar vários nós sem inventar grupos; `EnergyNetwork` restaura o estado no `_ready()` da fase percorrendo o grupo `powered`. A F21 trata o exemplo dela como ilustração.

<a id="adr-012"></a>
## ADR-012 — Esquema do JSON de fase: vale o da F21

- **Contexto:** F28/F29 escreveram metadados de fase com chaves próprias (`palette{}`, `music: "MUS-CORE"`, `tileset: "core"`), enquanto a F21 definiu o esquema do parser (`ambient_color`, `music: "core"`, `tileset` como caminho `.tres`, `terminals: [...]`, `triggers[]`).
- **Decisão:** o esquema **canônico é o da F21**. As fases traduzem 1:1 (cada doc já traz o bloco de compatibilidade). O `triggers[]` ganha dois tipos além de `dialogue`: **`objective`** (chama `GameState.set_objective`) e **`set_flag`**, ambos com `once`.
- **Consequências:** um parser só, testável; as fases não podem inventar chave nova sem atualizar a F21 e o teste do esquema.

<a id="adr-013"></a>
## ADR-013 — Quem troca de cena no fim da demo é a F10

- **Contexto:** tanto a F29 (fase) quanto a F10 (telas de fim) podiam reagir a `demo_completed` e chamar `SceneManager.goto`, o que causaria troca dupla.
- **Decisão:** a fase **só emite** `EventBus.demo_completed`; **a F10 escuta e troca** para `demo_end.tscn`. Mesma regra para `game_over(reason)` e para a morte do chassi.
- **Consequências:** fases não conhecem telas; a F10 é o único lugar com a política de fim de jogo.
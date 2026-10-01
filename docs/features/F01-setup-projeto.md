---
id: F01
title: Setup do projeto, git & GitHub
status: done
scope: demo
block: 0
priority: P0
rubric: ["Github"]
depends_on: []
unblocks: ["F02", "F05", "F06", "F30"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F01 — Setup do projeto, git & GitHub

## 1. Contexto e objetivo

O projeto Godot foi criado com os padrões do editor: renderer **Forward+**, física 3D **Jolt**, stretch `canvas_items`/`expand`, sem Input Map, sem nomes de camadas e sem cena principal. Nada disso serve a um plataforma 2D em pixel art 384×216. Esta feature deixa o `project.godot` no estado definitivo das decisões cross-cutting ([ADR-000](../DECISIONS.md#adr-000), [ADR-002](../DECISIONS.md#adr-002), [ADR-003](../DECISIONS.md#adr-003), [ADR-010](../DECISIONS.md#adr-010)), cria o `README.md` público e publica o repositório no GitHub.

É a base de tudo: sem o `project.godot` correto, nenhuma cena renderiza em pixel nítido, nenhuma ação de input existe e o agente não consegue rodar o jogo nem os portões. Serve indiretamente aos três pilares ([GDD pilares](../design/GDD.md#gdd-pilares)); diretamente, entrega o item **Github** da rubrica (repo público, histórico de commits por feature, README).

O `.gitignore`, o `git init`, o commit inicial e o `.claude/settings.json` (com `$GODOT`) **já foram feitos pelo orquestrador** — não são escopo desta feature, só são conferidos.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.4 — Controles](../design/GDD.md#gdd-2-4) (nomes e teclas das ações) · [GDD-2.9 — Estilo visual](../design/GDD.md#gdd-2-9-visual) (384×216, escala inteira) · [GDD-2.2 — Visão geral](../design/GDD.md#gdd-2-2) (pitch para o README)
- **Parâmetros:** `Balance.TILE_SIZE` ([GDD-P](../design/GDD.md#gdd-p)) — só como referência; `balance.gd` nasce na [F02](F02-autoloads-nucleo.md)
- **Ajustes:** [AJ-001, AJ-005](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Ideia principal](../design/JORNADA-DO-HEROI.md#jh-ideia) (texto de apresentação do README)
- **ADRs:** [ADR-000](../DECISIONS.md#adr-000) · [ADR-001](../DECISIONS.md#adr-001) · [ADR-002](../DECISIONS.md#adr-002) · [ADR-003](../DECISIONS.md#adr-003) · [ADR-008](../DECISIONS.md#adr-008) · [ADR-010](../DECISIONS.md#adr-010)

## 3. Critério de avaliação atendido

- **Github** ([ENTREGAS §3.1](../ENTREGAS.md#rubrica)): o avaliador abre `https://github.com/<usuário>/orbita`, vê o repositório **público**, o `README.md` com descrição, controles, como rodar, integrantes e créditos, e o histórico de commits `feat(F<id>): …` feature a feature. A release `v0.1-demo` é da [F30](F30-build-demo.md).

## 4. Escopo

### Inclui
- `project.godot` reescrito à mão: nome, renderer Compatibility, remoção da física 3D, resolução/stretch do ADR-003, `[input]` com as 12 ações do GDD-2.4 (teclado + controle), `[layer_names]` com as 7 camadas 2D, `run/main_scene` apontando para `res://scenes/boot/splash.tscn`.
- `[autoload]` **vazio** por ora (F06 registra `QACapture`, F02 registra os demais).
- Cena mínima `scenes/boot/splash.tscn` (stub) para que a cena principal exista; a [F03](F03-cenas-splash-loading.md) a substitui.
- Árvore de pastas do [`/CLAUDE.md` §4.1](../../CLAUDE.md) criada com um `.gitkeep` onde ficaria vazia.
- `README.md` público em pt-BR.
- 🧑 Criação do repositório no GitHub e autenticação; `git remote add` + `git push` feitos pelo agente com autorização.

### Não inclui
- `.gitignore`, `git init`, commit inicial, `.claude/settings.json` (orquestrador).
- Autoloads e `balance.gd` ([F02](F02-autoloads-nucleo.md)); testes e smoke ([F06](F06-testes-portoes-qa.md)); splash de verdade ([F03](F03-cenas-splash-loading.md)); `default_bus_layout.tres` ([F04](F04-audio-volume.md)).
- Janela 1920×1080 e presets de export ([F30](F30-build-demo.md)).
- Remapeamento de teclas em runtime (F51 — Final).
- GitHub Actions/CI (Final, se houver tempo).

## 5. Critérios de aceite

- [x] `project.godot` contém `config/features=PackedStringArray("4.7", "GL Compatibility")` e `renderer/rendering_method="gl_compatibility"` + `.mobile` idem.
- [x] Não existe nenhuma linha `3d/` nem `Forward Plus` nem `d3d12` no `project.godot`.
- [x] Ao rodar `"$GODOT" --path .` abre uma janela 1280×720 com a cena stub em pixel nítido (texto sem borrão, escala inteira ×3 do viewport 384×216).
- [x] Redimensionar a janela mantém escala inteira com barras pretas (stretch `viewport` + `keep` + `integer`).
- [x] `[input]` contém exatamente: `move_left`, `move_right`, `move_up`, `move_down`, `jump`, `dash`, `interact`, `beam`, `flashlight`, `map`, `log_archive`, `pause` com as teclas e botões da tabela da seção 6.
- [x] `[layer_names]` contém `2d_physics/layer_1="world"` … `layer_7="one_way"`.
- [x] `"$GODOT" --headless --path . --import` termina sem `ERROR`/`Parse Error`.
- [x] `README.md` existe na raiz com as seções listadas na seção 6, controles idênticos ao GDD-2.4 e **sem** menção a IA/Claude.
- [x] `git remote -v` mostra `origin https://github.com/<usuário>/orbita.git` e `git push -u origin main` concluiu; o repo é **Public** no navegador.
- [x] Commit `chore(F01): configura projeto 2D, input e README` sem `Co-Authored-By`.
- [x] Portões do `/CLAUDE.md` §6 verdes (os que já existem nesta fase: `--import` e varreduras 3D/comentários).
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
project.godot                     reescrito
README.md                         novo
scenes/boot/splash.tscn           stub: Control "Splash" + Label "ÓRBITA" centralizado
autoload/ scripts/core/ scenes/{boot,ui,player,enemies,world,levels}/
data/{levels,energy,logs,dialogue}/ assets/{sprites,tiles,ui,fonts,audio/music,audio/sfx,placeholder}/
tests/ tools/                     pastas vazias recebem .gitkeep
```

### `project.godot` alvo (seções relevantes)

```ini
config_version=5

[application]
config/name="ÓRBITA"
config/description="Plataforma 2D de exploração com puzzles de energia na estação ARTEMIS."
run/main_scene="res://scenes/boot/splash.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")
config/icon="res://icon.svg"

[autoload]

[display]
window/size/viewport_width=384
window/size/viewport_height=216
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="viewport"
window/stretch/aspect="keep"
window/stretch/scale_mode="integer"

[input]
(ver abaixo)

[layer_names]
2d_physics/layer_1="world"
2d_physics/layer_2="player"
2d_physics/layer_3="enemy"
2d_physics/layer_4="interactable"
2d_physics/layer_5="hazard"
2d_physics/layer_6="pickup"
2d_physics/layer_7="one_way"

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```

Remover: `[physics] 3d/physics_engine`, `rendering_device/driver.windows`, `window/stretch/mode="canvas_items"`, `aspect="expand"`.

### Input Map ([ADR-010](../DECISIONS.md#adr-010), [GDD-2.4](../design/GDD.md#gdd-2-4))

| Ação | Teclas (`physical_keycode`) | Controle |
|---|---|---|
| `move_left` | A (65), ← (4194319) | eixo 0 valor −1.0 |
| `move_right` | D (68), → (4194321) | eixo 0 valor +1.0 |
| `move_up` | W (87), ↑ (4194320) | eixo 1 valor −1.0 |
| `move_down` | S (83), ↓ (4194322) | eixo 1 valor +1.0 |
| `jump` | Espaço (32) | botão 0 (A) |
| `dash` | Shift (4194325) | botão 1 (B) |
| `interact` | E (69) | botão 2 (X) |
| `beam` | Q (81) | botão 3 (Y) |
| `flashlight` | F (70) | botão 9 (LB) |
| `map` | Tab (4194306) | botão 4 (Back/Select) |
| `log_archive` | L (76) | — |
| `pause` | Esc (4194305) | botão 6 (Start) |

`deadzone` 0.2 em todas (0.5 nos eixos). Formato serializado de cada evento (exemplo `jump`):

```ini
jump={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":0,"pressure":0.0,"pressed":true,"script":null)
]
}
```

Eixo (exemplo `move_left`): `Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":0,"axis_value":-1.0,"script":null)`.

As ações `ui_*` padrão permanecem (não precisam ser escritas). Para o menu responder ao controle, `ui_accept` já inclui o botão 0 por padrão.

### `README.md` (público)

Seções, em pt-BR, sem menção a IA:
1. `# ÓRBITA` + frase do [GDD-2.1](../design/GDD.md#gdd-2-1) + tema da disciplina ("ESTAÇÃO" → estação espacial ARTEMIS).
2. **Sobre** — pitch do [GDD-2.2](../design/GDD.md#gdd-2-2) e os 3 pilares.
3. **Status** — "Demo (1ª entrega): Fase 0 Núcleo Central + Fase 1 Estufa".
4. **Controles** — tabela idêntica ao GDD-2.4 (só as ações da Demo; `map` marcado "entrega final").
5. **Como rodar** — baixar Godot 4.7.2, `godot --path .` ou abrir `project.godot` no editor e apertar F5; link da release (preenchido pela F30).
6. **Estrutura do projeto** — árvore resumida (autoload, scenes, scripts/core, data, assets, tests, tools) e "fases em ASCII".
7. **Design** — links para `docs/design/GDD.md` e `docs/design/JORNADA-DO-HEROI.md` (versionados).
8. **Equipe** — Alex Hoffmann, Erick Scur, Murilo Wolff Klug, Kauan Giacomin, Victor William · Prof. Jeferson Eduardo Guido · disciplina Desenvolvimento de Jogos.
9. **Créditos e licenças** — tabela espelho de [ASSETS.md → Créditos](../ASSETS.md) (vazia agora; cada feature que integra asset acrescenta linha).

### Autoloads / sinais do EventBus
- Nenhum. `[autoload]` fica vazio.

### Dados (`data/`)
- Só as pastas.

### Input actions / camadas de colisão
- Definidas aqui (tabelas acima). Validação automática por teste fica na [F06](F06-testes-portoes-qa.md) (`tests/test_project_settings.gd`).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| — | O stub do splash usa só `Label` com a fonte padrão | — |

## 8. 🧑 Ação humana

> 🧑 **AÇÃO HUMANA — Criar o repositório público "orbita" no GitHub e autorizar o push** (≈ 10 min)
> **Por quê:** o agente não tem conta no GitHub nem pode criar repositórios ou digitar senhas. A rubrica exige o repositório público.
>
> **Parte A — Conta e repositório**
> 1. Abra o navegador em **https://github.com/login**. Se já tem conta, entre com usuário e senha. Se não tem, clique em **Create an account**, preencha e-mail, senha e nome de usuário, resolva o desafio e confirme o código enviado ao e-mail.
> 2. Já logado, abra **https://github.com/new**.
> 3. Em **Owner**, deixe o seu usuário. Em **Repository name**, digite `orbita`.
> 4. Em **Description** (opcional), cole: `ÓRBITA — plataforma 2D em Godot sobre uma IA sozinha na estação espacial ARTEMIS.`
> 5. Marque **Public**.
> 6. **Não** marque **Add a README file**. Em **Add .gitignore**, deixe **None**. Em **Choose a license**, deixe **None**. (O projeto já tem esses arquivos; marcar qualquer um deles faz o primeiro push falhar.)
> 7. Clique no botão verde **Create repository**.
> 8. Na página que abre, na caixa **Quick setup**, confirme que o botão **HTTPS** está selecionado (não SSH) e clique no ícone de copiar ao lado da URL. Ela tem o formato `https://github.com/SEU-USUARIO/orbita.git`.
>
> **Parte B — Autenticação (escolha UMA das opções)**
>
> *Opção 1 (recomendada) — GitHub CLI, login pelo navegador:*
> 1. Abra o app **Terminal** (⌘ + Espaço, digite `Terminal`, Enter).
> 2. Cole e rode: `brew install gh` (o Homebrew já está instalado nesta máquina). Espere terminar.
> 3. Rode: `gh auth login`.
> 4. Responda com as setas + Enter: **GitHub.com** → **HTTPS** → *Authenticate Git with your GitHub credentials?* **Yes** → **Login with a web browser**.
> 5. O Terminal mostra um código de 8 caracteres (ex.: `ABCD-1234`). Copie, aperte Enter; o navegador abre em github.com/login/device. Cole o código, clique **Continue** e depois **Authorize github**.
> 6. Volte ao Terminal: deve aparecer `✓ Logged in as SEU-USUARIO`. Rode `gh auth status` para confirmar.
>
> *Opção 2 — Personal Access Token (sem instalar nada):*
> 1. No navegador, abra **https://github.com/settings/tokens** (menu da sua foto → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**).
> 2. Clique **Generate new token** → **Generate new token (classic)**.
> 3. **Note:** `orbita-mac`. **Expiration:** `90 days`. Em **Select scopes**, marque só **repo**.
> 4. Clique **Generate token** no fim da página e **copie o token** (começa com `ghp_`). Ele só aparece uma vez; guarde num lugar seguro e **não cole no chat do agente**.
> 5. Abra o **Terminal**, rode `cd /Users/BRScurPaEr/code/fag/jogo` e depois o comando que o agente vai mostrar: `git push -u origin main`.
> 6. Quando pedir **Username**, digite seu usuário do GitHub. Quando pedir **Password**, cole o **token** (nada aparece enquanto cola; é normal) e Enter. O macOS guarda o token no Keychain; os próximos pushes do agente funcionam sem perguntar.
>
> **Parte C — Autorizar o agente**
> 1. Envie ao agente a URL copiada na Parte A, passo 8, e diga qual opção de autenticação usou.
> 2. O agente roda `git remote add origin <URL>` e, com sua autorização, `git push -u origin main` (na Opção 2, se o push pedir senha, ele pede que você rode o push no seu Terminal uma única vez).
>
> **Pronto quando:** em `https://github.com/SEU-USUARIO/orbita` aparecem os arquivos do projeto e o `README.md` renderizado, com o selo **Public** ao lado do nome. · **Avise o agente com:** "Repo criado: https://github.com/SEU-USUARIO/orbita.git — autentiquei com a opção 1 (ou 2). Pode dar push."

## 9. Plano de execução

- [ ] **Passo 1** — Conferir o que o orquestrador fez: `git log --oneline` tem o commit inicial, `.gitignore` exclui `CLAUDE.md`, `.claude/`, `docs/*` exceto `docs/design/`, e `echo $GODOT` aponta para o binário.
- [ ] **Passo 2** — Reescrever `project.godot` conforme a seção 6 (manter `config_version=5` e `config/icon`). Escrever o `[input]` completo das 12 ações.
- [ ] **Passo 3** — Criar a árvore de pastas com `.gitkeep` e o stub `scenes/boot/splash.tscn` (`Control` full-rect + `ColorRect` preto + `Label` "ÓRBITA" centralizado).
- [ ] **Passo 4** — `"$GODOT" --headless --path . --import`; corrigir qualquer erro de parse do `project.godot`.
- [ ] **Passo 5** — Abrir com janela (`"$GODOT" --path . --quit-after 120`) e conferir visualmente (screenshot manual via `screencapture` se ainda não houver `QACapture`).
- [ ] **Passo 6** — Escrever `README.md`.
- [ ] **Passo 7** — Varreduras do §6 (3D e comentários) e `git status --short`.
- [ ] **Passo 8** — Commit `chore(F01): configura projeto 2D, input e README`.
- [ ] **Passo 9** — Mostrar ao humano o bloco 🧑 da seção 8 e **parar** até a confirmação.
- [ ] **Passo 10** — `git remote add origin <URL>`; com autorização explícita, `git push -u origin main`; conferir `git status -sb` mostrando `main...origin/main`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** nenhum nesta feature. A [F06](F06-testes-portoes-qa.md) cria `tests/test_project_settings.gd` que confere `InputMap.has_action()` das 12 ações, o renderer `gl_compatibility`, viewport 384×216 e os 7 nomes de camadas.
- **Smoke:** `scenes/boot/splash.tscn` entra em `tests/scenes.txt` quando a F06 existir.
- **Roteiro godot-qa (após F06):** cena `res://scenes/boot/splash.tscn`, sem inputs; screenshot no frame 10 `f01_splash_stub` deve mostrar fundo preto e "ÓRBITA" com bordas duras (sem antialias), ocupando o centro da imagem 384×216.
- **Verificação manual:** `grep -nE "3d/|Forward|d3d12" project.godot` vazio; `grep -c "physical_keycode" project.godot` ≥ 16 (16 teclas na tabela).
- **Playtest humano (opcional):** abrir o repo no navegador e ler o README como se fosse o professor.

## 11. ADRs locais

### ADR-F01-001 — Stub de splash para satisfazer `run/main_scene`
- **Contexto:** `run/main_scene` precisa apontar para uma cena existente, mas o splash real é da F03.
- **Decisão:** criar um stub mínimo no caminho final `scenes/boot/splash.tscn`; a F03 o sobrescreve.
- **Consequências:** o jogo abre desde o primeiro commit. **Data:** 2026-09-19.

### ADR-F01-002 — Push só após confirmação humana
- **Contexto:** [ADR-008](../DECISIONS.md#adr-008) exige autorização para push; `gh` não está instalado.
- **Decisão:** o agente prepara tudo, mostra a ação humana e só roda `git push` depois do "pode dar push".
- **Consequências:** a F01 pode ficar `[~]` esperando o humano; F02+ podem seguir localmente. **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD, ADRs 000–010 e estado atual do `project.godot` · **Próximo passo**: implementação.

### 2026-09-19 — Implementação
- **Quem**: agente (feature-loop Dia 1)
- **O que foi feito**: `project.godot` reescrito (nome ÓRBITA, Compatibility, 384×216 stretch viewport/keep/integer, filtro nearest, snap 2D, 12 ações de input com teclado+controle, 7 camadas 2D, main_scene = splash stub); removidos Forward+, Jolt 3D, driver d3d12 e stretch canvas_items; árvore de pastas do CLAUDE §4.1 criada com `.gitkeep`; `scenes/boot/splash.tscn` stub; `README.md` público completo.
- **Verificação**: `--import` sem erros; jogo abre em OpenGL Compatibility sem `ERROR`/`SCRIPT ERROR`; varreduras 3D e de comentários vazias.
- **Repositório**: remoto `git@github.com:ErickScur/FAG-orbita.git` configurado pelo humano (SSH em vez de HTTPS; `main` sincronizada) — a Parte A/B da ação humana já estava cumprida.
- **Próximo passo**: F02 (autoloads núcleo + Balance).

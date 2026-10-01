---
id: F30
title: Build & release da Demo
status: not-started
scope: demo
block: 4
priority: P0
rubric: ["Github"]
depends_on: ["F01", "F10", "F28", "F29"]
unblocks: []
estimate: 1.5h
last_updated: 2026-09-19
---

# F30 — Build & release da Demo

## 1. Contexto e objetivo

A entrega 1 só existe quando alguém **que não é o time** consegue jogar. Esta feature fecha a Demo: gera as builds de **macOS** e **Windows** a partir de `export_presets.cfg` escrito pelo agente, escreve o `README.md` final (controles + créditos espelhando o [`ASSETS.md`](../ASSETS.md)), cria a tag `v0.1-demo` e publica uma **Release no GitHub** com os dois zips anexados.

É o item **Github** da rubrica e fecha a [Definition of Done da Demo](../ENTREGAS.md#entregas): *"do splash ao FIM DA DEMO sem crash, em build exportada (macOS e Windows)"*, repositório público com README, créditos e release.

Duas coisas aqui **não** são possíveis por arquivo/CLI e viram ação humana: instalar os *export templates* do Godot 4.7.2 (download de ~1 GB feito pelo editor) e publicar a Release pela web (o `gh` não está instalado nesta máquina).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.2 (plataforma: PC)](../design/GDD.md#gdd-2-2) · [GDD-2.9 estética (pixel-perfect 1920×1080)](../design/GDD.md#gdd-2-9-visual) · [GDD-2.8 telas (a Demo termina em FIM DA DEMO)](../design/GDD.md#gdd-2-8-telas)
- **Parâmetros:** nenhum de gameplay. A resolução e o modo de stretch vêm do [ADR-003](../DECISIONS.md#adr-003).
- **Entregas:** [ENTREGAS §1 — Definition of Done da Demo e tag `v0.1-demo`](../ENTREGAS.md#entregas) · [ENTREGAS §3.1 — Github](../ENTREGAS.md#rubrica) · [roteiro da apresentação](../ENTREGAS.md#apresentacao)
- **ADRs:** [ADR-001](../DECISIONS.md#adr-001) (Godot 4.7.2) · [ADR-002](../DECISIONS.md#adr-002) (Compatibility) · [ADR-003](../DECISIONS.md#adr-003) · [ADR-008](../DECISIONS.md#adr-008) (git/main, push só autorizado) · [ADR-009](../DECISIONS.md#adr-009)
- **Features vizinhas:** [F01 — Setup do projeto, git & GitHub](F01-setup-projeto.md) (repo, `.gitignore`), [F28](F28-fase-nucleo-central.md)/[F29](F29-fase-estufa.md) (o conteúdo que será exportado), [F10](F10-telas-fim-de-jogo.md) (a tela que fecha o percurso).

## 3. Critério de avaliação atendido

**Github** ([rubrica](../ENTREGAS.md#rubrica)). O avaliador abre o repositório público e vê: histórico de commits **por feature** em pt-BR, `README.md` com pitch, controles, créditos e licenças, o GDD versionado em `docs/design/`, a tag `v0.1-demo` e uma **Release** com `ORBITA-v0.1-demo-macos.zip` e `ORBITA-v0.1-demo-windows.zip`. Na apresentação, o jogo roda **da build exportada**, não do editor.

## 4. Escopo

### Inclui
- `export_presets.cfg` escrito pelo agente (presets **macOS** e **Windows Desktop**), com filtros que garantem a inclusão de `data/**` (fases `.txt` e JSONs) e a exclusão de `tests/` e `tools/`.
- `build/` no `.gitignore`.
- Comandos de export headless e empacotamento dos zips.
- Assinatura **ad-hoc** do `.app` no macOS (sem conta Apple) e verificação com `codesign -dv`.
- Smoke da build exportada (rodar o `.app` e conferir ausência de `SCRIPT ERROR`/`ERROR:`).
- `README.md` final: pitch, como jogar (macOS e Windows, incluindo o aviso de app não assinado), **controles** ([GDD-2.4](../design/GDD.md#gdd-2-4), só o que existe na Demo), créditos do time + professor, créditos de assets/licenças espelhando o [`ASSETS.md`](../ASSETS.md), licença da engine e como rodar do código-fonte.
- Tag anotada `v0.1-demo`.
- 🧑 Ação humana 1: instalar os export templates 4.7.2 pelo editor.
- 🧑 Ação humana 2: publicar a Release no GitHub pela web, anexando os zips.
- `tests/test_export_presets.gd` (valida o `.cfg` sem precisar exportar).

### Não inclui
- Export **Web/HTML5**, Linux, mobile ou console — fora do escopo da disciplina.
- Assinatura/notarização Apple de verdade (exige conta paga) e certificado Windows — o README explica como abrir mesmo assim.
- Instalador (.dmg, .msi, Inno Setup) — zip basta.
- **Push automático**: `git push` (main e tag) só acontece com autorização explícita do humano ([ADR-008](../DECISIONS.md#adr-008)).
- Screenshots/GIF no README gerados automaticamente (opcional: reaproveitar PNGs da QA copiando para `media/`).

## 5. Critérios de aceite

- [ ] `export_presets.cfg` existe, está commitado e `tests/test_export_presets.gd` passa.
- [ ] `"$GODOT" --headless --path . --export-release "macOS" build/macos/ORBITA.app` termina com código 0 e sem `ERROR:`.
- [ ] `"$GODOT" --headless --path . --export-release "Windows Desktop" build/windows/ORBITA.exe` termina com código 0 e gera o `.exe` com o `.pck` embutido.
- [ ] `codesign -dv build/macos/ORBITA.app` reporta assinatura (ad-hoc aceita).
- [ ] Rodar `build/macos/ORBITA.app/Contents/MacOS/ORBITA` abre o jogo na janela (1920×1080 ou tela cheia) com pixel nítido, som e sem erro no stdout.
- [ ] Percurso completo na build: **splash → loading → menu → opções (volume/dificuldade) → Núcleo Central → Estufa → FIM DA DEMO**, sem crash.
- [ ] As fases carregam na build (prova de que `data/**` foi incluído no pacote) — se a fase aparecer vazia, o filtro está errado.
- [ ] `build/ORBITA-v0.1-demo-macos.zip` e `build/ORBITA-v0.1-demo-windows.zip` gerados, e `build/` **não** aparece em `git status`.
- [ ] `README.md` com controles, créditos do time, professor, licenças dos assets e instruções de abertura em macOS/Windows.
- [ ] `git tag -l` mostra `v0.1-demo` apontando para o commit da Demo completa.
- [ ] Release publicada no GitHub com os dois zips (confirmação do humano + link).
- [ ] Portões do `/CLAUDE.md` §6 verdes
- [ ] Sem comentários no código; nada 3D

## 6. Definição técnica

### Arquivos
```
export_presets.cfg        (raiz, commitado)
README.md                 (raiz, commitado)
.gitignore                (+ build/)
tests/test_export_presets.gd
build/                    (ignorado pelo git)
  macos/ORBITA.app
  windows/ORBITA.exe
  ORBITA-v0.1-demo-macos.zip
  ORBITA-v0.1-demo-windows.zip
```

### `export_presets.cfg`

Chaves omitidas assumem o padrão do Godot; escreva só o que importa:

```ini
[preset.0]

name="macOS"
platform="macOS"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="data/*.txt, data/*.json, data/**/*.txt, data/**/*.json"
exclude_filter="tests/*, tools/*, docs/*, *.md"
export_path="build/macos/ORBITA.app"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

binary_format/architecture="universal"
application/bundle_identifier="com.orbita.demo"
application/short_version="0.1"
application/version="0.1.0"
application/copyright="2026 Alex Hoffmann, Erick Scur, Murilo Wolff Klug, Kauan Giacomin, Victor William"
notarization/notarization=0

[preset.1]

name="Windows"
platform="Windows Desktop"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="data/*.txt, data/*.json, data/**/*.txt, data/**/*.json"
exclude_filter="tests/*, tools/*, docs/*, *.md"
export_path="build/windows/ORBITA.exe"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.1.options]

binary_format/architecture="x86_64"
binary_format/embed_pck=true
application/modify_resources=false
application/product_name="ORBITA"
application/file_version="0.1.0.0"
application/product_version="0.1.0.0"
application/company_name="Equipe ÓRBITA"
application/file_description="ORBITA - Demo"
codesign/enable=false
```

Pontos que **quebram a build** se forem esquecidos (ADR-F30-001):
1. `include_filter` com `data/**` — fases em `.txt` e JSONs **não** são recursos importados do Godot; sem o filtro, o jogo exporta sem fases e a tela fica vazia.
2. `application/modify_resources=false` no Windows — mudar ícone/metadados do `.exe` exige `rcedit`, que não está instalado no macOS; com `true`, o export falha ou avisa.
3. `binary_format/embed_pck=true` no Windows — entrega um `.exe` único, mais simples de zipar e de o professor abrir.
4. `script_export_mode=2` — GDScript em binário (mais rápido para carregar); se der qualquer problema de carregamento, volte para `1` (texto).

### Comandos (macOS, host de desenvolvimento)

```bash
export GODOT="/Users/BRScurPaEr/Downloads/Godot.app/Contents/MacOS/Godot"

ls "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable/" | head        # 1. templates instalados?

mkdir -p build/macos build/windows
"$GODOT" --headless --path . --import                                                     # 2. reimporta assets
"$GODOT" --headless --path . --export-release "macOS" build/macos/ORBITA.app              # 3. build macOS
"$GODOT" --headless --path . --export-release "Windows Desktop" build/windows/ORBITA.exe  # 4. build Windows

codesign --force --deep --sign - build/macos/ORBITA.app                                   # 5. assinatura ad-hoc
codesign -dv build/macos/ORBITA.app                                                       #    deve dizer "Signature=adhoc"

build/macos/ORBITA.app/Contents/MacOS/ORBITA --quit-after 600 2>&1 | grep -E "ERROR|SCRIPT ERROR"   # 6. smoke (sem saída = ok)

ditto -c -k --keepParent build/macos/ORBITA.app build/ORBITA-v0.1-demo-macos.zip          # 7. zips
ditto -c -k --keepParent build/windows build/ORBITA-v0.1-demo-windows.zip
```
Se o passo 1 mostrar a pasta vazia ou inexistente, **pare** e execute a 🧑 AÇÃO HUMANA 1 (seção 8).

### Tag e push

```bash
git status --short                 # nada de CLAUDE.md, .claude/, docs/ (exceto docs/design/), nada de build/
git add README.md export_presets.cfg .gitignore
git commit -m "feat(F30): presets de export, README e empacotamento da Demo"
git tag -a v0.1-demo -m "ÓRBITA — Demo (1ª entrega): Núcleo Central + Estufa"
# push SOMENTE com autorização explícita do humano:
git push origin main
git push origin v0.1-demo
```

### Estrutura do `README.md`

1. **ÓRBITA** + uma linha de pitch ([GDD-2.1](../design/GDD.md#gdd-2-1)) e o badge/linha "Demo v0.1 — Godot 4.7.2".
2. **O que é** (3 linhas) + tema da disciplina: Estação Espacial ARTEMIS.
3. **Como jogar** — link da Release; macOS (descompactar, **botão direito → Abrir**, e o caminho alternativo em *Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim*); Windows (descompactar, se aparecer o SmartScreen: *Mais informações → Executar assim mesmo*).
4. **Controles** (só o que existe na Demo):

   | Ação | Teclado | Controle |
   |---|---|---|
   | Mover | A / D ou ← / → | Analógico esquerdo |
   | Subir / descer (escalar) | W / S ou ↑ / ↓ | Analógico esquerdo |
   | Pular | ESPAÇO | A |
   | Interagir | E | X |
   | Lanterna | F | LB |
   | Pausar | ESC | Start |
   | Dash · Feixe · Arquivo de Logs | SHIFT · Q · L | B · Y · — |

   (as três últimas só entram se as stretch [F31](F31-dash-feixe.md)/[F33](F33-arquivo-logs.md) forem implementadas — remover a linha se não.)
5. **O que a Demo tem** — Fase 0 + Fase 1, puzzle de energia, timer do reator, lanterna, logs, coletáveis, área secreta, SR-3, esporos, garras magnéticas.
6. **Equipe** — Alex Hoffmann, Erick Scur, Murilo Wolff Klug, Kauan Giacomin, Victor William · Professor: Jeferson Eduardo Guido · disciplina de Desenvolvimento de Jogos.
7. **Créditos e licenças** — tabela **espelhada** da seção "Créditos e licenças" do [`ASSETS.md`](../ASSETS.md) (asset, autor, licença, link); citar Godot Engine (MIT) e, se a fonte [UI-FONT](../ASSETS.md#ui-font) for a m5x7 de Daniel Linssen, o crédito pedido pelo autor.
8. **Rodar do código-fonte** — clonar, abrir com Godot 4.7.2, ou `godot --path .`.
9. **Design** — link para `docs/design/GDD.md` e `docs/design/JORNADA-DO-HEROI.md` (os únicos docs versionados).

### Autoloads / sinais do EventBus
- Nenhum. Esta feature não toca em código de jogo.

### Dados (`data/`)
- Nenhum arquivo novo — mas é **a** feature que garante que `data/` chega à build (ver `include_filter`).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-LOGO](../ASSETS.md#ui-logo) | Ícone da janela/app e imagem do topo do README | Texto "ÓRBITA" na fonte pixel |
| (todos) | A tabela de créditos do README espelha o [`ASSETS.md`](../ASSETS.md) | — |

## 8. 🧑 Ação humana

> 🧑 **AÇÃO HUMANA — Instalar os modelos de exportação (export templates) do Godot 4.7.2** (≈ 10 min, dependendo da internet)
> **Por quê:** para gerar o jogo como aplicativo (macOS e Windows), o Godot precisa de uns arquivos-base de ~1 GB que ele **não** traz instalados. Só o editor sabe baixar e instalar esses arquivos no lugar certo. Sem eles, o comando de exportação falha.
> 1. Abra o **Godot**: vá em `Downloads` e dê dois cliques em **Godot** (o ícone do robozinho azul).
> 2. Se aparecer a lista de projetos, dê dois cliques no projeto **jogo** para abrir o editor. Espere carregar (pode demorar na primeira vez).
> 3. Na barra de menus **no topo da tela**, clique em **Editor**.
> 4. No menu que abrir, clique em **Manage Export Templates…** (em português: **Gerenciar Modelos de Exportação…**).
> 5. Vai abrir uma janelinha. Clique no botão **Download and Install** (**Baixar e Instalar**). Se ele pedir para escolher um servidor (*mirror*), escolha o primeiro da lista, que costuma ser **GitHub**.
> 6. Espere a barra de progresso chegar ao fim. **Não feche a janela** e não desligue o Wi-Fi. São ~1 GB; pode levar de 3 a 15 minutos.
> 7. Quando terminar, a janelinha vai mostrar a versão **4.7.2.stable** com a palavra **Installed** (**Instalado**). Clique em **Close** (**Fechar**).
> 8. Pode fechar o Godot.
> **Pronto quando:** a janela "Manage Export Templates" mostra **4.7.2.stable — Installed**. · **Avise o agente com:** "templates instalados".
>
> *Alternativa sem editor (se preferir que o agente faça):* autorize o agente a baixar ~1 GB por linha de comando — ele baixa o arquivo `Godot_v4.7.2-stable_export_templates.tpz` da página oficial de releases do Godot e descompacta em `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`. Diga: **"pode baixar os templates por CLI"**.

> 🧑 **AÇÃO HUMANA — Publicar a Release no GitHub** (≈ 5 min)
> **Por quê:** o item "Github" da nota pede o jogo publicado. Esta máquina não tem a ferramenta `gh` instalada, e publicar release exige estar logado na sua conta — então é mais rápido e seguro você fazer pelo site.
> **Antes de começar:** o agente precisa ter feito o `git push` da `main` e da tag `v0.1-demo` (ele vai pedir sua autorização para isso), e os dois arquivos `.zip` precisam existir na pasta `build/` do projeto.
> 1. Abra o navegador e entre no endereço do repositório do jogo no **GitHub** (o mesmo link que você usou na F01). Faça login se pedir.
> 2. Na página inicial do repositório, olhe a **coluna da direita** e clique em **Releases** (ou em "Create a new release", se aparecer).
> 3. Clique no botão **Draft a new release** (**Rascunhar uma nova versão**).
> 4. Clique em **Choose a tag** (**Escolher uma tag**) e selecione **v0.1-demo** na lista. (Se ela não aparecer, o push da tag não foi feito — avise o agente.)
> 5. No campo **Release title** (título), escreva: `ÓRBITA — Demo v0.1`.
> 6. No campo grande de descrição, cole o texto que o agente te entregou (ele prepara o texto com o que a demo contém e os controles).
> 7. Na área escrita **Attach binaries by dropping them here or selecting them**, clique e selecione os dois arquivos: `ORBITA-v0.1-demo-macos.zip` e `ORBITA-v0.1-demo-windows.zip`. Eles estão na pasta `build` dentro da pasta do projeto. Espere os dois terminarem de subir (aparece uma barrinha em cada um).
> 8. Marque a caixinha **Set as a pre-release** (é uma demo, não a versão final).
> 9. Clique no botão verde **Publish release**.
> **Pronto quando:** a página da release mostra o título, os **dois** arquivos `.zip` listados e a etiqueta "Pre-release". · **Avise o agente com:** "release publicada" e cole o link da página.

## 9. Plano de execução

- [ ] **Passo 1** — Conferir se `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` existe; se não, entregar a 🧑 AÇÃO HUMANA 1 e **parar** até a confirmação.
- [ ] **Passo 2** — Escrever `export_presets.cfg` (seção 6) e `tests/test_export_presets.gd`; acrescentar `build/` ao `.gitignore`.
- [ ] **Passo 3** — `--import` e os dois exports; corrigir o que o log acusar.
- [ ] **Passo 4** — Assinatura ad-hoc + smoke da build + percurso completo jogado na build (é aqui que se descobre asset/fase faltando no pacote).
- [ ] **Passo 5** — Gerar os dois zips com `ditto`.
- [ ] **Passo 6** — Escrever o `README.md` final (estrutura da seção 6), espelhando os créditos do `ASSETS.md`.
- [ ] **Passo 7** — `/verify-gates`, `git status --short`, commit `feat(F30): presets de export, README e empacotamento da Demo` e tag `v0.1-demo`.
- [ ] **Passo 8** — Pedir autorização do humano para `git push` (main + tag); em seguida entregar a 🧑 AÇÃO HUMANA 2 com o texto da release pronto para colar.
- [ ] **Passo 9** — Depois do "release publicada": marcar a linha **Github** em [ENTREGAS §3.1](../ENTREGAS.md#rubrica), fechar a feature no INDEX e registrar o link no log.

## 10. Verificação

- **Testes (`tests/test_export_presets.gd`)** — lê `res://export_presets.cfg` com `ConfigFile` (sem exportar nada):
  - `test_has_two_presets`: seções `preset.0` e `preset.1` existem.
  - `test_platforms`: uma é `"macOS"`, a outra `"Windows Desktop"`.
  - `test_include_filter_has_data`: os dois `include_filter` contêm `data/` com `.txt` e `.json`.
  - `test_exclude_filter_has_tests_and_tools`.
  - `test_windows_embeds_pck` e `test_windows_does_not_modify_resources`.
  - `test_export_paths_under_build`: os dois `export_path` começam com `build/`.
- **Smoke:** não se aplica a cenas; o smoke aqui é a **build rodando** (`--quit-after 600` sem `ERROR:`).
- **Roteiro godot-qa:** a QA por screenshot roda no projeto, não na build. O equivalente aqui é o **percurso manual na build exportada**, com o mesmo caminho do [roteiro da apresentação](../ENTREGAS.md#apresentacao): splash → loading → menu → opções (mexer no volume e na dificuldade) → Núcleo Central → Estufa → morrer uma vez → religar o Nó → FIM DA DEMO. Guardar 3 capturas para o README/release: menu, Terminal de Distribuição aberto e a tela FIM DA DEMO.
- **Playtest humano (obrigatório):** o humano baixa o zip **da própria release**, abre em um Mac e (se possível) em um PC Windows e joga do começo ao fim. É a única prova de que a entrega funciona fora da máquina de desenvolvimento.

## 11. ADRs locais

### ADR-F30-001 — `include_filter` explícito para `data/**`
- **Contexto:** `export_filter="all_resources"` leva só o que o Godot **importa** como recurso. As fases em ASCII (`data/levels/*.txt`) e os JSONs de conteúdo ([ADR-004](../DECISIONS.md#adr-004), [ADR-006](../DECISIONS.md#adr-006)) são arquivos crus lidos por `FileAccess` — eles ficariam **de fora** do pacote e o jogo abriria com fases vazias.
- **Decisão:** `include_filter` explícito com `data/*.txt, data/*.json, data/**/*.txt, data/**/*.json` nos dois presets, e um critério de aceite que só passa se a fase **carregar na build**.
- **Consequências:** qualquer pasta nova de conteúdo cru precisa entrar no filtro — anotar em `/CLAUDE.md` §9 (lições aprendidas).
- **Data:** 2026-09-19

### ADR-F30-002 — Assinatura ad-hoc no macOS, sem notarização
- **Contexto:** Macs com Apple Silicon recusam binários sem assinatura; notarizar exige conta paga de desenvolvedor Apple, que o time não tem.
- **Decisão:** assinar **ad-hoc** (`codesign --force --deep --sign -`) e documentar no README o "botão direito → Abrir" e o caminho por *Ajustes do Sistema → Privacidade e Segurança*.
- **Consequências:** o app roda; o professor vê um aviso do Gatekeeper na primeira abertura, previsto no README.
- **Data:** 2026-09-19

### ADR-F30-003 — Release publicada pela web, push só com autorização
- **Contexto:** o `gh` não está instalado nesta máquina e o [ADR-008](../DECISIONS.md#adr-008) proíbe push sem autorização.
- **Decisão:** o agente prepara tudo localmente (commit, tag, zips, texto da release) e o humano executa dois passos: autorizar o push e publicar a release pela interface do GitHub.
- **Consequências:** nada é publicado sem o humano saber; a feature só fecha com o link da release no log.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial com presets de export, comandos, README, tag e os dois blocos de ação humana · **Próximo passo**: execução no Dia 3, depois de F28 e F29.

# INDEX.md — Catálogo mestre do ÓRBITA

> **Catálogo de todas as features.** Atualize o status conforme avança.
>
> **Antes de qualquer coisa**, leia [`/CLAUDE.md`](../CLAUDE.md), [`AGENTS.md`](AGENTS.md) e [`ENTREGAS.md`](ENTREGAS.md). Depois pegue a próxima feature aqui.

---

## Documentos âncora

- [`/CLAUDE.md`](../CLAUDE.md) — engenharia: regras duras, stack, arquitetura, convenções, portões
- [`design/GDD.md`](design/GDD.md) — **design e números canônicos** (fonte da verdade; tabela [GDD-P](design/GDD.md#gdd-p))
- [`design/JORNADA-DO-HEROI.md`](design/JORNADA-DO-HEROI.md) — **narrativa canônica** (9 etapas → fases)
- [`ENTREGAS.md`](ENTREGAS.md) — escopo da **Demo** e do **Final**, rubrica da disciplina → feature, roteiro da apresentação
- [`AGENTS.md`](AGENTS.md) — protocolo de trabalho para agentes
- [`VISION.md`](VISION.md) — visão em 1 página
- [`DECISIONS.md`](DECISIONS.md) — ADRs cross-cutting
- [`GLOSSARY.md`](GLOSSARY.md) — termos do jogo
- [`ASSETS.md`](ASSETS.md) — registro de assets (contrato, fonte, licença, prompt, status)
- [`ASSET-PIPELINE.md`](ASSET-PIPELINE.md) — guia de estilo, fontes gratuitas, prompts Nano Banana Pro
- [`EDITOR-GUIDE.md`](EDITOR-GUIDE.md) — Godot para leigos + formato do bloco 🧑 AÇÃO HUMANA
- [`TEMPLATE-FEATURE.md`](TEMPLATE-FEATURE.md) — template canônico de feature

---

## Legenda

| Símbolo | Status |
|---|---|
| `[ ]` | Não iniciado |
| `[~]` | Em progresso |
| `[x]` | Concluído (critérios de aceite + portões verdes) |
| `[!]` | Bloqueado (motivo no log da feature) |
| `[-]` | Removido / fora de escopo (com ADR) |

**Escopo:** `DEMO` = obrigatório na 1ª entrega · `STRETCH` = entra na demo se sobrar tempo · `FINAL` = entrega final (arquivo da feature nasce quando ela for planejada).

---

## Ordem de execução

Top-down por bloco. Dentro de um bloco, top-down, respeitando `depends_on`. **Não pule blocos sem ADR.** O ritmo sugerido para os 3 dias está em [`ENTREGAS.md`](ENTREGAS.md#ritmo-3-dias).

---

## Bloco 0 — Fundação

> Projeto configurado, sistemas globais e pipeline. Sem isto nada roda.

| # | Feature | Escopo | Rubrica | Status | Atualizado |
|---|---|:--:|---|:--:|---|
| F01 | [Setup do projeto, git & GitHub](features/F01-setup-projeto.md) | DEMO | Github | `[x]` | 2026-09-19 |
| F02 | [Autoloads núcleo & Balance](features/F02-autoloads-nucleo.md) | DEMO | — | `[x]` | 2026-09-19 |
| F03 | [SceneManager, Splash & Loading](features/F03-cenas-splash-loading.md) | DEMO | Splash/Loading | `[x]` | 2026-09-19 |
| F04 | [Áudio & ajuste de volume](features/F04-audio-volume.md) | DEMO | Volume · Música · Efeitos sonoros | `[x]` | 2026-09-19 |
| F05 | [Pipeline de assets & placeholders](features/F05-pipeline-assets-placeholders.md) | DEMO | Efeitos visuais | `[x]` | 2026-09-19 |
| F06 | [Testes, portões & QA por screenshot](features/F06-testes-portoes-qa.md) | DEMO | — | `[x]` | 2026-09-19 |

## Bloco 1 — Telas e meta-sistemas

> As telas que valem ponto direto na rubrica.

| # | Feature | Escopo | Rubrica | Status | Atualizado |
|---|---|:--:|---|:--:|---|
| F07 | [Menu principal](features/F07-menu-principal.md) | DEMO | Menu | `[x]` | 2026-09-19 |
| F08 | [Opções & dificuldade ajustável](features/F08-opcoes-dificuldade.md) | DEMO | Volume · Dificuldade ajustável | `[x]` | 2026-09-19 |
| F09 | [Pause & recomeçar](features/F09-pause-recomecar.md) | DEMO | Botão de pause · Botão de recomeçar | `[x]` | 2026-09-19 |
| F10 | [Telas de fim de jogo](features/F10-telas-fim-de-jogo.md) | DEMO | Tela de fim de jogo | `[x]` | 2026-09-19 |
| F11 | [Salvar / Carregar](features/F11-salvar-carregar.md) | DEMO | Salvar/Carregar progresso | `[x]` | 2026-09-19 |

## Bloco 2 — Núcleo de gameplay

> O MU-7, os recursos, o timer e o Terminal de Distribuição (o coração do jogo).

| # | Feature | Escopo | Rubrica | Status | Atualizado |
|---|---|:--:|---|:--:|---|
| F12 | [Movimento do MU-7 & câmera](features/F12-movimento-mu7.md) | DEMO | — (base) | `[x]` | 2026-09-19 |
| F13 | [Integridade, Carga, dano & respawn](features/F13-integridade-carga-respawn.md) | DEMO | Life skills · Recompensas | `[x]` | 2026-09-19 |
| F14 | [Estabilidade do Reator (timer global)](features/F14-estabilidade-reator.md) | DEMO | — (req. bimestre: timer) | `[x]` | 2026-09-19 |
| F15 | [HUD & objetivo atual](features/F15-hud-objetivos.md) | DEMO | HUD · Missões primárias | `[x]` | 2026-09-19 |
| F16 | [Sistema de interação](features/F16-interacao.md) | DEMO | — (base) | `[x]` | 2026-09-19 |
| F17 | [Terminal de Distribuição de Energia](features/F17-terminal-distribuicao.md) ⭐ | DEMO | Puzzle | `[x]` | 2026-09-19 |
| F18 | [Luz, sombra & lanterna](features/F18-luz-lanterna.md) | DEMO | Luz/Sombra · Efeitos naturais (campo de visão) | `[x]` | 2026-09-19 |
| F19 | [Diálogo, legendas & logs](features/F19-dialogo-logs.md) | DEMO | Diálogo | `[x]` | 2026-09-19 |
| F20 | [Coletáveis & contadores](features/F20-coletaveis-contadores.md) | DEMO | Coleta de itens · Score · Itens | `[x]` | 2026-09-19 |
| F21 | [Construtor de fases ASCII](features/F21-construtor-fases-ascii.md) | DEMO | — (infra) | `[x]` | 2026-09-19 |

## Bloco 3 — Mundo & ameaças

| # | Feature | Escopo | Rubrica | Status | Atualizado |
|---|---|:--:|---|:--:|---|
| F22 | [Inimigo SR-3 "Aranha de Reparo"](features/F22-inimigo-sr3.md) | DEMO | — (req. bimestre: inimigos) | `[x]` | 2026-09-19 |
| F23 | [Enxame de Esporos & efeitos de status](features/F23-esporos-status.md) | DEMO | Efeitos naturais | `[x]` | 2026-09-19 |
| F24 | [Garras Magnéticas (habilidade)](features/F24-garras-magneticas.md) | DEMO | Habilidades | `[x]` | 2026-09-19 |
| F25 | [Plataformas móveis & planta que cresce](features/F25-plataformas-moveis-planta.md) | DEMO | Plataformas que se movimentam | `[x]` | 2026-09-19 |
| F26 | [Parallax espacial](features/F26-parallax.md) | DEMO | Paralax | `[x]` | 2026-09-19 |
| F27 | [Área secreta](features/F27-area-secreta.md) | DEMO | Área secreta | `[x]` | 2026-09-19 |

## Bloco 4 — Fases da Demo & entrega

| # | Feature | Escopo | Rubrica | Status | Atualizado |
|---|---|:--:|---|:--:|---|
| F28 | [Fase 0 — Núcleo Central (tutorial/hub)](features/F28-fase-nucleo-central.md) | DEMO | Música (trilha) | `[x]` | 2026-09-19 |
| F29 | [Fase 1 — Estufa](features/F29-fase-estufa.md) | DEMO | Música (trilha) · Efeitos visuais/sonoros | `[x]` | 2026-09-19 |
| F30 | [Build & release da Demo](features/F30-build-demo.md) | DEMO | Github | `[ ]` | 2026-09-19 |

## Bloco 5 — Stretch da Demo

> Só depois do Bloco 4 `[x]`. Ordem de corte inversa: F34 → F33 → F32 → F31.

| # | Feature | Escopo | Rubrica | Status | Atualizado |
|---|---|:--:|---|:--:|---|
| F31 | [Dash magnético & Feixe de Manutenção](features/F31-dash-feixe.md) | STRETCH | Habilidades · Combate (não-letal) | `[ ]` | 2026-09-19 |
| F32 | [Obstáculos ambientais (vapor, piso elétrico)](features/F32-obstaculos-ambientais.md) | STRETCH | Efeitos visuais/sonoros | `[ ]` | 2026-09-19 |
| F33 | [Arquivo de Logs (codex)](features/F33-arquivo-logs.md) | STRETCH | Diálogo · Itens e inventário | `[ ]` | 2026-09-19 |
| F34 | [Drone BOTÂNICO 04](features/F34-drone-botanico.md) | STRETCH | Movimento aleatório de NPCs | `[ ]` | 2026-09-19 |
| F35 | [Polimento visual da Demo](features/F35-polimento-visual.md) | STRETCH | Efeitos visuais · Efeitos naturais · HUD · Paralax | `[x]` | 2026-09-20 |

## Bloco 5B — Revisão de jogabilidade (playtest humano de 2026-09-20)

> Origem: o primeiro playtest de ponta a ponta feito pelo humano. Diagnóstico dele, em três
> frases: o HUD tem informação demais e sem rótulo; ÓRBITA fala demais e os fragmentos de
> história são muitos e pequenos; o tutorial não ensina nada. Estas três features são **DEMO**,
> não stretch: sem elas a demo é confusa para quem não construiu o jogo.

| # | Feature | Escopo | Rubrica | Status | Atualizado |
|---|---|:--:|---|:--:|---|
| F36 | [Tutorial de verdade & briefing do MU-7](features/F36-tutorial-briefing.md) | DEMO | Missões primárias · Puzzle · Splash/Loading | `[x]` | 2026-09-20 |
| F37 | [Legibilidade do HUD e dos coletáveis](features/F37-legibilidade-hud.md) | DEMO | HUD · Score · Coleta de itens | `[x]` | 2026-09-20 |
| F38 | [Narrativa enxuta: menos falas, logs maiores](features/F38-narrativa-enxuta.md) | DEMO | Diálogo · Recompensas | `[x]` | 2026-09-20 |

## Bloco 5C — Menos informação, mais puzzle (playtest humano de 2026-09-20)

> Segundo playtest. O princípio que o humano fixou, nas palavras dele: *"É um jogo de puzzle,
> precisamos dar menos informações, o jogador só vai saber o objetivo, e tem que se virar.
> **Nao aplicar no tutorial, lá é excecção.**"* Vale como regra de design daqui para frente:
> o Núcleo Central explica tudo, as demais fases não explicam nada além do objetivo.

| # | Feature | Escopo | Rubrica | Status | Atualizado |
|---|---|:--:|---|:--:|---|
| F39 | [Diálogo enxuto e no tempo certo](features/F39-dialogo-enxuto.md) | DEMO | Diálogo | `[x]` | 2026-09-20 |
| F40 | [Terminal mudo fora do tutorial](features/F40-terminal-mudo.md) | DEMO | Puzzle | `[x]` | 2026-09-20 |
| F41 | [Escuridão de verdade](features/F41-escuridao.md) | DEMO | Luz/Sombra · Efeitos naturais | `[x]` | 2026-09-20 |
| F42 | [Cutscene de religamento do setor](features/F42-cutscene-religamento.md) | DEMO | Efeitos visuais · Recompensas | `[x]` | 2026-09-20 |
| F43 | [Estufa com cara de estufa](features/F43-estufa-viva.md) | DEMO | Efeitos naturais · Puzzle | `[x]` | 2026-09-20 |
| F44 | [Terminal do chassi e HUD magro](features/F44-terminal-do-chassi.md) | DEMO | HUD · Itens e inventário · Score | `[x]` | 2026-09-20 |
| F45 | [Ir e voltar entre setores](features/F45-ida-e-volta.md) | DEMO | Missões primárias | `[ ]` | 2026-09-20 |
| F46 | [Trilha por momento](features/F46-trilha-por-momento.md) | DEMO | Música | `[x]` | 2026-09-20 |
| F47 | [Tilesets definitivos](features/F47-tilesets-definitivos.md) | DEMO | Desenvolvimento de fases · Luz/Sombra | `[x]` | 2026-09-20 |
| F48 | [Props definitivos](features/F48-props-definitivos.md) | DEMO | Efeitos visuais | `[x]` | 2026-09-20 |
| F49 | [Partículas, fundo e logo](features/F49-fx-fundo-logo.md) | DEMO | Paralax · Efeitos naturais | `[x]` | 2026-09-20 |
| F50 | [Sombras legíveis](features/F50-sombras-legiveis.md) | DEMO | Luz/Sombra · Desenvolvimento de fases | `[x]` | 2026-09-20 |
| F51 | [Coletáveis, doca, HUD e drone](features/F51-sprites-coletaveis-hud.md) | DEMO | Coleta de itens · HUD | `[x]` | 2026-09-20 |
| F52 | [Efeitos sonoros](features/F52-efeitos-sonoros.md) | DEMO | Efeitos visuais/sonoros | `[x]` | 2026-09-20 |
| F53 | [Backup ao entrar na fase](features/F53-backup-ao-entrar.md) | DEMO | Salvar/Carregar | `[x]` | 2026-09-20 |
| F54 | [Porta, doca e portal](features/F54-porta-e-doca.md) | DEMO | Efeitos visuais | `[x]` | 2026-09-20 |
| F53 | [Backup ao entrar numa fase](features/F53-backup-ao-entrar.md) | DEMO | Salvar/Carregar progresso | `[x]` | 2026-09-20 |

## Bloco 6+ — Entrega final (não detalhado)

> Arquivo de feature criado quando for planejada (skill `plan-feature`). Referências de design já apontadas.

| # | Feature | Escopo | Rubrica | Design | Status |
|---|---|:--:|---|---|:--:|
| F60 | Fase 2 — Laboratório (Verão, CX-2, Superaquecimento, Dissipador) | FINAL | 4 fases · Efeitos naturais | [GDD-2.7 F2](design/GDD.md#gdd-2-7-f2) | `[ ]` |
| F61 | Fase 3 — Enfermaria (Inverno, V-9, Congelamento, Núcleo Aquecido) | FINAL | 4 fases | [GDD-2.7 F3](design/GDD.md#gdd-2-7-f3) | `[ ]` |
| F62 | Fase 4 — Docas (vácuo, Propulsor) | FINAL | 4 fases | [GDD-2.7 F4](design/GDD.md#gdd-2-7-f4) | `[ ]` |
| F63 | Mini boss — O Serralheiro | FINAL | Mini-boss | [GDD-2.6.2-G](design/GDD.md#gdd-2-6-2-g) | `[ ]` |
| F64 | Fase 5 — Núcleo de Memória / Protocolo Luto | FINAL | Boss | [GDD-2.6.2-H](design/GDD.md#gdd-2-6-2-h) | `[ ]` |
| F65 | Fase 6 — Núcleo do Reator / ARGOS | FINAL | Boss | [GDD-2.6.2-I](design/GDD.md#gdd-2-6-2-i) | `[ ]` |
| F66 | Final alternativo, epílogo por Dados & 40 nomes | FINAL | Fim de jogo alternativo | [Jornada 8–9](design/JORNADA-DO-HEROI.md#jh-8) | `[ ]` |
| F67 | Mapa da estação (TAB) | FINAL | Scanner | [GDD-2.8](design/GDD.md#gdd-2-8-telas) | `[ ]` |
| F68 | Status restantes (Superaquecimento, Congelamento, Descarga, Sobrecarga) | FINAL | Efeitos naturais | [GDD-2.6.2-F](design/GDD.md#gdd-2-6-2-f) | `[ ]` |
| F69 | Upgrades permanentes (Capacitor, Blindagem) & Acesso Root | FINAL | Nível/progressão · Recompensas | [GDD-2.6.3](design/GDD.md#gdd-2-6-3) | `[ ]` |
| F70 | Música adaptativa por camadas | FINAL | Música | [GDD-2.9](design/GDD.md#gdd-2-9-musica) | `[ ]` |
| F71 | Remapeamento de teclas & acessibilidade | FINAL | — | [GDD-2.8](design/GDD.md#gdd-2-8-telas) | `[ ]` |
| F72 | Apresentação final (5–10 min) | FINAL | Apresentação | [ENTREGAS](ENTREGAS.md#apresentacao) | `[ ]` |

## Fora de escopo

| Item da rubrica | Status | Motivo |
|---|:--:|---|
| 3D · Elementos de FPS | `[-]` | Jogo estritamente 2D — [ADR-000](DECISIONS.md#adr-000) |
| Elementos de RTS · Turnos · Montaria · Sandbox · Endless · Conta de usuário · Classes de personagem · Armaduras · Loja · Dinheiro · Simulação de dia | `[-]` | Não servem aos pilares do GDD; ver [ENTREGAS](ENTREGAS.md#rubrica) |

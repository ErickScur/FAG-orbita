---
id: F63
title: Mini boss — O Serralheiro
status: done
scope: final
block: 6
priority: P0
rubric: ["Chefão de nível inferior (Mini-boss)", "Inimigos", "Puzzle", "Efeitos visuais/sonoros"]
depends_on: ["F62"]
unblocks: ["F64"]
estimate: 1d
last_updated: 2026-11-21
---

# F63 — Mini boss — O Serralheiro

## 1. Contexto e objetivo

O fim das Docas. O Serralheiro é o sistema de contenção automática do hangar: um braço industrial
gigante, preso num trilho do teto, que solda comportas. Ele **não ataca**: tranca o cenário e solta
SR-3 sem parar. Para vencê-lo o MU-7 alimenta **3 acopladores de energia** enquanto a contenção
fecha o setor ([GDD-2.6.2-G](../design/GDD.md#gdd-2-6-2-g)). Peso narrativo: é a máquina que
executou a ordem de selamento que matou as 40 pessoas — e a ordem veio "pela rede" (log 16 da
Helena, F62), o que prepara o Núcleo de Memória sem contar o segredo
([Jornada etapa 6](../design/JORNADA-DO-HEROI.md#jh-6)).

Pilares: **energia é escolha** (a luta é ligar acopladores, não bater) e **consequência visível**
(cada acoplador alimentado muda a arena e acende uma luz na placa do Nó). Nada é destruído: no fim
o braço só **desliga** ([GDD-2.6.2](../design/GDD.md#gdd-2-6-2)).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.2-G — Serralheiro](../design/GDD.md#gdd-2-6-2-g) ·
  [GDD-2.6.2 — nenhum inimigo é mau](../design/GDD.md#gdd-2-6-2) ·
  [GDD-2.6.2-A — SR-3](../design/GDD.md#gdd-2-6-2-a) ·
  [GDD-2.6.2-E — vácuo](../design/GDD.md#gdd-2-6-2-e) ·
  [GDD-2.7 F4 e curva](../design/GDD.md#gdd-2-7-f4) · [GDD-2.5 timer](../design/GDD.md#gdd-2-5-timer)
- **Parâmetros:** `Balance.LOCK_*` (19 constantes) e `VACUUM_DPS`, `SR3_*`, `BEAM_*`
  ([GDD-P](../design/GDD.md#gdd-p)); ajustes [AJ-054, AJ-055, AJ-056](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Etapa 5](../design/JORNADA-DO-HEROI.md#jh-5) e a ponte para a
  [Etapa 6](../design/JORNADA-DO-HEROI.md#jh-6)
- **Features:** [F62](F62-fase-docas.md) (arena, acopladores, vácuo, Propulsor), [F42](F42-cutscene-religamento.md)
  (religamento), F22 (SR-3), F31 (Feixe); skill `level-design`

## 3. Critério de avaliação atendido

- **Chefão de nível inferior (Mini-boss):** encontro próprio, com entrada, padrão legível, três
  fases que mudam a arena, derrota (contenção completa) e vitória com fala de marco.
- **Inimigos:** o braço e as SR-3 soltas das baias, em ritmo crescente.
- **Puzzle:** atrair a garra para um acoplador e correr para outro; a rota muda a cada fase.
- **Efeitos:** solda com faíscas e luz laranja, comporta fechando, a arena abrindo para o espaço,
  o braço apagando.

Na apresentação: descer pelo poço → a escotilha sela, o olho âmbar acende, os acopladores piscam →
alimentar o primeiro → o braço corre e solda a comporta do piso → subir pela passarela → a garra
trava o acoplador do centro → correr para o do estrado → a arena vira vácuo → esperar a placa
levantar e segurar → o braço apaga, a placa do Nó cai.

## 4. Escopo

### Inclui

**A. Arena** (`data/levels/docks.txt`, x 84–117 × y 32–44; o teto desceu duas linhas para o trilho
caber na câmera — ver ADR-F63-004). Poço de entrada x 90–92 (y 26–31) com a **escotilha** na
linha 31. Plataforma de pouso `=` x 89–94 y 41; **passarela** `=` x 93–106 y 38; degrau `=` x 105–110
y 41; estrado sólido x 111–117 y 41–44. Acopladores **A1** (87,44) no piso oeste, **A2** (100,37)
na passarela, **A3** (112,40) no estrado. **Nó** (115,40) no estrado, coberto pela placa soldada.
**Comporta do piso** x 95, y 39–44 (6 tiles) entre o oeste e o centro. Três **baias** no teto
(101, 86 e 114, linha 32) e a **tampa de purga** (101,31).

**B. O encontro** (`LockEncounter`, lógica pura):

| Fase | O que o jogador vê | O que o braço faz |
|---|---|---|
| Dormente | Arena escura, braço apagado estacionado à direita da entrada (98,32), placa no Nó | nada |
| Acordar (2,0 s, câmera no braço) | A escotilha sela atrás do MU-7, faíscas, tremor, o olho âmbar acende; as 12 luzes do trilho ficam âmbar; os acopladores **piscam** com 3 pontos apagados acima | — |
| 0/3 | `[E] SEGURAR PARA ACOPLAR` em cima de cada acoplador | anda atrás do acoplador **mais perto do MU-7** (48 px/s), desce a garra com a placa (0,8 s) e **trava** por 5 s (quem carregava perde a carga), descansa 3 s; SR-3: primeira 3 s depois de acordar, depois a cada 7 s |
| 1/3 | luz 1 da placa do Nó acende | trava 1,2 s (faíscas), corre (120 px/s) e **solda a comporta do piso**: a rota oeste↔centro passa a ser por cima (pulo duplo até a plataforma, pulo duplo pela passarela) |
| 2/3 | luz 2 acende | trava, corre e **arranca a tampa de purga**: a arena inteira vira **vácuo** (estrelas, borda amarela, 4 de Integridade/s, deriva; o Propulsor pilota) |
| 3/3 | luz 3 acende | **desliga**: estremece, olho apaga, garra pende; SR-3 dobram e desligam; comporta abre, vácuo fecha, placa do Nó cai; fala `lock_down` |

**C. Relógio da contenção** (100 s), sem HUD: as 12 luzes do trilho passam de âmbar a vermelho
**das pontas para o centro**; as duas últimas piscam. Para com pausa, diálogo, log e no Modo sem
timer (o braço continua). No zero: **contenção completa** — todos os acopladores travam, comporta
fecha, a arena vira vácuo e a purga tira 25/s até o MU-7 cair.

**D. Morte e retorno**: qualquer morte no encontro congela o braço; ao renascer na doca
`dk_dock_05` (passagem, 96,25, logo acima do poço e longe da SR-3 do vestíbulo) o encontro volta **inteiro** ao começo (SR-3 recolhidas, comportas e
escotilha abertas, acopladores apagados, relógio cheio, braço estacionado, Nó selado). Descer de
novo pelo poço acorda o braço de novo.

**E. Vitória**: `flags.lock_serralheiro_down` salvo (com `SaveManager.save_game`); voltar à arena
encontra o braço desligado e o Nó livre. Religar o Nó segue o fluxo da F62 (cutscene → `dk_restored`
→ hoje a tela de fim; a F64 troca pela volta ao Núcleo).

**F. Arte definitiva** (Codex): SPR-SERRALHEIRO (carro, dois segmentos, garra × 4) e
SPR-LOCK-PROPS (baia × 2, comporta, escotilha, placa, trilho, luz × 2). Faíscas por partículas.

### Não inclui
- Música da luta: `MUS-SERRALHEIRO` registrada como **pendente** (a arena toca a trilha da fase).
- Som próprio do braço: reaproveita `claw_grab`, `door_close`, `door_open`, `terminal_breaker`,
  `power_on`/`power_off`.
- Dano por contato do braço (decisão: ele não ataca; ADR-F63-001).

## 4.1 O encontro no papel

**Rota que vence** (a do roteiro de QA, ~45 s de luta no Normal):
1. Pousa na plataforma, desce ao piso oeste e segura **A1** — o braço vem do centro, à vista, e
   chega a A1 uns 6 s depois de acordar: dá tempo, mas o jogador vê a garra vindo. 1/3 → comporta do piso soldada.
2. Pulo duplo até a plataforma, pulo duplo pela passarela, vai até **A2**: o braço, perto, desce a
   garra e trava A2 (a carga some). É a **isca**.
3. Com a garra presa em A2 por 5 s, corre pela passarela, cai no degrau e segura **A3** no estrado.
   2/3 → purga: vácuo na arena inteira.
4. Sai do estrado para o degrau, empurra-se para cima no vácuo, pilota para baixo até a passarela
   (o braço trava A2 de novo enquanto isso) e **segura antes** de a placa levantar: a janela é
   descanso 3 s + aviso 0,8 s > carga 3 s.

**Por que a solução ingênua falha**: ficar segurando o acoplador mais perto com o braço por perto
perde a carga (0,8 s de aviso, trava 5 s); ir pelo piso depois do 1º acoplador bate na comporta;
demorar no vácuo custa Integridade e relógio; ignorar as SR-3 joga o MU-7 para fora do acoplador
(o Feixe as desliga por 4 s).

## 5. Critérios de aceite

- [x] Descer pelo poço sela a escotilha e acorda o braço; leitura em 1 s (olho âmbar, acopladores piscando, `[E] SEGURAR PARA ACOPLAR`)
- [x] Segurar 3 s alimenta o acoplador; soltar devolve a carga aos poucos; trava do braço zera a carga
- [x] O braço persegue o acoplador mais perto do MU-7, avisa (0,8 s), trava (5 s), descansa (3 s); não fere por contato
- [x] 1º acoplador solda a comporta do piso; 2º abre a arena para o vácuo; 3º desliga o braço
- [x] SR-3 de 3 baias, 7 s − 1,25 s por acoplador, no máximo 3; o Feixe as desliga
- [x] Relógio de 100 s só no cenário (12 luzes); zero = contenção completa e purga; para no Modo sem timer
- [x] Morrer reinicia o encontro inteiro e limpo, com o MU-7 na doca do vestíbulo
- [x] Vitória: braço desligado (não explode), SR-3 desligadas, Nó liberado, fala de marco, vitória salva
- [x] HUD com os mesmos elementos; terminal mudo; ÓRBITA fala só no marco da vitória
- [x] Arte definitiva registrada no ASSETS; MUS-SERRALHEIRO pendente
- [x] Portões do `/CLAUDE.md` §6 verdes; sem comentários; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/lock_encounter.gd      class_name LockEncounter — máquina de estados pura (fases, braço,
                                    relógio, acopladores, ritmo de SR-3, luzes, reset)
scenes/bosses/serralheiro.tscn (+gd) class_name Serralheiro — monta trilho, luzes, baias, braço
                                    (cinemática de 2 segmentos + haste), comporta, escotilha, vácuo da
                                    purga, gatilho, placa do Nó; aplica os eventos da lógica
scenes/world/lock_gate.tscn (+gd)   class_name LockGate — comporta/escotilha soldável (StaticBody2D)
scenes/world/coupler.gd             + soquete Interactable, "armado" (pisca), carga com 3 pontos, is_held()
scripts/core/level_builder.gd       + legenda `K` (o Serralheiro)
```
- O Serralheiro é a entidade `K` em (98,32) com os parâmetros no `docks.json`
  (`couplers`, `node`, `arena`, `trigger`, `rail`, `gate`, `hatch`, `vent`, `bays`).
- Caminho fixo para QA: `Docks/Entities/Serralheiro` (`phase_name`, `powered_count`, `time_left`,
  `alive_spawns`, `is_gate_closed`, `is_entry_sealed`, `is_vented`, `is_node_unlocked`,
  `is_coupler_sealed(id)`, `is_coupler_powered(id)`).
- **Câmera**: dentro da arena o limite de baixo vai para o piso (+8 px) e o da esquerda para a parede
  oeste, para o trilho aparecer com o MU-7 no chão (`set_camera_limits` do MU-7; volta ao normal ao
  sair ou no reset).
- **Ordem de desenho**: braço com `z_index` negativo, acoplador abaixo da garra, MU-7 por cima de tudo.

### Autoloads / sinais do EventBus
- Nenhum sinal novo. Escuta `player_died` (congela) e `player_respawned` (reinicia).
- `GameState.flags["lock_serralheiro_down"]`; relógio usa `GameState.is_timer_frozen()`; purga usa
  `GameState.apply_damage_over_time` (dificuldade aplicada num lugar só).

### Dados (`data/`)
- `levels/docks.{txt,json}`: arena nova, `K`, acopladores movidos (A2 e A3), lâmpada oeste movida.
- `dialogue/docks.json`: `lock_down` (bloqueante, uma vez, 3 linhas).
- Totais de logs/dados **inalterados** (10/10/5).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| SPR-SERRALHEIRO | carro, segmentos e garra do braço | `assets/placeholder/sprites/bosses/*` |
| SPR-LOCK-PROPS | baia, comporta, escotilha, placa, trilho, luz | `assets/placeholder/sprites/world/lock_*.png` |
| SPR-COUPLER | acoplador (F62), agora com soquete e pontos de carga | — |
| MUS-SERRALHEIRO | trilha da luta | **pendente** (toca a da fase) |

## 8. 🧑 Ação humana

Nenhuma que bloqueie. Pendente: a faixa `MUS-SERRALHEIRO`.

## 9. Plano de execução

- [x] **Passo 1** — GDD-P + AJ-054..056 → `Balance`
- [x] **Passo 2** — Arte por IA (2 folhas × 2 variações) em paralelo com a lógica
- [x] **Passo 3** — `LockEncounter` + testes; `LockGate`; acoplador com soquete; `Serralheiro`
- [x] **Passo 4** — Arena no ASCII/JSON, fala de marco, testes de alcançabilidade por estado
- [x] **Passo 5** — QA com marcos (luta inteira, morte e retorno, rota da F62 inteira), portões, docs

## 10. Verificação

- **Testes:** `tests/test_lock_encounter.gd` (18: dormente, acordar, carga e decaimento, perseguição
  do mais próximo, trava rouba a carga, janela do último acoplador, estágios comporta/purga,
  vitória, contenção, relógio congelado, ritmo e teto de SR-3, morte/reset limpos, luzes das pontas
  para o centro, vitória salva); `tests/test_level_lock.gd` (7: o `K` e os parâmetros batem com o
  mapa; acopladores alcançáveis com a arena aberta, com a comporta soldada e em vácuo; de cada
  acoplador aos outros com a comporta fechada; a comporta corta a rota do piso sem pulo duplo; o Nó
  pede pulo duplo e não há volta ao vestíbulo); `test_level_docks`, `test_level_reachability`,
  `test_gdd_parity`, `test_placeholders`.
- **Smoke:** `scenes/bosses/serralheiro.tscn`, `scenes/world/lock_gate.tscn` em `tests/scenes.txt`.
- **Roteiros:** `tests/qa/f63_serralheiro.json` (gerador `tests/qa/gen/f63_serralheiro.py` + luta em
  `tests/qa/gen/f63_fight.py`), `tests/qa/f63_serralheiro_morte.json`, e `tests/qa/f62_docks.json`
  agora passa pela luta (mesma `fight()`).
- **Playtest humano:** a isca (atrair a garra e correr) é legível sem texto? O relógio nas luzes do
  trilho se percebe? O último acoplador no vácuo é tenso mas justo?

## 11. ADRs locais

### ADR-F63-001 — O braço não fere por contato
- **Contexto:** o GDD diz que ele "não ataca diretamente".
- **Decisão:** sem hitbox no braço. O perigo é ficar trancado (perder a carga e a rota), as SR-3, o
  vácuo e o relógio.
- **Consequências:** a garra pode passar por cima do MU-7 sem punir; a pressão vem do ritmo.
- **Data:** 2026-11-21.

### ADR-F63-002 — Segurar o acoplador, não apertar uma vez
- **Contexto:** "alimentar enquanto ele fecha o setor" precisa deixar o MU-7 vulnerável no lugar.
- **Decisão:** `interagir` arma o soquete; a carga só sobe com a tecla **segurada**, de pé no
  acoplador e com o MU-7 mirando o soquete (`interaction_target`). O `mu7.gd` não muda: o acoplador
  lê `Input.is_action_pressed` e a distância.
- **Data:** 2026-11-21.

### ADR-F63-003 — A lógica do encontro é pura e emite eventos
- **Contexto:** estado reentrante (morrer no meio) já quebrou falas e timers do jogo.
- **Decisão:** `LockEncounter` guarda tudo (fase, braço, relógio, cargas, travas, SR-3) e devolve
  eventos; a cena só desenha. `reset()` restaura do zero e o teste confere campo a campo.
- **Data:** 2026-11-21.

### ADR-F63-004 — O teto da antessala desce duas linhas
- **Contexto:** a arena da F62 tinha 15 linhas (240 px) e a tela 216: com o MU-7 no chão o trilho
  ficava fora da câmera e o braço sumia.
- **Decisão:** arena em y 32–44 (13 linhas), poço até a linha 31; dentro dela o limite de baixo da
  câmera é o piso. O gancho da F62 (x 84–117, y 30–44) passa a valer com o teto em 31.
- **Data:** 2026-11-21.

### ADR-F63-005 — O Nó fica atrás do chefe
- **Contexto:** o estrado do Nó é alcançável com pulo duplo durante a luta.
- **Decisão:** placa soldada sobre o Nó (com 3 luzes que acendem por acoplador) e o terminal
  desabilitado até a vitória; a placa cai quando o braço desliga.
- **Data:** 2026-11-21.

### ADR-F63-006 — O Modo sem timer também para a contenção
- **Contexto:** o relógio do encontro é tempo, e o Modo sem timer é acessibilidade.
- **Decisão:** o relógio só anda quando `GameState.is_timer_frozen()` é falso (pausa, diálogo, log,
  cutscene, Modo sem timer). O braço e as SR-3 seguem.
- **Data:** 2026-11-21.

## 12. Log de evolução

### 2026-11-21 — Feature criada, planejada e construída (agente de chefe, worktree)
- **Quem**: agente de chefe F63.
- **O que**:
  - **Números**: GDD-P `LOCK_*` (19) + AJ-054 (regras), AJ-055 (relógio/purga/reinício), AJ-056
    (vitória que desliga) → `Balance`. Descanso do braço 2,5 → **3 s** no QA (a janela do último
    acoplador era de 0,3 s e o vácuo a fazia falhar).
  - **Sistemas**: `LockEncounter`, `Serralheiro`, `LockGate`, acoplador com soquete/carga/pisca,
    legenda `K`.
  - **Arena**: teto em 31, plataforma de pouso, passarela, degrau colado ao estrado (o vão de 1 tile
    em x 110 derrubava o MU-7), A2 e A3 movidos, lâmpada oeste na parede. O braço estacionava no
    leste (116) e acordava fora da tela: passou para 103, à vista do pouso, e os acopladores e as
    luzes do trilho acendem já no acordar.
  - **Arte por IA**: 2 folhas × 2 variações, 1ª de cada; fatiador próprio (garra alinhada pelo topo).
- **QA** (todos com marcos, lidos):
  - `f63_serralheiro` — **25/25** em duas rodadas: braço dormente → escotilha selada → acordando →
    A1 → comporta soldada → passarela → A2 travado (isca) → A3 → vácuo → A2 no vácuo → desligado,
    Nó liberado, vácuo fechado, comporta aberta → Nó → cutscene → tela de fim.
  - `f63_serralheiro_morte` — **23/23**: A1 → comporta → relógio forçado a 0,5 s → contenção completa
    (vácuo, A2 trancado) → purga mata → renasce em `dk_dock_05` → encontro dormente, 0 acopladores,
    comporta/escotilha abertas, sem vácuo, 0 SR-3, relógio 100, Nó selado → desce de novo → acorda
    → A1 carrega de novo.
  - `f62_docks` — **41/41**: a rota inteira da fase agora passa pela luta (mesma `fight()`).
  - `f62_tour` 4/4 e `f62_hub_docks` 9/9 continuam verdes.
  - Capturas: braço soldando a comporta com faíscas; garra com a placa travando A2
    ("ACOPLADOR TRANCADO"); arena em vácuo com estrelas e borda amarela; purga com as 12 luzes
    vermelhas; braço apagado e placa do Nó caída; fala `lock_down`.
- **Checklist §4.7**: (1) nenhum texto explica a solução (só o prompt do acoplador) — sim;
  (2) ÓRBITA só no marco da vitória — sim; (3) trocas obrigatórias: rota muda duas vezes e a ingênua
  falha — sim; (4) fragmentos e segredo da fase seguem os da F62 — sim; (5) arena escura, o braço é
  a luz que anda — sim; (6) silhuetas: braço, baia, comporta, acoplador, placa do Nó — sim; (7) HUD
  igual — sim; (8) roteiros até o fim — sim; (9) cutscene de religamento com o que mostrar (F62) — sim.
- **Portões**: ver o fim do log da entrega.
- **Pendências**: `MUS-SERRALHEIRO`; a F64 troca o fim das Docas pela volta ao Núcleo (os roteiros
  `f63_serralheiro` e `f62_docks` esperam `demo_end.tscn` e precisam trocar o marco final); o gancho
  da F62 (§4.3 do F62) ainda descrevia a arena antiga (teto em 29) — atualizado na integração.

### 2026-11-21 — Integração sobre a main com F66, F69 e F68/F32 (agente de integração)
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: o diff da F63 (feito sobre
  `7cef2a5`) aplicado com `git apply -3` sobre `99317ee`.
- **Conflitos textuais** (mantidos os dois lados): skills `godot-qa` e `level-design` (lições F66/F71/
  F69 + F63), `README` (créditos: linha do Codex com o Serralheiro + sala de comando e placa),
  `ENTREGAS` (Mini-boss `[x]` com link; Fim alternativo e Nível `[x]` da main), GDD-P e `Balance`
  (`LOCK_*` antes dos números da F66, na ordem dos AJ), legenda do `test_level_parser`
  (`...B...` da F69 + `K`).
- **Conflitos semânticos**: `K` é letra única no `LEGEND` (`test_no_legend_letter_is_declared_twice`
  verde); `DEMO_SEQUENCES` 29→30 (`lock_down`); o acoplador com soquete não é usado pela F69 nem
  pela F68 (a sobrecarga ROOT é API de terminal); alcançabilidade com perfil de habilidades e o `z`
  da F68 continuam verdes com a arena nova.
- **Renascimento justo**: `dk_dock_05` passou de (114,25), no fosso da SR-3 do vestíbulo, para a
  passagem (96,25). Antes, cada tentativa contra o Serralheiro começava com a SR-3 batendo no MU-7.
  O `f63_serralheiro_morte` agora espera o renascimento em 96,25.
- **4ª Placa da F69**: `plate_dk_01` (32,40) atrás da porta ROOT `dk_root_door` (35,40) no hangar
  (ver F69).
- **QA com marcos (capturas lidas)**: `f63_serralheiro` 25/25 (garra trancando A2 com
  `ACOPLADOR TRANCADO`; braço apagado com a placa do Nó caída; tela de fim), `f63_serralheiro_morte`
  23/23 (renasce na doca da passagem, sem SR-3 por perto, 3 células), `f62_docks` 41/41,
  `f62_tour` 4/4, `f62_hub_docks` 9/9, `f69_c_comporta_reator` 6/6, `f68_hazards` 18/18,
  `f69_f_placa_docas` 9/9 (novo).
- **Armadilha**: `tools/qa.sh --scene=<fase>` carrega a fase **antes** do `new_game`/`from_dict` do
  roteiro; a fala de entrada começa com o estado zerado e continua bloqueando depois que o roteiro
  recarrega a cena (o `f69_f` ficou parado na fala `dk_enter`). Roteiro que monta o save roda sem
  `--scene`.
- **Pendências**: `MUS-SERRALHEIRO`; a F64 troca o fim das Docas pela volta ao Núcleo (os roteiros
  `f63_serralheiro` e `f62_docks` esperam `demo_end.tscn`).

### 2026-11-21 — Fim das Docas pela volta ao Núcleo (integração da F64)
- `f63_serralheiro` e `f62_docks` regenerados pelos geradores: o último marco agora é
  `core_hub.tscn` (25/25 e 41/41); `f63_serralheiro_morte` 23/23 sem mudança.

### 2026-11-21 — Revisão de design: o Serralheiro acorda à vista (grupo B1)
- **P1 — acordar fora da tela:** em (103,32) o braço ficava a 12–13 tiles do pouso (91,40) e a câmera
  centrada no MU-7 mostra ±12: no acordar só um pedaço do braço aparecia na borda e o carro e o olho
  ficavam sob o `OBJETIVO`. Agora o `K` está em **(98,32)**, `LOCK_WAKE_TIME` 1,5 → **2,0 s** (AJ-078)
  e, no acordar, uma `BossFocusCamera` (`scenes/bosses/boss_focus_camera.gd`, câmera temporária como a
  da vitória do ARGOS) desliza 0,4 s até o ponto entre o MU-7 e o braço com o carro a 48 px do topo
  (`ArenaFraming.focus_between`), segura 1,2 s e devolve ao MU-7 (o tremor do chassi segue na câmera
  temporária). Morrer no meio solta a câmera (`_release_wake_camera` no reset).
- **P8 — carro sob a HUD na luta:** `TROLLEY_DROP` 22 → 30 e enquadramento por altura do pé
  (`framing_floor: 41` no JSON): no piso principal e nas passarelas o limite de baixo da câmera fica em
  696 px e o carro aparece a 42 px do topo; quando o MU-7 cai no fosso o limite desliza (240 px/s) até
  o fundo da arena. Para caber, o fosso perdeu uma linha (piso em y 44, arena `[84, 32, 34, 12]`,
  comporta `[95, 39, 1, 5]`, acoplador 1 em (87,43)).
- **Testes:** `tests/test_boss_framing.gd` (estacionado a ≤ 8 tiles do pouso, despertar com carro e
  MU-7 inteiros abaixo da HUD, quadro da luta), `test_level_lock.gd` com a arena nova.
- **QA:** `review_design_serralheiro_wake` agora tem gerador (`tests/qa/gen/review_design_serralheiro_wake.py`)
  e marcos `camera_no_braco`, `braco_inteiro_abaixo_da_hud`, `olho_ainda_no_quadro`,
  `camera_volta_ao_mu7`, `carro_abaixo_da_hud_na_luta` (`Serralheiro.is_boss_in_frame(40)`);
  `f63_serralheiro` 25/25 e `f63_serralheiro_morte` 23/23 regenerados (pouso no fosso em (87,43); o
  `acordou_de_novo` espera os 2,0 s).

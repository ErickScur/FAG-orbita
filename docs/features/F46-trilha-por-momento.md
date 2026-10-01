---
id: F46
title: Trilha por momento
status: done
scope: demo
block: 6
priority: P1
rubric: ["Música (trilha sonora)", "Efeitos visuais/sonoros"]
depends_on: ["F04", "F10", "F14", "F42"]
unblocks: []
estimate: 2h
last_updated: 2026-09-20
---

# F46 — Trilha por momento

## 1. Contexto e objetivo

A demo tinha três trilhas em loop — `menu`, `core`, `greenhouse` — e mais nada. Os dois
momentos mais dramáticos do jogo (perder o chassi e perder a órbita) eram os **únicos em
silêncio**: as telas chamavam `AudioManager.stop_music()` e cortavam o som no exato instante em
que o jogador precisava sentir alguma coisa. O religamento de um setor, a única recompensa
alegre da demo, tocava com a trilha de exploração por baixo, como se nada tivesse acontecido.

Esta feature cria os **quatro encaixes de música que faltavam** e o mecanismo mínimo para eles
existirem: uma faixa **one-shot** (toca uma vez e devolve o lugar para a trilha anterior) e uma
**camada de tensão** em loop que sobe por cima da trilha da fase enquanto o reator está crítico.
Com placeholders gerados, tudo já funciona; quando o humano soltar os `.ogg` definitivos no
caminho final, nenhuma linha de código muda.

Serve aos pilares **AUSÊNCIA** e **URGÊNCIA** ([GDD pilares](../design/GDD.md#gdd-pilares)): o
silêncio deixa de ser acidente e a pressão do reator passa a ser audível, não só um número
piscando no HUD.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 Música](../design/GDD.md#gdd-2-9-musica) · [GDD-2.5 Timer do reator](../design/GDD.md#gdd-2-5-timer) · [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas)
- **Parâmetros:** `Balance.REACTOR_CRITICAL` (limiar do estado crítico) · `Balance.MUSIC_FADE_TIME` (crossfade das trilhas de fase) ([GDD-P](../design/GDD.md#gdd-p))
- **Jornada:** o religamento do setor é o momento de recompensa; a perda de órbita é o fim sem volta ([JORNADA](../design/JORNADA-DO-HEROI.md))
- **ADRs:** [ADR-005](../DECISIONS.md#adr-005) (placeholder-first) · ADR-F46-001 e ADR-F46-002 abaixo

## 3. Critério de avaliação atendido

- **Música (trilha sonora)** ([ENTREGAS §3.1](../ENTREGAS.md#rubrica)): o avaliador ouve trilhas
  diferentes em momentos diferentes — não uma única faixa em loop do começo ao fim. Morrer,
  religar a Estufa e deixar o reator cair têm cada um a sua música.
- **Efeitos visuais/sonoros**: a camada de tensão entra sozinha quando a estabilidade cruza
  `Balance.REACTOR_CRITICAL` e sai quando ela sobe de novo, sem o jogador apertar nada.

## 4. Escopo

### Inclui
- Quatro ids novos em `AudioManager.MUSIC`: `chassis_lost`, `game_over`, `sector_restored`, `reactor_critical`.
- API de **one-shot** no `AudioManager` (`play_one_shot`, `stop_one_shot`, `is_one_shot_playing`, `current_one_shot`).
- API de **camada** no `AudioManager` (`play_layer`, `stop_layer`, `current_layer`) num player dedicado no bus `Music`.
- Disparo automático por `EventBus` (`sector_restored`, `reactor_critical`, `game_over`) dentro do próprio `AudioManager`.
- Disparo do `chassis_lost` na tela CHASSI PERDIDO e do `game_over` na tela PERDA DE ÓRBITA.
- Placeholders WAV sintetizados dos quatro momentos em `tools/make_audio_placeholders.gd`.
- Contrato dos arquivos definitivos registrado no [`ASSETS.md`](../ASSETS.md) (MUS-CHASSIS, MUS-GAMEOVER, MUS-SECTOR, MUS-CRITICAL).

### Não inclui
- Música adaptativa de verdade (stems por intensidade, transição em compasso, sidechain). Isso é
  feature da entrega final — ver "o que ficou de fora" no ADR-F46-002.
- Bus novo no layout de áudio: a camada divide o bus `Music` com a trilha da fase.
- Mudança na tela FIM DA DEMO, que continua tocando `menu` de propósito.
- Trilha nova para o SR-3, para perseguição ou para o tutorial.

## 5. Critérios de aceite

- [x] Morrer com backup toca `chassis_lost` uma vez e, ao acabar, a trilha da fase volta sozinha.
- [x] Chegar a 0% de estabilidade toca `game_over` uma vez e termina em silêncio (não volta para a fase).
- [x] Religar um setor toca `sector_restored` por cima da cutscene e devolve a trilha da fase no fim.
- [x] Entrar em estado crítico sobe `reactor_critical` em loop **sem** cortar a trilha da fase; sair do estado crítico desce a camada e a trilha da fase continua intacta.
- [x] Nenhuma faixa one-shot fica em loop.
- [x] Tudo passa pelo bus `Music`, então os sliders das Opções mexem nos quatro momentos.
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
autoload/audio_manager.gd        one-shot, camada de tensão e escuta do EventBus
scenes/ui/chassis_lost.gd        dispara o one-shot chassis_lost em play()
scenes/ui/game_over.gd           dispara o one-shot game_over (antes chamava stop_music)
tools/make_audio_placeholders.gd gera os quatro WAV placeholder
tests/test_audio_moments.gd      suíte da feature
tests/qa/scenes/music_probe.tscn (+ .gd)  cena de prova que mostra trilha/momento/camada
```

### Contrato novo do `AudioManager`

| Método | O que faz |
|---|---|
| `play_one_shot(id, resume_previous := true)` | Toca `id` **uma vez**, sem loop, assumindo o lugar da trilha atual. Quando termina, volta para a trilha que estava tocando; com `resume_previous = false`, termina em silêncio. Chamar duas vezes com o mesmo id não reinicia a faixa. Um segundo one-shot por cima do primeiro **mantém** a trilha de retorno original. |
| `stop_one_shot(fade := -1.0)` | Corta o momento antes da hora e já devolve a trilha de retorno (ou o silêncio). |
| `is_one_shot_playing() -> bool` | Verdadeiro enquanto um momento toca. |
| `current_one_shot() -> StringName` | Id do momento em curso, ou `&""`. |
| `play_layer(id, fade := -1.0)` | Sobe uma faixa em **loop** num player dedicado do bus `Music`, **por cima** da trilha da fase, com fade de `LAYER_FADE_TIME` até `LAYER_GAIN_DB`. |
| `stop_layer(fade := -1.0)` | Desce a camada e para o player. |
| `current_layer() -> StringName` | Id da camada ativa, ou `&""`. |

Semântica que mudou nos métodos que já existiam:

- `current_music()` devolve o id do **one-shot** enquanto ele toca, e volta a devolver o id da
  trilha da fase quando ele termina.
- `play_music(id)` cancela o one-shot em curso (a fase manda mais que o momento) e **não** mexe
  na camada de tensão.
- `stop_music(fade)` agora silencia os três: trilha, momento e camada.
- `stop_all()` limpa trilha, momento e camada.
- `MUSIC_LOOPING` e `MUSIC_ONE_SHOT` particionam `MUSIC`: todo id está em exatamente uma das
  duas listas, e é isso que decide se o stream é carregado com loop ligado ou desligado.

### Autoloads / sinais do EventBus

Nenhum sinal novo. O `AudioManager` passa a escutar três sinais que já existiam:

| Sinal | Reação |
|---|---|
| `EventBus.sector_restored(sector_id)` | `play_one_shot(&"sector_restored")` — devolve a trilha da fase no fim |
| `EventBus.reactor_critical(active)` | `play_layer(&"reactor_critical")` / `stop_layer()` |
| `EventBus.game_over(reason)` | `play_one_shot(&"game_over", false)` — termina em silêncio |

Os outros dois disparos ficam na cena, porque só ela sabe a hora certa:

| Lugar | Reação |
|---|---|
| `scenes/ui/chassis_lost.gd::play()` | `play_one_shot(&"chassis_lost")` — a guarda de "morte com backup" já é do `SceneManager`, que só monta essa tela com o reator acima de 0% |
| `scenes/ui/game_over.gd::_ready()` | `play_one_shot(&"game_over", false)` — idempotente com o disparo do sinal, cobre a tela aberta por qualquer outro caminho |

### Dados (`data/`)
Nenhum. Os ids das trilhas moram em `AudioManager.MUSIC`.

### Input actions / camadas de colisão
Nenhuma.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [MUS-CHASSIS](../ASSETS.md#mus-chassis) | Tela CHASSI PERDIDO (one-shot, 6–10 s) | `assets/placeholder/audio/music/chassis_lost.wav` |
| [MUS-GAMEOVER](../ASSETS.md#mus-gameover) | Tela PERDA DE ÓRBITA (one-shot, 10–15 s) | `assets/placeholder/audio/music/game_over.wav` |
| [MUS-SECTOR](../ASSETS.md#mus-sector) | Cutscene de religamento (one-shot, 15–20 s) | `assets/placeholder/audio/music/sector_restored.wav` |
| [MUS-CRITICAL](../ASSETS.md#mus-critical) | Camada de tensão do reator (loop, 20–30 s) | `assets/placeholder/audio/music/reactor_critical.wav` |

### Contrato dos arquivos definitivos

- **Caminho final:** `assets/audio/music/<id>.ogg`, com `<id>` exatamente `chassis_lost`,
  `game_over`, `sector_restored` ou `reactor_critical`. Basta soltar o arquivo ali: o
  `AudioManager` prefere o caminho final e só cai no placeholder quando ele não existe.
- **Formato:** `.ogg` preferido; `.wav` e `.mp3` também importam no Godot 4 (a resolução tenta as
  três extensões, nessa ordem).
- **Faixas em loop** (`reactor_critical`): começo e fim precisam **casar**, sem fade dentro do
  arquivo. O loop é marcado na importação, não no áudio.
- **Faixas one-shot** (`chassis_lost`, `game_over`, `sector_restored`): **não** levam loop. Podem
  (e devem) ter decaimento natural no fim do arquivo.
- **Duração alvo:** 6–10 s, 10–15 s, 15–20 s e 20–30 s respectivamente — a suíte de testes
  confere que o arquivo que estiver no lugar respeita a faixa.
- **Mixagem:** a camada `reactor_critical` toca **junto** com a trilha da fase, com ganho de
  `LAYER_GAIN_DB` (−6 dB). Ela precisa somar sem competir: pulso e ruído, sem melodia e sem
  acorde que brigue com a tonalidade das outras faixas.

## 8. 🧑 Ação humana

Nenhuma para a feature funcionar — os quatro momentos já tocam com placeholder.

Quando quiser o som definitivo: baixe/gere os quatro arquivos pelos prompts de
[`ASSETS.md`](../ASSETS.md#trilha), salve em `assets/audio/music/<id>.ogg` e rode
`"$GODOT" --headless --path . --import`. Nada mais.

## 9. Plano de execução

- [x] **Passo 1** — Quatro ids em `AudioManager.MUSIC`, partição `MUSIC_LOOPING` / `MUSIC_ONE_SHOT`.
- [x] **Passo 2** — `_load_track`/`_start_track`/`_prepare_stream` extraídos do `play_music` para servirem aos três modos (trilha, momento, camada).
- [x] **Passo 3** — `play_one_shot` / `stop_one_shot` com retorno para a trilha anterior.
- [x] **Passo 4** — Player dedicado `MusicLayer` no bus `Music` e `play_layer` / `stop_layer`.
- [x] **Passo 5** — Escuta de `sector_restored`, `reactor_critical` e `game_over` no `AudioManager`.
- [x] **Passo 6** — `chassis_lost.gd` e `game_over.gd` disparando os seus momentos.
- [x] **Passo 7** — Placeholders dos quatro momentos no gerador.
- [x] **Passo 8** — `tests/test_audio_moments.gd` e cena de prova `music_probe`.
- [x] **Passo 9** — Portões §6 e QA visual.

## 10. Verificação

- **Testes (`tests/test_audio_moments.gd`)** — 20 casos, incluindo:
  - os quatro ids existem, resolvem para um arquivo e estão em exatamente uma das listas de loop;
  - stream de one-shot carrega com `LOOP_DISABLED`, o da camada com `LOOP_FORWARD`;
  - a duração do arquivo que está no lugar respeita a faixa documentada;
  - `core` → `chassis_lost` → fim → `core` (a trilha da fase volta);
  - `greenhouse` → `game_over` → fim → silêncio;
  - um segundo one-shot mantém a trilha de retorno original;
  - camada crítica sobe **sem** trocar `current_music()`, sobrevive a um one-shot e desce sem levar a trilha junto;
  - `stop_music()` silencia trilha, momento e camada;
  - id desconhecido não derruba a trilha da fase;
  - o `AudioManager` está de fato conectado aos três sinais do `EventBus`.
- **Smoke:** `res://tests/qa/scenes/music_probe.tscn` adicionada em `tests/scenes.txt` — 75 cenas, 0 erro.
- **Roteiro godot-qa:** cena `res://tests/qa/scenes/music_probe.tscn` (mostra TRILHA / MOMENTO / CAMADA na tela, porque som não sai em screenshot).
  - `tests/qa/f46_trilha_momentos.json` — estado inicial (`TRILHA: core`), liga o crítico (`CAMADA: reactor_critical` **com** `TRILHA: core` intacta) e religa o setor (`TRILHA: sector_restored`, `MOMENTO: sector_restored`, camada ainda ligada).
  - `tests/qa/f46_morte.json` — morte: tela CHASSI PERDIDO digitando, tela completa e, depois dela fechar, `TRILHA: chassis_lost` ainda tocando até o fim.
  - `tests/qa/f46_perda_de_orbita.json` — tela PERDA DE ÓRBITA montada com a faixa `game_over` no lugar do antigo silêncio.
- **Playtest humano (opcional):** com os `.ogg` definitivos no lugar, ouvir se a camada crítica
  soma com `core` e com `greenhouse` sem brigar de tonalidade — é o único risco que teste não pega.

## 11. ADRs locais

### ADR-F46-001 — One-shot reaproveita os dois players de crossfade

- **Contexto:** o `AudioManager` já tinha `_music_a`/`_music_b` alternando com crossfade. Um
  momento one-shot poderia ganhar um terceiro player e tocar por cima da trilha da fase.
- **Decisão:** o one-shot **toma o lugar** da trilha, usando o mesmo par de players e o mesmo
  crossfade (0,35 s em vez de 1,5 s). O fim da faixa é detectado pelo sinal `finished` do
  player, que só existe porque o stream é carregado com loop desligado.
- **Consequências:** `current_music()` passa a devolver o id do momento enquanto ele toca — o que
  é a leitura natural e é o que os testes conferem. Momento e trilha nunca se sobrepõem, o que
  é desejado: a música de morte não quer a trilha de exploração por baixo. Custo: `play_music`
  precisa cancelar o one-shot explicitamente, senão a fase voltaria por cima do momento.
- **Data:** 2026-09-20

### ADR-F46-002 — Camada de tensão é um player extra, não música adaptativa

- **Contexto:** `reactor_critical` precisa de uma camada que **some** com a trilha da fase, não
  que a substitua. Música adaptativa de verdade (stems sincronizados, transição em compasso,
  ducking por sidechain) exigiria reescrever o `AudioManager` e mudar o layout de buses.
- **Decisão:** um player dedicado (`MusicLayer`) no bus `Music` que toca a faixa em loop com fade
  de 2,5 s até −6 dB, por cima do que estiver tocando. Sem bus novo, sem stems, sem sincronismo.
- **Consequências:** funciona e respeita os sliders das Opções, porque tudo continua no bus
  `Music`. **Ficou de fora** (entrega final): sincronismo de compasso entre camada e trilha,
  ducking automático da trilha quando a camada sobe, variação de intensidade por faixa de
  estabilidade (hoje é liga/desliga no limiar `Balance.REACTOR_CRITICAL`) e camada de perseguição
  do SR-3. O risco real é musical, não técnico: se a faixa definitiva tiver melodia, ela vai
  brigar com a tonalidade de `core`/`greenhouse` — por isso o contrato do asset pede pulso e
  ruído, sem melodia.
- **Data:** 2026-09-20

### ADR-F46-003 — Dois momentos disparam pela cena, dois pelo EventBus

- **Contexto:** `sector_restored`, `reactor_critical` e `game_over` são estados globais e o
  `AudioManager` pode escutá-los direto. `chassis_lost`, não: o `EventBus.player_died` também
  dispara quando o reator chega a 0%, caso em que a tela certa é PERDA DE ÓRBITA, não CHASSI
  PERDIDO — a guarda mora no `SceneManager`.
- **Decisão:** `chassis_lost` dispara em `chassis_lost.gd::play()`, ou seja, exatamente quando a
  tela é montada, herdando a guarda de graça. `game_over` dispara nos dois lugares (sinal e
  tela) porque `play_one_shot` é idempotente para o mesmo id.
- **Consequências:** nenhum sinal novo no `EventBus`, nenhuma duplicação de regra de negócio, e a
  cutscene de religamento (`scenes/fx/sector_cutscene.gd`) não precisou ser tocada.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Feature implementada
- **Quem**: agente D · **O que**: quatro momentos de trilha (`chassis_lost`, `game_over`,
  `sector_restored`, `reactor_critical`), API de one-shot e de camada de tensão no
  `AudioManager`, placeholders gerados, 20 testes novos e três roteiros de QA com cena de prova
  que mostra trilha/momento/camada na tela. · **Próximo passo**: humano soltar os quatro `.ogg`
  definitivos em `assets/audio/music/` (contrato na seção 7); avaliar no `balance.gd` as
  constantes provisórias listadas abaixo.

#### Constantes provisórias pedidas para o `balance.gd`
Hoje moram em `autoload/audio_manager.gd` porque `scripts/core/balance.gd` é do humano:

| Nome sugerido | Valor | Para quê |
|---|---|---|
| `MUSIC_ONE_SHOT_FADE_TIME` | `0.35` | Crossfade de entrada/saída dos momentos (o `MUSIC_FADE_TIME` de 1,5 s é lento demais para uma morte) |
| `MUSIC_LAYER_FADE_TIME` | `2.5` | Subida e descida da camada de tensão do reator |
| `MUSIC_LAYER_GAIN_DB` | `-6.0` | Ganho da camada de tensão por cima da trilha da fase |

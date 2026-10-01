---
id: F04
title: Áudio & ajuste de volume
status: done
scope: demo
block: 0
priority: P0
rubric: ["Ajuste de volume (dentro do jogo)", "Música (trilha sonora)", "Efeitos visuais/sonoros"]
depends_on: ["F02", "F05"]
unblocks: ["F07", "F08", "F09", "F28", "F29"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F04 — Áudio & ajuste de volume

## 1. Contexto e objetivo

O som carrega metade do tom do ÓRBITA: drone frio no menu, clique de disjuntor no terminal, alarme do reator. Esta feature cria o layout de buses (`Master`, `Music`, `SFX`, `Voice`) e implementa o autoload `AudioManager`: música com crossfade, SFX por nome com pool de players e aplicação dos volumes vindos de `Settings`. A tela de opções ([F08](F08-opcoes-dificuldade.md)) só chama a API daqui.

Serve ao pilar **AUSÊNCIA** ([GDD pilares](../design/GDD.md#gdd-pilares)): silêncio e ruído de rádio como presença. O jogador ouve em todas as telas e fases; o avaliador mexe nos sliders e ouve a diferença na hora.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 Música](../design/GDD.md#gdd-2-9-musica) · [GDD-2.9 Efeitos sonoros](../design/GDD.md#gdd-2-9-sfx) · [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (menu "sem música, só ruído de rádio"; opções: volume de música, efeitos, voz)
- **Parâmetros:** nenhum da GDD-P atual; `Balance.MUSIC_FADE_TIME` proposto no ADR-F04-001
- **ADRs:** [ADR-005](../DECISIONS.md#adr-005) (áudio placeholder = beep gerado)

## 3. Critério de avaliação atendido

- **Ajuste de volume (dentro do jogo)** ([ENTREGAS §3.1](../ENTREGAS.md#rubrica)): esta feature fornece o motor; a UI de sliders (menu e pause) é da F08/F09. O avaliador arrasta "Música" e o volume muda imediatamente.
- **Música (trilha sonora)**: trilha do menu (MUS-MENU) toca a partir daqui; trilhas das fases entram na F28/F29 com `AudioManager.play_music`.
- **Efeitos visuais/sonoros**: todos os SFX da demo passam por `play_sfx`.

## 4. Escopo

### Inclui
- `default_bus_layout.tres` na raiz com buses `Master`, `Music`, `SFX`, `Voice` (os três últimos enviando para `Master`) e registro em `project.godot` (`audio/buses/default_bus_layout`).
- `AudioManager` completo: 2 `AudioStreamPlayer` de música (crossfade), pool de 8 `AudioStreamPlayer` de SFX, 1 `AudioStreamPlayer` de voz.
- Resolução de arquivos por id com fallback para placeholder via `AssetResolver` ([F05](F05-pipeline-assets-placeholders.md)).
- `set_bus_volume` / `apply_volumes` ligados a `Settings`.
- `scripts/core/audio_math.gd` (conversão linear↔dB, mudo em 0) + teste.
- SFX de navegação de UI (`ui_move`, `ui_confirm`, `ui_back`) disponíveis para F07–F10.

### Não inclui
- UI de sliders ([F08](F08-opcoes-dificuldade.md)).
- Música adaptativa por camadas e percussão em reator < 25% (F50 — Final). O alarme do reator é SFX em loop da [F14](F14-estabilidade-reator.md).
- Áudio posicional (`AudioStreamPlayer2D`) — entidades que quiserem podem usar direto no bus `SFX`, fora do AudioManager.
- Low-pass em áreas sem gravidade (Final, Docas).
- Busca/integração dos arquivos definitivos (pedido ao humano pelo `ASSETS.md`; integração quando chegarem).

## 5. Critérios de aceite

- [x] `AudioServer.get_bus_index(&"Music")`, `&"SFX"`, `&"Voice"` ≥ 1 ao rodar o jogo.
- [x] `AudioManager.play_music(&"menu")` toca `assets/audio/music/menu.ogg` se existir, senão `assets/placeholder/audio/music/menu.wav`, em loop, no bus `Music`.
- [x] `play_music` com outra trilha faz crossfade em `Balance.MUSIC_FADE_TIME` (a antiga desce até silêncio e para; a nova sobe). Chamar com a mesma trilha que já toca não reinicia.
- [x] `play_sfx(&"ui_confirm")` toca no bus `SFX`; até 8 sons simultâneos; o 9º reutiliza o player mais antigo. Id inexistente → `push_warning` uma única vez por id, sem erro.
- [x] `set_bus_volume(&"Music", 0.0)` silencia (bus mudo); `0.5` ≈ −6 dB; o valor é gravado em `Settings.music_volume`.
- [x] Ao iniciar, `apply_volumes()` aplica os 4 volumes salvos em `user://settings.cfg`.
- [x] `AudioManager` tem `process_mode = PROCESS_MODE_ALWAYS` (música continua no pause).
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
default_bus_layout.tres
autoload/audio_manager.gd       (preenche o esqueleto da F02)
scripts/core/audio_math.gd      class_name AudioMath
```

### `default_bus_layout.tres`
`AudioBusLayout` com `bus/0` Master, `bus/1` Music (`send = "Master"`), `bus/2` SFX, `bus/3` Voice. Sem efeitos por ora. `project.godot`: `[audio] buses/default_bus_layout="res://default_bus_layout.tres"`.

### `AudioManager`
```gdscript
extends Node

const MUSIC := {
	&"menu": "res://assets/audio/music/menu.ogg",
	&"core": "res://assets/audio/music/core.ogg",
	&"greenhouse": "res://assets/audio/music/greenhouse.ogg",
}
const SFX_DIR := "res://assets/audio/sfx/"
const SFX_POOL_SIZE := 8

func play_music(id: StringName, fade: float = -1.0) -> void
func stop_music(fade: float = -1.0) -> void
func play_sfx(sfx_name: StringName) -> void
func play_voice(stream: AudioStream) -> void
func stop_voice() -> void
func set_bus_volume(bus: StringName, linear: float) -> void
func apply_volumes() -> void
func current_music() -> StringName
```
- `fade < 0` → usa `Balance.MUSIC_FADE_TIME`.
- Música: `_music_a`/`_music_b` alternam; tween de `volume_db` de `AudioMath.SILENT_DB` a 0. Loop: `AudioStreamOggVorbis.loop = true`; `AudioStreamWAV.loop_mode = LOOP_FORWARD` com `loop_end = data.size() / 2` (mono 16 bit).
- SFX: busca `SFX_DIR + name + ".ogg"`, depois `.wav`, via `AssetResolver.audio()`; cache em `Dictionary`.
- `set_bus_volume`: `AudioServer.set_bus_volume_db(idx, AudioMath.linear_to_db_safe(linear))`, `set_bus_mute(idx, linear <= 0.001)`, grava no campo correspondente de `Settings` (`master_volume`, `music_volume`, `sfx_volume`, `voice_volume`). Não salva em disco (a F08 salva ao fechar a tela).
- `_ready()`: cria os players por código, `apply_volumes()`.

### `AudioMath`
```gdscript
class_name AudioMath
extends RefCounted

const SILENT_DB := -80.0

static func linear_to_db_safe(linear: float) -> float:
	if linear <= 0.001:
		return SILENT_DB
	return linear_to_db(clampf(linear, 0.0, 1.0))
```

### Autoloads / sinais do EventBus
- Não escuta sinais nesta feature. Features donas dos eventos chamam `AudioManager.play_sfx(...)` (ex.: F16 `interact`, F17 `terminal_breaker`).

### Dados (`data/`)
- Nenhum; ids de música são constantes (não é texto do jogador).

### Input actions / camadas de colisão
- Nenhuma.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [MUS-MENU](../ASSETS.md#mus-menu) | Trilha `&"menu"` | Ruído branco filtrado + drone 55 Hz, 4 s em loop, gerado pela F05 |
| [MUS-CORE](../ASSETS.md#mus-core) | Trilha `&"core"` (usada na F28) | Drone 65 Hz, 4 s loop |
| [MUS-GREENHOUSE](../ASSETS.md#mus-greenhouse) | Trilha `&"greenhouse"` (F29) | Drone 73 Hz + sino, 4 s loop |
| [SFX-PACK](../ASSETS.md#sfx-pack) | Todos os `play_sfx` | Beeps senoidais de 0,1–0,3 s, frequência distinta por nome |

## 8. 🧑 Ação humana

Nenhuma. (Os arquivos definitivos de música/SFX são pedidos ao humano pela lista priorizada do `ASSETS.md` ao fim do Dia 1, fora desta feature; a integração é trocar o arquivo no caminho final.)

## 9. Plano de execução

- [x] **Passo 1** — `tests/test_audio_math.gd` (falha) → `scripts/core/audio_math.gd`.
- [x] **Passo 2** — `default_bus_layout.tres` + linha no `project.godot`; `--import`.
- [x] **Passo 3** — Propor `MUSIC_FADE_TIME` na GDD-P + Ajustes; adicionar a `balance.gd`.
- [x] **Passo 4** — Implementar `audio_manager.gd`.
- [x] **Passo 5** — Cena de QA `tests/qa/scenes/audio_probe.tscn` (Control com 4 `Label`s mostrando `AudioServer.get_bus_volume_db` e `current_music()`; script chama `play_music(&"menu")` no `_ready` e, ao receber `ui_accept`, `play_sfx(&"ui_confirm")`; `ui_left/ui_right` alteram o volume de Music em 0,25).
- [ ] **Passo 6** — Portões, QA, commit `feat(F04): buses de áudio e AudioManager com crossfade e volumes`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** `test_audio_math.gd` — `linear_to_db_safe(0.0) == SILENT_DB`, `linear_to_db_safe(1.0) == 0.0`, `linear_to_db_safe(0.5)` ≈ −6,02 (±0,05). `test_audio_buses.gd` — bus layout tem os 4 nomes; `AudioManager.set_bus_volume(&"SFX", 0.0)` deixa o bus mudo e `Settings.sfx_volume == 0.0` (restaura no fim).
- **Smoke:** `res://tests/qa/scenes/audio_probe.tscn`.
- **Roteiro godot-qa:** cena `audio_probe.tscn`; inputs: frame 30 `ui_left` press/release 4× (volume Music de 0,8 → 0); screenshot frame 20 `f04_audio_start` (Label Music mostra `current_music = menu`, dB ≈ −1,9); frame 90 `f04_audio_muted` (Label Music mostra "MUDO"/−80 dB). O agente também confere no stdout de QA que não houve `ERROR`.
- **Playtest humano (opcional):** pedir ao humano que abra o menu com fone e diga se o crossfade e o volume respondem.

## 11. ADRs locais

### ADR-F04-001 — Duração do crossfade
- **Contexto:** GDD não define tempo de transição de música.
- **Decisão:** propor `MUSIC_FADE_TIME = 1.0` s. **Adicionar à [GDD-P](../design/GDD.md#gdd-p) e a [Ajustes](../design/GDD.md#gdd-ajustes)** antes de usar.
- **Consequências:** transições de setor suaves. **Data:** 2026-09-19.

### ADR-F04-002 — Volume vive em `Settings`, aplicação vive no `AudioManager`
- **Contexto:** evitar dois donos do volume.
- **Decisão:** `AudioManager.set_bus_volume` escreve em `Settings` e no `AudioServer`; `Settings.save_settings()` é chamado pela UI ao fechar.
- **Consequências:** sliders da F08 chamam só uma função. **Data:** 2026-09-19.

### ADR-F04-003 — Placeholders de áudio gerados por código, sem `AssetResolver`
- **Contexto:** não há `ffmpeg` nem arquivo de som no repo, e o `AssetResolver` da [F05](F05-pipeline-assets-placeholders.md) ainda não existe.
- **Decisão:** `tools/make_audio_placeholders.gd` (`extends SceneTree`) sintetiza tudo com `AudioStreamWAV` + `save_to_wav()`: 3 trilhas de 4 s em `assets/placeholder/audio/music/` (drones de 55/65/73 Hz, ciclos inteiros para o loop fechar) e 36 efeitos de 0,04–0,30 s em `assets/placeholder/audio/sfx/`, com timbre por tipo (`beep`, `sweep`, `click`, `noise`, `buzz`) e frequência distinta por nome. Ganho baixo (0,20–0,22) e envelope para não estourar. Arquivo separado do `tools/make_placeholders.gd` (PNG) para não atropelar a F05. Enquanto o `AssetResolver` não chega, o próprio `AudioManager` resolve: caminho final → placeholder de mesmo nome. Quando a F05 entrar, troca-se `_resolve_sfx_path`/`_resolve_music_path` por `AssetResolver.audio()`.
- **Consequências:** 39 arquivos, 884 KB. O jogo nunca depende de arte sonora para rodar. **Data:** 2026-09-19.

### ADR-F04-004 — `play_sfx` sorteia variações `<nome>_N`
- **Contexto:** o [SFX-PACK](../ASSETS.md#sfx-pack) documenta que `play_sfx("step_metal")` sorteia entre `step_metal_1..3`, mas a seção 6 desta feature não descreve o mecanismo.
- **Decisão:** se não existir arquivo com o nome exato, `_streams_for` procura `<nome>_1`, `<nome>_2`… (até 8) e sorteia na hora de tocar. O resultado fica em cache por id.
- **Consequências:** passos e futuras variações não precisam de lógica própria na cena. **Data:** 2026-09-19.

### ADR-F04-005 — `stop_all()` e parada de áudio antes de sair
- **Contexto:** com áudio tocando no instante do encerramento, o Godot 4.7.2 imprime `ERROR: N resources still in use at exit` (detalhes e bisseção no [ADR-F06-004](F06-testes-portoes-qa.md)).
- **Decisão:** o `AudioManager` expõe `stop_all()` (chamado em `_exit_tree`, em `NOTIFICATION_WM_CLOSE_REQUEST` e em `NOTIFICATION_CRASH`); o `QACapture` o chama antes de `quit()`.
- **Consequências:** execuções de QA e de teste saem limpas. Quem fechar o jogo por menu (F07/F09) deve chamar `AudioManager.stop_all()` antes de `get_tree().quit()`. **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.9 e do contrato de buses · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**:
  - `scripts/core/audio_math.gd` (`class_name AudioMath`): `SILENT_DB = -80.0`, `SILENCE_THRESHOLD = 0.001`, `linear_to_db_safe`, `db_to_linear_safe`, `is_silent`.
  - `default_bus_layout.tres` na raiz (Master / Music / SFX / Voice, os três últimos com `send = Master`) + `[audio] buses/default_bus_layout` no `project.godot`.
  - `autoload/audio_manager.gd` completo: 2 players de música com crossfade por `Tween` (`TWEEN_PAUSE_PROCESS`, para atravessar o pause), pool de 8 players de SFX, 1 de voz; `play_music`/`stop_music`/`play_sfx`/`play_voice`/`stop_voice`/`set_bus_volume`/`get_bus_volume`/`apply_volumes`/`current_music`/`stop_all`; `process_mode = ALWAYS`; `push_warning` uma única vez por id ausente, sem quebrar; loop aplicado no carregamento (`AudioStreamWAV.LOOP_FORWARD` com `loop_end = data.size() / bytes_por_frame`; `loop = true` em Ogg/MP3).
  - `tools/make_audio_placeholders.gd` + 39 WAVs em `assets/placeholder/audio/`.
  - Testes: `test_audio_math.gd` (6), `test_audio_buses.gd` (8), `test_audio_manager.gd` (15).
  - QA: `tests/qa/scenes/audio_probe.tscn`/`.gd` (na `tests/scenes.txt`) e roteiro `tests/qa/f04_audio.json`.
- **Decisões**: ADR-F04-003, ADR-F04-004 e ADR-F04-005.
- **Divergência do ADR-F04-001**: o `MUSIC_FADE_TIME` **já existia** na GDD-P e em `balance.gd` com **1.5 s** (posto pela F02), não os 1,0 s propostos aqui. Como a GDD manda, ficou 1,5 s e o Passo 3 não precisou mexer em número nenhum. O ADR-F04-001 fica registrado como proposta vencida.
- **Verificações**: import limpo; `68 passed, 0 failed` (exit 0); smoke 4/4 OK; varreduras 3D e de comentários vazias. QA com janela em `audio_probe`: `f04_audio_start` mostra `TRILHA: menu`, `MASTER 1.00 (0.0 dB)`, `MÚSICA 0.80 (-1.9 dB)`, `EFEITOS 0.80`, `VOZ 0.80`; depois de 4× `ui_left`, `f04_audio_muted` mostra `MÚSICA: MUDO (-80.0 dB)` com os outros buses intactos — ou seja, `set_bus_volume` mexe só no bus pedido, grava no `Settings` e não salva em disco. Nenhum `ERROR` no stdout do QA.
- **Pendências**: (a) a ficha do [SFX-PACK](../ASSETS.md#sfx-pack) e as de MUS-* continuam `pendente` e **não** foram atualizadas com o caminho dos placeholders — esta rodada só podia editar os dois arquivos de feature; (b) `play_voice` ainda não tem quem o chame (F19); (c) Passo 6 segue `[ ]` porque o agente desta rodada não faz git.
- **Próximo passo**: commit `feat(F04): buses de áudio e AudioManager com crossfade e volumes`; a F08 liga os sliders em `AudioManager.set_bus_volume` + `Settings.save_settings()`.

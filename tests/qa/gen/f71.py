import json
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "..")
PROBE = "res://tests/qa/scenes/f34_probe_corridor.tscn"
LEVEL = "F34ProbeCorridor/Greenhouse"


class Script:
    def __init__(self):
        self.events = []

    def at(self, frame, **fields):
        event = {"frame": frame}
        event.update(fields)
        self.events.append(event)

    def tap(self, frame, action):
        self.at(frame, action=action, pressed=True)
        self.at(frame + 2, action=action, pressed=False)

    def key(self, frame, name):
        self.at(frame, key=name, pressed=True)
        self.at(frame + 3, key=name, pressed=False)

    def save(self, name):
        path = os.path.join(ROOT, "tests", "qa", name)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write("[\n")
            handle.write(",\n".join("  " + json.dumps(e, ensure_ascii=False) for e in self.events))
            handle.write("\n]\n")


def options_header(script):
    script.at(1, call="Settings.set", args=["difficulty", "normal"])
    script.at(1, call="Settings.restore_default_bindings", args=[])
    script.at(1, call="Settings.set_colorblind", args=[False])
    script.at(1, call="Settings.set_subtitle_size", args=["normal"])
    script.at(1, call="GameState.new_game", args=[])
    script.at(1, scene="res://scenes/ui/options_menu.tscn")
    script.at(20, expect_scene="res://scenes/ui/options_menu.tscn")
    script.at(30, screenshot="01_opcoes_topo")


def rebind(script, frame, key_name):
    script.tap(frame, "ui_accept")
    script.key(frame + 12, key_name)
    return frame + 12


def remap_jump():
    s = Script()
    options_header(s)
    f = 40
    for _ in range(13):
        s.tap(f, "ui_down")
        f += 6
    s.at(f + 4, expect_call="OptionsMenu.binding_text", args=["jump"], equals="[ESPAÇO]",
         label="foco_no_pulo_com_espaco")
    s.at(f + 6, screenshot="02_foco_no_pulo")
    f += 10
    s.tap(f, "ui_accept")
    s.at(f + 8, expect_call="OptionsMenu.is_capturing", equals=True, label="aguardando_tecla")
    s.at(f + 10, screenshot="03_aguardando_tecla")
    f += 16
    s.key(f, "K")
    s.at(f + 8, expect_call="Settings.binding_label", args=["jump"], equals="[K]",
         label="pulo_agora_em_k")
    s.at(f + 8, expect_call="OptionsMenu.is_capturing", equals=False, label="captura_encerrada")
    s.at(f + 10, screenshot="04_pulo_em_k")
    f = rebind(s, f + 16, "E")
    s.at(f + 8, expect_call="Settings.binding_label", args=["jump"], equals="[E]",
         label="conflito_pulo_em_e")
    s.at(f + 8, expect_call="Settings.binding_label", args=["interact"], equals="[K]",
         label="conflito_interagir_trocou_para_k")
    s.at(f + 10, screenshot="05_conflito_trocou")
    f = rebind(s, f + 16, "Up")
    s.at(f + 8, expect_call="Settings.binding_label", args=["jump"], equals="[E]",
         label="seta_reservada_recusada")
    s.at(f + 10, screenshot="06_seta_reservada")
    f = rebind(s, f + 16, "K")
    s.at(f + 8, expect_call="Settings.binding_label", args=["jump"], equals="[K]",
         label="pulo_de_volta_em_k")
    s.at(f + 8, expect_call="Settings.binding_label", args=["interact"], equals="[E]",
         label="interagir_de_volta_em_e")
    s.at(f + 10, screenshot="07_pulo_em_k_interagir_em_e")
    f += 20
    s.at(f, scene=PROBE)
    f += 40
    s.at(f, expect_scene=PROBE)
    s.at(f + 2, expect_tile=[4, 22], tolerance=0, label="parado_no_chao")
    s.at(f + 4, call=LEVEL + "/TutorialCard.request", args=["tut_jump"])
    f += 30
    s.at(f, screenshot="08_cartao_mostra_k")
    s.key(f + 4, "Space")
    s.at(f + 14, expect_call=LEVEL + "/Player.is_on_floor", equals=True,
         label="espaco_nao_pula_mais")
    s.key(f + 20, "K")
    s.at(f + 30, expect_call=LEVEL + "/Player.is_on_floor", equals=False, label="k_pula")
    s.at(f + 30, screenshot="09_pulou_com_k")
    s.at(f + 90, expect_tile=[4, 22], tolerance=1, label="aterrissou")
    s.at(f + 92, call="Settings.restore_default_bindings", args=[])
    s.at(f + 94, expect_call="Settings.binding_label", args=["jump"], equals="[ESPAÇO]",
         label="restaurar_padroes")
    s.at(f + 100, quit=True)
    s.save("f71_remap_pulo.json")


def accessibility():
    s = Script()
    options_header(s)
    f = 40
    for _ in range(7):
        s.tap(f, "ui_down")
        f += 6
    s.tap(f + 4, "ui_right")
    s.at(f + 12, expect_call="Settings.subtitle_font_size", equals=32, label="legenda_grande")
    f += 16
    s.tap(f, "ui_down")
    s.tap(f + 8, "ui_accept")
    s.at(f + 20, expect_call="Settings.get", args=["colorblind"], equals=True,
         label="daltonico_ligado")
    s.at(f + 22, screenshot="02_legenda_grande_e_daltonico")
    f += 30
    s.at(f, scene=PROBE)
    f += 40
    s.at(f, expect_scene=PROBE)
    s.at(f + 2, call="DialogueManager.open_log", args=["log_gh_01"])
    s.at(f + 60, screenshot="03_log_com_legenda_grande")
    s.at(f + 62, call="Settings.set_subtitle_size", args=["normal"])
    s.at(f + 62, call="DialogueManager.open_log", args=["log_gh_02"])
    f += 70
    s.tap(f, "ui_accept")
    s.tap(f + 6, "ui_accept")
    s.at(f + 70, quit=True)
    s.save("f71_legenda_daltonico.json")


def colorblind_plates():
    s = Script()
    state = {
        "flags": {
            "dlg_core_wake": True, "dlg_core_alarm": True, "dlg_core_terminal_first": True,
            "dlg_core_lights_off": True, "dlg_hab_body": True, "dlg_hab_first_sr3": True,
            "dlg_core_return": True, "dlg_core_return_lab": True, "dlg_gh_enter": True,
            "dlg_gh_claws": True, "dlg_gh_restored": True, "dlg_lab_enter": True,
            "dlg_inf_enter": True, "reactor_online": True,
        },
        "abilities": ["magnetic_claws"],
        "sectors_restored": ["greenhouse"],
        "energy_states": {"core_hub": ["door_habitat"], "greenhouse": ["wing_door", "node_door"]},
        "current_objective": "obj_core_lab",
        "checkpoint": {"scene": "res://scenes/levels/core_hub.tscn", "dock_id": "hab_dock_02"},
    }
    s.at(1, call="Settings.set", args=["difficulty", "normal"])
    s.at(1, call="Settings.set_colorblind", args=[False])
    s.at(1, call="GameState.new_game", args=[])
    s.at(1, call="GameState.from_dict", args=[state])
    s.at(1, scene="res://scenes/levels/core_hub.tscn")
    s.at(20, expect_scene="res://scenes/levels/core_hub.tscn")
    s.at(80, expect_tile=[95, 12], tolerance=1, label="doca_da_ala")
    s.at(81, action="move_right", pressed=True)
    s.at(133, action="move_right", pressed=False)
    s.at(170, expect_tile=[101, 12], tolerance=1, label="portal_da_estufa")
    s.at(172, screenshot="01_placas_cores_normais")
    s.at(174, call="Settings.set_colorblind", args=[True])
    s.at(180, screenshot="02_placas_modo_daltonico")
    s.at(182, expect_call="Settings.get", args=["colorblind"], equals=True,
         label="modo_daltonico_ativo")
    s.at(190, quit=True)
    s.save("f71_placas_daltonico.json")


remap_jump()
accessibility()
colorblind_plates()

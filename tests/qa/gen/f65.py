import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
QA = os.path.dirname(HERE)
SCENE = "res://scenes/levels/reactor_core.tscn"
HUB = "res://scenes/levels/core_hub.tscn"
COMMAND = "res://scenes/levels/command_room.tscn"
ABILITIES = ["magnetic_claws", "heat_sink", "heated_core", "thruster", "root_access"]
PLAYER = "ReactorCore/Player"
JUMP_AT = 52
DOUBLE_AT = 12
WALK_TO_HOLE = 62
PERCH_STEP = 12
COUPLER_STEP = 10
PAD_STEP = 18
LEDGE_STEP = 8
BEAM_APEX = 14
ARGOS = "ReactorCore/Argos"


class Script:
    def __init__(self):
        self.events = []

    def add(self, frame, **event):
        event = dict(event)
        event["frame"] = frame
        self.events.append(event)

    def press(self, frame, action, hold=3):
        self.add(frame, action=action, pressed=True)
        self.add(frame + hold, action=action, pressed=False)

    def teleport(self, frame, cell):
        x = cell[0] * 16 + 8
        y = (cell[1] + 1) * 16 - 1
        self.add(frame, call=PLAYER + ".set_indexed", args=["global_position:x", x])
        self.add(frame, call=PLAYER + ".set_indexed", args=["global_position:y", y])

    def write(self, name):
        ordered = sorted(enumerate(self.events), key=lambda item: (item[1]["frame"], item[0]))
        lines = []
        for _, event in ordered:
            frame = event.pop("frame")
            body = json.dumps(event, ensure_ascii=False)[1:-1]
            lines.append('  {"frame": %d, %s}' % (frame, body))
        path = os.path.join(QA, name)
        with open(path, "w") as handle:
            handle.write("[\n" + ",\n".join(lines) + "\n]\n")


def setup(script, frame=1, defeated=False):
    script.add(frame, call="Settings.set", args=["difficulty", "normal"])
    script.add(frame, call="GameState.new_game", args=[])
    for ability in ABILITIES:
        script.add(frame, call="GameState.unlock_ability", args=[ability])
    script.add(frame, scene=SCENE)
    script.add(frame + 20, expect_scene=SCENE)


def tour():
    s = Script()
    setup(s)
    s.add(40, screenshot="00_entrada")
    s.press(41, "ui_accept")
    s.press(52, "ui_accept")
    s.press(63, "ui_accept")
    s.press(74, "ui_accept")
    s.add(110, expect_tile=[4, 44], tolerance=1, label="nasce_no_P")
    s.add(112, screenshot="01_spawn")
    stops = [
        ("02_fornalha", (12, 44)),
        ("03_vao_dash", (19, 44)),
        ("04_garras", (31, 40)),
        ("05_bloco_pulo_duplo", (20, 25)),
        ("06_escada", (8, 21)),
        ("07_log", (19, 5)),
        ("08_doca_arena", (30, 11)),
    ]
    frame = 120
    for name, cell in stops:
        s.teleport(frame, cell)
        s.add(frame + 30, screenshot=name)
        frame += 40
    s.add(frame, expect_call=ARGOS + ".state_name", equals="idle", label="arena_parada")
    s.teleport(frame + 2, (38, 31))
    s.add(frame + 40, expect_call=ARGOS + ".state_name", equals="active", label="luta_comecou")
    s.add(frame + 42, screenshot="09_arena_oeste")
    frame += 60
    arena = [
        ("10_acoplador_oeste", (41, 27)),
        ("11_piso", (40, 44)),
        ("12_plataformas", (49, 44)),
        ("13_acoplador_piso", (59, 44)),
        ("14_plataforma_leste", (58, 32)),
        ("15_parede_garras", (61, 20)),
        ("16_acoplador_alto", (55, 8)),
        ("17_nucleo", (52, 8)),
    ]
    for name, cell in arena:
        s.teleport(frame, cell)
        s.add(frame + 25, screenshot=name)
        frame += 35
    s.add(frame, call=ARGOS + ".overload_coupler", args=["rc_coupler_01"])
    s.add(frame + 40, screenshot="18_um_acoplador")
    s.add(frame + 41, expect_call=ARGOS + ".phase", equals=2, label="fase_2")
    s.add(frame + 60, call=ARGOS + ".overload_coupler", args=["rc_coupler_02"])
    s.add(frame + 100, screenshot="19_dois_acopladores")
    s.add(frame + 101, expect_call=ARGOS + ".phase", equals=3, label="fase_3")
    s.add(frame + 120, call=ARGOS + ".overload_coupler", args=["rc_coupler_03"])
    s.add(frame + 200, screenshot="20_argos_apagando")
    s.add(frame + 201, expect_call=ARGOS + ".is_defeated", equals=True, label="argos_vencido")
    s.add(frame + 330, screenshot="21_silencio")
    s.add(frame + 780, expect_scene=COMMAND)
    s.add(frame + 830, screenshot="22_sala_de_comando")
    s.add(frame + 850, quit=True)
    s.write("f65_tour.json")


HUB_FLAGS = {
    "dlg_core_wake": True, "dlg_core_alarm": True, "dlg_core_terminal_first": True,
    "dlg_core_lights_off": True, "dlg_hab_body": True, "dlg_hab_first_sr3": True,
    "dlg_core_return": True, "dlg_core_return_lab": True, "dlg_gh_enter": True,
    "dlg_gh_claws": True, "dlg_gh_restored": True, "dlg_lab_enter": True, "dlg_inf_enter": True,
    "dlg_core_return_infirmary": True, "dlg_core_return_docks": True, "reactor_online": True,
    "dlg_core_return_memory": True, "dlg_dk_enter": True, "dlg_dk_restored": True,
    "dlg_mem_enter": True, "dlg_mem_luto": True, "dlg_mem_restored": True, "mem_protocol": 3,
    "earth_signal": True,
}


def saved_state(extra_flags=None, checkpoint=None):
    flags = dict(HUB_FLAGS)
    flags.update(extra_flags or {})
    state = {
        "flags": flags,
        "abilities": ABILITIES,
        "sectors_restored": ["greenhouse", "lab", "infirmary", "docks", "memory"],
        "energy_states": {"core_hub": ["door_habitat"]},
        "current_objective": "obj_core_reactor",
    }
    if checkpoint is not None:
        state["checkpoint"] = checkpoint
    return state


def hub_to_reactor(s, frame):
    s.add(frame, call="Settings.set", args=["difficulty", "normal"])
    s.add(frame, call="GameState.new_game", args=[])
    s.add(frame, call="GameState.from_dict", args=[saved_state(
        checkpoint={"scene": HUB, "dock_id": "core_dock_wing"})])
    s.add(frame, call="SaveManager.save_game", args=[])
    s.add(frame, scene=HUB)
    s.add(frame + 39, expect_scene=HUB)
    s.add(frame + 59, call="CoreHub/Player.set_indexed", args=["global_position:x", 2264.0])
    s.add(frame + 59, call="CoreHub/Player.set_indexed", args=["global_position:y", 95.0])
    s.add(frame + 99, expect_tile=[141, 5], tolerance=0, label="hub_patamar_do_reator")
    s.add(frame + 104, action="move_right", pressed=True)
    s.add(frame + 134, action="move_right", pressed=False)
    s.add(frame + 150, expect_tile=[142, 5], tolerance=0, label="hub_barrado_pela_comporta")
    s.add(frame + 151, screenshot="01_hub_comporta_do_reator")
    s.press(frame + 160, "interact")
    s.add(frame + 195, expect_call="GameState.is_root_door_open", args=["door_reactor"],
          equals=True, label="hub_comporta_aberta_com_root")
    s.add(frame + 200, action="move_right", pressed=True)
    s.add(frame + 232, action="move_right", pressed=False)
    s.add(frame + 250, expect_tile=[146, 5], tolerance=1, label="hub_no_portal_do_reator")
    s.add(frame + 251, screenshot="02_hub_portal_do_reator")
    s.press(frame + 255, "interact")
    s.add(frame + 420, expect_scene=SCENE)
    return frame + 420


def reactor():
    s = Script()
    frame = hub_to_reactor(s, 1)
    s.add(frame + 10, screenshot="03_fala_de_entrada")
    for offset in (20, 45, 70, 95, 120, 145):
        s.press(frame + offset, "ui_accept")
    frame += 190
    s.add(frame, expect_tile=[2, 44], tolerance=1, label="chega_pelo_portal")
    s.add(frame + 1, screenshot="04_aproximacao")
    s.add(frame + 5, action="move_right", pressed=True)
    s.press(frame + 167, "jump")
    s.press(frame + 169, "dash")
    s.add(frame + 176, screenshot="05_dash_no_vao")
    s.add(frame + 240, action="move_right", pressed=False)
    s.add(frame + 260, expect_tile=[32, 44], tolerance=1, label="cruzou_o_vao_com_dash")
    frame += 270
    s.teleport(frame, (28, 25))
    s.add(frame + 30, expect_tile=[28, 25], tolerance=1, label="corredor_do_bloco")
    s.add(frame + 35, action="move_left", pressed=True)
    s.press(frame + 35 + JUMP_AT, "jump", DOUBLE_AT - 1)
    s.press(frame + 35 + JUMP_AT + DOUBLE_AT, "jump", 20)
    s.add(frame + 35 + JUMP_AT + 24, screenshot="06_pulo_duplo_no_bloco")
    s.add(frame + 35 + JUMP_AT + 60, action="move_left", pressed=False)
    s.add(frame + 35 + JUMP_AT + 70, expect_tile=[16, 21], tolerance=1,
          label="passou_o_bloco_com_pulo_duplo")
    frame += 35 + JUMP_AT + 80
    s.teleport(frame, (31, 11))
    s.add(frame + 30, expect_tile=[31, 11], tolerance=0, label="doca_antes_da_arena")
    s.add(frame + 31, expect_call=ARGOS + ".state_name", equals="idle", label="argos_espera")
    s.add(frame + 32, call="GameState.add_charge", args=[100])
    s.add(frame + 35, action="move_right", pressed=True)
    s.add(frame + 35 + WALK_TO_HOLE, action="move_right", pressed=False)
    for index in range(12):
        s.add(frame + 35 + WALK_TO_HOLE + index * 8, screenshot="queda_%02d" % index)
    frame += 35 + WALK_TO_HOLE + 110
    s.add(frame, expect_tile=[38, 31], tolerance=1, label="caiu_na_arena")
    s.add(frame + 1, expect_call=ARGOS + ".state_name", equals="active", label="luta_comecou")
    s.add(frame + 2, screenshot="07_arena_oeste")
    s.add(frame + 5, action="move_right", pressed=True)
    s.add(frame + 13, action="move_right", pressed=False)
    s.add(frame + 30, expect_tile=[39, 31], tolerance=0, label="no_console_b")
    s.press(frame + 32, "interact")
    s.add(frame + 50, screenshot="08_terminal_da_arena")
    s.press(frame + 55, "interact")
    s.press(frame + 65, "move_down")
    s.press(frame + 75, "interact")
    s.press(frame + 85, "move_down")
    s.press(frame + 95, "interact")
    s.add(frame + 105, screenshot="09_linhas_1_e_2")
    s.press(frame + 110, "ui_cancel")
    s.add(frame + 125, expect_call=ARGOS + ".coupler_fed", args=["rc_coupler_02"], equals=True,
          label="linha_2_viva")
    s.add(frame + 126, expect_call=ARGOS + ".coupler_fed", args=["rc_coupler_01"], equals=True,
          label="linha_1_viva")
    frame += 130
    s.press(frame, "jump", 11)
    s.press(frame + 12, "jump", 20)
    s.add(frame + 18, action="move_right", pressed=True)
    s.add(frame + 18 + PERCH_STEP, action="move_right", pressed=False)
    for index in range(10):
        s.add(frame + index * 6, screenshot="poleiro_%02d" % index)
    frame += 70
    s.add(frame, expect_tile=[41, 27], tolerance=1, label="no_poleiro_oeste")
    s.press(frame + 2, "move_left", 2)
    s.press(frame + 6, "beam")
    s.add(frame + 14, screenshot="10_feixe_na_torre")
    s.add(frame + 16, expect_call=ARGOS + ".state_name", equals="active", label="torre_atordoada")
    s.add(frame + 18, action="move_right", pressed=True)
    s.add(frame + 18 + COUPLER_STEP, action="move_right", pressed=False)
    s.press(frame + 40, "interact")
    s.add(frame + 70, screenshot="11_sobrecarga_root")
    s.add(frame + 140, expect_call=ARGOS + ".coupler_overloaded", args=["rc_coupler_02"],
          equals=True, label="acoplador_oeste_queimado")
    s.add(frame + 141, expect_call=ARGOS + ".phase", equals=2, label="fase_2")
    s.add(frame + 150, screenshot="12_acoplador_queimado")
    frame += 160
    s.teleport(frame, (58, 44))
    s.add(frame + 4, action="move_right", pressed=True)
    s.add(frame + 4 + PAD_STEP, action="move_right", pressed=False)
    s.press(frame + 4 + PAD_STEP + 2, "beam")
    s.add(frame + 4 + PAD_STEP + 8, screenshot="13_feixe_na_torre_do_piso")
    s.press(frame + 4 + PAD_STEP + 12, "interact")
    s.add(frame + 160, expect_call=ARGOS + ".coupler_overloaded", args=["rc_coupler_01"],
          equals=True, label="acoplador_do_piso_queimado")
    s.add(frame + 158, expect_tile=[60, 44], tolerance=0, label="no_acoplador_do_piso")
    s.add(frame + 161, expect_call=ARGOS + ".phase", equals=3, label="fase_3")
    s.add(frame + 162, screenshot="14_dois_acopladores")
    frame += 170
    s.teleport(frame, (40, 44))
    s.add(frame + 25, expect_tile=[40, 44], tolerance=0, label="piso_oeste")
    s.press(frame + 27, "move_left", 8)
    s.add(frame + 45, expect_tile=[39, 44], tolerance=0, label="no_console_a")
    s.press(frame + 47, "interact")
    s.press(frame + 65, "move_down")
    s.press(frame + 75, "move_down")
    s.press(frame + 85, "interact")
    s.press(frame + 95, "move_down")
    s.press(frame + 105, "interact")
    s.add(frame + 112, screenshot="15_linha_3")
    s.press(frame + 115, "ui_cancel")
    s.add(frame + 130, expect_call=ARGOS + ".coupler_fed", args=["rc_coupler_03"], equals=True,
          label="linha_3_viva")
    frame += 135
    s.teleport(frame, (57, 8))
    s.add(frame + 25, expect_tile=[57, 8], tolerance=0, label="no_alto")
    s.press(frame + 27, "move_left", LEDGE_STEP)
    s.press(frame + 45, "jump", 15)
    s.press(frame + 45 + BEAM_APEX, "beam")
    s.add(frame + 47 + BEAM_APEX, screenshot="16_feixe_no_alto")
    s.press(frame + 90, "interact")
    s.add(frame + 120, screenshot="17_ultimo_acoplador")
    s.add(frame + 188, expect_call=ARGOS + ".coupler_overloaded", args=["rc_coupler_03"],
          equals=True, label="acoplador_do_alto_queimado")
    s.add(frame + 190, expect_call=ARGOS + ".is_defeated", equals=True, label="argos_vencido")
    s.add(frame + 230, screenshot="18_argos_apagando")
    s.add(frame + 420, screenshot="19_silencio")
    s.add(frame + 860, expect_scene=COMMAND)
    s.add(frame + 900, screenshot="20_sala_de_comando")
    s.add(frame + 910, quit=True)
    s.write("f65_reactor.json")


def direct_setup(s):
    s.add(1, call="Settings.set", args=["difficulty", "normal"])
    s.add(1, call="GameState.new_game", args=[])
    s.add(1, call="GameState.from_dict", args=[saved_state({"dlg_rc_enter": True})])
    s.add(1, scene=SCENE)
    s.add(40, expect_scene=SCENE)
    s.teleport(60, (31, 11))
    s.add(90, expect_tile=[31, 11], tolerance=0, label="doca_antes_da_arena")
    s.add(91, expect_call=ARGOS + ".state_name", equals="idle", label="argos_espera")


def timeout():
    s = Script()
    direct_setup(s)
    s.teleport(100, (38, 44))
    s.add(130, expect_call=ARGOS + ".state_name", equals="active", label="luta_comecou")
    s.add(132, call=ARGOS + ".overload_coupler", args=["rc_coupler_01"])
    s.add(140, expect_call=ARGOS + ".overloaded_count", equals=1, label="um_acoplador")
    s.add(160, screenshot="01_ilha_fria_no_piso")
    start = 102
    s.add(start + 45 * 60, expect_call=ARGOS + ".lit_segments", equals=5, label="metade_das_lampadas")
    s.add(start + 45 * 60 + 2, screenshot="02_metade_do_tempo")
    s.add(start + 75 * 60, expect_call=ARGOS + ".lit_segments", equals=2, label="duas_lampadas")
    s.add(start + 75 * 60 + 2, screenshot="03_alarme_vermelho")
    s.add(start + 89 * 60, screenshot="04_ultimo_segundo")
    s.add(start + 91 * 60, screenshot="05_nucleo_estoura")
    after = start + 91 * 60 + 300
    s.add(after, expect_tile=[31, 11], tolerance=1, label="volta_na_doca")
    s.add(after + 1, expect_call=ARGOS + ".state_name", equals="idle", label="encontro_limpo")
    s.add(after + 2, expect_call=ARGOS + ".overloaded_count", equals=0, label="contagem_zerada")
    s.add(after + 3, expect_call=ARGOS + ".coupler_overloaded", args=["rc_coupler_01"],
          equals=False, label="acoplador_limpo")
    s.add(after + 4, expect_call=ARGOS + ".time_left", equals=90.0, label="relogio_cheio")
    s.add(after + 5, screenshot="06_de_volta_na_doca")
    s.teleport(after + 10, (38, 44))
    s.add(after + 40, expect_call=ARGOS + ".state_name", equals="active", label="recomeca")
    s.add(after + 50, quit=True)
    s.write("f65_falha_tempo.json")


def death():
    s = Script()
    direct_setup(s)
    s.teleport(100, (38, 44))
    s.add(130, expect_call=ARGOS + ".state_name", equals="active", label="luta_comecou")
    s.add(132, call=ARGOS + ".overload_coupler", args=["rc_coupler_02"])
    s.add(140, expect_call=ARGOS + ".phase", equals=2, label="fase_2")
    s.add(142, call="ReactorCore/EnergyNetwork.toggle", args=["reactor_core", "line_1"])
    s.add(146, expect_call=ARGOS + ".coupler_fed", args=["rc_coupler_01"], equals=True,
          label="linha_1_ligada")
    s.add(150, call="GameState.apply_damage", args=[500])
    s.add(170, screenshot="01_chassi_perdido")
    s.add(470, expect_tile=[31, 11], tolerance=1, label="volta_na_doca")
    s.add(471, expect_call=ARGOS + ".state_name", equals="idle", label="encontro_limpo")
    s.add(472, expect_call=ARGOS + ".phase", equals=1, label="fase_1")
    s.add(473, expect_call=ARGOS + ".coupler_overloaded", args=["rc_coupler_02"], equals=False,
          label="acoplador_limpo")
    s.add(474, expect_call=ARGOS + ".coupler_fed", args=["rc_coupler_01"], equals=False,
          label="energia_inicial")
    s.add(475, screenshot="02_de_volta_na_doca")
    s.teleport(480, (38, 44))
    s.add(510, expect_call=ARGOS + ".state_name", equals="active", label="recomeca")
    s.add(512, expect_call=ARGOS + ".lit_segments", equals=9, label="relogio_de_novo")
    s.add(520, quit=True)
    s.write("f65_morte.json")


def station_map():
    s = Script()
    state = saved_state({"argos_defeated": True},
                        checkpoint={"scene": HUB, "dock_id": "core_dock_wing"})
    state["sectors_restored"] = state["sectors_restored"] + ["reactor"]
    s.add(1, call="Settings.set", args=["difficulty", "normal"])
    s.add(1, call="GameState.new_game", args=[])
    s.add(1, call="GameState.from_dict", args=[state])
    s.add(1, scene=HUB)
    s.add(20, expect_scene=HUB)
    s.add(80, expect_tile=[129, 11], tolerance=1, label="doca_da_ala")
    s.add(84, screenshot="01_hub_depois_de_argos")
    s.press(90, "map", 4)
    s.press(120, "map", 4)
    hud_map = "CoreHub/HUD/ChassisMenu/Root/Map"
    s.add(140, expect_call="CoreHub/HUD/ChassisMenu.current_page", equals="map",
          label="mapa_aberto")
    for sector in ["greenhouse", "lab", "infirmary", "docks", "memory", "reactor"]:
        s.add(141, expect_call=hud_map + ".state_of", args=[sector], equals="restored",
              label="religado_" + sector)
    s.add(147, screenshot="02_mapa_religados_7_de_7")
    s.press(160, "map", 4)
    s.add(180, quit=True)
    s.write("f65_mapa_fim.json")


if __name__ == "__main__":
    station_map()
    tour()
    reactor()
    timeout()
    death()

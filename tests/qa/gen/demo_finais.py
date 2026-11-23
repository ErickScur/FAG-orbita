import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import demo as d
import demo_states as ds
import f66
import review_campaign as rc
from qa_build import R

STOP = os.environ.get("DEMO_STOP", "")
PREROLL = int(os.environ.get("DEMO_PREROLL", "0"))
ARGOS = "ReactorCore/Argos"
VENT = "ReactorCore/Entities/SteamVent"
LIFT = "ReactorCore/Entities/ThermalPlatform"


class Stop(Exception):
    pass


def probe(r, root, count=30, every=4, tag="p"):
    for index in range(count):
        r.add(expect_call=root + "/Player.get", args=["global_position"], equals="?",
              label="%s%03d" % (tag, index))
        r.wait(every)


def stage(r, name, root):
    if STOP == name:
        r.wait(4)
        probe(r, root)
        r.shot("stop_" + name)
        r.quit()
        raise Stop()


def picked(r, kind, item_id, prefix):
    rc.check(r, "GameState.register_pickup", False, prefix + "_ja_pegou_" + item_id,
             [kind, item_id])


def mark(r, x, y, label, root="ReactorCore"):
    r.expect(x, y, label)
    if STOP:
        r.add(expect_call=root + "/Player.get", args=["global_position"], equals="?",
              label=label + "_pos")
        vitals(r, label)


def vitals(r, prefix):
    if STOP:
        r.add(expect_call="GameState.get", args=["integrity"], equals="?", label=prefix + "_vida")
        r.add(expect_call="GameState.get", args=["charge"], equals="?", label=prefix + "_carga")


def walk(r, direction, frames, settle=12):
    r.hold("move_" + direction, frames)
    r.wait(settle)


def jump(r, hold=14, land=40):
    r.hold("jump", hold)
    r.wait(land)


def look(r, frames):
    r.wait(frames)


def reactor_hub(r):
    root = "CoreHub"
    r.at(40 + PREROLL)
    r.expect_scene(rc.HUB)
    mark(r, 129, 11, "r01_doca_da_ala")
    rc.silent(r, "r01")
    r.shot("r01_hub_ala")
    look(r, 30)
    walk(r, "right", 20, 8)
    jump(r, 14, 34)
    mark(r, 131, 9, "r02_primeira_passarela")
    walk(r, "right", 36, 8)
    jump(r, 14, 34)
    mark(r, 135, 7, "r03_segunda_passarela")
    walk(r, "right", 14, 8)
    jump(r, 14, 34)
    mark(r, 137, 5, "r04_patamar_do_reator")
    stage(r, "hub2", root)
    walk(r, "right", 50, 20)
    mark(r, 142, 5, "r05_comporta_root")
    r.shot("r05_comporta_root")
    look(r, 30)
    r.interact(40)
    rc.check(r, "GameState.is_root_door_open", True, "r06_comporta_aberta", ["door_reactor"])
    r.shot("r06_comporta_aberta")
    look(r, 30)
    walk(r, "right", 34, 20)
    mark(r, 146, 5, "r07_portal_do_reator")
    r.shot("r07_portal_do_reator")
    r.interact(2)
    d.wait_scene(r, rc.RC, "r08_chega_ao_reator", 90)


def reactor_approach(r):
    root = "ReactorCore"
    d.wait_call(r, "DialogueManager.is_active", True, "r08_fala_comeca", 30)
    arrival = r.f
    r.wait(10)
    rc.dialogue(r, "rc_enter", "r08_entrada")
    r.shot("r08_fala_de_entrada")
    r.wait(10)
    r.accept(rc.dialogue_lines("rc_enter") * 2 + 1, 25)
    r.at(arrival + 180)
    rc.silent(r, "r09")
    mark(r, 2, 44, "r09_portal_de_volta")
    r.shot("r09_corredor_do_reator")
    if STOP == "rc1":
        r.add(expect_call=root + "/Entities.get_children", equals="?", label="filhos")
    stage(r, "rc1", root)
    r.wait(5)
    walk(r, "right", 60, 20)
    mark(r, 9, 44, "r10_antes_da_fornalha")
    d.wait_call(r, VENT + ".current_phase", 1, "r10_ritmo_do_vapor", 8)
    r.shot("r10_espera_o_vapor")
    r.wait(40)
    r.press("move_right")
    r.wait(106)
    r.tap("jump", 2, 0)
    r.tap("dash", 3, 0)
    r.wait(66)
    r.release("move_right")
    r.wait(20)
    mark(r, 32, 44, "r10_cruzou_o_vao_com_dash")
    stage(r, "rc2", root)
    look(r, 20)
    r.press("move_up")
    r.hold("jump", 11)
    r.wait(2)
    r.press("move_left")
    r.hold("jump", 12)
    r.release("move_left")
    r.wait(178)
    r.press("move_left")
    r.hold("jump", 14)
    r.wait(26)
    r.release("move_up")
    r.wait(20)
    r.release("move_left")
    r.wait(20)
    mark(r, 26, 25, "r11_subiu_o_poco_com_garras")
    d.wait_call(r, VENT + ".current_phase", 2, "r12_vapor_do_corredor_liga", 8)
    r.shot("r12_vapor_do_corredor")
    d.wait_call(r, VENT + ".current_phase", 0, "r12_vapor_do_corredor_desliga", 8)
    walk(r, "left", 70, 14)
    mark(r, 19, 25, "r12_encostou_no_bloco")
    stage(r, "rc4", root)
    r.hold("jump", 11)
    r.wait(1)
    r.press("jump")
    r.press("move_left")
    r.wait(20)
    r.release("jump")
    r.wait(16)
    r.release("move_left")
    r.wait(24)
    mark(r, 16, 21, "r12_passou_o_bloco_com_pulo_duplo")
    vitals(r, "r12")
    look(r, 15)
    r.press("move_left")
    d.wait_call(r, "DialogueManager.is_active", True, "r13_argos_fala", 5)
    r.release("move_left")
    rc.dialogue(r, "rc_argos", "r13_argos")
    r.wait(20)
    r.shot("r13_argos_fala")
    look(r, 50)
    walk(r, "left", 28, 16)
    mark(r, 7, 25, "r14_pe_da_escada")
    stage(r, "rc6", root)
    for step in range(7):
        jump(r, 14, 36)
    r.wait(10)
    mark(r, 7, 11, "r15_topo_da_escada")
    rc.silent(r, "r15_argos_calado")
    r.shot("r15_topo_da_escada")
    look(r, 20)
    walk(r, "right", 66, 14)
    stage(r, "rc7", root)
    r.press("move_up")
    r.press("move_left")
    r.hold("jump", 12)
    r.release("move_left")
    r.wait(76)
    r.release("move_up")
    r.press("move_right")
    r.hold("jump", 10)
    r.wait(16)
    r.release("move_right")
    r.wait(16)
    mark(r, 16, 5, "r16_sala_do_registro")
    look(r, 20)
    walk(r, "right", 30, 16)
    mark(r, 21, 5, "r17_terminal_do_registro")
    r.shot("r17_terminal_do_registro")
    rc.read_log(r, "log_rc_01", 14)
    r.wait(30)
    rc.silent(r, "r17_registro_lido")
    picked(r, "log", "log_rc_01", "r17")
    stage(r, "rc9", root)
    walk(r, "left", 56, 50)
    mark(r, 15, 11, "r18_desceu_a_chamine")
    walk(r, "right", 146, 20)
    mark(r, 31, 11, "r19_doca_antes_da_arena")
    rc.check(r, ARGOS + ".state_name", "idle", "r19_argos_espera")
    r.shot("r19_doca_antes_da_arena")
    look(r, 150)
    stage(r, "rc10", root)


def reactor_arena(r):
    root = "ReactorCore"
    walk(r, "right", 56, 20)
    mark(r, 37, 11, "r20_beira_da_arena")
    r.shot("r20_beira_da_arena")
    look(r, 60)
    r.hold("move_right", 16)
    r.wait(110)
    mark(r, 38, 31, "r20_caiu_na_arena")
    rc.check(r, ARGOS + ".state_name", "active", "r20_luta_comecou")
    r.shot("r20_argos_acorda")
    look(r, 100)
    r.shot("r20_relogio_e_nucleo")
    walk(r, "right", 8, 14)
    mark(r, 39, 31, "r21_console_b")
    r.interact(20)
    r.shot("r21_terminal_da_arena")
    r.wait(20)
    r.interact(10)
    r.tap("move_down", 3, 8)
    r.interact(10)
    r.tap("move_down", 3, 8)
    r.interact(10)
    r.shot("r21_linhas_1_e_2")
    r.wait(30)
    r.tap("ui_cancel", 3, 14)
    rc.check(r, ARGOS + ".coupler_fed", True, "r21_linha_2_viva", ["rc_coupler_02"])
    rc.check(r, ARGOS + ".coupler_fed", True, "r21_linha_1_viva", ["rc_coupler_01"])
    r.shot("r21_acopladores_acesos")
    look(r, 30)
    walk(r, "left", 9, 12)
    stage(r, "rc11", root)
    if STOP == "rcp":
        base = r.f
        for k in range(25):
            r.add(expect_call=root + "/Player.get", args=["global_position"], equals="?", label="q%02d" % k)
            r.wait(3)
        r.at(base)
    r.hold("jump", 11)
    r.wait(1)
    r.press("jump")
    r.wait(5)
    r.press("move_right")
    r.wait(12)
    r.release("move_right")
    r.wait(3)
    r.release("jump")
    r.wait(12)
    stage(r, "rcp", root)
    mark(r, 40, 27, "r22_poleiro_oeste")
    if STOP == "rc12":
        base = r.f
        for k in range(40):
            r.add(expect_call="GameState.get", args=["integrity"], equals="?", label="h%02d" % k)
            r.shot("h%02d" % k)
            r.wait(5)
        r.at(base)
    r.tap("move_left", 2, 4)
    r.press("jump")
    r.wait(3)
    r.release("jump")
    r.wait(6)
    r.press("beam")
    r.wait(3)
    r.shot("r22_feixe_na_torre_oeste")
    r.release("beam")
    r.wait(20)
    walk(r, "right", 16, 6)
    mark(r, 42, 27, "r22_no_acoplador_oeste")
    r.interact(20)
    r.shot("r22_sobrecarga_root")
    d.wait_call(r, ARGOS + ".coupler_overloaded", True, "r23_acoplador_oeste_queimado", 5,
                ["rc_coupler_02"])
    rc.check(r, ARGOS + ".phase", 2, "r23_fase_2")
    r.shot("r23_nucleo_racha")
    walk(r, "left", 26, 30)
    mark(r, 39, 31, "r24_desceu_do_poleiro")
    stage(r, "rc12", root)
    r.press("move_right")
    r.wait(36)
    r.release("move_right")
    r.press("move_left")
    r.wait(20)
    r.release("move_left")
    r.wait(36)
    mark(r, 43, 44, "r25_piso_oeste")
    r.shot("r25_piso_oeste")
    look(r, 40)
    walk(r, "left", 30, 14)
    mark(r, 40, 44, "r26_console_a")
    r.interact(20)
    r.shot("r26_terminal_piso")
    r.wait(20)
    r.tap("move_down", 3, 8)
    r.tap("move_down", 3, 8)
    r.interact(10)
    r.tap("move_down", 3, 8)
    r.interact(10)
    r.shot("r26_linha_3")
    r.wait(30)
    r.tap("ui_cancel", 3, 14)
    rc.check(r, ARGOS + ".coupler_fed", True, "r26_linha_3_viva", ["rc_coupler_03"])
    rc.check(r, ARGOS + ".coupler_fed", True, "r26_linha_1_viva", ["rc_coupler_01"])
    walk(r, "right", 26, 10)
    mark(r, 43, 44, "r27_beira_do_piso_eletrico")
    r.shot("r27_plataformas_termicas")
    d.wait_call(r, LIFT + ".current_ratio", 1.0, "r27_plataforma_no_alto", 10)
    d.wait_call(r, LIFT + ".current_ratio", 0.0, "r27_plataforma_desceu", 10)
    r.wait(6)
    r.press("move_right")
    r.hold("jump", 14)
    r.wait(14)
    r.release("move_right")
    r.wait(6)
    r.shot("r28_sobe_com_o_calor")
    walk(r, "right", 12, 4)
    d.wait_call(r, LIFT + ".current_ratio", 1.0, "r28_plataforma_no_alto", 10)
    r.shot("r28_no_alto_da_plataforma")
    r.press("move_right")
    r.hold("jump", 14)
    r.wait(72)
    r.release("move_right")
    r.wait(16)
    mark(r, 56, 44, "r29_piso_leste")
    r.press("move_right")
    r.tap("dash", 3, 0)
    r.shot("r29_dash_para_a_torre")
    r.wait(14)
    r.release("move_right")
    r.wait(2)
    r.expect(61, 44, "r30_acoplador_do_piso", 2)
    r.press("beam")
    r.wait(4)
    r.shot("r30_feixe_na_torre_do_piso")
    r.wait(2)
    r.release("beam")
    r.wait(10)
    r.interact(20)
    r.shot("r30_sobrecarga_do_piso")
    d.wait_call(r, ARGOS + ".coupler_overloaded", True, "r31_acoplador_do_piso_queimado", 5,
                ["rc_coupler_01"])
    rc.check(r, ARGOS + ".phase", 3, "r31_fase_3")
    r.shot("r31_nucleo_racha_de_novo")
    if STOP:
        r.add(expect_call=ARGOS + ".time_left", equals="?", label="tempo")
    walk(r, "left", 50, 10)
    mark(r, 56, 44, "r32_volta_para_a_plataforma")
    d.wait_call(r, LIFT + ".current_ratio", 1.0, "r32_plataforma_leste_embaixo", 10)
    if STOP == "rcl":
        base = r.f
        for k in range(25):
            r.add(expect_call=root + "/Player.get", args=["global_position"], equals="?", label="q%02d" % k)
            r.add(expect_call=LIFT + ".current_ratio", equals="?", label="l%02d" % k)
            r.wait(3)
        r.at(base)
    r.press("move_left")
    r.wait(8)
    r.hold("jump", 14)
    r.wait(10)
    r.release("move_left")
    r.wait(8)
    r.shot("r33_sobe_na_plataforma_leste")
    stage(r, "rcl", root)
    d.wait_call(r, LIFT + ".current_ratio", 0.0, "r33_plataforma_leste_no_alto", 10)
    r.press("move_right")
    r.hold("jump", 14)
    r.wait(22)
    r.release("move_right")
    r.wait(10)
    mark(r, 57, 32, "r34_plataforma_r1")
    walk(r, "right", 34, 10)
    picked(r, "cell", "cell_rc_02", "r34")
    mark(r, 61, 32, "r34_pe_da_parede_leste")
    r.shot("r34_pe_da_parede_leste")
    look(r, 12)
    r.press("move_up")
    r.press("move_right")
    r.hold("jump", 12)
    r.wait(4)
    r.release("move_right")
    r.wait(150)
    r.shot("r35_garras_na_parede_leste")
    r.wait(146)
    r.press("move_left")
    r.hold("jump", 12)
    r.release("move_up")
    r.wait(20)
    r.release("move_left")
    r.wait(24)
    mark(r, 58, 8, "r36_plataforma_alta")
    walk(r, "left", 37, 8)
    mark(r, 53, 8, "r37_beira_da_plataforma_alta")
    r.shot("r37_dado_no_alto")
    stage(r, "rc15", root)
    if STOP == "rcd":
        base = r.f
        for k in range(25):
            r.add(expect_call=root + "/Player.get", args=["global_position"], equals="?", label="q%02d" % k)
            r.wait(3)
        r.at(base)
    t0 = r.f
    r.press("move_left")
    r.hold("jump", 11)
    r.wait(1)
    r.press("jump")
    r.at(t0 + 23)
    r.release("move_left")
    r.at(t0 + 28)
    r.release("jump")
    r.at(t0 + 33)
    r.press("move_right")
    r.tap("dash", 3, 0)
    r.at(t0 + 46)
    r.release("move_right")
    r.wait(30)
    stage(r, "rcd", root)
    picked(r, "research", "data_rc_01", "r38")
    mark(r, 53, 8, "r38_voltou_com_o_dado")
    r.shot("r38_voltou_com_o_dado")
    walk(r, "right", 30, 8)
    mark(r, 57, 8, "r39_debaixo_da_torre_alta")
    r.tap("move_left", 2, 4)
    r.press("jump")
    r.wait(14)
    r.press("beam")
    r.wait(3)
    r.shot("r39_feixe_no_pulo")
    r.release("beam")
    r.wait(1)
    r.release("jump")
    r.wait(24)
    rc.check(r, ARGOS + "/../Entities/Cx2Armored.is_shut_down", True, "r39_torre_alta_atordoada")
    r.interact(20)
    r.shot("r40_ultima_sobrecarga")
    if STOP:
        r.add(expect_call=ARGOS + ".time_left", equals="?", label="tempo_final")
    d.wait_call(r, ARGOS + ".is_defeated", True, "r40_argos_vencido", 5)
    rc.check(r, ARGOS + ".coupler_overloaded", True, "r40_acoplador_alto_queimado",
             ["rc_coupler_03"])
    picked(r, "research", "data_rc_01", "r40")
    picked(r, "log", "log_rc_01", "r40")
    r.wait(30)
    r.shot("r41_argos_apagando")
    r.wait(150)
    r.shot("r41_nucleo_racha")
    r.wait(200)
    r.shot("r42_silencio")
    d.wait_scene(r, rc.CMD, "r43_sala_de_comando", 40)
    r.wait(40)
    r.shot("r43_sala_de_comando")
    stage(r, "rc16", root)


def reactor_chapter():
    r = R()
    state = ds.full_state("s05", "reator")
    state["flags"].pop("root_door_open_door_reactor", None)
    state["checkpoint"] = {"scene": rc.HUB, "dock_id": "core_dock_wing"}
    rc.setup(r, state)
    r.scene(rc.HUB)
    try:
        reactor_hub(r)
        reactor_approach(r)
        reactor_arena(r)
        d.finish(r, r.f + 2)
    except Stop:
        return r
    return r


MEM_ROOT = "MemoryCore"
PROTOCOL = "MemoryCore/Protocol"
MEMORY_UNTIL = 7700


def f64_events():
    events = json.load(open(os.path.join(rc.QA, "f64_memory.json"), encoding="utf-8"))
    kept = []
    for event in events:
        frame = event.get("frame", 0)
        if frame <= 1 and (event.get("call") in rc.SETUP_CALLS or "scene" in event):
            continue
        if event.get("quit") or frame > MEMORY_UNTIL:
            continue
        copy = dict(event)
        if "screenshot" in copy:
            copy["screenshot"] = "orig_" + copy["screenshot"]
        if "label" in copy:
            copy["label"] = "orig_" + copy["label"]
        kept.append(copy)
    return kept


def splice(r, events, inserts):
    shift = 0
    pending = sorted(inserts, key=lambda item: item[0])
    index = 0
    skip_until = None
    for event in events:
        frame = event["frame"]
        while index < len(pending):
            cut, builder, resume = pending[index]
            late = frame > cut or (frame == cut and "action" in event)
            if not late:
                break
            r.at(cut + shift)
            builder(r)
            shift = r.f - resume
            skip_until = resume
            index += 1
        if skip_until is not None and frame < skip_until:
            continue
        copy = dict(event)
        copy["frame"] = frame + shift
        r.ev.append(copy)
    return shift


def memory_log_detour(r):
    root = MEM_ROOT
    stage(r, "m1", root)
    if STOP == "m2":
        base = r.f
        for k in range(30):
            r.add(expect_call=root + "/Player.get", args=["global_position"], equals="?",
                  label="q%02d" % k)
            r.add(expect_call=PROTOCOL + ".front_position", args=[1], equals="?",
                  label="f%02d" % k)
            r.wait(3)
        r.at(base)
    walk(r, "right", 18, 12)
    r.press("move_left")
    r.wait(20)
    t0 = r.f
    r.hold("jump", 14)
    r.at(t0 + 16)
    r.hold("jump", 14)
    r.at(t0 + 32)
    r.tap("dash", 3, 0)
    r.at(t0 + 60)
    r.release("move_left")
    r.wait(14)
    mark(r, 27, 24, "m02_nicho_do_registro", root)
    walk(r, "left", 18, 10)
    mark(r, 25, 24, "m03_terminal_do_registro", root)
    r.shot("m03_terminal_do_registro")
    rc.read_log(r, "log_mem_01", 14)
    r.wait(10)
    rc.silent(r, "m03_registro_lido")
    picked(r, "log", "log_mem_01", "m03")
    if STOP:
        r.add(expect_call=PROTOCOL + ".front_position", args=[1], equals="?", label="frente")
    walk(r, "right", 18, 4)
    stage(r, "m3", root)
    r.press("move_right")
    r.hold("jump", 14)
    r.wait(2)
    r.hold("jump", 14)
    r.wait(10)
    r.release("move_right")
    r.wait(20)
    mark(r, 32, 20, "m04_voltou_a_subida", root)
    walk(r, "right", 16, 8)
    stage(r, "m4", root)


def memory_look_exit(r):
    r.shot("m05_fase_2_firewall")
    look(r, 120)


def memory_hop_data(r):
    base = r.f
    r.press("jump")
    r.wait(8)
    r.release("jump")
    r.wait(6)
    r.shot("m06_dado_sobre_a_passarela")
    r.wait(20)
    r.hold("move_right", 11)
    r.at(base)


def memory_look_recall(r):
    r.shot("m07_fase_3_corredor")
    look(r, 120)


def memory_look_done(r):
    r.shot("m08_log_final_completo")
    look(r, 90)


def memory_chapter():
    r = R()
    state = ds.full_state("s04", "memoria")
    rc.setup(r, state)
    r.scene(rc.MEM)
    r.at(12)
    rc.dialogue(r, "mem_enter", "m00_entrada")
    r.at(14)
    r.accept(rc.dialogue_lines("mem_enter") * 2 + 1, 8)
    try:
        splice(r, f64_events(), [(1195, memory_log_detour, 1455),
                                  (1727, memory_look_exit, 1727),
                                  (2878, memory_hop_data, 2878),
                                  (3810, memory_look_recall, 3810),
                                  (6400, memory_look_done, 6400)])
        r.at(max(e["frame"] for e in r.ev) - 2)
        picked(r, "research", "data_mem_01", "m09")
        picked(r, "log", "log_mem_01", "m09")
        picked(r, "log", "log_mem_final", "m09")
        rc.check(r, "GameState.has_ability", True, "m09_acesso_root", ["root_access"])
        d.finish(r, max(e["frame"] for e in r.ev) + 2)
    except Stop:
        return r
    return r


FINAL_TIER = "most"


def full_collection_checks(r, prefix):
    for item in ds.items_before("final"):
        kind = {"data": "research", "log": "log", "capacitor": "capacitor",
                "plate": "armor_plate"}[item.split("_")[0]]
        picked(r, kind, item, prefix)
    rc.check(r, "GameState.secrets_found", 5, prefix + "_5_segredos")
    rc.check(r, "GameState.capacitors_installed", 4, prefix + "_4_capacitores")
    rc.check(r, "GameState.plates_installed", 4, prefix + "_4_placas")


def final_epilogue(r):
    r.add(expect_call="EndingEpilogue.tier", equals=FINAL_TIER, label="12_faixa_" + FINAL_TIER)
    r.wait(10)
    r.shot("12_epilogo")
    d.wait_call(r, "EndingEpilogue.stage_name", "names", "13_quarenta_nomes", 240)
    r.wait(20)
    r.shot("13_nomes")
    r.wait(400)
    r.shot("13_nomes_meio")
    d.wait_call(r, "EndingEpilogue.stage_name", "question", "14_pergunta", 240)
    r.wait(120)
    r.shot("14_pergunta")
    r.tap("ui_accept", 3, 20)
    d.wait_scene(r, f66.CREDITS, "15_creditos", 30)
    r.wait(300)
    r.shot("15_creditos")
    d.wait_scene(r, f66.MENU, "16_menu_depois_dos_creditos", 400)
    r.wait(90)
    r.add(expect_call="MainMenu/CompletedMark.is_visible_in_tree", equals=True,
          label="16_menu_marca_jogo_concluido")
    r.shot("16_menu")
    r.wait(10)
    r.quit()


def final_chapter(ending):
    r = R()
    state = ds.full_state("s06", "final")
    state["checkpoint"] = {}
    state["flags"].pop("dlg_cmd_enter", None)
    rc.setup(r, state)
    r.scene(rc.CMD)
    r.at(40)
    r.expect_scene(rc.CMD)
    full_collection_checks(r, "01_colecao")
    rc.dialogue(r, "cmd_enter", "07_entrada")
    r.at(50)
    r.accept(2, 16)
    r.at(96)
    r.expect(2, 12, "02_entrada_sem_fala")
    f66.choose(r, ending)
    f66.cutscene(r, ending)
    final_epilogue(r)
    return r


def reinforce(r, every=8):
    events = sorted(enumerate(r.ev), key=lambda item: (item[1]["frame"], item[0]))
    opened = {}
    extra = []
    for _, event in events:
        action = event.get("action", "")
        if not action.startswith("move_"):
            continue
        if event.get("pressed"):
            opened.setdefault(action, event["frame"])
        elif action in opened:
            start = opened.pop(action)
            for frame in range(start + every, event["frame"], every):
                extra.append({"frame": frame, "action": action, "pressed": True})
    r.ev.extend(extra)


PLAYLIST = [
    ("memoria", "Núcleo de Memória: Protocolo Luto e Acesso Root", 0),
    ("reator", "Núcleo do Reator: ARGOS", 20),
    ("final", "Sala de comando, final e créditos", 0),
]


def write_dev_playlist():
    chapters = []
    for key, title, wait in PLAYLIST:
        script = d.RES_DEMO + ("final_{final}.json" if key == "final" else key + ".json")
        chapters.append({"id": key, "titulo": title, "roteiro": script,
                         "espera_transicao": wait})
    data = {"nome": "_dev_finais", "capitulos": chapters}
    with open(os.path.join(d.DEMO, "_dev_finais.json"), "w", encoding="utf-8") as fh:
        fh.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main():
    builders = {"reator": reactor_chapter, "memoria": memory_chapter,
                "final_semeadura": lambda: final_chapter("seeding"),
                "final_transmissao": lambda: final_chapter("transmission")}
    only = os.environ.get("DEMO_ONLY", "")
    for key, builder in builders.items():
        if only and only != key:
            continue
        r = builder()
        reinforce(r)
        d.write(r, ("_try_" + key) if STOP else key)
    if not STOP and not only:
        write_dev_playlist()


if __name__ == "__main__":
    main()

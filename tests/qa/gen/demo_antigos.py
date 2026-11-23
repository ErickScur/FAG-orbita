import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import demo as d
import demo_states as ds
import review_campaign as rc
from qa_build import R

BEAM_CORRIDOR = 40
LOG2_RUN = 83
CLIMB_FRAMES = 190
C_RUN = 96
NODE_RUN = 120
TUT_JUMP_RUN = 108
TUT_PLATFORM_RUN = 30
TUT_LOG_RUN = 90
TUT_CONSOLE_RUN = 40
LIFT_BOARD = 215
LIFT_TOP = 506
LIFT_BACK = 582
LIFT_DOWN_RUN = 77
TUNNEL_BEAM_RUN = 8
DASH_RUN = 148
EXIT_RUN = 40
PHARMACY_RUN = 300
PHARMACY_BACK = 300
STAIRS_RUN = 42
UPPER_RUN = 227
UPPER_BACK = 190
UPPER_EDGE = 40
EAST_RUN = 260
RL_VENT_1 = 196
RL_VENT_2 = 56
RL_BLOCK_2 = 50
RL_DROP_WAIT = 50
RL_BEAM_A = 8
RL_BEAM_B = 56
RL_LIFT_STEP = 22
RL_LIFT_RIDE = 270
RL_DASH = 20
RL_DASH_2 = 40
RL_VENT_WAIT = 220
RL_BLOCK_3 = 4
RL_PIT = 97
RL_DOOR_RUN = 80
GAP_RUN = 130
GAP_AFTER = 94
DEV = os.environ.get("DEMO_DEV", "")
TRACE = os.environ.get("DEMO_TRACE", "")


class Run:
    def __init__(self, scene):
        self.r = R()
        self.scene = scene
        self.root = rc.ROOTS.get(scene, "")
        self.player = self.root + "/Player"

    def probe(self, label):
        if DEV:
            self.r.add(expect_call=self.player + ".get", args=["global_position"], equals="?",
                       label="P_" + label)

    def probe_node(self, path, label, prop="global_position"):
        if DEV:
            self.r.add(expect_call=self.root + "/" + path + ".get", args=[prop], equals="?",
                       label="N_" + label)

    def hop(self, label, direction=None, steer=0, hold=14, pre=2):
        r = self.r
        if direction:
            r.press("move_" + direction)
            r.wait(pre)
        r.press("jump")
        r.wait(hold)
        r.release("jump")
        if direction:
            r.wait(max(0, steer - hold))
            r.release("move_" + direction)
        r.wait(4)
        self.land(label)

    def land(self, label, timeout=6):
        d.wait_call(self.r, self.player + ".is_on_floor", True, label, timeout)

    def mark(self, x, y, label, tol=1):
        self.r.expect(x, y, label, tol)
        self.probe(label)


def add_trace(run, every=4):
    if not DEV:
        return
    last = max(e["frame"] for e in run.r.ev)
    saved = run.r.f
    for frame in range(2, last + 1, every):
        run.r.f = frame
        run.probe("t%d" % frame)
    run.r.f = saved


def finish_dev(run):
    run.r.wait(30)
    run.probe("fim")
    if DEV:
        for prop in ("integrity", "charge", "collected_ids", "flags"):
            run.r.add(expect_call="GameState.get", args=[prop], equals="?", label="G_" + prop)
    run.r.quit()
    add_trace(run, int(TRACE or 4))


MENU_VALUES = "/HUD/ChassisMenu/Root/Center/Panel/Body/Columns/"
MENU_LABELS = {
    "logs": "Right/LogsRow/LogsValue",
    "research": "Right/ResearchRow/ResearchValue",
    "capacitors": "Left/ChargeRow/CapacitorsValue",
    "plates": "Left/IntegrityRow/PlatesValue",
}
TOTALS = {"logs": 13, "research": 12, "capacitors": 4, "plates": 4}


def expected_counts(chapter):
    done = ds.items_before(chapter) + ds.CHAPTER_ITEMS.get(chapter, [])
    return {
        "logs": len([i for i in done if i.startswith("log_")]),
        "research": len([i for i in done if i.startswith("data_")]),
        "capacitors": len([i for i in done if i.startswith("capacitor_")]),
        "plates": len([i for i in done if i.startswith("plate_")]),
    }


def progress_check(run, chapter, prefix, look=110):
    r = run.r
    r.tap("map", 3, 30)
    rc.check(r, run.root + "/HUD/ChassisMenu.get", True, prefix + "_terminal_do_chassi",
             ["is_open"])
    counts = expected_counts(chapter)
    for key, path in MENU_LABELS.items():
        rc.check(r, run.root + MENU_VALUES + path + ".get_text",
                 "%d/%d" % (counts[key], TOTALS[key]), "%s_%s_%d" % (prefix, key, counts[key]))
    for secret in ds.CHAPTER_SECRETS.get(chapter, []):
        rc.check(r, "GameState.has_secret", True, prefix + "_" + secret, [secret])
    r.shot(prefix + "_terminal_do_chassi")
    r.wait(look)
    r.tap("ui_cancel", 3, 30)
    rc.check(r, run.root + "/HUD/ChassisMenu.get", False, prefix + "_chassi_fechado",
             ["is_open"])


def restore_node(run, seq_id, prefix):
    r = run.r
    r.interact(10)
    r.shot(prefix + "_religando")
    r.wait(120)
    r.shot(prefix + "_setor_religado")
    d.wait_call(r, "DialogueManager.is_active", True, prefix + "_fala_final", 30)
    r.wait(20)
    rc.dialogue(r, seq_id, prefix + "_fala")
    r.accept(rc.dialogue_lines(seq_id) * 2 + 1, 16)


def end_chapter(run):
    if DEV:
        finish_dev(run)
    else:
        d.finish(run.r, run.r.f)
    return run.r


def walk_into_dialogue(r, direction, seq_id, label, timeout=12):
    r.press("move_" + direction)
    d.wait_call(r, "DialogueManager.get", seq_id, label + "_chegou", timeout, ["_current_id"])
    r.release("move_" + direction)
    r.wait(16)
    rc.dialogue(r, seq_id, label)
    r.shot(label)
    r.accept(rc.dialogue_lines(seq_id) * 2 + 1, 14)
    r.wait(20)
    rc.check(r, "DialogueManager.queue_size", 0, label + "_fila_vazia")


def accept_dialogue(r, seq_id, label, gap=14):
    rc.dialogue(r, seq_id, label)
    r.wait(10)
    r.accept(rc.dialogue_lines(seq_id) * 2 + 1, gap)
    r.wait(20)
    rc.silent(r, label + "_fim")


def terminal(r, steps, label, look=70):
    r.interact(30)
    r.shot(label + "_terminal")
    for step in steps:
        if step == "i":
            r.tap("interact", 2, 24)
        else:
            r.tap("move_" + step, 2, 10)
    r.wait(30)
    r.shot(label + "_terminal_ajustado")
    r.tap("ui_cancel", 3, 20)
    r.wait(look)


def read_log(r, log_id, label):
    r.interact(12)
    r.wait(10)
    r.shot(label)
    r.accept(rc.lines_of(log_id) * 2 + 1, 12)
    r.wait(20)


def estufa():
    run = Run(rc.GH)
    r = run.r
    rc.setup(r, ds.full_state("s00", "estufa"))
    r.scene(rc.GH)
    r.at(20)
    r.expect_scene(rc.GH)
    r.at(50)
    accept_dialogue(r, "gh_enter", "e01_entrada")
    run.mark(4, 61, "e01_chegada")
    r.shot("e01_chegada")
    r.wait(20)
    r.press("move_right")
    r.wait(105)
    r.hold("jump", 16)
    r.wait(20)
    r.release("move_right")
    run.land("e02_pousou_apos_mureta")
    r.wait(10)
    run.mark(20, 61, "e02_console_a")
    terminal(r, ["i", "down", "down", "i"], "e03_console_a")
    r.shot("e03_trepadeira_crescendo")
    r.wait(106)
    r.shot("e04_sr3_chegando")
    r.tap("beam", 3, 12)
    run.probe_node("Entities/@CharacterBody2D@92", "sr3_baixo")
    run.probe_node("Entities/@CharacterBody2D@92", "sr3_off", "_shutdown_left")
    r.shot("e04_feixe_no_sr3")
    r.wait(20)
    r.press("move_right")
    r.wait(66)
    r.release("move_right")
    r.shot("e05_dado_gh_01")
    r.wait(30)
    run.mark(27, 61, "e05_dado_gh_01")
    r.press("move_left")
    r.wait(66)
    r.hold("jump", 16)
    r.wait(63)
    r.release("move_left")
    run.land("e06_antes_do_patamar")
    r.wait(16)
    run.mark(11, 61, "e06_sob_o_patamar")
    run.hop("e06_patamar")
    r.wait(14)
    run.hop("e07_trepadeira", "right", 20)
    r.wait(14)
    run.hop("e07_plataforma_1", "right", 14)
    r.wait(12)
    run.hop("e07_plataforma_2", "left", 6)
    r.wait(12)
    run.hop("e08_viveiro")
    run.mark(14, 51, "e08_viveiro")
    r.shot("e08_viveiro")
    r.wait(20)
    r.hold("move_left", 120)
    r.wait(20)
    r.shot("e09_segredo_capacitor")
    run.mark(2, 51, "e09_segredo_capacitor")
    r.wait(30)
    r.hold("move_right", 210)
    r.wait(12)
    run.mark(26, 51, "e10_pe_da_escada")
    run.hop("e10_degrau_1")
    r.wait(10)
    run.hop("e10_degrau_2", "right", 16)
    r.wait(10)
    run.hop("e10_degrau_3", "right", 16)
    r.wait(10)
    run.hop("e10_degrau_4", "right", 10, pre=10)
    r.wait(10)
    run.hop("e11_galeria")
    run.mark(33, 41, "e11_galeria")
    r.shot("e11_galeria")
    r.wait(24)
    r.hold("move_right", 14)
    r.wait(21)
    r.shot("e12_sr3_da_galeria")
    r.tap("beam", 3, 12)
    r.wait(10)
    r.hold("move_right", 54)
    r.wait(16)
    run.mark(41, 41, "e13_log_gh_01")
    read_log(r, "log_gh_01", "e13_log_gh_01")
    rc.silent(r, "e13_log_lido")
    r.wait(10)
    r.press("move_left")
    r.wait(GAP_RUN)
    r.hold("jump", 16)
    r.wait(GAP_AFTER)
    r.release("move_left")
    run.land("e14_depois_do_vao")
    r.wait(16)
    run.mark(13, 41, "e14_console_b")
    terminal(r, ["down", "i", "down", "down", "i"], "e15_console_b", 30)
    r.shot("e15_trepadeira_alta")
    r.wait(60)
    r.hold("move_right", 50)
    r.wait(10)
    run.mark(19, 41, "e16_pe_da_trepadeira_alta")
    run.hop("e16_patamar_da_copa")
    r.wait(12)
    run.hop("e16_topo_da_trepadeira_alta", "right", 20)
    r.wait(12)
    run.hop("e16_copa_1")
    r.wait(10)
    run.hop("e16_copa_2")
    r.wait(10)
    run.hop("e17_copa")
    run.mark(21, 31, "e17_copa")
    r.shot("e17_copa")
    r.wait(20)
    r.hold("move_right", 215)
    r.wait(10)
    r.shot("e18_segredo_da_copa")
    run.mark(45, 31, "e18_segredo_da_copa")
    r.wait(30)
    r.hold("move_left", 310)
    r.wait(12)
    run.mark(9, 31, "e19_pe_da_torre")
    for step in range(1, 5):
        run.hop("e19_torre_%d" % step)
        r.wait(8)
    run.hop("e20_corredor")
    run.mark(9, 21, "e20_corredor")
    r.shot("e20_corredor_escuro")
    r.wait(50)
    r.shot("e20_botanico")
    r.wait(50)
    r.press("move_right")
    r.wait(71)
    r.hold("jump", 16)
    run.land("e21_depois_do_poco_1")
    r.release("move_right")
    run.probe_node("Entities/SR3", "sr3_corredor")
    r.wait(BEAM_CORRIDOR)
    r.shot("e21_sr3_do_corredor")
    r.tap("beam", 3, 0)
    run.probe_node("Entities/SR3", "sr3_off", "_shutdown_left")
    r.wait(16)
    r.press("move_right")
    r.wait(28)
    r.hold("jump", 16)
    run.land("e22_depois_do_poco_2")
    r.wait(LOG2_RUN)
    r.release("move_right")
    r.wait(16)
    run.mark(38, 21, "e22_log_gh_02")
    read_log(r, "log_gh_02", "e22_log_gh_02")
    r.wait(10)
    rc.dialogue(r, "gh_claws", "e23_garras")
    rc.check(r, "GameState.has_ability", True, "e23_garras_liberadas", ["magnetic_claws"])
    r.shot("e23_garras_liberadas")
    r.wait(20)
    r.hold("move_right", 60)
    r.wait(10)
    run.mark(44, 21, "e24_pe_da_parede")
    r.press("move_up")
    r.wait(CLIMB_FRAMES)
    r.shot("e24_escalando")
    r.press("move_left")
    r.wait(2)
    r.hold("jump", 14)
    r.release("move_up")
    run.land("e25_plataforma_do_dado")
    r.release("move_left")
    run.mark(41, 5, "e25_dado_gh_03")
    r.shot("e25_dado_gh_03")
    r.wait(24)
    r.hold("move_left", C_RUN)
    r.wait(14)
    run.mark(31, 11, "e26_console_c")
    terminal(r, ["down", "down", "down", "i", "down", "down", "i"], "e26_console_c", 40)
    r.press("move_left")
    r.wait(46)
    r.hold("jump", 16)
    run.land("e27_depois_do_vao_do_no")
    r.wait(NODE_RUN)
    r.release("move_left")
    r.wait(16)
    run.mark(7, 11, "e27_no_do_setor")
    r.shot("e27_no_do_setor")
    progress_check(run, "estufa", "e28")
    r.wait(20)
    restore_node(run, "gh_restored", "e29")
    return end_chapter(run)


HAB_DOCK_X = 95


def hub_chapter(key, base, seq_id, objective_text, portal_x, prefix):
    run = Run(rc.HUB)
    r = run.r
    state = ds.full_state(base, key)
    state["flags"].pop("dlg_" + seq_id, None)
    state["checkpoint"] = {}
    rc.setup(r, state)
    r.scene(rc.HUB)
    r.at(20)
    d.wait_call(r, "DialogueManager.get", seq_id, prefix + "_a_fala_de_retorno", 20,
                ["_current_id"])
    r.wait(30)
    run.mark(HAB_DOCK_X, 11, prefix + "_a_doca")
    rc.dialogue(r, seq_id, prefix + "_a")
    r.shot(prefix + "_a_volta_ao_hub")
    r.accept(rc.dialogue_lines(seq_id) * 2 + 1, 14)
    r.wait(24)
    rc.silent(r, prefix + "_b")
    rc.objective(r, objective_text, prefix + "_b_objetivo")
    r.wait(16)
    r.hold("move_right", int((portal_x - HAB_DOCK_X) * 16 / 110.0 * 60) + 2)
    r.wait(20)
    run.mark(portal_x, 11, prefix + "_c_portal")
    r.shot(prefix + "_c_portal_seguinte")
    r.wait(10)
    r.interact(2)
    return end_chapter(run)


def hub_lab():
    return hub_chapter("hub_lab", "s01", "core_return", "Chegar ao Laboratório", 109, "hl")


def hub_enfermaria():
    return hub_chapter("hub_enfermaria", "s02", "core_return_lab", "Chegar à Enfermaria", 117,
                       "he")


LAB_NODE_FRAME = 8143
LAB_MARKS = [(2100, 56, 39, "salto_da_galeria"), (2522, 67, 41, "pe_do_pilar"), (2702, 67, 29, "escalando"), (3600, 82, 41, "esperando_elevador"), (3800, 82, 41, "elevador")]


def laboratorio():
    run = Run(rc.LAB)
    r = run.r
    rc.setup(r, ds.full_state("s01", "laboratorio"))
    r.scene(rc.LAB)
    rc.replay(r, "f60_lab", until=LAB_NODE_FRAME)
    for frame, x, y, label in LAB_MARKS:
        r.at(frame)
        r.expect(x, y, "l_" + label)
    r.at(LAB_NODE_FRAME + 1)
    run.probe("no")
    progress_check(run, "laboratorio", "l30")
    r.wait(20)
    restore_node(run, "lab_restored", "l31")
    return end_chapter(run)


def replay_range(r, original, start, end, offset):
    events = json.load(open(os.path.join(rc.QA, original + ".json"), encoding="utf-8"))
    for event in events:
        frame = event.get("frame", 0)
        if frame < start or frame > end or event.get("quit"):
            continue
        if frame <= 1 and (event.get("call") in rc.SETUP_CALLS or "scene" in event):
            continue
        copy = dict(event)
        copy["frame"] = frame + offset
        if "screenshot" in copy:
            copy["screenshot"] = "orig_" + copy["screenshot"]
        if "label" in copy:
            copy["label"] = "orig_" + copy["label"]
        r.ev.append(copy)
    r.f = end + offset


INF_CONSOLE_B = 1150
INF_LIFT_ON = 1247
INF_LOG_DONE = 2806
INF_EAST_WALL = 3085
INF_SHAFT_TOP = 3990
INF_NODE = 5870
INF_MARKS = [(642, 35, 46, "ala_de_leitos"), (2442, 68, 46, "esperando_a_maca")]


def enfermaria():
    run = Run(rc.INF)
    r = run.r
    rc.setup(r, ds.full_state("s02", "enfermaria"))
    r.scene(rc.INF)
    replay_range(r, "f61_infirmary", 2, INF_CONSOLE_B, 0)
    run.probe("console_b")
    r.wait(2)
    terminal(r, ["i", "down", "down", "down", "i"], "n03_console_b_farmacia", 20)
    r.hold("move_right", PHARMACY_RUN)
    r.wait(16)
    run.mark(84, 46, "n04_farmacia")
    r.shot("n04_dado_inf_01")
    r.wait(30)
    r.hold("move_left", PHARMACY_BACK)
    r.wait(16)
    run.mark(65, 46, "n05_console_b")
    r.interact(30)
    r.shot("n05_console_b_elevador")
    for step in ["down", "down", "down", "i", "up"]:
        if step == "i":
            r.tap("interact", 2, 24)
        else:
            r.tap("move_" + step, 2, 10)
    replay_range(r, "f61_infirmary", INF_LIFT_ON - 3, INF_LOG_DONE, r.f - (INF_LIFT_ON - 3))
    run.probe("log_lido")
    rc.check(r, "GameState.has_ability", True, "n08_nucleo_aquecido", ["heated_core"])
    r.shot("n08_nucleo_aquecido")
    r.wait(20)
    r.hold("move_right", STAIRS_RUN)
    r.wait(14)
    run.mark(94, 16, "n09_pe_da_escada")
    for step in range(1, 5):
        run.hop("n09_degrau_%d" % step)
        r.wait(8)
    run.hop("n10_sala_de_cima")
    run.mark(94, 6, "n10_sala_de_cima")
    r.shot("n10_sala_de_cima")
    r.wait(24)
    r.press("move_left")
    r.wait(39)
    r.hold("jump", 16)
    run.land("n11_gelo_fino")
    r.wait(UPPER_RUN)
    r.release("move_left")
    r.wait(16)
    run.mark(65, 6, "n12_log_inf_02")
    read_log(r, "log_inf_02", "n12_log_inf_02")
    r.wait(16)
    r.press("move_right")
    r.wait(UPPER_BACK)
    r.hold("jump", 16)
    run.land("n13_volta_pelo_gelo")
    r.wait(UPPER_EDGE)
    r.release("move_right")
    run.land("n13_plataforma")
    r.wait(10)
    r.tap("move_down", 3, 6)
    run.land("n13_desceu")
    r.wait(10)
    run.mark(95, 16, "n13_quarentena")
    r.hold("move_right", EAST_RUN)
    r.wait(10)
    run.mark(108, 29, "n14_fundo_do_poco_leste")
    replay_range(r, "f61_infirmary", INF_EAST_WALL + 1, INF_SHAFT_TOP,
                 r.f - (INF_EAST_WALL + 1))
    run.mark(78, 29, "n15_topo_do_poco_do_no")
    r.shot("n15_poco_vizinho")
    r.wait(20)
    r.press("jump")
    r.wait(6)
    r.press("move_left")
    r.wait(10)
    r.release("jump")
    run.land("n16_plataforma_do_poco_oeste")
    r.release("move_left")
    r.wait(12)
    r.wait(16)
    run.mark(76, 27, "n16_topo_do_pilar")
    run.hop("n16_plataforma_oeste", "left", 12)
    r.wait(12)
    run.mark(74, 29, "n16_plataforma_oeste")
    r.shot("n16_poco_oeste")
    r.tap("move_down", 3, 6)
    run.land("n17_fundo_do_poco_oeste")
    r.wait(14)
    r.hold("move_left", 12)
    r.wait(16)
    run.mark(73, 37, "n17_dado_inf_02")
    r.shot("n17_dado_inf_02")
    r.wait(20)
    run.hop("n18_subida_1", "right", 14)
    r.wait(10)
    for step in range(2, 5):
        run.hop("n18_subida_%d" % step)
        r.wait(8)
    run.mark(75, 29, "n18_saida_do_poco_oeste")
    run.hop("n18_pilar", "right", 10)
    r.wait(10)
    r.press("move_right")
    d.wait_call(r, run.player + ".is_on_floor", False, "n18_desce_do_pilar", 3)
    r.release("move_right")
    run.land("n18_poco_do_no")
    r.wait(8)
    r.hold("move_left", 25)
    r.wait(10)
    run.probe("encostado_no_pilar")
    r.hold("move_right", 8)
    r.wait(16)
    run.mark(78, 29, "n19_de_volta_ao_poco_do_no")
    replay_range(r, "f61_infirmary", INF_SHAFT_TOP + 1, INF_NODE, r.f - (INF_SHAFT_TOP + 1))
    run.probe("no")
    r.wait(2)
    progress_check(run, "enfermaria", "n20")
    r.wait(20)
    restore_node(run, "inf_restored", "n21")
    end = r.f
    for frame, x, y, label in INF_MARKS:
        r.at(frame)
        r.expect(x, y, "n_" + label)
    r.at(end)
    return end_chapter(run)


REVISIT_ROOT_FLAGS = ["root_door_open_lab_root_door", "root_door_open_door_reactor"]


def revisita_lab():
    run = Run(rc.HUB)
    r = run.r
    state = ds.full_state("s05", "revisita_lab")
    for flag in REVISIT_ROOT_FLAGS:
        state["flags"].pop(flag, None)
    state["checkpoint"] = {}
    rc.setup(r, state)
    r.scene(rc.HUB)
    r.at(40)
    r.expect_scene(rc.HUB)
    r.wait(30)
    rc.silent(r, "rl00")
    run.mark(HAB_DOCK_X, 11, "rl00_doca")
    r.shot("rl00_hub")
    r.wait(10)
    r.hold("move_right", int((109 - HAB_DOCK_X) * 16 / 110.0 * 60) + 2)
    r.wait(16)
    run.mark(109, 11, "rl01_portal_do_lab")
    r.shot("rl01_portal_do_lab")
    r.interact(2)
    d.wait_scene(r, rc.LAB, "rl02_laboratorio", 20)
    r.wait(60)
    run.root = rc.ROOTS[rc.LAB]
    run.player = run.root + "/Player"
    run.mark(2, 41, "rl02_entrada_do_lab")
    r.shot("rl02_laboratorio_religado")
    r.wait(10)
    r.hold("move_right", 88)
    r.wait(16)
    run.mark(12, 41, "rl03_console_a")
    terminal(r, ["down", "down", "down", "down", "i", "down", "i", "up", "up", "i", "up", "up",
                 "i"], "rl03_console_a_alivio", 40)
    r.press("move_right")
    r.wait(RL_VENT_1)
    r.hold("jump", 16)
    run.land("rl04_poco")
    r.wait(RL_VENT_2)
    r.hold("jump", 16)
    run.land("rl04_bloco")
    r.wait(RL_BLOCK_2)
    r.hold("jump", 16)
    run.land("rl05_bloco_da_galeria")
    r.release("move_right")
    r.wait(10)
    run.mark(56, 39, "rl05_bloco_da_galeria")
    r.shot("rl05_dois_sr3")
    r.wait(RL_DROP_WAIT)
    r.press("move_right")
    d.wait_call(r, run.player + ".is_on_floor", False, "rl06_desce_do_bloco", 3)
    run.land("rl06_chao_da_galeria")
    r.wait(RL_BEAM_A)
    r.release("move_right")
    r.shot("rl06_feixe_sr3_a")
    r.tap("beam", 3, 6)
    run.probe_node("Entities/SR3", "a_off", "_shutdown_left")
    run.probe("beam_a")
    r.press("move_right")
    r.wait(RL_BEAM_B)
    r.release("move_right")
    r.shot("rl07_feixe_sr3_b")
    r.tap("beam", 3, 6)
    run.probe_node("Entities/@CharacterBody2D@135", "b_off", "_shutdown_left")
    r.wait(10)
    r.hold("move_right", 110)
    r.wait(6)
    run.hop("rl08_bloco_do_console", "right", 6, hold=8, pre=2)
    r.wait(12)
    run.mark(79, 40, "rl08_console_b")
    r.interact(30)
    r.shot("rl08_console_b")
    for step in ["down", "down", "down", "i", "up"]:
        if step == "i":
            r.tap("interact", 2, 24)
        else:
            r.tap("move_" + step, 2, 10)
    r.tap("interact", 2, 2)
    r.tap("ui_cancel", 2, 0)
    r.hold("move_right", RL_LIFT_STEP)
    run.land("rl09_no_elevador")
    r.wait(10)
    run.mark(82, 41, "rl09_no_elevador")
    r.shot("rl09_elevador_subindo")
    r.wait(RL_LIFT_RIDE)
    run.mark(82, 15, "rl10_topo_do_elevador")
    r.shot("rl10_corredor_de_cima")
    r.press("move_left")
    r.wait(RL_DASH)
    r.tap("dash", 3, 0)
    r.wait(RL_DASH_2)
    r.release("move_left")
    r.shot("rl11_jato_do_poco")
    r.wait(RL_VENT_WAIT)
    r.press("move_left")
    r.wait(8)
    r.press("jump")
    r.wait(4)
    r.tap("dash", 3, 0)
    r.wait(9)
    r.release("jump")
    run.land("rl11_poco_do_jato")
    r.wait(RL_BLOCK_3)
    r.hold("jump", 16)
    run.land("rl11_bloco_do_corredor")
    r.wait(RL_PIT)
    r.hold("jump", 18)
    run.land("rl11_poco_do_corredor")
    r.wait(RL_DOOR_RUN)
    r.release("move_left")
    r.wait(20)
    run.mark(38, 15, "rl12_comporta_root")
    rc.check(r, "GameState.is_root_door_open", False, "rl12_comporta_fechada", ["lab_root_door"])
    r.shot("rl12_comporta_root_fechada")
    r.wait(30)
    r.interact(30)
    rc.check(r, "GameState.is_root_door_open", True, "rl13_acesso_root_abriu",
             ["lab_root_door"])
    rc.check(r, "DialogueManager.is_active", False, "rl13_sem_reabrir_o_log")
    r.shot("rl13_comporta_root_aberta")
    r.wait(60)
    r.hold("move_left", 50)
    r.wait(16)
    run.mark(33, 15, "rl14_placa_lab")
    r.shot("rl14_placa_lab")
    r.wait(40)
    progress_check(run, "revisita_lab", "rl15")
    r.wait(20)
    return end_chapter(run)


def briefing(r):
    rc.setup(r, None)
    r.call("SaveManager.delete_save")
    r.scene(rc.MENU)
    r.at(30)
    r.expect_scene(rc.MENU)
    r.shot("t00_menu_sem_save")
    r.at(50)
    r.tap("ui_accept", 3, 10)
    r.at(d.BRIEFING_SKIP_FRAME - 10)
    for index, chars in enumerate(d.briefing_blocks()):
        d.wait_call(r, d.BRIEFING_NODE + ".is_block_complete", True,
                    "t00_briefing_bloco_%d" % (index + 1), 30)
        r.wait(d.reading_frames(chars))
        r.shot("t00_briefing_%d" % (index + 1))
        r.press("jump")
        r.wait(3)
        r.release("jump")
        r.wait(12)
    d.wait_scene(r, rc.HUB, "t01_nucleo_central", 30)
    d.wait_call(r, "DialogueManager.is_active", True, "t01_acordar", 20)
    r.wait(30)
    rc.dialogue(r, "core_wake", "t01_acordar")
    rc.objective(r, "Chegar à Estufa", "t01_objetivo_estufa")
    r.shot("t01_acordar")
    r.accept(rc.dialogue_lines("core_wake") * 2 + 1, 14)
    r.wait(30)
    rc.silent(r, "t01_depois_do_acordar")


def tutorial():
    run = Run(rc.HUB)
    r = run.r
    briefing(r)
    run.mark(5, 11, "t01_nascimento")
    r.wait(20)
    r.press("move_right")
    r.wait(TUT_JUMP_RUN)
    r.hold("jump", 16)
    run.land("t02_bloco")
    r.wait(TUT_PLATFORM_RUN)
    r.release("move_right")
    r.wait(20)
    run.mark(23, 9, "t02_plataforma")
    r.tap("move_down", 3, 10)
    run.land("t02_desceu")
    r.wait(20)
    r.hold("move_right", TUT_LOG_RUN)
    r.wait(20)
    run.mark(34, 11, "t03_log_core_01")
    read_log(r, "log_core_01", "t03_log_core_01")
    rc.silent(r, "t03_log_lido")
    r.wait(20)
    walk_into_dialogue(r, "right", "core_terminal_first", "t04_primeiro_terminal")
    run.mark(51, 11, "t04_sobre_o_elevador")
    r.hold("move_right", TUT_CONSOLE_RUN)
    r.wait(16)
    run.mark(55, 11, "t05_console")
    lift_on = r.f
    terminal(r, ["i", "down", "i"], "t05_console_elevador", 10)
    lift_on = lift_on + 33 + 26 + 12
    r.shot("t05_elevador_subindo")
    r.at(lift_on + LIFT_BOARD)
    r.hold("move_left", 50)
    r.wait(10)
    run.mark(50, 11, "t06_no_elevador")
    r.shot("t06_no_elevador")
    r.at(lift_on + LIFT_TOP)
    run.probe("t06_topo")
    r.hold("move_left", 26)
    r.wait(10)
    run.mark(47, 5, "t06_dado_core_01")
    r.shot("t06_dado_core_01")
    r.at(lift_on + LIFT_BACK)
    r.hold("move_right", LIFT_DOWN_RUN)
    r.wait(16)
    run.mark(56, 11, "t07_console_de_novo")
    terminal(r, ["down", "i", "down", "i"], "t07_console_porta", 50)
    walk_into_dialogue(r, "right", "core_alarm", "t08_alarme")
    walk_into_dialogue(r, "right", "hab_body", "t09_corpo")
    r.hold("move_right", 10)
    r.wait(14)
    run.mark(64, 11, "t10_traje")
    read_log(r, "log_hab_01", "t10_log_hab_01")
    r.wait(20)
    r.hold("move_right", 18)
    r.wait(10)
    run.mark(66, 11, "t11_entrada_do_tunel")
    r.shot("t11_sr3_no_tunel")
    r.wait(40)
    run.hop("t11_degrau", "right", 12, hold=7)
    run.probe("t11_degrau")
    run.probe_node("Entities/SR3", "sr3_tunel")
    r.hold("move_right", TUNNEL_BEAM_RUN)
    r.shot("t12_feixe")
    r.tap("beam", 3, 10)
    run.probe_node("Entities/SR3", "sr3_off", "_shutdown_left")
    r.wait(16)
    r.press("move_right")
    r.wait(DASH_RUN)
    r.shot("t13_poco")
    r.hold("jump", 12)
    r.wait(2)
    r.tap("dash", 3, 0)
    run.land("t13_depois_do_poco")
    r.wait(EXIT_RUN)
    r.release("move_right")
    r.wait(20)
    run.mark(96, 11, "t14_antes_da_saida")
    progress_check(run, "tutorial", "t14")
    r.wait(16)
    r.hold("move_right", 38)
    r.wait(16)
    run.mark(100, 11, "t15_portal_da_estufa")
    r.shot("t15_portal_da_estufa")
    r.interact(2)
    return end_chapter(run)
    return run.r


CHAPTERS = {
    "tutorial": tutorial,
    "estufa": estufa,
    "hub_lab": hub_lab,
    "laboratorio": laboratorio,
    "hub_enfermaria": hub_enfermaria,
    "enfermaria": enfermaria,
    "revisita_lab": revisita_lab,
}


TITLES = {key: (title, wait) for key, title, wait in d.OLD}
TITLES["revisita_lab"] = ("Laboratório: o Acesso Root abre a comporta", d.SECTOR_WAIT)


def write_playlist():
    data = {"nome": "_dev_antigos",
            "capitulos": [d.chapter_entry(key, TITLES[key][0], TITLES[key][1], "_dev_antigos")
                          for key in CHAPTERS]}
    with open(os.path.join(d.DEMO, "_dev_antigos.json"), "w", encoding="utf-8") as fh:
        fh.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main():
    names = sys.argv[1:] or list(CHAPTERS)
    for name in names:
        d.write(CHAPTERS[name](), name)
    write_playlist()


if __name__ == "__main__":
    main()

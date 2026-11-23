import copy
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import demo as d
import demo_states as ds
import review_campaign as rc
from qa_build import R

DEBUG = os.environ.get("DEMO_DEBUG", "") == "1"
DK_PLAYER = "Docks/Player"
BOSS = "Docks/Entities/Serralheiro"
CHASSIS = "HUD/ChassisMenu"
CHASSIS_ROWS = "/Root/Center/Panel/Body/Columns/"
LOOK = 40
SEE = 60
BEAM_DELAY = int(os.environ.get("BEAM_DELAY", "24"))
MEM_RUN = int(os.environ.get("MEM_RUN", "142"))
VEST_SR3 = "Docks/Entities/SR3"
HUB_CLIMB = int(os.environ.get("HUB_CLIMB", "100"))
HUB_DOCKS_RUN = int(os.environ.get("HUB_DOCKS_RUN", "210"))
DK_PLATE_RUN = int(os.environ.get("DK_PLATE_RUN", "40"))
DK_A_RUN = int(os.environ.get("DK_A_RUN", "140"))
DK_DIAG_RUN = int(os.environ.get("DK_DIAG_RUN", "16"))
DK_BREACH_RUN = int(os.environ.get("DK_BREACH_RUN", "60"))
EXIT_J1 = int(os.environ.get("EXIT_J1", "6"))
EXIT_J2 = int(os.environ.get("EXIT_J2", "120"))
EXIT_RUN = int(os.environ.get("EXIT_RUN", "230"))
STAIR_RUN = int(os.environ.get("STAIR_RUN", "44"))
STEP2_RUN = int(os.environ.get("STEP2_RUN", "26"))
STEP3_RUN = int(os.environ.get("STEP3_RUN", "12"))
DOOR_RUN = int(os.environ.get("DOOR_RUN", "30"))
HUB_PLATE_RUN = int(os.environ.get("HUB_PLATE_RUN", "30"))
GH_PORTAL_RUN = int(os.environ.get("GH_PORTAL_RUN", "66"))
GH_RUN = int(os.environ.get("GH_RUN", "66"))
GH_SECOND = int(os.environ.get("GH_SECOND", "14"))
GH_AIR = int(os.environ.get("GH_AIR", "12"))
GH_DOOR_RUN = int(os.environ.get("GH_DOOR_RUN", "40"))
GH_BACK_RUN = int(os.environ.get("GH_BACK_RUN", "132"))
GH_EXIT_RUN = int(os.environ.get("GH_EXIT_RUN", "92"))
VEST_DELAY = int(os.environ.get("VEST_DELAY", "117"))
DOCK2_RUN = int(os.environ.get("DOCK2_RUN", "63"))
A_RUN = int(os.environ.get("A_RUN", "140"))
CRADLE_RUN = int(os.environ.get("CRADLE_RUN", "156"))


def pos(r, root, label):
    if DEBUG:
        r.add(expect_call="GameState.get", args=["integrity"], equals="dbg", label="dbg_hp_" + label)
        r.add(expect_call=root + "/Player.get", args=["global_position"], equals="dbg",
              label="dbg_" + label)


def walk(r, action, frames, after=0):
    r.hold(action, frames)
    if after:
        r.wait(after)


def terminal(r, steps, label, look=SEE, settle=30):
    r.interact(40)
    for step in steps:
        if step == "t":
            r.tap("interact", 3, 24)
        elif step == "u":
            r.tap("move_up", 3, 10)
        else:
            r.tap("move_down", 3, 10)
    r.wait(settle)
    r.shot(label + "_terminal")
    r.tap("ui_cancel", 3, 20)
    r.wait(look)
    r.shot(label + "_consequencia")


def boss(r, method, value, label, args=None):
    event = {"expect_call": BOSS + "." + method, "equals": value, "label": label}
    if args:
        event["args"] = args
    r.add(**event)


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


def progress_check(r, root, chapter, prefix, look=110):
    r.tap("map", 3, 30)
    d.check(r, root + "/HUD/ChassisMenu.get", True, prefix + "_terminal_do_chassi", ["is_open"])
    counts = expected_counts(chapter)
    for key, path in MENU_LABELS.items():
        d.check(r, root + MENU_VALUES + path + ".get_text", "%d/%d" % (counts[key], TOTALS[key]),
                "%s_%s_%d" % (prefix, key, counts[key]))
    for secret in ds.CHAPTER_SECRETS.get(chapter, []):
        d.check(r, "GameState.has_secret", True, prefix + "_" + secret, [secret])
    r.shot(prefix + "_terminal_do_chassi")
    r.wait(look)
    r.tap("ui_cancel", 3, 30)
    d.check(r, root + "/HUD/ChassisMenu.get", False, prefix + "_chassi_fechado", ["is_open"])


def anchored(r, label, timeout=8):
    d.wait_call(r, "Docks/Player.is_anchored", True, label, timeout)


def landed(r, label, timeout=8):
    d.wait_call(r, "Docks/Player.is_on_floor", True, label, timeout)


def grab_coupler(r, tries=4):
    for _ in range(tries - 1):
        r.press("interact")
        r.wait(14)
        r.release("interact")
        r.wait(2)
    r.press("interact")


def double_jump(r, direction, run=0, settle=22):
    r.press(direction)
    r.wait(run)
    r.press("jump"); r.wait(16); r.release("jump"); r.wait(2)
    r.press("jump"); r.wait(16); r.release("jump")
    r.wait(settle)
    r.release(direction)
    r.wait(20)


def docks_gallery(r):
    r.at(20)
    r.expect_scene(rc.DK)
    r.at(40)
    rc.dialogue(r, "dk_enter", "dk_00_entrada")
    r.shot("dk_00_entrada")
    r.at(50)
    r.accept(rc.dialogue_lines("dk_enter") * 2 + 1, 10)
    r.at(160)
    rc.silent(r, "dk_01")
    r.expect(3, 48, "dk_01_nascimento")
    r.shot("dk_01_galeria")
    start = r.f + 20
    r.at(start)
    r.press("move_right")
    r.at(start + 40); r.hold("jump", 14)
    r.at(start + 154); r.hold("jump", 14)
    r.at(start + 225); r.release("move_right")
    r.at(start + 240)
    r.expect(25, 48, "dk_02_fundo_da_brecha")
    pos(r, "Docks", "brecha")
    r.shot("dk_02_brecha")
    r.wait(12)
    r.hold("jump", 4)
    lift = r.f
    r.at(lift + 90); r.shot("dk_03_flutuando_na_brecha")
    anchored(r, "dk_03_teto_da_brecha")
    r.wait(14)
    r.press("move_right"); r.wait(2); r.hold("jump", 4)
    r.wait(DOCK2_RUN)
    r.release("move_right")
    landed(r, "dk_04_pe_no_corredor")
    r.wait(10)
    pos(r, "Docks", "doca_do_corredor")
    r.expect(32, 34, "dk_04_doca_do_corredor")
    r.shot("dk_04_doca_do_corredor")
    r.wait(180)
    walk(r, "move_right", A_RUN, 22)
    r.expect(47, 40, "dk_04_console_a")
    pos(r, "Docks", "console_a")


def docks_console_a(r):
    r.shot("dk_04_console_a")
    r.wait(20)
    terminal(r, ["t", "d", "d", "d", "t", "u", "u", "t"], "dk_05_console_a", look=20, settle=12)
    d.check(r, "Docks/EnergyNetwork.has_terminal", True, "dk_05_rede", ["docks"])


def push(r, direction, hold=4):
    if direction:
        r.press(direction)
        r.wait(2)
    r.hold("jump", hold)
    if direction:
        r.release(direction)


def hp_trace(r, tag, count, every):
    if not DEBUG:
        return
    for i in range(count):
        r.add(expect_call="GameState.get", args=["integrity"], equals="dbg", label="dbg_%s_%d" % (tag, i))
        r.add(expect_call="Docks/Player.get", args=["global_position"], equals="dbg", label="dbg_%sp_%d" % (tag, i))
        r.wait(every)


def docks_hangar(r):
    walk(r, "move_right", CRADLE_RUN, 10)
    pos(r, "Docks", "sob_o_dado")
    r.expect(66, 40, "dk_06_sob_o_berco")
    r.shot("dk_06_berco_vazio")
    r.wait(8)
    push(r, "")
    r.wait(130)
    r.shot("dk_07_dado_acima_do_berco")
    anchored(r, "dk_07_ancorado_no_teto")
    r.wait(8)
    pos(r, "Docks", "teto")
    r.expect(66, 14, "dk_07_teto_do_hangar")
    push(r, "move_right")
    anchored(r, "dk_08_ancorado_na_parede_leste")
    r.wait(6)
    pos(r, "Docks", "parede_leste")
    r.expect(78, 14, "dk_08_parede_leste")
    push(r, "move_down")
    landed(r, "dk_08_pe_no_parapeito")
    r.wait(6)
    pos(r, "Docks", "parapeito")
    r.expect(78, 20, "dk_08_parapeito")
    r.shot("dk_08_parapeito")
    r.wait(6)
    walk(r, "move_right", 44, 20)
    pos(r, "Docks", "cabine")
    r.expect(83, 20, "dk_09_cabine_secreta")
    d.check(r, "GameState.has_secret", True, "dk_09_segredo_dk_secret_01", ["dk_secret_01"])
    d.check(r, "GameState.capacitors_installed", 4, "dk_09_capacitor_4_de_4")
    r.shot("dk_09_cabine_secreta")
    r.wait(30)
    rc.read_log(r, "log_dk_02")
    r.wait(30)
    rc.silent(r, "dk_10_log_dk_02_lido")
    r.shot("dk_10_depois_do_log_dk_02")
    walk(r, "move_left", 57, 20)
    pos(r, "Docks", "volta_ao_parapeito")
    r.expect(77, 20, "dk_10_volta_ao_parapeito")
    push(r, "move_left")
    anchored(r, "dk_11_ancorado_no_teto_na_volta")
    r.wait(4)
    pos(r, "Docks", "teto_2")
    r.expect(71, 14, "dk_11_teto_na_volta", 2)
    push(r, "move_left")
    r.wait(150)
    r.shot("dk_11_deriva_rente_ao_teto")
    anchored(r, "dk_11_ancorado_na_parede_oeste")
    r.wait(4)
    pos(r, "Docks", "parede_oeste")
    r.expect(36, 14, "dk_11_parede_oeste")
    push(r, "move_down")
    landed(r, "dk_12_pe_no_passadico")
    r.wait(4)
    pos(r, "Docks", "passadico")
    r.expect(36, 20, "dk_12_passadico")
    r.shot("dk_12_passadico")


def docks_locker(r):
    walk(r, "move_left", 61, 20)
    pos(r, "Docks", "doca_vestiario")
    r.expect(29, 20, "dk_13_doca_do_vestiario")
    r.shot("dk_13_doca_reparando")
    r.wait(260)
    walk(r, "move_left", 96, 18)
    r.expect(18, 20, "dk_14_log_do_vestiario")
    r.shot("dk_14_vestiario")
    rc.read_log(r, "log_dk_01")
    r.wait(40)
    pos(r, "Docks", "propulsor")
    d.check(r, "GameState.has_ability", True, "dk_15_propulsor", ["thruster"])
    r.shot("dk_15_propulsor")
    d.wait_call(r, "DialogueManager.is_active", False, "dk_15_fala_do_propulsor_acabou", 12)
    r.wait(20)
    walk(r, "move_right", 60, 20)
    r.expect(25, 20, "dk_16_console_b")
    terminal(r, ["d", "t", "d", "d", "d", "t"], "dk_16_console_b", look=40)
    walk(r, "move_left", 34, 20)
    r.expect(21, 20, "dk_17_pe_da_prateleira")
    r.wait(12)
    double_jump(r, "move_left", 0, 20)
    r.expect(17, 16, "dk_17_prateleira_1")
    r.shot("dk_17_pulo_duplo")
    r.wait(10)
    double_jump(r, "move_right")
    r.expect(23, 12, "dk_18_prateleira_2")
    r.wait(10)
    double_jump(r, "move_left")
    r.expect(17, 8, "dk_18_prateleira_3")
    r.wait(10)
    double_jump(r, "move_right")
    r.expect(22, 4, "dk_19_duto")
    r.shot("dk_19_duto")
    pos(r, "Docks", "duto")


def docks_duct_and_ring(r):
    duct = r.f
    r.press("move_right")
    r.at(duct + 135); r.hold("dash", 4)
    r.at(duct + 190); r.press("jump"); r.wait(10); r.release("jump"); r.wait(2); r.hold("jump", 10)
    r.at(duct + 300); r.shot("dk_20_duto_cx2_desligada")
    r.at(duct + 490); r.release("move_right")
    r.at(duct + 510)
    r.expect(82, 4, "dk_20_doca_do_duto")
    r.shot("dk_20_doca_do_duto")
    r.wait(60)
    d.wait_call(r, VEST_SR3 + ".get", -1, "dk_20_sr3_do_vestibulo_vai_a_oeste", 10, ["dir"])
    d.wait_call(r, VEST_SR3 + ".get", 1, "dk_20_sr3_do_vestibulo_volta_a_leste", 10, ["dir"])
    r.wait(VEST_DELAY)
    pos(r, "Docks", "doca_duto")
    r.press("move_right")
    r.wait(60)
    anchored(r, "dk_21_ancorado_no_bloco")
    r.release("move_right")
    r.wait(20)
    pos(r, "Docks", "bloco_do_anel")
    r.shot("dk_21_anel_externo")
    r.expect(99, 4, "dk_21_bloco_do_anel")
    r.wait(10)
    push(r, "move_up")
    anchored(r, "dk_21_ancorado_no_teto_do_anel")
    r.wait(12)
    pos(r, "Docks", "teto_do_anel")
    r.expect(99, 2, "dk_21_teto_do_anel")
    r.wait(10)
    r.press("move_right")
    r.wait(2)
    r.hold("jump", 4)
    r.wait(30)
    anchored(r, "dk_22_ancorado_no_canto")
    r.release("move_right")
    r.wait(12)
    pos(r, "Docks", "canto_do_dado")
    r.shot("dk_22_dado_do_anel")
    r.expect(117, 2, "dk_22_canto_do_anel", 2)
    r.wait(10)
    push(r, "move_down")
    landed(r, "dk_23_pe_no_casco")
    r.wait(12)
    pos(r, "Docks", "casco")
    r.expect(117, 16, "dk_23_casco", 2)
    r.wait(10)
    docks_hull_drop(r)


def docks_hull_drop(r):
    r.press("move_left")
    r.wait(42)
    r.release("move_left")
    r.press("move_down")
    r.wait(40)
    r.release("move_down")
    landed(r, "dk_24_pe_no_vestibulo")
    r.wait(4)
    pos(r, "Docks", "vestibulo")
    r.expect(111, 25, "dk_24_pouso_no_vestibulo", 2)
    r.shot("dk_24_vestibulo")


def docks_vestibule(r):
    double_jump(r, "move_left", 30)
    r.expect(104, 21, "dk_25_bloco_do_console_c")
    walk(r, "move_left", 8, 20)
    r.expect(103, 21, "dk_25_console_c")
    terminal(r, ["d", "d", "d", "t", "d", "d", "t"], "dk_26_console_c", look=SEE)
    d.check(r, "GameState.get", "Religar as Docas", "dk_26_objetivo", ["current_objective"])
    walk(r, "move_left", 61, 30)
    pos(r, "Docks", "doca_passagem")
    r.expect(96, 25, "dk_27_doca_da_passagem")
    r.shot("dk_27_doca_antes_do_chefe")
    r.wait(420)


def docks_arena_drop(r):
    walk(r, "move_left", 40, 0)
    r.wait(30)
    landed(r, "dk_28_pe_na_plataforma_da_arena")
    pos(r, "Docks", "pouso_arena")
    r.expect(91, 40, "dk_28_pouso_na_arena")


def docks_fight(r):
    boss(r, "is_entry_sealed", True, "dk_29_escotilha_selada")
    r.wait(30)
    r.shot("dk_29_braco_acordando")
    walk(r, "move_left", 40, 15)
    pos(r, "Docks", "acoplador_1")
    r.expect(87, 43, "dk_30_acoplador_1")
    grab_coupler(r)
    d.wait_call(r, BOSS + ".phase_name", "ACTIVE", "dk_30_braco_ativo", 6)
    r.wait(80)
    r.shot("dk_30_carregando_acoplador_1")
    d.wait_call(r, BOSS + ".powered_count", 1, "dk_30_acoplador_1_ligado", 5)
    r.release("interact")
    r.wait(6)
    double_jump(r, "move_right", 0, 8)
    r.wait(10)
    r.expect(92, 40, "dk_31_plataforma_de_entrada")
    d.wait_call(r, BOSS + ".is_gate_closed", True, "dk_31_braco_solda_a_comporta", 6)
    r.wait(20)
    r.shot("dk_31_comporta_soldada")
    r.wait(40)
    d.wait_call(r, BOSS + ".is_coupler_sealed", True, "dk_32_braco_tranca_o_acoplador_2", 8,
                ["dk_coupler_02"])
    r.wait(20)
    r.shot("dk_32_acoplador_2_trancado_de_longe")
    r.wait(30)
    walk(r, "move_right", 12, 6)
    r.press("jump"); r.wait(16); r.release("jump"); r.wait(2)
    r.press("jump"); r.wait(16); r.release("jump"); r.wait(30)
    r.expect(94, 37, "dk_32_passarela")
    r.shot("dk_32_passarela")
    walk(r, "move_right", 58, 10)
    pos(r, "Docks", "acoplador_2")
    r.expect(100, 37, "dk_33_acoplador_2")
    grab_coupler(r, 2)
    boss(r, "is_coupler_sealed", True, "dk_33_acoplador_2_segue_trancado", ["dk_coupler_02"])
    boss(r, "powered_count", 1, "dk_33_so_um_acoplador")
    r.wait(10)
    r.shot("dk_33_acoplador_2_trancado")
    r.wait(30)
    r.release("interact")
    r.wait(20)
    walk(r, "move_right", 105, 12)
    pos(r, "Docks", "acoplador_3")
    r.expect(112, 40, "dk_34_acoplador_3")
    grab_coupler(r)
    r.wait(30)
    r.shot("dk_34_carregando_acoplador_3")
    d.wait_call(r, BOSS + ".alive_spawns", 3, "dk_34_sr3_cai_no_estrado", 6)
    r.wait(BEAM_DELAY)
    r.tap("beam", 3, 3)
    r.shot("dk_34_feixe_no_sr3")
    r.wait(8)
    r.tap("beam", 3, 3)
    r.release("interact")
    r.wait(10)
    r.shot("dk_34_sr3_desligado")
    pos(r, "Docks", "apos_feixe")
    walk(r, "move_right", 12, 8)
    pos(r, "Docks", "volta_ao_acoplador_3")
    grab_coupler(r)

    d.wait_call(r, BOSS + ".powered_count", 2, "dk_34_dois_acopladores", 6)
    r.release("interact")
    r.wait(6)
    walk(r, "move_left", 26, 10)
    pos(r, "Docks", "degrau")
    r.expect(109, 40, "dk_35_degrau_fora_do_estrado")
    d.wait_call(r, BOSS + ".is_vented", True, "dk_35_arena_em_vacuo", 6)
    r.wait(30)
    r.shot("dk_35_purga_de_vacuo")
    r.wait(40)
    push(r, "move_left")
    anchored(r, "dk_36_ancorado_no_teto_da_arena")
    pos(r, "Docks", "teto_arena")
    r.wait(10)
    push(r, "move_down")
    landed(r, "dk_36_pe_na_passarela")
    pos(r, "Docks", "passarela_vacuo")
    r.shot("dk_36_flutuou_ate_a_passarela")
    r.wait(10)
    walk(r, "move_right", 18, 10)
    pos(r, "Docks", "acoplador_2_no_vacuo")
    r.expect(100, 37, "dk_37_acoplador_2_no_vacuo")
    grab_coupler(r)
    r.wait(20)
    r.shot("dk_37_segurando_o_acoplador_2")
    if DEBUG:
        for i in range(16):
            r.add(expect_call="GameState.get", args=["integrity"], equals="dbg", label="dbg_fhp_%d" % i)
            r.add(expect_call=BOSS + ".get_indexed", args=["_fight:arm_state"], equals="dbg", label="dbg_farm_%d" % i)
            r.add(expect_call=BOSS + ".get_indexed", args=["_fight:_couplers:dk_coupler_02"], equals="dbg", label="dbg_fc2_%d" % i)
            r.add(expect_call="Docks/Entities/Coupler.is_held", equals="dbg", label="dbg_fh_%d" % i)
            r.shot("dbg_f_%d" % i)
            r.wait(30)
    d.wait_call(r, BOSS + ".is_coupler_sealed", False, "dk_37_braco_solta_o_acoplador_2", 9,
                ["dk_coupler_02"])
    r.release("interact")
    r.wait(2)
    grab_coupler(r)
    r.wait(20)
    r.shot("dk_37_carregando_no_vacuo")
    d.wait_call(r, BOSS + ".phase_name", "DEFEATED", "dk_38_serralheiro_desligado", 12)
    r.release("interact")
    boss(r, "is_node_unlocked", True, "dk_38_no_liberado")
    boss(r, "is_gate_closed", False, "dk_38_comporta_aberta")
    r.wait(20)
    r.shot("dk_38_braco_desligado")
    boss(r, "is_vented", False, "dk_38_vacuo_fechado")
    d.wait_call(r, "DialogueManager.is_active", True, "dk_39_ultima_ordem", 6)
    rc.dialogue(r, "lock_down", "dk_39_ultima_ordem")
    r.wait(10)
    r.shot("dk_39_ultima_ordem")
    r.accept(rc.dialogue_lines("lock_down") * 2 + 1, 14)
    r.wait(30)
    rc.silent(r, "dk_39_depois_da_ordem")
    progress_check(r, "Docks", "docas", "dk_39b")
    r.wait(10)
    walk(r, "move_right", 140, 30)
    pos(r, "Docks", "no_do_setor")
    r.expect(115, 40, "dk_40_no_do_setor")
    r.shot("dk_40_no_do_setor")
    r.wait(20)
    r.interact(30)
    r.shot("dk_40_religando")
    d.wait_call(r, "DialogueManager.is_active", True, "dk_41_fala_de_religamento", 20)
    rc.dialogue(r, "dk_restored", "dk_41_religamento")
    r.wait(10)
    r.shot("dk_41_docas_religadas")
    r.accept(rc.dialogue_lines("dk_restored") * 2 + 1, 14)
    d.wait_scene(r, rc.HUB, "dk_42_volta_ao_nucleo", 12)
def chapter_docks():
    r = R()
    rc.setup(r, ds.full_state("s03", "docas"))
    r.scene(rc.DK)
    docks_gallery(r)
    docks_console_a(r)
    docks_hangar(r)
    docks_locker(r)
    docks_duct_and_ring(r)
    docks_vestibule(r)
    docks_arena_drop(r)
    docks_fight(r)
    r.wait(10)
    pos(r, "Docks", "fim")
    r.quit()
    return r


HUB_SPAWN = (95, 11)
TOUR_LOOK = 120


def station_tour(r, prefix):
    root = "CoreHub/HUD/ChassisMenu"
    r.tap("map", 3, 40)
    d.check(r, root + ".get", True, prefix + "_t1_terminal_do_chassi", ["is_open"])
    r.shot(prefix + "_t1_terminal_do_chassi")
    r.wait(TOUR_LOOK - 40)
    r.tap("map", 3, 40)
    d.check(r, root + ".current_page", "map", prefix + "_t2_mapa_da_estacao")
    r.shot(prefix + "_t2_mapa_da_estacao")
    r.wait(TOUR_LOOK)
    r.tap("ui_cancel", 3, 30)
    d.check(r, root + ".get", False, prefix + "_t3_mapa_fechado", ["is_open"])
    r.tap("log_archive", 3, 40)
    d.check(r, "SceneManager/PauseMenu.get", True, prefix + "_t4_arquivo_aberto", ["is_open"])
    r.shot(prefix + "_t4_arquivo_de_logs")
    r.wait(TOUR_LOOK)
    r.tap("ui_cancel", 3, 40)
    d.check(r, "SceneManager/PauseMenu.get", False, prefix + "_t5_tudo_fechado", ["is_open"])
    rc.silent(r, prefix + "_t5")


def hub_start(base, chapter, seq_id, objective_text, prefix):
    r = R()
    state = ds.full_state(base, chapter)
    state["flags"].pop("dlg_" + seq_id, None)
    state["checkpoint"] = {}
    rc.setup(r, state)
    r.scene(rc.HUB)
    r.at(40)
    r.expect_scene(rc.HUB)
    rc.dialogue(r, seq_id, prefix + "_a")
    r.shot(prefix + "_a_volta_ao_hub")
    r.at(50)
    r.accept(rc.dialogue_lines(seq_id) * 2 + 1, 14)
    r.wait(30)
    rc.silent(r, prefix + "_b")
    rc.objective(r, objective_text, prefix + "_b_objetivo")
    r.expect(HUB_SPAWN[0], HUB_SPAWN[1], prefix + "_b_doca_do_hub")
    return r


def hub_docas():
    r = hub_start("s03", "hub_docas", "core_return_infirmary", "Chegar às Docas", "hd")
    station_tour(r, "hd")
    r.wait(20)
    walk(r, "move_right", 140, 0)
    r.expect(111, 11, "hd_c_corredor_dos_setores", 2)
    r.press("move_right")
    r.wait(126)
    r.release("move_right")
    r.wait(24)
    r.expect(125, 11, "hd_c_portal_das_docas")
    r.shot("hd_c_portal_das_docas")
    r.wait(20)
    r.interact(2)
    d.finish(r, r.f)
    return r


def hub_memoria():
    r = hub_start("s04", "hub_memoria", "core_return_docks", "Ir ao Núcleo de Memória", "hm")
    r.wait(20)
    walk(r, "move_right", 314, 0)
    r.expect(131, 11, "hm_c_ala_leste", 2)
    r.press("move_right")
    r.wait(MEM_RUN)
    r.release("move_right")
    r.wait(30)
    r.expect(146, 14, "hm_c_portal_da_memoria")
    r.shot("hm_c_portal_da_memoria")
    r.wait(20)
    r.interact(2)
    d.finish(r, r.f)
    return r


ROOT_FLAGS = ["root_door_open_gh_root_door", "root_door_open_lab_root_door",
              "root_door_open_dk_root_door", "root_door_open_door_reactor"]


def revisit_state():
    state = ds.full_state("s05", "revisita")
    for flag in ROOT_FLAGS:
        state["flags"].pop(flag, None)
    state["checkpoint"] = {}
    return state


def hub_plate(r):
    r.at(40)
    r.expect_scene(rc.HUB)
    r.wait(30)
    rc.silent(r, "rv_00")
    r.expect(HUB_SPAWN[0], HUB_SPAWN[1], "rv_00_doca_do_hub")
    r.shot("rv_00_hub")
    walk(r, "move_left", 16, 10)
    r.press("move_left")
    r.press("move_up")
    r.hold("jump", 12)
    r.wait(HUB_CLIMB)
    r.release("move_left")
    pos(r, "CoreHub", "parede_magnetica")
    r.shot("rv_01_garras_na_parede")
    r.release("move_up")
    r.wait(6)
    r.press("move_right")
    r.hold("jump", 12)
    r.wait(40)
    r.release("move_right")
    r.wait(20)
    pos(r, "CoreHub", "sala_da_placa")
    pos(r, "CoreHub", "placa")
    r.expect(99, 4, "rv_02_placa_do_nucleo")
    r.shot("rv_02_placa_do_nucleo")


def hub_plate_exit(r):
    r.wait(20)
    walk(r, "move_left", 50, 0)
    r.wait(50)
    pos(r, "CoreHub", "desceu_da_placa")
    r.expect(93, 11, "rv_03_desceu_da_sala_da_placa", 1)
    walk(r, "move_right", GH_PORTAL_RUN, 20)
    r.expect(101, 11, "rv_03_portal_da_estufa")
    r.shot("rv_03_portal_da_estufa")
    r.interact(2)
    d.wait_scene(r, rc.GH, "rv_04_estufa", 10)


def greenhouse_root(r):
    r.wait(40)
    rc.silent(r, "rv_04")
    pos(r, "Greenhouse", "chegada")
    r.expect(2, 61, "rv_04_chegada_na_estufa", 1)
    r.shot("rv_04_estufa")
    walk(r, "move_right", GH_RUN, 12)
    r.press("jump")
    r.press("move_right")
    r.wait(12)
    r.release("move_right")
    r.wait(2)
    r.release("jump")
    r.wait(30)
    pos(r, "Greenhouse", "degrau")
    r.expect(11, 59, "rv_05_degrau_da_estufa")
    r.wait(10)
    r.press("move_right")
    r.press("jump")
    r.wait(10)
    r.release("jump")
    r.press("jump")
    r.wait(GH_SECOND)
    r.release("jump")
    r.wait(GH_AIR)
    r.release("move_right")
    r.wait(30)
    pos(r, "Greenhouse", "corredor_root")
    r.expect(14, 55, "rv_05_corredor_da_comporta_root", 1)
    walk(r, "move_right", GH_DOOR_RUN, 20)
    pos(r, "Greenhouse", "comporta")
    r.expect(19, 55, "rv_06_comporta_root_da_estufa")
    d.check(r, "GameState.is_root_door_open", False, "rv_06_comporta_fechada", ["gh_root_door"])
    r.shot("rv_06_comporta_root_fechada")
    r.wait(20)
    r.interact(40)
    d.check(r, "GameState.is_root_door_open", True, "rv_06_acesso_root_abre", ["gh_root_door"])
    r.shot("rv_06_comporta_root_aberta")
    r.wait(30)
    walk(r, "move_right", 62, 30)
    pos(r, "Greenhouse", "placa")
    r.expect(26, 55, "rv_07_placa_da_estufa")
    r.shot("rv_07_placa_da_estufa")
    walk(r, "move_left", GH_BACK_RUN, 0)
    r.wait(60)
    pos(r, "Greenhouse", "de_volta_ao_chao")
    walk(r, "move_left", GH_EXIT_RUN, 20)
    r.expect(2, 61, "rv_08_saida_da_estufa")
    r.interact(2)
    d.wait_scene(r, rc.HUB, "rv_08_volta_ao_hub", 10)


def hub_to_docks(r):
    r.wait(30)
    rc.silent(r, "rv_09")
    r.expect(101, 11, "rv_09_de_volta_ao_portal_da_estufa")
    walk(r, "move_right", HUB_DOCKS_RUN, 20)
    r.expect(125, 11, "rv_09_portal_das_docas")
    r.shot("rv_09_portal_das_docas")
    r.interact(2)
    d.wait_scene(r, rc.DK, "rv_10_docas", 10)


def docks_root(r):
    r.wait(40)
    rc.silent(r, "rv_10")
    pos(r, "Docks", "chegada")
    r.expect(1, 48, "rv_10_chegada_nas_docas", 1)
    r.shot("rv_10_docas_religadas")
    start = r.f + 10
    r.at(start)
    r.press("move_right")
    r.at(start + 57); r.hold("jump", 14)
    r.at(start + 171); r.hold("jump", 14)
    r.at(start + 242); r.release("move_right")
    r.at(start + 257)
    pos(r, "Docks", "brecha_rv")
    r.expect(25, 48, "rv_11_fundo_da_brecha")
    r.wait(12)
    r.hold("jump", 4)
    anchored(r, "rv_11_teto_da_brecha")
    r.wait(10)
    r.press("move_right"); r.wait(2); r.hold("jump", 4)
    r.wait(DOCK2_RUN)
    r.release("move_right")
    landed(r, "rv_11_pe_no_corredor")
    r.wait(10)
    r.expect(32, 34, "rv_11_doca_do_corredor")
    walk(r, "move_right", 40, 0)
    landed(r, "rv_12_pe_no_hangar")
    r.wait(20)
    walk(r, "move_left", 20, 20)
    pos(r, "Docks", "comporta_rv")
    r.expect(36, 40, "rv_12_comporta_root_das_docas")
    d.check(r, "GameState.is_root_door_open", False, "rv_12_comporta_fechada", ["dk_root_door"])
    r.shot("rv_12_comporta_root_fechada")
    r.interact(40)
    d.check(r, "GameState.is_root_door_open", True, "rv_12_acesso_root_abre", ["dk_root_door"])
    r.shot("rv_12_comporta_root_aberta")
    r.wait(20)
    walk(r, "move_left", DK_PLATE_RUN, 30)
    pos(r, "Docks", "placa_rv")
    r.expect(32, 40, "rv_13_placa_das_docas")
    r.shot("rv_13_placa_das_docas")
    walk(r, "move_right", DK_A_RUN, 20)
    pos(r, "Docks", "console_a_rv")
    r.expect(47, 40, "rv_14_console_a")
    terminal(r, ["d", "t"], "rv_14_console_a", look=20, settle=12)
    walk(r, "move_left", DK_DIAG_RUN, 12)
    pos(r, "Docks", "impulso_rv")
    r.press("move_left"); r.wait(2); r.hold("jump", 4); r.release("move_left")
    if DEBUG:
        for i in range(25):
            r.add(expect_call="Docks/Player.get", args=["global_position"], equals="dbg", label="dbg_diag_%d" % i)
            r.add(expect_call="Docks/Player.is_in_vacuum", equals="dbg", label="dbg_dvac_%d" % i)
            r.wait(4)
    landed(r, "rv_15_volta_ao_corredor")
    r.wait(10)
    pos(r, "Docks", "corredor_rv")
    r.expect(34, 34, "rv_15_corredor", 2)
    walk(r, "move_left", DK_BREACH_RUN, 0)
    landed(r, "rv_16_chao_da_galeria", 12)
    r.wait(10)
    pos(r, "Docks", "galeria_rv")
    r.expect(22, 48, "rv_16_galeria", 2)


def docks_exit(r):
    t0 = r.f + 10
    r.at(t0)
    r.press("move_left")
    r.at(t0 + EXIT_J1); r.hold("jump", 14)
    r.at(t0 + EXIT_J2); r.hold("jump", 14)
    r.at(t0 + EXIT_RUN); r.release("move_left")
    r.wait(20)
    pos(r, "Docks", "saida_rv")
    r.expect(1, 48, "rv_17_saida_das_docas", 1)
    r.shot("rv_17_saida_das_docas")
    r.interact(2)
    d.wait_scene(r, rc.HUB, "rv_18_volta_ao_hub", 10)


def hub_reactor_door(r):
    r.wait(30)
    rc.silent(r, "rv_18")
    pos(r, "CoreHub", "portal_docas_rv")
    r.expect(125, 11, "rv_18_portal_das_docas")
    walk(r, "move_right", STAIR_RUN, 10)
    pos(r, "CoreHub", "pe_da_escada")
    r.expect(130, 11, "rv_19_pe_da_escada", 1)
    for index, (run, tile) in enumerate([(0, (132, 9)), (STEP2_RUN, (136, 7)),
                                         (STEP3_RUN, (138, 5))]):
        if run:
            walk(r, "move_right", run, 6)
        r.press("move_right")
        r.press("jump")
        r.wait(10)
        r.release("move_right")
        r.wait(4)
        r.release("jump")
        r.wait(36)
        pos(r, "CoreHub", "degrau_%d" % (index + 1))
        r.expect(tile[0], tile[1], "rv_19_degrau_%d" % (index + 1), 1)
    walk(r, "move_right", DOOR_RUN, 30)
    pos(r, "CoreHub", "porta_do_reator")
    r.expect(141, 5, "rv_20_diante_da_porta_do_reator", 1)
    d.check(r, "GameState.is_root_door_open", False, "rv_20_reator_ainda_fechado",
            ["door_reactor"])
    r.shot("rv_20_porta_do_reator")


def revisita():
    r = R()
    rc.setup(r, revisit_state())
    r.scene(rc.HUB)
    hub_plate(r)
    hub_plate_exit(r)
    greenhouse_root(r)
    hub_to_docks(r)
    docks_root(r)
    docks_exit(r)
    hub_reactor_door(r)
    r.wait(20)
    progress_check(r, "CoreHub", "revisita", "rv_21")
    r.wait(20)
    d.finish(r, r.f)
    return r


CHAPTERS = {
    "revisita": revisita,
    "hub_docas": hub_docas,
    "hub_memoria": hub_memoria,
    "docas": chapter_docks,
}


REAL = ["hub_docas", "docas", "hub_memoria", "revisita"]


def main():
    wanted = sys.argv[1:] or REAL
    for key in wanted:
        d.write(CHAPTERS[key](), key)


if __name__ == "__main__":
    main()

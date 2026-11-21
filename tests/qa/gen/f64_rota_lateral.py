import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
OUT = os.path.join(ROOT, "tests", "qa", "f64_rota_lateral.json")
from qa_build import R

SCENE = "res://scenes/levels/memory_core.tscn"
PROTOCOL = "MemoryCore/Protocol"
PLAYER = "MemoryCore/Player"
HALL_DOOR = "MemoryCore/Entities/Door"
WALKWAY = "MemoryCore/Entities/MovingPlatform"
STAGE = int(sys.argv[1]) if len(sys.argv) > 1 else 99
r = R()
sel = [0]


def probe(count=40, every=4):
    for i in range(count):
        r.add(expect_call=PLAYER + ".get", args=["global_position"], equals="?", label="p%03d" % i)
        r.wait(every)


def done():
    r.wait(4); probe(); r.shot("fim"); r.quit(); r.save(OUT); sys.exit()


def walk(direction, frames, settle=12):
    r.hold("move_" + direction, frames); r.wait(settle)


def toggle(row):
    while sel[0] < row:
        r.tap("move_down", 3, 8); sel[0] += 1
    while sel[0] > row:
        r.tap("move_up", 3, 8); sel[0] -= 1
    pressed = r.f
    r.interact(14)
    return pressed


r.call("Settings.set", "difficulty", "normal")
r.call("GameState.new_game")
r.call("GameState.from_dict", {
    "abilities": ["magnetic_claws", "heat_sink", "heated_core", "thruster"],
    "sectors_restored": ["greenhouse", "lab", "infirmary", "docks"],
    "flags": {"dlg_mem_enter": True, "dlg_mem_luto": True, "reactor_online": True,
              "mem_protocol": 1, "visited_memory_core": True},
    "checkpoint": {"scene": SCENE, "dock_id": "mem_dock_02"},
    "current_objective": "obj_memory",
})
r.scene(SCENE)
r.at(30); r.expect_scene(SCENE)
r.at(60); r.expect(47, 12, "01_doca_do_salao")
r.add(expect_call=PROTOCOL + ".phase", equals=2, label="01_firewall_ativo")
r.add(expect_call=PROTOCOL + ".is_hall_framed", equals=True, label="01_camera_no_salao")
r.add(expect_call=PROTOCOL + ".eye_clear_of_hud", equals=True, label="01_olho_fora_da_hud")
r.shot("01_salao_e_a_parede_magnetica")
walk("right", 63)
r.expect(54, 12, "02_console_a")
r.interact(30)
r.shot("02_console_a")
toggle(2); WALK_ON = toggle(1); toggle(2)
r.shot("03_so_passarela_e_isca")
r.tap("ui_cancel", 3, 40)
r.add(expect_call=PROTOCOL + ".pending_swap", equals="party_lights", label="04_firewall_mira_as_luzes")
r.add(expect_call=PROTOCOL + ".eye_clear_of_hud", equals=True, label="04_olho_fora_da_hud")
r.shot("04_roubo_visivel_do_console")
r.wait(80)
r.add(expect_call=WALKWAY + ".get", args=["powered"], equals=True, label="05_passarela_ficou")
r.add(expect_call=HALL_DOOR + ".is_open", equals=False, label="05_porta_do_salao_fechada")
r.shot("05_luzes_roubadas_porta_fechada")
if STAGE == 1:
    done()
r.hold("move_right", 9); r.wait(16)
CLIMB = r.f
if STAGE == 2:
    for i in range(80):
        r.at(CLIMB + i * 2)
        r.add(expect_call=PLAYER + ".get", args=["global_position"], equals="?", label="c%03d" % i)
        r.add(expect_call=PLAYER + ".is_double_jump_used", equals="?", label="d%03d" % i)
        r.add(expect_call="GameState.get", args=["charge"], equals="?", label="q%03d" % i)
    r.at(CLIMB)
r.press("jump"); r.wait(14); r.release("jump"); r.wait(6)
r.press("jump"); r.press("move_up"); r.wait(12); r.release("jump")
r.wait(60)
r.press("jump"); r.wait(4); r.press("move_right"); r.wait(8); r.release("jump")
r.wait(24); r.release("move_right"); r.release("move_up"); r.wait(20)
if STAGE == 2:
    done()
r.expect(59, 6, "06_galeria_sobre_a_porta")
r.add(expect_call=HALL_DOOR + ".is_open", equals=False, label="06_porta_continua_fechada")
r.shot("06_galeria_sobre_a_porta")
if STAGE == 3:
    done()
walk("right", 24, 40)
r.expect(61, 12, "07_desceu_alem_da_porta")
r.shot("07_alem_da_porta_sem_abrir")
if STAGE == 4:
    done()
r.at(WALK_ON + 666 + 696); r.hold("move_right", 14)
r.wait(30); r.shot("08_na_passarela_pela_galeria")
r.at(WALK_ON + 1018 + 696); r.hold("move_right", 46); r.wait(10)
r.expect(81, 12, "09_console_b")
r.interact(30)
sel[0] = 0
toggle(1); toggle(3); toggle(2)
r.shot("10_console_b_isca")
r.tap("ui_cancel", 3, 30)
r.add(expect_call=PROTOCOL + ".pending_swap", equals="party_lights", label="11_firewall_mira_de_novo")
r.add(expect_call=PROTOCOL + ".eye_clear_of_hud", equals=True, label="11_olho_fora_da_hud")
r.shot("11_roubo_visivel_do_console_b")
r.wait(90)
r.add(expect_call=PROTOCOL + ".pending_swap", equals="", label="12_troca_feita")
walk("right", 120, 20)
r.expect(92, 12, "12_passou_pela_porta_do_arquivo", 3)
r.add(expect_call=HALL_DOOR + ".is_open", equals=False, label="12_sem_nunca_abrir_a_porta_do_salao")
r.shot("12_arquivo_aberto_pela_galeria")
if STAGE == 5:
    done()
r.wait(10)
r.quit()
r.save(OUT)

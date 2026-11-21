import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
OUT = os.path.join(ROOT, "tests", "qa", "f64_memory.json")
from qa_build import R

SCENE = "res://scenes/levels/memory_core.tscn"
PROTOCOL = "MemoryCore/Protocol"
STAGE = int(sys.argv[1]) if len(sys.argv) > 1 else 99
ABILITIES = ["magnetic_claws", "heat_sink", "heated_core", "thruster"]
r = R()


def probe(count=40, every=4):
    for i in range(count):
        r.add(expect_call="MemoryCore/Player.get", args=["global_position"], equals="?", label="p%03d" % i)
        r.wait(every)


def done():
    r.wait(4); probe(); r.shot("fim"); r.quit(); r.save(OUT); sys.exit()


def phase_is(value, label):
    r.add(expect_call=PROTOCOL + ".phase", equals=value, label=label)


r.call("Settings.set", "difficulty", "normal")
r.call("GameState.new_game")
r.call("GameState.from_dict", {
    "abilities": ABILITIES,
    "sectors_restored": ["greenhouse", "lab", "infirmary", "docks"],
    "flags": {"dlg_mem_enter": True, "reactor_online": True},
    "current_objective": "obj_memory",
})
r.scene(SCENE)
r.at(30); r.expect_scene(SCENE)
r.at(60); r.expect(4, 55, "nascimento"); r.shot("01_refeitorio")
r.press("move_right")
r.at(300); r.release("move_right")
r.at(320); r.expect(31, 55, "base_do_poco"); phase_is(1, "fase_1_ativa")
r.hold("jump", 14)
r.wait(40)


def walk(direction, frames, settle=12):
    r.hold("move_" + direction, frames); r.wait(settle)


def jump(hold=14, land=40):
    r.hold("jump", hold); r.wait(land)


walk("right", 28); jump()
walk("right", 34); jump()
jump()
if STAGE == 1:
    done()
walk("left", 95, 4)
r.shot("02_subindo_com_a_estatica")
r.press("move_left"); r.press("move_up")
r.wait(8); r.release("move_left")
r.wait(240); r.release("move_up")
r.wait(10)
r.expect(28, 32, "topo_da_parede_magnetica"); r.shot("03_topo_da_garra")
if STAGE == 2:
    done()
walk("right", 44); jump()
walk("right", 40); jump()
r.press("jump"); r.wait(14); r.release("jump"); r.wait(8)
r.press("jump"); r.press("move_right"); r.wait(14); r.release("jump"); r.wait(12)
r.release("move_right"); r.wait(40)
r.expect(40, 24, "plataforma_do_pulo_duplo"); r.shot("04_pulo_duplo")
if STAGE == 3:
    done()
jump()
walk("left", 52); jump()
jump()
walk("right", 28); jump()
jump()
r.press("move_right"); r.wait(2); r.hold("jump", 14); r.wait(24); r.release("move_right"); r.wait(30)
r.expect(42, 12, "saiu_do_poco"); r.shot("05_saiu_do_poco")
r.add(expect_call=PROTOCOL + ".completed_phases", equals=1, label="fase_1_vencida")
phase_is(2, "fase_2_ativa")
if STAGE == 4:
    done()
walk("right", 84)
r.expect(51, 12, "console_a")
r.interact(30)
r.shot("06_console_a")
sel = [0]


def toggle(row):
    while sel[0] < row:
        r.tap("move_down", 3, 8); sel[0] += 1
    while sel[0] > row:
        r.tap("move_up", 3, 8); sel[0] -= 1
    r.interact(14)


toggle(2); toggle(4); toggle(0); toggle(1); toggle(2)
r.shot("07_console_a_isca_por_ultimo")
r.tap("ui_cancel", 3, 40)
r.add(expect_call=PROTOCOL + ".pending_swap", equals="party_lights", label="firewall_mira_as_luzes")
r.shot("08_firewall_mira_as_luzes")
r.wait(80)
r.add(expect_call="MemoryCore/Entities/MovingPlatform.get", args=["powered"], equals=True,
      label="passarela_continua_ligada")
r.shot("09_luzes_roubadas")
walk("right", 91, 4)
r.expect(61, 12, "beira_do_vao"); r.shot("10_beira_do_vao")
r.at(2672); r.hold("move_right", 14)
r.wait(20); r.shot("11_na_passarela")
r.at(2900); r.shot("12_atravessando_o_vao")
r.at(3024); r.hold("move_right", 46); r.wait(10)
r.expect(81, 12, "console_b")
r.interact(30)
sel[0] = 0
toggle(1); toggle(4); toggle(3); toggle(2)
r.shot("13_console_b_isca_por_ultimo")
r.tap("ui_cancel", 3, 30)
r.add(expect_call=PROTOCOL + ".pending_swap", equals="party_lights", label="firewall_mira_de_novo")
r.wait(90)
r.add(expect_call="MemoryCore/Protocol.pending_swap", equals="", label="troca_feita")
r.shot("14_porta_do_arquivo_aberta")
walk("right", 340, 4)
r.wait(70)
r.expect(119, 30, "fundo_do_poco_do_arquivo")
r.add(expect_call=PROTOCOL + ".completed_phases", equals=2, label="fase_2_vencida")
phase_is(3, "fase_3_ativa")
r.shot("15_corredor_escuro")
if STAGE == 6:
    done()
A = r.f
r.press("move_left")
r.at(A + 40); r.shot("16_primeira_linha")
r.at(A + 300); r.shot("17_lampejo")
r.at(A + 640); r.add(expect_call=PROTOCOL + ".recall_opened", equals=4, label="quatro_linhas_andando")
r.at(A + 700); r.shot("18_selei_o_lado_errado")
r.at(A + 1500); r.shot("19_helena_no_interfone")
r.at(A + 2100); r.shot("20_leito_doze")
r.at(A + 2560); r.release("move_left")
r.wait(30)
r.add(expect_call=PROTOCOL + ".completed_phases", equals=3, label="log_final_inteiro")
r.add(expect_call=PROTOCOL + ".final_log_collected", equals=True, label="log_final_coletado")
r.shot("21_esperar_a_tripulacao_voltar")
r.hold("move_right", 36); r.wait(20)
r.expect(51, 30, "no_do_setor"); r.shot("22_no_do_setor")
r.interact(20)
r.add(expect_call="GameState.has_ability", args=["root_access"], equals=True, label="acesso_root")
if STAGE == 7:
    done()
F = r.f
r.at(F + 120); r.shot("23_cutscene_a_memoria_volta")
r.at(F + 300); r.shot("24_cutscene_cores")
r.at(F + 480); r.shot("25_cutscene_refeitorio")
r.at(F + 720); r.shot("26_acesso_root")
r.add(expect_call=PROTOCOL + ".signal_visible", equals=True, label="sinal_da_terra")
r.accept(4, 14)
r.shot("27_um_sinal_da_terra")
r.accept(4, 14)
r.wait(200); r.expect_scene("res://scenes/ui/demo_end.tscn")
r.wait(10); r.shot("28_tela_de_fim")
r.add(expect_call="GameState.get", args=["checkpoint"], equals={"scene": "res://scenes/levels/core_hub.tscn", "dock_id": ""}, label="backup_no_nucleo")
r.wait(20); r.scene("res://scenes/levels/core_hub.tscn")
r.wait(40); r.expect_scene("res://scenes/levels/core_hub.tscn")
r.wait(30); r.accept(4, 12)
r.wait(60)
r.call("CoreHub/Player.set_indexed", "global_position:x", 141 * 16 + 8)
r.call("CoreHub/Player.set_indexed", "global_position:y", 6 * 16 - 1)
r.wait(40); r.expect(141, 5, "patamar_do_reator", 0)
r.hold("move_right", 30); r.wait(15)
r.expect(142, 5, "comporta_do_reator", 0); r.shot("29_comporta_do_reator_com_root")
r.interact(30)
r.add(expect_call="GameState.is_root_door_open", args=["door_reactor"], equals=True, label="reator_aberto_pela_memoria")
r.hold("move_right", 50); r.wait(15)
r.expect(147, 5, "passou_da_comporta_do_reator"); r.shot("30_reator_aberto")
r.wait(20); r.quit()
r.save(OUT)
sys.exit()
if STAGE == 5:
    for i in range(60):
        r.add(expect_call="MemoryCore/Player.get", args=["global_position"], equals="?", label="m%03d" % i)
        r.wait(6)
    done()
done()

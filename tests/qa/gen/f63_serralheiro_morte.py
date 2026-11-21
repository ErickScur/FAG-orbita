import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
OUT = os.path.join(ROOT, "tests", "qa", "f63_serralheiro_morte.json")
from qa_build import R

BOSS = "Docks/Entities/Serralheiro"
r = R()


def tp(x, y):
    r.call("Docks/Player.set_indexed", "global_position:x", x * 16 + 8)
    r.call("Docks/Player.set_indexed", "global_position:y", (y + 1) * 16 - 1)


def boss(method, value, label, args=None):
    event = {"expect_call": BOSS + "." + method, "equals": value, "label": label}
    if args:
        event["args"] = args
    r.add(**event)


def descend(start):
    r.at(start); tp(96, 25)
    r.at(start + 40); r.expect(96, 25, "passagem_%d" % start)
    r.press("move_left")
    r.at(start + 84); r.release("move_left")
    r.at(start + 130); r.expect(91, 40, "pouso_%d" % start)
    r.at(start + 160); r.press("move_left")
    r.at(start + 192); r.release("move_left")
    r.at(start + 220); r.expect(87, 43, "acoplador_1_%d" % start)


r.call("Settings.set", "difficulty", "normal")
r.call("GameState.new_game")
r.call("GameState.unlock_ability", "thruster")
r.scene("res://scenes/levels/docks.tscn")
r.at(20); r.expect_scene("res://scenes/levels/docks.tscn")
r.at(50); r.accept(6, 10)
r.at(150)
r.call("Docks/EnergyNetwork.toggle", "docks", "security")
r.call("Docks/EnergyNetwork.toggle", "docks", "outer_hatch")
r.call("Docks/EnergyNetwork.toggle", "docks", "node_door")
r.call("GameState.set", "checkpoint", {"scene": "res://scenes/levels/docks.tscn", "dock_id": "dk_dock_05"})
descend(160)
r.press("interact")
r.at(580); r.release("interact")
r.at(585); boss("powered_count", 1, "um_acoplador")
r.at(745); boss("is_gate_closed", True, "comporta_fechada")
r.shot("01_comporta_fechada")
r.call(BOSS + ".set_indexed", "_fight:time_left", 0.5)
r.at(790); boss("phase_name", "CONTAINED", "contencao_completa")
boss("is_vented", True, "purga_em_vacuo")
boss("is_coupler_sealed", True, "acoplador_2_trancado", ["dk_coupler_02"])
r.shot("02_contencao_completa")
r.at(820); r.shot("03_purga")
r.track("p", 40, 6)
r.at(1200); r.expect(96, 25, "renasce_na_doca_do_vestibulo", 2); r.shot("04_renascido")
boss("phase_name", "DORMANT", "encontro_dormente")
boss("powered_count", 0, "acopladores_apagados")
boss("is_gate_closed", False, "comporta_aberta")
boss("is_entry_sealed", False, "escotilha_aberta")
boss("is_vented", False, "sem_vacuo")
boss("alive_spawns", 0, "sr3_recolhidas")
boss("time_left", 100.0, "relogio_cheio")
boss("is_node_unlocked", False, "no_ainda_selado")
descend(1220)
r.press("interact")
r.at(1470); boss("phase_name", "ACTIVE", "acordou_de_novo")
r.shot("05_de_volta_ao_encontro")
r.at(1640); r.release("interact")
r.at(1645); boss("powered_count", 1, "carrega_de_novo"); r.shot("06_acoplador_de_novo")
r.wait(20); r.quit()
r.save(OUT)

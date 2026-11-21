import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, HERE)
OUT = os.path.join(ROOT, "tests", "qa", "review_design_serralheiro_wake.json")
from qa_build import R
from f63_fight import boss

r = R()


def tp(x, y):
    r.call("Docks/Player.set_indexed", "global_position:x", x * 16 + 8)
    r.call("Docks/Player.set_indexed", "global_position:y", (y + 1) * 16 - 1)


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
r.at(160); tp(96, 25)
r.at(200); r.expect(96, 25, "passagem"); boss(r, "phase_name", "DORMANT", "braco_dormente")
r.press("move_left")
r.at(244); r.release("move_left")
for i, f in enumerate(range(250, 411, 15)):
    r.at(f); r.shot("wake_%02d_f%d" % (i, f))
r.at(276); boss(r, "is_wake_framed", True, "camera_no_braco")
r.at(290); r.expect(91, 40, "pouso_na_plataforma")
boss(r, "is_entry_sealed", True, "escotilha_selada")
r.at(300); boss(r, "phase_name", "WAKING", "braco_acordando")
boss(r, "is_boss_in_frame", True, "braco_inteiro_abaixo_da_hud", [40.0])
r.at(330); boss(r, "is_boss_in_frame", True, "olho_ainda_no_quadro", [40.0])
r.at(400); boss(r, "is_wake_framed", False, "camera_volta_ao_mu7")
boss(r, "phase_name", "ACTIVE", "braco_ativo")
r.at(410); boss(r, "is_boss_in_frame", True, "carro_abaixo_da_hud_na_luta", [40.0])
r.at(415); r.expect(91, 40, "parado_no_pouso")
r.at(420); r.quit()
r.save(OUT)

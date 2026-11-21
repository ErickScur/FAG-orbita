import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, HERE)
OUT = os.path.join(ROOT, "tests", "qa", "f63_serralheiro.json")
from qa_build import R
from f63_fight import boss, fight

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
r.shot("01_passagem")
r.press("move_left")
r.at(244); r.release("move_left")
r.at(290); r.expect(91, 40, "pouso_na_plataforma")
STOP = sys.argv[1] if len(sys.argv) > 1 else ""
fight(r, 290, stop=STOP)
if STOP:
    r.wait(10); r.quit(); r.save(OUT); sys.exit()
r.interact(30)
r.shot("15_religando")
F = r.f
r.at(F + 200); r.shot("16_cutscene")
r.at(F + 560); r.shot("17_fala_de_religamento")
r.accept(6, 14)
r.wait(160); r.expect_scene("res://scenes/levels/core_hub.tscn")
r.wait(10); r.shot("18_de_volta_ao_nucleo")
r.wait(20); r.quit()
r.save(OUT)

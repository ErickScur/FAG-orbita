import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
OUT = os.path.join(ROOT, "tests", "qa", "f62_tour.json")
from qa_build import R

r = R()


def tp(x, y):
    r.call("Docks/Player.set_indexed", "global_position:x", x * 16 + 8)
    r.call("Docks/Player.set_indexed", "global_position:y", (y + 1) * 16 - 1)


r.call("Settings.set", "difficulty", "easy")
r.call("GameState.new_game")
r.scene("res://scenes/levels/docks.tscn")
r.at(20); r.expect_scene("res://scenes/levels/docks.tscn")
r.at(50); r.shot("00_fala")
r.accept(6, 10)
r.wait(30); r.expect(3, 48, "spawn"); r.shot("01_spawn")
r.wait(5); tp(16, 48); r.wait(30); r.shot("02_galeria")
r.wait(5); tp(25, 48); r.wait(30); r.expect(25, 48, "brecha"); r.shot("03_brecha")
r.wait(5); tp(47, 40); r.wait(40); r.expect(47, 40, "console_a"); r.shot("04_hangar_selado")
r.call("Docks/EnergyNetwork.toggle", "docks", "containment")
r.wait(60); r.shot("05_hangar_vacuo")
r.wait(5); tp(62, 40); r.wait(30); r.shot("06_berco")
r.call("GameState.unlock_ability", "thruster")
r.wait(5); tp(22, 20); r.wait(60); r.shot("07_vestiario")
r.wait(5); tp(50, 4); r.wait(30); r.shot("08_duto")
r.wait(5); tp(95, 7); r.wait(30); r.shot("09_anel")
r.wait(5); tp(112, 25); r.wait(30); r.shot("10_vestibulo")
r.wait(5); tp(100, 44); r.wait(30); r.shot("11_antessala")
r.wait(5); tp(112, 40); r.wait(30); r.shot("12_no")
r.wait(10); r.quit()
r.save(OUT)

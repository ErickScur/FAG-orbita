import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
OUT = os.path.join(ROOT, "tests", "qa", "review_reactor_pressure.json")
from qa_build import R

SECONDS = 100
r = R()
r.call("Settings.set", "difficulty", "normal")
r.call("Settings.set", "no_timer", False)
r.call("GameState.new_game")
r.call("GameState.from_dict", {
    "flags": {"reactor_online": True, "dlg_dk_enter": True, "visited_docks": True},
    "abilities": ["dash", "beam", "magnetic_claws", "heat_sink", "heated_core"],
})
r.scene("res://scenes/levels/docks.tscn")
r.at(30); r.expect_scene("res://scenes/levels/docks.tscn")
r.at(40); r.expect(3, 48, "parado_na_galeria")
r.add(expect_call="GameState.is_reactor_running", equals=True, label="relogio_correndo")
r.shot("01_inicio")
r.at(40 + SECONDS * 60); r.expect(3, 48, "ainda_parado")
r.add(expect_call="GameState.is_reactor_running", equals=True, label="ainda_correndo")
r.tap("map", 3, 20)
r.shot("02_terminal_do_chassi_depois_de_100_s")
r.tap("ui_cancel", 3, 20)
r.wait(10); r.quit()
r.save(OUT)

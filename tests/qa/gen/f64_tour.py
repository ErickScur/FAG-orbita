import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
OUT = os.path.join(ROOT, "tests", "qa", "f64_tour.json")
from qa_build import R

SCENE = "res://scenes/levels/memory_core.tscn"
PLAYER = "MemoryCore/Player"
r = R()


def tp(x, y):
    r.call(PLAYER + ".set_indexed", "global_position:x", x * 16 + 8)
    r.call(PLAYER + ".set_indexed", "global_position:y", (y + 1) * 16 - 1)


r.call("Settings.set", "difficulty", "normal")
r.call("GameState.new_game")
r.call("GameState.set", "flags", {"dlg_mem_enter": True})
r.scene(SCENE)
r.at(30); r.expect_scene(SCENE)
r.at(60); r.expect(4, 55, "nascimento"); r.shot("01_refeitorio")
r.at(70); tp(20, 55)
r.at(90); r.shot("02_refeitorio_mesas")
r.at(100); tp(30, 55)
r.at(110); r.expect(30, 55, "base_do_poco"); r.shot("03_entra_no_poco")
r.at(240); r.shot("04_estatica_subindo")
r.at(250); tp(31, 46)
r.at(300); r.shot("05_poco_meio")
r.at(310)
r.add(expect_call="MemoryCore/Protocol.phase", equals=1, label="fase_1_ativa")
r.at(320); tp(42, 12)
r.at(360); r.add(expect_call="MemoryCore/Protocol.completed_phases", equals=1, label="fase_1_feita")
r.at(370); r.shot("06_arena")
r.at(380); r.add(expect_call="MemoryCore/Protocol.phase", equals=2, label="fase_2_ativa")
r.at(470); r.shot("07_arena_estatica")
r.at(480); tp(72, 12)
r.at(500); r.shot("08_vao")
r.at(510); tp(84, 12)
r.at(530); r.shot("09_console_b")
r.at(540); tp(120, 20)
r.at(600); r.add(expect_call="MemoryCore/Protocol.completed_phases", equals=2, label="fase_2_feita")
r.at(610); r.shot("10_corredor")
r.at(620); r.add(expect_call="MemoryCore/Protocol.phase", equals=3, label="fase_3_ativa")
r.press("move_left")
r.at(700); r.shot("11_lembranca_1")
r.at(800); r.shot("12_lembranca_2")
r.at(1000); r.shot("13_lembranca_3")
r.at(1300); r.shot("14_lembranca_4")
r.at(1600); r.shot("15_lembranca_5")
r.at(2000); r.shot("16_lembranca_6")
r.at(2400); r.shot("17_lembranca_7")
r.at(2800); r.release("move_left")
r.at(2810); r.shot("18_fim_corredor")
r.at(2820); r.quit()
r.save(OUT)

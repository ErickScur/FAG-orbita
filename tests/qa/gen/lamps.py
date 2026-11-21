import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from qa_build import R

OUT = os.path.join(ROOT, "tests", "qa", "lamps_tilesets.json")
LEVELS = [
    ("lab", "Lab"), ("infirmary", "Infirmary"), ("docks", "Docks"),
    ("memory_core", "MemoryCore"), ("reactor_core", "ReactorCore"), ("core_hub", "CoreHub"),
]
SEEN = ["core_wake", "core_alarm", "core_terminal_first", "core_lights_off", "hab_body",
        "hab_first_sr3", "lab_enter", "inf_enter", "dk_enter", "mem_enter", "mem_luto", "rc_enter"]
ABILITIES = ["magnetic_claws", "heat_sink", "heated_core", "thruster"]


def lamp_spot(level):
    with open(os.path.join(ROOT, "data", "levels", level + ".txt"), encoding="utf-8") as fh:
        rows = [line.rstrip("\n") for line in fh]
    for y, row in enumerate(rows):
        for x, char in enumerate(row):
            if char != "@":
                continue
            for floor in range(y + 1, len(rows)):
                below = rows[floor][x] if x < len(rows[floor]) else " "
                if below == "#":
                    if floor - y <= 6:
                        return x, floor - 1
                    break
    raise SystemExit("sem lâmpada com piso perto em " + level)


r = R()
r.call("Settings.set", "difficulty", "normal")
for level, root in LEVELS:
    x, y = lamp_spot(level)
    r.call("GameState.new_game")
    r.call("GameState.from_dict", {"flags": dict({"dlg_" + s: True for s in SEEN},
                                                 reactor_online=True),
                                   "abilities": ABILITIES})
    scene = "res://scenes/levels/%s.tscn" % level
    r.scene(scene)
    r.wait(40); r.expect_scene(scene)
    r.call(root + "/Player.set_indexed", "global_position:x", x * 16 + 8)
    r.call(root + "/Player.set_indexed", "global_position:y", (y + 1) * 16 - 1)
    r.wait(50); r.expect(x, y, "%s_lampada_%d_%d" % (level, x, y))
    r.shot("%s_lampada" % level)
    r.wait(10)
r.quit()
r.save(OUT)

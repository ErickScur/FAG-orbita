import json
import sys

OUT = sys.argv[1]
TRACE = len(sys.argv) > 2 and sys.argv[2] == 'trace'
state = {
    "flags": {
        "dlg_core_wake": True, "dlg_core_alarm": True, "dlg_core_terminal_first": True,
        "dlg_core_lights_off": True, "dlg_hab_body": True, "dlg_hab_first_sr3": True,
        "dlg_core_return": True, "dlg_gh_enter": True, "dlg_gh_claws": True,
        "dlg_gh_restored": True, "reactor_online": True,
    },
    "abilities": ["magnetic_claws"],
    "sectors_restored": ["greenhouse"],
    "energy_states": {"core_hub": ["door_habitat"]},
    "current_objective": "obj_core_lab",
    "checkpoint": {"scene": "res://scenes/levels/core_hub.tscn", "dock_id": "hab_dock_02"},
}
J = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
ev = [
    {"frame": 1, "call": "Settings.set", "args": ["difficulty", "normal"]},
    {"frame": 1, "call": "GameState.new_game", "args": []},
    {"frame": 1, "call": "GameState.from_dict", "args": [state]},
    {"frame": 1, "scene": "res://scenes/levels/core_hub.tscn"},
    {"frame": 40, "expect_scene": "res://scenes/levels/core_hub.tscn"},
    {"frame": 80, "expect_tile": [95, 11], "tolerance": 1, "label": "01_doca_da_ala"},
    {"frame": 81, "action": "move_left", "pressed": True},
    {"frame": J.get("left_end", 95), "action": "move_left", "pressed": False},
    {"frame": 100, "action": "jump", "pressed": True},
    {"frame": J.get("grab", 112), "action": "move_left", "pressed": True},
    {"frame": 116, "action": "jump", "pressed": False},
    {"frame": 125, "action": "move_up", "pressed": True},
    {"frame": 127, "action": "move_left", "pressed": False},
    {"frame": J.get("up_end", 230), "action": "move_up", "pressed": False},
    {"frame": J.get("up_end", 230) + 5, "action": "jump", "pressed": True},
    {"frame": J.get("up_end", 230) + 7, "action": "move_right", "pressed": True},
    {"frame": J.get("up_end", 230) + 15, "action": "jump", "pressed": False},
    {"frame": J.get("right_end", 320), "action": "move_right", "pressed": False},
]
end = J.get("right_end", 320)
if TRACE:
    for f in list(range(84, 240, 4)) + list(range(240, end + 10, 6)):
        ev.append({"frame": f, "screenshot": "t%03d" % f})
else:
    ev += [
        {"frame": 126, "screenshot": "01_garras_na_parede_magnetica"},
        {"frame": J.get("up_end", 230) - 2, "screenshot": "02_topo_da_chamine"},
        {"frame": end + 15, "expect_call": "GameState.plates_installed", "equals": 1,
         "label": "03_placa_do_nucleo_instalada"},
        {"frame": end + 16, "expect_tile": J.get("vault_tile", [101, 4]), "tolerance": 1,
         "label": "03_no_cofre_acima_da_doca"},
        {"frame": end + 18, "screenshot": "03_placa_coletada"},
        {"frame": end + 30, "action": "map", "pressed": True},
        {"frame": end + 33, "action": "map", "pressed": False},
        {"frame": end + 50, "screenshot": "04_terminal_do_chassi"},
        {"frame": end + 55, "action": "ui_cancel", "pressed": True},
        {"frame": end + 58, "action": "ui_cancel", "pressed": False},
    ]
ev.append({"frame": end + 70, "quit": True})
ev = sorted(enumerate(ev), key=lambda pair: (pair[1]["frame"], pair[0]))
lines = ",\n  ".join(json.dumps(e, ensure_ascii=False) for _, e in ev)
open(OUT, "w").write("[\n  " + lines + "\n]\n")

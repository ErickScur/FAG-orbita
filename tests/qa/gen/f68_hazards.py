import json
import sys

path = sys.argv[1]
T = True
F = False
S = 0
events = [
    {"frame": 1, "call": "Settings.set", "args": ["difficulty", "normal"]},
    {"frame": 1, "call": "GameState.new_game", "args": []},
    {"frame": 1, "scene": "res://scenes/dev/hazard_test.tscn"},
    {"frame": 40, "expect_scene": "res://scenes/dev/hazard_test.tscn"},
    {"frame": 44, "expect_tile": [1, 10], "tolerance": 1, "label": "nasce_na_doca"},
    {"frame": 45, "action": "move_right", "pressed": T},
    {"frame": 105, "action": "move_right", "pressed": F},
    {"frame": 125, "expect_tile": [8, 10], "tolerance": 0, "label": "base_60_quadros_7_tiles"},
    {"frame": 125, "screenshot": "01_base_60_quadros"},
    {"frame": 130, "action": "move_left", "pressed": T},
    {"frame": 230, "action": "move_left", "pressed": F},
    {"frame": 240, "expect_tile": [1, 10], "tolerance": 0, "label": "volta_a_doca"},
    {"frame": 242, "call": "GameState.spend_charge", "args": [15]},
    {"frame": 250, "expect_call": "GameState.has_status", "args": ["overload"], "equals": F, "label": "sem_sobrecarga_antes"},
    {"frame": 260, "screenshot": "02_recarregando"},
    {"frame": 400, "expect_call": "GameState.has_status", "args": ["overload"], "equals": F, "label": "sem_sobrecarga_antes_de_encher"},
    {"frame": 440, "expect_call": "GameState.has_status", "args": ["overload"], "equals": T, "label": "sobrecarga_ao_completar"},
    {"frame": 441, "screenshot": "03_sobrecarga_na_doca"},
    {"frame": 445, "action": "move_right", "pressed": T},
    {"frame": 475, "screenshot": "04_rastro"},
    {"frame": 505, "action": "move_right", "pressed": F},
    {"frame": 525, "expect_tile": [10, 10], "tolerance": 0, "label": "sobrecarga_60_quadros_9_tiles"},
    {"frame": 525, "screenshot": "05_sobrecarga_60_quadros"},
    {"frame": 530, "call": "GameState.clear_status", "args": ["overload"]},
    {"frame": 535, "action": "move_right", "pressed": T},
    {"frame": 635, "action": "move_right", "pressed": F},
    {"frame": 650, "expect_tile": [21, 10], "tolerance": 0, "label": "em_cima_do_piso"},
    {"frame": 650, "screenshot": "06_no_piso"},
    {"frame": 652, "expect_call": "GameState.has_status", "args": ["discharge"], "equals": T, "label": "descarga_no_piso"},
    {"frame": 653, "expect_call": "HazardTest/Player.is_discharged", "equals": T, "label": "mu7_descarregado"},
    {"frame": 655, "action": "dash", "pressed": T},
    {"frame": 658, "action": "dash", "pressed": F},
    {"frame": 660, "expect_call": "HazardTest/Player.is_dashing", "equals": F, "label": "dash_nao_sai"},
    {"frame": 661, "screenshot": "07_dash_recusado"},
    {"frame": 665, "call": "GameState.repair", "args": [100]},
    {"frame": 725, "screenshot": "08_piso_queima_1s"},
    {"frame": 726, "expect_call": "GameState.get", "args": ["integrity"], "equals": 92, "label": "piso_tira_8_por_segundo"},
]
late = [
    {"frame": 730, "action": "move_left", "pressed": T},
    {"frame": 772, "action": "move_left", "pressed": F},
    {"frame": 790, "expect_tile": [16, 10], "tolerance": 0, "label": "no_terminal"},
    {"frame": 790, "screenshot": "10_no_terminal"},
    {"frame": 795, "action": "interact", "pressed": T},
    {"frame": 798, "action": "interact", "pressed": F},
    {"frame": 815, "screenshot": "11_terminal_aberto"},
    {"frame": 820, "action": "interact", "pressed": T},
    {"frame": 823, "action": "interact", "pressed": F},
    {"frame": 840, "screenshot": "12_grade_desligada"},
    {"frame": 845, "action": "ui_cancel", "pressed": T},
    {"frame": 848, "action": "ui_cancel", "pressed": F},
    {"frame": 870, "action": "move_right", "pressed": T},
    {"frame": 910, "action": "move_right", "pressed": F},
    {"frame": 930, "expect_tile": [21, 10], "tolerance": 0, "label": "de_volta_ao_piso"},
    {"frame": 931, "call": "GameState.repair", "args": [100]},
    {"frame": 1150, "expect_call": "HazardTest/Player.is_discharged", "equals": F, "label": "piso_desligado_nao_descarrega"},
    {"frame": 1151, "expect_call": "GameState.get", "args": ["integrity"], "equals": 100, "label": "piso_desligado_nao_queima"},
    {"frame": 1152, "screenshot": "13_piso_apagado"},
    {"frame": 1155, "action": "dash", "pressed": T},
    {"frame": 1158, "action": "dash", "pressed": F},
    {"frame": 1160, "expect_call": "HazardTest/Player.is_dashing", "equals": T, "label": "dash_volta"},
    {"frame": 1165, "screenshot": "14_dash_livre"},
    {"frame": 1200, "quit": T},
]
for event in late:
    event["frame"] += S
events += late
text = "[\n" + ",\n".join("  " + json.dumps(e, ensure_ascii=False) for e in events) + "\n]\n"
open(path, "w").write(text)

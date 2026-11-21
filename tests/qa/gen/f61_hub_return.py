import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
OUT = os.path.join(ROOT, "tests", "qa", "f61_hub_return.json")
from qa_build import R
FLAGS = {"dlg_core_wake": True, "dlg_core_alarm": True, "dlg_core_terminal_first": True,
         "dlg_core_lights_off": True, "dlg_hab_body": True, "dlg_hab_first_sr3": True,
         "dlg_core_return": True, "reactor_online": True}
r = R()
r.call("Settings.set", "difficulty", "normal")
r.call("GameState.new_game")
r.call("GameState.from_dict", {"flags": FLAGS, "abilities": ["magnetic_claws"],
       "sectors_restored": ["greenhouse"], "energy_states": {"core_hub": ["door_habitat"]},
       "checkpoint": {"scene": "res://scenes/levels/core_hub.tscn", "dock_id": ""},
       "current_objective": "obj_core_lab"})
r.scene("res://scenes/levels/core_hub.tscn")
r.at(20); r.expect_scene("res://scenes/levels/core_hub.tscn")
r.at(80); r.expect(95, 12, "01_depois_da_estufa_doca_habitacional")
r.at(81); r.hold("move_right", 74)
r.at(220); r.expect(104, 11, "02_comporta_da_enfermaria_selada"); r.shot("02_comporta_da_enfermaria_selada")
r.at(222); r.expect_scene("res://scenes/levels/core_hub.tscn")
r.at(232); r.call("GameState.new_game")
r.call("GameState.from_dict", {"flags": FLAGS, "abilities": ["magnetic_claws", "heat_sink"],
       "sectors_restored": ["greenhouse", "lab"],
       "energy_states": {"core_hub": ["door_habitat"], "lab": ["wing_door", "node_door"]},
       "checkpoint": {"scene": "res://scenes/levels/core_hub.tscn", "dock_id": ""},
       "current_objective": "obj_lab",
       "logs_collected": ["log_core_01", "log_hab_01", "log_gh_01", "log_gh_02", "log_lab_01", "log_lab_02"]})
r.scene("res://scenes/levels/core_hub.tscn")
r.at(251); r.expect_scene("res://scenes/levels/core_hub.tscn")
r.at(311); r.expect(95, 12, "03_revisita_do_lab_nasce_no_habitacional"); r.shot("03_revisita_do_lab")
r.at(312); r.accept(4, 10)
r.at(404); r.shot("04_mais_clara_objetivo_enfermaria")
r.at(405); r.hold("move_right", 46)
r.at(520); r.expect(101, 11, "05_portal_da_estufa_aberto", 2)
r.at(522); r.hold("move_right", 74)
r.at(640); r.expect(109, 11, "06_portal_do_lab_aberto", 2); r.shot("06_portal_do_lab_aberto")
r.at(642); r.expect_scene("res://scenes/levels/core_hub.tscn")
r.at(644); r.shot("07_comporta_da_enfermaria_aberta")
r.at(646); r.hold("move_right", 70)
r.at(740); r.expect(117, 12, "07b_no_portal_da_enfermaria"); r.shot("07b_no_portal_da_enfermaria")
r.at(742); r.interact()
r.at(950); r.expect_scene("res://scenes/levels/infirmary.tscn")
r.at(970); r.shot("08_chegada_a_enfermaria")
r.at(980); r.quit()
r.save(OUT)

import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from qa_build import R

OUT = os.path.join(ROOT, "tests", "qa", "f62_hub_docks.json")
HUB = "res://scenes/levels/core_hub.tscn"
DOCKS = "res://scenes/levels/docks.tscn"
FLAGS = {"dlg_core_wake": True, "dlg_core_alarm": True, "dlg_core_terminal_first": True,
         "dlg_core_lights_off": True, "dlg_hab_body": True, "dlg_hab_first_sr3": True,
         "dlg_core_return": True, "dlg_core_return_lab": True,
         "dlg_core_return_infirmary": True, "dlg_gh_enter": True, "dlg_gh_claws": True,
         "dlg_gh_restored": True, "dlg_lab_enter": True, "dlg_inf_enter": True,
         "dlg_inf_restored": True, "reactor_online": True}
SAVE = {"flags": FLAGS, "abilities": ["magnetic_claws", "heat_sink", "heated_core"],
        "sectors_restored": ["greenhouse", "lab", "infirmary"],
        "energy_states": {"core_hub": ["door_habitat"]},
        "checkpoint": {"scene": HUB, "dock_id": "hab_dock_02"},
        "current_objective": "obj_core_docks"}

r = R()
r.call("Settings.set", "difficulty", "normal")
r.call("GameState.new_game")
r.call("GameState.from_dict", SAVE)
r.call("SaveManager.save_game")
r.call("GameState.new_game")
r.call("SaveManager.load_game")
r.scene(HUB)
r.at(20); r.expect_scene(HUB)
r.at(80); r.expect(95, 12, "01_continuar_na_doca_da_ala"); r.shot("01_continuar_enfermaria_religada")
r.add(expect_call="GameState.get", args=["current_objective"], equals="Chegar às Docas",
      label="01_objetivo_docas")
r.at(81); r.hold("move_right", 261)
r.at(400); r.expect(125, 12, "02_portal_das_docas"); r.shot("02_portal_das_docas_aberto")
r.at(402); r.interact()
r.at(580); r.expect_scene(DOCKS)
r.at(600); r.shot("03_fala_de_entrada_das_docas")
r.at(610); r.accept(6, 10)
r.at(720); r.expect(1, 48, "04_chegou_pelo_portal_das_docas"); r.shot("04_chegou_pelo_portal_das_docas")
r.add(expect_call="GameState.get", args=["current_objective"], equals="Religar as Docas",
      label="04_objetivo_religar_docas")
r.at(730); r.interact()
r.at(900); r.expect_scene(HUB)
r.at(930); r.expect(125, 12, "05_de_volta_na_porta_das_docas"); r.shot("05_de_volta_na_porta_das_docas")
r.at(940); r.quit()
r.save(OUT)

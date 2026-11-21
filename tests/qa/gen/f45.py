import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from qa_build import R

QA = os.path.join(ROOT, "tests", "qa")
HUB = "res://scenes/levels/core_hub.tscn"
GH = "res://scenes/levels/greenhouse.tscn"
FLAGS = {"dlg_core_wake": True, "dlg_core_alarm": True, "dlg_core_terminal_first": True,
         "dlg_core_lights_off": True, "dlg_hab_body": True, "dlg_hab_first_sr3": True,
         "dlg_core_return": True, "dlg_core_return_lab": True,
         "dlg_core_return_infirmary": True, "dlg_gh_enter": True,
         "dlg_gh_claws": True, "dlg_gh_restored": True, "dlg_lab_enter": True,
         "dlg_inf_enter": True, "reactor_online": True}


def state(restored, checkpoint, objective, energy=None):
    data = {"flags": FLAGS, "abilities": ["magnetic_claws"], "sectors_restored": restored,
            "energy_states": energy or {"core_hub": ["door_habitat"]},
            "current_objective": objective}
    if checkpoint:
        data["checkpoint"] = checkpoint
    return data


def start(r, data, scene):
    r.call("Settings.set", "difficulty", "normal")
    r.call("GameState.new_game")
    r.call("GameState.from_dict", data)
    r.scene(scene)


def door_back():
    r = R()
    start(r, state([], None, "obj_greenhouse"), GH)
    r.at(20); r.expect_scene(GH)
    r.at(60); r.expect(4, 62, "01_entrada_da_estufa")
    r.at(61); r.hold("move_left", 16)
    r.at(100); r.expect(2, 62, "02_na_porta_de_volta"); r.shot("02_porta_de_volta_ao_nucleo")
    r.at(102); r.interact()
    r.at(260); r.expect_scene(HUB)
    r.at(290); r.expect(101, 12, "03_chegou_na_porta_da_estufa"); r.shot("03_chegou_na_porta_da_estufa")
    r.at(300); r.call("GameState.new_game")
    r.call("SaveManager.load_game")
    r.scene(HUB)
    r.at(330); r.expect_scene(HUB)
    r.at(370); r.expect(95, 12, "04_continuar_na_doca_da_ala"); r.shot("04_continuar_na_doca_da_ala")
    r.at(380); r.quit()
    r.save(os.path.join(QA, "f45_a_volta_pela_porta.json"))


def restored_revisit():
    r = R()
    energy = {"core_hub": ["door_habitat"], "greenhouse": ["wing_door", "node_door"]}
    start(r, state(["greenhouse"], {"scene": HUB, "dock_id": "hab_dock_02"}, "obj_core_lab",
                   energy), HUB)
    r.at(20); r.expect_scene(HUB)
    r.at(80); r.expect(95, 12, "01_doca_da_ala")
    r.at(81); r.hold("move_right", 52)
    r.at(160); r.expect(101, 12, "02_portal_da_estufa_aberto"); r.shot("02_portal_da_estufa_aberto")
    r.at(162); r.interact()
    r.at(330); r.expect_scene(GH)
    r.at(360); r.expect(2, 62, "03_estufa_religada_pela_porta"); r.shot("03_estufa_religada_clara")
    r.at(362); r.hold("move_right", 60)
    r.at(440); r.shot("04_estufa_religada_corredor")
    r.at(442); r.hold("move_left", 62)
    r.at(520); r.expect(2, 62, "05_de_volta_a_porta")
    r.at(522); r.interact()
    r.at(690); r.expect_scene(HUB)
    r.at(720); r.expect(101, 12, "06_de_novo_na_porta_da_estufa"); r.shot("06_de_novo_na_porta_da_estufa")
    r.at(730); r.quit()
    r.save(os.path.join(QA, "f45_b_estufa_religada.json"))


def sealed_wing():
    r = R()
    start(r, state(["greenhouse", "lab"], {"scene": HUB, "dock_id": "hab_dock_02"},
                   "obj_core_infirmary"), HUB)
    r.at(20); r.expect_scene(HUB)
    r.at(80); r.expect(95, 12, "01_doca_da_ala")
    r.at(81); r.hold("move_right", 230)
    r.at(330); r.expect(120, 12, "02_comporta_das_docas_selada"); r.shot("02_comporta_das_docas_selada")
    r.at(340); r.call("GameState.new_game")
    r.call("GameState.from_dict", state(["greenhouse", "lab", "infirmary"],
                                        {"scene": HUB, "dock_id": "core_dock_wing"},
                                        "obj_core_docks"))
    r.scene(HUB)
    r.at(370); r.expect_scene(HUB)
    r.at(420); r.expect(129, 12, "03_doca_da_rotunda"); r.shot("03_docas_abertas_saida_viva")
    r.at(422); r.hold("move_right", 130)
    r.at(600); r.expect(142, 15, "04_comporta_da_memoria_selada"); r.shot("04_memoria_e_reator_selados")
    r.at(610); r.quit()
    r.save(os.path.join(QA, "f45_c_ala_selada.json"))


door_back()
restored_revisit()
sealed_wing()

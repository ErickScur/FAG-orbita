import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from qa_build import R

HUB = "res://scenes/levels/core_hub.tscn"
MEMORY = "res://scenes/levels/memory_core.tscn"
ABILITIES = ["magnetic_claws", "heat_sink", "heated_core", "thruster"]
DOCKS_DONE = ["greenhouse", "lab", "infirmary", "docks"]
FLAGS = {
    "dlg_core_wake": True, "dlg_core_alarm": True, "dlg_core_terminal_first": True,
    "dlg_core_lights_off": True, "dlg_hab_body": True, "dlg_hab_first_sr3": True,
    "dlg_core_return": True, "dlg_core_return_lab": True, "dlg_core_return_infirmary": True,
    "dlg_core_return_docks": True, "dlg_gh_enter": True, "dlg_gh_claws": True,
    "dlg_gh_restored": True, "dlg_lab_enter": True, "dlg_inf_enter": True, "dlg_dk_enter": True,
    "dlg_dk_restored": True, "reactor_online": True,
}


def save(path, r):
    r.save(path)


def entry():
    r = R()
    state = {"flags": FLAGS, "abilities": ABILITIES, "sectors_restored": DOCKS_DONE,
             "energy_states": {"core_hub": ["door_habitat"]},
             "checkpoint": {"scene": HUB, "dock_id": "core_dock_wing"},
             "current_objective": "obj_core_memory"}
    r.call("Settings.set", "difficulty", "normal")
    r.call("GameState.new_game")
    r.call("GameState.from_dict", state)
    r.call("SaveManager.save_game")
    r.call("GameState.new_game")
    r.call("SaveManager.load_game")
    r.scene(HUB)
    r.at(20); r.expect_scene(HUB)
    r.at(80); r.expect(129, 11, "01_continuar_na_doca_da_ala"); r.shot("01_ala_com_docas_religadas")
    r.add(expect_call="GameState.get", args=["current_objective"], equals="Ir ao Núcleo de Memória",
          label="01_objetivo_memoria")
    r.at(81); r.hold("move_right", 160)
    r.at(260); r.expect(146, 14, "02_portal_da_memoria"); r.shot("02_comporta_da_memoria_aberta")
    r.at(262); r.interact()
    r.at(440); r.expect_scene(MEMORY)
    r.at(470); r.shot("03_fala_de_entrada_da_memoria")
    r.add(expect_call="DialogueManager.is_active", equals=True, label="03_fala_de_marco")
    r.at(480); r.accept(4, 12)
    r.at(600); r.expect(2, 55, "04_chegou_pelo_portal"); r.shot("04_refeitorio_da_memoria")
    r.add(expect_call="GameState.get", args=["current_objective"], equals="Religar a Memória",
          label="04_objetivo_religar_memoria")
    r.at(610); r.quit()
    save(os.path.join(ROOT, "tests", "qa", "f64_hub_entrada.json"), r)


def back():
    r = R()
    restored = DOCKS_DONE + ["memory"]
    state = {"flags": dict(FLAGS, dlg_mem_enter=True, dlg_mem_luto=True, dlg_mem_restored=True,
                           mem_protocol=3, earth_signal=True),
             "abilities": ABILITIES + ["root_access"], "sectors_restored": restored,
             "energy_states": {"core_hub": ["door_habitat"]},
             "checkpoint": {"scene": HUB, "dock_id": ""},
             "current_objective": "obj_memory"}
    r.call("Settings.set", "difficulty", "normal")
    r.call("GameState.new_game")
    r.call("GameState.from_dict", state)
    r.call("SaveManager.save_game")
    r.call("GameState.new_game")
    r.call("SaveManager.load_game")
    r.scene(HUB)
    r.at(20); r.expect_scene(HUB)
    r.at(60); r.shot("01_fala_de_volta_da_memoria")
    r.add(expect_call="DialogueManager.is_active", equals=True, label="01_fala_de_marco")
    r.at(70); r.accept(4, 12)
    r.at(170); r.shot("02_hub_mais_claro")
    r.add(expect_call="GameState.get", args=["current_objective"], equals="Religar o Reator",
          label="02_objetivo_reator")
    r.add(expect_call="GameState.has_ability", args=["root_access"], equals=True, label="02_root")
    r.at(172); r.call("CoreHub/Player.set_indexed", "global_position:x", 129 * 16 + 8)
    r.call("CoreHub/Player.set_indexed", "global_position:y", 12 * 16 - 1)
    r.at(200); r.expect(129, 11, "03_ala"); r.hold("move_right", 160)
    r.at(380); r.expect(146, 14, "04_portal_da_memoria"); r.shot("04_rotunda")
    r.at(382); r.interact()
    r.at(560); r.expect_scene(MEMORY)
    r.at(600); r.expect(2, 55, "05_memoria_religada"); r.shot("05_memoria_em_cores")
    r.add(expect_call="MemoryCore/Protocol.phase", equals=4, label="05_protocolo_desligado")
    r.at(601); r.hold("move_right", 300)
    r.at(920); r.shot("06_poco_intacto")
    r.add(expect_call="MemoryCore/Protocol.erased_count", equals=0, label="06_nada_apagado")
    r.at(930); r.quit()
    save(os.path.join(ROOT, "tests", "qa", "f64_hub_volta.json"), r)


entry()
back()

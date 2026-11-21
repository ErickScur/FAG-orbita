import os
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
OUT = os.path.join(ROOT, "tests", "qa", "f64_morte.json")
from qa_build import R

SCENE = "res://scenes/levels/memory_core.tscn"
PROTOCOL = "MemoryCore/Protocol"
r = R()
r.call("Settings.set", "difficulty", "normal")
r.call("GameState.new_game")
r.call("GameState.from_dict", {
    "abilities": ["magnetic_claws", "heat_sink", "heated_core", "thruster"],
    "sectors_restored": ["greenhouse", "lab", "infirmary", "docks"],
    "flags": {"dlg_mem_enter": True, "reactor_online": True},
    "current_objective": "obj_memory",
})
r.scene(SCENE)
r.at(30); r.expect_scene(SCENE)
r.at(60); r.expect(4, 55, "01_nascimento")
r.press("move_right")
r.at(300); r.release("move_right")
r.at(320); r.expect(31, 55, "02_parado_no_poco")
r.add(expect_call=PROTOCOL + ".phase", equals=1, label="02_fase_1_ativa")
r.at(540); r.shot("03_estatica_chegando")
r.at(577); r.shot("04_memoria_voltando")
r.add(expect_call="GameState.get", args=["integrity"], equals=85, label="04_dano_da_memoria")
r.add(expect_call=PROTOCOL + ".phase", equals=0, label="04_fase_1_refeita")
r.add(expect_call=PROTOCOL + ".erased_count", equals=0, label="04_poco_restaurado")
r.expect(7, 55, "04_de_volta_na_doca")
r.at(700); r.press("move_right")
r.at(740); r.call("GameState.set", "integrity", 10)
r.at(930); r.release("move_right")
r.at(950); r.add(expect_call=PROTOCOL + ".phase", equals=1, label="05_fase_1_de_novo")
r.at(1100); r.shot("05_sem_integridade")
r.at(1400); r.add(expect_call="GameState.get", args=["deaths"], equals=1, label="06_morreu")
r.at(1500); r.shot("06_renasceu")
r.add(expect_call=PROTOCOL + ".phase", equals=0, label="06_fase_1_limpa")
r.add(expect_call=PROTOCOL + ".erased_count", equals=0, label="06_nada_apagado")
r.expect(7, 55, "06_renasceu_na_doca_da_entrada")
r.at(1510); r.quit()
r.save(OUT)

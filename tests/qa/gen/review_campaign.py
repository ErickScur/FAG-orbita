import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from qa_build import R

QA = os.path.join(ROOT, "tests", "qa")
STATES = os.path.join(QA, "gen", "review_campaign_states")
CHAIN_SAVE = "user://review_campaign.json"
SCRATCH_SAVE = "user://review_campaign_scratch.json"
LV = "res://scenes/levels/"
HUB = LV + "core_hub.tscn"
GH = LV + "greenhouse.tscn"
LAB = LV + "lab.tscn"
INF = LV + "infirmary.tscn"
DK = LV + "docks.tscn"
MEM = LV + "memory_core.tscn"
RC = LV + "reactor_core.tscn"
CMD = LV + "command_room.tscn"
MENU = "res://scenes/ui/main_menu.tscn"
ROOTS = {HUB: "CoreHub", GH: "Greenhouse", LAB: "Lab", INF: "Infirmary", DK: "Docks",
         MEM: "MemoryCore", RC: "ReactorCore", CMD: "CommandRoom"}
SETUP_CALLS = {"GameState.new_game", "GameState.from_dict", "Settings.set",
               "SaveManager.save_game", "SaveManager.load_game"}


def lines_of(log_id):
    for name in sorted(n for n in os.listdir(os.path.join(ROOT, "data", "logs")) if n.endswith(".json")):
        data = json.load(open(os.path.join(ROOT, "data", "logs", name), encoding="utf-8"))
        for entry in data.get("logs", []):
            if entry["id"] == log_id:
                return len(entry["lines"])
    raise KeyError(log_id)


def dialogue_lines(seq_id):
    for name in sorted(n for n in os.listdir(os.path.join(ROOT, "data", "dialogue")) if n.endswith(".json")):
        data = json.load(open(os.path.join(ROOT, "data", "dialogue", name), encoding="utf-8"))
        seqs = data.get("sequences", data)
        if isinstance(seqs, dict) and seq_id in seqs:
            return len(seqs[seq_id].get("lines", []))
    raise KeyError(seq_id)


def load_state(name):
    path = os.path.join(STATES, name + ".json")
    if not os.path.exists(path):
        return None
    data = json.load(open(path, encoding="utf-8"))
    return data.get("state", data)


def tp(r, scene, x, y):
    root = ROOTS[scene]
    r.call(root + "/Player.set_indexed", "global_position:x", x * 16 + 8)
    r.call(root + "/Player.set_indexed", "global_position:y", (y + 1) * 16 - 1)


def check(r, target, equals, label, args=None):
    event = {"expect_call": target, "equals": equals, "label": label}
    if args is not None:
        event["args"] = args
    r.add(**event)


def objective(r, text, label):
    check(r, "GameState.get", text, label, ["current_objective"])


def dialogue(r, seq_id, label):
    check(r, "DialogueManager.is_active", True, label + "_fala_ativa")
    check(r, "DialogueManager.get", seq_id, label + "_qual_fala", ["_current_id"])


def silent(r, label):
    check(r, "DialogueManager.is_active", False, label + "_sem_fala")
    check(r, "DialogueManager.queue_size", 0, label + "_fila_vazia")


def read_log(r, log_id, gap=12):
    r.interact(gap)
    r.wait(10)
    r.accept(lines_of(log_id) * 2 + 1, gap)


def setup(r, state, save=CHAIN_SAVE):
    r.call("Settings.set", "difficulty", "normal")
    r.call("SaveManager.set", "save_path", save)
    r.call("GameState.new_game")
    if state is not None:
        r.call("GameState.from_dict", state)
        r.call("SaveManager.save_game")


def replay(r, original, offset=0, skip_labels=(), until=None):
    events = json.load(open(os.path.join(QA, original + ".json"), encoding="utf-8"))
    last = 0
    for event in events:
        if event.get("frame", 0) <= 1 and (event.get("call") in SETUP_CALLS or "scene" in event):
            continue
        if event.get("label") in skip_labels:
            continue
        if event.get("quit") or (until is not None and event.get("frame", 0) > until):
            continue
        copy = dict(event)
        copy["frame"] = event["frame"] + offset
        if "screenshot" in copy:
            copy["screenshot"] = "orig_" + copy["screenshot"]
        if "label" in copy:
            copy["label"] = "orig_" + copy["label"]
        r.ev.append(copy)
        last = max(last, copy["frame"])
    return last


def hub_return(r, start, seq_id, objective_text, from_x, door_x, portal_x, next_scene,
               next_dialogue, prefix):
    r.at(start); r.expect_scene(HUB)
    r.shot(prefix + "_a_volta_ao_hub")
    if seq_id:
        dialogue(r, seq_id, prefix + "_a")
        r.wait(10)
        r.accept(dialogue_lines(seq_id) * 2 + 1, 14)
        r.wait(40)
    silent(r, prefix + "_b")
    objective(r, objective_text, prefix + "_b_objetivo")
    r.shot(prefix + "_b_hub_depois_da_fala")
    r.wait(2)
    if isinstance(door_x, tuple):
        sx, sy, frames, px, py = door_x
        tp(r, HUB, sx, sy)
        r.wait(20)
        r.hold("move_right", frames)
        r.wait(20)
        r.expect(px, py, prefix + "_c_passou_a_comporta_ate_o_portal")
    else:
        tp(r, HUB, door_x - 2, 11)
        r.wait(20)
        r.hold("move_right", int((portal_x - door_x + 2) * 16 / 110 * 60) + 6)
        r.wait(20)
        r.expect(portal_x, 11, prefix + "_c_passou_a_comporta_ate_o_portal")
    r.shot(prefix + "_c_portal_seguinte")
    r.call("SaveManager.save_game")
    r.call("SaveManager.set", "save_path", SCRATCH_SAVE)
    r.wait(2)
    r.interact()
    r.wait(260)
    r.expect_scene(next_scene)
    if next_dialogue:
        dialogue(r, next_dialogue, prefix + "_d_entrada")
    r.shot(prefix + "_d_setor_seguinte")
    r.wait(10)
    r.quit()


def seg_00():
    r = R()
    setup(r, None)
    r.call("SaveManager.delete_save")
    r.scene(MENU)
    r.at(30); r.expect_scene(MENU); r.shot("00_menu_sem_save")
    r.at(50); r.tap("ui_accept", 3, 10)
    r.at(120); r.shot("00_briefing")
    r.at(140); r.tap("pause", 3, 10)
    r.at(520); r.expect_scene(HUB)
    dialogue(r, "core_wake", "00_acordar")
    objective(r, "Chegar à Estufa", "00_objetivo_estufa")
    r.shot("00_hub_acordar")
    r.at(530); r.accept(dialogue_lines("core_wake") * 2 + 1, 14)
    r.wait(40); silent(r, "00_depois_do_acordar")
    r.expect(5, 11, "00_nascimento")
    tp(r, HUB, 34, 11); r.wait(20)
    read_log(r, "log_core_01")
    r.wait(30); silent(r, "00_log_nucleo_lido")
    tp(r, HUB, 37, 11); r.wait(20)
    tp(r, HUB, 47, 5); r.wait(20)
    tp(r, HUB, 56, 11); r.wait(40)
    r.expect(56, 11, "00_console")
    r.interact(); r.wait(20)
    r.tap("move_down", 2, 6); r.tap("move_down", 2, 6)
    r.tap("interact", 2, 14)
    r.tap("move_up", 2, 6); r.tap("move_up", 2, 6)
    r.tap("interact", 2, 14)
    r.tap("move_down", 2, 6); r.tap("move_down", 2, 6)
    r.tap("interact", 2, 14)
    r.shot("00_terminal_porta_ligada")
    r.tap("ui_cancel", 3, 30)
    r.wait(120)
    r.hold("move_right", 40); r.wait(30)
    r.shot("00_alarme")
    r.accept(dialogue_lines("core_alarm") * 2 + 1, 14)
    r.wait(30)
    r.expect(61, 11, "00_depois_do_alarme")
    r.hold("move_right", 34); r.wait(30)
    r.shot("00_corpo")
    dialogue(r, "hab_body", "00_corpo")
    r.accept(dialogue_lines("hab_body") * 2 + 1, 14)
    r.wait(30)
    silent(r, "00_depois_do_corpo")
    r.expect(64, 11, "00_traje")
    read_log(r, "log_hab_01")
    r.wait(30)
    tp(r, HUB, 94, 11); r.wait(30)
    r.hold("move_right", 64); r.wait(20)
    r.expect(101, 11, "00_portal_da_estufa")
    r.shot("00_portal_da_estufa")
    r.call("SaveManager.save_game")
    r.call("SaveManager.set", "save_path", SCRATCH_SAVE)
    r.wait(2)
    r.interact(); r.wait(260)
    r.expect_scene(GH)
    dialogue(r, "gh_enter", "00_entrada_estufa")
    r.shot("00_estufa")
    r.wait(10); r.quit()
    r.save(os.path.join(QA, "review_campaign_00_novo_jogo.json"))


def seg_sector(key, name, state_name, scene, original, hub_seq, hub_objective, door_x, portal_x,
               next_scene, next_dialogue, hub_wait=30):
    r = R()
    setup(r, load_state(state_name))
    r.scene(scene)
    last = replay(r, original)
    hub_return(r, last + hub_wait, hub_seq, hub_objective, 0, door_x, portal_x, next_scene,
               next_dialogue, key)
    r.save(os.path.join(QA, "review_campaign_%s_%s.json" % (key, name)))


def seg_01():
    seg_sector("01", "estufa", "s00", GH, "f29_greenhouse", "core_return",
               "Chegar ao Laboratório", 105, 109, LAB, "lab_enter")


def seg_02():
    seg_sector("02", "laboratorio", "s01", LAB, "f60_lab", "core_return_lab",
               "Chegar à Enfermaria", 113, 117, INF, "inf_enter")


def seg_03():
    seg_sector("03", "enfermaria", "s02", INF, "f61_infirmary", "core_return_infirmary",
               "Chegar às Docas", 121, 125, DK, "dk_enter")


def seg_04():
    seg_sector("04", "docas", "s03", DK, "f62_docks", "core_return_docks",
               "Ir ao Núcleo de Memória", (129, 11, 160, 146, 14), 146, MEM, "mem_enter")


def seg_05():
    r = R()
    setup(r, load_state("s04"))
    r.scene(MEM)
    r.at(12); dialogue(r, "mem_enter", "05_entrada")
    r.at(14); r.accept(dialogue_lines("mem_enter") * 2 + 1, 8)
    last = replay(r, "f64_memory")
    r.at(last + 10)
    silent(r, "05_e")
    objective(r, "Religar o Reator", "05_e_objetivo")
    check(r, "GameState.has_ability", True, "05_e_root", ["root_access"])
    r.shot("05_e_portal_do_reator")
    r.call("SaveManager.save_game")
    r.call("SaveManager.set", "save_path", SCRATCH_SAVE)
    r.wait(2)
    r.interact()
    r.wait(260)
    r.expect_scene(RC)
    dialogue(r, "rc_enter", "05_f_entrada_reator")
    r.shot("05_f_reator")
    r.wait(10)
    r.quit()
    r.save(os.path.join(QA, "review_campaign_05_memoria.json"))


def seg_06():
    r = R()
    state = load_state("s05")
    state["flags"].pop("root_door_open_door_reactor", None)
    setup(r, state)
    r.scene(HUB)
    last = replay(r, "f65_reactor")
    r.at(last + 10)
    r.shot("06_sala_de_comando")
    r.call("SaveManager.save_game")
    r.wait(10)
    r.quit()
    r.save(os.path.join(QA, "review_campaign_06_reator.json"))


def seg_07():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import f66
    r = R()
    state = load_state("s06")
    state["checkpoint"] = {}
    state["flags"].pop("dlg_cmd_enter", None)
    setup(r, state)
    r.scene(CMD)
    r.at(40); r.expect_scene(CMD)
    dialogue(r, "cmd_enter", "07_entrada")
    r.shot("01_entrada_fala_da_orbita")
    r.at(50); r.accept(2, 16)
    r.at(96); r.expect(2, 12, "02_entrada_sem_fala"); r.shot("02_sala_de_comando")
    f66.choose(r, "seeding")
    f66.cutscene(r, "seeding")
    f66.epilogue(r, "seeding", "some")
    f66.credits_and_menu(r)
    r.save(os.path.join(QA, "review_campaign_07_final.json"))


CONTINUE_SAVE = "user://review_campaign_continue.json"


def mid_state(base, flags, checkpoint, extra=None):
    state = json.loads(json.dumps(load_state(base)))
    state["flags"].update(flags)
    state["checkpoint"] = checkpoint
    for key, value in (extra or {}).items():
        state[key] = value
    return state


def continue_cases():
    hub = lambda dock: {"scene": HUB, "dock_id": dock}
    s03 = load_state("s03")
    docks_mid = mid_state("s03", {"dlg_dk_enter": True, "dlg_dk_thruster": True,
                                   "dlg_lock_down": True, "lock_serralheiro_down": True,
                                   "visited_docks": True},
                          {"scene": DK, "dock_id": "dk_dock_05"},
                          {"abilities": s03["abilities"] + ["thruster"],
                           "current_objective": "Religar as Docas"})
    memory_mid = mid_state("s04", {"dlg_mem_enter": True, "dlg_mem_luto": True,
                                    "mem_protocol": 1, "visited_memory_core": True},
                           {"scene": MEM, "dock_id": "mem_dock_02"},
                           {"current_objective": "Religar a Memória"})
    reactor_mid = mid_state("s05", {"dlg_rc_enter": True, "visited_reactor_core": True},
                            {"scene": RC, "dock_id": "rc_dock_02"},
                            {"current_objective": "Desligar o ARGOS"})
    return [
        ("c0_tutorial", load_state("s00"), HUB, (95, 11), "Chegar à Estufa", []),
        ("c1_pos_estufa", load_state("s01"), HUB, (95, 11), "Chegar ao Laboratório", []),
        ("c2_pos_lab", load_state("s02"), HUB, (95, 11), "Chegar à Enfermaria", []),
        ("c3_pos_enfermaria", load_state("s03"), HUB, (129, 11), "Chegar às Docas", []),
        ("c4_pos_docas", load_state("s04"), HUB, (129, 11), "Ir ao Núcleo de Memória", []),
        ("c5_pos_memoria", load_state("s05"), HUB, (129, 11), "Religar o Reator",
         [("GameState.has_ability", True, ["root_access"])]),
        ("c6_docas_serralheiro_vencido", docks_mid, DK, (96, 25), "Religar as Docas",
         [("Docks/Entities/Serralheiro.is_defeated", True, None),
          ("Docks/Entities/Serralheiro.is_node_unlocked", True, None)]),
        ("c7_memoria_meio_do_protocolo", memory_mid, MEM, (47, 12), "Religar a Memória", []),
        ("c8_reator_doca_do_alto", reactor_mid, RC, (31, 11), "Desligar o ARGOS",
         [("ReactorCore/Argos.is_defeated", False, None)]),
        ("c9_sala_de_comando", load_state("s06"), CMD, (4, 12), "", []),
        ("c10_depois_do_fim", load_state("s07"), CMD, (4, 12), "",
         [("CommandRoom/Room.chosen", "", None)]),
    ]


def seg_continue():
    r = R()
    frame = 1
    for name, state, scene, tile, objective_text, extra in continue_cases():
        r.at(frame)
        setup(r, state, CONTINUE_SAVE)
        r.call("GameState.new_game")
        r.scene(MENU)
        r.at(frame + 40); r.expect_scene(MENU)
        r.at(frame + 50); r.tap("ui_accept", 3, 10)
        r.at(frame + 480); r.expect_scene(scene)
        r.expect(tile[0], tile[1], name + "_na_doca")
        r.shot(name)
        r.wait(30)
        silent(r, name)
        objective(r, objective_text, name + "_objetivo")
        for target, equals, args in extra:
            check(r, target, equals, name + "_" + target.rsplit(".", 1)[1], args)
        r.wait(10)
        r.shot(name + "_depois")
        frame = r.f + 10
    r.at(frame); r.quit()
    r.save(os.path.join(QA, "review_campaign_continuar.json"))


def seg_lab_root():
    r = R()
    setup(r, load_state("s05"), CONTINUE_SAVE)
    r.scene(LAB)
    r.at(40); r.expect_scene(LAB)
    r.at(70); silent(r, "00_revisita")
    tp(r, LAB, 42, 15)
    r.at(100); r.expect(42, 15, "01_dentro_do_segredo")
    r.hold("move_left", 70)
    r.wait(20)
    r.expect(38, 15, "02_barrado_pela_comporta_root")
    r.shot("02_prompt_na_comporta")
    check(r, "GameState.is_root_door_open", False, "02_fechada", ["lab_root_door"])
    r.interact(30)
    r.shot("03_depois_do_E")
    check(r, "GameState.is_root_door_open", True, "03_E_abre_a_comporta_root", ["lab_root_door"])
    check(r, "DialogueManager.is_active", False, "03_E_nao_reabre_o_log")
    r.wait(10)
    r.quit()
    r.save(os.path.join(QA, "review_campaign_lab_root.json"))


COLLECT = [
    (HUB, "hub", [("pick", 99, 4)]),
    (GH, "estufa", [("root", 19, 55, "move_right", 90, 28), ("pick", 27, 61), ("pick", 41, 5),
                    ("log", 41, 41, "log_gh_01"), ("pick", 4, 51), ("pick", 2, 51),
                    ("pick", 40, 31)]),
    (HUB, "hub_2", []),
    (LAB, "laboratorio", [("walk", 38, 15, "move_left", 100, 33)]),
    (HUB, "hub_3", []),
    (INF, "enfermaria", [("log", 64, 6, "log_inf_02"), ("pick", 69, 6), ("pick", 67, 5),
                         ("pick", 82, 45), ("pick", 73, 37)]),
    (HUB, "hub_4", []),
    (DK, "docas", [("root", 36, 40, "move_left", 80, 32), ("pick", 79, 20), ("pick", 81, 20),
                   ("log", 83, 20, "log_dk_02"), ("pick", 66, 29), ("pick", 114, 3)]),
    (HUB, "hub_5", []),
    (MEM, "memoria", [("log", 24, 24, "log_mem_01"), ("pick", 69, 9)]),
    (HUB, "hub_6", []),
    (RC, "reator", [("log", 21, 5, "log_rc_01"), ("pick", 50, 5)]),
]


def seg_collect():
    r = R()
    state = load_state("s05")
    setup(r, state, CONTINUE_SAVE)
    frame = 1
    for scene, name, items in COLLECT:
        r.at(frame)
        if scene == LAB:
            r.call("GameState.open_root_door", "lab_root_door")
        r.scene(scene)
        r.at(frame + 40); r.expect_scene(scene)
        if scene == RC:
            dialogue(r, "rc_enter", name)
            r.wait(10); r.accept(dialogue_lines("rc_enter") * 2 + 1, 14); r.wait(30)
        else:
            r.wait(30)
        silent(r, name + "_revisita")
        check(r, "GameState.is_timer_frozen", False, name + "_sem_cutscene")
        objective(r, "Desligar o ARGOS" if scene == RC else "Religar o Reator",
                  name + "_objetivo")
        r.shot(name + "_00_chegada")
        for index, item in enumerate(items):
            kind, x, y = item[0], item[1], item[2]
            tp(r, scene, x, y)
            r.wait(30)
            if kind == "log":
                read_log(r, item[3])
                r.wait(30)
                silent(r, "%s_%02d_log" % (name, index))
            elif kind in ("root", "walk"):
                if kind == "root":
                    r.interact(30)
                r.hold(item[3], item[4])
                r.wait(30)
                r.expect(item[5], y, "%s_%02d_placa_root" % (name, index))
            r.shot("%s_%02d_%s_%d_%d" % (name, index, kind, x, y))
        r.wait(10)
        frame = r.f + 10
    r.at(frame)
    check(r, "GameState.plates_installed", 4, "fim_4_placas")
    check(r, "GameState.capacitors_installed", 4, "fim_4_capacitores")
    check(r, "GameState.secrets_found", 5, "fim_5_segredos")
    check(r, "GameState.get", 200, "fim_integridade_max", ["integrity_max"])
    r.call("SaveManager.save_game")
    r.wait(10)
    r.tap("map", 3, 30); r.shot("fim_terminal_do_chassi")
    r.tap("ui_cancel", 3, 30)
    r.tap("log_archive", 3, 30)
    check(r, "SceneManager/PauseMenu/Root/Overlay/LogArchive.entry_count", 13, "fim_arquivo_13")
    r.shot("fim_arquivo_de_logs")
    r.tap("ui_cancel", 3, 30)
    r.tap("ui_cancel", 3, 30)
    r.scene("res://scenes/ui/ending_epilogue.tscn")
    r.wait(40)
    check(r, "EndingEpilogue.tier", "most", "fim_faixa_most")
    r.wait(10); r.quit()
    r.save(os.path.join(QA, "review_campaign_coleta_total.json"))


HELD = ["move_left", "move_right", "move_up", "move_down", "jump", "dash", "interact", "beam"]


def release_all(r):
    for action in HELD:
        r.release(action)


def screens_tour(r, label):
    r.tap("pause", 3, 20)
    check(r, "SceneManager/PauseMenu.get", True, label + "_pausa_aberta", ["is_open"])
    check(r, "GameState.is_timer_frozen", True, label + "_pausa_congela")
    r.shot(label + "_1_pausa")
    r.tap("ui_down", 3, 8); r.tap("ui_accept", 3, 25)
    check(r, "SceneManager/PauseMenu.overlay_owns_focus", True, label + "_mapa_aberto")
    r.shot(label + "_2_mapa")
    r.tap("ui_cancel", 3, 20)
    r.tap("ui_down", 3, 8); r.tap("ui_accept", 3, 25)
    r.shot(label + "_3_arquivo")
    r.tap("ui_cancel", 3, 20)
    r.tap("ui_down", 3, 8); r.tap("ui_accept", 3, 25)
    r.shot(label + "_4_opcoes")
    r.tap("ui_cancel", 3, 20)
    r.shot(label + "_5_volta_a_pausa")
    r.tap("ui_cancel", 3, 25)
    check(r, "SceneManager/PauseMenu.get", False, label + "_pausa_fechada", ["is_open"])
    r.tap("map", 3, 25)
    r.shot(label + "_6_terminal_do_chassi")
    r.tap("map", 3, 25)
    r.shot(label + "_7_mapa_pelo_tab")
    r.tap("ui_cancel", 3, 25)
    r.tap("log_archive", 3, 25)
    r.shot(label + "_8_arquivo_pelo_L")
    r.tap("ui_cancel", 3, 30)
    check(r, "SceneManager/PauseMenu.get", False, label + "_tudo_fechado", ["is_open"])
    r.shot(label + "_9_de_volta_ao_jogo")


def seg_screens_docks():
    r = R()
    state = load_state("s03")
    state["abilities"] = state["abilities"] + ["thruster"]
    setup(r, state, CONTINUE_SAVE)
    r.scene(DK)
    replay(r, "f63_serralheiro", until=430)
    r.at(431); release_all(r)
    r.at(440)
    check(r, "Docks/Entities/Serralheiro.phase_name", "ACTIVE", "00_luta_ativa")
    screens_tour(r, "docas_luta")
    check(r, "Docks/Entities/Serralheiro.phase_name", "ACTIVE", "10_luta_continua")
    r.wait(10); r.quit()
    r.save(os.path.join(QA, "review_campaign_telas_docas.json"))


def seg_screens_memory():
    r = R()
    setup(r, load_state("s04"), CONTINUE_SAVE)
    r.scene(MEM)
    r.at(12); r.accept(dialogue_lines("mem_enter") * 2 + 1, 8)
    replay(r, "f64_memory", until=320)
    r.at(321); release_all(r)
    r.at(330)
    check(r, "MemoryCore/Protocol.phase", 1, "00_fuga_ativa")
    screens_tour(r, "memoria_fuga")
    check(r, "MemoryCore/Protocol.phase", 1, "10_fuga_continua")
    check(r, "GameState.is_dead", False, "10_vivo")
    r.wait(10); r.quit()
    r.save(os.path.join(QA, "review_campaign_telas_memoria.json"))


def seg_screens_reactor():
    r = R()
    state = load_state("s05")
    state["flags"].pop("root_door_open_door_reactor", None)
    setup(r, state, CONTINUE_SAVE)
    r.scene(HUB)
    replay(r, "f65_reactor", until=1257)
    r.at(1258); release_all(r)
    r.at(1262)
    check(r, "ReactorCore/Argos.state_name", "active", "00_argos_ativo")
    screens_tour(r, "reator_argos")
    check(r, "ReactorCore/Argos.state_name", "active", "10_argos_continua")
    r.wait(10); r.quit()
    r.save(os.path.join(QA, "review_campaign_telas_reator.json"))


def seg_screens_room():
    r = R()
    state = load_state("s06")
    state["checkpoint"] = {}
    state["flags"].pop("dlg_cmd_enter", None)
    setup(r, state, CONTINUE_SAVE)
    r.scene(CMD)
    r.at(50); r.accept(2, 16)
    r.at(100)
    screens_tour(r, "sala")
    r.hold("move_right", 128); r.wait(32)
    r.expect(17, 12, "20_console_semeadura")
    r.interact(16)
    check(r, "CommandRoom/Room.is_busy", True, "21_confirmacao_aberta")
    r.tap("pause", 3, 20)
    r.shot("sala_22_pausa_na_confirmacao")
    r.tap("ui_cancel", 3, 20)
    r.tap("ui_cancel", 3, 20)
    r.shot("sala_23_depois_de_cancelar")
    r.wait(60)
    check(r, "CommandRoom/Room.chosen", "", "23_nada_escolhido")
    r.wait(10); r.quit()
    r.save(os.path.join(QA, "review_campaign_telas_sala.json"))


def seg_screens_cutscene():
    r = R()
    state = load_state("s01")
    state["flags"]["dlg_lab_enter"] = True
    setup(r, state, CONTINUE_SAVE)
    r.scene(LAB)
    r.at(40); r.expect_scene(LAB)
    r.at(60); tp(r, LAB, 98, 41)
    r.at(100); r.interact(10)
    r.at(170)
    check(r, "GameState.is_timer_frozen", True, "00_cutscene_rodando")
    r.shot("cutscene_0_religando")
    r.tap("pause", 3, 20)
    r.shot("cutscene_1_pausa_durante_cutscene")
    r.add(expect_call="SceneManager/PauseMenu.get", args=["is_open"], equals=True,
          label="01_pausa_abre_na_cutscene")
    r.tap("ui_cancel", 3, 20)
    r.tap("map", 3, 20)
    r.shot("cutscene_2_tab_durante_cutscene")
    r.tap("ui_cancel", 3, 20)
    r.wait(500)
    r.shot("cutscene_3_fala_de_religamento")
    r.accept(dialogue_lines("lab_restored") * 2 + 1, 14)
    r.wait(300)
    r.expect_scene(HUB)
    r.shot("cutscene_4_hub")
    r.wait(10); r.quit()
    r.save(os.path.join(QA, "review_campaign_telas_cutscene.json"))


SEGMENTS = {"00": seg_00, "01": seg_01, "02": seg_02, "03": seg_03, "04": seg_04,
            "05": seg_05, "06": seg_06, "07": seg_07, "continue": seg_continue,
            "coleta": seg_collect, "lab_root": seg_lab_root,
            "telas_docas": seg_screens_docks, "telas_memoria": seg_screens_memory,
            "telas_reator": seg_screens_reactor, "telas_sala": seg_screens_room,
            "telas_cutscene": seg_screens_cutscene}

if __name__ == "__main__":
    wanted = sys.argv[1:] or sorted(SEGMENTS)
    for key in wanted:
        SEGMENTS[key]()

import copy
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import review_campaign as rc
import f66
from qa_build import R

DEMO = os.path.join(rc.QA, "demo")
RES_DEMO = "res://tests/qa/demo/"
DEMO_SAVE = "user://demo_guiada.json"
DEMO_SCRATCH = "user://demo_guiada_rascunho.json"
SAVE_MAP = {rc.CHAIN_SAVE: DEMO_SAVE, rc.SCRATCH_SAVE: DEMO_SCRATCH, rc.CONTINUE_SAVE: DEMO_SAVE}
BRIEFING = os.path.join(rc.ROOT, "data", "ui", "briefing.json")
BRIEFING_NODE = "Briefing"
BRIEFING_SKIP_FRAME = 140
HOLD_BASE = 1.5
HOLD_PER_CHAR = 0.035
HOLD_MAX = 5.0
FPS = 60
TOUR_LOOK = 210
ENDINGS = {"semeadura": "seeding", "transmissao": "transmission"}
TIER = "some"
SECTOR_WAIT = 25
HUB_WAIT = 12
REACTOR_UNTIL = 2345
MEMORY_UNTIL = 7700
STARTS = {
    "completo": {"tutorial": 0, "estufa": 202, "hub_lab": 368, "laboratorio": 383,
                 "hub_enfermaria": 641, "enfermaria": 655, "hub_docas": 829, "docas": 856,
                 "hub_memoria": 1049, "memoria": 1062, "lab_root": 1211, "reator": 1218,
                 "final": 1270},
    "novidades": {"hub_docas": 0, "docas": 27, "hub_memoria": 220, "memoria": 233,
                  "lab_root": 382, "reator": 389, "final": 441},
}


def capture(builder):
    built = []
    original = R.save
    R.save = lambda self, path: built.append(self)
    try:
        builder()
    finally:
        R.save = original
    return built[-1]


def demo_saves(r):
    for event in r.ev:
        if event.get("call") == "SaveManager.set" and event["args"][0] == "save_path":
            event["args"] = [event["args"][0], SAVE_MAP.get(event["args"][1], event["args"][1])]


def finish(r, until):
    r.ev = [e for e in r.ev if e["frame"] <= until and not e.get("quit")]
    r.at(until + 1)
    r.quit()


def last_action(r, action):
    frames = [e["frame"] for e in r.ev if e.get("action") == action and e.get("pressed")]
    return max(frames)


def last_input_before_scene(original, scene):
    events = json.load(open(os.path.join(rc.QA, original + ".json"), encoding="utf-8"))
    arrival = max(e["frame"] for e in events if e.get("expect_scene") == scene)
    return max(e["frame"] for e in events if "action" in e and e["frame"] < arrival)


def reading_frames(chars):
    return int(min(HOLD_MAX, HOLD_BASE + HOLD_PER_CHAR * chars) * FPS)


def check(r, target, equals, label, args=None):
    rc.check(r, target, equals, label, args)


def wait_call(r, target, equals, label, timeout, args=None):
    event = {"wait_call": target, "equals": equals, "label": label, "timeout": timeout}
    if args is not None:
        event["args"] = args
    r.add(**event)


def wait_scene(r, scene, label, timeout):
    r.add(wait_scene=scene, label=label, timeout=timeout)


def hub_state(state_name, flag):
    state = copy.deepcopy(rc.load_state(state_name))
    state["flags"].pop(flag, None)
    state["checkpoint"] = {}
    return state


def station_tour(r, prefix):
    r.tap("map", 3, 40)
    check(r, "CoreHub/HUD/ChassisMenu.get", True, prefix + "_t1_terminal_do_chassi", ["is_open"])
    r.shot(prefix + "_t1_terminal_do_chassi")
    r.wait(TOUR_LOOK - 40)
    r.tap("map", 3, 40)
    check(r, "CoreHub/HUD/ChassisMenu.current_page", "map", prefix + "_t2_mapa_da_estacao")
    r.shot(prefix + "_t2_mapa_da_estacao")
    r.wait(TOUR_LOOK)
    r.tap("ui_cancel", 3, 30)
    check(r, "CoreHub/HUD/ChassisMenu.get", False, prefix + "_t3_mapa_fechado", ["is_open"])
    r.tap("log_archive", 3, 40)
    check(r, "SceneManager/PauseMenu.get", True, prefix + "_t4_arquivo_aberto", ["is_open"])
    r.shot(prefix + "_t4_arquivo_de_logs")
    r.wait(TOUR_LOOK)
    r.tap("ui_cancel", 3, 40)
    check(r, "SceneManager/PauseMenu.get", False, prefix + "_t5_tudo_fechado", ["is_open"])
    rc.silent(r, prefix + "_t5")


def hub_walk(r, start, seq_id, objective_text, door_x, portal_x, prefix, tour):
    r.at(start)
    r.expect_scene(rc.HUB)
    rc.dialogue(r, seq_id, prefix + "_a")
    r.shot(prefix + "_a_volta_ao_hub")
    r.wait(10)
    r.accept(rc.dialogue_lines(seq_id) * 2 + 1, 14)
    r.wait(40)
    rc.silent(r, prefix + "_b")
    rc.objective(r, objective_text, prefix + "_b_objetivo")
    if tour:
        station_tour(r, prefix)
    r.wait(2)
    if isinstance(door_x, tuple):
        sx, sy, frames, px, py = door_x
        rc.tp(r, rc.HUB, sx, sy)
        r.wait(20)
        r.hold("move_right", frames)
        r.wait(20)
        r.expect(px, py, prefix + "_c_portal")
    else:
        rc.tp(r, rc.HUB, door_x - 2, 11)
        r.wait(20)
        r.hold("move_right", int((portal_x - door_x + 2) * 16 / 110 * 60) + 6)
        r.wait(20)
        r.expect(portal_x, 11, prefix + "_c_portal")
    r.shot(prefix + "_c_portal_seguinte")
    r.wait(2)
    r.interact(2)
    finish(r, r.f)


def hub_chapter(key, state_name, seq_id, objective_text, door_x, portal_x, tour=False):
    r = R()
    rc.setup(r, hub_state(state_name, "dlg_" + seq_id))
    r.scene(rc.HUB)
    hub_walk(r, 40, seq_id, objective_text, door_x, portal_x, key, tour)
    return r


def sector_chapter(state_name, scene, original):
    r = R()
    rc.setup(r, rc.load_state(state_name))
    r.scene(scene)
    until = last_input_before_scene(original, rc.HUB) + 2
    rc.replay(r, original, until=until)
    finish(r, until)
    return r


def memory_chapter():
    r = R()
    rc.setup(r, rc.load_state("s04"))
    r.scene(rc.MEM)
    r.at(12)
    rc.dialogue(r, "mem_enter", "05_entrada")
    r.at(14)
    r.accept(rc.dialogue_lines("mem_enter") * 2 + 1, 8)
    rc.replay(r, "f64_memory", until=MEMORY_UNTIL)
    r.at(MEMORY_UNTIL - 5)
    rc.silent(r, "05_hub_depois_da_memoria")
    check(r, "GameState.has_ability", True, "05_root", ["root_access"])
    finish(r, MEMORY_UNTIL)
    return r


def lab_root_chapter():
    r = capture(rc.seg_lab_root)
    end = max(e["frame"] for e in r.ev if not e.get("quit"))
    r.ev = [e for e in r.ev if not e.get("quit")]
    r.at(end + 40)
    r.hold("move_left", 60)
    r.wait(40)
    r.shot("04_passou_a_comporta_root")
    finish(r, r.f + 1)
    return r


def reactor_chapter():
    r = R()
    state = copy.deepcopy(rc.load_state("s05"))
    state["flags"].pop("root_door_open_door_reactor", None)
    rc.setup(r, state)
    r.scene(rc.HUB)
    rc.replay(r, "f65_reactor", until=REACTOR_UNTIL)
    finish(r, REACTOR_UNTIL)
    return r


def demo_epilogue(r):
    r.add(expect_call="EndingEpilogue.tier", equals=TIER, label="12_faixa_" + TIER)
    r.wait(10)
    r.shot("12_epilogo")
    wait_call(r, "EndingEpilogue.stage_name", "names", "13_quarenta_nomes", 180)
    r.wait(20)
    r.shot("13_nomes")
    r.wait(400)
    r.shot("13_nomes_meio")
    wait_call(r, "EndingEpilogue.stage_name", "question", "14_pergunta", 240)
    r.wait(120)
    r.shot("14_pergunta")
    r.tap("ui_accept", 3, 20)
    wait_scene(r, f66.CREDITS, "15_creditos", 30)
    r.wait(300)
    r.shot("15_creditos")
    wait_scene(r, f66.MENU, "16_menu_depois_dos_creditos", 400)
    r.wait(90)
    r.add(expect_call="MainMenu/CompletedMark.is_visible_in_tree", equals=True,
          label="16_menu_marca_jogo_concluido")
    r.shot("16_menu")
    r.wait(10)
    r.quit()


def final_chapter(ending):
    r = R()
    state = copy.deepcopy(rc.load_state("s06"))
    state["checkpoint"] = {}
    state["flags"].pop("dlg_cmd_enter", None)
    rc.setup(r, state)
    r.scene(rc.CMD)
    r.at(40)
    r.expect_scene(rc.CMD)
    rc.dialogue(r, "cmd_enter", "07_entrada")
    r.at(50)
    r.accept(2, 16)
    r.at(96)
    r.expect(2, 12, "02_entrada_sem_fala")
    f66.choose(r, ending)
    f66.cutscene(r, ending)
    demo_epilogue(r)
    return r


def briefing_blocks():
    data = json.load(open(BRIEFING, encoding="utf-8"))
    sizes = []
    for block in data["blocks"]:
        chars = len(block.get("title", ""))
        chars += sum(len(a) + len(b) for a, b in block.get("fields", []))
        chars += sum(len(line) for line in block.get("lines", []))
        sizes.append(chars)
    return sizes


def tutorial_chapter():
    r = capture(rc.seg_00)
    skip = [e for e in r.ev if e.get("action") == "pause"]
    assert [e["frame"] for e in skip] == [BRIEFING_SKIP_FRAME, BRIEFING_SKIP_FRAME + 3]
    rest = [e for e in r.ev if e["frame"] > BRIEFING_SKIP_FRAME + 3]
    r.ev = [e for e in r.ev if e["frame"] < BRIEFING_SKIP_FRAME]
    r.at(BRIEFING_SKIP_FRAME - 10)
    for index, chars in enumerate(briefing_blocks()):
        wait_call(r, BRIEFING_NODE + ".is_block_complete", True,
                  "00_briefing_bloco_%d" % (index + 1), 30)
        r.wait(reading_frames(chars))
        r.shot("00_briefing_%d" % (index + 1))
        r.press("jump")
        leave = r.f
        r.wait(3)
        r.release("jump")
        r.wait(12)
    shift = leave - BRIEFING_SKIP_FRAME
    for event in rest:
        moved = dict(event)
        moved["frame"] = event["frame"] + shift
        r.ev.append(moved)
    finish(r, last_action(r, "interact") + 4)
    return r


def write(r, name):
    demo_saves(r)
    r.save(os.path.join(DEMO, name + ".json"))


NEWS = [
    ("hub_docas", "Núcleo Central: mapa, arquivo e rumo às Docas", HUB_WAIT,
     lambda: hub_chapter("hub_docas", "s03", "core_return_infirmary", "Chegar às Docas",
                         121, 125, tour=True)),
    ("docas", "Docas: Propulsor e o Serralheiro", SECTOR_WAIT,
     lambda: sector_chapter("s03", rc.DK, "f62_docks")),
    ("hub_memoria", "Núcleo Central: rumo ao Núcleo de Memória", HUB_WAIT,
     lambda: hub_chapter("hub_memoria", "s04", "core_return_docks", "Ir ao Núcleo de Memória",
                         (129, 11, 160, 146, 14), 146)),
    ("memoria", "Núcleo de Memória: Protocolo Luto e Acesso Root", 0, memory_chapter),
    ("lab_root", "Laboratório: o Acesso Root abre a comporta", 0, lab_root_chapter),
    ("reator", "Núcleo do Reator: ARGOS", 20, reactor_chapter),
    ("final", "Sala de comando, final e créditos", 0, None),
]

OLD = [
    ("tutorial", "Menu, briefing e tutorial", HUB_WAIT, tutorial_chapter),
    ("estufa", "Estufa", SECTOR_WAIT, lambda: sector_chapter("s00", rc.GH, "f29_greenhouse")),
    ("hub_lab", "Núcleo Central: rumo ao Laboratório", HUB_WAIT,
     lambda: hub_chapter("hub_lab", "s01", "core_return", "Chegar ao Laboratório", 105, 109)),
    ("laboratorio", "Laboratório", SECTOR_WAIT,
     lambda: sector_chapter("s01", rc.LAB, "f60_lab")),
    ("hub_enfermaria", "Núcleo Central: rumo à Enfermaria", HUB_WAIT,
     lambda: hub_chapter("hub_enfermaria", "s02", "core_return_lab", "Chegar à Enfermaria",
                         113, 117)),
    ("enfermaria", "Enfermaria", SECTOR_WAIT,
     lambda: sector_chapter("s02", rc.INF, "f61_infirmary")),
]


def chapter_entry(key, title, wait, playlist):
    script = RES_DEMO + ("final_{final}.json" if key == "final" else key + ".json")
    entry = {"id": key, "titulo": title, "roteiro": script, "espera_transicao": wait}
    start = STARTS.get(playlist, {}).get(key)
    if start is not None:
        entry["inicio_s"] = start
    return entry


def write_playlist(name, chapters):
    data = {"nome": name,
            "capitulos": [chapter_entry(key, title, wait, name) for key, title, wait, _ in chapters]}
    with open(os.path.join(DEMO, name + ".json"), "w", encoding="utf-8") as fh:
        fh.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main():
    os.makedirs(DEMO, exist_ok=True)
    for key, _, _, builder in OLD + NEWS:
        if builder is not None:
            write(builder(), key)
    for file_name, ending in ENDINGS.items():
        write(final_chapter(ending), "final_" + file_name)
    write_playlist("novidades", NEWS)
    write_playlist("completo", OLD + NEWS)


if __name__ == "__main__":
    main()

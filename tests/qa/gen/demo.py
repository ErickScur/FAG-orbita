import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import review_campaign as rc

DEMO = os.path.join(rc.QA, "demo")
RES_DEMO = "res://tests/qa/demo/"
SAVE_TAG = os.environ.get("DEMO_SAVE_TAG", "")
SAVE_SUFFIX = ("_" + SAVE_TAG) if SAVE_TAG else ""
DEMO_SAVE = "user://demo_guiada%s.json" % SAVE_SUFFIX
DEMO_SCRATCH = "user://demo_guiada_rascunho%s.json" % SAVE_SUFFIX
SAVE_MAP = {rc.CHAIN_SAVE: DEMO_SAVE, rc.SCRATCH_SAVE: DEMO_SCRATCH, rc.CONTINUE_SAVE: DEMO_SAVE}
BRIEFING = os.path.join(rc.ROOT, "data", "ui", "briefing.json")
BRIEFING_NODE = "Briefing"
BRIEFING_SKIP_FRAME = 140
HOLD_BASE = 0.5
HOLD_PER_CHAR = 0.015
HOLD_MAX = 2.0
FPS = 60
SECTOR_WAIT = 25
HUB_WAIT = 12
STARTS = {
    "completo": {"tutorial": 0, "estufa": 137, "hub_lab": 286, "laboratorio": 297,
                 "hub_enfermaria": 489, "enfermaria": 501, "hub_docas": 696, "docas": 718,
                 "hub_memoria": 935, "memoria": 950, "revisita_lab": 1113, "revisita": 1162,
                 "reator": 1233, "final": 1392},
    "novidades": {"hub_docas": 0, "docas": 22, "hub_memoria": 239, "memoria": 254,
                  "revisita_lab": 417, "revisita": 466, "reator": 537, "final": 696},
}


def demo_saves(r):
    for event in r.ev:
        if event.get("call") == "SaveManager.set" and event["args"][0] == "save_path":
            event["args"] = [event["args"][0], SAVE_MAP.get(event["args"][1], event["args"][1])]


def finish(r, until):
    r.ev = [e for e in r.ev if e["frame"] <= until and not e.get("quit")]
    r.at(until + 1)
    r.quit()


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


def briefing_blocks():
    data = json.load(open(BRIEFING, encoding="utf-8"))
    sizes = []
    for block in data["blocks"]:
        chars = len(block.get("title", ""))
        chars += sum(len(a) + len(b) for a, b in block.get("fields", []))
        chars += sum(len(line) for line in block.get("lines", []))
        sizes.append(chars)
    return sizes


def write(r, name):
    demo_saves(r)
    r.save(os.path.join(DEMO, name + ".json"))


def chapter_entry(key, title, wait, playlist):
    script = RES_DEMO + ("final_{final}.json" if key == "final" else key + ".json")
    entry = {"id": key, "titulo": title, "roteiro": script, "espera_transicao": wait}
    start = STARTS.get(playlist, {}).get(key)
    if start is not None:
        entry["inicio_s"] = start
    return entry


def write_playlist(name, chapters):
    data = {"nome": name,
            "capitulos": [chapter_entry(key, title, wait, name) for key, title, wait in chapters]}
    with open(os.path.join(DEMO, name + ".json"), "w", encoding="utf-8") as fh:
        fh.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


NEWS = [
    ("hub_docas", "Núcleo Central: mapa, arquivo e rumo às Docas", HUB_WAIT),
    ("docas", "Docas: Propulsor e o Serralheiro", SECTOR_WAIT),
    ("hub_memoria", "Núcleo Central: rumo ao Núcleo de Memória", HUB_WAIT),
    ("memoria", "Núcleo de Memória: Protocolo Luto e Acesso Root", 0),
    ("revisita_lab", "Laboratório: o Acesso Root abre a comporta", 0),
    ("revisita", "Portas ROOT: as placas da Estufa, das Docas e do Núcleo", 0),
    ("reator", "Núcleo do Reator: ARGOS", 20),
    ("final", "Sala de comando, final e créditos", 0),
]

OLD = [
    ("tutorial", "Menu, briefing e tutorial", HUB_WAIT),
    ("estufa", "Estufa", SECTOR_WAIT),
    ("hub_lab", "Núcleo Central: rumo ao Laboratório", HUB_WAIT),
    ("laboratorio", "Laboratório", SECTOR_WAIT),
    ("hub_enfermaria", "Núcleo Central: rumo à Enfermaria", HUB_WAIT),
    ("enfermaria", "Enfermaria", SECTOR_WAIT),
]


def chapters():
    import demo_antigos
    import demo_docas
    import demo_finais
    built = {}
    built.update(demo_antigos.CHAPTERS)
    built.update({key: demo_docas.CHAPTERS[key] for key in demo_docas.REAL})
    finals = {"memoria": demo_finais.memory_chapter, "reator": demo_finais.reactor_chapter,
              "final_semeadura": lambda: demo_finais.final_chapter("seeding"),
              "final_transmissao": lambda: demo_finais.final_chapter("transmission")}
    for key, builder in finals.items():
        built[key] = _reinforced(demo_finais, builder)
    return built


def _reinforced(module, builder):
    def build():
        r = builder()
        module.reinforce(r)
        return r
    return build


def main():
    os.makedirs(DEMO, exist_ok=True)
    for key, builder in chapters().items():
        write(builder(), key)
    write_playlist("novidades", NEWS)
    write_playlist("completo", OLD + NEWS)


if __name__ == "__main__":
    main()

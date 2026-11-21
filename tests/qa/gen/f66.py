import json
import os
import re
import sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from qa_build import R

QA = os.path.join(ROOT, "tests", "qa")
ROOM = "res://scenes/levels/command_room.tscn"
CUTSCENE = "res://scenes/ui/ending_cutscene.tscn"
EPILOGUE = "res://scenes/ui/ending_epilogue.tscn"
CREDITS = "res://scenes/ui/credits.tscn"
MENU = "res://scenes/ui/main_menu.tscn"
SPAWN = (2, 12)
WALK = {"seeding": 128, "transmission": 244}
CONSOLE = {"seeding": (17, 12), "transmission": (30, 12)}
CUT_AT = {"seeding": 14.0, "transmission": 13.5}
TEXT_CPS = 30.0
FPS = 60
ROOM_BEAT = 180
BLACK = 90
FADE = 30


def research_total():
    with open(os.path.join(ROOT, "scripts", "core", "balance.gd"), encoding="utf-8") as fh:
        return int(re.search(r"const RESEARCH_TOTAL: int = (\d+)", fh.read()).group(1))


def paragraphs(ending, tier):
    with open(os.path.join(ROOT, "data", "endings", "endings.json"), encoding="utf-8") as fh:
        return json.load(fh)["endings"][ending]["epilogue"][tier]


def typing_frames(text):
    return int(len(text) / TEXT_CPS * FPS) + 12


def research_ids(research):
    return ["qa_f66_research_%02d" % index for index in range(research)]


def start(r, research, flags=None):
    r.call("Settings.set", "difficulty", "normal")
    r.call("GameState.new_game")
    ids = research_ids(research)
    r.call("GameState.from_dict", {"research_collected": ids, "collected_ids": ids,
                                   "flags": flags or {}})


def enter_room(r, research):
    start(r, research)
    r.scene(ROOM)
    r.at(40); r.expect_scene(ROOM)
    r.shot("01_entrada_fala_da_orbita")
    r.at(50); r.accept(2, 16)
    r.at(96); r.expect(SPAWN[0], SPAWN[1], "02_entrada_sem_fala"); r.shot("02_sala_de_comando")


def choose(r, ending):
    r.at(100); r.hold("move_right", WALK[ending])
    r.wait(32)
    x, y = CONSOLE[ending]
    r.expect(x, y, "03_no_console_" + ending); r.shot("03_console_" + ending)
    r.wait(2); r.interact(16)
    r.add(expect_call="CommandRoom/Room.is_busy", equals=True, label="04_confirmacao_aberta")
    r.shot("04_confirmacao")
    r.tap("ui_left", 3, 12)
    r.tap("ui_accept", 3, 12)
    r.add(expect_call="CommandRoom/Room.chosen", equals=ending, label="05_escolha_registrada")
    r.shot("05_alavanca_puxada")
    r.wait(70); r.shot("06_sala_apagando")
    r.wait(ROOM_BEAT - 70 + 20)


def cutscene(r, ending):
    r.expect_scene(CUTSCENE)
    begin = r.f - 20
    r.at(begin + 100); r.shot("07_cutscene_inicio")
    r.at(begin + 330); r.shot("08_cutscene_execucao")
    if ending == "seeding":
        r.add(expect_call="EndingCutscene.capsule_launched", equals=True, label="08_capsula_partiu")
    r.at(begin + 620); r.shot("09_cutscene_apagando")
    cut = begin + int(CUT_AT[ending] * FPS)
    r.at(cut - 20); r.shot("10_ultimo_instante")
    r.at(cut + 30); r.add(expect_call="EndingCutscene.is_cut", equals=True, label="11_corte_seco")
    r.shot("11_preto")
    r.at(cut + BLACK + FADE * 2 + 40); r.expect_scene(EPILOGUE)


def read_paragraphs(r, ending, tier, shots):
    for index, text in enumerate(paragraphs(ending, tier)):
        r.wait(typing_frames(text))
        r.add(expect_call="EndingEpilogue.paragraph_index", equals=index,
              label="p%d_%s" % (index + 1, tier))
        if index in shots:
            r.shot("%s_p%d" % (shots[index], index + 1))
        r.tap("ui_accept", 3, 2)


def epilogue(r, ending, tier):
    r.add(expect_call="EndingEpilogue.tier", equals=tier, label="12_faixa_" + tier)
    read_paragraphs(r, ending, tier, {0: "12_epilogo", 1: "13_epilogo", 6: "13_epilogo"})
    r.wait(10)
    r.add(expect_call="EndingEpilogue.stage_name", equals="names", label="14_nomes")
    r.wait(240); r.shot("14_nomes_rolando")
    r.wait(360); r.shot("14_nomes_meio")
    r.tap("ui_accept", 3, 20)
    r.add(expect_call="EndingEpilogue.stage_name", equals="crew_footer", label="15_quarenta")
    r.shot("15_quarenta_pessoas")
    r.tap("ui_accept", 3, 30)
    r.shot("16_estatisticas")
    r.tap("ui_accept", 3, 20)
    r.add(expect_call="EndingEpilogue.stage_name", equals="question", label="17_pergunta")
    r.shot("17_pergunta")


def credits_and_menu(r):
    r.tap("ui_accept", 3, 90)
    r.expect_scene(CREDITS)
    r.wait(200); r.shot("18_creditos_inicio")
    r.wait(400); r.shot("19_creditos_meio")
    r.call("SaveManager.save_game")
    r.tap("ui_accept", 3, 90)
    r.expect_scene(MENU)
    r.wait(20); r.shot("20_menu_com_marca")
    r.add(expect_call="MainMenu/CompletedMark.is_visible_in_tree", equals=True,
          label="20_menu_marca_jogo_concluido")
    r.wait(10); r.quit()


def full(ending, research, tier, name):
    r = R()
    enter_room(r, research)
    choose(r, ending)
    cutscene(r, ending)
    epilogue(r, ending, tier)
    credits_and_menu(r)
    r.save(os.path.join(QA, name))


def high_versus_low():
    r = R()
    for label, research, tier in (("baixo", 0, "few"), ("alto", research_total(), "most")):
        start(r, research, {"ending": "seeding", "game_completed": True})
        r.scene(EPILOGUE)
        r.wait(40); r.expect_scene(EPILOGUE)
        r.add(expect_call="EndingEpilogue.tier", equals=tier, label="faixa_" + label)
        texts = paragraphs("seeding", tier)
        r.wait(typing_frames(texts[0]))
        r.tap("ui_accept", 3, 2)
        r.wait(typing_frames(texts[1]))
        r.add(expect_call="EndingEpilogue.paragraph_index", equals=1, label="p2_" + label)
        r.shot("p2_dados_" + label)
        r.wait(30)
    r.quit()
    r.save(os.path.join(QA, "f66_dados_alto_baixo.json"))


def skip_by_holding():
    r = R()
    start(r, 0, {"ending": "transmission", "game_completed": True})
    r.scene(CUTSCENE)
    r.at(30); r.expect_scene(CUTSCENE)
    r.at(40); r.tap("jump", 3, 20)
    r.add(expect_call="EndingCutscene.is_cut", equals=False, label="01_toque_nao_pula")
    r.shot("01_toque_curto")
    r.press("jump"); r.wait(30); r.shot("02_segurando_barra")
    r.wait(40); r.release("jump")
    r.add(expect_call="EndingCutscene.is_cut", equals=True, label="02_segurar_pula")
    r.wait(BLACK + FADE * 2 + 60); r.expect_scene(EPILOGUE)
    r.shot("03_epilogo_depois_do_pulo")
    r.wait(10); r.quit()
    r.save(os.path.join(QA, "f66_pular_cutscene.json"))


if __name__ == "__main__":
    full("seeding", 0, "few", "f66_semeadura.json")
    full("transmission", research_total(), "most", "f66_transmissao.json")
    high_versus_low()
    skip_by_holding()

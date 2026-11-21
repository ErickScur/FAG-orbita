BOSS = "Docks/Entities/Serralheiro"


def boss(r, method, value, label, args=None):
    event = {"expect_call": BOSS + "." + method, "equals": value, "label": label}
    if args:
        event["args"] = args
    r.add(**event)


def fight(r, landed, shots=True, stop=""):
    def shot(name):
        if shots:
            r.shot(name)

    L = landed
    r.at(L); boss(r, "is_entry_sealed", True, "escotilha_selada"); shot("02_entrada_selada")
    r.at(L + 30); r.press("move_left")
    r.at(L + 40); shot("03_braco_acordando"); boss(r, "phase_name", "WAKING", "braco_acordando")
    r.at(L + 90); r.release("move_left")
    r.at(L + 96); r.press("move_right")
    r.at(L + 122); r.release("move_right")
    r.at(L + 140); r.expect(87, 44, "acoplador_1"); boss(r, "phase_name", "ACTIVE", "braco_ativo")
    A = L + 140
    r.press("interact")
    r.at(A + 90); shot("04_carregando_1")
    r.at(A + 200); r.release("interact")
    r.at(A + 205); boss(r, "powered_count", 1, "um_acoplador"); shot("05_acoplador_1")
    r.press("move_right"); r.press("jump"); r.wait(16); r.release("jump"); r.wait(2)
    r.press("jump"); r.wait(16); r.release("jump"); r.wait(8); r.release("move_right")
    r.wait(30); r.expect(92, 40, "plataforma_de_entrada")
    r.press("move_right"); r.wait(12); r.release("move_right"); r.wait(6)
    r.press("jump"); r.wait(16); r.release("jump"); r.wait(2)
    r.press("jump"); r.wait(16); r.release("jump"); r.wait(30)
    r.expect(94, 37, "passarela"); shot("06_passarela_comporta")
    boss(r, "is_gate_closed", True, "comporta_soldada")
    r.press("move_right"); r.wait(50); r.release("move_right"); r.wait(10)
    r.expect(100, 37, "acoplador_2")
    r.press("interact")
    r.wait(132)
    boss(r, "is_coupler_sealed", True, "acoplador_2_trancado", ["dk_coupler_02"])
    shot("07_acoplador_2_trancado")
    r.release("interact")
    r.press("move_right"); r.wait(116); r.release("move_right"); r.wait(12)
    r.expect(112, 40, "acoplador_3")
    r.press("interact")
    r.wait(192)
    r.release("interact")
    boss(r, "powered_count", 2, "dois_acopladores"); shot("08_acoplador_3")
    D = r.f
    r.press("move_left"); r.wait(20); r.release("move_left")
    r.at(D + 40); r.expect(110, 40, "degrau_fora_do_estrado")
    r.at(D + 80); boss(r, "is_vented", True, "arena_em_vacuo"); shot("09_purga_vacuo")
    r.press("move_left"); r.press("jump"); r.wait(4); r.release("jump"); r.release("move_left")
    P = r.f
    if stop == "drift":
        r.track("h", 40, 4)
        return
    r.at(P + 130); r.press("move_down"); r.press("jump"); r.wait(4); r.release("jump")
    r.release("move_down")
    r.at(P + 185); r.press("move_right"); r.wait(5); r.release("move_right")
    r.at(P + 200); r.expect(100, 37, "acoplador_2_no_vacuo"); r.press("interact")
    if stop == "last":
        r.track("m", 70, 6)
        return
    r.at(D + 560); shot("10_ultimo_acoplador")
    r.at(D + 740); r.release("interact")
    boss(r, "phase_name", "DEFEATED", "serralheiro_desligado")
    boss(r, "is_node_unlocked", True, "no_liberado")
    boss(r, "is_vented", False, "vacuo_fechado")
    boss(r, "is_gate_closed", False, "comporta_aberta")
    shot("11_serralheiro_desligado")
    r.at(D + 810); shot("12_fala_do_serralheiro"); r.accept(6, 14)
    r.wait(30); shot("13_depois_da_fala")
    r.press("move_right"); r.wait(140); r.release("move_right"); r.wait(30)
    r.expect(115, 40, "no_do_setor"); shot("14_no_do_setor")

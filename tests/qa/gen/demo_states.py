import copy
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import review_campaign as rc

BASE_CHARGE = 100.0
BASE_INTEGRITY = 100
CAPACITOR_BONUS = 25.0
PLATE_BONUS = 25

ORDER = [
    "tutorial", "estufa", "hub_lab", "laboratorio", "hub_enfermaria", "enfermaria",
    "hub_docas", "docas", "hub_memoria", "memoria", "revisita_lab", "revisita", "reator",
    "final",
]

CHAPTER_ITEMS = {
    "tutorial": ["log_core_01", "data_core_01", "log_hab_01"],
    "estufa": ["data_gh_01", "data_gh_02", "data_gh_03", "log_gh_01", "log_gh_02",
               "capacitor_gh_01"],
    "hub_lab": [],
    "laboratorio": ["data_lab_01", "data_lab_02", "log_lab_01", "log_lab_02",
                    "capacitor_lab_01"],
    "hub_enfermaria": [],
    "enfermaria": ["data_inf_01", "data_inf_02", "log_inf_01", "log_inf_02", "capacitor_inf_01"],
    "hub_docas": [],
    "docas": ["data_dk_01", "data_dk_02", "log_dk_01", "log_dk_02", "capacitor_dk_01"],
    "hub_memoria": [],
    "memoria": ["data_mem_01", "log_mem_01", "log_mem_final"],
    "revisita_lab": ["plate_lab_01"],
    "revisita": ["plate_core_01", "plate_gh_01", "plate_dk_01"],
    "reator": ["data_rc_01", "log_rc_01"],
    "final": [],
}

CHAPTER_SECRETS = {
    "estufa": ["gh_secret_01", "gh_secret_02"],
    "laboratorio": ["lab_secret_01"],
    "enfermaria": ["inf_secret_01"],
    "docas": ["dk_secret_01"],
}

CHAPTER_FLAGS = {
    "revisita": [],
}

KIND_FLAGS = {"data": "research", "log": "log", "capacitor": "capacitor",
              "plate": "armor_plate"}


def items_before(chapter):
    done = []
    for key in ORDER[:ORDER.index(chapter)]:
        done.extend(CHAPTER_ITEMS.get(key, []))
    return done


def items_from(chapter):
    later = []
    for key in ORDER[ORDER.index(chapter):]:
        later.extend(CHAPTER_ITEMS.get(key, []))
        later.extend(CHAPTER_SECRETS.get(key, []))
    return later


def full_state(base_name, chapter):
    state = copy.deepcopy(rc.load_state(base_name))
    pending = set(items_from(chapter))
    for field in ("collected_ids", "logs_collected", "research_collected"):
        state[field] = [item for item in state.get(field, []) if item not in pending]
    flags = state.setdefault("flags", {})
    for secret in pending:
        flags.pop("secret_" + secret, None)
    for key in ORDER[:ORDER.index(chapter)]:
        for item in CHAPTER_ITEMS.get(key, []):
            _add(state, item)
        for secret in CHAPTER_SECRETS.get(key, []):
            flags["secret_" + secret] = True
        for flag in CHAPTER_FLAGS.get(key, []):
            flags[flag] = True
    collected = state["collected_ids"]
    capacitors = len([i for i in collected if i.startswith("capacitor_")])
    plates = len([i for i in collected if i.startswith("plate_")])
    state["charge_max"] = BASE_CHARGE + CAPACITOR_BONUS * capacitors
    state["charge"] = state["charge_max"]
    state["integrity_max"] = BASE_INTEGRITY + PLATE_BONUS * plates
    state["integrity"] = state["integrity_max"]
    state["deaths"] = 0
    return state


def _add(state, item):
    if item not in state["collected_ids"]:
        state["collected_ids"].append(item)
    prefix = item.split("_")[0]
    if prefix == "log" and item not in state["logs_collected"]:
        state["logs_collected"].append(item)
    if prefix == "data" and item not in state["research_collected"]:
        state["research_collected"].append(item)
    if prefix in KIND_FLAGS:
        state["flags"]["seen_kind_" + KIND_FLAGS[prefix]] = True

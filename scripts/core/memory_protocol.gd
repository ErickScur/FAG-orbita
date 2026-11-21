class_name MemoryProtocol
extends RefCounted

enum Phase { DORMANT, ASCENT, FIREWALL, RECALL, DONE }

const FLAG_KEY: String = "mem_protocol"
const SECTOR_ID: StringName = &"memory"
const ROOT_ABILITY: StringName = &"root_access"
const EARTH_FLAG: String = "earth_signal"
const PHASE_ORDER: Array[Phase] = [Phase.ASCENT, Phase.FIREWALL, Phase.RECALL]
const PHASE_KEYS: Dictionary = {
	Phase.ASCENT: "ascent",
	Phase.FIREWALL: "firewall",
	Phase.RECALL: "recall",
}

var phase: Phase = Phase.DORMANT
var completed: int = 0


static func create(saved_completed: int, restored: bool) -> MemoryProtocol:
	var protocol := MemoryProtocol.new()
	protocol.completed = clampi(saved_completed, 0, PHASE_ORDER.size())
	if restored:
		protocol.finish()
	return protocol


static func saved_progress(flags: Dictionary) -> int:
	return clampi(int(flags.get(FLAG_KEY, 0)), 0, PHASE_ORDER.size())


static func key_of(which: Phase) -> String:
	return String(PHASE_KEYS.get(which, ""))


func is_active() -> bool:
	return phase == Phase.ASCENT or phase == Phase.FIREWALL or phase == Phase.RECALL


func is_done() -> bool:
	return phase == Phase.DONE


func awaits_node() -> bool:
	return phase == Phase.DORMANT and completed >= PHASE_ORDER.size()


func next_phase() -> Phase:
	if phase == Phase.DONE or completed >= PHASE_ORDER.size():
		return Phase.DONE
	return PHASE_ORDER[completed]


func try_start(inside_trigger: bool) -> bool:
	if phase != Phase.DORMANT or not inside_trigger:
		return false
	var upcoming: Phase = next_phase()
	if upcoming == Phase.DONE:
		return false
	phase = upcoming
	return true


func complete_current() -> int:
	if not is_active():
		return completed
	completed = mini(completed + 1, PHASE_ORDER.size())
	phase = Phase.DORMANT
	return completed


func abort_current() -> Phase:
	var aborted: Phase = phase
	if is_active():
		phase = Phase.DORMANT
	return aborted


func finish() -> void:
	completed = PHASE_ORDER.size()
	phase = Phase.DONE


func phases_already_erased() -> Array[Phase]:
	var result: Array[Phase] = []
	if phase == Phase.DONE:
		return result
	for index: int in range(mini(completed, PHASE_ORDER.size())):
		result.append(PHASE_ORDER[index])
	return result


func stage() -> Phase:
	if phase == Phase.DONE:
		return Phase.DONE
	if is_active():
		return phase
	if completed <= 0:
		return Phase.DORMANT
	return PHASE_ORDER[mini(completed, PHASE_ORDER.size()) - 1]


func desaturation() -> float:
	match stage():
		Phase.ASCENT:
			return Balance.MEMORY_DESAT_ASCENT
		Phase.FIREWALL:
			return Balance.MEMORY_DESAT_FIREWALL
		Phase.RECALL:
			return Balance.MEMORY_DESAT_RECALL
	return 0.0


func ambient_key() -> String:
	match stage():
		Phase.ASCENT:
			return "ascent"
		Phase.FIREWALL:
			return "firewall"
		Phase.RECALL:
			return "recall"
		Phase.DONE:
			return "restored"
	return "dormant"

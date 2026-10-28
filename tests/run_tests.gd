extends Node
## Headless checks for the slice. Run from the project folder with:
##   godot --headless res://tests/run_tests.tscn
## Exits with code 0 when everything passes.

var _failures := 0


func _ready() -> void:
	GameState.test_mode = true
	_test_dice()
	_test_sheets()
	_test_save_roundtrip()
	await _test_office_flow()
	print("\n%s" % ("ALL TESTS PASSED" if _failures == 0 else "%d FAILURE(S)" % _failures))
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	print("%s  %s" % ["ok  " if condition else "FAIL", label])
	if not condition:
		_failures += 1


func _test_dice() -> void:
	Dice.rng.seed = 1939
	var trials := 10000
	var die_hits := 0
	var passes := 0
	for i in trials:
		var r := Dice.roll(8, 3, 2)
		die_hits += r.successes
		if r.passed:
			passes += 1
	var per_die := float(die_hits) / (trials * 3)
	_check(absf(per_die - 0.8) < 0.015, "skill 8 gives about 80%% per die (got %.3f)" % per_die)
	var expected := Dice.odds(8, 3, 2)
	_check(absf(expected - 0.896) < 0.001, "odds formula: skill 8, 3 dice, need 2 = 89.6%")
	_check(absf(float(passes) / trials - expected) < 0.015, "rolled pass rate matches the odds shown")
	_check(Dice.odds(0, 3, 1) == 0.0 and Dice.odds(10, 3, 3) == 1.0, "odds at skill 0 and 10")


func _test_sheets() -> void:
	var adrian: CharacterSheet = load("res://data/characters/adrian.tres")
	var tom: CharacterSheet = load("res://data/characters/tom.tres")
	_check(adrian.get_skill("eloquence") == 8 and adrian.get_skill("occultism") == 1, "Adrian's sheet matches the agreed draft")
	_check(tom.get_skill("firearms") == 9 and tom.get_skill("eloquence") == 2, "Tom's sheet matches the agreed draft")
	_check(adrian.skills.size() == 9, "Adrian has all 9 skills")


func _test_save_roundtrip() -> void:
	GameState.reset()
	GameState.examined.append("pistol")
	GameState.set_flag("has_pistol")
	GameState.fee_per_day = 30
	SaveSystem.autosave("knock")
	GameState.reset()
	_check(SaveSystem.load_save(), "autosave loads")
	_check(GameState.checkpoint == "knock" and GameState.has_examined("pistol")
		and GameState.has_flag("has_pistol") and GameState.fee_per_day == 30, "autosave restores the run")
	SaveSystem.delete_save()


## Plays the whole office: three objects, the knock, Tom, the fee check.
func _test_office_flow() -> void:
	GameState.reset()
	var office: Node2D = load("res://scenes/office/office.tscn").instantiate()
	_check(office.has_method("examine"), "office scene script loads")
	if not office.has_method("examine"):
		return
	add_child(office)
	await get_tree().process_frame
	for id in ["bills", "gin", "pistol"]:
		await office.examine(id)
	_check(GameState.examined.size() == 3, "three objects examined")
	_check(not GameState.has_flag("has_pistol"), "leaving the pistol leaves no flag")
	_check(GameState.checkpoint == "office_done", "the scene reaches the end card")
	_check(GameState.fee_per_day in [20, 30], "a fee was agreed ($%d)" % GameState.fee_per_day)
	_check(SaveSystem.has_save(), "autosaved at the end")
	office.queue_free()
	SaveSystem.delete_save()

extends Node
## Dice pools: roll `dice` d10s, each succeeds if it rolls at or under the
## skill value (so 10% per skill point). The check passes on `needed` successes.


class CheckResult:
	extends RefCounted
	var skill := 0
	var dice := 0
	var needed := 0
	var rolls: Array[int] = []
	var successes := 0
	var passed := false


var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func chance_per_die(skill: int) -> float:
	return clampf(skill * 0.1, 0.0, 1.0)


## Exact chance of at least `needed` successes, for showing odds before a check.
func odds(skill: int, dice: int, needed: int) -> float:
	var p := chance_per_die(skill)
	var total := 0.0
	for k in range(needed, dice + 1):
		total += _choose(dice, k) * pow(p, k) * pow(1.0 - p, dice - k)
	return clampf(total, 0.0, 1.0)


func roll(skill: int, dice: int, needed: int) -> CheckResult:
	var result := CheckResult.new()
	result.skill = skill
	result.dice = dice
	result.needed = needed
	for i in dice:
		var face := rng.randi_range(1, 10)
		result.rolls.append(face)
		if face <= skill:
			result.successes += 1
	result.passed = result.successes >= needed
	return result


func _choose(n: int, k: int) -> float:
	var r := 1.0
	for i in k:
		r *= float(n - i) / float(i + 1)
	return r

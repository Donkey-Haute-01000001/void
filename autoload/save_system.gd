extends Node
## A single autosave slot, written as JSON.

const PATH := "user://autosave.json"


func autosave(checkpoint: String) -> void:
	GameState.checkpoint = checkpoint
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_error("Autosave failed: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func load_save() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return false
	GameState.from_dict(data)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

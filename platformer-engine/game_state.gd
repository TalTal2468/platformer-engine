
extends Node
## Autoload (name it GameState). Remembers progress between scenes.

signal wood_changed(new_amount: int)

var solved := {}
var insight := 1

var wood_count: int = 0


func add_wood(amount: int) -> void:
	if amount <= 0:
		return

	wood_count += amount
	wood_changed.emit(wood_count)


func spend_wood(amount: int) -> bool:
	if amount <= 0 or amount > wood_count:
		return false

	wood_count -= amount
	wood_changed.emit(wood_count)
	return true

extends Node

const COLS := 18

var row: Array[int] = []
var rule_binary: Array[int] = []

func _ready():
	rule_binary = get_rule_binary(30)

	# Инициализируем строку нулями
	row.resize(COLS)
	for i in range(COLS):
		row[i] = 0

	# Устанавливаем одну живую клетку в центр
	row[int(COLS / 2.0)] = 1



func get_next_row() -> Array:
	var new_row: Array[int] = []
	for i in range(COLS):
		var l := row[(i - 1 + COLS) % COLS]
		var c := row[i]
		var r := row[(i + 1) % COLS]
		var idx := int(l) * 4 + int(c) * 2 + int(r)
		new_row.append(rule_binary[idx])
	row = new_row
	print("▶ Новое поколение Rule30:", row)
	return row.duplicate()



func get_rule_binary(rule_number: int) -> Array[int]:
	var binary_string := ""
	var num := rule_number

	while num > 0:
		binary_string = str(num % 2) + binary_string
		num /= 2

	while binary_string.length() < 8:
		binary_string = "0" + binary_string

	var digits: Array[int] = []
	for i in range(7, -1, -1):
		digits.append(int(binary_string[i]))

	return digits

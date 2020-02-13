extends Control

signal delete_property
signal update_property

var m_id = -1
var m_type = g_types.e_column_type_int
var m_name = ""

func _ready():
	$align/prop_name.connect("text_changed", self, "on_name_changed")

	$align/prop_type.add_item("Integer")
	$align/prop_type.add_item("String")
	$align/prop_type.connect("item_selected", self, "on_type_changed")

	$align/close_button.connect("pressed", self, "on_delete_button_pressed")

func setup(id, type, name):
	set_id(id)
	set_type(type)
	set_name(name)

func set_id(id):
	m_id = id
	$align/prop_id.set_text(str(m_id))

func get_id():
	return m_id

func set_type(type):
	m_type = type
	if(m_type == g_types.e_column_type_int):
		$align/prop_type.select(0)
	elif(m_type == g_types.e_column_type_string):
		$align/prop_type.select(1)

func get_type():
	return m_type

func set_name(name):
	m_name = name
	$align/prop_name.set_text(m_name)

func get_name():
	return m_name

func on_name_changed(new_text):
	m_name = new_text
	emit_signal("update_property", m_id, m_type, m_name)

func on_type_changed(new_type):
	m_type = new_type
	emit_signal("update_property", m_id, m_type, m_name)

func on_delete_button_pressed():
	emit_signal("delete_property", m_id)

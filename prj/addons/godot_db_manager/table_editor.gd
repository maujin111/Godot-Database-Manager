"""
class GDDBTableEditor
"""

class_name GDDBTableEditor

tool
extends Control

signal set_dirty

var m_parent_table = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$tabs/structure/new_property_btn.connect("pressed", self, "on_new_property_btn_pressed")
	$tabs/data/data_holder/btns/add_data_btn.connect("pressed", self, "on_add_row_data_btn_pressed")
	$tabs/data/data_holder/btns/add_data_btn.set_disabled(true)

	$load_res_path_dlg.connect("file_selected", self, "on_select_res_path")

	$data_dlg.connect("select_data", self, "on_select_data")

# called when the new_property button is pressed
func on_new_property_btn_pressed() -> void:
	# print("GDDBTableEditor::on_new_property_btn_pressed()")
	if(null == m_parent_table):
		print("ERROR: GDDBTableEditor::on_new_property_btn_pressed() - m_parent_table is null")
		return
	var prop_idx = m_parent_table.get_props_count()
	var prop_type = db_types.e_prop_type_bool
	var prop_name = "Property_" + str(prop_idx+1)
	var prop_id = m_parent_table.add_prop(prop_type, prop_name)
	add_prop_to_structure(prop_id, prop_type, prop_name)
	add_prop_to_data(prop_id, prop_type, prop_name)

	# enable add data btn
	$tabs/data/data_holder/btns/add_data_btn.set_disabled(false)

	emit_signal("set_dirty")

# adds a property to structure tab
func add_prop_to_structure(prop_id : int, prop_type : int, prop_name : String) -> void:
	# print("GDDBTableEditor::add_prop_to_structure(" + str(prop_id) + ", " + str(prop_type) + ", " + prop_name + ")")
	var prop = load(g_constants.c_addon_main_path + "table_property.tscn").instance()
	$tabs/structure/properties.add_child(prop)
	prop.set_parent_table(m_parent_table)
	prop.setup(prop_id, prop_type, prop_name)
	prop.connect("edit_property", self, "on_edit_property")
	prop.connect("delete_property", self, "on_delete_property")

# adds a property to data tab
func add_prop_to_data(prop_id : int, prop_type : int, prop_name : String) -> void:
	var prop = load(g_constants.c_addon_main_path + "data_label.tscn").instance()
	$tabs/data/data_holder/data_header.add_child(prop)
	prop.set_prop_id(prop_id)
	prop.set_text(prop_name)

	# add property to the existing rows
	for idx in range(0, $tabs/data/data_holder/data_container.get_child_count()):
		var row = $tabs/data/data_holder/data_container.get_child(idx)
		var cell = load(g_constants.c_addon_main_path + "table_cell.tscn").instance()
		row.add_child(cell)
		cell.set_prop_id(prop_id)
		cell.set_row_idx(idx)
		cell.set_prop_type(prop_type)
		cell.set_text("")
		cell.connect("edit_data", self, "on_edit_data")
		cell.connect("choose_resource", self, "on_choose_resource")
		cell.connect("choose_data", self, "on_choose_data")

# called when the add data button is pressed
func on_add_row_data_btn_pressed() -> void:
	# print("GDDBTableEditor::on_add_row_data_btn_pressed")
	# add blank row in the table
	var row_idx = m_parent_table.get_rows_count()
	m_parent_table.add_blank_row()

	# add row in the interface
	var row = HBoxContainer.new()
	$tabs/data/data_holder/data_container.add_child(row)
	for idx in range(0, $tabs/structure/properties.get_child_count()):
		var cell = load(g_constants.c_addon_main_path + "table_cell.tscn").instance()
		row.add_child(cell)
		cell.set_prop_id(idx)
		cell.set_row_idx(row_idx)
		cell.set_prop_type(db_types.e_prop_type_int)
		cell.set_text("")
		cell.connect("edit_data", self, "on_edit_data")
		cell.connect("choose_resource", self, "on_choose_resource")
		cell.connect("choose_data", self, "on_choose_data")

	emit_signal("set_dirty")

# sets the table from database
func set_table(table : Object) -> void:
	# print("GDDBTableEditor::set_table(" + table.get_table_name() + ")")
	clear_current_layout()

	m_parent_table = table
	fill_properties()
	fill_data()

# fills the interface with current table's properties
func fill_properties() -> void:
	# print("GDDBTableEditor::fill_properties()")
	var props_count = m_parent_table.get_props_count()
	for idx in range(0, props_count):
		var db_prop = m_parent_table.get_prop_at(idx)
		add_prop_to_structure(db_prop.get_prop_id(), db_prop.get_prop_type(), db_prop.get_prop_name())
		var prop = load(g_constants.c_addon_main_path + "data_label.tscn").instance()
		$tabs/data/data_holder/data_header.add_child(prop)
		prop.set_prop_id(db_prop.get_prop_id())
		prop.set_prop_type(db_prop.get_prop_type())
		prop.set_text(db_prop.get_prop_name())
	if(props_count > 0):
		$tabs/data/data_holder/btns/add_data_btn.set_disabled(false)

# fills the interface with current table's data
func fill_data() -> void:
	# print("GDDBTableEditor::fill_data()")
	var rows_count = m_parent_table.get_rows_count()
	for idx in range(0, rows_count):
		var row = HBoxContainer.new()
		$tabs/data/data_holder/data_container.add_child(row)
		var data_row = m_parent_table.get_data_at_row_idx(idx)
		for jdx in range(0, data_row.size()):
			var db_prop = m_parent_table.get_prop_at(jdx)

			var cell = load(g_constants.c_addon_main_path + "table_cell.tscn").instance()

			var prop_type = db_prop.get_prop_type()
			# print("Prop: type - " + str(prop_type) + " - " + db_types.get_data_name(prop_type) + " - id: " + str(data_row[jdx].get_prop_id()) + " - data: " + data_row[jdx].get_data())

			var cell_data = data_row[jdx].get_data()

			if(prop_type > db_types.e_data_types_count):
				var db = m_parent_table.get_parent_database()
				var tbl = db.get_table_by_id(prop_type - db_types.e_data_types_count)
				var data_row_idx = cell_data.to_int()
				var row_data = tbl.get_data_at_row_idx(data_row_idx)

				# TODO: this code is duplicated; the same code is in "data_dlg.gd::on_about_to_show". Put it in a global function

				cell_data = "{"
				for kdx in range(0, row_data.size()):
					var prop_name = tbl.get_prop_at(kdx).get_prop_name()
					cell_data += "\"" + prop_name + "\":"
					cell_data += "\"" + row_data[kdx].get_data() + "\""
					if(kdx < row_data.size() - 1):
						cell_data += ", "
				cell_data += "}"

			row.add_child(cell)
			cell.set_prop_id(data_row[jdx].get_prop_id())
			cell.set_row_idx(idx)
			cell.set_prop_type(prop_type)
			cell.set_text(cell_data)
			cell.connect("edit_data", self, "on_edit_data")
			cell.connect("choose_resource", self, "on_choose_resource")
			cell.connect("choose_data", self, "on_choose_data")

# links properties
func link_props() -> void :
	# print("GDDBTableEditor::link_props() for table with name: " + m_parent_table.get_table_name())
	for idx in range(0, $tabs/structure/properties.get_child_count()):
		var prop = $tabs/structure/properties.get_child(idx)
		prop.link()

# cleares current layout
func clear_current_layout() -> void:
	# clear structure tab
	for idx in range(0, $tabs/structure/properties.get_child_count()):
		$tabs/structure/properties.get_child(idx).queue_free()

	# clear data from data tab
	for idx in range(0, $tabs/data/data_holder/data_container.get_child_count()):
		var row = $tabs/data/data_holder/data_container.get_child(idx)
		for jdx in range(0, row.get_child_count()):
			row.get_child(jdx).queue_free()
		row.queue_free()

	# clear properties from data tab
	for idx in range(0, $tabs/data/data_holder/data_header.get_child_count()):
		$tabs/data/data_holder/data_header.get_child(idx).queue_free()

	$tabs/data/data_holder/btns/add_data_btn.set_disabled(true)

# called when a property is edited
func on_edit_property(prop_id : int, prop_type : int, prop_name : String) -> void:
	"""
	print("GDDBTableEditor::on_edit_property(" + str(prop_id) + ", " + str(prop_type) + ", " + prop_name + ")")
	if(prop_type >= db_types.e_data_types_count):
		var db = m_parent_table.get_parent_database()
		var selected_table = db.get_table_by_id(db_types.e_data_types_count - prop_type)
		print("GDDBTableEditor::on_edit_property(" + str(prop_id) + ", " + selected_table.get_table_name() + ", " + prop_name + ")")
	else:
		print("GDDBTableEditor::on_edit_property(" + str(prop_id) + ", " + db_types.get_data_name(prop_type) + ", " + prop_name + ")")
	#"""
	# edit prop in the table
	m_parent_table.edit_prop(prop_id, prop_type, prop_name)

	# refresh the prop name in data tab
	for idx in range(0, $tabs/data/data_holder/data_header.get_child_count()):
		var prop = $tabs/data/data_holder/data_header.get_child(idx)
		if(prop.get_prop_id() == prop_id):
			prop.set_text(prop_name)

	# update data type
	for idx in range(0, $tabs/data/data_holder/data_container.get_child_count()):
		var row = $tabs/data/data_holder/data_container.get_child(idx)
		for jdx in range(0, row.get_child_count()):
			var cell = row.get_child(jdx)
			if(cell.get_prop_id() == prop_id):
				"""
				if(prop_type < db_types.e_data_types_count):
					print("Prop type: " + db_types.get_data_name(prop_type))
				else:
					print("Prop type: custom")
				"""
				cell.set_prop_type(prop_type)

	emit_signal("set_dirty")

# called when a property is deleted
func on_delete_property(prop_id : int) -> void:
	# print("GDDBTableEditor::on_delete_property(" + str(prop_id) + ")")
	# deletes property from table; also all data by this property
	m_parent_table.delete_prop(prop_id)

	# delete cells from data tab
	for idx in range(0, $tabs/data/data_holder/data_container.get_child_count()):
		var row = $tabs/data/data_holder/data_container.get_child(idx)
		for jdx in range(0, row.get_child_count()):
			var cell = row.get_child(jdx)
			if(cell.get_prop_id() == prop_id):
				cell.disconnect("edit_data", self, "on_edit_data")
				cell.queue_free()
				break

	# delete property from data tab
	for idx in range(0, $tabs/data/data_holder/data_header.get_child_count()):
		var prop = $tabs/data/data_holder/data_header.get_child(idx)
		if(prop.get_prop_id() == prop_id):
			prop.queue_free()
			break

	# delete prop from structure
	for idx in range(0, $tabs/structure/properties.get_child_count()):
		var prop = $tabs/structure/properties.get_child(idx)
		if(prop.get_prop_id() == prop_id):
			prop.queue_free()
			break

	# refresh the add data button
	var props_count = m_parent_table.get_props_count()
	if(props_count == 0):
		$tabs/data/data_holder/btns/add_data_btn.set_disabled(true)

	emit_signal("set_dirty")

# called when edit data
func on_edit_data(prop_id : int, row_idx : int, data : String) -> void:
	m_parent_table.edit_data(prop_id, row_idx, data)
	emit_signal("set_dirty")

# called when choosing a resource
func on_choose_resource(prop_id : int, row_idx : int) -> void:
	# print("GDDBTableEditor::on_choose_resource(" + str(prop_id) + ", " + str(row_idx) + ")")
	$load_res_path_dlg.set_prop_id(prop_id)
	$load_res_path_dlg.set_row_idx(row_idx)
	$load_res_path_dlg.popup_centered()

# called when choosing a data
func on_choose_data(prop_id : int, row_idx : int, prop_type : int) -> void:
	# print("GDDBTableEditor::on_choose_data(" + str(prop_id) + ", " + str(row_idx) + ", " + str(prop_type) + ")")
	$data_dlg.set_prop_id(prop_id)
	$data_dlg.set_row_idx(row_idx)
	var table_id = prop_type - db_types.e_data_types_count
	var db = m_parent_table.get_parent_database()
	var tbl = db.get_table_by_id(table_id)
	$data_dlg.set_table(tbl)
	$data_dlg.popup_centered()

# called when selecting a resource filepath
func on_select_res_path(filepath : String) -> void:
	# print("GDDBTableEditor::on_select_res_path(" + filepath + ")")
	var prop_id = $load_res_path_dlg.get_prop_id()
	var row_idx = $load_res_path_dlg.get_row_idx()
	var row = $tabs/data/data_holder/data_container.get_child(row_idx)
	for idx in range(0, row.get_child_count()):
		var cell = row.get_child(idx)
		if(cell.get_prop_id() == prop_id):
			cell.set_text(filepath)

# called when data from a table is choosen
func on_select_data(prop_id : int, row_idx : int, data_row_idx : int, data : String) -> void:
	# set the data in the databes / table
	m_parent_table.edit_data(prop_id, row_idx, str(data_row_idx))

	# fill in the interface cell with data
	var row = $tabs/data/data_holder/data_container.get_child(row_idx)
	for idx in range(0, row.get_child_count()):
		var cell = row.get_child(idx)
		if(cell.get_prop_id() == prop_id):
			cell.set_text(data)
			break

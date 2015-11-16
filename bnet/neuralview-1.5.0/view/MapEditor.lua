--[[
    This file is part of NeuralView.

    NeuralView is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NeuralView is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NeuralView.  If not, see <http://www.gnu.org/licenses/>.
--]]

---
-- Dialog that allows the creation / manipulation of maps.
local MapEditor, MapEditorMT = nv_module('view.MapEditor')

local Map = require('core.Map')

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of MapEditor 
function MapEditor.new(parent)
    local self = {}
    setmetatable(self, MapEditorMT)
    
    self:build_gui(parent)
    self.iter = gtk.TreeIter.new()
    
    return self
end

local CELL_LIMIT, CELL_VALUE = 0, 1

---
-- Builds the interface.
--
-- @private
function MapEditor:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('title', _"Map editor", 'transient-for', parent,
        'default-width', 400, 'default-height', 300, 'icon', NVIcon)
    self.dialog:add_buttons('gtk-cancel', gtk.RESPONSE_CANCEL, 
        'gtk-ok', gtk.RESPONSE_OK)
    self.vbox = self.dialog:get_content_area()
    
    -- treeview
    self.model = gtk.ListStore.new('gdouble', 'gchararray')
    self.view = gtk.TreeView.new_with_model(self.model)
    local cell = gtk.CellRendererText.new()
    cell:set('editable', true)
    cell:connect('edited', self.cell_edited, {self, CELL_LIMIT})
    self.limitcol = gtk.TreeViewColumn.new_with_attributes(_"Upper limit", 
        cell, 'text', 0)
    
    local cell = gtk.CellRendererText.new()
    cell:set('editable', true)
    cell:connect('edited', self.cell_edited, {self, CELL_VALUE})
    self.valuecol = gtk.TreeViewColumn.new_with_attributes(_"Value", 
        cell, 'text', 1)
    
    self.view:append_column(self.limitcol)
    self.view:append_column(self.valuecol)
    self.selection = self.view:get_selection()
    self.selection:set_mode(gtk.SELECTION_MULTIPLE)
    
    self.scroll = gtk.ScrolledWindow.new()
    self.scroll:set('vscrollbar-policy', gtk.POLICY_AUTOMATIC,
        'hscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.scroll:add(self.view)
    
    -- add / remove / clear map buttons
    self.button_box = gtk.ButtonBox.new(gtk.ORIENTATION_VERTICAL)
    self.button_box:set('layout-style', gtk.BUTTONBOX_START)
    
    self.add = gtk.Button.new_with_mnemonic(_"_Add")
    self.add:connect('clicked', self.add_row, self)
    self.add:set('tooltip-text', _"Add a new interval point")
    
    self.remove = gtk.Button.new_with_mnemonic(_"_Remove")
    self.remove:connect('clicked', self.remove_row, self)
    self.remove:set('tooltip-text', _"Remove the selected interval points")
    
    self.button_box:add(self.add, self.remove)
    
    self.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    self.hbox:pack_start(self.scroll, true, true, 0)
    self.hbox:pack_start(self.button_box, false, true, 0)
    
    self.vbox:pack_start(self.hbox, true, true, 0)
    self.vbox:show_all()
end

---
-- Prepares the interface for a new map.
--
-- @private
function MapEditor:prepare(map)
    local model, iter = self.model, self.iter
    
    self.view:set('model', nil)
    model:clear()
    
    if map then
        map:foreach(
            function(value, label)
                model:append(self.iter)
                model:seto(self.iter, value, label)
            end)
    end
    
    self.view:set('model', model)
end

---
-- Transforms the user input into a map.
function MapEditor:get_map()
    local model, iter = self.model, self.iter
    local valid = model:get_iter_first(iter)
    local map = Map.new()
    
    while valid do
        local value, label = model:get(iter, 0, 1)
        map:add(value, label)
        valid = model:iter_next(iter)
    end
    
    map:sort()
    
    return map
end

---
-- Handles a cell edition.
--
-- @private
function MapEditor:cell_edited(path, data)
    local self, cell = unpack(self)
    local value
    
    if cell == CELL_LIMIT then
        value = tonumber(data) 
    elseif cell == CELL_VALUE then
        value = data
    end
    
    if value then
        self.model:get_iter_from_string(self.iter, path)
        self.model:set(self.iter, cell, value)
    end
end

---
-- Adds a row to the editor.
--
-- @private
function MapEditor:add_row()
    self.model:append(self.iter)
    self.model:seto(self.iter, 0, _"New value")
end

---
-- Removes the selected row from the editor.
--
-- @private
function MapEditor:remove_row()
    local rows = self.selection:get_selected_rows(self.iter)
    
    for i = #rows, 1, -1 do
        self.model:get_iter_from_string(self.iter, rows[i])
        self.model:remove(self.iter)
    end
end

---
-- Runs the map editor.
--
-- @param map Map to edit
-- @return New map, or nil to clear the map
function MapEditor:run(map)
    self:prepare(map)
    
    local res = self.dialog:run()
    local ret
    self.dialog:hide()
    
    if res == gtk.RESPONSE_OK then
        ret = self:get_map()
    else
        ret = map
    end
    
    self:prepare()
    return ret 
end

return MapEditor 

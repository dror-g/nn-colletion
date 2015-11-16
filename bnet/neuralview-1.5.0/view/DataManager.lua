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
-- Dialog that handles a list of training datas.
local DataManager, DataManagerMT = nv_module('view.DataManager')

local Utils = require('view.Utils')

---
-- Constructor.
--
-- @param parent Parent window
function DataManager.new(parent)
    local self = {}
    setmetatable(self, DataManagerMT)
    
    self:build_gui(parent)
    self.iter = gtk.TreeIter.new()
    self:clear()
    
    return self
end

---
-- Builds the interface.
--
-- @private
function DataManager:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('transient-for', parent, 'title', _"Data manager",
        'icon', NVIcon)
    self.dialog:add_button('gtk-close', gtk.RESPONSE_OK)
    
    self.vbox = self.dialog:get_content_area()
    self.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 5)
    self.button_box = gtk.ButtonBox.new(gtk.ORIENTATION_VERTICAL)
    self.button_box:set('layout-style', gtk.BUTTONBOX_START)
    
    self.add = gtk.Button.new_with_mnemonic(_"_Add")
    self.add:connect('clicked', self.add_data, self)
    self.add:set('tooltip-text', _"Add a new data")
    
    self.import = Utils.new_button('gtk-open', _"_Import")
    self.import:connect('clicked', self.import_data, self)
    self.import:set('tooltip-text', _"Import a data from a file")
    
    self.edit = gtk.Button.new_with_mnemonic(_"_Edit")
    self.edit:connect('clicked', self.edit_data, self)
    self.edit:set('tooltip-text', _"Edit the selected data")
    
    self.copy = gtk.Button.new_with_mnemonic(_"_Copy")
    self.copy:connect('clicked', self.copy_data, self)
    self.copy:set('tooltip-text', _"Create a copy of the selected data")
    
    self.run_copy = gtk.Button.new_with_mnemonic(_"_Run")
    self.run_copy:connect('clicked', self.run_copy_data, self)
    self.run_copy:set('tooltip-text', _"Run a copy of the selected data")
    
    self.scale = Utils.new_button('gtk-convert', _"_Scale")
    self.scale:connect('clicked', self.scale_data, self)
    self.scale:set('tooltip-text', _"Scale the selected data between an interval")
    
    self.shuffle = Utils.new_button('gtk-jump-to', _"Shu_ffle")
    self.shuffle:connect('clicked', self.shuffle_data, self)
    self.shuffle:set('tooltip-text', _"Shuffle the rows of selected data")
    
    self.remove = gtk.Button.new_with_mnemonic(_"_Remove")
    self.remove:connect('clicked', self.remove_data, self)
    self.remove:set('tooltip-text', _"Remove the selected data")
    
    self.button_box:add(self.add, self.import, self.edit, self.copy,
        self.run_copy, self.scale, self.shuffle, self.remove)
    
    self.model = gtk.ListStore.new('gchararray', 'gint')
    self.view = gtk.TreeView.new_with_model(self.model)
    self.view:set('enable-search', false, 'enable-tree-lines', true, 
        'reorderable', true)
    self.selection = self.view:get_selection()
    self.selection:connect('changed', self.selection_changed, self)
    
    self.cell_renderer = gtk.CellRendererText.new()
    self.cell_renderer:set('editable', true)
    self.cell_renderer:connect('edited', self.cell_edited, self)
    self.column = gtk.TreeViewColumn.new_with_attributes(_"Data name",
        self.cell_renderer, 'text', 0)
    self.view:append_column(self.column)
    
    self.scroll = gtk.ScrolledWindow.new()
    self.scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC,
        'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.scroll:add(self.view)
    
    self.hbox:pack_start(self.scroll, true, true, 0)
    self.hbox:pack_start(self.button_box, false, true, 0)
    
    self.vbox:add(self.hbox)
    self.vbox:show_all()
    
    self.dialog:set('default-width', 400, 'default-height', 300)
end

-- Never used, but need to be defined
local function creation_callback() end

---
-- Creates a new, empty data
--
-- @private
function DataManager:create_empty_data()
    local data = {}
    data.desc = _"New data"
    data.obj = fann.Data.create_from_callback(0, self.num_input,
        self.num_output, creation_callback)
        
    return data
end

---
-- Imports a data from a file.
--
-- @private
function DataManager:import_data()
    if not self.data_open_dialog then
        local DataOpenDialog = require('view.DataOpenDialog') 
        self.data_open_dialog = DataOpenDialog.new(self.dialog)
    end
    
    local data, msg = self.data_open_dialog:run(self.num_input, self.num_output)
    
    if data then
        self:add_helper({desc = _"Imported data", obj = data})
        self.data_changed = true
    elseif msg then
        Utils.show_info(msg)
    end
end

---
-- To ease the manipulation of the data (and make it more efficient), the
-- data reference is copied to an aux array, manipulated there, and in the
-- end it is copied to the project.
--
-- @private
function DataManager:add_helper(data)
    self.temp_data[self.temp_index] = data.obj
    self.model:append(self.iter)
    self.model:seto(self.iter, data.desc, self.temp_index)
    self.temp_index = self.temp_index + 1
end

---
-- Saves the loaded data back to the project (just copies the reference).
--
-- @param project Project to receive the data
-- @private
function DataManager:save_data(project)
    local new_data = {}
    local valid = self.model:get_iter_first(self.iter)

    while valid do
        local desc, obj_id  = self.model:get(self.iter, 0, 1)
        table.insert(new_data, {['desc'] = desc,
            ['obj'] = self.temp_data[obj_id]} )
        valid = self.model:iter_next(self.iter)
    end
    
    project.data = new_data
end

---
-- Adds a new empty data to the list.
--
-- @private
function DataManager:add_data()
    local data = self:create_empty_data()
    self:add_helper(data)
    self.data_changed = true
end

---
-- Removes the selected data from the list.
--
-- @private
function DataManager:remove_data()
    if self.selection:get_selected(self.iter) then
        local name, id = self.model:get(self.iter, 0, 1)
        local str = string.format(_"Permanently remove <b>%s</b>?", name)
    
        if Utils.show_confirmation(str) then
            self.model:remove(self.iter)
            self.temp_data[id] = nil -- release the reference to allow gc
            self.data_changed = true
        end
    end
end

---
-- Scales the selected data from the list.
function DataManager:scale_data()
    if self.selection:get_selected(self.iter) then
        if not self.scale_dialog then
            local ScaleDialog = require('view.ScaleDialog')
            self.scale_dialog = ScaleDialog.new(self.dialog)
        end
    
        local id = self.model:get(self.iter, 1)
        local changed = self.scale_dialog:run(self.temp_data[id])
        
        if changed then
            self.data_changed = true
        end
    end
end

---
-- Copies the selected data from the list into the NetworkRunner dialog.
--
-- @private
function DataManager:run_copy_data()
    if self.selection:get_selected(self.iter) then
        local id = self.model:get(self.iter, 1)
        local data = self.temp_data[id]
        
        self.ctrl:network_run(data)
    end
end

---
-- Copies the selected data from the list.
--
-- @private
function DataManager:copy_data()
    if self.selection:get_selected(self.iter) then
        local name, id = self.model:get(self.iter, 0, 1)
        local new_data = self.temp_data[id]:duplicate()
        self:add_helper({desc = _"(Copy)" .. name, obj = new_data})
        self.data_changed = true
    end
end

---
-- Shuffles the selected data from the list.
--
-- @private
function DataManager:shuffle_data()
    if self.selection:get_selected(self.iter) then
        local id = self.model:get(self.iter, 1)
        self.temp_data[id]:shuffle()
        self.data_changed = true
    end
end

---
-- Edits the selected data from the list.
--
-- @private
function DataManager:edit_data()
    if self.selection:get_selected(self.iter) then
        if not self.editor then
            local DataEditor = require('view.DataEditor')
            self.editor = DataEditor.new(self.dialog)
        end
    
        local id = self.model:get(self.iter, 1)
        local new_data = self.editor:run(self.temp_data[id], self.maps)
        self.temp_data[id] = new_data
        self.data_changed = true
    end
end

---
-- Handles a cell edition.
--
-- @private
function DataManager:cell_edited(path, data)
    if not data or data == '' then return false end
    self.model:get_iter_from_string(self.iter, path)
    self.model:set(self.iter, 0, data)
    self.data_changed = true
end

---
-- Updates the buttons based on the current selection.
--
-- @private
function DataManager:selection_changed()
    local is_selected = self.selection:get_selected(self.iter)
    self.run_copy:set('sensitive', is_selected)
    self.copy:set('sensitive', is_selected)
    self.edit:set('sensitive', is_selected)
    self.scale:set('sensitive', is_selected)
    self.shuffle:set('sensitive', is_selected)
    self.remove:set('sensitive', is_selected)
end

---
-- Clears the manager.
--
-- @private
function DataManager:clear()
    self.temp_data = {}
    self.temp_index = 1
    self.view:set('model', nil)
    self.model:clear()
    self.view:set('model', self.model)
    self:selection_changed()
end

---
-- Prepates the data manager.
--
-- @private
function DataManager:prepare(project, ctrl)
    self.data_changed = false
    self.ctrl = ctrl
    self:clear()
    
    if project then
        self.maps = project.maps
    
        -- Load the data
        self.num_input = project.network:get_num_input()
        self.num_output = project.network:get_num_output()
        
        for i, data in ipairs(project.data) do
            self:add_helper(data)
        end
    else
        self.maps = nil
    end
end

---
-- Runs the data manager.
--
-- @param ctrl Main controller to use
-- @param project Project that will have the training data handled.
-- @return true if the data changed
function DataManager:run(ctrl, project)
    self:prepare(project, ctrl)
    
    -- Running
    self.dialog:run()
    self.dialog:hide()
    
    -- Saving the changes
    self:save_data(project)
    local changed = self.data_changed
    
    self:prepare()
    return changed
end

return DataManager

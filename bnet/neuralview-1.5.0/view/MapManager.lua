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
-- Dialog that handles a list of maps.
--
-- To store the maps and the relations, the following data structures
-- are used:
-- <ul>
-- <li>self.maps: array that contains the current maps
-- (may have 'holes') </li>
-- <li>self.model: list in the form (mapname, self.maps index) </li>
-- <li>self.neurons_tab.model: list in the form (neuron identifier, 
-- self.maps index)</li>
-- </ul>
local MapManager, MapManagerMT = nv_module('view.MapManager')

local Map = require('core.Map')

local NO_MAP = {name = _"No map"} -- dummy

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of MapManager 
function MapManager.new(parent)
    local self = {}
    setmetatable(self, MapManagerMT)
    
    self:build_gui(parent)
    self.iter = gtk.TreeIter.new()
    self.neurons = {}
    
    return self
end

---
-- Builds the map creation / edition / removal tab.
--
-- @private
function MapManager:build_map_tab()
    local tab = {}
    self.map_tab = tab
    
    tab.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 5)
    tab.button_box = gtk.ButtonBox.new(gtk.ORIENTATION_VERTICAL)
    tab.button_box:set('layout-style', gtk.BUTTONBOX_START)
    
    tab.add = gtk.Button.new_with_mnemonic(_"_Add")
    tab.add:connect('clicked', self.add_map, self)
    tab.add:set('tooltip-text', _"Add a new map")
    
    tab.edit = gtk.Button.new_with_mnemonic(_"_Edit")
    tab.edit:connect('clicked', self.edit_map, self)
    tab.edit:set('tooltip-text', _"Edit the selected map")
    
    tab.remove = gtk.Button.new_with_mnemonic(_"_Remove")
    tab.remove:connect('clicked', self.remove_map, self)
    tab.remove:set('tooltip-text', _"Remove the selected map")
    
    tab.button_box:add(tab.add, tab.edit, tab.remove)
    
    self.model = gtk.ListStore.new('gchararray', 'gint')
    tab.view = gtk.TreeView.new_with_model(self.model)
    tab.view:set('enable-search', false, 'enable-tree-lines', true,
        'reorderable', true, 'hexpand', true, 'vexpand', true)
    tab.selection = tab.view:get_selection()
    tab.selection:connect('changed', self.selection_changed, self)
    
    tab.cell_renderer = gtk.CellRendererText.new()
    tab.cell_renderer:set('editable', true)
    tab.cell_renderer:connect('edited', self.cell_edited, self)
    tab.column = gtk.TreeViewColumn.new_with_attributes(_"Map name",
        tab.cell_renderer, 'text', 0)
    tab.view:append_column(tab.column)
    
    tab.scroll = gtk.ScrolledWindow.new()
    tab.scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC,
        'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    tab.scroll:add(tab.view)
    
    tab.hbox:pack_start(tab.scroll, true, true, 0)
    tab.hbox:pack_start(tab.button_box, false, true, 0)
    
    tab.label = gtk.Label.new_with_mnemonic(_"_Maps")
    tab.label:set('tooltip-text', _"Available maps")
end

---
-- Builds the neurons tab.
--
-- @private
function MapManager:build_neurons_tab()
    local tab = {}
    self.neurons_tab = tab
    
    tab.model = gtk.ListStore.new('gchararray', 'gint')
    tab.view = gtk.TreeView.new_with_model(tab.model)
    tab.view:set('hexpand', true, 'vexpand', true)
    tab.neuron_cell = gtk.CellRendererText.new()
    tab.neuron_col = gtk.TreeViewColumn.new_with_attributes(_"Neuron",
        tab.neuron_cell, 'text', 0)
    tab.map_cell = gtk.CellRendererCombo.new()
    tab.map_cell:set('model', self.model, 'text-column', 0,
        'has-entry', false, 'editable', true)
    tab.map_cell:connect('changed', self.neurons_map_changed, self)
    tab.map_cell:connect('edited', self.neurons_map_edited, self)
    tab.map_col = gtk.TreeViewColumn.new_with_attributes(_"Map",
        tab.map_cell, 'text', 1)
    tab.map_col:set_cell_data_func(tab.map_cell,
        self.neurons_map_cell_data_func, self)
    
    tab.view:append_column(tab.neuron_col)
    tab.view:append_column(tab.map_col)
    
    tab.scroll = gtk.ScrolledWindow.new()
    tab.scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 
        'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    tab.scroll:add(tab.view)
    
    tab.label = gtk.Label.new_with_mnemonic(_"_Neurons")
    tab.label:set('tooltip-text', _"Map associations")
end

---
-- Builds the interface.
--
-- @param parent Parent window
-- @private
function MapManager:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('transient-for', parent, 'title', _"Map manager",
        'default-width', 400, 'default-height', 300, 'icon', NVIcon)
    self.dialog:add_button('gtk-close', gtk.RESPONSE_OK)
    
    self.vbox = self.dialog:get_content_area()
    self.notebook = gtk.Notebook.new()
    
    self:build_map_tab()
    self.notebook:append_page(self.map_tab.hbox, self.map_tab.label)
    
    self:build_neurons_tab()
    self.notebook:append_page(self.neurons_tab.scroll, self.neurons_tab.label)
    
    self.vbox:add(self.notebook)
    self.vbox:show_all()
end

---
-- @private
function MapManager:neurons_map_changed(path, iter)
    -- set the neuron map
    local neuron = tonumber(path) + 1
    local map = self.model:get(iter, 1)
    self.neurons[neuron] = map
    self.data_changed = true
end

---
-- @private
function MapManager:neurons_map_edited(path)
    local neuron = tonumber(path) + 1
    self.neurons_tab.model:get_iter_from_string(self.iter, path)
    self.neurons_tab.model:set(self.iter, 1, self.neurons[neuron])
end

---
-- @private
function MapManager:neurons_map_cell_data_func(iter)
    local map = self.neurons_tab.model:get(iter, 1)
    map = self.maps[map]
    
    -- if the map doesn't exists them it's because it was removed
    -- all these special cases must be handled in self:save_maps()
    if map then
        name = map.name
    else
        name = NO_MAP.name
    end
    
    self.neurons_tab.map_cell:set('text', name)
end

---
-- @private
function MapManager:add_helper(map)
    self.model:append(self.iter)
    self.model:seto(self.iter, map.name, self.map_index)
    self.maps[self.map_index] = map
    self.map_index = self.map_index + 1
end

---
-- @private
function MapManager:add_map()
    self:add_helper(Map.new())
    self.data_changed = true
end

---
-- @private
function MapManager:edit_map()
    if self:has_selection() then
        if not self.editor then
            local MapEditor = require('view.MapEditor')
            self.editor = MapEditor.new(self.dialog)
        end
    
        local id = self.model:get(self.iter, 1)
        local new_map = self.editor:run(self.maps[id])
        
        new_map.name = self.maps[id].name
        new_map.cols = self.maps[id].cols
        
        self.maps[id] = new_map
        self.data_changed = true
    end
end

---
-- @private
function MapManager:remove_map()
    if self:has_selection() then
        local id = self.model:get(self.iter, 1)
        self.model:remove(self.iter)
        self.maps[id] = nil -- release the reference to allow gc
        self.data_changed = true
    end
end

---
-- @private
function MapManager:has_selection()
    local has_sel = self.map_tab.selection:get_selected(self.iter)
    
    if has_sel then
        local map = self.maps[self.model:get(self.iter, 1)]
        has_sel = map ~= NO_MAP
    end
    
    return has_sel
end

---
-- @private
function MapManager:selection_changed()
    local tab = self.map_tab
    local has_sel = self:has_selection()
    tab.edit:set('sensitive', has_sel)
    tab.remove:set('sensitive', has_sel)
end

---
-- @private
function MapManager:cell_edited(path, data)
    if self:has_selection() then
        if not data or data == '' then return false end
        self.model:get_iter_from_string(self.iter, path)
        
        local map = self.model:get(self.iter, 1)
        self.maps[map].name = data
        
        self.model:set(self.iter, 0, data)
        self.data_changed = true
    end
end

---
-- Prepares the manager for an array of maps.
--
-- @param project Project that contains the maps
-- @private
function MapManager:prepare(project)
    self.project = project
    self.map_index = 0
    self.maps = {}
    
    self.map_tab.view:set('model', nil)
    self.neurons_tab.view:set('model', nil)
    self.model:clear()
    self.neurons_tab.model:clear()
    
    if project then
        -- the mighty "No map"
        self:add_helper(NO_MAP)
        
        -- read the relations from the maps
        local rel = {}
    
        -- populate the maps    
        for i, map in ipairs(project.maps) do
            self:add_helper(map)
            
            for j, r in ipairs(map.cols) do
                rel[r] = i
            end
        end
        
        local model, network = self.neurons_tab.model, project.network
        
        -- add the input neurons
        local num_input = network:get_num_input()
        
        for i = 1, num_input do
            model:append(self.iter)
            model:seto(self.iter, _"Input#" .. i, rel[i] or 0)
        end
        
        -- add the output neurons
        local num_output = network:get_num_output()
        
        for i = 1, num_output do
            model:append(self.iter)
            model:seto(self.iter, _"Output#" .. i, rel[i + num_input] or 0)
        end
    end
    
    self.map_tab.view:set('model', self.model)
    self.neurons_tab.view:set('model', self.neurons_tab.model)
end

---
-- Saves the maps back to the project.
--
-- @private
function MapManager:save_maps()
    -- holes can be present in the map table, so we must skip them and
    -- shift the maps 'to zero'
    
    -- get the references, with the original ids
    local refs = {} -- map<map_id, {neuron_id} >
    local tab = self.neurons_tab
    
    local valid, i = tab.model:get_iter_first(self.iter), 1
    
    while valid do
        local map_id = tab.model:get(self.iter, 1)
        if not refs[map_id] then refs[map_id] = {} end 
        table.insert(refs[map_id], i)
        
        valid = tab.model:iter_next(self.iter)
        i = i + 1
    end
    
    -- get the maps and their relations from the refs table, and store then
    -- in a new array, without holes
        
    local new_maps = {}
    local valid = self.model:get_iter_first(self.iter)
    
    while valid do
        local map_id = self.model:get(self.iter, 1)
        local map = self.maps[map_id]
        
        if map and map ~= NO_MAP then
            map.cols = refs[map_id] or {}
            table.insert(new_maps, map)
        end
        
        valid = self.model:iter_next(self.iter)
    end
    
    self.project.maps = new_maps
end

---
-- Runs the dialog.
--
-- @param project Project that contains the maps
-- @return true if the maps changed
function MapManager:run(project)
    self.data_changed = false
    self:prepare(project)
    
    self.dialog:run()
    self.dialog:hide()
    
    self:save_maps()
    self:prepare()
    
    return self.data_changed
end

return MapManager

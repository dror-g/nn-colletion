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
-- Dialog that allows the user to edit training and test data.
local DataEditor, DataEditorMT = nv_module('view.DataEditor')

---
-- Dialog reimplementation for a greater control.
--
-- @private
function DataEditor:response()
    local self, resp = unpack(self)
    self.response = resp
    gtk.main_quit()
    
    return true
end

---
-- Constructor.
--
-- @param parent Parent window
-- @param self Permits inheritance (internal use)
-- @return New instance of DataEditor 
function DataEditor.new(parent, self)
    if not self then
        self = {}
        setmetatable(self, DataEditorMT)
    end
    
    self:build_gui(parent)
    self.iter = gtk.TreeIter.new()
    self.columns = {}
    self.renderers = {}
    self.current_columns = 0
    self.n_rows = 0
    
    return self
end

---
-- @private
function DataEditor:add_action_buttons(box)
    self.map = gtk.CheckButton.new_with_mnemonic(_"_Map")
    self.map:connect('clicked', self.toggle_map, self)
    self.map:set('tooltip-text', _"Toggle the map visualization")
    
    self.add = gtk.Button.new_with_mnemonic(_"_Add")
    self.add:connect('clicked', self.add_row, self)
    self.add:set('tooltip-text', _"Add a new row")
    
    self.remove = gtk.Button.new_with_mnemonic(_"_Remove")
    self.remove:connect('clicked', self.remove_rows, self)
    self.remove:set('tooltip-text', _"Remove the selected rows")
    
    box:pack_start(self.map, false, true, 0)
    box:pack_start(self.add, false, true, 0)
    box:pack_start(self.remove, false, true, 0)
end

---
-- @private
function DataEditor:add_response_buttons(box)
    self.cancel = gtk.Button.new_with_mnemonic(_"_Cancel")
    self.cancel:connect('clicked', self.response, {self, gtk.RESPONSE_CANCEL})
    self.save = gtk.Button.new_with_mnemonic(_"_Save")
    self.save:connect('clicked', self.response, {self, gtk.RESPONSE_OK})
    
    box:pack_start(self.cancel, false, true, 0)
    box:pack_start(self.save, false, true, 0)
end

---
-- Builds the interface.
--
-- @private
function DataEditor:build_gui(parent)
    self.window = gtk.Window.new()
    self.window:set('transient-for', parent, 'window-position',
        gtk.WIN_POS_CENTER_ON_PARENT,
        'default-width', 500, 'default-height', 400, 'title', _"Data editor",
        'modal', true, 'icon', NVIcon)
        
    self.accel_group  = gtk.AccelGroup.new()
    self.accel_group:connect('Escape', self.response, {self, gtk.RESPONSE_CANCEL})
    self.window:add_accel_group(self.accel_group)
    
    self.button_box = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    self.hbox1      = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    self.hbox2      = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    
    -- this allows subclasses to customize this in a clean way
    self:add_action_buttons(self.hbox1)
    self:add_response_buttons(self.hbox2)
    
    self.align1 = gtk.Alignment.new(0, 0.5, 0, 0)
    self.align1:add(self.hbox1)
    self.align2 = gtk.Alignment.new(1, 0.5, 0, 0)
    self.align2:add(self.hbox2)
    
    self.button_box:pack_start(self.align1, true, true, 0)
    self.button_box:pack_start(self.align2, true, true, 0)
    
    self.scroll = gtk.ScrolledWindow.new()
    self.scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC,
        'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.view = gtk.TreeView.new()
    self.view:set('enable-search', false, 'enable-tree-lines', true,
        'reorderable', true)
        
    self.selection = self.view:get_selection()
    self.selection:set_mode(gtk.SELECTION_MULTIPLE)
    self.selection:connect('changed', self.selection_changed, self)
    
    self.scroll:add(self.view)
    
    self.vbox = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 5)
    self.vbox:pack_start(self.scroll, true, true, 0)
    self.vbox:pack_start(self.button_box, false, true, 5)
    self.vbox:show_all()

    self.window:add(self.vbox)
    self.window:connect('delete-event', self.response, {self, gtk.RESPONSE_CANCEL})
end

---
-- Toggles the map on / off.
function DataEditor:toggle_map()
    -- In fact, the render_cell method handles this. Here we just redraw the
    -- list to make the interface responsive.
    self.view:queue_draw()
end

---
-- Renders the values.
function DataEditor:render_cell(iter)
    local self, col = unpack(self)
    if not self.map:get('active') or not self.rel then return end
    
    local map = self.rel[col]
    
    -- If we have a map for that column
    if map then
        local val = self.model:get(iter, col - 1)
        local label = map:get_label(val)
        
        -- If the map have a label for that value
        if label then
            self.renderers[col]:set('text', label) 
        end
    end
end

---
-- Clears the view, removing all columns and detaching the model.
--
-- @private
function DataEditor:clear_view()
    self.view:set('model', nil)
    if self.model then self.model:clear() end
    
    local c = self.current_columns
    
    for i = 1, c do
        local col = self.columns[i]
        self.view:remove_column(col)
    end
    
    self.current_columns = 0
    self.n_rows = 0
end

---
-- Adds a column to the view. Re-uses columns in the cache.
--
-- @private
function DataEditor:add_column(pos, title, read_only)
    local col = self.columns[pos]
    local rend = self.renderers[pos]
    
    if not col then
        rend = gtk.CellRendererText.new()
        rend:connect('edited', self.cell_edited, {self, pos -1})
        
        col = gtk.TreeViewColumn.new_with_attributes('', rend, 'text',
            pos - 1)
        col:set('resizable', true)
        col:set_cell_data_func(rend, self.render_cell, {self, pos})
        self.columns[pos] = col
        self.renderers[pos] = rend
    end
    
    rend:set('editable', not read_only)
    col:set('title', title)
    col:queue_resize()
    self.view:append_column(col)
    self.current_columns = self.current_columns + 1
end

DataEditor.TITLE_INPUT = _"Input#"
DataEditor.TITLE_OUTPUT = _"Output#"

---
-- Adds a row to the end of the model.
--
-- @private
function DataEditor:add_row()
    self.model:append(self.iter)
    self.n_rows = self.n_rows + 1
end

---
-- Remove the selected rows.
--
-- @private
function DataEditor:remove_rows()
    local rows = self.selection:get_selected_rows()
    self.view:set('model', nil) -- avoids n^2 behaviour
    
    -- remove in inverted ordem to prevent the paths from changing
    local len = #rows
    
    for i = len, 1, -1 do
        self.model:get_iter_from_string(self.iter, rows[i])
        self.model:remove(self.iter)
        self.n_rows = self.n_rows - 1
    end
    
    self.view:set('model', self.model)
end

---
-- Handles a cell edition.
--
-- @private
function DataEditor:cell_edited(path, data)
    local weight = tonumber(data)
    if not weight then return end
    
    local self, cell = unpack(self)
    self.model:get_iter_from_string(self.iter, path)
    self.model:set(self.iter, cell, weight)
end

---
-- Updates the buttons based on the current selection.
--
-- @private
function DataEditor:selection_changed()
    local rows = self.selection:get_selected_rows()
    self.remove:set('sensitive', #rows > 0)
end

---
-- To allow a base class to override the selection changed. 
--
-- @private
function DataEditor:selection_changed_cb()
    self:selection_changed()
end

---
-- Adds a list of maps to the editor.
--
-- @param maps Table (array) with the maps to be added
function DataEditor:add_maps(maps)
    if maps then
        self.maps = maps
        local rel = {}
        
        for i, map in ipairs(maps) do
            for j, col in ipairs(map.cols) do
                rel[col] = map
            end
        end
        
        self.rel = rel
    else
        self.maps = nil
        self.rel = nil
    end
end

---
-- Creates and populates the model.
--
-- @param num_input Number of input neurons
-- @param num_output Number of output neurons
-- @param data Data to populate the model (optional)
function DataEditor:create_model(num_input, num_output, data)
    local total = num_input + num_output
    
    -- Create the model
    local t = {}
    for i = 1, total do table.insert(t, 'gdouble') end
    self.model = gtk.ListStore.new(unpack(t))
    
    -- Create the columns
    for i = 1, total do
        local title = i <= num_input and DataEditor.TITLE_INPUT .. i or
            DataEditor.TITLE_OUTPUT .. (i - num_input)
        self:add_column(i, title)
    end
    
    if data then
        local len = data:length()
        
        -- Populate the model
        for i = 1, len do
            local row = data:get_row(i)
            self.model:append(self.iter)
            self.model:seto(self.iter, unpack(row) )
            self.n_rows = self.n_rows + 1
        end
    end
    
    -- set the model
    self.view:set('model', self.model)
    self.view:show_all()
end

---
-- Prepares the editor.
--
-- @param data fann.Data to be loaded
-- @param maps Visualization maps to use
-- @private
function DataEditor:prepare(data, maps)
    self:clear_view()
    self:add_maps(maps)
    
    if data then
        local len, num_input, num_output = data:length(), data:num_input(),
            data:num_output()
            
        self:create_model(num_input, num_output, data)
    end
end

---
-- Callback that handles the creation of the fann.Data.
--
-- @private
local function creation_callback(ud, ndata, num_in, num_out)
    local model, iter, rows = unpack(ud)
    if(ndata > 1) then model:iter_next(iter) end
    return model:get(iter, unpack(rows))
end

---
-- Creates a new fann.Data based o the contents of the editor.
--
-- @param num_input Number of input neurons
-- @param num_output Number of output neurons
-- @return New fann.Data created with the editor values
-- @private
function DataEditor:save_data(num_input, num_output)
    self.model:get_iter_first(self.iter)
    
    local rows, total = {}, num_input + num_output
    for i = 1, total do table.insert(rows, i-1) end
    
    local data = fann.Data.create_from_callback(self.n_rows, num_input,
        num_output, creation_callback, {self.model, self.iter, rows})
    
    return data
end

---
-- Runs the editor.
--
-- @param data The data to be edited
-- @param maps Visualization maps to be used
-- @return The original data, if the user canceled, or the new one if the user
-- confirmed the changes.
function DataEditor:run(data, maps)
    self:prepare(data, maps)
    self.response = gtk.RESPONCE_CANCEL
    
    self.window:show()
    gtk.main()
    self.window:hide()
    
    if self.response == gtk.RESPONSE_OK then
        data = self:save_data(data:num_input(), data:num_output())
    end
    
    self:prepare()
    
    return data
end

return DataEditor

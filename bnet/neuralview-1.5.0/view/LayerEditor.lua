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
-- Widget that allows the user to define the layers of a neural network.
local LayerEditor, LayerEditorMT = nv_module('view.LayerEditor')

local Utils = require('view.Utils')

---
-- Constructor.
--
-- @param fixed_input_output If the user can't edit the number of input and
-- output neurons
-- @return New LayerEditor instance
function LayerEditor.new(fixed_input_output)
    local self = {}
    setmetatable(self, LayerEditorMT)
    
    self.iter = gtk.TreeIter.new()
    self:build_gui()
    self.fixed_input_output = fixed_input_output
    
    return self
end

---
-- Initializes the values of the editor.
--
-- @param layer_array Array with the number of neurons of each layer (without
-- the bias neurons)
function LayerEditor:init(layer_array)
    -- adjust the number of layers
    self:clear_layers()
    local len = #layer_array - 2
    
    for hidden = 1, len do
        self:add_layer()
    end
    
    -- set the values
    self.model:get_iter_first(self.iter)
    
    for layer, neurons in ipairs(layer_array) do
        self.model:set(self.iter, 1, neurons)
        self.model:iter_next(self.iter)
    end
end

---
-- Builds the interface.
--
-- @private
function LayerEditor:build_gui()
    self.model = gtk.ListStore.new('gchararray', 'guint')
    self.box   = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    
    Utils.populate_model(self.model, {
        {_"Input", 1},
        {_"Output", 1}
    })
    
    self.cell1 = gtk.CellRendererText.new()
    self.cell1:set('xalign', 0.5)
    self.cell2 = gtk.CellRendererText.new()
    self.cell2:set('xalign', 0.5, 'editable', true)
    self.cell2:connect('edited', self.edit_neuron, self)
    self.col1 = gtk.TreeViewColumn.new_with_attributes(_"Layer", self.cell1, 'text', 0)
    self.col1:set('expand', true, 'alignment', 0.5)
    self.col2 = gtk.TreeViewColumn.new_with_attributes(_"Neurons", self.cell2, 'text', 1)
    self.col2:set('expand', true, 'alignment', 0.5)
    
    self.view = gtk.TreeView.new_with_model(self.model)
    self.view:set('enable-search', false)
    self.view:append_column(self.col1)
    self.view:append_column(self.col2)
    
    -- Selection
    self.selection = self.view:get_selection()
    self.n_hidden = 0
    
    -- Add / remove / clear layer buttons
    self.button_box = gtk.ButtonBox.new(gtk.ORIENTATION_VERTICAL)
    self.button_box:set('layout-style', gtk.BUTTONBOX_START)
    
    self.add = gtk.Button.new_with_mnemonic(_"_Add")
    self.add:set('tooltip-text', _"Add a hidden layer")
    self.add:connect('clicked', self.add_layer, self)
    
    self.remove = gtk.Button.new_with_mnemonic(_"_Remove")
    self.remove:set('tooltip-text', _"Remove a hidden layer")
    self.remove:connect('clicked', self.remove_layer, self)
    
    self.reset = Utils.new_button('gtk-clear', _"Res_et")
    self.reset:set('tooltip-text', _"Remove all hidden layers and added neurons")
    self.reset:connect('clicked', self.clear_layers, self)
    
    self.button_box:add(self.add, self.remove, self.reset)
    
    self.scroll = gtk.ScrolledWindow.new()
    self.scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.scroll:add(self.view)
    self.box:pack_start(self.scroll, true, true, 0)
    self.box:pack_start(self.button_box, false, true, 0)
    
    self.hl = _"Hidden" .. ' #'
end

---
-- Handles the neuron cell edit event.
--
-- @param path TreePath of the current selection, as a string
-- @param data The new cell data
-- @private
function LayerEditor:edit_neuron(path, data)
    if self.fixed_input_output then
        -- do not allow the user to edit the input and output neurons
        local p = tonumber(path)
        if p == 0 or p == self.n_hidden +1 then return end
    end
    
    local n = tonumber(data)
    if(not n or n < 1) then return end
    
    if n > 100000 then n = 100000 end
    self.model:get_iter_from_string(self.iter, path)
    self.model:set(self.iter, 1, n)
end

---
-- Appends a hidden layer.
--
-- @private
function LayerEditor:add_layer()
    if self.n_hidden >= 100 then return end
    self.n_hidden = self.n_hidden + 1
    self.model:insert(self.iter, self.n_hidden)
    self.model:seto(self.iter, self.hl .. self.n_hidden, 1)
end

---
-- Removes the last hidden layer.
--
-- @private
function LayerEditor:remove_layer()
    if(self.n_hidden < 1) then return end
    self.model:get_iter_from_string(self.iter, self.n_hidden)
    self.model:remove(self.iter)
    self.n_hidden = self.n_hidden - 1
end

---
-- Gets a table with the number of neurons in each layer.
--
-- @return Array with the number of neurons in each layer
function LayerEditor:get_layers()
    local valid = self.model:get_iter_first(self.iter)
    local tbl = {}
    
    while valid do
        table.insert(tbl, self.model:get(self.iter, 1))
        valid = self.model:iter_next(self.iter)
    end
    
    return tbl
end

---
-- Resets the layers to the defaults.
--
-- @private
function LayerEditor:clear_layers()
    local n_input, n_output = 1, 1
    
    if self.fixed_input_output then
        -- only remove the hidden layers
        local layers = self:get_layers()
        n_input = layers[1]
        n_output = layers[#layers]
    end

    Utils.populate_model(self.model, {
        {_"Input",  n_input },
        {_"Output", n_output}
    }, true, self.view)
    
    self.n_hidden = 0
end

return LayerEditor

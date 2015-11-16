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
-- Widget that allows the user to view the weights os a neural network in a
-- table format.
local WeightViewer, WeightViewerMT = nv_module('view.WeightViewer')

local Utils = require('view.Utils')

---
-- Constructor.
--
-- @return New instance of WeightViewer 
function WeightViewer.new()
    local self = {}
    setmetatable(self, WeightViewerMT)
    
    self.iter = gtk.TreeIter.new()
    self:build_gui()
    
    return self
end

---
-- @private
local function set_search_col(data)
    local view, id = unpack(data)
    view:set_search_column(id)
    view:grab_focus()
end

---
-- @private
function WeightViewer:new_column(label, id)
    local cell = gtk.CellRendererText.new()
    local col = gtk.TreeViewColumn.new_with_attributes(label, cell, 'text', id)
    col:set_sort_column_id(id)
    col:connect('clicked' , set_search_col, {self.view, id})
    
    return col, cell
end

---
-- Builds the interface.
--
-- @private
function WeightViewer:build_gui()
    self.model = gtk.ListStore.new('gint', 'gint', 'gdouble')
    self.view = gtk.TreeView.new_with_model(self.model)
    
    self.from_col = self:new_column(_"From", 0)
    self.to_col = self:new_column(_"To", 1)
    self.weight_col = self:new_column(_"Weight", 2)
    
    self.view:append_column(self.from_col)
    self.view:append_column(self.to_col)
    self.view:append_column(self.weight_col)
    self.view:connect('row-activated', self.row_activated, self)
    self.view:set('hexpand', true, 'vexpand', true)
    
    self.scroll = gtk.ScrolledWindow.new()
    self.scroll:set('vscrollbar-policy', gtk.POLICY_AUTOMATIC,
        'hscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.scroll:add(self.view)

    self.layer_label = gtk.Label.new_with_mnemonic(_"_Layer")
    self.layer_spin = gtk.SpinButton.new_with_range(1, 1, 1)
    self.layer_label:set('mnemonic-widget', self.layer_spin, 'tooltip-text',
        _"Source layer to show the connections")
    self.id = self.layer_spin:connect('value-changed', self.layer_changed, self)
    self.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 5)
    self.hbox:pack_start(self.layer_label, false, true, 0)
    self.hbox:pack_start(self.layer_spin, true, true, 0)

    self.vbox = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 5)
    self.vbox:pack_start(self.hbox, false, true, 0)
    self.vbox:pack_start(self.scroll, true, true, 0)
    
    self.label_size_group = gtk.SizeGroup.new(gtk.SIZE_GROUP_BOTH)
    self.label_size_group:add_widget(self.layer_label)
    self.layer_label:set('xalign', 1)
end

---
-- @private
function WeightViewer:layer_changed()
    local layer = self.layer_spin:get('value')
    self:populate(layer)
end

---
-- Gets the layer and the position in the layer of a neuron id.
-- O(n), where n is the number os layers.
--
-- @param neuron_id Neuron id
-- @return layer, position, is bias
-- @private
function WeightViewer:get_layer_pos(neuron_id)
    local init = self.layer_init
    local layer = 1
    
    while neuron_id >= init[layer + 1] do
        layer = layer + 1
    end
    
    local pos = neuron_id - init[layer] + 1
    local is_bias = pos > (self.layer_array[layer] - self.bias_array[layer])
    
    return layer, pos, is_bias
end

---
-- Shows a more detailed description of the connection for the user.
-- It's implemented this way for performance reasons.
-- 
-- @private
function WeightViewer:row_activated(path)
    if self.model:get_iter(self.iter, path) then
        local from, to, weight = self.model:get(self.iter, 0, 1, 2)
        local f_layer, f_pos, f_bias = self:get_layer_pos(from)
        local t_layer, t_pos, t_bias = self:get_layer_pos(to)
        
        local f_detail = string.format(_" (layer: %d, pos: %d%s)", f_layer, 
            f_pos, f_bias and _", bias" or "")
        local t_detail = string.format(_" (layer: %d, pos: %d%s)", t_layer,
            t_pos, t_bias and _", bias" or "")
        
        local info = {
            _"<b>Connection details:</b>\n\n",
            _"<i>From:</i> ", from, f_detail, "\n",
            _"<i>To:</i> ", to, t_detail, "\n",
            _"<i>Weight:</i> ", string.format("%.6f", weight) 
        }
        info = table.concat(info)
        Utils.show_info(info)
    end
end

---
-- Populates the model with the connections of a layer.
--
-- @param layer Layer ("from") to get the connections
function WeightViewer:populate(layer)
    local model, iter = self.model, self.iter
    local conn = self.conn_array
    
    -- disable the sorting and clear the model
    self.view:set_search_column(-1)
    self.view:set('model', nil)
    model:set_sort_column_id(gtk.TREE_SORTABLE_UNSORTED_SORT_COLUMN_ID, 
        gtk.SORT_DESCENDING)
    model:clear()
    
    -- populate the model
    if layer then
        local neuron_id = self.layer_init[layer]
        local layer_end = self.layer_init[layer + 1] - 1
        
        for from = neuron_id, layer_end do
            local aux = conn[from]
            
            if aux then
                for to, weight in pairs(aux) do
                    model:append(iter)
                    model:seto(iter, from, to, weight)
                end
            end
        end
    end
    
    self.view:set('model', model)
end

---
-- Prepares the widget for new connections.
--
-- @param layer_array Array with the number of neurons in each layer
-- @param bias_array Array with the number of bias in each layer
-- @param conn_array Map<layer, layer_array> with the connections
function WeightViewer:prepare(layer_array, bias_array, conn_array)
    self.conn_array = conn_array
    self.bias_array = bias_array
    
    if layer_array then
        -- compute the initial position of each layer, adding the bias array
        -- to the layer_array
        local new_layer_array = {}
        local b, acc = {}, 1
        
        for i, j in ipairs(layer_array) do
            local n = j + bias_array[i]
            new_layer_array[i] = n
            b[i] = acc
            acc = acc + n
        end
        
        b[#new_layer_array + 1] = acc
        self.layer_array = new_layer_array
        self.layer_init = b
    
        self.layer_spin:set('sensitive', true)
        
        -- only one populate, please
        self.layer_spin:block(self.id)
        self.layer_spin:set_range(1, #layer_array - 1, 1)
        self.layer_spin:unblock(self.id)
        
        self:layer_changed()
    else
        self.layer_spin:set('sensitive', false)
        self:populate()
    end
end

return WeightViewer

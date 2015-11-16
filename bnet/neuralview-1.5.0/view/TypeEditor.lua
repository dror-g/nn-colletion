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
-- Widget to edit the type of a neural network.
local TypeEditor, TypeEditorMT = nv_module('view.TypeEditor')

local Utils = require('view.Utils')

---
-- Constructor.
--
-- @return New TypeEditor instance
function TypeEditor.new()
    local self = {}
    setmetatable(self, TypeEditorMT)
    
    self:build_gui()
    
    return self
end

---
-- Buils the interface.
--
-- @private
function TypeEditor:build_gui()
    self.box = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 5)
    self.model = gtk.ListStore.new('gchararray', 'gchararray')
    self.iter = gtk.TreeIter.new()
    
    Utils.populate_model(self.model, {
        {'standard', _"Standard"},
        {'shortcut', _"Shortcut"},
        {'sparse', _"Sparse"},
    })
    
    self.cell = gtk.CellRendererText.new()
    self.combo = gtk.ComboBox.new_with_model(self.model)
    self.combo:pack_start(self.cell, false)
    self.combo:add_attribute(self.cell, 'text', 1)
    self.combo:set('active', 0)
    self.combo:connect('changed', self.type_selected, self)
    
    self.rate_label = gtk.Label.new_with_mnemonic(_"_Rate %")
    self.rate_spin = gtk.SpinButton.new_with_range(1, 100, 1)
    self.rate_spin:set('width-chars', 4, 'numeric', true, 'value', 100)
    self.rate_spin:set('no-show-all', true)
    self.rate_label:set('no-show-all', true, 'mnemonic-widget',
        self.rate_spin, 'tooltip-text', _"Connection rate of the network")
    
    self.box:pack_start(self.combo, true, true, 0)
    self.box:pack_start(self.rate_label, false, true, 0)
    self.box:pack_start(self.rate_spin, false, true, 0)
end

---
-- Initializes the values of the editor.
--
-- @param network_type Network type to be selected
-- @param connection_rate Connection rate to be setted
function TypeEditor:init(network_type, connection_rate)
    if connection_rate ~= 1 then
        self.combo:set('active', 2)
        self.rate_spin:set('value', connection_rate * 100)
    else
        self.combo:set('active', network_type)
    end
end

---
-- Shows the rate editor only when the type selected is "sparse".
--
-- @private
function TypeEditor:type_selected()
    local is_sparse = self:get_type() == 'sparse'
    self.rate_label:set('visible', is_sparse)
    self.rate_spin:set('visible', is_sparse)
end

---
-- Gets the selected type ("standard", "shortcut" or "sparse") and the 
-- connection rate (scaled to FANN, from 0 to 1).
--
-- @return Network type and the connection rate
function TypeEditor:get_type()
    if self.combo:get_active_iter(self.iter) then
        local stype = self.model:get(self.iter, 0)
        return stype, stype == 'sparse' and self.rate_spin:get('value') / 100 or 1
    end
end

return TypeEditor

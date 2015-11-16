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
-- Widget that handles the creation and configuration of a neural network topology.
local NetworkNewDialog, NetworkNewDialogMT = nv_module('view.NetworkNewDialog')

local Utils         = require('view.Utils')
local LayerEditor   = require('view.LayerEditor')
local TypeEditor    = require('view.TypeEditor')

---
-- Constructor.
--
-- @param parent Parent window
-- @param edit_mode If the user can't edit the number of input and
-- output neurons
-- @return New NetworkNewDialog instance
function NetworkNewDialog.new(parent, edit_mode)
    local self = {}
    setmetatable(self, NetworkNewDialogMT)
    
    self:build_gui(parent, edit_mode)
    
    return self
end

---
-- Builds the interface.
--
-- @param parent Parent window
-- @param edit_mode If the user can't edit the number of input and
-- output neurons
-- @private
function NetworkNewDialog:build_gui(parent, edit_mode)
    local title = edit_mode and _"Edit network" or _"Create network"
    
    self.dialog = gtk.Dialog.new()
    self.dialog:set('title', title, 'transient-for', parent,
        'icon', NVIcon)
    
    self.table = gtk.Grid.new(2, 2, true)
    self.table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    -- Network type
    self.type_label = gtk.Label.new_with_mnemonic(_"_Type")
    self.type_editor = TypeEditor.new()
    self.table:attach(self.type_label, 0, 1, 1, 1 )
    self.table:attach_next_to(self.type_editor.box, self.type_label, 1, 1, 1, 1, 3)
    self.type_label:set('mnemonic-widget', self.type_editor.combo,
        'tooltip-text', _"Network connection type")
    
    -- Layers
    self.layer_label = gtk.Label.new_with_mnemonic(_"_Layers")
    self.layer_editor = LayerEditor.new(edit_mode)
    self.layer_editor.box:set('hexpand', true, 'vexpand', true)
    self.table:attach(self.layer_label, 0, 1, 1, 2, 0, 0)
    self.table:attach(self.layer_editor.box, 1, 2, 1, 2, of, of)
    self.layer_label:set('mnemonic-widget', self.layer_editor.view,
        'tooltip-text', _"Network topology")
    
    -- Pack it
    self.vbox = self.dialog:get_content_area()
    self.vbox:add(self.table)
    self.vbox:show_all()
    
    -- Buttons
    self.cancel, self.ok = self.dialog:add_buttons('gtk-cancel', gtk.RESPONCE_CANCEL,
        'gtk-ok', gtk.RESPONSE_OK)
        
    self.dialog:set('default-width', 400, 'default-height', 350)
end

---
-- Runs the dialog and returns the created neural network.
--
-- @param base_net Network to get the current number of neurons and type (can
-- be nil)
-- @return A new network, network type and connection rate.
-- If the user canceled, nil is returned. 
function NetworkNewDialog:run(base_net)
    -- initialize the fields?
    if base_net then
        local network_type      = base_net:get_network_type()
        local connection_rate   = base_net:get_connection_rate()
        local layer_array       = base_net:get_layer_array()
        
        self.type_editor:init(network_type, connection_rate)
        self.layer_editor:init(layer_array)
    end

    local res = self.dialog:run()
    self.dialog:hide()
    
    if res == gtk.RESPONSE_OK then
        return self:create_network()
    end
end

---
-- Creates a network based on the widget parameters.
-- @private
function NetworkNewDialog:create_network()
    local ntype, rate = self.type_editor:get_type()
    local layers = self.layer_editor:get_layers()
    local nn
    
    if ntype == 'standard' then
        nn = fann.Net.create_standard(layers)
    elseif ntype == 'shortcut' then
        nn = fann.Net.create_shortcut(layers)
    elseif ntype == 'sparse' then
        nn = fann.Net.create_sparse(rate, layers)
    else
        error(_"Invalid network type " .. ntype)
    end
    
    return nn, ntype, rate
end

return NetworkNewDialog

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
-- Dialog to configure the network activation functions.
local ActivationConfigurator, ActivationConfiguratorMT = nv_module('view.ActivationConfigurator')

local FannNetwork = require('core.FannNetwork')
local ParamWidget = require('view.ParamWidget')
local Utils = require('view.Utils')

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of ActivationConfigurator
function ActivationConfigurator.new(parent)
    local self ={}
    setmetatable(self, ActivationConfiguratorMT)
    
    self:build_gui(parent)
    
    return self
end

-- the fake NetworkParam
local activation_param = {
    type = 'option',
    name = _"Function",
    options = FannNetwork.activation_functions,
    tooltip = _"Activation function",
}

---
-- Refreshs the activation function and steepness of the
-- 'per neuron' page (isn't aplicable to the other page).
--
-- @private
function ActivationConfigurator:reload_neuron_info()
    local layer = self.per_neuron.layer_spin:get('value')
    self.per_neuron.neuron_spin:set_range(1, self.layer_array[layer])
    
    local neuron = self.per_neuron.neuron_spin:get('value')
    local step = self.network:get_activation_steepness(layer, neuron)
    local activation = self.network:get_activation_function(layer, neuron)
    
    self.per_neuron.step_spin:set('value', step)
    self.per_neuron.widget:set(activation)
end

---
-- Sets the values for the current neuron in the 'per neuron' page.
--
-- @private
function ActivationConfigurator:set_per_neuron()
    local layer = self.per_neuron.layer_spin:get('value')
    local neuron = self.per_neuron.neuron_spin:get('value')
    local step = self.per_neuron.step_spin:get('value')
    local activation = self.per_neuron.widget:get()
    
    self.network:set_activation_function(activation, layer, neuron)
    self.network:set_activation_steepness(step, layer, neuron)
end

---
-- Sets the values for the current layer in the 'per layer' page.
--
-- @private
function ActivationConfigurator:set_per_layer()
    local layer = self.per_layer.layer_spin:get('value')
    local step = self.per_layer.step_spin:get('value')
    local activation = self.per_layer.widget:get()
    
    self.network:set_activation_function_layer(activation, layer)
    self.network:set_activation_steepness_layer(step, layer)
    
    -- the other page may need an update now
    self:reload_neuron_info()
end

---
-- Buids the interface.
--
-- @param parent Parent window
-- @private
function ActivationConfigurator:build_gui(parent)
    -- dialog
    self.dialog = gtk.Dialog.new()
    self.dialog:set('title', _"Activation functions", 'transient-for', parent,
        'icon', NVIcon)
    self.dialog:add_button('gtk-close', gtk.RESPONSE_OK)
    self.vbox = self.dialog:get_content_area()
    
    -- Per neuron
    local g = {}
    self.per_neuron = g
    g.table = gtk.Grid.new(5, 2, false)
    g.table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    g.layer_label = gtk.Label.new(_"Layer")
    g.layer_label:set('xalign', 1, 'tooltip-text',
        _"Layer where the neuron is located")
    g.layer_spin = gtk.SpinButton.new_with_range(2, 5, 1)
    g.layer_spin:connect('changed', self.reload_neuron_info, self)
    
    g.neuron_label = gtk.Label.new(_"Neuron")
    g.neuron_label:set('xalign', 1, 'tooltip-text', _"Neuron to set the activation function")
    g.neuron_spin = gtk.SpinButton.new_with_range(1, 5, 1)
    g.neuron_spin:connect('changed', self.reload_neuron_info, self)
    
    g.widget = ParamWidget.new(activation_param)
    g.activation_label = g.widget.label
    g.activation_entry = g.widget.entry
    
    g.step_label = gtk.Label.new(_"Steepness")
    g.step_label:set('xalign', 1, 'tooltip-text', _"Activation function steepness")
    g.step_spin = gtk.SpinButton.new_with_range(0, 100, 0.1)
    g.step_spin:set('digits', 4)
    g.apply = gtk.Button.new_with_mnemonic(_"_Apply")
    g.apply:connect('clicked', self.set_per_neuron, self)
    g.apply:set('tooltip-text', _"Apply the changes")
    
    g.table:attach(g.layer_label, 0, 0, 1, 1)
    g.table:attach(g.layer_spin, 1, 0, 1, 1)
    g.table:attach(g.neuron_label, 0, 1, 1, 1)
    g.table:attach(g.neuron_spin, 1, 1, 1, 1)
    g.table:attach(g.activation_label, 0,2,1,1)
    g.table:attach(g.activation_entry,  1,2, 1, 1)
    g.table:attach(g.step_label,  0,3, 1, 1)
    g.table:attach(g.step_spin, 1,3, 1, 1)
    g.table:attach(g.apply, 0, 4, 2, 1)
    g.table:show_all()
    g.label = gtk.Label.new_with_mnemonic(_"Per _neuron")
    g.label:set('tooltip-text', _"Set the activation function for a single neuron")
    
    -- Per layer
    local g = {}
    self.per_layer = g
    g.table = gtk.Grid.new(4, 2, false)
    g.table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    g.layer_label = gtk.Label.new(_"Layer")
    g.layer_label:set('xalign', 1, 'tooltip-text',
        _"Layer to set the activation function")
    g.layer_spin = gtk.SpinButton.new_with_range(2, 5, 1)
    
    g.widget = ParamWidget.new(activation_param)
    g.activation_label = g.widget.label
    g.activation_entry = g.widget.entry
    
    g.step_label = gtk.Label.new(_"Steepness")
    g.step_label:set('xalign', 1, 'tooltip-text', _"Activation function steepness")
    g.step_spin = gtk.SpinButton.new_with_range(0, 100, 0.1)
    g.step_spin:set('digits', 4, 'value', 0.5)
    
    g.apply = gtk.Button.new_with_mnemonic(_"_Apply")
    g.apply:connect('clicked', self.set_per_layer, self)
    g.apply:set('tooltip-text', _"Apply the changes")
    
    g.table:attach(g.layer_label, 0,0,1,1)
    g.table:attach(g.layer_spin, 1, 0, 1, 1)
    g.table:attach(g.activation_label, 0, 1, 1, 1)
    g.table:attach(g.activation_entry, 1, 1, 1, 1)
    g.table:attach(g.step_label, 0, 2, 1, 1)
    g.table:attach(g.step_spin, 1, 2, 1, 1)
    g.table:attach(g.apply, 0, 3, 2, 1)
    g.table:show_all()
    g.label = gtk.Label.new_with_mnemonic(_"Per _layer")
    g.label:set('tooltip-text', _"Set the activation function for an entire layer")
    
    -- notebook
    self.notebook = gtk.Notebook.new()
    self.notebook:append_page(self.per_neuron.table, self.per_neuron.label)
    self.notebook:append_page(self.per_layer.table, self.per_layer.label)
    
    self.vbox:add(self.notebook)
    self.vbox:show_all()
end

---
-- Prepares the dialog to be used with a network.
--
-- @param network Network to be used
-- @private
function ActivationConfigurator:prepare()
    self.layer_array = self.network:get_layer_array()
    
    self.per_neuron.layer_spin:set_range(2, #self.layer_array)
    self.per_neuron.layer_spin:set('value', 2)
    self.per_neuron.neuron_spin:set('value', 1)
    
    self.per_layer.layer_spin:set_range(2, #self.layer_array)
    self.per_layer.layer_spin:set('value', 2)
    
    self:reload_neuron_info()
end

---
-- Runs the dialog.
--
-- @param network Network to be used
function ActivationConfigurator:run(network)
    self.network = network
    self:prepare()
    
    self.dialog:run()
    self.dialog:hide()
    
    self.network = nil
end

return ActivationConfigurator

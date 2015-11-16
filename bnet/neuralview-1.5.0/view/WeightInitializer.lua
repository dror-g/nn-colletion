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
-- Dialog to (re)initialize the weights of the connections of a network.
local WeightInitializer, WeightInitializerMT = nv_module('view.WeightInitializer')

local Utils = require('view.Utils')
local DataSelector = require('view.DataSelector')

---
-- Constructor.
--
-- @param ctrl Application controller, used to emit events 
-- @param Parent parent window
-- @return New instance of WeightInitializer 
function WeightInitializer.new(ctrl, parent)
    local self = {}
    setmetatable(self, WeightInitializerMT)
    
    self:build_gui(parent)
    self.ctrl = ctrl
    
    return self
end

-- range params
local min_range, max_range = -100, 100

---
-- Builds the interface.
--
-- @param parent Parent window
--
-- @private
function WeightInitializer:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('title', _"Initialize weights", 'transient-for', parent,
        'icon', NVIcon)
    self.dialog:add_button('gtk-close', gtk.RESPONSE_OK)
    
    self.table = gtk.Grid.new(2, 5, false)
    self.table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    -- randomize
    self.range_label = gtk.Label.new(_"Range")
    self.range_start = gtk.SpinButton.new_with_range(min_range, max_range, 0.1)
    self.range_start:set('digits', 4, 'value', -0.1)
    self.range_start:connect('changed', self.recalc_range, self)
    self.to_label = gtk.Label.new(_"to")
    self.range_end = gtk.SpinButton.new_with_range(min_range, max_range, 0.1)
    self.range_end:set('digits', 4, 'value', 0.1)
    self.range_end:connect('changed', self.recalc_range, self)
    
    self.randomize_button = Utils.new_button('gtk-new', _"Randomize")
    self.randomize_button:connect('clicked', self.randomize, self)
    self.randomize_button:set('tooltip-text', _"Set the connection weights to random values between a range")
    
    self.table:attach(self.range_label, 0, 0, 1, 1)
    self.table:attach(self.range_start, 1, 0, 1, 1)
    self.table:attach(self.to_label, 2, 0, 1, 1)
    self.table:attach(self.range_end, 3, 0, 1, 1)
    self.table:attach(self.randomize_button, 4, 0, 1, 1)
    
    -- Nguyen-Widrow
    self.data_selector = DataSelector.new()
    
    self.initialize_button = Utils.new_button('gtk-new', _"Nguyen-Widrow")
    self.initialize_button:connect('clicked', self.initialize, self)
    self.initialize_button:set('tooltip-text', _"Set the connection weights according to the Nguyen-Widrow algorithm")
    
    self.table:attach(self.data_selector.widget, 0, 1, 1, 1)
    self.table:attach(self.initialize_button, 4, 1, 1, 1)
    
    self.vbox = self.dialog:get_content_area()
    self.vbox:add(self.table)
    self.vbox:show_all()
end

---
-- Randomized the current network weights.
--
-- @private
function WeightInitializer:randomize()
    local lower = self.range_start:get('value')
    local upper = self.range_end:get('value')
    self.project.network:randomize_weights(lower, upper)
    self.project.weight_init = {
        ['type'] = 'randomize',
        ['lower'] = lower,
        ['upper'] = upper
    }
    
    self.ctrl:network_weights_changed()
end

---
-- Initialize the current network weights, using the Nguyen-Widrow algorithm.
--
-- @private
function WeightInitializer:initialize()
    local data = self.data_selector:get()
    local net = self.project.network
    
    self.project.weight_init = {
        ['type'] = 'nguyen-widrow'
    }
    
    net:reset_MSE()
    net:init_weights(data)
    
    self.ctrl:network_weights_changed()
end

---
-- Recalculates the range of each spin.
--
-- @private
function WeightInitializer:recalc_range()
    local lower = self.range_start:get('value')
    local upper = self.range_end:get('value')
    
    self.range_start:set_range(min_range, upper - 0.0001)
    self.range_end:set_range(lower + 0.0001, max_range)
end

---
-- Filters the data that can be used to the weight initialization.
--
-- @private
local function filter(data)
    return data:length() > 0
end

---
-- Runs the dialog.
--
-- @param project Project that contains the network to initialize connection weights 
function WeightInitializer:run(project)
    self.project = project
    self.data_selector:prepare(project.data, filter)
    
    local has_data = self.data_selector:get() ~= nil
    self.initialize_button:set('sensitive', has_data)
    
    self.dialog:run()
    self.dialog:hide()
    
    self.data_selector:clear()
    self.network = nil
end

return WeightInitializer

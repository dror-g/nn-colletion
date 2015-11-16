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
-- Dialog that allows the user to test the network with a data file.
local NetworkTester, NetworkTesterMT = nv_module('view.NetworkTester')

local DataSelector = require('view.DataSelector')
local Utils = require('view.Utils')

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of NetworkTester 
function NetworkTester.new(parent)
    local self = {}
    setmetatable(self, NetworkTesterMT)
    
    self:build_gui(parent)
    
    return self
end
---
-- Builds the interface.
--
-- @param parent Parent window
-- @private
function NetworkTester:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('transient-for', parent, 'title', _"Test network",
        'icon', NVIcon)
    self.dialog:add_button('gtk-close', gtk.RESPONSE_OK)
    self.vbox = self.dialog:get_content_area()
    
    self.table = gtk.Grid.new(4, 3)
    self.table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    self.data_label = gtk.Label.new_with_mnemonic(_"Test _data")
    self.data_label:set('xalign', 1)
    self.data_sel = DataSelector.new()
    self.data_label:set('mnemonic-widget', self.data_sel.widget,
        'tooltip-text', _"Test data to be used")
    
    self.data_test = Utils.new_button('gtk-execute', _"Test")
    self.data_test:connect('clicked', self.test, self)
    self.data_test:set('tooltip-text', _"Test the network")
    
    self.table:attach(self.data_label, 0, 0, 1, 1)
    self.table:attach(self.data_sel.widget, 1, 0, 1, 1)
    self.table:attach(self.data_test, 3, 0, 1, 1)
    
    self.mse_label = gtk.Label.new(_"Mean squared error")
    self.mse_label:set('xalign', 1, 'tooltip-text', _"Test result")
    self.mse_res = gtk.Label.new('-')
    self.mse_res:set('xalign', 0, 'selectable', true)
    
    self.table:attach(self.mse_label, 0, 1, 1, 1)
    self.table:attach(self.mse_res, 1, 1, 2, 1)
    
    self.bit_label = gtk.Label.new(_"Bit fail")
    self.bit_label:set('xalign', 1, 'tooltip-text', _"Test result")
    self.bit_res = gtk.Label.new('-')
    self.bit_res:set('xalign', 0, 'selectable', true)
    
    self.table:attach(self.bit_label, 0, 2, 1, 1)
    self.table:attach(self.bit_res, 1, 2, 2, 1)
    
    self.class_label = gtk.Label.new(_"Classification")
    self.class_label:set('xalign', 1, 'tooltip-text', _"Test result")
    self.class_res = gtk.Label.new('-')
    self.class_res:set('xalign', 0, 'selectable', true)
    
    self.table:attach(self.class_label, 0, 3, 1, 1)
    self.table:attach(self.class_res  , 1, 3, 2, 1)
    
    self.vbox:pack_start(self.table)
    self.vbox:show_all()
end

---
-- Prepares the dialog for tests.
function NetworkTester:prepare(project)
    self.project = project
    local data_array = project and project.data
    local has_data = data_array and #data_array > 0 or false
    self.data_sel:prepare(data_array)
    self.data_test:set('sensitive', has_data)
end

---
-- Returns the index of the higher element
--
-- @private
local function get_higher(tbl, first)
    local first = first or 1
    local max_val, max_idx = tbl[first], first
    
    for i = first, #tbl do
        local val = tbl[i]
        
        if val > max_val then
            max_val = val
            max_idx = i
        end
    end
    
    return max_idx - first + 1
end

---
-- Calculates the % of the data that is classified correctly (only suitable for
-- specific cases).
--
-- @private
local function calc_classification(net, data)
    local len     = data:length()
    local num_in  = data:num_input()
    local num_out = data:num_output()
    local n_corr  = 0
    
    -- Populate the model
    for i = 1, len do
        local row = data:get_row(i)
        local out = net:run(row)
    
        local h_data = get_higher(row, num_in + 1)
        local h_out  = get_higher(out)
        
        if h_data == h_out then
            n_corr = n_corr + 1
        end
    end
    
    return n_corr / data:length()
end

---
-- Tests the current network with the selected data.
--
-- @private
function NetworkTester:test()
    local data = self.data_sel:get()
    
    if data then
        local net = self.project.network
        net:reset_MSE()
        net:test_data(data)
        
        local mse      = net:get_MSE()
        local bit_fail = net:get_bit_fail()
        local class    = calc_classification(net, data)
        
        self.mse_res:set('label', string.format('%.6f', mse))
        self.bit_res:set('label', bit_fail)
        self.class_res:set('label', string.format('%.2f%%', class * 100))
    end
end

---
-- Runs the network tester.
--
-- @param project Project to use
function NetworkTester:run(project)
    self:prepare(project)
    
    self.dialog:run()
    self.dialog:hide()

    self:prepare()
end

return NetworkTester

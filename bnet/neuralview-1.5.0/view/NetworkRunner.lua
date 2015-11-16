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
-- Dialog that allows the user to execute the network.
local NetworkRunner, NetworkRunnerMT = nv_module('view.NetworkRunner')

local DataEditor = require('view.DataEditor')
setmetatable(NetworkRunner, {__index = DataEditor})

local Utils = require('view.Utils')

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of NetworkRunner 
function NetworkRunner.new(parent)
    local self = {}
    setmetatable(self, NetworkRunnerMT)
    DataEditor.new(parent, self)
    self.window:set('title', _"Network runner")
    
    return self
end

---
-- @private
function NetworkRunner:add_action_buttons(box)
    DataEditor.add_action_buttons(self, box)
    
    self.run_sel_button = Utils.new_button('gtk-execute', _"R_un")
    self.run_sel_button:connect('clicked', self.run_selected, self)
    self.run_sel_button:set('tooltip-text', _"Runs the network for the selected rows")
    
    self.run_all_button = Utils.new_button('gtk-execute', _"Run a_ll")
    self.run_all_button:connect('clicked', self.run_all, self)
    self.run_all_button:set('tooltip-text', _"Runs the network for all rows")
    
    box:pack_start(self.run_sel_button, false, true, 0)
    box:pack_start(self.run_all_button, false, true, 0)
end

---
-- @private
function NetworkRunner:add_response_buttons(box)
    self.close = gtk.Button.new_with_mnemonic(_"_Close")
    self.close:connect('clicked', self.response, {self, gtk.RESPONSE_CLOSE})
    
    box:pack_start(self.close, false, true, 0)
end

---
-- @private
function NetworkRunner:selection_changed()
    DataEditor.selection_changed(self)
    
    local is_selected = #self.selection:get_selected_rows() > 0
    self.run_sel_button:set('sensitive', is_selected)
end

---
-- Runs the network with the content of a row.
--
-- @param iter Iter that points to desired row
function NetworkRunner:run_row(iter)
    local model = self.model
    local ni = self.n_input
    local no = self.n_output
    local input = {}
    
    for i = 1, ni do
        input[i] = model:get(iter, i - 1)
    end
    
    local output = self.network:run(input)
    
    for i = 1, no do
        model:set(iter, i + ni - 1, output[i])
    end
end

---
--
-- @private
function NetworkRunner:run_selected()
    local rows = self.selection:get_selected_rows()
    
    for i, path in ipairs(rows) do
        self.model:get_iter_from_string(self.iter, path)
        self:run_row(self.iter)
    end
end

---
-- @private
function NetworkRunner:run_all()
    local model = self.model
    local valid = model:get_iter_first(self.iter)
    
    while valid do
        self:run_row(self.iter)
        valid = model:iter_next(self.iter)
    end
end

---
-- Prepares the network runner.
--
-- @private
function NetworkRunner:prepare(project, data)
    if project then
        self:clear_view()
        self:add_maps(project.maps)
        
        self.network = project.network
        self.n_input = self.network:get_num_input()
        self.n_output = self.network:get_num_output()
    
        self:create_model(self.n_input, self.n_output, data)
    else
        self.network = nil
        self:add_maps()
    end
end

---
-- Runs the network runner.
--
-- @param network Network to be used
-- @param data Initial data to be populated (optional)
function NetworkRunner:run(network, data)
    self:prepare(network, data)
    
    self.window:show()
    gtk.main()
    self.window:hide()
    
    self:prepare()
end

return NetworkRunner

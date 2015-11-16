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
-- Dialog (non-modal) that allows the user to view the connection weights of a
-- neural network.
local WeightDialog, WeightDialogMT = nv_module('view.WeightDialog')

local WeightViewer = require('view.WeightViewer')

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of WeightDialog 
function WeightDialog.new(parent)
    local self = {}
    setmetatable(self, WeightDialogMT)
    
    self:build_gui(parent)
    
    return self
end

---
-- Builds the interface.
--
-- @param parent Parent window
-- @private
function WeightDialog:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('title', _"View weights", 'transient-for', parent,
        'default-width', 250, 'default-height', 350, 'icon', NVIcon)
    self.close_button = self.dialog:add_button('gtk-close', gtk.RESPONSE_OK)
    self.dialog:connect('delete-event', self.close, self)
    self.close_button:connect('clicked', self.close, self)
    
    self.weight_viewer = WeightViewer.new()
    
    self.vbox = self.dialog:get_content_area()
    self.vbox:add(self.weight_viewer.vbox)
end

---
-- Prepares the interface for a new network.
--
-- @private
function WeightDialog:prepare(network)
    self.network = network
    local layer_array, bias_array, conn_array
    
    if network then
        conn_array = network:get_connection_array()
        layer_array = network:get_layer_array()
        bias_array = network:get_bias_array()
    end
    
    self.weight_viewer:prepare(layer_array, bias_array, conn_array)
end

---
-- Closes the dialog.
function WeightDialog:close()
    self:prepare()
    self.dialog:hide()
    self.running = false
    
    return true
end

---
-- Updates the interface if the project changed.
--
-- @param event Event that triggered this handler
-- @param project The current project
-- @slot
function WeightDialog:project_selected(event, project)
    if self.running then
        self:prepare(project and project.network)
    end
end

---
-- Runs the dialog.
--
-- @param network Network to show the weights

function WeightDialog:run(network)
    self.running = true
    self:prepare(network)
    self.dialog:show_all()
end

return WeightDialog

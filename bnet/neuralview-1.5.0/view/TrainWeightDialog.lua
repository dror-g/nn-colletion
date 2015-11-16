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
-- Widget that allows the user to view snapshots of the a neural network
-- weights during the training process.
local TrainWeightDialog, TrainWeightDialogMT = nv_module('view.TrainWeightDialog')

local WeightViewer = require('view.WeightViewer')
local Utils = require('view.Utils')

local SNAPSHOT_LIMIT = Config.limits.snapshots

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of TrainWeightDialog
function TrainWeightDialog.new(parent)
    local self = {}
    setmetatable(self, TrainWeightDialogMT)
    
    self:build_gui(parent)
    self:prepare()
    
    return self
end

local huge = 999999999

---
-- Builds the interface.
-- @private
function TrainWeightDialog:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('title', _"Weight snapshots", 'transient-for', parent,
        'default-width', 250, 'default-height', 350, 'icon', NVIcon)
    self.dialog:add_button("gtk-close", gtk.RESPONSE_OK)
    
    self.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 5)
    self.snap_label = gtk.Label.new(_"Snapshot")
    self.snap_label:set('xalign', 1)
    self.snap_spin = gtk.SpinButton.new_with_range(1, huge, 1)
    self.id = self.snap_spin:connect('value-changed', self.snap_changed, self)
    self.hbox:pack_start(self.snap_label, false, true, 0)
    self.hbox:pack_start(self.snap_spin, true, true, 0)
    
    self.weight_viewer = WeightViewer.new()
    self.weight_viewer.label_size_group:add_widget(self.snap_label)
    
    self.vbox = self.dialog:get_content_area()
    self.vbox:pack_start(self.hbox, false, true, 0)
    self.vbox:pack_start(self.weight_viewer.vbox, true, true, 0)
    self.vbox:show_all()
end

---
-- Prepares the dialog.
--
-- @param network Network to prepare the dialog
function TrainWeightDialog:prepare(network)
    self.snaps = {}
    
    if network then
        self.layer_array = network:get_layer_array()
        self.bias_array = network:get_bias_array()
    else
        self.layer_array = nil
        self.bias_array = nil
    end
end

---
-- Adds a weight snapshot.
function TrainWeightDialog:add_snapshot(network)
    if #self.snaps < SNAPSHOT_LIMIT then
        local conn = network:get_connection_array()
        table.insert(self.snaps, conn)
    end
end

---
-- @private
function TrainWeightDialog:snap_changed()
    local snap = self.snap_spin:get('value')
    local conn_array = self.snaps[snap]
    self.weight_viewer:prepare(self.layer_array, self.bias_array, conn_array)
end

---
-- Runs the dialog.
function TrainWeightDialog:run()
    if #self.snaps == 0 then
        Utils.show_info(_"There aren't any weight snapshot to show")
    else
        -- only one populate, please
        self.snap_spin:block(self.id)
        self.snap_spin:set_range(1, #self.snaps)
        self.snap_spin:unblock(self.id)
        
        self:snap_changed()
        
        self.dialog:run()
        self.dialog:hide()
    end
end

return TrainWeightDialog

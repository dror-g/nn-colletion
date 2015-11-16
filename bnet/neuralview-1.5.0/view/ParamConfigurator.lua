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
-- Dialog to configure the network training parameters.
local ParamConfigurator, ParamConfiguratorMT = nv_module('view.ParamConfigurator')

local FannNetwork = require('core.FannNetwork')
local ParamWidget = require('view.ParamWidget')
local Utils = require('view.Utils')

---
-- Constructor.
--
-- @param parent Parent window
function ParamConfigurator.new(parent)
    local self = {}
    setmetatable(self, ParamConfiguratorMT)
    
    self.algo_widgets = {}
    self:build_gui(parent)
    
    return self
end


---
-- Gets the widget table for an algorithm.
--
-- @param algo_id Algorithm to get the tables for
-- @private
function ParamConfigurator:get_widget_table(algo_id)
    if not self.algo_widgets[algo_id] then
        -- Construct the table, and cache it
        local widgets = {}
        
        local algo = FannNetwork.algorithms[algo_id]
        local gtk_tbl = gtk.Grid.new(#algo.params, 2)
        gtk_tbl:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
        
        for j, param in ipairs(algo.params) do
            local widget = ParamWidget.new(param)
            widgets[j] = widget
            gtk_tbl:attach(widget.label, 0, j+1, 1, 1)
            gtk_tbl:attach(widget.entry, 1, j+1, 1, 1)
        end
        
        self.algo_widgets[algo_id] = {['widgets'] = widgets, ['table'] = gtk_tbl}
    end
    
    return self.algo_widgets[algo_id]
end

---
-- Builds the interface.
--
-- @private
function ParamConfigurator:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.vbox = self.dialog:get_content_area()
    
    -- dialog
    self.dialog:add_buttons('gtk-cancel', gtk.RESPONCE_CANCEL, 'gtk-ok', gtk.RESPONSE_OK)
    self.dialog:set('title', _"Training parameters", 'transient-for', parent,
        'icon', NVIcon)

    -- algorithm selector
    self.cur_training = ParamWidget.new(FannNetwork.params.training_algorithm_option)
    self.cur_training.entry:connect('changed', self.load_helper, self)
    local label = self.cur_training.label:get('label')
    self.cur_training.label:set('label', '<b>' .. label .. '</b>', 'use-markup', true)
    
    self.algo_hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 5)
    self.algo_hbox:pack_start(self.cur_training.label, false, true, 0)
    self.algo_hbox:pack_start(self.cur_training.entry, true, true, 0)

    self.vbox:pack_start(self.algo_hbox, false, true, 2)
    self.vbox:pack_start(gtk.Separator.new(gtk.ORIENTATION_HORIZONTAL), false, true, 2)
    
    self.vbox:show_all()
end

---
-- Helper function to prevent recursive looping. Called when the self.algo_combo
-- changes.
--
-- @private
function ParamConfigurator:load_helper()
    self:clear()
    
    local algo_id = self.cur_training:get()
    
    if algo_id then
        local algo_widgets = self:get_widget_table(algo_id)
        
        -- Set the values
        for i, param in ipairs(FannNetwork.algorithms[algo_id].params) do
            local value = param.get(self.network)
            algo_widgets.widgets[i]:set(value)
        end
    
        self.cur_tbl = algo_widgets.table
        self.vbox:add(self.cur_tbl)
        self.vbox:show_all()
    end
end

---
-- Prepares the interface for a training algorithm (adjusts the parameters).
--
-- @param network Network to configure
-- @private
function ParamConfigurator:load_params()
    local algo_id = self.network:get_training_algorithm()
    self.cur_training:set(algo_id)
    self:load_helper()
end

---
-- Saves the parameters configured in the form to the network.
--
-- @param network Network where the parameters will be saved to
-- @private
function ParamConfigurator:save_params(network)
    local algo_id = self.cur_training:get()
    
    if algo_id then
        -- Save the training algorithm
        network:set_training_algorithm(algo_id)
        
        -- Set the values
        local algo_widgets = self:get_widget_table(algo_id)
    
        for i, param in ipairs(FannNetwork.algorithms[algo_id].params) do
            local value = algo_widgets.widgets[i]:get()
            param.set(network, value)
        end
    end
end

---
-- Clears the interface.
--
-- @private
function ParamConfigurator:clear(algo_id)
    if self.cur_tbl then
        self.vbox:remove(self.cur_tbl)
        self.cur_tbl = nil
    end
end

---
-- Runs the network configurator.
--
-- @param network Network to be configured
-- @return true if the network changed
function ParamConfigurator:run(network)
    self.network = network
    self:load_params(network)
    
    local res = self.dialog:run()
    self.dialog:hide()
    
    self:clear()
    self.network = nil
    
    if res == gtk.RESPONSE_OK then
        self:save_params(network)
        return true
    end
end

return ParamConfigurator

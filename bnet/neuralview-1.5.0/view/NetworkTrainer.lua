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
-- Widget that allows the user to define the layers of a neural network.
local NetworkTrainer, NetworkTrainerMT = nv_module('view.NetworkTrainer')

local DataSelector      = require('view.DataSelector')
local TrainWeightDialog = require('view.TrainWeightDialog')
local Utils             = require('view.Utils')

local MSE_LIMIT = Config.limits.mse
local BIT_LIMIT = Config.limits.bit

---
-- Constructor.
--
-- @param ctrl Application controller, used to emit events 
-- @param parent Parent window
-- @return New instance of NetworkTrainer 
function NetworkTrainer.new(ctrl, parent)
    local self = {}
    setmetatable(self, NetworkTrainerMT)
    
    self:build_gui(parent)
    self.timer = glib.Timer.new()
    self.timer:stop()
    self.ctrl = ctrl
    self.weight_dialog = TrainWeightDialog.new(self.dialog)
    self:clear_reports()
    
    return self
end

-- param bounds
local small, huge = 0, 999999999

-- respect the locale
local zero = string.format('%.6f', 0)

function create_labels(label, label2, tooltip)
    local lbl1 = gtk.Label.new(label)
    local lbl2 = gtk.Label.new(label2 or _"0")
    lbl1:set('xalign', 1, 'selectable', true, 'tooltip-text', tooltip)
    lbl2:set('xalign', 0, 'selectable', true)
    return lbl1, lbl2
end

---
-- Clears the stored report information (MSE, weights).
-- @private
function NetworkTrainer:clear_reports()
    self.mse_hist = {}
    self.bit_hist = {}
    self.weight_dialog:prepare(self.net)
end

---
-- @private
function NetworkTrainer:add_status_ui()
    local g = {}
    self.status = g

    g.frame = Utils.new_frame(_"Training status")
    g.table = gtk.Grid.new(5, 2, false)
    g.table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    g.epochs_label, g.epochs_value = create_labels(_"Epochs", nil, _"Number of epochs trained")
    g.time_label, g.time_value = create_labels(_"Time elapsed (s)", zero, _"Elapsed time")
    g.mse_label, g.mse_value = create_labels(_"Mean squared error", zero, _"Mean squared error")
    g.bit_label, g.bit_value = create_labels(_"Bit fail", nil, _"Bit fail")
    
    g.table:attach(g.epochs_label,  0, 0, 1, 1)
    g.table:attach(g.epochs_value,  1, 0, 1, 1)
    g.table:attach(g.time_label,    0, 1, 1, 1)
    g.table:attach(g.time_value,    1, 1, 1, 1)
    g.table:attach(g.mse_label,     0, 2, 1, 1)
    g.table:attach(g.mse_value,     1, 2, 1, 1)
    g.table:attach(g.bit_label,     0, 3, 1, 1)
    g.table:attach(g.bit_value,     1, 3, 1, 1)
    
    g.view_vbox = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 5)
    
    g.view_weights = Utils.new_button('gtk-zoom-in', _"_Weights")
    g.view_weights:set('tooltip-text', _"View snapshots of the network weights")
    
    g.view_mse = Utils.new_button('gtk-zoom-in', _"_MSE")
    g.view_mse:set('tooltip-text', _"View the plotting of the mean squared error changes")
    
    g.view_bit = Utils.new_button('gtk-zoom-in', _"_Bit")
    g.view_bit:set('tooltip-text', _"View the plotting of the bit fail changes")
    
    g.hbox = gtk.Box.new(gtk.ORIENTATIL_HORIZONTAL, 5)
    g.hbox:pack_start(g.view_weights, false, true)
    g.hbox:pack_start(g.view_mse, false, true)
    g.hbox:pack_start(g.view_bit, false, true)
    
    g.view_weights:connect('clicked', self.show_weight_dialog, self)
    g.view_mse:connect('clicked', self.show_mse_dialog, self)
    g.view_bit:connect('clicked', self.show_bit_dialog, self)
    
    g.view_vbox:pack_start(g.table, false, true, 0)
    g.view_vbox:pack_start(g.hbox, false, true, 0)
    g.frame:add(g.view_vbox)
    self.right_vbox:add(g.frame)
end

---
-- @private
function NetworkTrainer:show_weight_dialog()
    self.weight_dialog:run()
end

local title = _"Mean squared error history"

---
-- @private
function NetworkTrainer:create_plot_dialog()
    if not self.image_viewer then
        local ImageViewer = require('view.ImageViewer')
        self.image_viewer = ImageViewer.new(self.dialog)
        self.plot = require('core.Plot')        
    end
end

---
-- @private
function NetworkTrainer:show_mse_dialog()
    self:create_plot_dialog()
    
    if #self.mse_hist > 1 then
        local title = _"Training history"
        local img = self.plot.line(self.mse_hist, title, _"Snapshot",
            _"Mean squared error")
            
        if img then
            self.image_viewer:run(img, title)
        else
            Utils.show_info(_"Couldn't render the plotting")
        end
    else
        Utils.show_info(_"There aren't any data to show")
    end
end

---
-- @private
function NetworkTrainer:show_bit_dialog()
    self:create_plot_dialog()
    
    if #self.bit_hist > 1 then
        local title = _"Training history"
        local img = self.plot.line(self.bit_hist, title, _"Snapshot",
            _"Bit fail")
            
        if img then
            self.image_viewer:run(img, title)
        else
            Utils.show_info(_"Couldn't render the plotting")
        end
    else
        Utils.show_info(_"There aren't any data to show")
    end
end

---
-- @private
function NetworkTrainer:add_stop_conditions_ui()
    -- stop functions
    local g = {}
    self.cond = g
    g.frame = Utils.new_frame(_"Stop condition")
    g.vbox = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 5)
    
    g.mse_radio = gtk.RadioButton.new_with_mnemonic_from_widget(nil, 
        _"Mean squared error")
    g.mse_radio:set('tooltip-text', _"Use the mean squared error as stop condition")
    
    g.bit_radio = gtk.RadioButton.new_with_mnemonic_from_widget(g.mse_radio,
        _"Bit limit")
    g.bit_radio:set('tooltip-text', _"Use the bit fail as stop condition")
    
    g.vbox:pack_start(g.mse_radio, false, true, 0)
    g.vbox:pack_start(g.bit_radio, false, true, 0)
    g.frame:add(g.vbox)

    -- parameters
    local g = {}
    self.param = g
    g.frame = Utils.new_frame(_"Parameters")
    g.table = gtk.Grid.new(5, 2, false)
    g.table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    g.data_label = gtk.Label.new_with_mnemonic(_"Training _data")
    g.data_sel = DataSelector.new()
    g.data_label:set('xalign', 1, 'mnemonic-widget', g.data_sel.widget,
        'tooltip-text', _"Training data to be used")
    g.table:attach(g.data_label, 0, 0, 1, 1, of, 0)
    g.table:attach(g.data_sel.widget, 1, 0, 1, 1)
    
    g.error_label = gtk.Label.new_with_mnemonic(_"Desired _error")
    g.error_spin = gtk.SpinButton.new_with_range(small, huge, 0.001)
    g.error_spin:set('digits', 6, "value", 0.001)
    g.error_label:set('mnemonic-widget', g.error_spin, 'xalign', 1,
        'tooltip-text', _"The desired mean squared error / bit fail")
    g.table:attach(g.error_label, 0, 1, 1, 1)
    g.table:attach(g.error_spin, 1, 1, 1, 1)
    
    g.bit_fail_label = gtk.Label.new_with_mnemonic(_"_Bit fail limit")
    g.bit_fail_spin = gtk.SpinButton.new_with_range(small, huge, 0.001)
    g.bit_fail_spin:set('digits', 6, 'value', 0.035)
    g.bit_fail_label:set('mnemonic-widget', g.bit_fail_spin, 'xalign', 1,
        'tooltip-text', _"The acceptable bit error")
        
    g.table:attach(g.bit_fail_label, 0, 2, 1, 1)
    g.table:attach(g.bit_fail_spin, 1, 2, 1, 1)
    
    g.max_epochs_label = gtk.Label.new_with_mnemonic(_"_Max epochs")
    g.max_epochs_spin = gtk.SpinButton.new_with_range(1, huge, 100)
    g.max_epochs_spin:set('value', 1000)
    g.max_epochs_label:set('mnemonic-widget', g.max_epochs_spin, 'xalign', 1,
        'tooltip-text', _"The maximum number of epochs that the training can run")
    g.table:attach(g.max_epochs_label, 0, 3, 1, 1)
    g.table:attach(g.max_epochs_spin, 1, 3, 1, 1)
    
    g.rep_label = gtk.Label.new_with_mnemonic(_"_Log epochs")
    g.rep_spin = gtk.SpinButton.new_with_range(0, huge, 100)
    g.rep_spin:set('value', 0)
    g.rep_label:set('mnemonic-widget', g.rep_spin, 'xalign', 1,
        'tooltip-text', _"The interval between logs (0 disables the logs)")
    g.table:attach(g.rep_label, 0, 4, 1, 1)
    g.table:attach(g.rep_spin, 1, 4, 1, 1)
    
    g.frame:add(g.table)
    
    self.left_vbox:pack_start(self.cond.frame, false, true, 0)
    self.left_vbox:pack_start(self.param.frame, false, true, 0)
end

---
-- Builds the interface.
--
-- @param parent Parent window
-- @private
function NetworkTrainer:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('transient-for', parent, 'title', _"Training",
        'icon', NVIcon)
    self.close_btn = self.dialog:add_button('gtk-close', gtk.RESPONSE_OK)
    self.close_btn:connect('clicked', self.stop_training, self)
    
    self.vbox = self.dialog:get_content_area()
    self.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 10)
    self.left_vbox = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 5)
    self.right_vbox = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 5)
    
    -- stop conditions
    self:add_stop_conditions_ui()
    
    -- progress
    self.prog_box = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    self.progress = gtk.ProgressBar.new()
    
    self.start = Utils.new_button('gtk-execute', _"_Start")
    self.start:set('tooltip-text', _"Starts the training")
    self.start:connect('clicked', self.start_training, self)
    
    self.stop = gtk.Button.new_with_mnemonic('_Stop')
    self.stop:connect('clicked', self.stop_training, self)
    self.stop:set('no-show-all', true, 'tooltip-text', _"Stops the training")
    
    -- same cell, but only one is visible at the same time
    self.prog_box:pack_start(self.stop, false, true, 0)
    self.prog_box:pack_start(self.start, false, true, 0)
    self.prog_box:pack_start(self.progress, true, true, 0)
    
    -- status
    self:add_status_ui()
    
    self.hbox:pack_start(self.left_vbox, false, true, 0)
    self.hbox:pack_start(gtk.Separator.new(gtk.ORIENTATION_VERTICAL), false, false, 0)
    self.hbox:pack_start(self.right_vbox, true, true, 0)
    
    self.vbox:pack_start(self.hbox, true, true, 5)
    self.vbox:pack_start(gtk.Separator.new(gtk.ORIENTATION_HORIZONTAL), false, false, 0)
    self.vbox:pack_start(self.prog_box, false, true, 5)
    self.vbox:show_all()
end

---
-- Prepares the dialog.
--
-- @private
function NetworkTrainer:prepare(project)
    self.project = project
    
    if project then
        self.net = project.network
        local has_data = #self.project.data > 0
        self.start:set('sensitive', has_data)
        self.param.data_sel:prepare(self.project.data)
        self.net:set_callback(self.training_callback, self)
    else
        self.net = nil
    end
end

---
-- Clears the training status (interface only, doesn't changed the network)
function NetworkTrainer:clear()
    local g = self.status
    g.epochs_value:set('label', 0)
    g.bit_value:set('label', 0)
    g.mse_value:set('label', zero)
    g.time_value:set('label', zero)
    self.weight_dialog:prepare()
end

---
-- Estimates a good epochs_between_reports param, based on the size of the
-- training data and the number of connections in the network.
--
-- @param net Network to be used in the training
-- @param data Data to be used in the training
-- @return Report interval, an integer between 1 and 1000
-- @private
local function calculate_interval(net, data)
    local val = 10000
    local div = data:length() * net:get_total_connections()
    val = val / div
    if val < 1 then val = 1 elseif val > 1000 then val = 1000 end
    return math.ceil(val)
end

---
-- Training callback. Since the training occurs in the same thread as the
-- interface, we process the pending main loop events here.
function NetworkTrainer:training_callback(max_epochs, rep_epochs, target, cur_epoch)
    -- process pending events
    while gtk.events_pending() do
        gtk.main_iteration()
    end
    
    self.last_epoch = cur_epoch
    
    -- process the queued updates only once
    if self.need_update then
        self.progress:pulse()
        self:update_status(cur_epoch)
        self.need_update = false
    end
    
    -- collect information for reports?
    if self.rep_epochs and (cur_epoch > 1 or self.rep_epochs == 1) then
        self.weight_dialog:add_snapshot(self.net)
        
        if #self.mse_hist < MSE_LIMIT then
            table.insert(self.mse_hist, self.net:get_MSE() )
        end
        
        if #self.bit_hist < BIT_LIMIT then
            table.insert(self.bit_hist, self.net:get_bit_fail() )
        end
    end
    
    -- check if the user requested to stop the training
    return self.running and 0 or -1
end

---
-- Starts the training.
--
-- @private
function NetworkTrainer:start_training()
    local stop_func = fann.STOPFUNC_MSE
    local p = self.param
    
    local bit_fail = p.bit_fail_spin:get('value')
    self.net:set_bit_fail_limit(bit_fail)
    
    if self.cond.bit_radio:get('active') then
        stop_func = fann.STOPFUNC_BIT
    end
    
    self.net:set_train_stop_function(stop_func)
    local data = p.data_sel:get()
    local max_epochs = p.max_epochs_spin:get('value')
    local desired_error = p.error_spin:get('value')
    
    -- prepare
    self:clear_reports()
    self.start:hide()
    self.stop:show()
    glib.timeout_add(glib.PRIORITY_DEFAULT, 150, self.queue_update, self)
    self.last_epoch = 0
    
    -- train
    self.running = true
    self.timer:start()
    
    -- the user can configure an interval for the reports, or let the program
    -- calculate one
    local rep_epochs, interval = self.param.rep_spin:get('value')
    self.rep_epochs = rep_epochs > 0 and rep_epochs 
    
    if self.rep_epochs then
        interval = self.rep_epochs
        self.weight_dialog:add_snapshot(self.net)
    else
        interval = calculate_interval(self.net, data)
    end
    
    -- save the current params to let other components to get the last training 
    -- params too
    self.project.training_params = {
        ['stop_func']       = stop_func,
        ['desired_error']   = desired_error,
        ['bit_fail']        = bit_fail,
        ['rep_epochs']      = rep_epochs,
        ['interval']        = interval,
        ['max_epochs']      = max_epochs,
    }
    
    self.net:reset_MSE()
    self.net:train_on_data(data, max_epochs, interval, desired_error)

    -- training finished
    self.stop:hide()
    self.start:show()
    self.running = false
    self.timer:stop()
    self.progress:set('fraction', 0)
    self:update_status(self.last_epoch)
    self.ctrl:network_weights_changed()
end

---
-- Stops the training (queue it, the training only stops on the next iteration).
--
-- @private
function NetworkTrainer:stop_training()
    self.running = false
end

---
-- Queues a GUI update. Used to avoid the useless concentration of events in
-- the same callback.
--
-- @private
function NetworkTrainer:queue_update()
    if self.running then
        self.need_update = true
        return true
    else
        return false
    end
end

---
-- Updates the training status, based on parameters of the current network.
--
-- @param epochs Current epoch (optional)
function NetworkTrainer:update_status(epoch)
    local mse = self.net:get_MSE()
    local bit = self.net:get_bit_fail()
    local elapsed = self.timer:elapsed()
    
    -- status group
    local g = self.status
    if epoch then g.epochs_value:set('label', epoch) end
    g.bit_value:set('label', bit) 
    g.mse_value:set('label', string.format('%.6f', mse)) 
    g.time_value:set('label', string.format('%.6f', elapsed))
    
    -- write the info to the project, to allow other components to get the
    -- current status too
    self.project.training_status = {
        ['epoch'] = epoch,
        ['mse'] = mse,
        ['bit'] = bit,
        ['elapsed'] = elapsed,
    }
end

---
-- Runs the dialog.
--
-- @param project Project to use the network and training data
function NetworkTrainer:run(project)
    self:prepare(project)
    
    self.dialog:run()
    self.dialog:hide()
    
    self:prepare()
end

return NetworkTrainer

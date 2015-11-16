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
-- Dialog to scale training / test datas.
local ScaleDialog, ScaleDialogMT = nv_module('view.ScaleDialog')

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of ScaleDialog 
function ScaleDialog.new(parent)
    local self = {}
    setmetatable(self, ScaleDialogMT)
    
    self:build_gui(parent)
    
    return self
end

-- range params
local min_range, max_range = -100, 100

local SCALE_INPUT, SCALE_OUTPUT, SCALE_ALL = 1, 2, 3

---
-- Builds the interface.
--
-- @private
function ScaleDialog:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('transient-for', parent, 'title', _"Scale data",
        'icon', NVIcon)
    self.dialog:add_buttons('gtk-close', gtk.RESPONSE_OK)
    
    self.table = gtk.Grid.new(3, 3)
    self.table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    self.min_label = gtk.Label.new(_"Min")
    self.min_spin = gtk.SpinButton.new_with_range(min_range, max_range, 0.1)
    self.min_spin:set('value', 0, 'digits', 4)
    self.min_spin:connect('changed', self.recalc_range, self)
    
    self.max_label = gtk.Label.new(_"Max")
    self.max_spin = gtk.SpinButton.new_with_range(min_range, max_range, 0.1)
    self.max_spin:set('value', 1, 'digits', 4)
    self.max_spin:connect('changed', self.recalc_range, self)
    
    self.scale_input_button = gtk.Button.new_with_mnemonic(_"Scale _input")
    self.scale_input_button:connect('clicked', self.scale, {self, SCALE_INPUT})
    self.scale_output_button = gtk.Button.new_with_mnemonic(_"Scale _output")
    self.scale_output_button:connect('clicked', self.scale,{self, SCALE_OUTPUT})
    self.scale_all_button = gtk.Button.new_with_mnemonic(_"Scale _all")
    self.scale_all_button:connect('clicked', self.scale, {self, SCALE_ALL})
    
    -- Pack the range
    self.table:attach(self.min_label, 0, 0, 1, 1)
    self.table:attach(self.min_spin, 1, 0, 1, 1)
    
    self.table:attach(self.max_label, 0, 1, 1, 1)
    self.table:attach(self.max_spin, 1, 1, 1, 1)
    
    -- Pack the buttons
    self.table:attach(self.scale_input_button, 2, 0, 1, 1)   
    self.table:attach(self.scale_output_button, 2, 1, 1, 1) 
    self.table:attach(self.scale_all_button, 2, 2, 1, 1) 
        
    self.vbox = self.dialog:get_content_area()
    self.vbox:add(self.table)
    self.vbox:show_all()
end

---
-- Recalculates the range of each spin
--
-- @private
function ScaleDialog:recalc_range()
    local lower = self.min_spin:get('value')
    local upper = self.max_spin:get('value')
    
    self.min_spin:set_range(min_range, upper - 0.0001)
    self.max_spin:set_range(lower + 0.0001, max_range)
end

---
-- Scales the data.
--
-- @private
function ScaleDialog:scale()
    local self, stype = unpack(self)
    
    local rmin = self.min_spin:get('value')
    local rmax = self.max_spin:get('value')
    
    if stype == SCALE_INPUT then
        self.data:scale_input(rmin, rmax)
    elseif stype == SCALE_OUTPUT then
        self.data:scale_output(rmin, rmax)
    else
        self.data:scale(rmin, rmax)
    end
    
    self.changed = true
end

---
-- Runs the dialog.
--
-- @param data Data to be scaled
-- @return true if the data was scaled, false otherwise
function ScaleDialog:run(data)
    self.changed = false
    self.data = data
    
    local res = self.dialog:run()
    self.dialog:hide()
    
    self.data = nil
    return self.changed
end

return ScaleDialog

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
-- Handles the creation of widgets to allow the user to change network parameters.
-- @see core.NetworkParam
local ParamWidget, ParamWidgetMT = nv_module('view.ParamWidget')

local NumberEntry = {}
local NumberEntryMT = {__index = NumberEntry}

---
-- Constructor.
--
-- @param param NetworkParam to create a widget for
-- @return New instance of NumberEntry
-- @private
function NumberEntry.new(param)
    local self = {}
    setmetatable(self, NumberEntryMT)
    
    self.entry = gtk.SpinButton.new_with_range(param.min, param.max, 0.1)
    self.entry:set('numeric', true, 'digits', 4)
    self.label = gtk.Label.new(param.name)
    self.label:set('xalign', 1, 'mnemonic-widget', self.entry,
        'tooltip-text', param.tooltip)
    
    return self
end

---
-- Gets the value from the entry.
--
-- @return Value from the entry
function NumberEntry:get()
    return self.entry:get('value')
end

---
-- Sets the value of the entry.
--
-- @param value New value of the entry
function NumberEntry:set(value)
    self.entry:set('value', value)
end

local OptionEntry = {}
local OptionEntryMT = {__index = OptionEntry}

---
-- Creates a TreeModel for the parameter.
--
-- @private
function OptionEntry:create_model(param)
    local model = gtk.ListStore.new('gchararray', 'gint')
    local opt = param.options
    
    for i, value in ipairs(opt.values) do
        self.model_index[value] = i - 1
        model:append(self.iter)
        model:seto(self.iter, opt.names[i], value)
    end
    
    return model
end

---
-- Constructor.
--
-- @param param NetworkParam to create a widget for
-- @return New instance of OptionEntry
-- @private
function OptionEntry.new(param)
    local self = {}
    setmetatable(self, OptionEntryMT)
    
    self.model_index = {}
    self.iter = gtk.TreeIter.new()
    self.model = self:create_model(param)
    self.entry = gtk.ComboBox.new_with_model(self.model)
    
    self.renderer = gtk.CellRendererText.new()
    self.entry:pack_start(self.renderer, false)
    self.entry:add_attribute(self.renderer, 'text', 0)
    self.entry:set('active', 0)
    
    self.label = gtk.Label.new(param.name)
    self.label:set('xalign', 1, 'mnemonic-widget', self.entry,
        'tooltip-text', param.tooltip)
    
    return self
end

---
-- Gets the value from the entry.
--
-- @return Value from the entry
function OptionEntry:get()
    if self.entry:get_active_iter(self.iter) then
        return self.model:get(self.iter, 1) 
    end
end

---
-- Sets the value of the entry.
--
-- @param value New value of the entry
function OptionEntry:set(value)
    self.entry:set('active', self.model_index[value])
end

local entry = {
    number = NumberEntry,
    option = OptionEntry,
}

---
-- Factory to create entries for params.
--
-- @param param Parameter to construct a entry for
-- @return New ParamWidget instance.
-- the entry widget.
function ParamWidget.new(param)
    return entry[param.type].new(param)
end

return ParamWidget

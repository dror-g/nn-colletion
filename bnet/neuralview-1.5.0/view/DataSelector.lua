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
-- Widget that allows the user to select a data from a project.
-- If the data array change, prepare() must be called.
local DataSelector, DataSelectorMT = nv_module('view.DataSelector')

---
-- Constructor. The real GTK+ widget is the field 'widget'.
--
-- @return New instance of DataSelector
function DataSelector.new()
    local self = {}
    setmetatable(self, DataSelectorMT)
    
    self.iter = gtk.TreeIter.new()
    self:build_gui()
    
    return self
end

local function _filter() return true end

---
-- Populates the model with the data name and data index in the array.
--
-- @private
function DataSelector:populate_model()
    local filter = self.filter or _filter
    
    self.widget:set('model', nil)
    self.model:clear()
    
    local valid_id
    
    if self.data_array then
        for i, data in ipairs(self.data_array) do
            local res = filter(data.obj)
            self.model:append(self.iter)
            self.model:seto(self.iter, data.desc, res, i)
            if res and (not valid_id) then valid_id = i - 1 end
        end
    end
    
    self.widget:set('model', self.model)
    -- select the first valid data
    if valid_id then self.widget:set('active', valid_id) end
end

---
-- Builds the interface.
--
-- @private
function DataSelector:build_gui()
    self.model = gtk.ListStore.new('gchararray', 'gboolean', 'gint')
    self.widget = gtk.ComboBox.new_with_model(self.model)
    self.renderer = gtk.CellRendererText.new()
    self.widget:pack_start(self.renderer, false, false, 0)
    self.widget:add_attribute(self.renderer, 'text', 0)
    self.widget:add_attribute(self.renderer, 'sensitive', 1)
end

---
-- Gets the selected data.
--
-- @return The selected fann.Data 
function DataSelector:get()
    if self.widget:get_active_iter(self.iter) then
        local index = self.model:get(self.iter, 2)
        return self.data_array[index].obj
    end
end

---
-- Prepares the DataSelector for a new data array.
--
-- @param data_array Data array to use
-- @param filter Filter function that takes a fann.Data and return true or false, to
-- accept or reject a fann.Data (optional).
function DataSelector:prepare(data_array, filter)
    self.data_array = data_array
    self.filter = filter
    self:populate_model()
end

---
-- Clears the DataSelector, also releasing references to the data.
function DataSelector:clear()
    self.data_array = nil
    self.filter = nil
    self:populate_model()
end

return DataSelector


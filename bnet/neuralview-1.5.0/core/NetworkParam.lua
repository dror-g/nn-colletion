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
-- Encapsulates network parameters.
local NetworkParam, NetworkParamMT = nv_module('core.NetworkParam')

---
-- @name NumberParam
-- @class table
-- @description Representation of a training parameter
-- @field type Type of the parameter ("number")
-- @field name The (human-readable) name of the parameter
-- @field tooltip Description of the parameter
-- @field get The getter function (acts on a fann.Net object)
-- @field set The setter function (acts on a fann.Net object)
-- @field min Lower bound of the param value 
-- @field max Upper bound of the param value

---
-- @name OptionParam
-- @class table
-- @description Representation of a training parameter
-- @field type Type of the parameter ("option")
-- @field name The (human-readable) name of the parameter
-- @field tooltip Description of the parameter
-- @field get The getter function (acts on a fann.Net object)
-- @field set The setter function (acts on a fann.Net object)
-- @field values Table with {name, value} for the valid options

---
-- @name ReadOnlyParam
-- @class table
-- @description Representation of a network read-only parameter
-- @field type Type of the parameter ("readonly")
-- @field name The (human-readable) name of the parameter
-- @field tooltip Description of the parameter
-- @field get The getter function (acts on a fann.Net object)

---
-- Creates a new NumberParam.
--
-- @param name Human-readable name of the parameter
-- @param tooltip Description of the parameter
-- @param get The getter function
-- @param set The setter function
-- @param min Lower bound of the param value 
-- @param max Upper bound of the param value
-- @return New NumberParam
function NetworkParam.new_number(name, tooltip, get, set, min, max)
    local self = {}
    
    self.type = 'number'
    self.name = name
    self.tooltip = tooltip
    self.get = get
    self.set = set
    self.min = min
    self.max = max
    
    return self
end

---
-- Creates a new OptionParam.
--
-- @param name Human-readable name of the parameter
-- @param tooltip Description of the parameter
-- @param get The getter function
-- @param set The setter function
-- @param options A (shared, will not be copied) table in the form { {names}, {values} } with
-- the possible options
-- @return New OptionParam
function NetworkParam.new_option(name, tooltip, get, set, options)
    local self = {}
    
    self.type = 'option'
    self.name = name
    self.tooltip = tooltip
    self.get = get
    self.set = set
    self.options = options
    
    return self
end

---
-- Creates a new ReadOnlyParam.
--
-- @param name Human-readable name of the parameter
-- @param tooltip Description of the parameter
-- @param get The getter function
-- @return New ReadOnlyParam
function NetworkParam.new_readonly(name, tooltip, get)
    local self = {}
    
    self.type = 'readonly'
    self.name = name
    self.tooltip = tooltip
    self.get = get
    
    return self
end

return NetworkParam

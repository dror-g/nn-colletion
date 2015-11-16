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
-- Visualization map.
local Map, MapMT = nv_module('core.Map')

local Utils = require('core.Utils')

local floor = math.floor
local ti = table.insert

---
-- Constructor.
--
-- @return New Map instance
function Map.new()
    local self = {}
    setmetatable(self, MapMT)
    
    self.name = _"New map"
    self.values = {}
    self.labels = {}
    self.cols = {}
    
    return self
end

---
-- Loads a map from a pre-built table.
--
-- @param tbl Pre-build table
function Map.load(tbl)
    setmetatable(tbl, MapMT)
    tbl:sort()
    
    return tbl
end

---
-- Serializes the map to a Lua table.
--
-- @return The serialized map
function Map:serialize()
    local plabels = {}
    for i, label in ipairs(self.labels) do
        table.insert(plabels, Utils.protect_string(label))
    end
    
    local values = string.format( '{%s}', table.concat(self.values, ', ') )
    local labels = string.format( '{%s}', table.concat(plabels, ', '))
    local cols   = string.format( '{%s}', table.concat(self.cols, ', ') )
    
    local tmp = string.format( '{["name"] = %s, ["values"] = %s, ["labels"] = %s, ["cols"] = %s}', 
        Utils.protect_string(self.name),
        values,
        labels,
        cols
    )   
    
    return tmp
end

---
-- Adds a pair to the map values.
--
-- @param value Value of the pair
-- @param label Label of the pair
function Map:add(value, label)
    ti(self.values, value)
    ti(self.labels, label)
end

---
-- Sorts the map.
function Map:sort()
    local tbl, vals, lbls  = {}, self.values, self.labels
    
    for i, value in ipairs(vals) do
        ti(tbl, {value, lbls[i]})
    end
    
    table.sort(tbl, function(a,b) return a[1] < b[1] end)
    
    for i, pair in ipairs(tbl) do
        vals[i] = pair[1]
        lbls[i] = pair[2]
    end
end

---
-- Gets the label relative to the specified value.
--
-- @param value Value to be searched
-- @param label Label referenced by the specified value
function Map:get_label(value)
    -- modified binary search
    local vals = self.values
    local i1, i2 = 1, #vals
    
    while i1 < i2 do
        local a = floor( (i1 + i2) / 2 )
        local v = vals[a]
        
        if v < value then
            i1 = a + 1
        elseif v >= value then
            i2 = a
        end
    end
    
    return self.labels[i1]
end

---
-- Runs a functions for every value pair in the map.
--
-- @param f Callback function, in the form function f(value, label)
function Map:foreach(f)
    for i, value in ipairs(self.values) do
        f(value, self.labels[i])
    end
end

return Map

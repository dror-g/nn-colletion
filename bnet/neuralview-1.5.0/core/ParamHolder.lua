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
-- Stores and restores network parameters and activation functions.
local ParamHolder, ParamHolderMT = nv_module('core.ParamHolder')

---
-- Constructor.
--
-- @return New instance of ParamHolder 
function ParamHolder.new()
    local self = {}
    setmetatable(self, ParamHolderMT)
    
    return self
end

---
-- Stores the parameters and activation functions of a network.
--
-- @param net Network to get the parameters
-- @param params Map with the parameters to be getted (the readonly ones are
-- ignored)
function ParamHolder:store(net, params)
    local values = {}
    
    -- parameters
    for name, param in pairs(params) do
        if param.type ~= 'readonly' then
            values[name] = param.get(net)
        end
    end
    
    self.values = values
    
    -- activation functions
    local functions = {}
    local layer_array = net:get_layer_array()
    
    for layer = 2, #layer_array do
        local neurons = layer_array[layer]
        local tbl = {}
        
        for n = 1, neurons do
            local activation = net:get_activation_function(layer, n)
            local steepness  = net:get_activation_steepness(layer, n)
            tbl[n] = {activation, steepness}
        end
        
        functions[layer] =  tbl
    end
    
    self.functions = functions
end

---
-- Restores / sets the parameters and activation functions of a network.
--
-- @param net Network to set the parameters
-- @param params Map with the parameters to be setted (the redonly ones are
-- ignored)
function ParamHolder:restore(net, params)
    local values = self.values
    
    for name, param in pairs(params) do
        if param.type ~= 'readonly' then
            param.set(net, values[name])
        end
    end
    
    local functions = self.functions 
    local layer_array = net:get_layer_array()
    
    -- the number of layers and neurons could been changed, so this is just a
    -- guess
    
    for layer = 2, #layer_array do
        local tbl = self.functions[layer]
        if not tbl then break end
        
        local neurons = layer_array[layer]
        
        for n = 1, neurons do
            if tbl[n] then
                local act_func = tbl[n][1]
                local act_step = tbl[n][2]
                
                net:set_activation_function(act_func, layer, n)
                net:set_activation_steepness(act_step, layer, n)
            else
                break
            end
        end
    end
end

return ParamHolder

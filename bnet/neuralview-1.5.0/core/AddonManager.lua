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
-- Class that manages the complements ("add-ons").
local AddonManager, AddonManagerMT = nv_module('core.AddonManager')

---
-- Constructor.
--
-- @param ctrl Application controller to be used
-- @return New instance of AddonManager 
function AddonManager.new(ctrl)
    local self = {}
    setmetatable(self, AddonManagerMT)
    
    -- loaded addons, indexed by an unique integer
    self.loaded = {}
    self.info = {}
    self.ctrl = ctrl
    
    return self
end

local FOLDER = 'addons/'

---
-- Reads the addon List, loads the addons and populates the self.loaded list.
--
-- @returns Table with the information of each addon
function AddonManager:load_addons()
    local List = require(FOLDER .. 'List')
    local ctrl = self.ctrl
    
    for i, name in ipairs(List) do
        local res, out1 = pcall(require, FOLDER .. name)
        if type(out1) ~= 'table' or type(out1.load) ~= 'function' then
            res = false
            out1 = "The '" .. name .. "' add-on must return a table with the method 'load'"
        end
        
        if res then
            res, out2 = pcall(out1.load, ctrl)
        else
            io.stderr:write(out1, '\n')
            return
        end
        
        if res then
            table.insert(self.loaded, out1)
            table.insert(self.info, out1.info)
        else
            io.stderr:write(out2, '\n')
            return
        end
    end
end

---
-- Unloads all addons.
function AddonManager:unload_addons()
    for i, addon in ipairs(self.loaded) do
        addon.unload()
    end
end

---
-- Returns the info table.
--
-- @return Addons info table
function AddonManager:get_info()
    return self.info
end

return AddonManager

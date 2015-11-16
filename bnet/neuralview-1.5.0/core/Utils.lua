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
-- Utilities that aren't related to the user interface.
local Utils, UtilsMT = nv_module('core.Utils')

---
-- Performs a shallow copy of a table fields.
--
-- @param source The source table
-- @param dest The destination table
function Utils.shallow_copy(source, dest)
    for i, j in pairs(source) do
        dest[i] = j
    end
end

---
-- Transforms a string into a version that can be serialized and then loaded
-- back.
--
-- @param str String to be 'protected'
-- @return 'Protected' string
function Utils.protect_string(str)
    return string.format('%q', str)
end

return Utils

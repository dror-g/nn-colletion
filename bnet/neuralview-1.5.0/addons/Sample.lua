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

local Sample = {}

local Utils = require('view.Utils')

---
-- Information about the addon.
Sample.info = {
    name = _"Sample addon",
    description = _"Sample description.\nMay have multiple lines.",
    authors = _"Lucas Hermann Negri",
    version = '0.1.0',
}

---
-- Function that will be called when loading the addon.
-- All addons are loaded only one time, when the application starts.
--
-- @param ctrl Controller of the application
function Sample.load(ctrl)
    print(_"Loading sample")
    
    -- add a button to the main menu
    local button = Utils.new_tool_button('gtk-apply', _"Sample", _"Sample tooltip")
    
    button:connect('clicked', function()
        Utils.show_info(_"Sample clicked!")
    end)
    
    ctrl.menu:add_addon_button(button, false)
end

---
-- All addons are unloaded only one time, when the application ends.
function Sample.unload()
    print(_"Unloading sample")
end

return Sample

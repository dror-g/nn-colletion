#! /usr/bin/env lua5.1

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
    
    Copyright (c) 2009 - 2013 Lucas Hermann Negri
--]]

---
-- Main application.

-- ** Global definitions **

require('Globals')

-- ** Main **

local MainController = require('core.MainController')

local MainApp = {}
local MainAppMT = {__index = MainApp}

---
-- Constructor.
function MainApp.new()
    local self = {}
    setmetatable(self, MainAppMT)
    
    self.controller = MainController.new()
    
    return self
end

---
-- Runs the application.
function MainApp:run()
    self.controller:run()
end

-- Main

local app = MainApp.new()
app:run()

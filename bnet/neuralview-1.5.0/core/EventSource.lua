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
-- Holds a set of callbacks, that are associated with events, and provides a
-- way to calling then.
-- The order that the callbacks are called is undefined.
local EventSource, EventSourceMT = nv_module('core.EventSource')

---
-- Constructor.
--
-- @return New EventSource instance
function EventSource.new()
    local self = {}
    setmetatable(self, EventSourceMT)
    
    self.listeners = {}
    
    return self
end

---
-- Adds a callback to the set.
--
-- @param event Event to listen
-- @param callback Callback to be called when the event occurs
-- @param arg Value to be passed as first argument of the callback
-- (if nil, it isn't passed)
function EventSource:add(event, callback, arg)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    
    self.listeners[event][callback] = arg or false
end

---
-- Removes a callback from the set.
--
-- @param event Event associated with the callback
-- @param callback Registered callback to be removed
function EventSource:remove(event, callback)
    local event = self.listeners[event]
    if event then event[callback] = nil end
end

---
-- Sends an event to all registered callbacks.
--
-- @param event Event to send
-- @param ... Extra arguments to be passed (after the :add argument).
function EventSource:send(event, ...)
    local listeners = self.listeners[event]
    if not listeners then return end
    
    local resp = {}
    
    for callback, object in pairs(listeners) do
        if object then
            callback(object, event, ...)
        else
            callback(event, ...)
        end
    end
end

return EventSource

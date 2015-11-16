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
-- Widget to define a description for the project.
local ProjectDescription, ProjectDescriptionMT = nv_module('view.ProjectDescription')

---
-- Constructor.
--
-- @return New instance of ProjectDescription
function ProjectDescription.new()
    local self = {}
    setmetatable(self, ProjectDescriptionMT)
    
    self:build_gui()
    
    return self
end

---
-- Builds the interface.
--
-- @private
function ProjectDescription:build_gui()
    self.scroll = gtk.ScrolledWindow.new()
    self.scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC,
        'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.buffer = gtk.TextBuffer.new()
    self.view = gtk.TextView.new_with_buffer(self.buffer)
    self.scroll:add(self.view)
end

---
-- Sets the description text.
--
-- @param text New description text
function ProjectDescription:set_description(text)
    self.buffer:set('text', text)
end

---
-- Gets the description text.
--
-- @return Description text
function ProjectDescription:get_description()
    return self.buffer:get('text')
end

---
-- Updates the interface if the project changed.
--
-- @param event Event that triggered this handler
-- @param project The current project
-- @slot
function ProjectDescription:project_selected(event, project)
    local network_exists = project ~= nil
    local text = network_exists and project.description
        
    self.buffer:set('text', text or '')
    self.scroll:set('sensitive', network_exists)
end

---
-- Copies the description to the project.
--
-- @param event Event that triggered this handler
-- @param project The project to be filled
-- @slot
function ProjectDescription:project_will_save(event, project)
    project.description = self.buffer:get('text')
end

return ProjectDescription

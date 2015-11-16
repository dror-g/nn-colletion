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
-- Panel that shows informations about a project.
--
-- @see core.Project
-- @see core.TrainingAlgorithm
local ProjectInfo, ProjectInfoMT = nv_module('view.ProjectInfo')

local FannNetwork = require('core.FannNetwork')
---
-- Constructor.
--
-- @return New ProjectInfo instance
function ProjectInfo.new()
    local self = {}
    setmetatable(self, ProjectInfoMT)
    
    self:build_gui()
    
    return self
end


---
-- Shows a parameter in the list.
--
-- @param param The parameter to show
-- @private
function ProjectInfo:add_param(param)
    self.n_params = self.n_params + 1
    local params = self.params
    local tbl = params[self.n_params]
    
    -- Do we need to create a new table row?
    if not tbl then
        -- create a new row
        tbl = {}
        table.insert(params, tbl)
        tbl.label = gtk.Label.new('')
        tbl.label:set('use-markup', true, 'xalign', 1, 'selectable', true)
        tbl.content = gtk.Label.new('')
        tbl.content:set('xalign', 0, 'selectable', true)
        tbl.label:set('mnemonic-widget', tbl.content)
        local tam = #params
        
        self.n_max_params = tam
        self.table:attach(tbl.label, 1, tam-1, 1, 1)
        self.table:attach(tbl.content, 2, tam-1, 2, 1)
    end
    
    -- update the row values
    tbl.label:set('label', '<b>' .. param.name .. '</b>', 'tooltip-text',
        param.tooltip)
        
    local value = param.get( self.project.network ) or _"None"
    if type(value) == 'number' then value = string.format('%.4f', value) end
    tbl.content:set('label', value)
    
    -- show the row
    tbl.label:show()
    tbl.content:show()
end

---
-- Clears the parameter list.
-- @private
function ProjectInfo:clear_params()
    -- Keep the labels on the cache
    self.n_params = 0
    self.table:hide()
end

---
-- Buils the interface.
-- @private
function ProjectInfo:build_gui()
    self.table = gtk.Grid.new(10, 2, true)
    self.table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    self.scroll = gtk.ScrolledWindow.new()
    self.scroll:add(self.table)
    self.scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC,
        'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.params = {} 
    self.n_max_params = 0
    self:network_changed()
end

---
-- Updates the interface, adding the parameters corresponding to the current
-- network.
-- @private
function ProjectInfo:update_gui()
    local ftype = self.project.type
    local algo = self.project.network:get_training_algorithm()
    
    -- Add the general params
    for i, param in ipairs(FannNetwork.general_params) do
        self:add_param(param)
    end
    
    for i, param in ipairs(FannNetwork.algorithms[algo].params) do
        self:add_param(param)
    end
    
    self.table:show()
end

---
-- Updates the interface, based on the current project.
--
-- @param event Event that triggered this handler
-- @param project Current project   
-- @slot
function ProjectInfo:network_changed(event, project)
    self:clear_params()
    self.project = project
    
    if project and project.network then
        self:update_gui()
    end
end

return ProjectInfo

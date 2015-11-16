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
-- Provides the logic that unites the different objects.
-- Objects (listeners) can be registered to the event_source object, that's
-- used to notify the listeners about events.
-- Holds the current project info, in the format described by Project.loaded in
-- the field 'project'.
-- 
-- Event list:
-- <table>
--     <tr><td><b>name</b></td>             <td><b>param_a</b></td> </tr>
--     <tr><td>project-selected</td>        <td>Project</td>        </tr>
--     <tr><td>project-will-save</td>       <td>Project</td>        </tr>
--     <tr><td>project-maps-changed</td>    <td>Project</td>        </tr>
--     <tr><td>project-data-changed</td>    <td>Project</td>        </tr>
--     <tr><td>network-changed</td>         <td>Project</td>        </tr>
--     <tr><td>network-weights-changed</td> <td>Project</td>        </tr>
-- </table>
local MainController, MainControllerMT = nv_module('core.MainController')

local EventSource = require('core.EventSource')
local Project = require('core.Project')

local MainMenu = require('view.MainMenu')
local Utils = require('view.Utils')
local Fann = require('core.FannNetwork')

---
-- Constructor.
--
-- @return New MainController instance
function MainController.new()
    local self = {}
    setmetatable(self, MainControllerMT)
    
    self.event_source = EventSource.new()
    self.menu = MainMenu.new(self)
    self:load_addons()
    self:project_select()
    
    return self
end

---
-- Loads the addons.
--
-- @private
function MainController:load_addons()
    if not self.addon_manager then
        local Manager = require('core.AddonManager')
        self.addon_manager = Manager.new(self)
        self.addon_manager:load_addons()
    end
end

---
-- Runs the network creation dialog to create a new project.
function MainController:project_new()
    if not self.network_new_dlg then
        local dlg = require('view.NetworkNewDialog')
        self.network_new_dlg = dlg.new(self.menu.window)
    end
    
    local nn, ntype, rate = self.network_new_dlg:run()
    
    if nn then
        local project = Project.new()
        project.network = nn
        project.type = ntype
        project.rate = rate
        project.maps = {}
        project.data = {}
        project.fixed = false
        project.changed = true
        self:project_select(project)
    end
end

---
-- Runs the project open dialog.
function MainController:project_open()
    if not self.network_open_dlg then
        local dlg = require('view.FileDialog')
        self.network_open_dlg = dlg.new(self.menu.window, _"Open project",
            gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER)
    end
    
    local folder = self.network_open_dlg:run()
    
    if folder then
        local project = Project.new()
        
        if project:load(folder) then
            self:project_select(project)
        else
            Utils.show_info(_"Couldn't load the project.")
        end
    end
end

---
-- Runs the dialog to edit the network topology (mantaining the current
-- parameters other project info).
function MainController:project_edit_topology()
    if not self.network_edit_dlg then
        local dlg = require('view.NetworkNewDialog')
        local hld = require('core.ParamHolder')
        self.network_edit_dlg = dlg.new(self.menu.window, true)
        self.param_holder = hld.new()
    end
    
    local project = self.project
    
    self.param_holder:store(project.network, Fann.params)
    local nn, ntype, rate = self.network_edit_dlg:run(project.network)
    
    if nn then
        self.param_holder:restore(nn, Fann.params)
        project.network = nn
        project.type    = ntype
        project.rate    = rate
        self:network_changed()
        self:network_weights_changed()
    end
end

---
-- Runs the project save dialog.
function MainController:project_save()
    if not self.network_save_dlg then
        local dlg = require('view.FileDialog')
        self.network_save_dlg = dlg.new(self.menu.window, _"Save project",
            gtk.FILE_CHOOSER_ACTION_CREATE_FOLDER)
    end
    
    local folder = self.network_save_dlg:run(self.project.folder)
    
    if folder then
        -- Tell the listeners to save their data on self.project
        self.event_source:send('project-will-save', self.project)
        
        if not self.project:save(folder) then
            Utils.show_info(_"Couldn't save the project.")
        end
    end
end

---
-- Runs the map manager.
function MainController:project_edit_maps()
    if not self.map_manager then
        local dlg = require('view.MapManager')
        self.map_manager = dlg.new(self.menu.window)
    end
    
    local maps_changed = self.map_manager:run(self.project)
    if maps_changed then self:project_maps_changed() end
end

---
-- Runs the data manager.
function MainController:project_edit_data()
    if not self.data_manager then
        local dlg = require('view.DataManager')
        self.data_manager = dlg.new(self.menu.window)
    end
    
    local data_changed = self.data_manager:run(self, self.project)
    if data_changed then self:project_data_changed() end
end

---
-- Closes the current opened project.
function MainController:project_close()
    self:project_select()
end

---
-- Runs the param configurator dialog.
function MainController:network_configure_params()
    if not self.param_configurator then
        local dlg = require('view.ParamConfigurator')
        self.param_configurator = dlg.new(self.menu.window)
    end
    
    local changed = self.param_configurator:run(self.project.network)
    
    if changed then
        self:network_changed()
    end
end

---
-- Runs the activation function configurator dialog.
function MainController:network_configure_activation()
    if not self.activation_configurator then
        local dlg = require('view.ActivationConfigurator')
        self.activation_configurator = dlg.new(self.menu.window)
    end
    
    local changed = self.activation_configurator:run(self.project.network)
    
    if changed then
        self:network_changed()
    end
end

---
-- Runs the weight initializer dialog.
function MainController:network_initialize_weights()
    if not self.weight_initializer then
        local dlg = require('view.WeightInitializer')
        self.weight_initializer = dlg.new(self, self.menu.window)
    end
    
    self.weight_initializer:run(self.project)
end

---
-- Runs the network trainer dialog.
function MainController:network_train()
    if not self.network_trainer then
        local dlg = require('view.NetworkTrainer')
        self.network_trainer = dlg.new(self, self.menu.window)
        self.event_source:add('project-selected', self.network_trainer.clear,
            self.network_trainer) 
    end
    
    self.network_trainer:run(self.project)
end

---
-- Runs the graph view dialog.
function MainController:graph_view()
    if not self.graph_viewer then
        local dlg = require('view.GraphViewer')
        local inst = dlg.new(self.menu.window)
        local src = self.event_source
        self.graph_viewer = inst
        
        -- same slot
        src:add('project-selected', inst.project_selected, inst)
        src:add('network-weights-changed', inst.project_selected, inst)
    end
    
    self.graph_viewer:run(self.project.network)
end

---
-- Runs the weight view dialog.
function MainController:weight_view()
    if not self.weight_dialog then
        local dlg = require('view.WeightDialog')
        local inst = dlg.new(self.menu.window)
        local src = self.event_source
        self.weight_dialog = inst
        
        -- same slot
        src:add('project-selected', inst.project_selected, inst)
        src:add('network-weights-changed', inst.project_selected, inst)
    end
    
    self.weight_dialog:run(self.project.network)
end

---
-- Runs the network test dialog.
function MainController:network_test()
    if not self.network_tester then
        local dlg = require('view.NetworkTester')
        self.network_tester = dlg.new(self.menu.window)
    end
    
    self.network_tester:run(self.project)
end

---
-- Runs the network run dialog.
function MainController:network_run(data)
    if not self.network_runner then
        local dlg = require('view.NetworkRunner')
        self.network_runner = dlg.new(self.menu.window)
    end
    
    self.network_runner:run(self.project, data)
end

---
-- Opens the addon viewer dialog.
function MainController:addon_view()
    if not self.addon_viewer then
        local dlg = require('view.AddonViewer')
        local info_table = self.addon_manager:get_info()
        self.addon_viewer = dlg.new(info_table, self.menu.window)
    end
    
    self.addon_viewer:run()
end

---
-- Opens the about dialog.
function MainController:about()
    if not self.about_dlg then
        local dlg = require('view.AboutDialog')
        self.about_dlg = dlg.new(self.menu.window)
    end
    
    self.about_dlg:run()
end

---
-- Changes the current project. If the current project "changed" flag is on,
-- then the user will be asked if he really wants to change projects. 
--
-- @param project Project to select (can be nil to just close)
-- @return true if the new project was selected
function MainController:project_select(project)
    local cont = true
    
    if self.project and self.project.changed then
        cont = Utils.show_confirmation(_"The current project is not saved. Close it anyway?")
    end
    
    if cont then    
        -- Change the current network
        self.project = project
    
        -- Notify the listeners that a project was selected 
        self.event_source:send('project-selected', self.project)
    end
    
    return cont 
end

---
-- Emits an "project-data-changed" event for the current network.
function MainController:project_data_changed()
    -- Notify the listeners that the data of the current project changed
    self.event_source:send('projet-data-changed', self.project)
    self.project.changed = true
end

---
-- Emits an "project-maps-changed" event for the current network.
function MainController:project_maps_changed()
    -- Notify the listeners that the maps of the current project changed
    self.event_source:send('projet-maps-changed', self.project)
    self.project.changed = true
end

---
-- Emits an "network-changed" event for the current network.
function MainController:network_changed()
    -- Notify the listeners that the current network changed
    self.event_source:send('network-changed', self.project)
    self.project.changed = true
end

---
-- Emits an "network-weight-changed" event for the current network.
function MainController:network_weights_changed()
    -- Notify the listeners that the weights of the current network changed
    self.event_source:send('network-weights-changed', self.project)
    self.project.changed = true
end

---
-- Quits from the application.
function MainController:main_quit()
    if self:project_select() then
        gtk.main_quit()
    end
    
    self.addon_manager:unload_addons()
        
    return true
end

---
-- Runs the application.
function MainController:run()
    self.menu.window:show_all()
    gtk.main()
end

return MainController

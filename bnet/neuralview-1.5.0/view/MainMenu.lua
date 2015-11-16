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
-- Menu that provides access to the functions of the simulator.
local MainMenu, MainMenuMT  = nv_module('view.MainMenu')

local ProjectInfo           = require('view.ProjectInfo')
local ProjectDescription    = require('view.ProjectDescription')
local Utils                 = require('view.Utils')

---
-- Constructor.
--
-- @param controlled MainControler instance that created the menu.
-- @return New MainMenu instance
function MainMenu.new(controller)
    local self = {}
    setmetatable(self, MainMenuMT)
    
    -- table that hold the buttons that only are sensitive if there's a
    -- current project. 
    self.s_buttons = {}
    self:build_gui()
    self.controller = controller
    self:connect_events()
    
    return self
end

---
-- Adds buttons to the s_buttons group.
--
-- @private
function MainMenu:add_s_buttons(...)    
    for i, button in ipairs({...}) do
        table.insert(self.s_buttons, button)
    end
end

---
-- Adds a new group to the main menu palette.
--
-- @param title Title of the group
-- @param ... Tool items to be packed
-- @return The vbox created internally
function MainMenu:pack_group(title, ...)
    local group = gtk.ToolItemGroup.new(title)
    group:get('label_widget'):set('use-underline', true)
    
    for i, item in ipairs{...} do
        group:add(item)
    end
    
    self.palette:add(group)
    self.palette:set_exclusive(group, true)
    
    return group
end

---
-- Builds the interface.
--
-- @private
function MainMenu:build_gui()
    -- Main window
    self.window = gtk.Window.new()
    self.window:set('title', 'NeuralView', 'window-position', 
        gtk.WIN_POS_CENTER, 'icon', NVIcon)
    
    self.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 5)
    self.palette = gtk.ToolPalette.new()
    self.palette:set('toolbar-style', gtk.TOOLBAR_BOTH_HORIZ)
    self.right_box = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 5)
    
    -- Project group
    self.project_group = {}
    local g = self.project_group
    
    g.new  = Utils.new_tool_button('gtk-new',  
        _"_New",
        _"Create a new project"
    )
    g.load = Utils.new_tool_button('gtk-open',
        _"_Open",
        _"Open an existing project"
    )
    g.edit = Utils.new_tool_button('gtk-edit',
        _"_Topology",
        _"Edit the network topology"
    )
    g.maps = Utils.new_tool_button('gtk-convert',
        _"_Data Maps",
        _"Manage the data maps"
    )
    g.data = Utils.new_tool_button('gtk-directory', 
        _"Data _Manager",
        _"Manage the training / test data"
    )
    g.save = Utils.new_tool_button('gtk-save',
        _"_Save",
        _"Save the project"
    )   
    g.close = Utils.new_tool_button('gtk-close',
        _"_Close",
        _"Close the project"
    )
    
    g.group = self:pack_group(_"_Project", g.new, g.load, g.edit,
        g.maps, g.data, g.save, g.close)
    self:add_s_buttons(g.edit, g.maps, g.data, g.save, g.close)
    
    -- Training group
    self.training_group = {}
    local g = self.training_group
    
    g.params = Utils.new_tool_button('gtk-preferences',
        _"_Parameters",
        _"Configure the training parameters"
    )
    g.activation = Utils.new_tool_button('gtk-preferences', 
        _"Activation _Functions",
        _"Configure the activation functions"
    )
    g.initialize = Utils.new_tool_button('gtk-new', 
        _"Initialize _Weights",
        _"Initialize the connection weights of the network"
    )
    g.train = Utils.new_tool_button('gtk-execute',
        _"_Train",
        _"Train the network"
    )
    g.group = self:pack_group(_"_Training", g.params, g.activation, g.initialize, g.train)
    self:add_s_buttons(g.params, g.activation, g.initialize, g.train)
    
    -- Execution group
    self.execution_group = {}
    local g = self.execution_group
    
    g.graph = Utils.new_tool_button('gtk-zoom-in',
        _"View _Graph",
        _"View the graph of the network"
    )
    g.weights = Utils.new_tool_button('gtk-select-all', 
        _"View Weig_hts",
        _"View the connection weights of the network"
    )   
    g.test = Utils.new_tool_button('gtk-apply',
        _"Te_st",
        _"Test the network using an existing data"
    )   
    g.run = Utils.new_tool_button('gtk-execute', 
        _"Ru_n",
        _"Run the network for general inputs"
    )
    
    g.group = self:pack_group(_"_Execution", g.graph, g.weights, g.test, g.run)
    self:add_s_buttons(g.graph, g.weights, g.test, g.run)
    
    -- Addon group
    self.addon_group = {}
    local g = self.addon_group
    
    g.manager = Utils.new_tool_button('gtk-about',
        _"_View Add-ons",
        _"View the loaded add-ons"
    )
        
    g.group = self:pack_group(_"_Add-ons", g.manager)
    
    -- Other group
    self.other_group = {}
    local g = self.other_group
    
    g.about = Utils.new_tool_button('gtk-about',
        _"_About",
        _"View informations about the application"
    )
    g.quit = Utils.new_tool_button('gtk-quit',
        _"_Quit",
        _"Quit from the application"
    )
        
    g.group = self:pack_group(_"Othe_r", g.about, g.quit)
    
    -- Info view
    self.project_info = ProjectInfo.new()
    self.project_description = ProjectDescription.new()
    self.info_view = {}
    
    local g = self.info_view
    g.notebook = gtk.Notebook.new()
    g.notebook:set('vexpand', true, 'hexpand', true)
    
    g.info_label = gtk.Label.new_with_mnemonic(_"_Information")
    g.info_label:set('tooltip-text', 'Information about the project')
    
    g.info_content = self.project_info.scroll
    g.info_label:set('mnemonic-widget', g.info_content)
    
    g.desc_label = gtk.Label.new_with_mnemonic(_"_Description")
    g.desc_label:set('tooltip-text', 'Description of the project')
    
    g.desc_content = self.project_description.scroll
    g.desc_label:set('mnemonic-widget', g.desc_content)
    
    g.notebook:append_page(g.info_content, g.info_label)
    g.notebook:append_page(g.desc_content, g.desc_label)
    self.right_box:add(g.notebook)
    
    -- pack it
    self.hbox:pack_start(self.palette, false, true, 0)
    self.hbox:pack_start(self.right_box, true, true, 0)
    self.window:set('default-width', 600, 'default-height', 500)
    
    self.project_group.group:set('collapsed', false)
    
    self.window:add(self.hbox)
end

---
-- Connects the events of the menu to the controller.
--
-- @private
function MainMenu:connect_events()
    local controller = self.controller
    self.window:connect('delete-event', controller.main_quit, controller)
    
    local g = self.project_group
    g.new:connect('clicked',        controller.project_new, controller)
    g.load:connect('clicked',       controller.project_open, controller)
    g.edit:connect('clicked',       controller.project_edit_topology, controller)
    g.maps:connect('clicked',       controller.project_edit_maps, controller)
    g.data:connect('clicked',       controller.project_edit_data, controller)
    g.save:connect('clicked',       controller.project_save, controller)
    g.close:connect('clicked',      controller.project_close, controller)
    
    local g = self.training_group
    g.params:connect('clicked',     controller.network_configure_params, controller)
    g.activation:connect('clicked', controller.network_configure_activation, controller)
    g.initialize:connect('clicked', controller.network_initialize_weights, controller)
    g.train:connect('clicked',      controller.network_train, controller)
    
    local g = self.execution_group
    g.graph:connect('clicked',      controller.graph_view, controller)
    g.weights:connect('clicked',    controller.weight_view, controller)
    g.test:connect('clicked',       controller.network_test, controller)
    g.run:connect('clicked',        controller.network_run, controller)
    
    local g = self.addon_group
    g.manager:connect('clicked',    controller.addon_view, controller)
    
    local g = self.other_group
    g.about:connect('clicked',      controller.about, controller)
    g.quit:connect('clicked',       controller.main_quit, controller)
    
    -- Add listeners to the event source
    local src = self.controller.event_source
    src:add('project-selected',     self.project_selected, self)
    src:add('project-selected',     self.project_description.project_selected, self.project_description)
    src:add('project-selected',     self.project_info.network_changed, self.project_info)
    src:add('project-will-save',    self.project_description.project_will_save, self.project_description)
    src:add('network-changed',      self.project_info.network_changed, self.project_info)
end

---
-- Updates the menu items, based on the current project.
--
-- @param event Event that triggered this handler
-- @param project Current project
-- @slot
function MainMenu:project_selected(event, project)      
    local network_exists = project ~= nil
    
    for i, button in ipairs(self.s_buttons) do
        button:set('sensitive', network_exists) 
    end
end

---
-- Adds a tool item to the addon group.
--
-- @param Tool item to add to the group
-- @param context If the button must only be clickable if there's a selected
-- project
function MainMenu:add_addon_button(item, context)
    self.addon_group.group:add(item)
    if context then self:add_s_buttons(item) end
end

return MainMenu

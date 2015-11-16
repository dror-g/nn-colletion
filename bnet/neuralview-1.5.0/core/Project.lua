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
-- Handles the serialization and loading of projects. A project involves
-- the neural network and the attached train / test data, plus other informations.
local Project, ProjectMT = nv_module('core.Project')

local Map = require('core.Map')
local Utils = require('core.Utils')

---
-- @name network.nv
-- @class table
-- @description Format of the serialized project file.
-- @field fixed True it the network has been saved to a fixed point format
-- @field description User-defined description of the network
-- @field data Array that holds the project's data file descriptions. The files must be named
-- index.data, like 1.data, 2.data, 3.data, relative to the description array
-- @field maps Array that holds the project's data maps (to be used to
-- map input and output neuron values)
-- @field file The filename (relative) of the serialized neural network from the core library

---
-- @name Project
-- @class table
-- @description Format of the in memory project.
-- @field changed True if the network changed since the last save
-- @field description User-defined description of the network
-- @field data Array of {desc, obj} that holds the project's data files
-- @field maps Array of {desc, tbl} that holds the project's maps
-- @field network The neural network
-- @field folder The path where the network was loaded
-- @field training_params Holds the last used training parameters (can be nil)
-- @field training_status Holds the last training status (can be nil)
-- @field weight_init Holds the last weight initialization params

local NET_NV_NAME = 'net.nv'
local NET_FANN_NAME = 'net.fann'

Project['NET_NV_NAME'] = NET_NV_NAME
Project['NET_FANN_NAME'] = NET_FANN_NAME

---
-- Constructor.
function Project.new()
    local self = {}
    setmetatable(self, ProjectMT)
    
    self.changed = true
    
    return self
end

---
-- Loads a project from a folder. Can raise errors, so use with pcall.
--
-- @param folder Path of the project folder to be loaded
-- @return Project table with the loaded info
-- @private
local function load_helper(folder)
    local self = {}

    -- Test if the folder is valid
    -- local mode = lfs.attributes(folder, "mode")
    -- assert(mode == "directory")
    local prefix = folder .. '/'
    
    -- Try to load the network information
    local info = dofile(prefix .. NET_NV_NAME)
    assert(info)
    
    -- Can't load fixed networks
    assert(not info.fixed)
    
    -- Load the project description 
    assert(info.description and info.data)
    self.description = info.description
    self.fixed = info.fixed
    
    local new_data = {}
    
    -- Load the data
    for i, desc in ipairs(info.data) do
        local aux = fann.Data.read_from_file(prefix .. i .. '.data')
        assert(aux)
            
        table.insert(new_data, {
            desc = desc,
            obj = aux,
        })
    end
    
    self.data = new_data
    
    -- Load the maps
    assert(info.maps)
    self.maps = info.maps
    
    for i, map in ipairs(self.maps) do
        self.maps[i] = Map.load(map)
    end
    
    -- Load the FANN network
    local nn = fann.Net.create_from_file(prefix .. NET_FANN_NAME)
    assert(nn)
    
    self.network = nn
    self.folder = folder
    
    return self
end

---
-- Saves a project to a folder. Can raise errors, so use with pcall. If no error
-- has been raised, then the save succeeded.
--
-- @param prj Project to be saved
-- @param folder Folder wher the project will be saved
-- @param fixed true if the project will be saved in fixed mode
-- @private
local function save_helper(prj, folder, fixed)
    -- Check the project info
    assert(prj.description and prj.data and prj.network)
    
    -- Check the output folder
    -- local mode = lfs.attributes(folder, "mode")
    -- assert(mode == "directory")
    local prefix = folder .. '/'
    local save_net, save_data
    
    if fixed then
        save_net = fann.Net.save_to_fixed
        save_data = fann.Data.save_to_fixed
    else
        save_net = fann.Net.save
        save_data = fann.Data.save
    end
    
    -- Save the network
    -- res can be the floating point digits if fixed or -1 / 0 if not fixed
    local res = save_net(prj.network, prefix .. NET_FANN_NAME)
    assert(res >= 0) 
    
    -- Save the project
    local file = io.open(prefix .. NET_NV_NAME, 'w')
    assert(file)
    
    -- Serialization of the maps
    local maps = {}
    
    for i, map in ipairs(prj.maps) do
        table.insert(maps, map:serialize())
    end
    
    local mapst = table.concat(maps ,',\n\t\t')
    
    local data_descs = {}
    
    -- Save the data
    for i, data in ipairs(prj.data) do
        assert(save_data(data.obj, prefix .. i .. '.data', res) >= 0)
        table.insert(data_descs, Utils.protect_string(data.desc) )
    end
    
    -- Serialization of the data names
    local datat = table.concat(data_descs, ', ')
    
    file:write(string.format([[
local NeuralNetwork = {
    fixed = %s,
    description = %s,
    maps = {
        %s
    },
    data = {%s}
}

return NeuralNetwork]], 
    tostring(fixed), Utils.protect_string(prj.description), mapst, datat))

    file:close()
end

---
-- Saves the project to an existing folder (the folder creation is handled by the 
-- ProjectSaveDialog). Overwrites existing files.
--
-- @param folder Folder where the project will be stored
-- @param export If true, the project will not be marked as 'not changed'
-- @param fixed If true, the project will be saved in fixed mode. Also, it
-- will not mark as 'not changed'
-- @return true, or nil plus an error message in case of errors
-- @see view.ProjectSaveDialog
function Project:save(folder, export, fixed)
    -- workaround for the locale dependency of FANN
    lcl.setlocale(lcl.ALL, 'C')
    local res, msg = pcall(save_helper, self, folder, fixed)
    lcl.setlocale()
    
    if res then
        if not export and not fixed then
            self.changed = false
        end
        
        return true
    else
        io.stderr:write(msg, '\n')
        return nil, _"Couldn't save the project"
    end
end

---
-- Loads the fields from a folder.
--
-- @param folder Folder where the project is stored
-- @return true, or nil plus an error message in case of errors
-- @see view.ProjectOpenDialog
function Project:load(folder)
    -- workaround for the locale dependency of FANN
    lcl.setlocale(lcl.ALL, 'C')
    local res, info = pcall(load_helper, folder)
    lcl.setlocale()
    
    -- Success? The extra layer prevents an invalid state in the case of 
    -- invalid projects.
    if res then
        Utils.shallow_copy(info, self)
        self.changed = false
        return true
    else
        io.stderr:write(info, '\n')
        return nil, _"Invalid project"
    end
end

return Project

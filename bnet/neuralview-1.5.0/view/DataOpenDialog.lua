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
-- Dialog that allows the user to load a data from a file.
local DataOpenDialog, DataOpenDialogMT = nv_module('view.DataOpenDialog')
local FileDialog = require('view.FileDialog')

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of DataOpenDialog
function DataOpenDialog.new(parent)
    local self = {}
    setmetatable(self, DataOpenDialogMT)
    
    self:build_gui(parent)
    
    return self
end

---
-- Builds the interface.
--
-- @param parent Parent window
-- @private
function DataOpenDialog:build_gui(parent)
    self.dialog = FileDialog.new(parent, _"Open training/test data",
        gtk.FILE_CHOOSER_ACTION_OPEN)
end

---
-- Runs the dialog.
--
-- @param num_input Expected number of neurons in the input layer
-- @return The selected data on success, nil if the user canceled or nil plus
-- an error message if an error occurred 
function DataOpenDialog:run(num_input, num_output)
    local filename = self.dialog:run()
    
    if filename then
        local data = fann.Data.read_from_file(filename)
        if not data then return nil, _"Invalid data" end
        
        if not (data:num_input() == num_input and data:num_output() == num_output) then
            return nul, _"The number of input/output neurons in the data doesn't matches the network."
        end
        
        return data
    end
end

return DataOpenDialog 

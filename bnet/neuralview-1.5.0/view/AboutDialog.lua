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
-- Dialog that shows some information about the people involved with the
-- project.
local AboutDialog, AboutDialogMT = nv_module('view.AboutDialog')

---
-- Constructor.
--
-- @param parent Parent window
-- @return New AboutDialog instance
function AboutDialog.new(parent)
    local self = {}
    setmetatable(self, AboutDialogMT)
    
    self:build_gui(parent)
    
    return self
end

---
-- Builds the interface.
--
-- @param parent Parent window
-- @private
function AboutDialog:build_gui(parent)
    self.dialog = gtk.AboutDialog.new()
    self.dialog:set('transient-for', parent)
    
    self.logo = gdk.Pixbuf.new_from_file('logo.png')
    
    self.dialog:set('authors', NVAuthors)
    self.dialog:set('comments', _"Neural Network Simulator")
    self.dialog:set('license', 'GPLv3+')
    self.dialog:set('logo', self.logo)
    self.dialog:set('program-name', 'NeuralView')
    self.dialog:set('version', NVVersion)
    self.dialog:set('website', 'https://bitbucket.org/lucashnegri/neuralview')
    self.dialog:set('icon', NVIcon)
end

---
-- Runs the dialog.
--
-- @return The response code 
function AboutDialog:run()
    local res = self.dialog:run()
    self.dialog:hide()
     
    return res
end

return AboutDialog

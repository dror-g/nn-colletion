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
-- Dialog that allows the user to view an image.
local ImageViewer, ImageViewerMT = nv_module('view.ImageViewer')

---
-- Constructor.
--
-- @param parent Parent window
function ImageViewer.new(parent)
    local self = {}
    setmetatable(self, ImageViewerMT)
    
    self:build_gui()
    
    return self
end

---
-- Builds the interface.
--
-- @private
function ImageViewer:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('transient-for', parent, 'resizable', false, 'icon', NVIcon)
    self.dialog:add_button('gtk-close', gtk.RESPONSE_OK)
    
    self.image = gtk.Image.new()
    self.vbox = self.dialog:get_content_area()
    self.vbox:add(self.image)
    self.vbox:show_all()
end

---
-- Runs the dialog.
--
-- @param img Name of the image file
-- @param title Title of the image
function ImageViewer:run(img, title)
    self.dialog:set('title', title)
    self.image:set('file', img)
    
    self.dialog:run()
    self.dialog:hide()
    
    self.image:set('file', nil)
end

return ImageViewer

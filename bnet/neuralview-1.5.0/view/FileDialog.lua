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
-- Enhanced gtk.FileChooserDialog.
local FileDialog, FileDialogMT = nv_module('view.FileDialog')

---
-- Constructor.
--
-- @param parent Parent window
-- @param title Title of the dialog
-- @param action GtkFileChooserAction to use
-- @param filters Table in the form {{id = 1, name = "Lua", ext = ".lua"}} (optional)
-- (name must be unique, the id is returned to the user)
-- @return New FileDialog instance
function FileDialog.new(parent, title, action, filters)
    local self = {}
    setmetatable(self, FileDialogMT)
    
    self:build_gui(parent, title, action)
    self:add_filters(filters)
    
    return self
end

---
-- Builds the interface.
--
-- @param parent Parent window
-- @private
function FileDialog:build_gui(parent, title, action)
    self.dialog = gtk.FileChooserDialog.new(title, parent, action,
        'gtk-cancel', gtk.RESPONSE_CANCEL, 'gtk-ok', gtk.RESPONSE_OK)
        
    self.dialog:set('do-overwrite-confirmation', true) 
end

---
-- Adds filters to the dialog.
--
-- @private
function FileDialog:add_filters(filters)
    if not filters then return end
    self.filter_map = {}
    
    for i, filter in ipairs(filters) do
        local f = gtk.FileFilter.new()
        f:set_name(filter.name)
        f:add_pattern('*' .. filter.ext)
        self.filter_map[filter.name] = filter
        self.dialog:add_filter(f)
        
        if not self.default_filter then
            self.default_filter = f
        end
    end
end

---
-- Runs the dialog.
--
-- @param folder The initial folder that the dialog should point (can be nil)
-- @return The selected folder
function FileDialog:run(folder)
    if folder then self.dialog:set_filename(folder) end
    
    if self.default_filter then
        self.dialog:set('filter', self.default_filter)
    end
    
    local res = self.dialog:run()
    self.dialog:hide()
    
    if res == gtk.RESPONSE_OK then
        local name, id = self.dialog:get_filename()
        local filter = self.dialog:get('filter')
        
        if filter then
            local filter = self.filter_map[filter:get_name()]
            local ext = filter.ext
            id = filter.id
            
            -- put the extension if needed
            if name:sub(-#ext) ~= ext then
                name = name .. ext
            end
        end
        
        return name, id
    end
end

return FileDialog

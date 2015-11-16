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
-- Dialog that allows the user to see the current loaded addons.
local AddonViewer, AddonViewerMT = nv_module('view.AddonViewer')

---
-- Constructor.
--
-- @param info_table Table with information of each addon
-- @param parent Parent window
function AddonViewer.new(info_table, parent)
    local self = {}
    setmetatable(self, AddonViewerMT)
    
    self:build_gui(parent)
    self.iter = gtk.TreeIter.new()
    self:prepare(info_table)
    
    return self
end

---
-- Builds the interface.
--
-- @param parent Parent window
-- @private
function AddonViewer:build_gui(parent)
    self.dialog = gtk.Dialog.new()
    self.dialog:set('title', _"View add-ons", 'transient-for', parent, 
        'default-width', 200, 'default-height', 300, 'icon', NVIcon)
    self.dialog:add_button('gtk-close', gtk.RESPONSE_OK)
        
    self.model = gtk.ListStore.new('gchararray', 'gint')
    self.view = gtk.TreeView.new_with_model(self.model)
    
    self.selection = self.view:get_selection()
    self.selection:connect('changed', self.addon_selected, self)
    
    self.name_rend = gtk.CellRendererText.new()
    self.name_col = gtk.TreeViewColumn.new_with_attributes(_"Add-ons", 
        self.name_rend, 'text', 0)
    
    self.view:append_column(self.name_col)
    
    self.info_table = gtk.Grid.new(3, 2, false)
    self.info_table:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    -- Name
    self.name_label = gtk.Label.new(_"<b>Add-on:</b>")
    self.name_label:set('use-markup', true, 'xalign', 1, 'tooltip-text',
        _"Add-on name")
    self.name_value = gtk.Label.new()
    self.name_value:set('xalign', 0, 'max-width-chars', 50, 'selectable', true)
    
    self.info_table:attach(self.name_label, 0 , 0 , 1 , 1)
    self.info_table:attach(self.name_value, 1 , 0 , 1 , 1)
    
    -- Description
    self.desc_label = gtk.Label.new(_"<b>Description:</b>")
    self.desc_label:set('use-markup', true, 'xalign', 1, 'tooltip-text',
        _"Add-on description")
    self.desc_value = gtk.Label.new()
    self.desc_value:set('xalign', 0, 'max-width-chars', 50, 'selectable', true)
    
    self.info_table:attach(self.desc_label, 0, 1, 1, 1)
    self.info_table:attach(self.desc_value, 1, 1, 1, 1)
    
    -- Authors
    self.authors_label = gtk.Label.new(_"<b>Author(s):</b>")
    self.authors_label:set('use-markup', true, 'xalign', 1,
        'tooltip-text', _"Add-on authors")
    self.authors_value = gtk.Label.new()
    self.authors_value:set('xalign', 0, 'max-width-chars', 50)
    
    self.info_table:attach(self.authors_label, 0, 2, 1, 1)
    self.info_table:attach(self.authors_value, 1, 2, 1, 1)
    
    self.scroll = gtk.ScrolledWindow.new()
    self.scroll:set('vscrollbar-policy', gtk.POLICY_AUTOMATIC,
        'hscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.scroll:add(self.view)
    
    self.vbox = self.dialog:get_content_area()
    self.vbox:pack_start(self.scroll, true, true, 0)
    self.vbox:pack_start(self.info_table, false, true, 0)
    
    self.vbox:show_all()
end

---
-- @private
function AddonViewer:addon_selected()
    if self.selection:get_selected(self.iter) then
        local idx = self.model:get(self.iter, 1)
        local info = self.info_table[idx]
        local name = string.format(_"%s v%s", info.name, info.version)
        local desc = info.description
        local authors = info.authors
        
        self.name_value:set('label', name)
        self.desc_value:set('label', desc)
        self.authors_value:set('label', authors)
    end
end

---
-- Prepares the interface for a new list of addons.
--
-- @param info_table Table with the addons
function AddonViewer:prepare(info_table)
    local model, iter = self.model, self.iter
    
    self.view:set('model', nil)
    self.info_table = info_table
    model:clear()
    
    if info_table then
        for i, info in ipairs(info_table) do
            model:append(iter)
            model:seto(iter, info.name, i)
        end
    end
    
    self.view:set('model', model)
end

---
-- Runs the addon viewer dialog.
function AddonViewer:run()
    self.dialog:run()
    self.dialog:hide()
end

return AddonViewer

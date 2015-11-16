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
-- Interface creation utilities.
local Utils, UtilsMT = nv_module('view.Utils')

---
-- Creates a new frame with a label.
--
-- @param label Frame label
-- @return New frame
function Utils.new_frame(label)
    local label = gtk.Label.new('<b>' .. label .. '</b>')
    label:set('use-markup', true)
    local frame = gtk.Frame.new()
    frame:set('label-widget', label)
    
    return frame
end

---
-- Creates a button with a custom label and image.
--
-- @param namel Icon name
-- @param label Label to override the stock one
-- @return New Button
function Utils.new_button(name, label)
    local image = gtk.Image.new()
    image:set('icon-name', name)
    local button = gtk.Button.new_with_mnemonic(label)
    button:set('image', image)
    
    return button
end

---
-- Creates a tool button with an icon. Makes GTK+ respect the
-- use-underlineproperty!
--
-- @param name Icon name
-- @param label Label to override the stock one
-- @return New ToolButton
function Utils.new_tool_button(name, label, tooltip)
    local image  = gtk.Image.new()
    image:set('icon-name', name)
    local button = gtk.ToolButton.new(image, '')
    local label  = gtk.Label.new_with_mnemonic(label)
    button:set('label-widget', label)
    button:set('tooltip-text', tooltip)
    
    return button
end

---
-- Creates a label | main widget ToolItem.
--
-- @param label Label widget
-- @param entry Widget to serve as content
-- @param flip If the entry should come before the label
-- @return New composed tool item
function Utils.new_tool_item(label, entry, flip)
    local item = gtk.ToolItem.new()
    local hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    hbox:pack_start(label, false, true, 0)
    hbox:pack_start(entry, true, true, 5)
    item:add(hbox)
    label:set('mnemonic-widget', entry)
    
    return item
end

local iter = gtk.TreeIter.new()

---
-- Populates a model using values from a table.
-- Does not accept nils.
--
-- @param model Model to be populated
-- @param values Values in the form { {cell11, cell12}, {cell21, cell22}, ... }
-- @param clear true to also clear the model before the population
-- @param view View of the model to freeze signals (optional)
function Utils.populate_model(model, values, clear, view)
    if view then view:set('model', nil) end
    if clear then model:clear() end
    
    for i, row in ipairs(values) do
        model:append(iter)
        model:seto(iter, unpack(row))
    end
    
    if view then view:set('model', model) end
end

-- confirmation dialog table
local confirm = {}

local function build_confirm_dlg()
    confirm.dlg = gtk.Dialog.new()
    confirm.dlg:set('window-position', gtk.WIN_POS_CENTER, 'resizable', false,
        'title', _"Confirmation", 'role', 'confirm', 'modal', true,
        'icon', NVIcon)
    confirm.no, confirm.yes = confirm.dlg:add_buttons('gtk-cancel', gtk.RESPONSE_CANCEL,
        'gtk-ok', gtk.RESPONSE_OK)
    local vbox = confirm.dlg:get_content_area()
    local image = gtk.Image.new()
    image:set('icon-size', 6, 'stock', 'gtk-dialog-warning')
    confirm.label = gtk.Label.new('')
    confirm.label:set('selectable', true, 'use-markup', true)
    local hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 10)
    hbox:add(image, confirm.label)
    vbox:add(hbox)
    vbox:show_all()
end

---
-- Shows a confirmation dialog (Cancel, OK buttons).
--
-- @param message Message to show on the dialog
-- @return true if the user clicked OK, false otherwise
function Utils.show_confirmation(message)
    if not confirm.dlg then
        build_confirm_dlg()
    end
    
    confirm.label:set('label', message)
    confirm.no:grab_focus()
    local res = confirm.dlg:run()
    confirm.dlg:hide()
    
    return res == gtk.RESPONSE_OK
end

-- info dialog table
local info = {}

local function build_info_dlg()
    info.dlg = gtk.Dialog.new()
    info.dlg:set('window-position', gtk.WIN_POS_CENTER, 'resizable', false,
        'title', _"Information", 'role', 'info', 'modal', true, 'icon', NVIcon)
    info.dlg:add_buttons('gtk-ok', gtk.RESPONSE_OK)
    local vbox = info.dlg:get_content_area()
    local image = gtk.Image.new()
    image:set('icon-size', 6, 'stock', 'gtk-dialog-info')
    info.label = gtk.Label.new('')
    info.label:set('selectable', true, 'use-markup', true)
    local hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 10)
    hbox:add(image, info.label)
    vbox:add(hbox)
    vbox:show_all()
end

---
-- Shows a info dialog (OK button).
--
-- @param message Message to show on the dialog
function Utils.show_info(message)
    if not info.dlg then
        build_info_dlg()
    end
    
    info.label:set('label', message)
    local res = info.dlg:run()
    info.dlg:hide()
end

return Utils

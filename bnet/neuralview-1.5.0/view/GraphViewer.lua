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
-- Window that allows the user to view the graph of a neural network.
local GraphViewer, GraphViewerMT = nv_module('view.GraphViewer')

local Utils = require('view.Utils')

---
-- Constructor.
--
-- @param parent Parent window
-- @return New instance of GraphViewer 
function GraphViewer.new(parent)
    local self = {}
    setmetatable(self, GraphViewerMT)
    
    self:build_gui(parent)
    self.zoom = 1
    self.spacing = 1
    
    return self
end

---
-- Builds the interface.
--
-- @param parent Parent window
-- @private
function GraphViewer:build_gui(parent)
    self.window = gtk.Window.new()
    self.window:set('transient-for', parent, 'title', _"View graph",
        'default-width', 600, 'default-height', 400, 'window-position',
        gtk.WIN_POS_CENTER_ON_PARENT, 'icon', NVIcon)
        
    self.accel_group  = gtk.AccelGroup.new()
    self.accel_group:connect('Escape', self.close, self)
    self.window:add_accel_group(self.accel_group)
    
    -- toolbar
    self.toolbar = gtk.Toolbar.new()
    local i = {}
    self.items = i
    
    i.save = Utils.new_tool_button('gtk-save', _"_Save")
    i.save:connect('clicked', self.save, self)
    i.save:set('tooltip-text', _"Save the network graph")
    
    -- zoom
    i.zoom_spin = gtk.SpinButton.new_with_range(10, 200, 10)
    i.zoom_label = gtk.Label.new_with_mnemonic(_"_Zoom (%)")
    i.zoom_spin:set('value', 100)
    i.zoom_spin:connect('value-changed', self.zoom_changed, self)
    i.zoom_label:set('tooltip-text', _"Select the zoom level", 
        'mnemonic-widget', i.zoom_spin)
    i.zoom = Utils.new_tool_item(i.zoom_label, i.zoom_spin)
    
    -- spacing
    i.spacing_spin = gtk.SpinButton.new_with_range(50, 1000, 10)
    i.spacing_label = gtk.Label.new_with_mnemonic(_"S_pacing (%)")
    i.spacing_spin:set('value', 100)
    i.spacing_spin:connect('value-changed', self.spacing_changed, self)
    i.spacing = Utils.new_tool_item(i.spacing_label, i.spacing_spin)
    i.spacing_label:set('tooltip-text', _"Select the spacing between layers",
        'mnemonic-widget', i.spacing_spin)
    
    -- bias
    i.bias_check = gtk.CheckButton.new_with_mnemonic(_"Show _bias")
    i.bias_check:connect('toggled', self.show_bias_changed, self)
    i.bias = gtk.ToolItem.new()
    i.bias:set('tooltip-text', _"Toggles the bias neuron visualization")
    i.bias:add(i.bias_check)
    
    i.close = Utils.new_tool_button('gtk-close', _"_Close")
    i.close:connect('clicked', self.close, self)
    i.close:set('tooltip-text', _"Close the dialog")
    
    self.toolbar:add(i.save,
        gtk.SeparatorToolItem.new(),
        i.zoom, i.spacing,
        gtk.SeparatorToolItem.new(),
        i.bias,
        gtk.SeparatorToolItem.new(),
        i.close
    )
    
    self.area = gtk.DrawingArea.new()
    self.scroll = gtk.ScrolledWindow.new()
    self.scroll:add(self.area)

    self.vbox = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
    self.vbox:pack_start(self.toolbar, false, true, 0)
    self.vbox:pack_start(self.scroll, true, true, 0)
    
    self.window:connect('delete-event', self.close, self)
    --~ self.area:modify_bg(gtk.STATE_NORMAL, gdk.color_parse('white') )
    self.area:connect('draw', self.draw, self)
    
    self.vbox:show_all()
    self.window:add(self.vbox)
    
end

---
-- @private
function GraphViewer:calc_size()
    if self.net then
        local w, h = self.painter:calc_size(self.layer_array, self.bias_array,
            self.zoom, self.spacing, self.show_bias)
        
        return w, h
    else
        return 1, 1
    end
end

---
-- @private
function GraphViewer:draw_graph(cr)
    if self.net then
        self.painter:draw_graph(cr, self.layer_array, self.conn_array, 
            self.bias_array, self.layer_color, self.zoom, self.spacing,
            self.show_bias, self.w_max)
    end
end

---
-- @private
function GraphViewer:zoom_changed()
    self.zoom = self.items.zoom_spin:get('value') / 100
    self:set_canvas_size()
end

---
-- @private
function GraphViewer:spacing_changed()
    self.spacing = self.items.spacing_spin:get('value') / 100
    self:set_canvas_size()
end

---
-- @private
function GraphViewer:show_bias_changed()
    self.show_bias = self.items.bias_check:get('active')
    self:set_canvas_size()
end

local COLOR_RED = {0.8, 0.4, 0.4}
local COLOR_GREEN = {0.4, 0.8, 0.4}
local COLOR_BLUE = {0.4, 0.4, 0.8}

local TYPE_SVG, TYPE_PNG = 1, 2

-- handlers for different output types
local handlers = {}

handlers[TYPE_PNG] = {
    prepare = function(file, w, h)
        local surface = cairo.ImageSurface.create(cairo.FORMAT_ARGB32, w, h)
        local cr = cairo.Context.create(surface)
        return cr, surface
        
    end,
    
    commit = function(file, cr, surface)
        surface:write_to_png(file)
    end,
}

handlers[TYPE_SVG] = {
    prepare = function(file, w, h)
        local surface = cairo.SvgSurface.create(file, w, h)
        local cr = cairo.Context.create(surface)
        return cr, surface
        
    end,
    
    commit = function(file, cr, surface)
        cr:show_page()
        surface:finish()
    end,
}


---
-- Saves the current graph to a file.
--
-- @private
function GraphViewer:save()
    if not self.save_dialog then
        local dlg = require('view.FileDialog')
        local filters = {
            {id = TYPE_SVG, name = _"SVG image", ext = '.svg'},
            {id = TYPE_PNG, name = _"PNG image", ext = '.png'},
        }
        
        self.save_dialog = dlg.new(self.window, _"Save graph",
            gtk.FILE_CHOOSER_ACTION_SAVE, filters)
    end
    
    local file, ftype = self.save_dialog:run()
    
    if file then
        local handler = handlers[ftype]
        local w, h = self:calc_size()
        local cr, surface = handler.prepare(file, w, h)
        
        self:draw_graph(cr)
        
        handler.commit(file, cr, surface)
        cr:destroy()
        surface:destroy()
    end
end

---
-- @private
function GraphViewer:prepare(network)
    if not network then self:clear() return end

    if not self.painter then
        local GraphPainter = require('core.GraphPainter')
        self.painter = GraphPainter.new()
    end
    
    self.net = network
    self.layer_array = self.net:get_layer_array()
    
    local w_min, w_max
    self.conn_array, w_min, w_max = self.net:get_connection_array()
    if w_min < 0 then w_min = -w_min end
    self.w_max = w_max > w_min and w_max or w_min
    
    self.bias_array = self.net:get_bias_array()
    self.layer_color = {}
    self.layer_color[1] = COLOR_GREEN
    self.layer_color[#self.layer_array] = COLOR_BLUE
    self.bias_color = COLOR_RED
    self:set_canvas_size()
end

---
-- Updates the interface if the project changed.
--
-- @param event Event that triggered this handler
-- @param project The current project
-- @slot
function GraphViewer:project_selected(event, project)
    if self.running then
        self:prepare(project and project.network)
    end
end

---
-- @private
function GraphViewer:set_canvas_size()
    local w, h = self:calc_size()
        
    -- GTK+ optimizes multiple requests (the manual queue_draw is needed, the
    -- width and height can be the same but the content may be changed)
    self.area:set_size_request(w, h)
    self.area:queue_draw()
end

---
-- @private
function GraphViewer:clear()
    self.net = nil
    self.layer_array = nil
    self.conn_array = nil
    self.layer_color = nil
    self:set_canvas_size()
end

---
-- @private
function GraphViewer:close()
    self:prepare()
    self.window:hide()
    self.running = false
    
    return true
end

---
-- @private
function GraphViewer:draw(cr)
    local cr = cairo.Context.wrap(cr)
    self:draw_graph(cr)
end

---
-- Runs the dialog.
--
-- @param network Network that will be used to draw the graph 
function GraphViewer:run(network)
    self.running = true
    self:prepare(network)
    self.window:show_all()
end

return GraphViewer

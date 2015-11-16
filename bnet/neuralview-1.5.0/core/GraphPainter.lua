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
-- Class that handles the painting of a feed-forward neural network graph.
local GraphPainter, GraphPainterMT = nv_module('core.GraphPainter')
local GREY = {0.9, 0.9, 0.9}
local RED = {0.65, 0.45, 0.45}
local BLUE = {0.45, 0.45, 0.65}
local BIAS = {0.8, 0.4, 0.4}

---
-- @name Color
-- @class table
-- @description RGB color representation (referenced in the draw_* methods).
-- @field 1 red (0 to 1)
-- @field 2 green (0 to 1)
-- @field 3 blue (0 to 1)

---
-- Constructor.
--
-- @param r Neuron radius (it's used as base for the other sizes too)
-- @return New instance of GraphPainter 
function GraphPainter.new(r)
    local self = {}
    setmetatable(self, GraphPainterMT)
    self.r = r or 30
    
    return self
end

---
-- Draws a neuron as a circle.
--
-- @param cr Cairo context to be used
-- @param xc x-center of the neuron 
-- @param yc y-center of the neuron
-- @param r radius of the neuron
-- @param color Color of the neuron (fill)
function GraphPainter:draw_neuron(cr, xc, yc, r, color)
    cr:arc(xc, yc, r, 0, 2 * math.pi)
    cr:set_source_rgb(unpack(color))
    cr:fill_preserve()
    cr:set_source_rgb(0.1, 0.1, 0.1)
    cr:stroke()
end

---
-- Draws a connection.
--
-- @param cr Cairo context to be used
-- @param x1 from x
-- @param y1 from y
-- @param x2 to x
-- @param y2 to y
-- @param w Connection width
-- @param color Connection color
function GraphPainter:draw_connection(cr, x1, y1, x2, y2, w, color)
    cr:set_source_rgb(unpack(color))
    cr:set_line_width(w)
    cr:move_to(x1, y1)
    cr:line_to(x2, y2)
    cr:stroke()
end

---
-- Calculates the sizes of the graph elements.
--
-- @param layer_array Array with number of neurons in each layer
-- @param zoom Zoom level of the graph ( default = 1 (100%) )
-- @param y_space Spacing between layers ( default = 1 (100%) )
-- @param show_bias To show the bias neurons too ( default = false )
-- @return width, height, zoom, y_space, new radius, max layer size, 
-- space ratio, border spacing
function GraphPainter:calc_size(layer_array, bias_array, zoom, y_space, show_bias)
    local zoom = zoom or 1
    local y_space = (y_space or 1) * 2
    local r = self.r * zoom
    
    local max_layer = 0
    
    -- get the biggest layer in the array
    for i, j in ipairs(layer_array) do
        if show_bias then j = j + bias_array[i] end
        if j > max_layer then max_layer = j end
    end
    
    local n_layers = #layer_array
    local space = r * 0.2
    local ratio = r * 3
    local diameter = r * 2
    
    -- calculate the total size (width and height)
    local total_dx = (n_layers * diameter) + ((n_layers - 1) * y_space
        * diameter) + 2 * space
    local total_dy = (max_layer * diameter) + (max_layer - 1) * r + 2 * space
    
    return total_dx, total_dy, zoom, y_space, r, max_layer, ratio, space
end

---
-- Draws the graph. Due to the massive number of connections, this can be
-- slow for real-time drawing.
--
-- @param cr Cairo context to use
-- @param layer_array Array with number of neurons in each layer
-- @param conn_array Array with the connections, in the FANN format
-- @param bias_array Array with the number of biases in each layer (0 or 1)
-- @param layer_color Table with the color of each layer (the colors can be nil
-- to use the default)
-- @param zoom Zoom level of the graph ( default = 1 (100%) )
-- @param y_space Spacing between layers ( default = 1 (100%) )
-- @param show_bias To show the bias neurons too ( default = false )
-- @param w_max Minimum connection weight (modulo) ( default = 1 )
-- @param bias_color The color of the bias neurons ( default = green )
-- @param pos_color 
-- @param neg_color 
function GraphPainter:draw_graph(cr, layer_array, conn_array, bias_array, layer_color, zoom,
    y_space, show_bias, w_max, bias_color, pos_color, neg_color)
    
    local total_dx, total_dy, zoom, y_space, r, max_layer, ratio, space = 
        self:calc_size(layer_array, bias_array, zoom, y_space, show_bias)
    
    -- colors
    local bias_color = bias_color or BIAS
    local pos_color = pos_color or BLUE
    local neg_color = neg_color or RED
    
    -- stores the position of each neuron (follows FANN sequence)
    local pos = {}
    
    -- layout params
    local n_layers = #layer_array
    cr:set_line_width(r / 8)
    
    -- draw the neurons
    local diameter = 2 * r
    local dx = space
    
    -- move the y_space, plus the space for the neuron itself
    local x_step = (y_space + 1) * diameter 
    local neuron_id = 1 -- next valid sequence number
    
    for x, n_neurons in ipairs(layer_array) do
        -- include the bias too
        local n_bias = bias_array[x]
        local aux = (n_bias > 0 and not show_bias) and 2 or 1 
        local n_neurons = n_neurons + n_bias
        local init = total_dy - ( (n_neurons - aux) * ratio + diameter)
        local dy = init / 2
        local y_step = ratio
        
        for y = 1, n_neurons do
            local draw, color
            
            if y == n_neurons and n_bias > 0 then
                -- its a bias
                if show_bias then
                    draw = true
                    color = BIAS
                end
            else
                -- not a bias
                draw = true
                color = layer_color[x] or GREY
            end
            
            if draw then
                -- store the neuron position to draw the connections in the future
                pos[neuron_id] = {dx + diameter, dy + r}
                self:draw_neuron(cr, dx + r, dy + r, r, color)
                dy = dy + y_step
            end
            
            neuron_id = neuron_id + 1
        end
        
        dx = dx + x_step
    end
    
    local w_full = r / 12
    local w_min = r / 36
    local f = w_full / w_max
    
    -- draw the connections
    for from, tbl in pairs(conn_array) do
        -- skip the bias
        if pos[from] then       
            local fx = pos[from][1]
            local fy = pos[from][2]
        
            for to, weight in pairs(tbl) do
                local tx = pos[to][1] - diameter
                local ty = pos[to][2]
                
                -- calculate the weight
                local pos = weight >= 0 
                local w = (pos and weight or -weight) * f
                if w < w_min then w = w_min end
                local color = pos and pos_color or neg_color
                self:draw_connection(cr, fx, fy, tx, ty, w, color)
            end
        end
    end
end

return GraphPainter

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
-- Provides an interface with gnuplot.
local Plot, PlotMT = nv_module('core.Plot')

-- Create only two tmp files
local tmpimg = Config.plot.tmpimg or os.tmpname()
local tmpdata = Config.plot.tmpdata or os.tmpname()

---
-- Saves the point to a temp file and returns the name of it.
local function generate_2d_data(points)
    local file = io.open(tmpdata, 'w')
    
    for i, j in ipairs(points) do
        file:write(i, ' ', j, '\n')
    end
    
    file:close()
    return tmpdata
end

local function set_labels(plot, x, y)
    plot:write('set xlabel "', x, '"\n')
    plot:write('set ylabel "', y, '"\n')
end

local function generate_image(plot)
    plot:write('set term png size 500, 500 font', Config.plot.font,'\n')
    plot:write('set output "' .. tmpimg .. '"\n')
    return tmpimg
end

---
-- Generates a line plot.
--
-- @param points Map<x,y>
-- @param data Legend of the data
-- @param x Legend of the x axis
-- @param y Legend of the y axis
-- @return Name of the generated image file
function Plot.line(points, data, x, y)
    local name = generate_2d_data(points)
    local plot = io.popen(Config.plot.bin, 'w')
    if not plot then return end
    
    -- set the labels
    set_labels(plot, x, y)
    
    -- create the image
    local img = generate_image(plot)
    plot:write('plot "', name, '" ti "', data ,'" with lines\n')
    plot:write('quit\n')
    plot:close()
    
    return img
end

return Plot

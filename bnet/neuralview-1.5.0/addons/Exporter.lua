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

local Exporter = {}

local Utils = require('view.Utils')

---
-- Information about the addon.
Exporter.info = {
    name = _"Exporter",
    description =  _"Exports the neural network and\ngenerates a simple program to use it.",
    authors = _"Lucas Hermann Negri",
    version = '1.0.0',
}

-- export types
local TYPE_NOTHING, TYPE_C, TYPE_LUA = 0, 1, 2

-- current state
local st = {}

local function build_dialog()
    st.dialog = gtk.Dialog.new()
    st.dialog:set('title', _"Exporter", 'transient-for', st.ctrl.menu.window,
        'icon', NVIcon)
    st.dialog:add_buttons('gtk-close', gtk.RESPONSE_CLOSE, 'gtk-ok', 
        gtk.RESPONSE_OK)
        
    local vbox = st.dialog:get_content_area()
    local tbl = gtk.Grid.new(2, 2, false)
    tbl:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    st.type_label = gtk.Label.new_with_mnemonic(_"Export _type")
    st.type_label:set('xalign', 1)
    
    st.type_model = gtk.ListStore.new('gchararray', 'gint')
    Utils.populate_model(st.type_model, {{_"C", TYPE_C}, {_"Lua", TYPE_LUA}, 
        {_"No code", TYPE_NOTHING}})
    st.type_combo = gtk.ComboBox.new_with_model(st.type_model)
    st.type_cell = gtk.CellRendererText.new()
    st.type_combo:pack_start(st.type_cell)
    st.type_combo:add_attribute(st.type_cell, 'text', 0)
    st.type_combo:set('active', 0)
    st.type_label:set('mnemonic-widget', st.type_combo, 'tooltip-text',
        _"Output type")
    st.iter = gtk.TreeIter.new()
    
    tbl:attach(st.type_label, 0, 0, 1, 1)
    tbl:attach(st.type_combo, 1, 0, 1, 1)
    
    st.fixed_label = gtk.Label.new_with_mnemonic(_"_Fixed point")
    st.fixed_label:set('xalign', 1)
    
    st.fixed_check = gtk.CheckButton.new()
    st.fixed_label:set('mnemonic-widget', st.fixed_check, 'tooltip-text',
        _"If the network will be exported using fixed point numbers")
    
    tbl:attach(st.fixed_label, 0, 1, 1, 1)
    tbl:attach(st.fixed_check, 1, 1, 1, 1)
    
    vbox:add(tbl)
    vbox:show_all()
end

local export_funcs = {
    [TYPE_LUA] = {ext = _".lua"},
    [TYPE_C] = {ext = _".c"},
}

export_funcs[TYPE_LUA].func = function(file, fixed, n_input, n_output, net_file)
    local code = [[
#! /usr/bin/env lua

-- load the library
require("lfann")

local n_input, n_output = %d, %d
local input, output = {}
local write, sf = io.write, string.format

-- load the network from the exported file
local net = fann.Net.create_from_file("%s")

-- test using the stdio (enter q to quit)
while true do
    local cont = true
    
    -- input
    for i = 1, n_input do
        local aux = io.read("*n")
        
        if not aux then
            cont = false
            break
        end
        
        input[i] = aux
    end
    
    if not cont then break end
    
    -- run the network
    output = net:run(input)
    
    -- output
    for i = 1, n_output do
        if i >  1 then write(" ") end
        write( sf("%s", output[i]) )
    end
    
    write("\n")
end
]]
    local iformat = fixed and '%d' or '%.6f'
    file:write( string.format(code, n_input, n_output, net_file, iformat) )
end

export_funcs[TYPE_C].func = function(file, fixed, n_input, n_output, net_file)
    local code = [[
#include <%s>

int main(int argc, char* argv[])
{
    int n_input = %d, n_output = %d, i;
    struct fann* net = fann_create_from_file("%s");
    fann_type input[n_input], *output;
    
    while(1)
    {
        /* input */
        for(i = 0; i < n_input; ++i)
            if(scanf("%s", &input[i]) != 1)
                goto _end;
        
        /* run */
        output = fann_run(net, input);
        
        /* output */
        for(i = 0; i < n_output; ++i)
        {
            if(i > 0) printf(" ");
            printf("%s", output[i]);
        }
        
        printf("\n");
    }
    
    _end:
    
    fann_destroy(net);
         
    return 0;
}
]]
    local header = fixed and 'fixedfann.h' or 'doublefann.h'
    local iformat = fixed and '%d' or '%lf'
    local oformat = fixed and '%d' or '%.6lf'
    file:write( string.format(code, header, n_input, n_output, net_file,
        iformat, oformat) )
end

local function export(exp_type, fixed, folder)
    -- save the project
    local prj = st.ctrl.project
    local res = prj:save(folder, true, fixed)
    assert(res)
    
    if exp_type ~= TYPE_NOTHING then
        local net = prj.network
        
        -- create some code
        local t = export_funcs[exp_type]
        local file = io.open(folder .. '/main' .. t.ext, 'w')
        local n_input = net:get_num_input()
        local n_output = net:get_num_output()
        
        t.func(file, fixed, n_input, n_output, prj['NET_FANN_NAME'])
        file:close()
    end
end

local function show_dialog(ctrl)
    if not st.dialog then
        build_dialog()
    end
    
    local res = st.dialog:run()
    
    while res == gtk.RESPONSE_OK do
        if not st.save_dlg then
            local FileDialog = require('view.FileDialog')
            
            st.save_dlg = FileDialog.new(st.dialog, _"Export project",
                gtk.FILE_CHOOSER_ACTION_CREATE_FOLDER)
        end
        
        local folder = st.save_dlg:run()
        
        if folder then
            st.type_combo:get_active_iter(st.iter)
            local exp_type = st.type_model:get(st.iter, 1)
            local fixed = st.fixed_check:get('active')
            
            -- Tell the listeners to save their data on self.project
            ctrl.event_source:send('project-will-save', ctrl.project)
            
            local res, msg = pcall(export, exp_type, fixed, folder)
            
            if not res then
                Utils.show_info(string.format(_"Couldn't export to %s", folder))
                io.stderr:write(msg, '\n')
            end
        end
        
        res = st.dialog:run()
    end
    
    st.dialog:hide()
end

function Exporter.load(ctrl)
    st.ctrl = ctrl
    
    st.button = Utils.new_tool_button('gtk-convert',
        _"_Exporter",
        _"Save the network for external use"
    )
        
    st.button:connect('clicked', show_dialog, ctrl)
    ctrl.menu:add_addon_button(st.button, true)
end

function Exporter.unload()
end

return Exporter

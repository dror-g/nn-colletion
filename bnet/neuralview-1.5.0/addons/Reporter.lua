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

local Reporter = {}

local Utils = require('view.Utils')
local FannNetwork = require('core.FannNetwork')

---
-- Information about the addon.
Reporter.info = {
    name = _"Reporter",
    description =  _"Generates reports about the\ncurrent project.",
    authors = _"Lucas Hermann Negri",
    version = '1.0.0',
}

local params = FannNetwork.params
local st = {}

local TYPE_HTML = 0
local sf, ti = string.format, table.insert

local function format(value)
    if type(value) == 'number' and math.floor(value) ~= value then
        if value < 0.000001 then
            return '< 0.000001'
        else
            return string.format('%.6f', value)
        end
    else
        return tostring(value)
    end
end

local function tableize(tbl)
    local html = {'<table>'}
    
    for i, pair in ipairs(tbl) do
        ti(html, '<tr>')
        ti(html, '<td>' .. pair.key .. '</td>')
        ti(html, '<td>' .. format(pair.value)  .. '</td>')
        ti(html, '</tr>')
    end
    
    ti(html, '</table>')
    
    return table.concat(html, '\n')
end

local export_funcs = {}

export_funcs[TYPE_HTML] = function(file, data)
    local body = {
        sf('<h1>%s</h1>', _'Project report'),
        sf('<h2>%s</h2>', _'Description'),
        '<p>', data.description, '<\p>',
        sf('<h2>%s</h2>', _'Topology'),
        tableize(data.topology),
        sf('<h2>%s</h2>', _'Training algorithm'),
        tableize(data.training_algorithm),
    }
    
    if data.weight_init then
        ti( body, sf('<h2>%s</h2>', _'Last weight initialization') )
        ti( body, tableize(data.weight_init) )
    end
    
    if data.training_params then
        ti( body, sf('<h2>%s</h2>', _'Last training params') )
        ti( body, tableize(data.training_params) )
    end
    
    if data.training_status then
        ti( body, sf('<h2>%s</h2>', _'Last training status') )
        ti( body, tableize(data.training_status) )
    end

    file:write( sf([[
<html>
    <head>
        <title>%s</title>
    </head>
    
    <body>
        %s
    </body>
</html>    
    ]], _'Project report', table.concat(body, '\n')) )
end

-- pair from parameter
local function getpair(param, net)
    return {
        key     = param.name,
        value     = param.get(net)
    }
end

local function export(exp_type, file)
    local prj = st.ctrl.project
    local net = prj.network
    
    -- extract the data
    local data = {}
    
    data.description = prj.description or ''
    
    data.topology = {
        getpair(params.network_type, net),
        getpair(params.connection_rate, net),
        getpair(params.total_neurons, net),
        getpair(params.total_connections, net),
        getpair(params.neurons_per_layer, net),
        getpair(params.bias_per_layer, net)
    }
    
    local algo = FannNetwork.algorithms[net:get_training_algorithm()]
    
    data.training_algorithm = {
        getpair(params.training_algorithm, net)
    }
    
    for i, j in ipairs(algo.params) do
        ti(data.training_algorithm, getpair(j, net) )
    end
    
    local tbl = prj.weight_init or {
        ["type"] = 'randomize',
        ["lower"] = -0.1,
        ["upper"] = 0.1,
    }
    
    if tbl.type == 'randomize' then
        data.weight_init = {
            {
                key     = _"Type",
                value     = _"Randomize",
            },
            {
                key     = _"Range",
                value     = sf( _"%.4f to %.4f", tbl.lower, tbl.upper ),
            },
        }
    else
        data.weight_init = {
            {
                key     = _"Type",
                value     = _"Nguyen-Widrow",
            }
        }
    end
    
    if prj.training_params then
        local tbl = prj.training_params
        
        data.training_params = {
            {
                key        = _"Stop function",
                value    = tbl.stop_func == fann.STOPFUNC_BIT and _"Bit limit"
                    or _"Mean squared error",
            },
            {
                key        = _"Desired error",
                value    = tbl.desired_error,
            },
            {
                key        = _"Bit fail limit",
                value    = tbl.bit_fail,
            },
            {
                key        = _"Max epochs",
                value    = tbl.max_epochs,
            },
            {
                key        = _"Epochs between reports",
                value    = tbl.rep_epochs,
            },
        }
    end
    
    if prj.training_status then
        local tbl = prj.training_status
        
        data.training_status = {
            {
                key        = _"Epoch",
                value    = tbl.epoch,
            },
            {
                key        = _"Mean squared error",
                value    = tbl.mse,
            },
            {
                key        = _"Bit fail",
                value    = tbl.bit,
            },
            {
                key        = _"Time elapsed (s)",
                value    = tbl.elapsed,
            },
        }
    end
        
    local file = io.open(file, 'w')
    export_funcs[exp_type](file, data)
    file:close()
end

function build_dialog()
    st.dialog = gtk.Dialog.new()
    st.dialog:set('title', _"Reporter", 'transient-for', st.ctrl.menu.window,
        'icon', NVIcon)
    st.dialog:add_buttons('gtk-close', gtk.RESPONSE_CLOSE, 'gtk-ok', 
        gtk.RESPONSE_OK)
        
    local vbox = st.dialog:get_content_area()
    local tbl = gtk.Grid.new(1, 2, false)
    tbl:set('column-spacing', NVSpacing, 'row-spacing', NVSpacing)
    
    st.iter = gtk.TreeIter.new()
    st.type_label = gtk.Label.new_with_mnemonic(_"Export _type")
    st.type_model = gtk.ListStore.new('gchararray', 'gint')
    Utils.populate_model(st.type_model, { {_"HTML", TYPE_HTML} } )
    st.type_combo = gtk.ComboBox.new_with_model(st.type_model)
    st.type_cell = gtk.CellRendererText.new()
    st.type_combo:pack_start(st.type_cell)
    st.type_combo:add_attribute(st.type_cell, 'text', 0)
    st.type_combo:set('active', 0)
    st.type_label:set('mnemonic-widget', st.type_combo, 'tooltip-text',
        _"Output type")
        
    tbl:attach(st.type_label, 0, 0, 1, 1)
    tbl:attach(st.type_combo, 1, 0, 1, 1)
    
    vbox:pack_start(tbl)
    vbox:show_all()
end

function show_dialog(ctrl)
    if not st.dialog then
        build_dialog()
    end
    
    local res = st.dialog:run()
    
    while res == gtk.RESPONSE_OK do
        if not st.save_dlg then
            local FileDialog = require('view.FileDialog')
        
            st.save_dlg = FileDialog.new(st.dialog, _"Generate report",
                gtk.FILE_CHOOSER_ACTION_SAVE, {
                    {id = TYPE_SVG, name = _"HTML page", ext = '.html'}
                })
        end
        
        local file = st.save_dlg:run()
        
        if file then
            st.type_combo:get_active_iter(st.iter)
            local exp_type = st.type_model:get(st.iter, 1)
            
            -- Tell the listeners to save their data on self.project
            ctrl.event_source:send('project-will-save', ctrl.project)
            
            local res, msg = pcall(export, exp_type, file)
            
            if not res then
                Utils.show_info(string.format(_"Couldn't export to %s", file))
                io.stderr:write(msg, '\n')
            end
        end
        
        res = st.dialog:run()
    end
    
    st.dialog:hide()
end

function Reporter.load(ctrl)
    st.ctrl = ctrl
    
    st.button = Utils.new_tool_button('gtk-file', 
        _"_Reporter",
        _"Generate reports about the current project"
    )
    st.button:connect('clicked', show_dialog, ctrl)
    
    ctrl.menu:add_addon_button(st.button, true)
end

function Reporter.unload()
end

return Reporter

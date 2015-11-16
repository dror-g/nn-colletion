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
-- Libraries and definitions that are pushed to the global 'namespace'. 

---
-- module definition
function nv_module(name)
    local mod_tbl = {}
    return mod_tbl, {__index = mod_tbl}
end

-- basic libraries (other libraries are loaded on demand) 
require('lgob.gtk')
require('lgob.gdk') 
require('lgob.cairo')
require('lfann')
require('lcl')

_ = lcl.gettext
lcl.bindtextdomain('neuralview', 'po')
lcl.bindtextdomain_codeset('neuralview', 'UTF-8')

NVVersion = '1.5.0'
NVIcon    = gdk.Pixbuf.new_from_file('logo.png')
NVAuthors = {
    'Lucas Hermann Negri <lucashnegri@gmail.com>',
    'Gabriel Hermann Negri <negri.gabriel@gmail.com>'
}
NVSpacing = 5

Config = require('Config')

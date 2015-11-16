#! /usr/bin/env lua5.1

--[[
    Extracts strings marked for translation, _"string", to a fake C header.
    Like an intltool-extract for Lua.
    
    @usage lua5.1 po/Extract.lua *.lua view/*.lua > po/header.h 

    @author Lucas Hermann Negri
--]]

-- Set of translation strings
local trans = {}
local sf = string.format

-- Read the input files
for index = 1, #arg do
    -- Extraction
    local input = io.open(arg[index])

    for line in input:lines() do
        for match in line:gmatch('_(["%[].-[%]"])') do
            trans[match] = true
        end
    end
    
    input:close()
end

-- Messages
for msg, j in pairs(trans) do
    print(sf([[char* s = N_(%s);]], msg))
end


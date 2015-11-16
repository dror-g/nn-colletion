#! /usr/bin/env lua

-- to be used from the root dir

local cmd = arg[1]
local lang = arg[2]
local ex  = function(a) print(a) os.execute(a) end

if lang == 'all' then
    langs = {
        'pt_BR',
    }
else
    langs = {lang}
end

if cmd == 'create' then
    ex('lua po/Extract.lua core/*.lua view/*.lua addons/*.lua MainApp.lua > po/header.h')
    ex('xgettext --from-code=utf-8 -kN_  -o po/messages.pot po/header.h')
    
    for i, lang in ipairs(langs) do
        ex('msginit -i po/messages.pot -l po/' .. lang)
        ex('mkdir -p po/' .. lang .. '/LC_MESSAGES')
        ex('msgfmt po/' .. lang .. '.po -o po/' .. lang .. '/LC_MESSAGES/neuralview.mo')
    end
    
elseif cmd == 'update' then
    ex('lua po/Extract.lua core/*.lua view/*.lua addons/*.lua MainApp.lua > po/header.h')
    ex('xgettext --from-code=utf-8 -kN_  -o po/messages.pot po/header.h')

    for i, lang in ipairs(langs) do
        ex('msgmerge -U po/' .. lang .. '.po po/messages.pot')
        ex('mkdir -p po/' .. lang .. '/LC_MESSAGES')
        ex('msgfmt po/' .. lang .. '.po -o po/' .. lang .. '/LC_MESSAGES/neuralview.mo')
    end
    
elseif cmd == 'clean' then
    ex('rm -rf po/header.h po/messages.pot po/*.po~')
    for _, lang in ipairs(langs) do
        ex('rm -rf po/' .. lang)
    end
else
    print('Usage: ./makepo.lua command lang')
end

print('End.')

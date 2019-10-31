-- TODO work on this
-- Support for : Colors | Styles
-- Minetest :    Yes    | No
-- IRC :         Yes    | Yes
-- Discord :     No     | Yes

-- Assumptions : 
-- 1. IRC users only use IRC formatting chars and don't rely on Markdown
-- 2. Minetest users only use Minetest color codes + Markdown
-- 3. Discord users only rely on Markdown
-- Note : Markdown means Discord Markdown

-- Resulting conversions :
-- Minetest colors -> IRC colors
-- IRC colors -> Minetest colors
-- Discord styles -> IRC styles
-- IRC styles -> Discord styles

-- Resources : 
-- https://modern.ircdocs.horse/formatting.html
-- https://support.discordapp.com/hc/en-us/articles/210298617-Markdown-Text-101-Chat-Formatting-Bold-Italic-Underline-
-- https://github.com/minetest/minetest/blob/master/doc/lua_api.txt

-- Notes: 
-- While code ("`code`") to IRC is straightforward (monospace), monospace to code is undefined behavior (concat code blocks? no code blocks at all?)

local function is_digit(char)
    return char >= "0" and char <= "9"
end

local md_escape={
    ["*"]=true, ["_"]=true, ["~"]=true, ["`"]=true, ["\\"]=true, ["|"]=true
}

function escape_markdown(text)
    local res={}
    for i=1, text:len() do
        local char=text:sub(i,i)
        if md_escape[char] then
            table.insert(res, "\\")
        end
        table.insert(res, char)
    end
    return table.concat(res)
end

-- minetest characters: color starter
local minetest_color_starter=string.char(0x1b)

-- irc characters
local irc_escape_code=string.char(0x02)..string.char(0x02)
local irc_disable=string.char(0x0F)
local irc_color_reverse=string.char(0x16)
local irc_color_starter=string.char(0x03)
local irc_hex_color_starter=string.char(0x04)
local irc_bold=string.char(0x02)
local irc_italics=string.char(0x1D)
local irc_underlined=string.char(0x1F)
local irc_strikethrough=string.char(0x1F)
local irc_monospace=string.char(0x11)

-- Converts Discord-style Markdown to IRC format
local irc_style_to_md={
    [irc_bold]="**", -- Bold
    [irc_italics]="*", -- Italics
    [irc_underlined]="__", -- Underlined
    [irc_strikethrough]="~~", -- Strikethrough
}

local md_style_to_irc=table_ext.flip(irc_style_to_md)

local irc_escape={
    [irc_bold]=true, [irc_italics]=true, [irc_underlined]=true, [irc_strikethrough]="~~", [irc_disable]=true, [irc_color_reverse]=true, [irc_monospace]=true
}

local function skip_color_code(text, i)
    for j=1,2 do
        if is_digit(text:sub(i+1,i+1)) then
            i=i+1
        end
    end
    if text:sub(i+1,i+1) == "," and is_digit(text:sub(i+1,i+1)) then
        i=i+1
        if is_digit(text:sub(i+1,i+1)) then
            i=i+1
        end
    end
    return i
end

function escape_irc(text)
    local res={}
    local i=1
    while i <= text:len() do
        local char=text:sub(i,i)
        if char == irc_color_starter then
            i=skip_color_code(text, i)
        elseif char == irc_hex_color_starter then
            i=i+6
        elseif not irc_escape[char] then
            table.insert(res, char)
        end
        i=i+1
    end
    return table.concat(res)
end

md_style_to_irc["_"]=md_style_to_irc["*"]

local markdown_trie = trie.new()
for tag, toggle in pairs(md_style_to_irc) do
    trie.insert(markdown_trie, tag, {name=tag, reversed=tag, opening=toggle, closing=toggle, space_sensitive=true})
end
trie.insert(markdown_trie, "||", {name="||", reversed="||", opening=irc_color_starter.."01,01", closing=irc_color_starter, escape_func=is_digit})
trie.insert(markdown_trie, "***", {name="***", reversed="***", opening=irc_italics..irc_bold, closing=irc_italics..irc_bold,
    space_sensitive=true, conversion={
        ["*"]={name="**", reversed=irc_italics.."**", opening=irc_italics..irc_bold, closing=irc_bold},
        ["**"]={name="*", reversed=irc_bold.."*", opening=irc_italics..irc_bold, closing=irc_italics}
    }
})
trie.insert(markdown_trie, "___", {reversed="___", opening=irc_underlined..irc_italics, closing=irc_underlined..irc_italics,
    space_sensitive=true, conversion={
        ["_"]={name="__", reversed=irc_italics.."__", opening=irc_italics..irc_underlined, closing=irc_underlined},
        ["__"]={name="_", reversed=irc_underlined.."_", opening=irc_underlined..irc_italics, closing=irc_italics}
    }
})

local markdown_code_tag="`"

-- Strips Markdown for Minetest. Won't strip invalid Markdown (like 1*1=2)
function strip_markdown(markdown)
    local i=1
    local res={}
    local tags={}
    while i <= markdown:len() do
        local char = markdown:sub(i,i)
        if char == markdown_code_tag then
            local closing = markdown:find("[^\\]`", i+1)
            if closing then
                table.insert(res, markdown:sub(i+1, closing))
                i=closing+1
                goto continue
            end
        elseif char == "\\" and md_escape[markdown:sub(i+1,i+1)] then
            table.insert(res, markdown:sub(i+1,i+1))
            i=i+1
            goto continue
        elseif char == " " then
            if res[#res] and res[#res].space_sensitive then
                res[#res] = res[#res].reversed
                table.remove(tags)
            end
        else
            local tag, offset = trie.find_longest(markdown_trie, markdown, i)
            if tag then
                for index, tag_index in table_ext.rpairs(tags) do
                    local conversion = res[tag_index].conversion and res[tag_index].conversion[tag.name]
                    if res[tag_index].name == tag.name or conversion then
                        if tag.space_sensitive and markdown:sub(i-1,i-1) == " " then
                            table.insert(res, tag.reversed)
                        else
                            local index_2 = #tags
                            while index_2 > index do
                                local tag_index_2 = tags[index_2]
                                res[tag_index_2] = res[tag_index_2].reversed
                                table.remove(tags)
                                index_2 = index_2 - 1
                            end
                            if conversion then
                                res[tag_index] = conversion
                            else
                                table.remove(tags)
                                res[tag_index] = ""
                            end
                        end
                        i=offset
                        goto continue
                    end
                end
                table.insert(res, tag)
                table.insert(tags, #res)
                i=offset
                goto continue
            end
        end
        table.insert(res, char)
        ::continue::
        i=i+1
    end
    for _, tag in pairs(tags) do
        if res[tag].reversed then
            res[tag]=res[tag].reversed
        end
    end
    return table.concat(res)
end

function markdown_to_irc(markdown)
    local i=1
    local res={}
    local tags={}
    while i <= markdown:len() do
        local char = markdown:sub(i,i)
        if char == markdown_code_tag then
            local closing = markdown:find("[^\\]`", i+1)
            if closing then
                table.insert(res, irc_monospace)
                table.insert(res, markdown:sub(i+1, closing))
                table.insert(res, irc_monospace)
                i=closing+1
                goto continue
            end
        elseif char == "\\" and md_escape[markdown:sub(i+1,i+1)] then
            table.insert(res, markdown:sub(i+1,i+1))
            i=i+1
            goto continue
        elseif char == " " then
            if res[#res] and res[#res].space_sensitive then
                res[#res] = res[#res].reversed
                table.remove(tags)
            end
        else
            local tag, offset = trie.find_longest(markdown_trie, markdown, i)
            if tag then
                for index, tag_index in table_ext.rpairs(tags) do
                    local conversion = res[tag_index].conversion and res[tag_index].conversion[tag.name]
                    if res[tag_index].name == tag.name or conversion then
                        if tag.space_sensitive and markdown:sub(i-1,i-1) == " " then
                            table.insert(res, tag.reversed)
                        else
                            local index_2 = #tags
                            while index_2 > index do
                                local tag_index_2 = tags[index_2]
                                res[tag_index_2] = res[tag_index_2].reversed
                                table.remove(tags)
                                index_2 = index_2 - 1
                            end
                            if conversion then
                                res[tag_index] = conversion
                            else
                                table.remove(tags)
                                res[tag_index] = res[tag_index].opening
                            end
                            table.insert(res, tag.closing)
                            if tag.escape_func and tag.escape_func(markdown:sub(offset+1,offset+1)) then
                                table.insert(res, irc_escape_code)
                            end
                        end
                        i=offset
                        goto continue
                    end
                end
                table.insert(res, tag)
                table.insert(tags, #res)
                i=offset
                goto continue
            end
        end
        table.insert(res, char)
        ::continue::
        i=i+1
    end
    for _, tag in pairs(tags) do
        if res[tag].reversed then
            res[tag]=res[tag].reversed
        end
    end
    return table.concat(res)
end

-- Converts Markdown to IRC
function markdown_to_irc(markdown)
    local i=1
    local res={}
    local tags={}
    while i <= markdown:len() do
        local char = markdown:sub(i,i)
        if char == markdown_code_tag then
            local closing = markdown:find("[^\\]`", i+1)
            if closing then
                table.insert(res, irc_monospace)
                table.insert(res, markdown:sub(i+1, closing))
                table.insert(res, irc_monospace)
                i=closing+1
                goto continue
            end
        elseif char == "\\" and md_escape[markdown:sub(i+1,i+1)] then
            table.insert(res, markdown:sub(i+1,i+1))
            i=i+1
            goto continue
        elseif char == " " then
            if res[#res] and res[#res].space_sensitive then
                res[#res] = res[#res].reversed
                table.remove(tags)
            end
        else
            local tag, offset = trie.find_longest(markdown_trie, markdown, i)
            if tag then
                for index, tag_index in table_ext.rpairs(tags) do
                    local conversion = res[tag_index].conversion and res[tag_index].conversion[tag.name]
                    if res[tag_index].name == tag.name or conversion then
                        if tag.space_sensitive and markdown:sub(i-1,i-1) == " " then
                            table.insert(res, tag.reversed)
                        else
                            local index_2 = #tags
                            while index_2 > index do
                                local tag_index_2 = tags[index_2]
                                res[tag_index_2] = res[tag_index_2].reversed
                                table.remove(tags)
                                index_2 = index_2 - 1
                            end
                            if conversion then
                                res[tag_index] = conversion
                            else
                                table.remove(tags)
                                res[tag_index] = res[tag_index].opening
                            end
                            table.insert(res, tag.closing)
                            if tag.escape_func and tag.escape_func(markdown:sub(offset+1,offset+1)) then
                                table.insert(res, irc_escape_code)
                            end
                        end
                        i=offset
                        goto continue
                    end
                end
                table.insert(res, tag)
                table.insert(tags, #res)
                i=offset
                goto continue
            end
        end
        table.insert(res, char)
        ::continue::
        i=i+1
    end
    for _, tag in pairs(tags) do
        if res[tag].reversed then
            res[tag]=res[tag].reversed
        end
    end
    return table.concat(res)
end

-- Converts IRC text modifiers to Discord markdown, escaping included
function irc_to_markdown(irc)
    local res={}
    local active={}
    local i=1
    while i <= irc:len() do
        local char=irc:sub(i,i)
        local md=irc_style_to_md[char]
        if md then
            while irc:sub(i+1)==" " do
                table.insert(res, " ")
                i=i+1
            end
            for index, open_md in table_ext.rpairs(active) do
                if open_md == md then
                    table.remove(active, index)
                    local i=#res
                    while res[i] == " " do
                        i=i-1
                    end
                    table.insert(res, i+1, md)
                    goto noinsert
                end
            end
            table.insert(active, md)
            table.insert(res, md)
            ::noinsert::
        elseif char == irc_disable then
            for _, md in table_ext.rpairs(active) do
                table.insert(res, md)
            end
            active={}
        elseif md_escape[char] then
            table.insert(res, "\\")
        elseif char == irc_color_starter then --color
            if irc:sub(i+2, i+2) == "," then
                if is_digit(irc:sub(i+1, i+1)) and irc:sub(i+1, i+1) == irc:sub(i+3, i+3) and not is_digit(irc:sub(i+4, i+4)) then
                    table.insert(active, "||")
                    table.insert(res, md)
                end
            elseif irc:sub(i+3, i+3) == "," then
                local fg, bg = irc:sub(i+1, i+2), irc:sub(i+4, i+5)
                if is_digit(irc:sub(i+1, i+1)) and is_digit(irc:sub(i+2, i+2)) and fg == bg and fg ~= "99" then
                    table.insert(active, "||")
                    table.insert(res, md)
                end
            else
                for index, open_md in table_ext.rpairs(active) do
                    if open_md == "||" then
                        table.remove(active, index)
                        local j=#res
                        while res[j] == " " do
                            j=j-1
                        end
                        table.insert(res, j+1, md)
                    end
                end
            end
            i=skip_color_code(text, i)
        else
            table.insert(res, char)
        end
        i=i+1
    end
    for _, thing in table_ext.rpairs(active) do
        table.insert(res, thing)
    end
    return table.concat(res)
end

-- Converts IRC colors to Minetest colors, background colors included
local user_defined_colors={'000000','0000FF','00FF00','FF0000', '654321','FF00FF','FFA500','FFFF00',
'90EE90','00FFFF','E0FFFF','ADD8E6','FF69B4','808080','D3D3D3'}
user_defined_colors[0]='FFFFFF'
local conversion_table={[16]='470000',[17]='472100',[18]='474700',[19]='324700',[20]='004700',[21]='00472c',[22]='004747',[23]='002747',[24]='000047',[25]='2e0047',[26]='470047',[27]='47002a',[28]='740000',[29]='743a00',[30]='747400',[31]='517400',[32]='007400',[33]='007449',[34]='007474',[35]='004074',[36]='000074',[37]='4b0074',[38]='740074',[39]='740045',[40]='b50000',[41]='b56300',[42]='b5b500',[43]='7db500',[44]='00b500',[45]='00b571',[46]='00b5b5',[47]='0063b5',[48]='0000b5',[49]='7500b5',[50]='b500b5',[51]='b5006b',[52]='ff0000',[53]='ff8c00',[54]='ffff00',[55]='b2ff00',[56]='00ff00',[57]='00ffa0',[58]='00ffff',[59]='008cff',[60]='0000ff',[61]='a500ff',[62]='ff00ff',[63]='ff0098',[64]='ff5959',[65]='ffb459',[66]='ffff71',[67]='cfff60',[68]='6fff6f',[69]='65ffc9',[70]='6dffff',[71]='59b4ff',[72]='5959ff',[73]='c459ff',[74]='ff66ff',[75]='ff59bc',[76]='ff9c9c',[77]='ffd39c',[78]='ffff9c',[79]='e2ff9c',[80]='9cff9c',[81]='9cffdb',[82]='9cffff',[83]='9cd3ff',[84]='9c9cff',[85]='dc9cff',[86]='ff9cff',[87]='ff94d3',[88]='000000',[89]='131313',[90]='282828',[91]='363636',[92]='4d4d4d',[93]='656565',[94]='818181',[95]='9f9f9f',[96]='bcbcbc',[97]='e2e2e2',[98]='ffffff'}
function hex_to_table(color)
    return {tonumber(color:sub(1, 2), 16), tonumber(color:sub(3, 4), 16), tonumber(color:sub(5, 6), 16)}
end
function table_to_hex(color)
    return string.format("%02X", color[1])..string.format("%02X", color[2])..string.format("%02X", color[3])
end
table_ext.add_all(conversion_table, user_defined_colors)
local reversed = table_ext.flip(conversion_table)
for k, v in pairs(reversed) do
    reversed[string.upper(k)]=v
    reversed[string.lower(k)]=v
end
reversed.FFFFFF=0
reversed.ffffff=0

function irc_to_minetest(irc)
    local fg, background
    local reversed = false
    local rope={}
    local i=1
    while i <= irc:len() do
        local char = irc:sub(i,i)
        if char == irc_color_starter then
            local j=i+1
            if is_digit(irc:sub(j,j)) then
                fg=irc:byte(j,j)-string.byte("0")
                i=j
                j=j+1
                if is_digit(irc:sub(j,j)) then
                    fg=fg*10+(irc:byte(j,j)-string.byte("0"))
                    i=j
                    j=j+1
                end
                local bg
                if irc:sub(j,j) == "," and is_digit(irc:sub(j+1,j+1)) then
                    local bg=irc:byte(j,j)-string.byte("0")
                    i=j
                    j=j+1
                    if is_digit(irc:sub(j,j)) then
                        bg=bg*10+(irc:byte(j,j)-string.byte("0"))
                        i=j
                    end
                end
                if bg then
                    -- no proper implementation for background escape sequences yet - see the "Escape sequences" part of the Lua API
                    -- table.insert(rope, minetest.get_background_escape_sequence("#"..conversion_table[bg]))
                    background = bg
                end
                if reversed then
                    table.insert(rope, minetest.get_color_escape_sequence("#"..conversion_table[bg]))
                else
                    table.insert(rope, minetest.get_color_escape_sequence("#"..conversion_table[fg]))
                end
            else
                table.insert(rope, minetest.get_color_escape_sequence("#FFFFFF"))
            end
        elseif char == irc_disable then
            table.insert(rope, minetest.get_color_escape_sequence("#FFFFFF"))
            background = nil
        elseif char == irc_color_reverse then
            reversed = not reversed
            if background then
                table.insert(rope, minetest.get_color_escape_sequence("#"..conversion_table[background]))
                -- no proper implementation for background escape sequences yet - see the "Escape sequences" part of the Lua API
                -- table.insert(rope, minetest.get_background_escape_sequence("#"..conversion_table[fg]))
                background, fg = fg, background
            end
        elseif not irc_style_to_md[char] and char ~= irc_monospace then
            table.insert(rope, char)
        end
        i=i+1
    end
    return table.concat(rope)
end

local color_conv = bridges.irc.convert_minetest_colors

if color_conv == "hex" then -- always use hex, no matter what
    function convert_color_to_irc(color)
        return nil, irc_hex_color_starter..color
    end
elseif color_conv == "hex_safer" then
    function convert_color_to_irc(color)
        -- prefer simple colors
        local rev = reversed[color]
        if rev then
            return ",", irc_color_starter..((rev < 10 and "0") or "")..tostring(rev)
        end
        return nil, irc_hex_color_starter..color
    end
elseif color_conv == "disabled" then
    function convert_color_to_irc(color)
        return error("Color conversion to IRC is disabled. Check your config.")
    end
else
    local color_chooser
    if color_conv == "safest" then
        local closest_color_basic = closest_color_finder(table_ext.process(user_defined_colors, function(k, color) return hex_to_table(color) end))
        color_chooser = closest_color_basic
    else
        local closest_color_extended = closest_color_finder(table_ext.process(conversion_table, function(k, color) return hex_to_table(color) end))
        color_chooser = closest_color_extended
    end
    function convert_color_to_irc(color)
        local rev = reversed[color]
        if rev and rev <= 15 then
            return function(c) return c=="," end, irc_color_starter..((rev < 10 and "0") or "")..tostring(reversed[color])
        end
        local closest = reversed[table_to_hex(color_chooser(hex_to_table(color)))]
        if not closest then error(table_to_hex(color_chooser(hex_to_table(color)))) end
        return function(c) return c=="," end, irc_color_starter..((closest < 10 and "0") or "")..tostring(closest)
    end
end

local old_convert_color_to_irc = convert_color_to_irc
function convert_color_to_irc(color)
    if color:lower() == "ffffff" then -- treat white as color reset, by default. TODO think of doing the same for close colors (can we?)
        return function(c) return c >= "0" and c <= "9" end, irc_color_starter
    end
    return old_convert_color_to_irc(color)
end

function minetest_to_irc(message)
    local i=1
    local res={}
    while i <= message:len() do
        if message:sub(i,i) == minetest_color_starter and message:sub(i+1, i+4) == "(c@#" and message:sub(i+11, i+11) == ")" then
            local color = message:sub(i+5, i+10)
            for j=1, 6 do
                local c = color:sub(j, j):lower()
                if not (c >= "0" and c <= "9") and not (c >= "a" and c <= "f") then
                    goto continue
                end
            end
            local needs_escape, color = convert_color_to_irc(color)
            table.insert(res, color)
            if needs_escape and needs_escape(message:sub(i+12, i+12)) then
                table.insert(res, irc_escape_code)
            end
            i=i+11
            goto continue_loop
            ::continue::
        end
        table.insert(res, message:sub(i,i))
        ::continue_loop::
        i=i+1
    end
    return table.concat(res)
end
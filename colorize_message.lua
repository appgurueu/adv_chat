-- Converts "#XXXXXX" color codes to colors
function colorize_message(message)
    local rope={}
    --IFNDEF discord
    local otherrope={}
    --ENDIF
    local function append_character(c)
        table.insert(rope, c)
        --IFNDEF discord
        table.insert(otherrope, c)
        --ENDIF
    end
    local i=1
    while i <= message:len() do
        local c=message:sub(i,i)
        if c == string.char(0x1b) and message:sub(i+1, i+4) == "(c@#" and message:sub(i+11, i+11) == ")" then
            table.insert(rope, message:sub(i, i+11))
            i=i+11
        elseif c == "#" then
            local color = true
            for j=i+1, i+6 do
                local c2=message:sub(j,j):upper()
                if c2=="" or not ((c2 >= "0" and c2 <= "9") or (c2 >= "A" and c2 <= "F")) then
                    color = false
                    break
                end
            end
            if color then
                table.insert(rope, minetest.get_color_escape_sequence(message:sub(i, i+6)))
                i=i+6
            else
                append_character(c)
            end
        else
            append_character(c)
        end
        i=i+1
    end
    return table.concat(rope)
    --IFNDEF discord
    , table.concat(otherrope)
    --ENDIF
end

load_schemes()
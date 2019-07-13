function colorize_message(message)
    local rope={}
    --IFNDEF bridge
    local otherrope={}
    --ENDIF
    local last_index=1
    for i=1, string.len(message) do
        local c=string.byte(message:sub(i,i))
        if c == hashtag then
            for j=i+1, i+6 do
                local c2=string.byte(string.upper(message:sub(j,j)))
                if c2:len() == 0 or not string_ext.is_hexadecimal(c2) then
                    i=j
                    goto nocolor
                end
            end
            local colorstring=minetest.get_color_escape_sequence(string.sub(message, i, i+6))
            table.insert(rope, message:sub(last_index, i-1))
            --IFNDEF bridge
            table.insert(otherrope, message:sub(last_index, i-1))
            --ENDIF
            table.insert(rope, colorstring)
            last_index=i+7
            ::nocolor::
        end
    end
    table.insert(rope, message:sub(last_index))
    --IFNDEF bridge
    table.insert(otherrope, message:sub(last_index))
    --ENDIF
    return table.concat(rope, "")
    --IFNDEF bridge
    , table.concat(otherrope, "")
    --ENDIF
end
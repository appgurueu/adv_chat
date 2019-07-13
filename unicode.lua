unicode_patterns={"\\u","U%+"}

function parse_utf8_codepoints(message, pattern)
    local last_index=0
    local begin,index=string.find(message,pattern)
    local rope={}
    while index do
        local number=""
        while index <= index+4 do
            index=index+1
            local char=string.upper(string.sub(message, index,index))
            if char:len() == 0 or not string_ext.is_hexadecimal(string.byte(char)) then
                break
            end
            number=number..char
        end
        number=tonumber(number, 16)
        local utf_8_char=string_ext.utf8(number)
        if utf_8_char then
            table.insert(rope, message:sub(last_index, begin-1))
            table.insert(rope, utf_8_char)
            last_index=index
        end
        begin,index=string.find(message,pattern, index)
    end
    table.insert(rope, message:sub(last_index))
    return table.concat(rope, "")
end

function parse_unicode(message)
    for _, pattern in pairs(unicode_patterns) do
        message=parse_utf8_codepoints(message, pattern)
    end
    return message
end
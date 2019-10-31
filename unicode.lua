unicode_patterns={"\\u","U+"}

function parse_utf8_codepoints(message, pattern)
    local last_index=0
    local begin,index=string.find(message,pattern,0,true)
    local rope={}
    while index do
        local number=""
        local i=index
        while i <= i+4 do
            i=i+1
            local char=string.upper(string.sub(message,i,i))
            if char == "" or not ((char >= "0" and char <= "9") or (char >= "A" and char <= "F")) then
                break
            end
            number=number..char
        end
        number=tonumber(number, 16)
        if number then
            local utf_8_char=string_ext.utf8(number)
            if utf_8_char then
                table.insert(rope, message:sub(last_index, begin-1))
                table.insert(rope, utf_8_char)
                last_index=i
            end
        end
        begin,index=string.find(message,pattern,index,true)
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
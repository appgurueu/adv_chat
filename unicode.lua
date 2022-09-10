local function unicode_char(hex_str)
	local codepoint = tonumber(hex_str, 0x10)

	local C0_control = (codepoint >= 0 and codepoint <= 0x1F) or codepoint == 0x7F
	local C1_control = codepoint >= 0x80 and codepoint <= 0x9F
	local surrogate = codepoint >= 0xD800 and codepoint <= 0xDFFF
	local non_unicode = codepoint > 0x10FFFF

	if not (C0_control or C1_control or surrogate or non_unicode) then
		return modlib.utf8.char(codepoint)
	end
end

function parse_unicode(message)
    return message:gsub("\\u(%x+)", unicode_char):gsub("U%+(%x+)", unicode_char)
end

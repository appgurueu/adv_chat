adv_chat={}
extend_mod("adv_chat", "conf")

-- Some IFNDEFS hehe
local bridge_ifndefs={
    bridge=adv_chat.bridges.discord or adv_chat.bridges.irc,
    discord=adv_chat.bridges.discord,
    irc=adv_chat.bridges.irc
}

if not bridge_ifndefs.bridge then
    error("OOF")
end

extend_mod_string("adv_chat", string_ext.handle_ifndefs(file_ext.read(get_resource("adv_chat", "colorize_message.lua")), bridge_ifndefs))

if bridge_ifndefs.bridge then
    adv_chat.scheme.other=adv_chat.scheme.other or {}
    for k, v in pairs(adv_chat.scheme.minetest) do
        local mt_msg, msg=adv_chat.colorize_message(v)
        adv_chat.scheme.minetest[k]=mt_msg
        if not adv_chat.scheme.other[k] then
            adv_chat.scheme.other[k]=msg
        end
    end
else
    for k, v in pairs(adv_chat.scheme.minetest) do
        local mt_msg=adv_chat.colorize_message(v)
        adv_chat.scheme.minetest[k]=mt_msg
    end
end

extend_mod_string("adv_chat", string_ext.handle_ifndefs(file_ext.read(get_resource("adv_chat", "main.lua")), bridge_ifndefs))

-- Basic API stuff
extend_mod("adv_chat", "unicode")
extend_mod("adv_chat", "hud_channels")

-- Chat bridges
if adv_chat.bridges.irc then
    extend_mod("adv_chat", "irc")
end

if adv_chat.bridges.discord then
    extend_mod("adv_chat", "discord")
end

-- Tests - don't uncomment unless you actually want to test something
--[[
-- -- -- extend_mod("adv_chat", "test")
]]
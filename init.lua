adv_chat={}
extend_mod("adv_chat", "conf")

-- Some IFNDEFS hehe
local bridge_ifndefs={
    bridge=adv_chat.bridges.discord or adv_chat.bridges.irc,
    discord=adv_chat.bridges.discord,
    irc=adv_chat.bridges.irc
}

extend_mod_string("adv_chat", string_ext.handle_ifndefs(file_ext.read(get_resource("adv_chat", "colorize_message.lua")), bridge_ifndefs))

extend_mod_string("adv_chat", string_ext.handle_ifndefs(file_ext.read(get_resource("adv_chat", "main.lua")), bridge_ifndefs))

-- Basic API stuff
extend_mod("adv_chat", "unicode")
extend_mod("adv_chat", "closest_color")
extend_mod("adv_chat", "trie")
extend_mod("adv_chat", "text_styles")
extend_mod("adv_chat", "message")
extend_mod("adv_chat", "hud_channels")

-- Chat bridges
if bridge_ifndefs.bridge then
    extend_mod("adv_chat", "chatcommands")
    extend_mod("adv_chat", "process_bridges")
    
    local env = minetest.request_insecure_environment() or error("Error: adv_chat needs to be added to the trusted mods for chat bridges to work. See the Readme for more info.")
    adv_chat.set_os_execute(env.os.execute)
    adv_chat.set_socket(env.require("socket"))

    if adv_chat.bridges.irc then
        extend_mod("adv_chat", "irc")
    end
    
    if adv_chat.bridges.discord then
        extend_mod("adv_chat", "discord")
    end

    adv_chat.build_socket_bridge = nil
    adv_chat.build_file_bridge = nil
    adv_chat.build_bridge = nil
end

-- Tests - don't uncomment unless you actually want to test something
--[[
-- -- -- extend_mod("adv_chat", "test")
]]
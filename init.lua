adv_chat={}
modlib.mod.extend("adv_chat", "conf")

-- Some IFNDEFS hehe
local bridge_ifndefs={
    bridge=adv_chat.bridges.discord or adv_chat.bridges.irc,
    discord=adv_chat.bridges.discord,
    irc=adv_chat.bridges.irc
}

modlib.mod.extend_string("adv_chat", modlib.text.handle_ifndefs(modlib.file.read(modlib.mod.get_resource("adv_chat", "colorize_message.lua")), bridge_ifndefs))

modlib.mod.extend_string("adv_chat", modlib.text.handle_ifndefs(modlib.file.read(modlib.mod.get_resource("adv_chat", "main.lua")), bridge_ifndefs))

-- Basic API stuff
modlib.mod.extend("adv_chat", "unicode")
modlib.mod.extend("adv_chat", "closest_color")
if cmdlib.trie then
    adv_chat.trie = cmdlib.trie
else
    modlib.mod.extend("adv_chat", "trie")
end
modlib.mod.extend("adv_chat", "text_styles")
modlib.mod.extend("adv_chat", "message")
modlib.mod.extend("adv_chat", "hud_channels")

-- Chat bridges
if bridge_ifndefs.bridge then
    modlib.mod.extend("adv_chat", "chatcommands")
    modlib.mod.extend("adv_chat", "process_bridges")
    
    local env = minetest.request_insecure_environment() or error("Error: adv_chat needs to be added to the trusted mods for chat bridges to work. See the Readme for more info.")
    adv_chat.set_os_execute(env.os.execute)
    adv_chat.set_socket(env.require("socket"))

    if adv_chat.bridges.irc then
        modlib.mod.extend("adv_chat", "irc")
    end
    
    if adv_chat.bridges.discord then
        modlib.mod.extend("adv_chat", "discord")
    end

    adv_chat.build_socket_bridge = nil
    adv_chat.build_file_bridge = nil
    adv_chat.build_bridge = nil
end

-- Tests - don't uncomment unless you actually want to test something
--[[
-- -- -- modlib.mod.extend("adv_chat", "test")
]]
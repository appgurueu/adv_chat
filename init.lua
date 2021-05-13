assert(modlib.version >= 69, "Upgrade modlib to rolling-69 or newer")
local mod = modlib.mod
mod.create_namespace()
mod.extend("conf")

mod.extend("colorize_message")

mod.extend("main")

-- Basic API stuff
mod.extend("unicode")
mod.extend("closest_color")
if cmdlib and cmdlib.trie then
    adv_chat.trie = cmdlib.trie
else
    mod.extend("trie")
end
mod.extend("text_styles")
mod.extend("message")
mod.extend("hud_channels")

-- Chat bridges
if adv_chat.bridges.irc or adv_chat.bridges.discord then
    mod.extend("chatcommands")
    mod.extend("process_bridges")
    local env = minetest.request_insecure_environment() or error("Error: adv_chat needs to be added to the trusted mods for chat bridges to work. See the Readme for more info.")
    adv_chat.set_insecure_environment(env)

    if adv_chat.bridges.irc then
        mod.extend("irc")
    end
    if adv_chat.bridges.discord then
        mod.extend("discord")
    end

    adv_chat.build_socket_bridge = nil
    adv_chat.build_file_bridge = nil
    adv_chat.build_bridge = nil
end

-- Tests - don't uncomment unless you actually want to test something
--[[
-- -- -- mod.extend("test")
]]
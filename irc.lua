register_role("irc",{color="#FFFF66"})

local bridge
if bridges.discord.bridge == "files" then
    bridge = build_file_bridge("irc")
else
    bridge = build_bridge("irc")
end

irc_bridge = bridge

bridge.listen(function(line)
    local linecontent=line:sub(6)
    if modlib.text.starts_with(line, "[MSG]") then
        local parts=modlib.text.split(linecontent, " ", 2)
        local src=parts[1].."[irc]"
        local adv_msg=message.new(chatters[src], nil, parts[2])
        adv_msg.sent_to="irc"
        send_to_all(adv_msg)
    elseif modlib.text.starts_with(line, "[PMS]") then
        local parts=modlib.text.split(linecontent, " ", 1)
        local source=parts[1]
        local target=parts[2]
        local msg=parts[3]
        if modlib.text.ends_with(target, "[discord]") then
            discord_bridge.write("[PMS]"..source.." "..target.."@you : "..msg)
        else
            if minetest.get_player_by_name(target_and_msg[1]) then
                minetest.chat_send_player(target_and_msg[2])
            end
        end
    elseif modlib.text.starts_with(line, "[CMD]") then
        local parts=modlib.text.split(linecontent, " ", 2)
        local source=parts[1]
        local call=parts[2]
        local success, retval = call_chatcommand(source.."[irc]", call)
        local prefix="Unknown"
        if success then prefix="Success" elseif success ~= nil then prefix="Error" end
        irc_bridge.write("[PMS]"..source.." "..prefix.." : "..(retval or "No return value."))
    elseif modlib.text.starts_with(line, "[GMS]") or modlib.text.starts_with(line, "[CGM]") then -- GMS = group message or CGM = channel group message
        local parts=modlib.text.split(linecontent, " ",3)
        local source=parts[1]
        local targets=modlib.text.split_without_limit(parts[2], ",")
        local msg=parts[3]
        local sent_to
        if modlib.text.starts_with(line, "[CGM]") then
            sent_to="irc"
        end
        local adv_msg=message.new(chatters[source.."[discord]"], targets, msg)
        adv_msg.sent_to=sent_to
        message.mentionpart(adv_msg) --force check mentions
        send_to_targets(adv_msg)
        if (#adv_msg.invalid_mentions) == 1 then
            irc_bridge.write("[PMS]"..source.." The target "..adv_msg.invalid_mentions[1].." is inexistant.")
        elseif (#adv_msg.invalid_mentions) > 1 then
            irc_bridge.write("[PMS]"..source.." The targets "..table.concat(adv_msg.invalid_mentions, ", ").." are inexistant.")
        end
    elseif modlib.text.starts_with(line, "[JOI]") then
        local parts=modlib.text.split(linecontent, " ", 3) --nick & color & channel
        join(parts[1].."[irc]", {color=parts[2], roles={}, irc=true})
        local chattername=parts[1].."[irc]"
        minetest.chat_send_all(mt_color(chattername)..
            chattername..minetest.get_color_escape_sequence("#FFFFFF").." joined.", 
            minetest.get_color_escape_sequence(parts[2])..parts[1].."[irc]"..
            minetest.get_color_escape_sequence("#FFFFFF").." joined.")
    elseif modlib.text.starts_with(line, "[EXT]") then
        local parts=modlib.text.split(linecontent, " ", 2) --nick & reason
        local chattername=parts[1].."[irc]"
        minetest.chat_send_all(mt_color(chattername)..chattername..minetest.get_color_escape_sequence("#FFFFFF").." quitted ("..parts[2]..").")
        leave(chattername)
    elseif modlib.text.starts_with(line, "[BYE]") then
        local parts=modlib.text.split(linecontent, " ", 2) --nick & reason
        local chattername=parts[1].."[irc]"
        minetest.chat_send_all(mt_color(chattername)..chattername..minetest.get_color_escape_sequence("#FFFFFF").." left ("..parts[2]..").")
        leave(chattername)
    elseif modlib.text.starts_with(line, "[NCK]") then
        local parts=modlib.text.split(linecontent, " ", 2) --nick & newnick
        local chattername=parts[1].."[irc]"
        local new_chattername=parts[2].."[irc]"
        rename(chattername, new_chattername)
    end
end)

-- Pinging
modlib.minetest.register_globalstep(1, function()
    bridge.write("[PIN]")
end)

bridge.serve()

-- Start AFTER mods are loaded, so that the player sees chat messages
minetest.register_on_mods_loaded(function()
    local java="java"
    local classpath=minetest.get_modpath("adv_chat").."/MinetestChatBridgeIRCBot/build/classes/java/main"
    local port=bridges.irc.port
    local network=bridges.irc.network
    local ssl=tostring(bridges.irc.ssl)
    local nick=bridges.irc.nickname
    local textchannel=bridges.irc.channelname
    local prefixes='"'..bridges.discord.minetest_prefix..'" "'..bridges.discord.prefix..'"'

    bridge.start(java..' -Dfile.encoding=UTF-8 -classpath "'..classpath..'" appguru.Main '..port..' "'..network..'" '..ssl..' "'..nick..'" "'..textchannel..'" "%s" "%s" "%s" '..prefixes..' &')
end)
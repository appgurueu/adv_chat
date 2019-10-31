register_role("discord",{color="#7289DA"})

function delete_discord_role(linecontent)
    if roles[linecontent].discord then
        for chatter, _ in pairs(roles[linecontent].affected) do
            if chatters[chatter].discord then
                chatters[chatter].roles[linecontent]=nil
            end
        end
        roles[linecontent]=nil
    else
        for chatter, _ in pairs(roles[linecontent].affected) do
            if chatters[chatter].discord then
                remove_role(chatter, linecontent, "discord")
            end
        end
    end
end

local bridge
if bridges.discord.bridge == "files" then
    bridge = build_file_bridge("discord")
else
    bridge = build_bridge("discord")
end

discord_bridge = bridge

bridge.listen(function(line)
    local linecontent=line:sub(6)
    if string_ext.starts_with(line, "[MSG]") then
        local parts=string_ext.split(linecontent, " ", 2)
        local src=parts[1].."[discord]"
        local adv_msg=message.new(chatters[src], nil, parts[2])
        adv_msg.sent_to="discord"
        send_to_all(adv_msg)
    elseif string_ext.starts_with(line, "[GMS]") or string_ext.starts_with(line, "[CGM]") then -- GMS = group message or CGM = channel group message
        local parts=string_ext.split(linecontent, " ",3)
        local source=parts[1]
        local targets=string_ext.split_without_limit(parts[2], ",")
        local msg=parts[3]
        local sent_to
        if string_ext.starts_with(line, "[CGM]") then
            sent_to="discord"
        end
        local targetset={}
        for _, target in ipairs(targets) do
            targetset[target]=true
        end
        local adv_msg=message.new(chatters[source.."[discord]"], targets, msg)
        adv_msg.sent_to=sent_to
        message.mentionpart(adv_msg) --force check mentions
        send_to_targets(adv_msg)
        if (#adv_msg.invalid_mentions) == 1 then
            discord_bridge.write("[PMS]#FFFFFF "..source.." The target "..adv_msg.invalid_mentions[1].." is inexistant.")
        elseif (#adv_msg.invalid_mentions) > 1 then
            discord_bridge.write("[PMS]#FFFFFF "..source.." The targets "..table.concat(adv_msg.invalid_mentions, ", ").." are inexistant.")
        end
    elseif string_ext.starts_with(line, "[CMD]") then
        local parts=string_ext.split(linecontent, " ", 2)
        local source=parts[1]
        local call=parts[2]
        local success, retval = call_chatcommand(source.."[discord]", call)
        local prefix = "[PMS]#FFFFFF "
        if success then prefix = "[SUC]" elseif success == false then prefix = "[ERR]" end
        discord_bridge.write(prefix..source.." "..(retval or "No return value."))
    elseif string_ext.starts_with(line, "[JOI]") or string_ext.starts_with(line, "[LIS]") then
        local parts=string_ext.split(linecontent, " ", 2) --nick & roles
        local chatter=parts[1].."[discord]"
        join(chatter, {color=parts[2], roles={}, discord=true})
        if string_ext.starts_with(line, "[JOI]") then
            minetest.chat_send_all(get_color(chatter)..chatter..minetest.get_color_escape_sequence("#FFFFFF").." joined.")
        end
    elseif string_ext.starts_with(line, "[EXT]") then
        chatters[linecontent.."[discord]"]=nil
        minetest.chat_send_all(linecontent.." left.")
    elseif string_ext.starts_with(line, "[NCK]") then
        local parts=string_ext.split(linecontent, " ", 2) --nick & newnick
        chatters[parts[1].."[discord]"]=nil
        chatters[parts[2].."[discord]"]=true
        minetest.chat_send_all(parts[1].."[discord] is now known as "..parts[2].."[discord]")
    elseif string_ext.starts_with(line, "[ROL]") then
        local parts=string_ext.split(linecontent, " ", 3) --name, color, nicks
        if not bridges.discord.blacklist[parts[1]] then
            if not roles[parts[1]] then
                register_role(parts[1], {color=parts[2], discord=true})
            end
            if parts[3] then
                for _,nick in pairs(string_ext.split_without_limit(parts[3], ",")) do
                    add_role(nick.."[discord]", parts[1], "discord")
                end
            end
        end
    elseif string_ext.starts_with(line, "[DEL]") then --Role is deleted
        delete_discord_role()
    elseif string_ext.starts_with(line, "[REM]") then --User is removed from role
        local parts=string_ext.split(linecontent, " ", 2) --role & nick
        remove_role(parts[2].."[discord]", parts[1], "discord")
    elseif string_ext.starts_with(line, "[ADD]") then --User is added to role
        local parts=string_ext.split(linecontent, " ", 2) --role & nick
        add_role(parts[2].."[discord]", parts[1], "discord")
    elseif string_ext.starts_with(line, "[NAM]") then --Role changes name
        local parts=string_ext.split(linecontent, " ", 2) --oldname, newname
        if not bridges.discord.blacklist[parts[2]] then
            if roles[parts[1]].discord then
                for chatter,_ in pairs(roles[parts[1]].affected) do
                    chatters[chatter].roles[parts[1]]=nil
                    chatters[chatter].roles[parts[2]]="discord"
                end
                roles[parts[2]]=table_ext.tablecopy(roles[parts[1]])
                roles[parts[1]]=nil
            else
                roles[parts[2]]=table_ext.tablecopy(roles[parts[1]])
                roles[parts[2]].discord=true
                for chatter,_ in pairs(roles[parts[1]].affected) do
                    if chatters[chatter].roles[parts[1]]=="discord" then --Move
                        roles[parts[1]].affected[chatter]=nil
                        chatters[chatter].roles[parts[1]]=nil
                        add_role(chatter, parts[2], "discord")
                    end
                end
            end
        else
            delete_discord_role(parts[1])
        end
    elseif string_ext.starts_with(line, "[COL]") then --Role changes color
        local parts=string_ext.split(linecontent, " ", 2) --role & color
        if roles[parts[1]].discord then
            roles[parts[1]].color=parts[2]
        end
    end
end)

-- Pinging
mt_ext.register_globalstep(1, function()
    bridge.write("[PIN]")
end)

-- Killing on_shutdown
minetest.register_on_shutdown(function()
    bridge.write("[KIL]")
end)

bridge.serve()

-- Start AFTER mods are loaded, so that the player sees chat messages
minetest.register_on_mods_loaded(function()
    local java="java"
    local jarpath=minetest.get_modpath("adv_chat").."/MinetestChatBridgeBot/build/libs/MinetestChatBridgeBot-all.jar"
    local token=bridges.discord.token or "NTc4MjM0NjM5NTc2MDcyMjEx.XPgWKA.ilzmvz-I7XTIML6Emj1jBx4ejLw"
    local text_channel=bridges.discord.channelname
    local prefixes='"'..bridges.discord.minetest_prefix..'" "'..bridges.discord.prefix..'"'
    local guild_id=bridges.discord.guild_id.." " or ""

    bridge.start(java..' -jar "'..jarpath..'"  "'..token..'" "'..text_channel..'" "%s" "%s" "%s" '..prefixes.." "..guild_id.." &")
end)
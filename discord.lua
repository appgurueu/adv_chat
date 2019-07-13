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

file_ext.process_bridge_build("discord")

file_ext.process_bridge_listen("discord", function(line)
    local linecontent=line:sub(6)
    if string_ext.starts_with(line, "[MSG]") then
        local parts=string_ext.split(linecontent, " ", 2)
        local src=parts[1].."[discord]"
        send_to_all(src, src..scheme.other.delim..parts[2], minetest.get_color_escape_sequence(get_color(src))..src..scheme.minetest.delim..parts[2], "discord")
    elseif string_ext.starts_with(line, "[GMS]") or string_ext.starts_with(line, "[CGM]") then -- GMS = group message or CGM = channel group message
        local parts=string_ext.split(linecontent, " ",3)
        local source=parts[1]
        local targets=string_ext.split_without_limit(parts[2], ",")
        local msg=parts[3]
        local sent_to="nobody"
        if string_ext.starts_with(line, "[CGM]") then
            sent_to="discord"
        end
        local targetset={}
        for _, target in ipairs(targets) do
            targetset[target]=true
        end
        local invalid_targets, msg, mt_msg=build_message(source.."[discord]", targets, msg)
        send_to_targets(source.."[discord]", table_ext.set(targets), msg, mt_msg, sent_to)
        if (#invalid_targets) == 1 then
            file_ext.process_bridge_write("discord", "[PMS]"..source.." The target "..invalid_targets[1].." is inexistant.")
        elseif (#invalid_targets) > 1 then
            file_ext.process_bridge_write("discord", "[PMS]"..source.." The targets "..table.concat(invalid_targets, ", ").." are inexistant.")
        end
    elseif string_ext.starts_with(line, "[CMD]") then
        local parts=string_ext.split(linecontent, " ", 3)
        local source=parts[1]
        local commandname=parts[2]
        local params=parts[3]
        local command=minetest.registered_chatcommands[commandname]
        if command then
            if not table_ext.is_empty(command.privs) then
                file_ext.process_bridge_write("discord", "[ERR]"..source.." Command requires privs.")
            else
                local success, retval = command.func(source.."[discord]", params or "")
                if success then
                    file_ext.process_bridge_write("discord", "[SUC]"..source.." "..(retval or "No return value."))
                else
                    file_ext.process_bridge_write("discord", "[ERR]"..source.." "..(retval or "No return value."))
                end
            end
        else
            file_ext.process_bridge_write("discord", "[ERR]"..source.."`"+commandname+"` : No such command.")
        end
    elseif string_ext.starts_with(line, "[JOI]") or string_ext.starts_with(line, "[LIS]") then
        local parts=string_ext.split(linecontent, " ", 2) --nick & roles
        local chatter=parts[1].."[discord]"
        join(chatter, {color=parts[2], roles={}, discord=true})
        if string_ext.starts_with(line, "[JOI]") then
            send_to_all("", get_color(chatter)..chatter..minetest.get_color_escape_sequence("#FFFFFF").." joined.")
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
    file_ext.process_bridge_write("discord", "[PIN]")
end)

-- Killing on_shutdown
minetest.register_on_shutdown(function()
    file_ext.process_bridge_write("discord", "[KIL]")
end)

file_ext.process_bridge_serve("discord")

-- Start AFTER mods are loaded, so that the player sees chat messages
minetest.register_on_mods_loaded(function()
    local java="java"
    local classpath=minetest.get_modpath("adv_chat").."/minetest-chat-bridge-bot/out/production/classes:/home/lars/.gradle/caches/modules-2/files-2.1/net.dv8tion/JDA/3.7.1_388/f534ab5132d8df986e603a404120492d4cdf815e/JDA-3.7.1_388.jar:/home/lars/.gradle/caches/modules-2/files-2.1/com.google.guava/guava/23.5-jre/e9ce4989adf6092a3dab6152860e93d989e8cf88/guava-23.5-jre.jar:/home/lars/.gradle/caches/modules-2/files-2.1/com.google.code.findbugs/jsr305/3.0.2/25ea2e8b0c338a877313bd4672d3fe056ea78f0d/jsr305-3.0.2.jar:/home/lars/.gradle/caches/modules-2/files-2.1/org.slf4j/slf4j-api/1.7.25/da76ca59f6a57ee3102f8f9bd9cee742973efa8a/slf4j-api-1.7.25.jar:/home/lars/.gradle/caches/modules-2/files-2.1/org.apache.commons/commons-collections4/4.1/a4cf4688fe1c7e3a63aa636cc96d013af537768e/commons-collections4-4.1.jar:/home/lars/.gradle/caches/modules-2/files-2.1/org.json/json/20160810/aca5eb39e2a12fddd6c472b240afe9ebea3a6733/json-20160810.jar:/home/lars/.gradle/caches/modules-2/files-2.1/net.sf.trove4j/trove4j/3.0.3/42ccaf4761f0dfdfa805c9e340d99a755907e2dd/trove4j-3.0.3.jar:/home/lars/.gradle/caches/modules-2/files-2.1/club.minnced/opus-java/1.0.2/c2e69f8d9aab5eab7476df8f5558e001657009bd/opus-java-1.0.2.jar:/home/lars/.gradle/caches/modules-2/files-2.1/com.neovisionaries/nv-websocket-client/2.4/da95dda351dba317468b08f8e5575216c05102/nv-websocket-client-2.4.jar:/home/lars/.gradle/caches/modules-2/files-2.1/com.squareup.okhttp3/okhttp/3.8.1/4d060ca3190df0eda4dc13415532a12e15ca5f11/okhttp-3.8.1.jar:/home/lars/.gradle/caches/modules-2/files-2.1/org.checkerframework/checker-qual/2.0.0/518929596ee3249127502a8573b2e008e2d51ed3/checker-qual-2.0.0.jar:/home/lars/.gradle/caches/modules-2/files-2.1/com.google.errorprone/error_prone_annotations/2.0.18/5f65affce1684999e2f4024983835efc3504012e/error_prone_annotations-2.0.18.jar:/home/lars/.gradle/caches/modules-2/files-2.1/com.google.j2objc/j2objc-annotations/1.1/ed28ded51a8b1c6b112568def5f4b455e6809019/j2objc-annotations-1.1.jar:/home/lars/.gradle/caches/modules-2/files-2.1/org.codehaus.mojo/animal-sniffer-annotations/1.14/775b7e22fb10026eed3f86e8dc556dfafe35f2d5/animal-sniffer-annotations-1.14.jar:/home/lars/.gradle/caches/modules-2/files-2.1/club.minnced/opus-java-api/1.0.2/e6e5afd72b5305356ef6d3aa95e84790cd340828/opus-java-api-1.0.2.jar:/home/lars/.gradle/caches/modules-2/files-2.1/club.minnced/opus-java-natives/1.0.2/b62c0be7a49c9bf0933d003cc0418e90518db728/opus-java-natives-1.0.2.jar:/home/lars/.gradle/caches/modules-2/files-2.1/com.squareup.okio/okio/1.13.0/a9283170b7305c8d92d25aff02a6ab7e45d06cbe/okio-1.13.0.jar:/home/lars/.gradle/caches/modules-2/files-2.1/net.java.dev.jna/jna/4.4.0/cb208278274bf12ebdb56c61bd7407e6f774d65a/jna-4.4.0.jar"
    local token=bridges.discord.token or "NTc4MjM0NjM5NTc2MDcyMjEx.XPgWKA.ilzmvz-I7XTIML6Emj1jBx4ejLw"
    local text_channel=bridges.discord.channelname
    local prefixes='"'..bridges.discord.minetest_prefix..'" "'..bridges.discord.prefix..'"'
    local guild_id=bridges.discord.guild_id.." " or ""

    file_ext.process_bridge_start("discord", java..' -Dfile.encoding=UTF-8 -classpath "'..classpath..'" appguru.Main "'..token..'" "'..text_channel..'" "%s" "%s" "%s" '..prefixes.." "..guild_id.."&")
end)
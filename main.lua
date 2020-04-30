--- THIS FILE USES CUSTOM STUFF (IFNDEFS) IMPLEMENTED USING MODLIB - DON'T CHANGE THE WAY IT IS EXECUTED IN init.lua

modlib.log.create_channel("adv_chat") -- Create log channel
modlib.data.create_mod_storage("adv_chat") --Create mod storage
modlib.player.set_property_default("adv_chat.roles",{})
modlib.player.set_property_default("adv_chat.blocked",{chatters={}, roles={}})

registered_on_chat_messages = {}

function register_on_chat_message(func)
    table.insert(registered_on_chat_messages, func)
end

register_on_chat_message(function(sendername, content, msg)
    if not msg.targets then
        modlib.log.write("adv_chat", "[MSG] "..sendername..": "..content)
    end
end)

function unregister_on_chat_message(func)
    for index, func_2 in modlib.table.rpairs(func) do
        if func == func_2 then
            table.remove(registered_on_chat_messages, index)
        end
    end
end

function call_registered_on_chat_messages(name, message, msg_info)
    for _, func in ipairs(registered_on_chat_messages) do
        if func(name, message, msg_info) then
            return true
        end
    end
    return false
end

registered_on_joinplayers = {}

function register_on_joinplayer(func)
    table.insert(registered_on_joinplayers, func)
end

register_on_joinplayer(function(player)
    if get_color(player:get_player_name()) == "#FFFFFF" then
        chatters[player:get_player_name()].color = roles.minetest.color
    end
end)


function call_registered_on_joinplayers(player)
    for _, func in ipairs(registered_on_joinplayers) do
        if func(player) then
            return true
        end
    end
    return false
end

channels={} --channelname -> definition : {hud_pos, mode, autoremove, max_messages, max_lines, wrap_chars, smartwrap}
roles={} -- Role -> players -> true
if roles_case_insensitive then
    modlib.table.set_case_insensitive_index(roles)
end
chatters={} -- Chatter -> stuff
to_be_sent={} --Receiver -> { {sender, message, date, time} }

function save_data()
    modlib.data.save_json("chatroles", "to_be_sent", to_be_sent)
end

to_be_sent = modlib.data.load_json("chatroles", "to_be_sent") or {}

modlib.minetest.register_globalstep(30, save_data) -- TODO introduce config var
minetest.register_on_shutdown(save_data)

function is_blocked(target, source)
    if not chatters[target] then return false end
    local blocked=chatters[target].blocked
    if not blocked then return false end
    if blocked.chatters[source] then
        return true
    end
    for role,_ in pairs(blocked.roles) do
        if roles[role].affected[source] then
            return true
        end
    end
end

function send_to_chatter(sendername, chattername, message)
    if is_blocked(chattername, sendername) then return end
    if chatters[chattername].minetest then
        minetest.chat_send_player(chattername, sendername)
    else
        --IFNDEF discord
        if chatters[chattername].discord then
            discord_bridge.write("[PMS]"..get_color(chattername).." "..chattername.." "..message)
        end
        --ENDIF
        --IFNDEF irc
        if chatters[chattername].irc then
            irc_bridge.write("[PMS]"..chattername.." "..message)
        end
        --ENDIF
    end
end

function send_to_targets(msg)
    message.mentionpart(msg)
    if modlib.table.is_empty(msg.valid_targets) then
        return
    end
    if message.handle_on_chat_messages(msg) then
        return msg.handled_by_on_chat_messages
    end
    --IFNDEF bridge
    local discord_mentioned, irc_mentioned=msg.targets.discord, msg.targets.irc
    --ENDIF
    for target, _ in pairs(msg.targets) do
        if not chatters[target] then
            if roles[target] then
                modlib.table.add_all(msg.targets, roles[target].affected)
            end
            msg.targets[target]=nil
        end
    end
    local discord_chatters={}
    local irc_chatters={}
    for chatter, _ in pairs(msg.targets) do
        if not is_blocked(chatter, sendername) then
            if chatters[chatter].minetest then
                minetest.chat_send_player(chatter, message.build(msg, "minetest"))
            else
                --IFNDEF discord
                if chatters[chatter].discord then
                    table.insert(discord_chatters, chatter:sub(1, chatter:len()-9))
                end
                --ENDIF
                --IFNDEF irc
                if chatters[chatter].irc then
                    table.insert(irc_chatters, chatter:sub(1, chatter:len()-5))
                end
                --ENDIF
            end
        end
    end

    --IFNDEF discord
    if msg.sent_to ~= "discord" then
        if discord_mentioned then
            discord_bridge.write("[MSG]"..(msg.chatter.color).." "..message.build(msg, "discord"))
        elseif #discord_chatters > 0 then
            discord_bridge.write("[PMS]"..(msg.chatter.color).." "..table.concat(discord_chatters, ",").." "..message.build(msg, "discord"))
        end
    end
    --ENDIF

    --IFNDEF irc
    if msg.sent_to ~= "irc" then
        if irc_mentioned then
            irc_bridge.write("[MSG]"..message.build(msg, "irc"))
        elseif #irc_chatters > 0 then
            irc_bridge.write("[PMS]"..table.concat(irc_chatters, ",").." "..message.build(msg, "irc"))
        end
    end
    --ENDIF
end

function join(name, def)
    if not def.roles then
        def.roles={}
    end
    if not def.name then
        def.name=name
    end
    def.service = ((def.minetest and "minetest") or (def.irc and "irc")) or "discord"
    chatters[name]=def
    local to_be_received=to_be_sent[name]
    if to_be_received then
        local date=os.date("%Y-%m-%d")
        for _, m in ipairs(to_be_received) do
            local sender_color=get_color(m.sender)
            local datepart=""
            if date ~= m.date then
                datepart=m.date.." "
            end
            local message
            if def.minetest then
                message="["..datepart..m.time.."] "..minetest.get_color_escape_sequence(sender_color)..
                    m.sender..schemes.minetest.content_prefix..m.message
            else
                message="["..datepart..m.time.."] "..m.sender..schemes.other.content_prefix..m.message
            end
            send_to_chatter(m.sender, name, message)
        end
    end
    to_be_sent[name]=nil
end

function core.send_join_message(name) end

function send_join_message(name)
    minetest.chat_send_all(mt_color(name)..name..minetest.get_color_escape_sequence("#FFFFFF").." joined.")
end

function rename(chattername, new_chattername)
    chatters[new_chattername]=chatters[chattername]
    transfer_roles(chattername, new_chattername)
    chatters[chattername]=nil
    minetest.chat_send_all(mt_color(new_chattername)..chattername..minetest.get_color_escape_sequence("#FFFFFF").." is now known as "..mt_color(new_chattername)..new_chattername)
end

function leave(name)
    remove_roles(name)
    chatters[name]=nil
end

function core.send_leave_message(name, timeout) end

function send_leave_message(name, timed_out)
    local message = mt_color(name)..name..minetest.get_color_escape_sequence("#FFFFFF").." left"
    if timed_out then
        message = message .. " (timed out)"
    end
    minetest.chat_send_all(message .. ".")
end

minetest.register_on_joinplayer(function(player)
    join(player:get_player_name(), {color=modlib.player.get_color(player), roles={}, blocked={chatters={}, roles={}}, minetest=true})
    add_role(player:get_player_name(), "minetest")
    if not call_registered_on_joinplayers(player) then
        send_join_message(player:get_player_name())
    end
end)

minetest.register_on_leaveplayer(function(player, timed_out)
    send_leave_message(player:get_player_name(), timed_out)
    leave(player:get_player_name())
end)

function register_role(rolename, roledef)
    roles[rolename]={title=roledef.title, color=roledef.color or "#FFFFFF",affected={}}
    modlib.player.register_forbidden_name(rolename)
end

--IFNDEF bridge
minetest.original_chat_send_all=minetest.chat_send_all
minetest.chat_send_all=function(msg)
    local adv_message=message.new(nil, nil, msg)
    adv_message.internal=true
    send_to_all(adv_message)
end
--ENDIF

--IFNDEF bridge
minetest.original_chat_send_player=minetest.chat_send_player
minetest.chat_send_player=function(name, msg)
    local chatter=chatters[name]
    if not chatter then
        return
    end
    if chatter.minetest then
        return minetest.original_chat_send_player(name, msg)
    end
    local adv_message=message.new(nil, nil, msg)
    adv_message.internal=true
    local to_be_sent=message.build(adv_message, chatter.service)
--ENDIF

    --IFNDEF irc
    if chatter.irc then
        irc_bridge.write("[PMS]"..chatter.name.." "..to_be_sent)
    end
    --ENDIF
    --IFNDEF discord
    if chatter.discord then
        discord_bridge.write("[PMS]#FFFFFF "..chatter.name.." "..to_be_sent)
    end
    --ENDIF

--IFNDEF bridge
end
--ENDIF

register_role("minetest",{color="#66FF66"})

function unregister_role(rolename)
    roles[rolename]=nil
    modlib.player.unregister_forbidden_name(rolename)
end

function add_role(player, role, value)
    if not roles[role] or not chatters[player] then return false end
    if not roles[role].affected[player] then
        roles[role].affected[player]=value or true
    end
    if not chatters[player].roles[role] then
        chatters[player].roles[role]=value or true
    end
    return true
end

function remove_role(player, role, expected_value)
    if expected_value and roles[role].affected[player] == expected_value then
        roles[role].affected[player]=nil
        chatters[player].roles[role]=nil
    end
end

function remove_roles(chatter)
    for role, _ in pairs(chatters[chatter].roles) do
        roles[role].affected[chatter] = nil
        chatters[chatter].roles[role] = nil
    end
end

function transfer_roles(chatter, new_chatter)
    for role, _ in pairs(chatters[chatter].roles) do
        roles[role].affected[new_chatter] = roles[role].affected[chatter]
        roles[role].affected[chatter] = nil
    end
end

function get_color(chatter)
    if chatters[chatter] then
        return chatters[chatter].color or "#FFFFFF"
    end
    return "#FFFFFF"
end

function mt_color(chattername)
    return minetest.get_color_escape_sequence(get_color(chattername))
end

function send_to_all(msg)
    if message.handle_on_chat_messages(msg) then
        return msg.handled_by_on_chat_messages
    end
    --IFNDEF irc
    if msg.sent_to ~= "irc" then
        irc_bridge.write("[MSG]"..message.build(msg, "irc"))
    end
    --ENDIF
    --IFNDEF discord
    if msg.sent_to ~= "discord" then
        discord_bridge.write("[MSG]"..((msg.chatter and msg.chatter.color) or "#FFFFFF").." "..message.build(msg, "discord"))
    end
    --ENDIF
    if msg.sent_to ~= "minetest" then
        local mt_msg
        for _,player in pairs(minetest.get_connected_players()) do
            local playername=player:get_player_name()
            if not msg.chatter or not is_blocked(playername, msg.chatter) then
                mt_msg=mt_msg or message.build(msg, "minetest")
                minetest.chat_send_player(playername, mt_msg)
            end
        end
    end
end

function send_to_players(msg, players, origin)
    for playername,_ in pairs(players) do
        local blocked=modlib.player.get_property(playername, "chatroles.blocked")
        if not blocked.players[origin] then
            local send = true
            for role,_ in ipairs(blocked.roles) do
                if roles[role].affected[origin] then
                    send = false
                    break
                end
            end
            if send then
                minetest.chat_send_player(playername, msg)
            end
        end
    end
end

function get_affected_by_mentions(mentions)
    local affected={}
    for _, mention in pairs(mentions) do
        if roles[mention] then
            modlib.table.add_all(affected, roles[mention].affected)
        elseif minetest.get_player_by_name(mention) then
            affected[mention]=true
        end
    end
    return affected
end

function parse_message(message)
    return colorize_message(parse_unicode(message))
end

function on_chat_message(sender, msg)
    local mentions={}
    local msg_content=msg
    if msg:sub(1,1)=="@" then
        local delim_space=false
        local last_non_delim_char=false
        for i=1,msg:len() do
            local c=msg:sub(i,i)
            if c == "," then
                last_non_delim_char=false
            elseif c ~=" " then
                if last_non_delim_char and i-last_non_delim_char > 1 then
                    delim_space=i-1
                    break
                end
                last_non_delim_char=i
            end
        end

        if not delim_space then
            minetest.chat_send_player(sender,  "No message given. Use '@mentions message'.")
            return true
        end

        msg_content=msg:sub(delim_space+1)
        local msg_header=msg:sub(2, delim_space-1)
        local parts=modlib.text.split_without_limit(msg_header,",")
        for _, part in pairs(parts) do
            table.insert(mentions, modlib.text.trim(part, " "))
        end
        local adv_msg=message.new(chatters[sender], mentions, msg_content)
        message.mentionpart(adv_msg)
        table.insert(mentions, sender)
        send_to_targets(adv_msg)
        if #adv_msg.invalid_mentions == 1 then
            minetest.chat_send_player(sender, "The target "..adv_msg.invalid_mentions[1].." is inexistant.")
        elseif #adv_msg.invalid_mentions > 1 then
            minetest.chat_send_player(sender, "The targets "..table.concat(adv_msg.invalid_mentions, ", ").." are inexistant.")
        end
    else
        local sender_color=get_color(sender)
        players={}
        for _,player in pairs(minetest.get_connected_players()) do
            players[player:get_player_name()]=true
        end
        local adv_msg=message.new(chatters[sender], mentions, msg_content)
        send_to_all(adv_msg)
    end
    return true
end
minetest.register_on_chat_message(on_chat_message)

local prefix = (cmdlib and "chat ") or "chat_"

minetest.register_chatcommand(prefix.."msg",{
    params = "<name> <message>",
    description = "Send a message to a chatter as soon as they join",
    privs={},
    func = function(sendername, param)
        local delim=param:find(" ")
        if not delim or delim==string.len(param) then
            return false, "No message specified"
        else
            local playername=param:sub(1,delim-1)
            if minetest.player_exists(playername) or modlib.text.ends_with(playername, "[irc]") or modlib.text.ends_with(playername, "[discord]") then
                local message=colorize_message(param:sub(delim+1))
                if not to_be_sent[playername] then
                    to_be_sent[playername]={}
                end
                table.insert(to_be_sent[playername],{sender=sendername, message=message, date=os.date("%Y-%m-%d"), time=os.date("%H:%M:%S")})
                return true, "Your message '"..message..minetest.get_color_escape_sequence("#FFFFFF").."' will be sent to chatter '"..playername.."' as soon as they join."
            else
                return false, "No chatter called '"..playername.."'"
            end
        end
    end
})

local formspec=[[size[9,0.5,false]
field[0.2,0.2;7,1;text;;]
button_exit[7,0;2,0.75;send;Send]
no_prepend[]
]]

minetest.register_chatcommand(prefix.."say", {
    params="",
    description="Send chat message using entry field.",
    privs={discord_user=false, irc_user=false},
    func=function(sendername)
        minetest.show_formspec(sendername, "chatroles:chatbox", formspec)
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname=="chatroles:chatbox" and fields.text then
        on_chat_message(player:get_player_name(), fields.text)
    end
end)

minetest.register_chatcommand(prefix.."block", {
    params = "<name> | <role>",
    description = "Block messages from chatter or role",
    privs={},
    func = function(sendername, param)
        param=modlib.text.trim(param)
        if param:len() == 0 or (not chatters[param] and not roles[param]) then
            return false, "No valid chatter name or role given."
        end
        if not chatters[sendername] then
            return false, "No valid sender name."
        end
        local blocked=chatters[sendername].blocked.chatters
        if roles[param] then
            blocked=chatters[sendername].blocked.roles
        end
        if blocked[param] then
            return false, type..param.." is already blocked"
        end
        blocked[param]=true
        return true, type..param.." was blocked"
    end
})

minetest.register_chatcommand(prefix.."unblock", {
    params = "<name> | <role>",
    description = "Unblock messages from chatter or role",
    privs={},
    func = function(sendername, param)
        param=modlib.text.trim(param)
        if param:len() == 0 or (not chatters[param] and not roles[param]) then
            return false, "No valid chatter name or role given."
        end
        if not chatters[sendername] then
            return false, "No valid sender name."
        end
        local blocked=chatters[sendername].blocked.chatters
        if roles[param] then
            blocked=chatters[sendername].blocked.roles
        end
        if not blocked[param] then
            return false, type..param.." is not blocked"
        end
        blocked[param]=nil
        return true, type..param.." was unblocked"
    end
})

minetest.register_chatcommand(prefix.."login", {
    params = "<name> <password>",
    description = "Log in as (fake) player to execute chatcommands as them",
    privs = {chatter=true},
    func = function(sendername, param)
        param=modlib.text.trim(param)
        if param:len() == 0 then
            return false, "No arguments given - missing name and password."
        end
        local name, password = unpack(modlib.text.split(param, " ", 2))
        password = password or ""
        local auth = minetest.get_auth_handler().get_auth(name)
        if auth and minetest.check_password_entry(name, auth.password, password) then
            chatters[sendername].login = name
            return true, 'Logged in as "'..name..'"'
        end
        return false, "Wrong playername/password. : "..name..", "..password.."!="..auth.password
    end
})

minetest.register_chatcommand(prefix.."logout", {
    params = "",
    description = "Log out from your (fake) player account",
    privs = {chatter=true},
    func = function(sendername, param)
        if not chatters[sendername].login then
            return false, "Not logged in."
        end
        local login = chatters[sendername].login
        chatters[sendername].login = nil
        return true, 'Logged out from "'..login..'"'
    end
})

minetest.original_get_player_privs = minetest.get_player_privs
function minetest.get_player_privs(playername)
    if chatters[playername] then
        return {chatter=true}
    end
    return minetest.original_get_player_privs(playername)
end

if cmd_ext then
    function call_chatcommand(chatter, call)
        local last_space, next_space = 1, call:find(" ")
        local command_trie, command_name = cmd_ext.chatcommands
        local cmd, suggestion
        local total_command_name = {}
        repeat
            next_space = next_space or call:len()+1
            command_name = call:sub(last_space, next_space-1)
            table.insert(total_command_name, command_name)
            local concat = table.concat(total_command_name, " ")
            if bridges.command_blacklist[total_command_name] then
                return false, "Command only available from Minetest."
            end
            total_command_name = {concat}
            if command_name == "" and cmd and not cmd.params then break end
            cmd, suggestion, _ = trie.search(command_trie, command_name)
            if not cmd then
                return false, "No such chatcommand."..((suggestion and " Did you mean \""..call:sub(0, last_space-1)..suggestion.."\" ?") or "")
            elseif cmd.subcommands and not cmd.implicit_call then
                command_trie = cmd.subcommands
                last_space, next_space = next_space + 1, call:find(" ", next_space+1)
            else
                last_space = next_space + 1
                break
            end
        until next_space == call:len()
        local params = call:sub(last_space)
        if cmd.privs and cmd.privs.chatter then
            return cmd.func(chatter, params)
        end
        return cmd.func((chatters[chatter] and chatters[chatter].login) or chatter, params)
    end
else
    function call_chatcommand(chatter, call)
        local name, params = unpack(string_ext.split(call, " ", 2))
        if bridges.command_blacklist[name] then
            return false, "Command only available from Minetest."
        end
        local command = minetest.registered_chatcommands[name]
        if not command then
            return false, "No such chatcommand."
        end
        local privs = minetest.get_player_privs(chatter)
        local to_lose, to_gain = {}, {}
        for priv, val in pairs(command.privs) do
            if val ~= privs[val] then
                table.insert((val and to_gain) or to_lose, priv)
            end
        end
        if #to_lose ~= 0 or #to_gain ~= 0 then
            if #to_lose == 0 then
                return false, "Missing privileges : "..table.concat(to_gain, ", ")
            end
            if #to_gain == 0 then
                return false, "Privileges to be lost : "..table.concat(to_lose, ", ")
            end
            return false, "Missing privileges : "..table.concat(to_gain, ", ")..", privileges to be lost : "..table.concat(to_lose, ", ")
        end
        if cmd.privs.chatter then
            return cmd.func(chatter, params)
        end
        return command.func((chatters[chatter] and chatters[chatter].login) or chatter, params)
    end
end
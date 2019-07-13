hud_channels ={} -- in order to reduce overhead
channel_defs={}

function register_hud_channel(channel, def)
    hud_channels[channel]={}
    local mode=def.mode or "list"
    local height=def.height or 20
    if mode=="list" then
        height=-height
    end
    channel_defs[channel]={autoremove_interval=def.autoremove_interval,
                           mode=mode, max_messages=def.max_messages or 5, height=height,
                           hud_base_offset=def.hud_base_offset or {x=0, y=0}, hud_base_position=def.hud_base_position or {0.5,0.5}} -- defaults
end

function unregister_hud_channel(channel)
    hud_channels[channel]=nil
    channel_defs[channel]=nil
end

minetest.register_globalstep(function(dtime)
    for channelname,channel in pairs(hud_channels) do
        local def=channel_defs[channelname]
        for _,player in pairs(minetest.get_connected_players()) do
            local name=player:get_player_name()
            local channel=channel[name]
            if def.autoremove_interval and channel.last_message > def.autoremove_interval then
                remove_last_msg_from_hud({player}, channelname)
                hud_channels[channelname][name].last_message=0
            end
            hud_channels[channelname][name].last_message=hud_channels[channelname][name].last_message+dtime
        end
    end
end)

minetest.register_on_joinplayer(function(player)
    minetest.after(0, function()
        for channelname,channel in pairs(hud_channels) do
            hud_channels[channelname][player:get_player_name()]={last_message=0}
        end
    end)
end)

minetest.register_on_leaveplayer(function(player)
    minetest.after(0, function()
        for channelname,channel in pairs(hud_channels) do
            hud_channels[channelname][player:get_player_name()]={}
        end
    end)
end)

function remove_last_msg_from_hud(players, listname)
    local def=channel_defs[listname]
    local list=hud_channels[listname]
    for _,player in pairs(players or minetest.get_connected_players()) do
        local name=player:get_player_name()
        local hud_ids=list[name]
        local i=#list[name]
        if def.mode=="list" then
            player:hud_remove(hud_ids[i])
            hud_ids[i]=nil
        else
            player:hud_remove(hud_ids[1]) -- Will be replaced
            for j=2,i do
                local new={x=def.hud_base_offset.x,y=def.hud_base_offset.y-((j-2)*def.height)}
                player:hud_change(hud_ids[j],"offset",new)
                hud_ids[j-1]=hud_ids[j] --Perform index shift
            end
            hud_ids[i]=nil
        end
        list[name]=hud_ids
    end
end

function add_msg_to_hud(players, listname, hud_def) -- MAY NOT BE CALLED SIMULTANEOUSLY
    local def=channel_defs[listname]
    local list=hud_channels[listname]
    hud_def.offset={x=def.hud_base_offset.x}
    hud_def.position=def.hud_base_position
    for _,player in pairs(players or minetest.get_connected_players()) do
        local name=player:get_player_name()
        local hud_ids=list[name] --Hud elem IDs
        hud_ids=list[name] or {}
        local i=#hud_ids
        if i == 0 then
            hud_ids.last_message=0
        end
        if (i == def.max_messages) then --Have to remove
            if def.mode=="list" then
                player:hud_remove(hud_ids[i])
            else
                player:hud_remove(hud_ids[1]) -- Will be replaced
                for j=2,i do
                    local new={x=def.hud_base_offset.x,y=def.hud_base_offset.y-((j-2)*def.height)}
                    player:hud_change(hud_ids[j],"offset",new)
                    hud_ids[j-1]=hud_ids[j] --Perform index shift
                end
            end
            i=i-1
        end
        if def.mode=="list" then
            for j=i,1,-1 do
                local new={x=def.hud_base_offset.x,y=def.hud_base_offset.y-(j*def.height)}
                player:hud_change(hud_ids[j],"offset",new)
                hud_ids[j+1]=hud_ids[j] --Perform index shift
            end
            hud_def.offset.y=def.hud_base_offset.y
            hud_ids[1]=player:hud_add(hud_def)
        else
            hud_def.offset.y=def.hud_base_offset.y-(i*def.height)
            hud_ids[i+1]=player:hud_add(hud_def)
        end
        list[name]=hud_ids --Update IDs
    end
end
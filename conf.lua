local schemedef={
    type = "table",
    children={
        message_prefix={type="string"},
        mention_prefix={type="string"},
        mention_delim={type="string"},
        content_prefix={type="string"},
        message_suffix={type="string"}
    }
}

local conf_spec={type="table", required_children={
    schemes={type="table", required_children={
        minetest=schemedef
    }, possible_children={
        irc=schemedef,
        discord=schemedef
    }},
    bridges={
        type="table",
        possible_children={
            irc={type="table", required_children={
                    port={type="number", range={0, 65535}},
                    network={type="string"},
                    nickname={type="string"},
                    channelname={type="string"},
                    ssl={type="boolean"},
                    prefix={type="string"},
                    minetest_prefix={type="string"}
                },
                possible_children={
                    bridge={type="string", possible_values={"files", "sockets"}},
                    convert_minetest_colors={type="string", possible_values={"disabled", "hex", "safer", "safest"}},
                    handle_discord_markdown={type="boolean"},
                    handle_minetest_markdown={type="boolean"}
                }
            },
            discord={type="table", required_children={
                    token={type="string"},
                    channelname={type="string"},
                    prefix={type="string"},
                    minetest_prefix={type="string"}
                },
                possible_children={
                    blacklist={type="table", keys={type="string"}},
                    whitelist={type="table", keys={type="string"}},
                    guild_id={type="string"},
                    bridge={type="string", possible_values={"files", "sockets"}},
                    convert_internal_markdown={type="boolean"},
                    convert_minetest_markdown={type="boolean"},
                    handle_irc_styles={type="string", possible_values={"escape_markdown", "convert", "disabled"}},
                    send_embeds={type="boolean"}
                }
            },
            command_blacklist={type="table", keys={type="number"}, values={type="string"}},
            command_whitelist={type="table", keys={type="number"}, values={type="string"}}
        }
    }
}, possible_children={
    roles_case_insensitive={type="boolean"}
}}

local config=modlib.conf.import("adv_chat", conf_spec)
modlib.table.add_all(getfenv(1), config)

function load_schemes()
    for k, v in pairs(schemes.minetest) do
        schemes.minetest[k] = colorize_message(v)
    end

    for _,s in pairs({"irc", "discord"}) do
        if not schemes[s] then
            schemes[s] = {}
            for k, v in pairs(schemes.minetest) do
                schemes[s][k] = minetest.strip_colors(v)
            end
        end
    end

    load_schemes = nil
end

if bridges.irc and not bridges.irc.style_conversion then
    bridges.irc.style_conversion={}
    if not bridges.irc.style_conversion.colors then
        bridges.irc.style_conversion.colors="disabled"
    end
end

if bridges.discord then

    local blacklist_empty=modlib.table.is_empty(bridges.discord.blacklist or {})
    local whitelist_empty=modlib.table.is_empty(bridges.discord.whitelist or {})
    if blacklist_empty then
        if not whitelist_empty then
            bridges.discord.blacklist=setmetatable(bridges.discord.blacklist, {__index=function(value)
                if bridges.discord.whitelist[value] then
                    return nil
                end
                return true
            end})
        end
    else
        if not whitelist_empty then
            bridges.discord.blacklist={}
        end
    end

end

if bridges.discord or bridges.irc then

    bridges.command_blacklist = modlib.table.set(bridges.command_blacklist or {})
    bridges.command_whitelist = modlib.table.set(bridges.command_whitelist or {})
    local blacklist_empty=modlib.table.is_empty(bridges.command_blacklist)
    local whitelist_empty=modlib.table.is_empty(bridges.command_whitelist or {})
    if blacklist_empty then
        if not whitelist_empty then
            bridges.command_blacklist=setmetatable(bridges.command_blacklist, {__index=function(value)
                if bridges.command_whitelist[value] then
                    return nil
                end
                return true
            end})
        end
    end

end

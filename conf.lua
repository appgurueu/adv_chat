local schemedef={mention_prefix={type="string"},
mention_delim={type="string"},
delim={type="string"}}

local conf_spec={type="table", children={
    scheme={type="table", required_children={
        minetest=schemedef
    }, possible_children={
        other=schemedef
    }},
    bridges={
        type="table",
        possible_children={
            irc={type="table", children={
                port={type="number", range={0, 65535}},
                network={type="string"},
                nickname={type="string"},
                channelname={type="string"},
                ssl={type="boolean"},
                prefix={type="string"},
                minetest_prefix={type="string"}
            }},
            discord={type="table", required_children={
                    token={type="string"},
                    channelname={type="string"},
                    prefix={type="string"},
                    minetest_prefix={type="string"}
                },
                possible_children={
                    blacklist={type="table", keys={type="string"}},
                    whitelist={type="table", keys={type="string"}},
                    guild_id={type="string"}
                }
            }
        }
    }
}}

local config=conf.import("adv_chat", conf_spec)
table_ext.add_all(getfenv(1), config)

if bridges.discord then

    local blacklist_empty=table_ext.is_empty(bridges.discord.blacklist or {})
    local whitelist_empty=table_ext.is_empty(bridges.discord.whitelist or {})
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
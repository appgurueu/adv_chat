-- TODO handle <https://example.com> and mentions like @<ID> or @<!ID> (modification of Discord bot needed)

message={}

function message.new(chatter, mentions, content)
    return {chatter=chatter, mentions=mentions, content=content}
end

local function unicode(message)
    message.unicode_content = message.unicode_content or parse_unicode(message.content)
    return message.unicode_content
end

local function colorized(message)
    if not message.colorized_content then
        message.colorized_content, message.uncolorized_content=colorize_message(unicode(message))
    end
    return message.colorized_content
end

local function uncolorized(message)
    if not message.uncolorized_content then
        message.colorized_content, message.uncolorized_content=colorize_message(unicode(message))
    end
    message.uncolorized_content=minetest.strip_colors(message.uncolorized_content)
    return message.uncolorized_content
end

local to = {
    minetest = {
        from={
            internal=function(message)
                return message.content
            end,
            minetest = colorized,
            irc = function(message)
                message.colorized_content = irc_to_minetest(colorized(message))
                return message.colorized_content
            end,
            discord = uncolorized
        }
    },

    irc = {
        from={
            internal=function(message)
                return message.content
            end,
            minetest = function(message)
                return colorized(message)
            end,
            irc = function(message)
                return colorized(message)
            end,
            discord = function(message)
                return minetest_to_irc(colorized(message))
            end
        }
    },

    discord = {
        from={
            internal=function(message)
                return minetest.strip_colors(message.content)
            end,
            minetest = uncolorized,
            irc = function(message)
                return uncolorized(message)
            end,
            discord = uncolorized
        }
    }
}

local builders = to

builders.minetest.scheme = schemes.minetest
builders.irc.scheme = schemes.irc
builders.discord.scheme = schemes.discord

function message.mentionpart(msg)
    if not msg.mentionpart then
        msg.invalid_mentions={}
        msg.targets={}
        msg.valid_targets={}
        msg.mentionpart={}
        for _, mention in ipairs(msg.mentions or {}) do
            if not msg.targets[mention] then
                msg.targets[mention]=true
                if roles[mention] then
                    table.insert(msg.mentionpart, roles[mention].color)
                    table.insert(msg.mentionpart, mention)
                    msg.valid_targets[mention] = roles[mention]
                elseif chatters[mention] then
                    table.insert(msg.mentionpart, chatters[mention].color)
                    table.insert(msg.mentionpart, mention)
                    msg.valid_targets[mention] = chatters[mention]
                else
                    table.insert(msg.invalid_mentions, mention)
                end
            end
        end
    end
end

local mentionpart_builders = {
    irc=nil,
    discord=function(msg)
        if not msg.uncolorized_mentionpart then
            msg.uncolorized_mentionpart={}
            for i=2, #msg.mentionpart, 2 do
                table.insert(msg.uncolorized_mentionpart,msg.mentionpart[i])
            end
        end
        return "uncolorized_mentionpart"
    end,
    minetest=function(msg)
        if not msg.mt_mentionpart then
            msg.mt_mentionpart={}
            for index, item in ipairs(msg.mentionpart) do
                table.insert(msg.mt_mentionpart, ((index % 2 == 0) and item) or minetest.get_color_escape_sequence(item))
            end
        end
        return "mt_mentionpart"
    end
}

local function wrap_builder(source, goal, wrapper)
    local old_builder = builders[source].from[goal]
    builders[source].from[goal] = function(msg) return wrapper(old_builder(msg)) end
end

if bridges.discord then
    if not bridges.discord.convert_internal_markdown then
        wrap_builder("discord", "internal", escape_markdown)
    end
    if not bridges.discord.convert_minetest_markdown then
        wrap_builder("discord", "minetest", escape_markdown)
    end
    if bridges.discord.handle_irc_styles == "escape_markdown" then
        wrap_builder("discord", "irc", escape_markdown)
    elseif bridges.discord.handle_irc_styles ~= "disabled" then
        wrap_builder("discord", "irc", irc_to_markdown)
    end
end

if bridges.irc then

    if bridges.irc.handle_discord_markdown == "strip" then
        wrap_builder("irc", "discord", strip_markdown)
    elseif bridges.irc.handle_discord_markdown ~= "disabled" then
        wrap_builder("irc", "discord", markdown_to_irc)
    end

    if bridges.irc.handle_minetest_markdown == "strip" then
        wrap_builder("irc", "minetest", strip_markdown)
    elseif bridges.irc.handle_discord_markdown ~= "disabled" then
        wrap_builder("irc", "minetest", markdown_to_irc)
    end

    if bridges.irc.handle_internal_markdown == "strip" then
        wrap_builder("irc", "internal", strip_markdown)
    elseif bridges.irc.handle_discord_markdown ~= "disabled" then
        wrap_builder("irc", "internal", markdown_to_irc)
    end

    if bridges.irc.convert_minetest_colors=="disabled" then
        mentionpart_builders.irc=mentionpart_builders.discord
    else
        local old_from_minetest = builders.irc.from.minetest
        builders.irc.from.minetest=function(msg) return minetest_to_irc(old_from_minetest(msg)) end
        local old_from_internal = builders.irc.from.internal
        builders.irc.from.internal=function(msg) return minetest_to_irc(old_from_internal(msg)) end
        mentionpart_builders.irc=function(msg)
            if not msg.irc_mentionpart then
                msg.irc_mentionpart={}
                for index, item in ipairs(msg.mentionpart) do
                    if index % 2 == 0 then
                        table.insert(msg.irc_mentionpart, item)
                    elseif item ~= "#FFFFFF" then
                        table.insert(msg.irc_mentionpart, convert_color_to_irc(item:sub(2)))
                    end
                    table.insert(msg.irc_mentionpart, ((index % 2 == 0) and item) or (item ~= "#FFFFFF" and convert_color_to_irc(item:sub(2))))
                end
            end
            return "irc_mentionpart"
        end
    end
end

function message.mentionpart_target(msg, target)
    local builder=mentionpart_builders[target]
    message.mentionpart(msg)
    local name=builder(msg)
    local text = name.."_text"
    if not msg[text] then
        msg[text]=table.concat(msg[name], builders[target].mention_delim)
    end
    return msg[text]
end

function message.build(msg, target)
    local build=target.."_build"
    if not msg[build] then
        local builder = builders[target]
        if msg.internal then
            msg[build]=builder.from.internal(msg)
            return msg[build]
        end
        local conversion = builder.from[msg.chatter.service]
        local content = conversion(msg)
        local source = (msg.chatter.name and msg.chatter.name)
        if source and msg.chatter.color then
            if target=="minetest" then
                source=minetest.get_color_escape_sequence(msg.chatter.color)..source
            elseif target=="irc" and bridges.irc.style_conversion.color~="disabled" then
                local to_escape, color=convert_color_to_irc(msg.chatter.color:sub(2))
                if source:sub(1,1)==to_escape then
                    source=string.char(0x02)..string.char(0x02)..source
                end
                source=color..source
            end
        end
        local mentions = (msg.mentions and next(msg.mentions) and builder.scheme.mention_prefix..message.mentionpart_target(msg, target)..builder.scheme.content_prefix)
        if not mentions and source then source=source..builder.scheme.content_prefix end
        msg[build]=builder.scheme.message_prefix..(source or "")..(mentions or "")..content..builder.scheme.message_suffix
    end
    return msg[build]
end

function message.handle_on_chat_messages(msg)
    local on_chat_messages = call_registered_on_chat_messages(msg.chatter.name, msg.content, msg)
    if on_chat_messages then
        msg.handled_by_on_chat_messages = on_chat_messages
        return on_chat_messages
    end
end
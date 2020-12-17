# Advanced Chat (`adv_chat`)

> One Mod to rule them all, One Mod to find them,  
> One Mod to bring them all, and in the darkness bind them  

\- adapted quote from "Lord of the Rings"

Adds roles, colors, unicode, hud notifications, and chat bridges (IRC & discord).

## About

Depends on [`modlib`](https://github.com/appgurueu/modlib). Modlib has been updated to add features required by this mod, so make sure to get the newest version. Backwards compatibility was kept as far as I know.

Code licensed under the GPLv3 (GNU Public License Version 3). Written by Lars Mueller alias LMD or appguru(eu).

## Links

* [GitHub](https://github.com/appgurueu/adv_chat) - sources, issue tracking, contributing
* [Discord](https://discord.gg/ysP74by) - discussion, chatting
* [Minetest Forum](https://forum.minetest.net/viewtopic.php?f=9&t=22845) - (more organized) discussion
* [ContentDB](https://content.minetest.net/packages/LMD/adv_chat/) - releases (downloading from GitHub is recommended)

## Setup

In order to properly use `adv_chat`, you'll have to meet the following prerequisites:

* `modlib` Minetest mod installed and enabled as hard dependency and additionally also `cmdlib` (recommended)
* `adv_chat` needs to be installed, enabled and added to the trusted mods in settings/`minetest.conf`
* [LuaSocket](https://luarocks.org/modules/luasocket/luasocket) should be installed (`sudo luarocks install luasocket` on Ubuntu)
* Complete [Java](https://www.java.com/de/) 8 or ideally newer installation under your system path (accessible from terminal via `java`)

Then just install it like any other mod and enjoy your greatly improved chat experience!

## Terminology

Chatter: Participant in chat, be it a Minetest player, IRC user, or Discord member  
Role: "Group" of chatters  
Targets/Mentions: Roles or chatters mentioned using `@`

## Features

* Discord & IRC chat bridges, login & commands
* Blocking
* Colorization
* Style preservation
* Unicode
* Mentions
* HUD channels/notifications
* Scheduled messages for offline players

## Changes

### 🎃 Halloween Update

* Proper formatting support
* More configuration options
* Remote login for chatcommand execution
* Many under-the-hood changes cleaning up stuff & fixing bugs (improving the code & architecture)

### `rolling-4`

* Merged `config_help.md` into the Readme
* Adds `adv_chat.register_on_chat_message` which works much like `minetest.register_on_chat_message`
* Adds basic logging (of global messages)

### `rolling-5`

* Various fixes
* API additions

### `rolling-6`

* Replaced deprecated `modlib` and `cmdlib` calls

### `rolling-7`

* Replaced `goto`s for increased compatibility

### `rolling-8`

* Supports configuring case insensitive roles
* Removed outdated `config_help.md`

### `rolling-9`

* Fixes [`rolling-8`]

### `rolling-10`

* Supports sending messages instead of embeds (discord bridge)
* Fixes

### `rolling-20`

* Does not require disabling mod security anymore

## API

### HUD notifications

See `hud_channels.lua` for how it works and `test.lua` for a score change demo running with random values.

### Votes

Have not been added and will probably not be added. This belongs somewhere else.
There are already some vote mods out there. Will probably release a better one anyways.

### IRC Bridge

If enabled, creates a bridge to an IRC channel. For more details see the [Configuration].

### Discord Bridge

If enabled, creates a bridge to a Discord guild channel. For more details see the [Configuration].
Note that you need to create your own OAuth application (bot) but can of course use the provided implementation.

### More

See the code and [Configuration] options. Feel free to contact me.

## How it works

### Unicode support

This mod adds unicode support. Simply use the unicode codepoint in hexadecimal format prefixed by `U+`. To get a "slight smile" (🙂), you'd use `U+1F642`. Note that not all fonts fully support Unicode.
Use the `/chat say` command to open a text entry field to paste text.

### Real-time chat

Use `@` at the beginning to message players or roles before your message.
There are 3 special mentions : `minetest`, `irc` and `discord`.
Can be separated by comma **&** whitespace. Examples:

* `@singleplayer hi, singleplayer !` - message `hi, singleplayer !` is sent to singleplayer
* `lol(or whitespaces) @singleplayer hi` - message is just sent in global chat
* `@singleplayer, secondplayer, a_role Hmm...` - message `Hmm...` will be sent to `singleplayer`, `secondplayer` and all players with the role `a_role`
* `@a role message` - message `role message`(!) will be sent to player/role `a`
* `@p1, p2   ,   p4 lol` - message `lol` will be sent to `p1`, `p2`, `p3`

### Scheduled messages

Use the chatcommand `/msg <playername> <message>` to have playername receive a message as soon as they join.
Examples :

* `/msg singleplayer hi` - when singleplayer rejoins, he is sent the message, even if he is already online.

### IRC Bridge

Names of IRC users are suffixed with `[irc]`. A user `singlechatter` would be addressed as `singlechatter[irc]`.
Global messages & messages using `@irc` will be sent to the entire channel.
In order to write private messages yourself, use the common prefixes and send a private message to the bot.
So if an IRC user `singlechatter` wanted to chat with `singleplayer`, they would have to send private messages to the bot prefixed with `@singleplayer`.
On the other end, `singleplayer` would have to prefix messages with `@singleplayer[irc]`.

### Discord Bridge

Names of Discord users are suffixed with `[discord]`. A user `singlechatter` would be addressed as `singlechatter[discord]`.
Messages **without** any mentions will be sent to the channel, **publicly readable by any guild member, at any time**.
In order to write private messages yourself, use the common prefixes and send a direct message to the bot.
So if an Discord user `singlechatter` wanted to chat with `singleplayer`, they would have to send direct messages to the bot prefixed with `@singleplayer`.
On the other end, `singleplayer` would have to prefix messages with `@singlechatter[discord]`.
Privileges are represented using roles.
Summarized, the Discord Chat Bridge works quite similar to the IRC one, with some exceptions on when to send messages into the public channel.

#### Constraints

Making Minetest & IRC chat compatible with Discord required the introduction of restrictions to simplify and reduce confusion.

* No double nicknames on Discord. If there are double nicknames, one of them gets an appendix, which is not guaranteed to be the same each time. So better make sure this doesn't happen.
* Spaces (` `) and commata (`,`) in Discord nicknames are replaced by underscores (`_`)

## Configuration

### Locations

JSON Configuration: `<worldpath>/config/adv_chat.json`

Text Logs: `<worldpath>/logs/adv_chat/<date>.json`

Readme: `<modpath/gamepath>/adv_chat/Readme.md`

### Default Configuration

Located under `<modpath/gamepath>/adv_chat/default_config.json`

```json
{
  "schemes" : {
    "minetest" : {"message_prefix": "", "message_suffix": "", "mention_prefix": "#FFFF00@", "mention_delim": "#FFFF00, ", "content_prefix": "#FFFF00: #FFFFFF"}, 
    "other" : null
  },
  "bridges" : {
    "discord" : null,
    "irc" : null
  },
  "roles_case_insensitive": true
}
```

### Example Configuration

```json
{
  "schemes" : {
    "minetest" : {"message_prefix": "Somebody - namely ", "mention_prefix": "#FFFF00 - wrote to ", "mention_delim": "#FFFF00 and ", "content_prefix": "#FFFF00: #FFFFFF", "message_suffix": " :D"},
    "other" : null
  },
  "bridges" : {
    "discord" : {"channelname":"allgemein", "prefix": "?", "minetest_prefix": "!", "token":"S.U.Pxxs.E.R.T.9998OKEN", "blacklist":{"~~new_role~~":true}, "guild_id": 580416319703351296, "send_embeds": true},
    "irc" : {"channelname":"#mtchatbridgetest", "prefix": "?", "minetest_prefix": "!", "nickname": "MT_Chat_Bridge", "network":  "irc.freenode.net", "port": 7000, "ssl":  true}
  }
}

```

### Usage

#### `schemes`

Specifies the chat message format, `minetest` is for the one used on the Minetest chat, `irc` is IRC, and `discord` for Discord.

* `message_prefix` - Prefix for the message
* `mention_prefix` - Prefix for mentionpart.
* `mention_delim` - Mention delimiter.
* `content_prefix` - Message/sendername delimiter.
* `message_suffix` - Suffix for the message

If you want to use color escape sequences, type something like `#66FF00 colorized text here`, and replace `#66FF00` with your color of choice in hex format.

Messages are formatted as `message_prefix + sendername + mention_prefix + {mentions, mention_delim} + delim + message + message_suffix`

#### `bridges`

Configuration for IRC/Discord chat bridges. If `irc` or `discord` are set to `false` or `null`, the corresponding chat bridges aren't created.

##### `discord`

Table with the following entries :

* `token`: Discord bot token, required
* `channelname`: Name of bridge channel, required as well
* `prefix`, `minetest_prefix`: Prefixes for Discord/Minetest commands, required
* `role_blacklist`/`role_whitelist`: Blacklist/whitelist of Discord roles. If both or none are set, Discord roles are ignored.
* `guild_id`: Guild ID, string. If swines add your bot to other servers, force it to use the server with the specified Guild ID. Optional. If unset, bot will use the guild it joined first.
* `bridge`: Optional. Forces type of process bridge to use. Choices are `"file"` and `"socket"`. Sockets are recommended but require `luasocket`.
* `convert_internal_markdown`/`convert_minetest_markdown`: Optional boolean. Whether Markdown sent from Minetest/internal chat messages should be left untouched as if it was Discord Markdown
* `handle_irc_styles`: Optional string. How IRC styles should be converted to Discord Markdown. Possible values: `"disabled"`, `"escape_markdown"` and `"convert"`
* `strip_discord_markdown_in_minetest`: Optional boolean. Whether Discord Markdown should be stripped from Minetest chat.
* `send_embeds`: Optional boolean, whether the bot should send embeds or messages.

Example :

```json
    {
        "discord": {
              "prefix": "?",
              "minetest_prefix": "!",
              "token": "Ao.663438supers.76trange8343",
              "channelname": "ingame-chat",
              "blacklist":{"~~new_role~~":true},
              "guild_id": "580416319703351296"
        }
    }
```

##### `irc`

Table with fields. Required are:

* `network`: IRC network, for example `irc.freenode.net`
* `port`: Port, on [Freenode](https://freenode.net/kb/answer/chat) it would be `7000` if SSL is used, or else `6667`. Just google "connecting to network" for your IRC network of choice to get detailed information.
* `ssl`: Whether to use encryption (SSL) to communicate with the IRC network. Setting this to `true` is recommended.
* `nickname`: Bot nickname
* `channelname`: IRC channel name, for example `#minetest-server`
* `prefix`, `minetest_prefix`: Prefixes for IRC bot/Minetest chatcommands, required

Optional fields are:

* `bridge`: Type of process bridge to use can be forced here. Choices are `"file"` and `"socket"`. Sockets are recommended but require `luasocket`.
* `convert_minetest_colors`: How colors from Minetest chat messages should be converted to IRC. Possible values are `"disabled"`, `"safest"`, `"safe"` and `"hex_safe"` and `"hex"`
* `handle_internal_markdown`: How Markdown sent from internal MT should be converted to IRC text styles. Possible values are `"disabled"`, `"strip"` and `"convert"`
* `handle_minetest_markdown`: How Markdown sent from Minetest should be converted to IRC text styles. Possible values are `"disabled"`, `"strip"` and `"convert"`
* `handle_discord_markdown`: How Markdown sent from Discord should be converted to IRC text styles. Possible values are `"disabled"`, `"strip"` and `"convert"`

Example:

```json
    {
        "irc": {
              "prefix": "?",
              "minetest_prefix": "!",
              "channelname": "#minetest-server",
              "nickname": "SERVERNAME_Chat",
              "port": 7000,
              "ssl": true,
              "network": "irc.freenode.net"
        }
    }
```

##### `chatcommand_whitelist`/`chatcommand_blacklist`

Whitelist/blacklist of chatcommands which are not available from Discord or IRC. If both or none are set, all chatcommands are blacklisted.

### Recommendations

#### Consistency

It is recommended to **keep consistency**. To do so, channel & chat bot names could be similar across Discord and IRC. The same goes for prefixes.

#### Prefixes

You should try to keep prefixes similar and memorable, while ensuring that there are no collisions. I recommend the combination of `?` for Discord/IRC commands and `!` for Minetest commands.
Other neat combinations I have thought of are `+` and `-`, or `;` and `:`. Keep in mind that prefixes should be easy to type as well, and that others might have a different keyboard layout.

#### Discord Avatar

Pixel-art Minetest skin heads always work well as avatars. For an example look you could look at my [Robby-Head](https://github.com/appgurueu/artwork/blob/master/robbyhead.png).
There are tons of skins out there and it's fairly easy to extract the faces (but make sure you don't violate the licenses when using the images).
A good starting point is [Addis Open MT-Skin Database](http://minetest.fensta.bplaced.net/). You can, however, of course also design it yourself. Just grab your favorite pixel-art program and draw a 8x8 head.
You should also make sure to scale the small image up (to at least 256x256), because else Discord scales it up "for you" which makes it lose it's sharp edges.

#### Security

Only two basic hints : Always enable SSL, and don't give your bot token to anyone.
And of course make sure your server isn't hacked. Messages are sent as plain text over the sockets or file bridges.

## Internal process bridge protocol

I "developed" a simple protocol using files for communication between the processes.
There are three files : Output, input and logs. After a process has read it's input, it deletes the content.
The connected processes both run two threads, one for handling input, and the other for serving the output.
It works message-based. Messages are delimited by newlines (linefeed, `\n`).
They start with a message-type identifier wrapped in square brackets, followed by the parameters, delimited by spaces.
Example : `[PMS]singlechatter[irc] singleplayer Hi`
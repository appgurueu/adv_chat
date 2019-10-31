# Advanced Chat - Configuration

## Locations

JSON Configuration : `<worldpath>/config/adv_chat.json`

Text Logs : `<worldpath>/logs/adv_chat/<date>.json`

Explaining document(this, Markdown) : `<modpath/gamepath>/adv_chat/config_help.md`

Readme : `<modpath/gamepath>/adv_chat/Readme.md`

## Default Configuration

Located under `<modpath/gamepath>/adv_chat/default_config.json`

```json
{
  "schemes" : {
    "minetest" : {"message_prefix": "", "mention_prefix": "#FFFF00@", "mention_delim": "#FFFF00, ", "content_prefix": "#FFFF00: #FFFFFF"},
    "other" : null
  },
  "bridges" : {
    "discord" : null,
    "irc" : null
  }
}
```

## Example Configuration

```json
{
  "schemes" : {
    "minetest" : {"message_prefix": "Somebody - namely ", "mention_prefix": "#FFFF00 - wrote to ", "mention_delim": "#FFFF00 and ", "content_prefix": "#FFFF00: #FFFFFF", "message_suffix": " :D"},
    "other" : null
  },
  "bridges" : {
    "discord" : {"channelname":"allgemein", "prefix": "?", "minetest_prefix": "!","token":"S.U.Pxxs.E.R.T.9998OKEN", "blacklist":{"~~new_role~~":true}, "guild_id": 580416319703351296},
    "irc" : {"channelname":"#mtchatbridgetest", "prefix": "?", "minetest_prefix": "!", "nickname": "MT_Chat_Bridge", "network":  "irc.freenode.net", "port": 7000, "ssl":  true}
  }
}

```

## Usage

### `schemes`

Specifies the chat message format, `minetest` is for the one used on the Minetest chat, `irc` is IRC, and `discord` for Discord.

* `message_prefix` - Prefix for the message
* `mention_prefix` - Prefix for mentionpart.
* `mention_delim` - Mention delimiter.
* `content_prefix` - Message/sendername delimiter.
* `message_suffix` - Suffix for the message

If you want to use color escape sequences, type something like `#66FF00 colorized text here`, and replace `#66FF00` with your color of choice in hex format.

Messages are formatted as `message_prefix + sendername + mention_prefix + {mentions, mention_delim} + delim + message + message_suffix`

### `bridges`

Configuration for IRC/Discord chat bridges. If `irc` or `discord` are set to `false` or `null`, the corresponding chat bridges aren't created.

#### `discord`

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

#### `irc`

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

#### `chatcommand_whitelist`/`chatcommand_blacklist`

Whitelist/blacklist of chatcommands which are not available from Discord or IRC. If both or none are set, all chatcommands are blacklisted.

## Recommendations

### Consistency

It is recommended to **keep consistency**. To do so, channel & chat bot names could be similar across Discord and IRC. The same goes for prefixes.

### Prefixes

You should try to keep prefixes similar and memorable, while ensuring that there are no collisions. I recommend the combination of `?` for Discord/IRC commands and `!` for Minetest commands.
Other neat combinations I have thought of are `+` and `-`, or `;` and `:`. Keep in mind that prefixes should be easy to type as well, and that others might have a different keyboard layout.

### Discord Avatar

Pixel-art Minetest skin heads always work well as avatars. For an example look you could look at my [Robby-Head](https://github.com/appgurueu/artwork/blob/master/robbyhead.png).
There are tons of skins out there and it's fairly easy to extract the faces (but make sure you don't violate the licenses when using the images).
A good starting point is [Addis Open MT-Skin Database](http://minetest.fensta.bplaced.net/). You can, however, of course also design it yourself. Just grab your favorite pixel-art program and draw a 8x8 head.
You should also make sure to scale the small image up (to at least 256x256), because else Discord scales it up "for you" which makes it lose it's sharp edges.

### Security

Only two basic hints : Always enable SSL, and don't give your bot token to anyone.
And of course make sure your server isn't hacked. Messages are sent as plain text over the sockets or file bridges.

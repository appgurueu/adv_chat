# Advanced Chat (`adv_chat`)

> One Mod to rule them all, One Mod to find them,  
> One Mod to bring them all, and in the darkness bind them  

\- adapted quote from "Lord of the Rings"

Adds roles, colors, unicode, hud notifications, and chat bridges (IRC & discord).

## About

Help can be found under `config_help.md` in the same folder as this.

Depends on [`modlib`](https://github.com/appgurueu/modlib). Modlib has been updated to add features required by this mod, so make sure to get the newest version. Backwards compatibility was kept as far as I know.

Code licensed under the GPLv3 (GNU Public License Version 3). Written by Lars Mueller alias LMD or appguru(eu).

## Links

* [GitHub](https://github.com/appgurueu/voxelizer) - sources, issue tracking, contributing
* [Discord](https://discord.gg/ysP74by) - discussion, chatting
* [Minetest Forum](https://forum.minetest.net/viewtopic.php?f=9&t=22845) - (more organized) discussion
* [ContentDB](https://content.minetest.net/packages/LMD/voxelizer/) - releases (downloading from GitHub is recommended)

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
* See `config_help.md` and the sources for all details

## API

### HUD notifications

See `hud_channels.lua` for how it works and `test.lua` for a score change demo running with random values.

### Votes

Have not been added and will probably not be added. This belongs somewhere else.
There are already some vote mods out there. Will probably release a better one anyways.

### IRC Bridge

If enabled, creates a bridge to an IRC channel. For more details see `config_help.md`.

### Discord Bridge

If enabled, creates a bridge to a Discord guild channel. For more details see `config_help.md`.
Note that you need to create your own OAuth application (bot) but can of course use the provided implementation.

### More

See the code and `config_help.md`. Feel free to contact me.

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

### Internal process bridge protocol

I "developed" a simple protocol using files for communication between the processes.
There are three files : Output, input and logs. After a process has read it's input, it deletes the content.
The connected processes both run two threads, one for handling input, and the other for serving the output.
It works message-based. Messages are delimited by newlines (linefeed, `\n`).
They start with a message-type identifier wrapped in square brackets, followed by the parameters, delimited by spaces.
Example : `[PMS]singlechatter[irc] singleplayer Hi`

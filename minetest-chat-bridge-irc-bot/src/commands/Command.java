package commands;

import irc.IRCBot;

public interface Command {
    int getMinArgs();
    int getMaxArgs();
    void execute(IRCBot bot, String nick, String... params);
}

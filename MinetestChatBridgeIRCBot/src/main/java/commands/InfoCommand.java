package commands;

import handlers.TryAgainHandler;
import irc.IRCBot;

import java.io.IOException;

public abstract class InfoCommand implements Command {
    @Override
    public int getMinArgs() {
        return 0;
    }

    @Override
    public int getMaxArgs() {
        return 0;
    }

    public abstract String[] execute(String nick, String... args);

    @Override
    public void execute(IRCBot bot, String nick, String... args) {
        String[] reply=execute(nick, args);
        for (String message:reply) {
            String command = "PRIVMSG " + nick + " :" + message;
            try {
                bot.send(command, new TryAgainHandler(command));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
}

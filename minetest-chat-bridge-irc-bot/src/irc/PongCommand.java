package irc;

import irc.IRCBot;

import java.io.IOException;
import java.util.List;
import java.util.Map;

public class PongCommand implements Command {
    @Override
    public void execute(IRCBot bot, Map<String, Object> tags, String source, List<String> params) {
        try {
            if (params.size() == 1) {
                bot.send("PONG "+params.get(0));
            } else {
                bot.send("PONG " + params.get(0)+" "+params.get(1));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

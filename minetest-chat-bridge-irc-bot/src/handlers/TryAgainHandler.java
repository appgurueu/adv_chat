package handlers;

import irc.HandledResponse;
import irc.IRCBot;

import java.io.IOException;
import java.util.List;
import java.util.Map;

public class TryAgainHandler extends TimeoutResponseHandler {
    public String command;
    public TryAgainHandler(String command) {
        super(5000);
        this.command=command;
    }
    public void onTimeout() {}
    public HandledResponse handleWithoutTimeout(IRCBot bot, String commandname, Map<String, Object> tags, String source, List<String> params) {
        if (commandname.equals("263")) { // RPL_TRYAGAIN
            try {
                bot.send(command, new TryAgainHandler(this.command));
            } catch (IOException e) {
                e.printStackTrace();
            }
            return HandledResponse.KILL;
        }
        return HandledResponse.PASS;
    }
}

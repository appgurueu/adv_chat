package handlers;

import handlers.NumericHandler;
import irc.HandledResponse;
import irc.IRCBot;
import numeric.NumericLookup;

import java.util.List;
import java.util.Map;

public class NumericResponseHandler {
    private NumericHandler handler;

    public NumericResponseHandler(NumericHandler handler) {
        this.handler = handler;
    }

    public HandledResponse handle(IRCBot bot, String commandname, Map<String, String> tags, String source, List<String> params) {
        if (commandname.length() == 3) {
            for (byte i=0; i <= 2; i++) {
                if (commandname.charAt(i) < '0' || commandname.charAt(i) > '9') {
                    return HandledResponse.PASS;
                }
            }
            return handler.handle(bot, NumericLookup.lookup(commandname), params);
        }
        return HandledResponse.PASS;
    }
}

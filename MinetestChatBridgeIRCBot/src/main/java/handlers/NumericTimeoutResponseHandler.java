package handlers;

import irc.HandledResponse;
import irc.IRCBot;
import numeric.Numeric;
import numeric.NumericLookup;

import java.util.List;
import java.util.Map;

public abstract class NumericTimeoutResponseHandler extends TimeoutResponseHandler {

    public NumericTimeoutResponseHandler(long timeout) {
        super(timeout);
    }

    public abstract HandledResponse handleNumeric(IRCBot bot, Numeric num, List<String> params);

    @Override
    HandledResponse handleWithoutTimeout(IRCBot bot, String commandname, Map<String, Object> tags, String source, List<String> params) {
        if (commandname.length() == 3) {
            for (byte i=0; i <= 2; i++) {
                if (commandname.charAt(i) < '0' || commandname.charAt(i) > '9') {
                    return HandledResponse.PASS;
                }
            }
            return handleNumeric(bot, NumericLookup.lookup(commandname), params);
        }
        return HandledResponse.PASS;
    }

    @Override
    void onTimeout() {}
}

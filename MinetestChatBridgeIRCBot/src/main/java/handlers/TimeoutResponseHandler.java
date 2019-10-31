package handlers;

import handlers.ResponseHandler;
import irc.HandledResponse;
import irc.IRCBot;

import java.util.List;
import java.util.Map;

public abstract class TimeoutResponseHandler implements ResponseHandler {
    public long init; // System current time millis
    public long timeout;

    public TimeoutResponseHandler(long timeout) {
        this.init=System.currentTimeMillis();
        this.timeout = timeout;
    }

    abstract HandledResponse handleWithoutTimeout(IRCBot bot, String commandname, Map<String, Object> tags, String source, List<String> params);

    abstract void onTimeout();

    public HandledResponse handle(IRCBot bot, String commandname, Map<String, Object> tags, String source, List<String> params) {
        long current_millis=System.currentTimeMillis();
        if (current_millis - init > timeout) {
            onTimeout();
            return HandledResponse.KILL;
        }
        return this.handleWithoutTimeout(bot, commandname, tags, source, params);
    }
}

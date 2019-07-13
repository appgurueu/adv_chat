package handlers;

import irc.HandledResponse;
import irc.IRCBot;

import java.util.List;
import java.util.Map;

// pretty much like default
public interface ResponseHandler {
    HandledResponse handle(IRCBot bot, String commandname, Map<String, Object> tags, String source, List<String> params);
}

package irc;

import irc.IRCBot;

import java.util.List;
import java.util.Map;

public interface Command {
    void execute(IRCBot bot, Map<String, Object> tags, String source, List<String> params);
}

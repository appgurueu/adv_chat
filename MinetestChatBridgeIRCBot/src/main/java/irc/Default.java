package irc;

import irc.IRCBot;

import java.util.List;
import java.util.Map;

public interface Default {
    void execute(IRCBot bot, String commandname, Map<String, Object> tags, String source, List<String> params);
}

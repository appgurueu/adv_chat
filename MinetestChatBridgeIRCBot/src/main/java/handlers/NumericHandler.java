package handlers;

import irc.HandledResponse;
import irc.IRCBot;
import numeric.Numeric;

import java.util.List;

public interface NumericHandler {
    HandledResponse handle(IRCBot bot, Numeric num, List<String> params);
}

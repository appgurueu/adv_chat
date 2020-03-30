package handlers;

import handlers.NumericTimeoutResponseHandler;
import irc.HandledResponse;
import irc.IRCBot;
import numeric.Numeric;

import java.util.List;

public class TopicResponseHandler extends NumericTimeoutResponseHandler {
    public String provided_topic;

    public TopicResponseHandler() {
        super(20000);
        provided_topic=null;
    }

    @Override
    public HandledResponse handleNumeric(IRCBot bot, Numeric num, List<String> params) {
        switch (num) {
            case RPL_NOTOPIC:
                return HandledResponse.RETURN;
            case RPL_TOPIC:
                // Params are <client> <channel> :<topic>
                provided_topic=params.get(2);
                return HandledResponse.BREAK;
            case RPL_TOPICWHOTIME:
                // Params are <client> <channel> <nick> <setat>

                return HandledResponse.RETURN;
            case ERR_CHANOPRIVSNEEDED:
                return HandledResponse.RETURN;
            case ERR_NOTONCHANNEL:
                return HandledResponse.RETURN;
            case ERR_NOSUCHCHANNEL:
                return HandledResponse.RETURN;
            case ERR_NEEDMOREPARAMS:
                return HandledResponse.RETURN;
        }
        return HandledResponse.PASS;
    }
}

package numeric;

import java.util.HashMap;

public class NumericLookup {
    public static HashMap<Short, Numeric> map;
    static {
        map=new HashMap();
        map.put((short)1, Numeric.RPL_WELCOME);
        map.put((short)2, Numeric.RPL_YOURHOST);
        map.put((short)3, Numeric.RPL_CREATED);
        map.put((short)4, Numeric.RPL_MYINFO);
        map.put((short)5, Numeric.RPL_ISUPPORT);
        map.put((short)10, Numeric.RPL_BOUNCE);
        map.put((short)221, Numeric.RPL_UMODEIS);
        map.put((short)251, Numeric.RPL_LUSERCLIENT);
        map.put((short)252, Numeric.RPL_LUSEROP);
        map.put((short)253, Numeric.RPL_LUSERUNKNOWN);
        map.put((short)254, Numeric.RPL_LUSERCHANNELS);
        map.put((short)255, Numeric.RPL_LUSERME);
        map.put((short)256, Numeric.RPL_ADMINME);
        map.put((short)257, Numeric.RPL_ADMINLOC1);
        map.put((short)258, Numeric.RPL_ADMINLOC2);
        map.put((short)259, Numeric.RPL_ADMINEMAIL);
        map.put((short)263, Numeric.RPL_TRYAGAIN);
        map.put((short)265, Numeric.RPL_LOCALUSERS);
        map.put((short)266, Numeric.RPL_GLOBALUSERS);
        map.put((short)276, Numeric.RPL_WHOISCERTFP);
        map.put((short)300, Numeric.RPL_NONE);
        map.put((short)301, Numeric.RPL_AWAY);
        map.put((short)302, Numeric.RPL_USERHOST);
        map.put((short)303, Numeric.RPL_ISON);
        map.put((short)305, Numeric.RPL_UNAWAY);
        map.put((short)306, Numeric.RPL_NOWAWAY);
        map.put((short)311, Numeric.RPL_WHOISUSER);
        map.put((short)312, Numeric.RPL_WHOISSERVER);
        map.put((short)313, Numeric.RPL_WHOISOPERATOR);
        map.put((short)314, Numeric.RPL_WHOWASUSER);
        map.put((short)317, Numeric.RPL_WHOISIDLE);
        map.put((short)318, Numeric.RPL_ENDOFWHOIS);
        map.put((short)319, Numeric.RPL_WHOISCHANNELS);
        map.put((short)321, Numeric.RPL_LISTSTART);
        map.put((short)322, Numeric.RPL_LIST);
        map.put((short)323, Numeric.RPL_LISTEND);
        map.put((short)324, Numeric.RPL_CHANNELMODEIS);
        map.put((short)329, Numeric.RPL_CREATIONTIME);
        map.put((short)331, Numeric.RPL_NOTOPIC);
        map.put((short)332, Numeric.RPL_TOPIC);
        map.put((short)333, Numeric.RPL_TOPICWHOTIME);
        map.put((short)341, Numeric.RPL_INVITING);
        map.put((short)346, Numeric.RPL_INVITELIST);
        map.put((short)347, Numeric.RPL_ENDOFINVITELIST);
        map.put((short)348, Numeric.RPL_EXCEPTLIST);
        map.put((short)349, Numeric.RPL_ENDOFEXCEPTLIST);
        map.put((short)351, Numeric.RPL_VERSION);
        map.put((short)353, Numeric.RPL_NAMREPLY);
        map.put((short)366, Numeric.RPL_ENDOFNAMES);
        map.put((short)367, Numeric.RPL_BANLIST);
        map.put((short)368, Numeric.RPL_ENDOFBANLIST);
        map.put((short)369, Numeric.RPL_ENDOFWHOWAS);
        map.put((short)375, Numeric.RPL_MOTDSTART);
        map.put((short)372, Numeric.RPL_MOTD);
        map.put((short)376, Numeric.RPL_ENDOFMOTD);
        map.put((short)381, Numeric.RPL_YOUREOPER);
        map.put((short)382, Numeric.RPL_REHASHING);
        map.put((short)400, Numeric.ERR_UNKNOWNERROR);
        map.put((short)401, Numeric.ERR_NOSUCHNICK);
        map.put((short)402, Numeric.ERR_NOSUCHSERVER);
        map.put((short)403, Numeric.ERR_NOSUCHCHANNEL);
        map.put((short)404, Numeric.ERR_CANNOTSENDTOCHAN);
        map.put((short)405, Numeric.ERR_TOOMANYCHANNELS);
        map.put((short)421, Numeric.ERR_UNKNOWNCOMMAND);
        map.put((short)422, Numeric.ERR_NOMOTD);
        map.put((short)432, Numeric.ERR_ERRONEUSNICKNAME);
        map.put((short)433, Numeric.ERR_NICKNAMEINUSE);
        map.put((short)441, Numeric.ERR_USERNOTINCHANNEL);
        map.put((short)442, Numeric.ERR_NOTONCHANNEL);
        map.put((short)443, Numeric.ERR_USERONCHANNEL);
        map.put((short)451, Numeric.ERR_NOTREGISTERED);
        map.put((short)461, Numeric.ERR_NEEDMOREPARAMS);
        map.put((short)462, Numeric.ERR_ALREADYREGISTERED);
        map.put((short)464, Numeric.ERR_PASSWDMISMATCH);
        map.put((short)465, Numeric.ERR_YOUREBANNEDCREEP);
        map.put((short)471, Numeric.ERR_CHANNELISFULL);
        map.put((short)472, Numeric.ERR_UNKNOWNMODE);
        map.put((short)473, Numeric.ERR_INVITEONLYCHAN);
        map.put((short)474, Numeric.ERR_BANNEDFROMCHAN);
        map.put((short)475, Numeric.ERR_BADCHANNELKEY);
        map.put((short)481, Numeric.ERR_NOPRIVILEGES);
        map.put((short)482, Numeric.ERR_CHANOPRIVSNEEDED);
        map.put((short)483, Numeric.ERR_CANTKILLSERVER);
        map.put((short)491, Numeric.ERR_NOOPERHOST);
        map.put((short)501, Numeric.ERR_UMODEUNKNOWNFLAG);
        map.put((short)502, Numeric.ERR_USERSDONTMATCH);
        map.put((short)670, Numeric.RPL_STARTTLS);
        map.put((short)691, Numeric.ERR_STARTTLS);
        map.put((short)723, Numeric.ERR_NOPRIVS);
        map.put((short)900, Numeric.RPL_LOGGEDIN);
        map.put((short)901, Numeric.RPL_LOGGEDOUT);
        map.put((short)902, Numeric.ERR_NICKLOCKED);
        map.put((short)903, Numeric.RPL_SASLSUCCESS);
        map.put((short)904, Numeric.ERR_SASLFAIL);
        map.put((short)905, Numeric.ERR_SASLTOOLONG);
        map.put((short)906, Numeric.ERR_SASLABORTED);
        map.put((short)907, Numeric.ERR_SASLALREADY);
        map.put((short)908, Numeric.RPL_SASLMECHS);
    }
    public static Numeric lookup(short s) {
        return map.get(s);
    }
    public static Numeric lookup(String s) throws NumberFormatException {
        if (s.startsWith("0")) {
            s=s.substring(1);
        }
        if (s.startsWith("0")) {
            s=s.substring(1);
        }
        Numeric num=lookup(Short.parseShort(s));
        if (num == null) {
            return Numeric.NULL;
        }
        return num;
    }
}

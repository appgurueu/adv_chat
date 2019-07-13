package appguru;

import bridge.ProcessBridge;
import commands.Command;
import commands.InfoCommand;
import handlers.NumericTimeoutResponseHandler;
import handlers.TryAgainHandler;
import irc.HandledResponse;
import irc.IRCBot;
import misc.GarbageCollector;
import numeric.Numeric;

import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.TimeUnit;


public class Main {
    public static long STARTED_AT;

    public static long GARBAGE_COLLECTION = 5000; //5s

    public static String IRC_PREFIX="?";
    public static String PREFIX="!";

    public static long PING_WAIT=20000; //20s

    public static PrintStream OUT = System.out;

    public static IRCBot chat_bridge;

    public static void main(String[] args) throws IOException {
        String project_url="https://github.com/appgurueu/adv_chat";

        if (args.length > 7) {
            File log=new File(args[7]);
            if (!log.isFile() || !log.canWrite()) {
                OUT.println("ERR: Log file doesn't exist or can't be written to.");
            } else {
                OUT = new PrintStream(new FileOutputStream(log, true));
                Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                    OUT.close();
                }));
            }
            if (args.length > 8) {
                PREFIX=args[8];
                if (args.length > 9) {
                    IRC_PREFIX=args[9];
                }
            }
        }
        System.setErr(OUT);

        String[] showargs=new String[args.length];
        for (int i = 0; i < args.length; i++) {
            if (args[i].indexOf(' ') >= 0) {
                showargs[i]='"'+args[i]+'"';
            } else {
                showargs[i]=args[i];
            }
        }
        OUT.println("["+ new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date())+"]");

        OUT.println("INFO: Program arguments: "+String.join(" ", showargs));

        OUT.println("INFO: Starting Minetest chat bridge");

        int port=Integer.parseInt(args[0]);
        String network=args[1];
        String ssl=args[2];
        String nickname=args[3];
        String channelname=args[4];

        File in=new File(args[5]);
        File out=new File(args[6]);
        if (!in.isFile() || !out.isFile() || !in.canWrite() || !in.canRead() || !out.canWrite() || !out.canRead()) {
            OUT.println("ERR: Input or output files do not exist or can't be read/written.");
            System.exit(0);
        }

        /* Open Process Bridge */
        ProcessBridge pb=new ProcessBridge(in, out);

        /* Create IRC Bot */
        chat_bridge=new IRCBot(port, network, ssl.equals("true"));

        chat_bridge.commands.put("PRIVMSG", (bot, tags, source, params) -> {
            if (source == null || params.size() < 2) {
                return;
            }
            int indexOf=source.indexOf('!');
            String nick=indexOf >= 0 ? source.substring(0, indexOf):source;
            if (params.get(1).charAt(0) == '@') { //mentions used
                String mentionstring="";
                Set<String> mentions=new HashSet();
                String current_mention="";
                int delim_space = -1;
                int last_non_delim_char = -1;
                for (int i = 1; i < params.get(1).length(); i++) {
                    char c = params.get(1).charAt(i);
                    if (c == ',') {
                        if (current_mention.length() > 0) {
                            if (!mentions.contains(current_mention)) {
                                mentions.add(current_mention);
                                mentionstring+=current_mention+",";
                            }
                        }
                        current_mention="";
                        last_non_delim_char = -1;
                    } else if (c != ' ') {
                        if (last_non_delim_char >= 0 && i - last_non_delim_char > 1) {
                            if (current_mention.length() > 0) {
                                if (!mentions.contains(current_mention)) {
                                    mentions.add(current_mention);
                                    mentionstring+=current_mention;
                                }
                            }
                            delim_space = i - 1;
                            break;
                        }
                        last_non_delim_char = i;
                        current_mention+=c;
                    }
                }
                if (delim_space >= 0) {
                    String msg_content = params.get(1).substring(delim_space+1);
                    if (params.get(0).startsWith("#")) { // Channel msg
                        if (!mentions.contains("irc")) {
                            mentionstring+=",irc";
                        }
                    }
                    pb.write((params.get(0).startsWith("#") ? "[CGM]":"[GMS]")+nick+" "+mentionstring+" "+msg_content);
                } else {
                    String command="PRIVMSG "+nick+" :No message given. Use '@mentions message'.";
                    try {
                        chat_bridge.send(command, new TryAgainHandler(command));
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
                return;
            } else if (params.get(1).startsWith(PREFIX)) {
                String command = params.get(1).substring(PREFIX.length());
                String[] commandname_and_params = command.split(" ", 2);
                if (commandname_and_params[0].length() == 0) {
                    String reply="PRIVMSG "+nick+" :No commandname given !";
                    try {
                        chat_bridge.send(reply, new TryAgainHandler(command));
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                } else {
                    pb.write("[CMD]"+nick+" "+String.join(" ", commandname_and_params)+(commandname_and_params.length == 1 ? " ":""));
                }
                return;
            } else if (params.get(1).startsWith(Main.IRC_PREFIX)) {
                String command = params.get(1).substring(Main.IRC_PREFIX.length());
                String firstPart = command.split(" ", 2)[0];
                Command c = bot.chatcommands.get(firstPart);
                if (c != null) {
                    command = command.substring(firstPart.length());
                    String[] arguments = new String[0];
                    if (command.length() > 0) {
                        command = command.substring(1);
                    }
                    if (command.length() > 0) {
                        arguments = command.split(" ", c.getMaxArgs());
                    }
                    if (arguments.length < c.getMinArgs()) {
                        bot.sendTryAgain("PRIVMSG "+nick+" :Too few arguments supplied.");
                    } else if (arguments.length > c.getMaxArgs()) {
                        bot.sendTryAgain("PRIVMSG "+nick+" :Too many arguments supplied.");
                    } else {
                        c.execute(bot, nick, arguments);
                    }
                } else {
                    bot.sendTryAgain("PRIVMSG "+nick+" :No such chatcommand.");
                }
                return;
            }
            if (params.get(0).startsWith("#")) {
                pb.write("[MSG]"+nick+" "+params.get(1));
            } else {
                bot.sendTryAgain("PRIVMSG "+nick+" :I can only deliver your message if you use '@mentions'.");
            }
        });

        chat_bridge.commands.put("JOIN", (bot, tags, source, params) -> {
            if (source == null || params.isEmpty()) {
                return;
            }
            int indexOf=source.indexOf('!');
            String nick=indexOf >= 0 ? source.substring(0, indexOf):source;
            if (nick.equals(nickname)) {
                return;
            }
            int color=(nick.hashCode()/2 + Integer.MAX_VALUE/2) / 128;
            String colorstring=Integer.toString(color, 16);
            for (byte b=0; b < colorstring.length()-6; b++) {
                colorstring="0"+colorstring;
            }
            pb.write("[JOI]"+nick+" #"+colorstring+" "+channelname);
        });

        chat_bridge.commands.put("NICK", (bot, tags, source, params) -> {
            if (source == null || params.isEmpty()) {
                return;
            }
            int indexOf=source.indexOf('!');
            String nick=indexOf >= 0 ? source.substring(0, indexOf):source;
            pb.write("[NCK]"+nick+" "+params.get(0));
        });

        chat_bridge.commands.put("QUIT", (bot, tags, source, params) -> {
            if (source == null || params.isEmpty()) {
                return;
            }
            int indexOf=source.indexOf('!');
            String nick=indexOf >= 0 ? source.substring(0, indexOf):source;
            pb.write("[EXT]"+nick+" "+(params.size() >= 2 ? params.get(1):"no reason"));
        });

        chat_bridge.commands.put("PART", (bot, tags, source, params) -> {
            if (source == null || params.isEmpty()) {
                return;
            }
            int indexOf=source.indexOf('!');
            String nick=indexOf >= 0 ? source.substring(0, indexOf):source;
            pb.write("[BYE]"+nick+" "+(params.size() >= 2 ? params.get(1):"no reason"));
        });

        // TODO Probably Ident & SASL negotiation ?
        //chat_bridge.send("CAP LS 302");
        chat_bridge.send("NICK "+nickname);
        chat_bridge.send("USER Minetest null null :Minetest Chat Bridge"); // 0 *

        chat_bridge.send("JOIN "+channelname, new NumericTimeoutResponseHandler(20000) {
            @Override
            public HandledResponse handleNumeric(IRCBot bot, Numeric num, List<String> params) {
                switch (num) {
                    case RPL_NAMREPLY:
                        if (params.size() < 4) {
                            return HandledResponse.PASS;
                        }
                        for (String prefixednick:params.get(3).split(" ")) {
                            String nick=prefixednick;
                            if (prefixednick.charAt(0) == '~' || prefixednick.charAt(0) == '&' || prefixednick.charAt(0) == '@' || prefixednick.charAt(0) == '+' || prefixednick.charAt(0) == '%') {
                                nick=prefixednick.substring(1);
                            }
                            if (nick.equals(nickname)) {
                                continue;
                            }
                            int color=(nick.hashCode()/2 + Integer.MAX_VALUE/2) / 128;
                            String colorstring=Integer.toString(color, 16);
                            for (byte b=0; b < colorstring.length()-6; b++) {
                                colorstring="0"+colorstring;
                            }
                            pb.write("[JOI]"+nick+" #"+colorstring+" "+channelname);
                        }
                        return HandledResponse.BREAK;
                    case RPL_ENDOFNAMES:
                        return HandledResponse.RETURN;
                }
                return HandledResponse.PASS;
            }
        });

        InfoCommand help_command=new InfoCommand() {
            @Override
            public String[] execute(String nick, String... args) {
                return new String[]{"Help","Commands",
                        "- "+IRC_PREFIX+"about - General info about this bot",
                        "- "+IRC_PREFIX+"status - Status info",
                        "- "+IRC_PREFIX+"help - This help message" ,
                        "Instructions\n" ,
                        "- Destinations/targets/mentions - Use '@' followed by a comma-separated list of them\n",
                        "- Formatting - Use hexcodes in the format of '#XXXXXX'",
                        "- Minetest chatcommands - Use '"+PREFIX+"' as prefix",
                        "More",
                        "-See the GitHub Readme : "+project_url
                };
            }
        };
        chat_bridge.chatcommands.put("help", help_command);

        InfoCommand about_command=new InfoCommand() {
            @Override
            public String[] execute(String nick, String... args) {
                return new String[]{"About","A feature-rich IRC bot connecting Minetest to IRC chat channels",
                        "For more info see the GitHub Readme : "+project_url
                };
            }
        };
        chat_bridge.chatcommands.put("about", about_command);

        InfoCommand status_command=new InfoCommand() {
            @Override
            public String[] execute(String nick, String... args) {
                long duration_msecs = System.currentTimeMillis() - Main.STARTED_AT;
                String uptime=String.format("Up for %d days, %d hours, %d minutes and %d seconds", TimeUnit.DAYS.convert(duration_msecs, TimeUnit.MILLISECONDS),
                        TimeUnit.HOURS.convert(duration_msecs, TimeUnit.MILLISECONDS)%24,
                        TimeUnit.MINUTES.convert(duration_msecs, TimeUnit.MILLISECONDS)%60,
                        TimeUnit.SECONDS.convert(duration_msecs, TimeUnit.MILLISECONDS)%60);
                String memory="Currently %.2f megabyte of memory are in use";
                memory=String.format(Locale.ENGLISH, memory, ((double)(Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory())/1024/1024));
                return new String[]{"Status","Uptime",uptime,"Memory",memory
                };
            }
        };
        chat_bridge.chatcommands.put("status", status_command);

        OUT.println("INFO: Starting client");
        Main.STARTED_AT=System.currentTimeMillis();
        chat_bridge.listen();

        OUT.println("INFO: Starting server");
        pb.serve();
        OUT.println("INFO: Starting listener");
        pb.listen(line -> {
            if (line.startsWith("[MSG]")) {
                try {
                    String command="PRIVMSG #mtchatbridgetest :"+line.substring(5);
                    chat_bridge.send(command, new TryAgainHandler(command));
                } catch (IOException e) {
                    e.printStackTrace();
                }
            } else if (line.startsWith("[PMS]")) { // GMS = PMS with comma separated list of targets
                String line_content=line.substring(5);
                String[] parts=line_content.split(" ", 2);
                String command="PRIVMSG "+parts[0]+" :"+parts[1];
                try {
                    chat_bridge.send(command, new TryAgainHandler(command));
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        });

        OUT.println("INFO: Starting garbage collector");
        new GarbageCollector().start();
    }
}

package appguru;

import bridge.FileBridge;
import bridge.ProcessBridge;
import bridge.SocketBridge;
import chat.Bot;
import commands.StatusCommand;
import misc.GarbageCollector;

import javax.security.auth.login.LoginException;
import java.io.*;

import java.awt.Color;
import java.text.SimpleDateFormat;
import java.util.Date;

public class Main {
    public static long STARTED_AT;
    public static int GARBAGE_COLLECTION=5000; //5s
    public static long PING_WAIT=5000; //5s
    public static String PREFIX="!";
    public static String DISCORD_PREFIX="?";
    public static String GUILD_ID=null;

    public static PrintStream OUT=System.out;
    
    public static ProcessBridge PROCESS_BRIDGE;
    
    public static void main(String[] args) throws IOException {
        int required_args = 4;
        if (args.length < required_args) {
            OUT.println("ERR: Not enough arguments given ("+required_args+" required)");
            System.exit(1);
        }
        boolean send_embeds = true;
        if (args.length > required_args) {
            send_embeds = args[required_args].equalsIgnoreCase("true");
            required_args++;
            if (args.length > required_args) {
                File log=new File(args[required_args]);
                if (!log.isFile() || !log.canWrite()) {
                    OUT.println("ERR: Log file doesn't exist or can't be written to.");
                } else {
                    OUT = new PrintStream(new FileOutputStream(log, true));
                    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                        OUT.close();
                    }));
                }
                required_args++;
                if (args.length > required_args) {
                    PREFIX=args[required_args];
                    required_args++;
                    if (args.length > required_args) {
                        DISCORD_PREFIX=args[required_args];
                        required_args++;
                        if (args.length > required_args) {
                            GUILD_ID=args[required_args];
                        }
                    }
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
        String token=args[0];
        String channelname=args[1];
        
        if (args[2].length() == 0) {
            int socket_port=Integer.parseInt(args[3]);
            PROCESS_BRIDGE=new SocketBridge("localhost", socket_port);
        } else {
            File in=new File(args[2]);
            File out=new File(args[3]);
            if (!in.isFile() || !out.isFile() || !in.canWrite() || !in.canRead() || !out.canWrite() || !out.canRead()) {
                OUT.println("ERR: Input or output files do not exist or can't be read/written.");
                System.exit(0);
            }
            PROCESS_BRIDGE=new FileBridge(in, out);
        }

        try {
            Bot i=new Bot(token, PROCESS_BRIDGE, channelname, send_embeds);

            i.registerInfo("status", "Status", "", Color.CYAN, null);
            i.registerCommand("status", new StatusCommand());

            i.registerInfo("about","About","A Discord bot connecting in-game Minetest chat to Discord guilds. See the GitHub Readme linked in the title for more info.",Color.YELLOW, null);
            i.registerInfo("help","Help","**Commands**\n" +
                    "• "+"`"+DISCORD_PREFIX+"about` - General info about this bot\n"+
                    "• "+"`"+DISCORD_PREFIX+"help` - This help message\n" +
                    "**Instructions**\n" +
                    "• Destinations/targets/mentions - Use `@` followed by a comma-separated list of them\n"+
                    "• Formatting - Use hexcodes in the format of `#XXXXXX`\n"+
                    "• Minetest chatcommands - Use `"+PREFIX+"` as prefix\n"+
                    "**More**\n"+
                    "• See the GitHub Readme linked in the title",Color.GREEN, null);
        } catch (LoginException e) {
            System.out.println("ERR: Invalid token. Login failed.");
            return;
        }
        OUT.println("INFO: Starting garbage collector");
        new GarbageCollector().start();
    }
}

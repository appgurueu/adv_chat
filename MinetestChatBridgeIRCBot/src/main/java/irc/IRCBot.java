package irc;

import appguru.Main;
import handlers.ResponseHandler;
import handlers.TryAgainHandler;

import javax.net.ssl.*;
import java.io.IOException;
import java.net.Socket;
import java.util.*;

import static irc.HandledResponse.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;

public class IRCBot {
    public Map<String, commands.Command> chatcommands;
    public Map<String, Command> commands;
    public Default default_command;
    public List<ResponseHandler> responseHandlers=new ArrayList();
    public Socket socket;
    public IRCBot(int port, String server, boolean ssl) throws IOException {
        default_command= (bot, commandname, tags, source, params) -> {};
        chatcommands=new HashMap();
        commands=new HashMap();
        commands.put("PING", new PongCommand());
        if (ssl) {
            try {
                SSLSocketFactory ssf = (SSLSocketFactory) SSLSocketFactory.getDefault();
                SSLSocket s = (SSLSocket) ssf.createSocket(server, port);
                s.startHandshake();
                socket = s;
            } catch (Exception e) {
                Main.OUT.println("ERR: Could not create SSL socket (" + e.getMessage() + ") !");
            }
        } else {
            socket = new Socket(server, port);
        }
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            if (!socket.isClosed()) {
                try {
                    socket.close();
                } catch (IOException e) {
                    e.printStackTrace(Main.OUT);
                }
            }
        }));
    }
    public void join(String channelname) throws IOException {
        this.send("JOIN "+channelname);
    }
    public void join(String channelname, String key) throws IOException {
        this.send("JOIN "+channelname+" "+key);
    }
    public void leave(String channelname, String reason) throws IOException {
        this.send("PART "+channelname+" "+reason);
    }
    public void processMessage(String message) throws InvalidMessageException {
        HashMap<String,Object> tags=new HashMap();
        int i = 0;
        if (message.charAt(0) == '@') { // tags part...
            String tagname = "";
            String tagcontent = "";
            boolean after_equals_sign = false;
            i++;
            tag_parsing:
            for (; i < message.length(); i++) {
                char c = message.charAt(i);
                switch (c) {
                    case '=': // Tag content starts
                        after_equals_sign = true;
                        break;
                    case ';': // Tag ends
                        if (after_equals_sign) {
                            tags.put(tagname, tagcontent);
                        } else {
                            tags.put(tagname, true);
                        }
                        after_equals_sign = false;
                        tagname = "";
                        tagcontent = "";
                        break;
                    case ' ': // Tag part ends
                        break tag_parsing;
                    default:
                        if (after_equals_sign) {
                            tagcontent += c;
                        } else {
                            tagname += c;
                        }

                }
            }
            i++;
        }
        String source=null;
        if (message.charAt(i) == ':') { // source is given
            int nextSpace=message.indexOf(' ', i+1);
            if (nextSpace < 0) {
                throw new InvalidMessageException("Source part doesn't end.");
            }
            source=message.substring(i+1, nextSpace);
            i=nextSpace;
            i++;
        }
        int nextSpace=message.indexOf(' ', i+1); // Retrieve command
        if (nextSpace < 0) {
            throw new InvalidMessageException("Command part doesn't end.");
        }
        String commandname=message.substring(i, nextSpace);
        List<String> params=new ArrayList();
        String param="";
        nextSpace++;
        if (message.charAt(nextSpace) == ':') {
            params.add(message.substring(nextSpace+1));
        } else {
            main_label:
            {
                for (int j = nextSpace; j < message.length(); j++) {
                    if (message.charAt(j) == ' ') {
                        params.add(param);
                        if (message.charAt(j + 1) == ':') {
                            params.add(message.substring(j + 2));
                            break main_label;
                        }
                        param = "";
                    } else {
                        param += message.charAt(j);
                    }
                }
                params.add(param);
            }
            //params.add(param);
        }

        handleMessage:
        {
            for (int k = responseHandlers.size() - 1; k >= 0; k--) {
                ResponseHandler handler = responseHandlers.get(k);
                HandledResponse handled = handler.handle(this, commandname, tags, source, params);
                switch (handled) {
                    case BREAK:
                        break handleMessage;
                    case RETURN:
                        responseHandlers.remove(k);
                        break handleMessage;
                    case KILL:
                        responseHandlers.remove(k);
                        break;
                }
            }

            Command command = commands.get(commandname);
            if (command == null) {
                default_command.execute(this, commandname, tags, source, params);
                return;
            }
            command.execute(this, tags, source, params);
        }
    }
    public void listen() {
        Thread listenerThread = new Thread(() -> {
            BufferedReader reader=null;
            try {
                reader=new BufferedReader(new InputStreamReader(socket.getInputStream(), "UTF-8"));
            } catch (IOException e) {
                e.printStackTrace(Main.OUT);
                if (socket.isClosed() || socket.isInputShutdown() || socket.isOutputShutdown()) {
                    Main.PROCESS_BRIDGE.kill("Socket connection lost");
                }
                System.exit(1);
            }
            while (true) {
                try {
                    Thread.sleep(20);
                } catch (InterruptedException e) {
                    return;
                }
                try {
                    String message;
                    while ((message = reader.readLine()) != null) {
                        try {
                            processMessage(message);
                        } catch (InvalidMessageException e) {
                            e.printStackTrace(Main.OUT);
                        }
                    }
                } catch (IOException e) {
                    e.printStackTrace(Main.OUT);
                    if (socket.isClosed() || socket.isInputShutdown() || socket.isOutputShutdown()) {
                        Main.PROCESS_BRIDGE.kill("Socket connection lost");
                    }
                }
            }
        });
        listenerThread.start();
    }
    public void send(String message) throws IOException {
        if (socket.isClosed() || socket.isOutputShutdown()) {
            Main.PROCESS_BRIDGE.kill("Socket connection lost");
        }
        socket.getOutputStream().write(message.getBytes("UTF-8"));
        socket.getOutputStream().write('\r');
        socket.getOutputStream().write('\n');
    }
    public void send(String message, ResponseHandler response_handler) throws IOException {
        this.send(message);
        responseHandlers.add(response_handler);
    }
    public void sendTryAgain(String command) {
        try {
            send(command, new TryAgainHandler(command));
        } catch (IOException e) {
            e.printStackTrace(Main.OUT);
        }
    }
    public void shutdown(String reason) {
        try {
            this.send("QUIT :" + reason);
        } catch (IOException e) {
            e.printStackTrace(Main.OUT);
        }
        if (!this.socket.isClosed()) {
            try {
                this.socket.close();
            } catch (IOException e) {
                e.printStackTrace(Main.OUT);
            }
        }
    }
}

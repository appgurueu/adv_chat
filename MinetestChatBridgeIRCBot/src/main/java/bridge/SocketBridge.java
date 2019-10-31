package bridge;

import appguru.Main;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.function.Consumer;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author lars
 */
public class SocketBridge extends ProcessBridge {
    private Socket socket;
    private final BufferedWriter writer;
    private BufferedReader reader;
    
    public SocketBridge(String host, int port) throws IOException {
        socket = new Socket();
        socket.connect(new InetSocketAddress(host, port));
        writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));
        reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
    }

    @Override
    public void kill(String reason) {
        Main.OUT.println("INFO: "+reason);
        if (socket.isConnected()) {
            try {
                writer.write("[KIL]"+reason);
            } catch (IOException ex) {
                ex.printStackTrace(Main.OUT);
            }
        }
        try {
            writer.close();
            reader.close();
            socket.close();
        } catch (IOException ex) {
            ex.printStackTrace(Main.OUT);
        } finally {
            Main.OUT.close();
            System.exit(1);
        }
    }

    @Override
    public void write(String out) {
        synchronized (writer) {
            try {
                writer.write(out+"\n");
                writer.flush();
            } catch (IOException ex) {
                ex.printStackTrace(Main.OUT);
            }
        }
    }

    @Override
    public void serve() {
    }

    @Override
    public void listen(Consumer<String> line_consumer) {
        ping();
        new Thread(() -> {
            while(true) {
                try {
                    Thread.sleep(20);
                } catch (InterruptedException e) {
                    e.printStackTrace(Main.OUT);
                }
                String line = null;
                try {
                    line = reader.readLine();
                } catch (IOException e) {
                    e.printStackTrace(Main.OUT);
                    if (socket.isClosed() || socket.isInputShutdown() || socket.isOutputShutdown()) {
                        kill("Socket connection lost");
                    }
                }
                boolean one_line = line != null;
                while (line != null) {

                    if (line.startsWith("[PIN]")) { // A PING YAY
                        ping();
                    } else if (line.startsWith("[KIL]")) {
                        kill("Minetest server shutting down; shutting down as well.");
                    } else {
                        line_consumer.accept(line);
                    }

                    try {
                        line = reader.readLine();
                    } catch (IOException e) {
                        e.printStackTrace(Main.OUT);
                    }
                }
                if (System.currentTimeMillis()-last_ping > Main.PING_WAIT) {
                    kill("No ping during the last "+(Main.PING_WAIT/1000)+"s; shutting down.");
                }
            }
        }).start();
    }
    
}

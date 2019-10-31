package bridge;

import appguru.Main;

import java.io.*;
import java.util.function.Consumer;

public class FileBridge extends ProcessBridge {

    public File out_file;
    public File in;
    public PrintWriter out;
    private long last_ping_sent;

    public FileBridge(File in, File out) throws IOException {
        this.out = new PrintWriter(new BufferedWriter(new FileWriter(out, true)));
        this.out_file=out;
        this.in=in;
        this.last_ping_sent=System.currentTimeMillis();
    }

    public void kill(String reason) {
        Main.OUT.println("INFO: "+reason);
        FileWriter fw = null;
        try {
            fw = new FileWriter(in);
            fw.write("");
            fw.close();
        } catch (IOException e) {
            e.printStackTrace(Main.OUT);
        }
        Main.OUT.close();
        out.write("[KIL]"+reason);
        out.close();
        System.exit(0);
    }

    public void write(String out) {
        this.out.println(out);
    }

    public void serve() {
        new Thread() {
            public void run() {
                while(true) {
                    try {
                        Thread.sleep(20);
                    } catch (InterruptedException e) {
                        e.printStackTrace(Main.OUT);
                    }
                    if (System.currentTimeMillis()-last_ping_sent >= 1000) {
                        out.write("[PIN]");
                    }
                    // Main.OUT.flush();
                    out.flush();
                    out.close();
                    try {
                        out = new PrintWriter(new BufferedWriter(new FileWriter(out_file, true)));
                    } catch (IOException e) {
                        e.printStackTrace(Main.OUT);
                    }
                }
            }
        }.start();
    }

    public void listen(Consumer<String> line_consumer) {
        ping();
        new Thread(() -> {
            while(true)

            {
                try {
                    Thread.sleep(20);
                } catch (InterruptedException e) {
                    e.printStackTrace(Main.OUT);
                }
                BufferedReader r = null;
                try {
                    r = new BufferedReader(new FileReader(in));
                } catch (FileNotFoundException e) {
                    e.printStackTrace(Main.OUT);
                }
                String line = null;
                try {
                    line = r.readLine();
                } catch (IOException e) {
                    e.printStackTrace(Main.OUT);
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
                        line = r.readLine();
                    } catch (IOException e) {
                        e.printStackTrace(Main.OUT);
                    }
                }
                if (System.currentTimeMillis()-last_ping > Main.PING_WAIT) {
                    kill("No ping during the last "+(Main.PING_WAIT/1000)+"s; shutting down.");
                }
                if (one_line) {
                    try {
                        FileWriter fw = new FileWriter(in);fw.write("");fw.close();
                    } catch (IOException e) {
                        e.printStackTrace(Main.OUT);
                    }
                }
            }
        }).start();
    }
}
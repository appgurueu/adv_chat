package bridge;

import appguru.Main;

import java.io.*;
import java.util.function.Consumer;

public class ProcessBridge {
    public static long PING_WAIT=20000; //20s

    public long last_ping;
    public void ping() {
        last_ping=System.currentTimeMillis();
    }
    public File out_file;
    public File in;
    public PrintWriter out;

    public ProcessBridge(File in, File out) throws IOException {
        this.out = new PrintWriter(new BufferedWriter(new FileWriter(out, true)));
        this.out_file=out;
        this.in=in;
    }

    public void kill(String reason) {
        Main.OUT.println("INFO: "+reason);
        FileWriter fw = null;
        try {
            fw = new FileWriter(in);
            fw.write("");
            fw.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        Main.OUT.close();
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
                        e.printStackTrace();
                    }
                    Main.OUT.flush();
                    out.flush();
                    out.close();
                    try {
                        out = new PrintWriter(new BufferedWriter(new FileWriter(out_file, true)));
                    } catch (IOException e) {
                        e.printStackTrace();
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
                    e.printStackTrace();
                }
                BufferedReader r = null;
                try {
                    r = new BufferedReader(new FileReader(in));
                } catch (FileNotFoundException e) {
                    e.printStackTrace();
                }
                String line = null;
                try {
                    line = r.readLine();
                } catch (IOException e) {
                    e.printStackTrace();
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
                        e.printStackTrace();
                    }
                }
                if (System.currentTimeMillis()-last_ping > Main.PING_WAIT) {
                    kill("No ping during the last "+(Main.PING_WAIT/1000)+"s; shutting down.");
                }
                if (one_line) {
                    try {
                        FileWriter fw = new FileWriter(in);fw.write("");fw.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }).start();
    }
}
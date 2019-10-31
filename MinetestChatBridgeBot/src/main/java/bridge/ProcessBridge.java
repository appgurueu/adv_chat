package bridge;

import java.util.function.Consumer;

public abstract class ProcessBridge {
    public long last_ping;
    public void ping() {
        last_ping=System.currentTimeMillis();
    }
    
    public abstract void kill(String reason);

    public abstract void write(String out);

    public abstract void serve();

    public abstract void listen(Consumer<String> line_consumer);
}
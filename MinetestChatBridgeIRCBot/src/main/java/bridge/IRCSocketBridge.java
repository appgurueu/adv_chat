package bridge;

import appguru.Main;
import java.io.IOException;

/**
 *
 * @author lars
 */
public class IRCSocketBridge extends SocketBridge {
    public IRCSocketBridge(String host, int port) throws IOException {
        super(host, port);
    }
    
    @Override
    public void kill(String reason) {
        super.kill(reason);
        
        Main.CHAT_BRIDGE.shutdown(reason);
        
        System.exit(0);
    }
}

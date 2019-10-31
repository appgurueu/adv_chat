package bridge;

import appguru.Main;
import java.io.File;
import java.io.IOException;

/**
 *
 * @author lars
 */
public class IRCFileBridge extends FileBridge {

    public IRCFileBridge(File in, File out) throws IOException {
        super(in, out);
    }
    
    @Override
    public void kill(String reason) {
        super.kill(reason);
        
        Main.CHAT_BRIDGE.shutdown(reason);

        System.exit(0);
    }
}

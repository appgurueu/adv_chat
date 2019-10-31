package commands;

import chat.Bot;
import net.dv8tion.jda.api.events.message.MessageReceivedEvent;

public abstract class Command {

    public int getMinArgs() {
        return 1;
    }

    public int getMaxArgs() {
        return 1;
    }

    public boolean isStaffOnly() {
        return false;
    }

    public abstract void execute(Bot b, MessageReceivedEvent e, String... args);
}

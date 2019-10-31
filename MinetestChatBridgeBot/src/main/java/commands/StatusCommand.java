package commands;

import appguru.Main;
import chat.Bot;
import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.events.message.MessageReceivedEvent;

import java.util.Locale;
import java.util.concurrent.TimeUnit;

public class StatusCommand extends Command {

    @Override
    public int getMinArgs() {
        return 0;
    }

    @Override
    public int getMaxArgs() {
        return 0;
    }

    @Override
    public void execute(Bot b, MessageReceivedEvent e, String... args) {
        EmbedBuilder eb=b.embed.get("status");
        long duration_msecs = System.currentTimeMillis() - Main.STARTED_AT;
        String uptime=String.format("Up for %d days, %d hours, %d minutes and %d seconds", TimeUnit.DAYS.convert(duration_msecs, TimeUnit.MILLISECONDS),
                TimeUnit.HOURS.convert(duration_msecs, TimeUnit.MILLISECONDS)%24,
                TimeUnit.MINUTES.convert(duration_msecs, TimeUnit.MILLISECONDS)%60,
                TimeUnit.SECONDS.convert(duration_msecs, TimeUnit.MILLISECONDS)%60);
        String memory="**Memory**\nCurrently %.2f megabyte of memory are in use\n";
        memory=String.format(Locale.ENGLISH, memory, ((double)(Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory())/1024/1024));
        String description="**Uptime**\n"+uptime+"\n"+
                memory+
                "**Ping**\n";
        e.getAuthor().openPrivateChannel().queue(pc -> {
            final long millis=System.currentTimeMillis();
            pc.sendMessage("Pinging...").queue(test_ping -> {
                synchronized (eb) {
                    long current_millis = System.currentTimeMillis();
                    eb.setDescription(description + "Ping took " + (current_millis - millis) + " milliseconds");
                    pc.sendMessage(eb.build()).queue();
                    test_ping.delete().queue();
                }
            });
        });
    }
}

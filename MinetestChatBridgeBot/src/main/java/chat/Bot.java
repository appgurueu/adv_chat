package chat;

import appguru.Main;
import bridge.ProcessBridge;
import com.google.common.collect.HashBiMap;
import commands.Command;
import misc.Utils;
import net.dv8tion.jda.api.*;
import net.dv8tion.jda.api.entities.*;
import net.dv8tion.jda.api.events.ReadyEvent;
import net.dv8tion.jda.api.events.channel.text.TextChannelCreateEvent;
import net.dv8tion.jda.api.events.channel.text.TextChannelDeleteEvent;
import net.dv8tion.jda.api.events.channel.text.update.*;
import net.dv8tion.jda.api.events.guild.GuildJoinEvent;
import net.dv8tion.jda.api.events.guild.member.*;
import net.dv8tion.jda.api.events.message.MessageReceivedEvent;
import net.dv8tion.jda.api.events.role.RoleCreateEvent;
import net.dv8tion.jda.api.events.role.RoleDeleteEvent;
import net.dv8tion.jda.api.events.role.update.RoleUpdateColorEvent;
import net.dv8tion.jda.api.events.role.update.RoleUpdateNameEvent;
import net.dv8tion.jda.api.hooks.ListenerAdapter;

import javax.security.auth.login.LoginException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.*;

import java.awt.Color;
import net.dv8tion.jda.api.events.guild.member.update.GuildMemberUpdateNicknameEvent;

public class Bot extends ListenerAdapter {
    public static int DEFAULT_COLOR=Integer.parseInt("7289DA",16); // Discord color

    public String text_channel;
    public ProcessBridge bridge;
    public JDA jda;

    public void setGlobalChannel(long global_channel) {
        this.global_channel = global_channel;
    }

    public long global_channel;
    public String readmeURL="https://github.com/appgurueu/adv_chat";
    public HashMap<String, EmbedBuilder> embed=new HashMap();
    public HashMap<String, Command> commands=new HashMap();
    public HashBiMap<String, Long> members=HashBiMap.create();
    public HashBiMap<String, Long> roles=HashBiMap.create();

    public EmbedBuilder error;
    public EmbedBuilder success;
    public EmbedBuilder message;

    public Bot(String token, ProcessBridge pb, String text_channel) throws LoginException {
        Main.OUT.println("INFO: Starting client");
        JDABuilder builder=new JDABuilder(AccountType.BOT);
        builder.setToken(token);
        jda=builder.build();
        bridge=pb;

        this.text_channel=text_channel;

        error=new EmbedBuilder();
        error.setColor(new Color(255, 0,0));
        error.setTitle("Error");

        success=new EmbedBuilder();
        success.setColor(new Color(0, 255,0));
        success.setTitle("Success");

        message=new EmbedBuilder();

        jda.addEventListener(this);
    }

    public Guild getGuild() {
        return this.jda.getGuildById(Main.GUILD_ID);
    }

    @Override
    public void onTextChannelDelete(TextChannelDeleteEvent event) {
        if (event.getChannel().getIdLong() == global_channel) {
            System.err.println("Error ! Global channel was deleted !");
            System.exit(1);
        }
    }
    
    @Override
    public void onTextChannelUpdatePermissions(TextChannelUpdatePermissionsEvent event) {
        if (event.getChannel().getIdLong() == global_channel && !event.getChannel().canTalk()) {
            System.err.println("Error ! Cannot talk in global channel !");
            System.exit(1);
        }
    }
    
    @Override
    public void onTextChannelUpdateNSFW(TextChannelUpdateNSFWEvent event) {}
    @Override
    public void onTextChannelUpdateParent(TextChannelUpdateParentEvent event) {}
    @Override
    public void onTextChannelCreate(TextChannelCreateEvent event) {}

    @Override
    public void onGuildJoin(GuildJoinEvent e) {
        /*Iterator it=jda.getGuildCache().iterator();it.hasNext();
        if (it.hasNext()) {
            e.getGuild().leave().queue();
        }*/
        // IDEA: leave
    }
    
    public String escapeName(String name) {
        return name.replace(" ", "_").replace(",", "_");
    }

    @Override
    public void onGuildMemberJoin(GuildMemberJoinEvent e) {
        Member m=e.getMember();
        String name=escapeName(m.getEffectiveName());
        members.put(Utils.getFreeKey(name, members), m.getUser().getIdLong());
        bridge.write("[JOI]"+name+" #"+ Utils.getColorString(m.getColorRaw()));
    }

    @Override
    public void onGuildMemberLeave(GuildMemberLeaveEvent e) {
        bridge.write("[EXT]"+members.inverse().get(e.getMember().getUser().getIdLong()));
    }

    public synchronized MessageEmbed buildMessage(String msg, Color color) {
        message.setColor(color);
        message.setDescription(msg);
        message.setTimestamp(Instant.now());
        return message.build();
    }

    public void sendToAll(String message, Color color) {
        sendToAll(buildMessage(message, color));
    }

    public void sendToAll(MessageEmbed message) {
        jda.getTextChannelById(global_channel).sendMessage(message).queue();
    }

    public void sendToMembers(String message, Color c, String... targets) {
        sendToMembers(buildMessage(message, c), targets);
    }

    public void sendToMembers(MessageEmbed m, String... targets) {
        for (String member:targets) {
            sendToMember(member, m);
        }
    }

    public void sendToMember(String member, MessageEmbed m) {
        Long member_id=members.get(member);
        if (member_id != null) {
            jda.getUserById(member_id).openPrivateChannel().queue(pc -> pc.sendMessage(m).queue());
        }
    }

    @Override
    public void onReady(ReadyEvent event) {
        if (event.getJDA().getGuildCache().size() == 0) {
            Main.OUT.println("INFO: Not in any guild currently");
            System.exit(0);
        }
        Main.STARTED_AT=System.currentTimeMillis();
        Guild chosen=event.getJDA().getGuildById(Main.GUILD_ID);
        if (chosen == null) {
            List<Guild> guilds=event.getJDA().getGuilds();
            String guild_id=guilds.get(0).getId();
            OffsetDateTime min_join_time=guilds.get(0).getMember(event.getJDA().getSelfUser()).getTimeJoined();
            for (int i=1; i < guilds.size(); i++) {
                Guild g=guilds.get(i);
                OffsetDateTime join_time=guilds.get(i).getMember(event.getJDA().getSelfUser()).getTimeJoined();
                if (join_time.isBefore(min_join_time)) {
                    min_join_time=join_time;
                    guild_id=g.getId();
                }
            }
            Main.OUT.println("INFO: Guild ID "+(Main.GUILD_ID==null ? "not set":"invalid")+"; falling back to using the first joined guild (ID: "+guild_id+")");
            Main.GUILD_ID=guild_id;
        }
        setGlobalChannel(getGuild().getTextChannelsByName(text_channel, true).get(0).getIdLong());
        event.getJDA().getPresence().setActivity(Activity.playing("Minetest"));
        for (Member m:getGuild().getMemberCache()) {
            String name=escapeName(m.getEffectiveName());
            String finalname=Utils.getFreeKey(name, members);
            members.put(finalname, m.getUser().getIdLong());
            int color=m.getColor() == null ? DEFAULT_COLOR:m.getColorRaw();
            bridge.write("[LIS]"+finalname+" #"+ Utils.getColorString(color));
        }
        for (Role r:getGuild().getRoles()) {
            String name=escapeName(r.getName());
            String finalname=Utils.getFreeKey(name, roles);
            String output="[ROL]"+finalname+" #"+Utils.getColorString(r.getColorRaw());
            for (Member m:getGuild().getMembersWithRoles(r)) {
                String membername=members.inverse().get(m.getUser().getIdLong());
                output+=" "+membername;
            }
            bridge.write(output);
            roles.put(finalname, r.getIdLong());
        }
        Main.OUT.println("INFO: Starting server");
        bridge.serve();
        Main.OUT.println("INFO: Starting listener");
        bridge.listen(line -> {
            String linecontent=line.substring(5);
            if (line.startsWith("[MSG]")) {
                String[] color_and_message=linecontent.split(" ", 2);
                this.sendToAll(color_and_message[1], new Color(Integer.parseInt(color_and_message[0].substring(1), 16)));
            } else if (line.startsWith("[ERR]")) {
                String[] lineparts=linecontent.split(" ", 2);
                //error.setTimestamp(Instant.now());
                error.setDescription(lineparts[1]);
                sendToMember(lineparts[0], error.build());
            } else if (line.startsWith("[SUC]")) {
                String[] lineparts=linecontent.split(" ", 2);
                //success.setTimestamp(Instant.now());
                success.setDescription(lineparts[1]);
                sendToMember(lineparts[0], success.build());
            } else if (line.startsWith("[PMS]")) {
                String line_content=line.substring(5);
                String[] parts=line_content.split(" ", 3); // Color, targets and message - No need to handle stuff like blocks, already done by MT
                sendToMembers(parts[2], new Color(Integer.parseInt(parts[0].substring(1), 16)), parts[1].split(","));
            }
        });
    }

    @Override
    public void onRoleCreate(RoleCreateEvent event) {
        String name=escapeName(event.getRole().getName());
        String output="[ROL]"+Utils.getFreeKey(name, roles)+" #"+Utils.getColorString(event.getRole().getColorRaw());
        bridge.write(output);
    }


    @Override
    public void onRoleUpdateName(RoleUpdateNameEvent event) {
        String oldname=roles.inverse().get(event.getRole().getIdLong());
        String name=Utils.getFreeKey(escapeName(event.getNewName()), roles);
        roles.inverse().remove(event.getRole().getIdLong());
        roles.put(name, event.getRole().getIdLong());
        String output="[NAM]"+oldname+" "+name;
        bridge.write(output);
    }

    @Override
    public void onRoleUpdateColor(RoleUpdateColorEvent event) {
        String output="[COL]"+roles.inverse().get(event.getRole().getIdLong())+" #"+Utils.getColorString(event.getRole().getColorRaw());
        bridge.write(output);
    }

    @Override
    public void onRoleDelete(RoleDeleteEvent event) {
        bridge.write("[DEL]"+roles.inverse().get(event.getRole().getIdLong()));
    }

    @Override
    public void onGuildMemberRoleAdd(GuildMemberRoleAddEvent event) {
        for (Role r:event.getRoles()) {
            bridge.write("[ADD]" + roles.inverse().get(r.getIdLong()) + " " + members.inverse().get(event.getUser().getIdLong()));
        }
    }

    @Override
    public void onGuildMemberRoleRemove(GuildMemberRoleRemoveEvent event) {
        for (Role r:event.getRoles()) {
            bridge.write("[REM]" + roles.inverse().get(r.getIdLong()) + " " + members.inverse().get(event.getUser().getIdLong()));
        }
    }

    @Override
    public void onGuildMemberUpdateNickname(GuildMemberUpdateNicknameEvent event) {
        String newnick=escapeName((event.getNewNickname() != null ? event.getNewNickname():event.getUser().getName()));
        if (members.containsKey(newnick)) {
            getGuild().modifyNickname(event.getMember(), event.getOldNickname()).queue();
            event.getMember().getUser().openPrivateChannel().queue(pc -> pc.sendMessage("Your nickname could not be changed to `"+event.getNewNickname()+"` as there already is another guild member with a similar nickname.").queue());
        } else {
            members.inverse().remove(event.getMember().getUser().getIdLong());
            members.put(newnick, event.getMember().getUser().getIdLong());
        }
    }

    public static String getName(Member m) {
        return m.getEffectiveName()+(m.getNickname() == null ? "":" aka "+m.getUser().getName())+" #"+m.getUser().getDiscriminator();
    }

    public void registerInfo(String command, String title, String info, Color c, String url) {
        EmbedBuilder eb=new EmbedBuilder();
        if (url == null) {
            eb.setTitle(title,readmeURL+"#"+title.toLowerCase());
        } else {
            eb.setTitle(title,url);
        }
        eb.setAuthor("Minetest Chat Bridge",readmeURL);
        eb.setDescription(info /*.replace("\n-","\n•")*/);
        eb.setColor(c);
        embed.put(command,eb);
    }

    public void registerCommand(String command, Command c) {
        commands.put(command,c);
    }

    public void handleMessage(long sender_id, String cmd, boolean privmsg) {
        String discordname=members.inverse().get(sender_id);
        if (cmd.charAt(0) == '@') { //mentions used
            String mentionstring = "";
            Set<String> mentions = new HashSet();
            String current_mention = "";
            int delim_space = -1;
            int last_non_delim_char = -1;
            for (int i = 1; i < cmd.length(); i++) {
                char c = cmd.charAt(i);
                if (c == ',') {
                    if (current_mention.length() > 0) {
                        if (!mentions.contains(current_mention)) {
                            mentions.add(current_mention);
                            mentionstring += current_mention + ",";
                        }
                    }
                    current_mention = "";
                    last_non_delim_char = -1;
                } else if (c != ' ') {
                    if (last_non_delim_char >= 0 && i - last_non_delim_char > 1) {
                        if (current_mention.length() > 0) {
                            if (!mentions.contains(current_mention)) {
                                mentions.add(current_mention);
                                mentionstring += current_mention;
                            }
                        }
                        delim_space = i - 1;
                        break;
                    }
                    last_non_delim_char = i;
                    current_mention += c;
                }
            }
            if (delim_space >= 0) {
                String msg_content = cmd.substring(delim_space + 1);
                if (!privmsg && !mentions.contains("discord")) {
                    mentionstring += ",discord";
                }
                bridge.write((privmsg ? "[GMS]" : "[CGM]") + discordname + " " + mentionstring + " " + msg_content);
            } else {
                jda.getUserById(sender_id).openPrivateChannel().queue(pc -> pc.sendMessage("No message given. Use `@mentions message`.").queue());
            }
        } else {
            if (privmsg) {
                jda.getUserById(sender_id).openPrivateChannel().queue(pc -> pc.sendMessage("I cannot deliver your message without `@mentions` specifying targets.").queue());
            } else {
                bridge.write("[MSG]"+discordname+" "+cmd);
            }
        }
    }

    public void handleMessageReceived(MessageReceivedEvent event, boolean is_privmsg) {
        if (event.getAuthor().getIdLong() != jda.getSelfUser().getIdLong()) {
            String[] messages=event.getMessage().getContentRaw().split("\n");
            for (String cmd:messages) {
                if (cmd.startsWith(Main.PREFIX)) {
                    String command = cmd.substring(Main.PREFIX.length());
                    String[] commandname_and_params = command.split(" ", 2);
                    if (commandname_and_params[0].length() == 0) {
                        error.setDescription("No commandname given!");
                        error.setTimestamp(Instant.now());
                        event.getAuthor().openPrivateChannel().queue(pc -> pc.sendMessage(error.build()).queue());
                    } else {
                        String discordname=members.inverse().get(event.getAuthor().getIdLong());
                        bridge.write("[CMD]"+discordname+" "+String.join(" ", commandname_and_params)+(commandname_and_params.length == 1 ? " ":""));
                    }
                }
                else if (cmd.startsWith(Main.DISCORD_PREFIX)) {
                    String command = cmd.substring(Main.DISCORD_PREFIX.length());
                    String firstPart = command.split(" ", 2)[0];
                    Command c = commands.get(firstPart);
                    if (c != null) {
                        if (c.isStaffOnly()) {
                            abort:
                            {
                                if (!event.getMember().isOwner() && !event.getMember().hasPermission(Permission.MANAGE_SERVER)) {
                                    error.setDescription("Only the server owner or members with the `MANAGE_SERVER` permission may use this command.");
                                    error.setTimestamp(Instant.now());
                                    event.getAuthor().openPrivateChannel().queue(pc -> pc.sendMessage(error.build()).queue());
                                    return;
                                }
                            }
                        }
                        command = command.substring(firstPart.length());
                        String[] args = new String[]{};
                        if (command.length() > 0) {
                            command = command.substring(1);
                            int terminator = command.lastIndexOf("\n");
                            if (terminator < 0) {
                                terminator = command.length();
                            }
                            command = command.substring(0, terminator);
                        }
                        if (command.length() > 0) {
                            args = command.split(" ", c.getMaxArgs());
                        }
                        if (args.length < c.getMinArgs()) {
                            error.setDescription("Too few arguments supplied.");
                            error.setTimestamp(Instant.now());
                            event.getAuthor().openPrivateChannel().queue(pc -> pc.sendMessage(error.build()).queue());
                        } else if (args.length > c.getMaxArgs()) {
                            error.setDescription("Too many arguments supplied.");
                            error.setTimestamp(Instant.now());
                            event.getAuthor().openPrivateChannel().queue(pc -> pc.sendMessage(error.build()).queue());
                        } else {
                            c.execute(this, event, args);
                        }
                    } else {
                        EmbedBuilder info = embed.get(command);
                        if (info == null) {
                            return;
                        }
                        event.getAuthor().openPrivateChannel().queue(pc -> pc.sendMessage(info.build()).queue());
                    }
                }
                else {
                    handleMessage(event.getAuthor().getIdLong(), cmd, is_privmsg);
                }
            }
        }
    }

    @Override
    public void onMessageReceived(MessageReceivedEvent event) {
        handleMessageReceived(event, event.getChannelType() == ChannelType.PRIVATE);
    }

    /*@Override
    public void onPrivateMessageReceived(PrivateMessageReceivedEvent event) {
        handleMessageReceived(new MessageReceivedEvent(event.getJDA(), event.getResponseNumber(), event.getMessage()), true);
    }*/
}

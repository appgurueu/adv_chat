package irc;

public enum HandledResponse {
    KILL, PASS, BREAK, RETURN;
    // Kill : kill this handler, but pass on the command
    // Pass : pass on the command (ignore)
    // Break : "use" the command (break)
    // Return : Break and kill this handler
}

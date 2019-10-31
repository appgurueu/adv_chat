package irc;

public class InvalidMessageException extends Throwable {
    public InvalidMessageException(String s) {
        super(s);
    }
}

package misc;

import java.util.Map;

public class Utils {
    // Gets color by hash
    public static int getColorFromNick(String nick) {
        return (nick.hashCode()/2 + Integer.MAX_VALUE/2) / 128;
    }
    public static String getColorString(int color) {
        String colorstring=Integer.toString(Math.min(color, 0xFFFFFF), 16);
        for (byte b=0; b < colorstring.length()-6; b++) {
            colorstring="0"+colorstring;
        }
        return colorstring;
    }


    public static String getFreeKey(String desired, Map<String, ?> map) {
        if (map.containsKey(desired)) {
            int number = 2;
            while (map.containsKey(desired + number)) {
                number++;
            }
            return desired+number;
        }
        return desired;
    }
}

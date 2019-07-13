package misc;

import appguru.Main;

public class GarbageCollector extends Thread {
    @Override
    public void run() {
        while (true) {
            try {
                Thread.sleep(Main.GARBAGE_COLLECTION);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.gc();
        }
    }
}

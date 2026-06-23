import com.google.adk.core.Event;
public class Test {
    public static void main(String[] args) {
        for (java.lang.reflect.Method m : Event.class.getMethods()) {
            System.out.println(m.getName());
        }
    }
}

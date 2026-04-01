package growerp

import org.moqui.context.ExecutionContext
import java.sql.Timestamp
import java.util.Calendar

class GrowErpDateTimeUtil {
    public static final String TIMESTAMP_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    public static final String DATE_FORMAT = "yyyy-MM-dd"

    static String formatTimestamp(ExecutionContext ec, Timestamp ts) {
        return ts != null ? ec.l10n.format(ts, TIMESTAMP_FORMAT) : null
    }

    static String formatDate(ExecutionContext ec, java.util.Date date) {
        return date != null ? ec.l10n.format(date, DATE_FORMAT) : null
    }

    static Timestamp parseTimestamp(ExecutionContext ec, String str) {
        if (str == null || str.isEmpty()) return null
        // Moqui's parseTimestamp handles ISO 8601 robustly
        // If it contains 'T', Moqui handles it. If it's the space format, it also handles it.
        return ec.l10n.parseTimestamp(str, null)
    }

    static Timestamp getEndOfDay(Timestamp ts) {
        if (ts == null) return null
        Calendar cal = Calendar.getInstance()
        cal.setTime(ts)
        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 59)
        cal.set(Calendar.SECOND, 59)
        cal.set(Calendar.MILLISECOND, 999)
        return new Timestamp(cal.getTimeInMillis())
    }

    static Timestamp truncateToDate(Timestamp ts) {
        if (ts == null) return null
        Calendar cal = Calendar.getInstance()
        cal.setTime(ts)
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return new Timestamp(cal.getTimeInMillis())
    }

    static Integer getYear(Timestamp ts) {
        if (ts == null) return null
        Calendar cal = Calendar.getInstance()
        cal.setTime(ts)
        return cal.get(Calendar.YEAR)
    }
}

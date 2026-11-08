package ma.emsi.emsidrive.schedule.service;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.LocalTime;
import java.util.*;

/** Derives course boundaries from the full visual cell span instead of a default session duration. */
final class TimetableTimeResolver {
    record Column(String start, String end) {}
    record Times(String start, String end, boolean needsReview) {}

    private final Map<Integer, Column> columns;

    TimetableTimeResolver(JsonNode headers) {
        var parsed = new LinkedHashMap<Integer, Column>();
        if (headers.isArray() && !headers.isEmpty() && headers.size() <= 24) {
            String previousEnd = null;
            for (JsonNode header : headers) {
                int index = header.path("index").asInt(-1);
                String start = time(header, "startTime"), end = time(header, "endTime");
                if (!header.path("index").isIntegralNumber() || index != parsed.size() + 1
                        || start == null || end == null || start.compareTo(end) >= 0
                        || (previousEnd != null && start.compareTo(previousEnd) < 0)) {
                    parsed.clear(); break;
                }
                parsed.put(index, new Column(start, end)); previousEnd = end;
            }
        }
        columns = Map.copyOf(parsed);
    }

    Times resolve(JsonNode row) {
        JsonNode evidence = row.path("timeEvidence");
        String start = time(row, "startTime"), end = time(row, "endTime");
        boolean certain = evidence.path("spanCertain").isBoolean() && evidence.path("spanCertain").asBoolean();
        if (certain && "EXPLICIT".equals(evidence.path("source").asText())) {
            // Hours actually written in the course cell override the generic column headers.
            return new Times(start, end, start == null || end == null || start.compareTo(end) >= 0);
        }
        if (certain && "HEADERS".equals(evidence.path("source").asText())
                && evidence.path("startColumn").isIntegralNumber() && evidence.path("endColumn").isIntegralNumber()) {
            int first = evidence.path("startColumn").asInt(-1), last = evidence.path("endColumn").asInt(-1);
            if (first > 0 && last >= first && columns.containsKey(first) && columns.containsKey(last)) {
                // A two-column cell ends at the end of the SECOND column, even if the model
                // copied only the first column's end into endTime. Preserve gaps between sessions.
                return new Times(columns.get(first).start(), columns.get(last).end(), false);
            }
        }
        // An unverified right boundary must not silently shorten a possible double session.
        return new Times(start, null, true);
    }

    static String time(JsonNode row, String field) {
        JsonNode value = row.path(field);
        if (!value.isTextual() || !value.asText().matches("\\d{2}:\\d{2}")) return null;
        try { LocalTime.parse(value.asText()); return value.asText(); }
        catch (RuntimeException ex) { return null; }
    }
}

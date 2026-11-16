package ma.emsi.emsidrive.schedule.service;

import java.sql.Time;
import java.sql.Date;
import java.util.*;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.ride.marketplace.MarrakechArea;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplace;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.*;
import ma.emsi.emsidrive.schedule.dto.ScheduleDtos.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Matches real bookable offers using the owner's attendance windows and private city point. */
@Service
public class ScheduleMatchingService {
    private final JdbcTemplate jdbc;
    private final ScheduleService schedules;
    private final RideMarketplace marketplace;
    private final MarrakechArea area;

    public ScheduleMatchingService(JdbcTemplate jdbc, ScheduleService schedules, RideMarketplace marketplace, MarrakechArea area) {
        this.jdbc = jdbc; this.schedules = schedules; this.marketplace = marketplace; this.area = area;
    }

    public TravelPreferences preferences(UUID user) {
        var rows = jdbc.query("SELECT * FROM schedule_travel_preferences WHERE user_id = ?", (rs, i) ->
                new TravelPreferences(Campus.valueOf(rs.getString("campus")), new Point(rs.getBigDecimal("latitude"), rs.getBigDecimal("longitude")),
                        rs.getInt("radius_meters"), rs.getInt("commute_minutes"), rs.getInt("margin_minutes")), user);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public TravelPreferences savePreferences(UUID user, TravelPreferences request) {
        if (!area.contains(request.point())) throw ApiException.badRequest("OUTSIDE_MARRAKECH", "City point outside supported area");
        jdbc.update("""
                INSERT INTO schedule_travel_preferences(user_id,campus,latitude,longitude,radius_meters,commute_minutes,margin_minutes)
                VALUES (?,?,?,?,?,?,?) ON CONFLICT(user_id) DO UPDATE SET campus=excluded.campus,latitude=excluded.latitude,
                longitude=excluded.longitude,radius_meters=excluded.radius_meters,commute_minutes=excluded.commute_minutes,
                margin_minutes=excluded.margin_minutes,updated_at=now()
                """, user, request.campus().name(), request.point().latitude(), request.point().longitude(),
                request.radiusMeters(), request.commuteMinutes(), request.marginMinutes());
        return preferences(user);
    }

    @Transactional(readOnly = true, isolation = org.springframework.transaction.annotation.Isolation.REPEATABLE_READ)
    public List<RideMatch> matches(UUID user, Integer commuteOverride) {
        var schedule = schedules.current(user);
        var preferences = preferences(user);
        if (preferences == null) throw ApiException.badRequest("SCHEDULE_TRAVEL_REQUIRED", "Choose a campus and city point");
        int commute = commuteOverride == null ? preferences.commuteMinutes() : commuteOverride;
        if (commute < 5 || commute > 180) throw ApiException.badRequest("VALIDATION_ERROR", "Invalid commute duration");
        String campus = "EMSI Marrakech " + (preferences.campus() == Campus.TARGA ? "Targa" : "Centre");
        var rows = jdbc.queryForList("""
                WITH settings AS (SELECT ?::text campus, ?::double precision latitude, ?::double precision longitude),
                days AS (SELECT weekday,min(start_time) arrival,max(end_time) leaving FROM schedule_slots WHERE schedule_id = ? GROUP BY weekday),
                candidates AS (
                    SELECT o.id,p.latitude,p.longitude,o.departure_time,
                        (o.departure_time AT TIME ZONE 'Africa/Casablanca')::date ride_date,
                        o.destination_label = p.campus to_campus,
                        CASE WHEN o.destination_label = p.campus THEN d.arrival ELSE d.leaving END course_time,
                        CASE WHEN o.destination_label = p.campus THEN o.origin_latitude ELSE o.destination_latitude END city_latitude,
                        CASE WHEN o.destination_label = p.campus THEN o.origin_longitude ELSE o.destination_longitude END city_longitude
                    FROM ride_offers o JOIN users u ON u.id=o.driver_id CROSS JOIN settings p
                    JOIN days d ON d.weekday = extract(isodow FROM o.departure_time AT TIME ZONE 'Africa/Casablanca')
                    WHERE o.marketplace AND o.status='OPEN' AND o.available_seats>0 AND u.enabled AND o.driver_id<>?
                        AND o.departure_time>now() AND o.departure_time<now()+interval '7 days'
                        AND (o.departure_time AT TIME ZONE 'Africa/Casablanca')::date BETWEEN ? AND ?
                        AND (o.destination_label=p.campus OR o.origin_label=p.campus)
                        AND NOT EXISTS(SELECT 1 FROM bookings b WHERE b.ride_offer_id=o.id AND b.passenger_id=? AND b.status='CONFIRMED')
                ), scored AS (
                    SELECT *, 6371000.0*2*asin(least(1.0,sqrt(
                        power(sin(radians(city_latitude-latitude)/2),2)
                        +cos(radians(latitude))*cos(radians(city_latitude))*power(sin(radians(city_longitude-longitude)/2),2)))) distance_meters,
                        extract(epoch FROM ((ride_date+course_time) AT TIME ZONE 'Africa/Casablanca')-departure_time)/60.0 gap
                    FROM candidates
                ) SELECT * FROM scored WHERE distance_meters<=?
                    AND ((to_campus AND gap BETWEEN ? AND ?) OR (NOT to_campus AND gap BETWEEN -60 AND 0))
                    ORDER BY ride_date,distance_meters,departure_time,id LIMIT 50
                """, campus, preferences.point().latitude(), preferences.point().longitude(), schedule.id(), user,
                schedule.validFrom(), schedule.validUntil(), user, preferences.radiusMeters(),
                commute + preferences.marginMinutes(), commute + preferences.marginMinutes() + 60);
        return rows.stream().map(row -> new RideMatch(marketplace.listing(user, Kind.OFFER, (UUID) row.get("id")),
                ((Date) row.get("ride_date")).toLocalDate(), (Boolean) row.get("to_campus"),
                ((Time) row.get("course_time")).toLocalTime(), ((Number) row.get("gap")).intValue(),
                (int) Math.round(((Number) row.get("distance_meters")).doubleValue()))).toList();
    }
}

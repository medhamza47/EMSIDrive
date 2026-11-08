package ma.emsi.emsidrive.ride.marketplace;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import ma.emsi.emsidrive.ride.marketplace.RideMarketplaceController.Point;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

@Component
class MarrakechArea {
    private final JsonNode features;

    MarrakechArea(ObjectMapper mapper) throws IOException {
        try (var stream = new ClassPathResource("maps/marrakech.geojson").getInputStream()) {
            features = mapper.readTree(stream).required("features");
        }
    }

    boolean contains(Point point) {
        for (var feature : features) {
            var rings = feature.required("geometry").required("coordinates");
            if (!insideRing(rings.get(0), point)) {
                continue;
            }
            boolean inHole = false;
            for (int i = 1; i < rings.size(); i++) {
                if (insideRing(rings.get(i), point)) {
                    inHole = true;
                    break;
                }
            }
            if (!inHole) {
                return true;
            }
        }
        return false;
    }

    private static boolean insideRing(JsonNode ring, Point point) {
        double lat = point.latitude().doubleValue();
        double lon = point.longitude().doubleValue();
        boolean inside = false;
        for (int i = 0, previous = ring.size() - 1; i < ring.size(); previous = i++) {
            var a = ring.get(previous);
            var b = ring.get(i);
            double aLat = a.get(1).asDouble();
            double bLat = b.get(1).asDouble();
            if ((aLat > lat) == (bLat > lat)) {
                continue;
            }
            double aLon = a.get(0).asDouble();
            double crossing = aLon + (b.get(0).asDouble() - aLon) * (lat - aLat) / (bLat - aLat);
            if (lon < crossing) {
                inside = !inside;
            }
        }
        return inside;
    }
}

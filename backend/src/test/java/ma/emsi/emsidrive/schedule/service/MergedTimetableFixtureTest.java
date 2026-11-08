package ma.emsi.emsidrive.schedule.service;

import java.nio.file.*;
import org.apache.pdfbox.pdmodel.*;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.*;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

/** A visual regression fixture: wide cells with their text only in the first half. */
class MergedTimetableFixtureTest {
    private void text(PDPageContentStream c, float x, float y, String value) throws Exception {
        c.beginText(); c.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
        c.newLineAtOffset(x,y); c.showText(value); c.endText();
    }
    private void line(PDPageContentStream c, float x1, float y1, float x2, float y2) throws Exception {
        c.moveTo(x1,y1); c.lineTo(x2,y2); c.stroke();
    }
    @Test void createsMergedAndSeparateCellsWithUnambiguousBorders() throws Exception {
        var target = Path.of("target/timetable-merged.pdf");
        try (var pdf = new PDDocument()) {
            var page = new PDPage(new PDRectangle(760,500)); pdf.addPage(page);
            try (var c = new PDPageContentStream(pdf,page)) {
                text(c,30,460,"EMSI - EMPLOI DU TEMPS - MERGED-G1 - Campus TARGA - Salle LI8");
                // Header bottom=350. Data rows are 70 points high. Columns x=130,270,410,550,690.
                for (int row = 0; row <= 5; row++) line(c,30,420-row*70,690,420-row*70);
                line(c,30,420,30,70); line(c,130,420,130,70); line(c,690,420,690,70);
                for (int x : new int[]{270,410,550}) line(c,x,420,x,350);
                text(c,40,390,"Jour");
                String[] hours = {"08:30 - 10:00","10:15 - 11:45","12:00 - 13:30","13:45 - 15:15"};
                for (int col = 0; col < hours.length; col++) text(c,140+140*col,390,hours[col]);
                text(c,40,315,"Lundi"); text(c,145,315,"ERP"); text(c,145,300,"Targa LI8");
                line(c,410,350,410,280); line(c,550,350,550,280); // NO x=270 divider: ERP spans 1..2.
                text(c,40,245,"Mardi"); text(c,145,245,"JAVA"); text(c,285,245,"JAVA");
                text(c,145,230,"Targa LI8"); text(c,285,230,"Targa LI8");
                for (int x : new int[]{270,410,550}) line(c,x,280,x,210); // Two genuinely separate JAVA classes.
                text(c,40,175,"Mercredi"); text(c,425,175,"DEVOPS"); text(c,425,160,"Targa LI8");
                line(c,270,210,270,140); line(c,410,210,410,140); // NO x=550 divider: DEVOPS spans 3..4.
                text(c,40,105,"Jeudi"); text(c,425,115,"BUSINESS ENGLISH");
                text(c,425,100,"13:00 - 15:00"); text(c,425,85,"Targa LI8");
                line(c,270,140,270,70); line(c,410,140,410,70); // Printed course hours override headers.
            }
            Files.createDirectories(target.getParent()); pdf.save(target.toFile());
        }
        assertThat(Files.size(target)).isPositive();
    }
}

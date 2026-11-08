package ma.emsi.emsidrive.schedule.service;

import java.io.ByteArrayOutputStream;
import java.nio.file.*;
import org.apache.pdfbox.pdmodel.*;
import org.apache.pdfbox.pdmodel.font.*;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;
import static org.assertj.core.api.Assertions.*;

class ScheduleDocumentReaderTest {
    final ScheduleDocumentReader reader = new ScheduleDocumentReader();
    @Test void keepsFaintPhotoGridPixelsLosslesslyForMergedCellDetection() throws Exception {
        var image=TimetableGridDetectorTest.photographedGrid();
        var jpeg=new ByteArrayOutputStream();javax.imageio.ImageIO.write(image,"jpg",jpeg);
        var decoded=javax.imageio.ImageIO.read(new java.io.ByteArrayInputStream(jpeg.toByteArray()));
        var document=reader.read(new MockMultipartFile("file","photo.jpg","image/jpeg",jpeg.toByteArray()));
        assertThat(document.images().get(0)).startsWith("data:image/png;base64,");
        var normalized=javax.imageio.ImageIO.read(new java.io.ByteArrayInputStream(java.util.Base64.getDecoder().decode(document.images().get(0).split(",")[1])));
        for(int y=0;y<image.getHeight();y+=7)for(int x=0;x<image.getWidth();x+=7)
            assertThat(normalized.getRGB(x,y)).isEqualTo(decoded.getRGB(x,y));
    }
    @Test void rejectsInvalidFilesWithoutTrustingExtension() {
        for (byte[] bytes : new byte[][] {new byte[0], "not an image".getBytes(), new byte[8 * 1024 * 1024 + 1]}) {
            assertThatThrownBy(() -> reader.read(new MockMultipartFile("file","photo.jpg","image/jpeg",bytes))).isInstanceOf(ApiException.class);
        }
    }
    @Test void rejectsTooManyPdfPages() throws Exception {
        try (var pdf = new PDDocument(); var output = new ByteArrayOutputStream()) {
            for (int i = 0; i < 4; i++) pdf.addPage(new PDPage());
            pdf.save(output);
            assertThatThrownBy(() -> reader.read(new MockMultipartFile("file", output.toByteArray())))
                    .isInstanceOfSatisfying(ApiException.class, e -> assertThat(e.getCode()).isEqualTo("SCHEDULE_PDF_PAGES"));
        }
    }
    @Test void rendersPdfAndWritesKnownTimetableFixtureForManualSmokeTest() throws Exception {
        try (var pdf = new PDDocument(); var output = new ByteArrayOutputStream()) {
            var page = new PDPage(); pdf.addPage(page);
            try (var content = new PDPageContentStream(pdf,page)) {
                content.beginText(); content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA),16);
                content.setLeading(32); content.newLineAtOffset(30,730);
                for (var line : new String[] {"EMSI - EMPLOI DU TEMPS - GROUPE TEST-G1", "Jour | Debut | Fin | Matiere | Campus | Salle", "Lundi | 08:30 | 10:00 | ERP | CENTRE | LI8", "Mercredi | 13:45 | 15:15 | DEVOPS | TARGA | LI3", "Samedi | 10:15 | 11:45 | JAVA | TARGA | LI8"}) {
                    content.showText(line); content.newLine();
                }
                content.endText();
            }
            pdf.save(output);
            Files.createDirectories(Path.of("target")); Files.write(Path.of("target/timetable-smoke.pdf"), output.toByteArray());
            var document = reader.read(new MockMultipartFile("file","timetable.pdf","application/pdf",output.toByteArray()));
            assertThat(document.source()).isEqualTo(ScheduleSource.PDF);
            assertThat(document.images()).hasSize(1); assertThat(document.images().get(0)).startsWith("data:image/jpeg;base64,");
        }
    }
}

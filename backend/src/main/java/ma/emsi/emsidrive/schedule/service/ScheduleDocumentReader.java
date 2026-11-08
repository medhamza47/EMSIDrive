package ma.emsi.emsidrive.schedule.service;

import java.awt.Color;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.*;
import javax.imageio.ImageIO;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.schedule.entity.ScheduleSource;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

@Component
public class ScheduleDocumentReader {
    public record Document(ScheduleSource source, List<String> images) {}
    public Document read(MultipartFile file) {
        if (file.isEmpty() || file.getSize() > 8 * 1024 * 1024) {
            throw ApiException.badRequest("SCHEDULE_FILE_SIZE", "File must be between 1 byte and 8 MB");
        }
        try {
            byte[] bytes = file.getBytes();
            if (bytes.length >= 5 && new String(bytes, 0, 5, java.nio.charset.StandardCharsets.US_ASCII).equals("%PDF-")) {
                try (var pdf = Loader.loadPDF(bytes)) {
                    if (pdf.isEncrypted()) throw invalid();
                    if (pdf.getNumberOfPages() < 1 || pdf.getNumberOfPages() > 3) {
                        throw ApiException.badRequest("SCHEDULE_PDF_PAGES", "PDF must contain 1 to 3 pages");
                    }
                    var images = new ArrayList<String>();
                    var renderer = new PDFRenderer(pdf);
                    renderer.setSubsamplingAllowed(true);
                    for (int i = 0; i < pdf.getNumberOfPages(); i++) {
                        var box = pdf.getPage(i).getCropBox();
                        float size = Math.max(box.getWidth(), box.getHeight());
                        if (!Float.isFinite(size) || size <= 0) throw invalid();
                        images.add(encode(renderer.renderImage(i, Math.min(2f, 2000f / size), ImageType.RGB), false));
                    }
                    return new Document(ScheduleSource.PDF, images);
                }
            }
            try (var stream = ImageIO.createImageInputStream(new ByteArrayInputStream(bytes))) {
                var readers = ImageIO.getImageReaders(stream);
                if (!readers.hasNext()) throw invalid();
                var reader = readers.next();
                try {
                    if (!Set.of("JPEG", "PNG").contains(reader.getFormatName().toUpperCase(Locale.ROOT))) throw invalid();
                    reader.setInput(stream);
                    int width = reader.getWidth(0), height = reader.getHeight(0);
                    if ((long) width * height > 25_000_000L) {
                        throw ApiException.badRequest("SCHEDULE_IMAGE_SIZE", "Image exceeds 25 megapixels");
                    }
                    // Preserve faint grid rules: recompressing a photographed JPEG can erase a divider.
                    return new Document(ScheduleSource.IMAGE, List.of(encode(reader.read(0), true)));
                } finally { reader.dispose(); }
            }
        } catch (IOException | IllegalArgumentException ex) {
            throw invalid();
        }
    }

    private String encode(BufferedImage image, boolean lossless) throws IOException {
        double scale = Math.min(1, 2000.0 / Math.max(image.getWidth(), image.getHeight()));
        var rgb = new BufferedImage(Math.max(1, (int) (image.getWidth() * scale)),
                Math.max(1, (int) (image.getHeight() * scale)), BufferedImage.TYPE_INT_RGB);
        var g = rgb.createGraphics();
        try {
            g.setColor(Color.WHITE); g.fillRect(0, 0, rgb.getWidth(), rgb.getHeight());
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            g.drawImage(image, 0, 0, rgb.getWidth(), rgb.getHeight(), null);
        } finally { g.dispose(); image.flush(); }
        var output = new ByteArrayOutputStream();
        ImageIO.write(rgb, lossless ? "png" : "jpg", output);
        rgb.flush();
        return "data:image/" + (lossless ? "png" : "jpeg") + ";base64," + Base64.getEncoder().encodeToString(output.toByteArray());
    }

    private ApiException invalid() {
        return ApiException.badRequest("SCHEDULE_FILE_INVALID", "Use a readable JPEG, PNG or unencrypted PDF");
    }
}

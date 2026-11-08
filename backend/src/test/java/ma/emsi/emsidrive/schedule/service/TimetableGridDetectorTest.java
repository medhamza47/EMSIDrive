package ma.emsi.emsidrive.schedule.service;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.*;
import java.util.List;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class TimetableGridDetectorTest {
    static BufferedImage photographedGrid() {
        var image=new BufferedImage(860,560,BufferedImage.TYPE_INT_RGB);
        var g=image.createGraphics();g.setColor(new Color(185,195,202));g.fillRect(0,0,860,560);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,RenderingHints.VALUE_ANTIALIAS_ON);
        g.shear(0,-.01);g.setColor(new Color(125,135,140));
        for(int y:new int[]{60,80,100,150,200,250,300,350,400})g.drawLine(50,y,830,y);
        int[] borders={50,170,280,390,500,610,720,830};
        for(int x:borders)g.drawLine(x,60,x,100);
        g.drawLine(50,100,50,400);g.drawLine(170,100,170,400);g.drawLine(830,100,830,400);
        for(int row=0;row<6;row++)for(int x:new int[]{280,390,500,610,720}) {
            if(x==280 && (row==0 || row==5))continue;
            g.drawLine(x,100+row*50,x,150+row*50);
        }
        g.setColor(new Color(55,65,70));g.setFont(new Font(Font.SANS_SERIF,Font.PLAIN,12));
        g.drawString("Deep Learning",210,125);g.drawString("ERP",200,325);g.drawString("Framework JEE",210,375);
        g.dispose();return image;
    }
    @Test void measuresTwoColumnCoursesAndKeepsSingleCourseBesideEmptyCellsSeparate() {
        var grid=new TimetableGridDetector().detect(photographedGrid()).orElseThrow();
        assertThat(grid.borders()).hasSize(7);assertThat(grid.rows()).hasSize(6);
        assertThat(grid.rows().get(0).cells().get(0).first()).isEqualTo(1);
        assertThat(grid.rows().get(0).cells().get(0).last()).isEqualTo(2);
        assertThat(grid.rows().get(4).cells().get(0).last()).isEqualTo(1);
        assertThat(grid.rows().get(5).cells().get(0).last()).isEqualTo(2);
    }
    @Test void buildsBoundedCellCardsAndUniqueOpaqueIdentifiers() throws Exception {
        var out=new ByteArrayOutputStream();ImageIO.write(photographedGrid(),"png",out);
        var plan=new TimetableGridDetector().prepare(List.of("data:image/png;base64,"+Base64.getEncoder().encodeToString(out.toByteArray()))).orElseThrow();
        assertThat(plan.batches()).hasSize(2);
        var ids=plan.grid().rows().stream().flatMap(r->r.cells().stream()).map(TimetableGridDetector.Cell::id).toList();
        assertThat(new HashSet<>(ids)).hasSameSizeAs(ids);
        for(var batch:plan.batches()) {
            var card=ImageIO.read(new java.io.ByteArrayInputStream(Base64.getDecoder().decode(batch.image().split(",")[1])));
            assertThat(card.getWidth()).isEqualTo(1020);assertThat(card.getHeight()).isLessThan(1500);
        }
    }
    @Test void doesNotInventGridForBlankOrUnsupportedDocuments() {
        assertThat(new TimetableGridDetector().detect(new BufferedImage(860,560,BufferedImage.TYPE_INT_RGB))).isEmpty();
        assertThat(new TimetableGridDetector().prepare(List.of("data:image/jpeg;base64,AA=="))).isEmpty();
        assertThat(new TimetableGridDetector().prepare(List.of("a","b"))).isEmpty();
    }
}

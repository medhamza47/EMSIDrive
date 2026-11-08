package ma.emsi.emsidrive.schedule.service;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.*;
import javax.imageio.ImageIO;
import java.util.*;
import java.util.List;

/** Finds ruled cells from image pixels; the language model does not decide their column spans. */
final class TimetableGridDetector {
    record Line(double intercept, double slope, int left, int right, int strength) {
        double y(double x) { return intercept + slope * x; }
    }
    record Cell(String id, int first, int last) {}
    record Row(int index, Line top, Line bottom, List<Cell> cells) {}
    record Grid(List<Integer> borders, List<Row> rows, int headerTop, int headerBottom) {}
    record Batch(String image, List<Row> rows) {}
    record Plan(Grid grid, List<Batch> batches) {}

    Optional<Plan> prepare(List<String> images) {
        if (images.size()!=1) return Optional.empty();
        try {
            var decoded=ImageIO.read(new ByteArrayInputStream(Base64.getDecoder().decode(images.get(0).substring(images.get(0).indexOf(',')+1))));
            if(decoded==null) return Optional.empty();
            double scale=Math.min(1,Math.min(1000.0/decoded.getWidth(),1400.0/decoded.getHeight()));
            var image=new BufferedImage(Math.max(1,(int)(decoded.getWidth()*scale)),Math.max(1,(int)(decoded.getHeight()*scale)),BufferedImage.TYPE_INT_RGB);
            var draw=image.createGraphics();draw.setRenderingHint(RenderingHints.KEY_INTERPOLATION,RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            draw.drawImage(decoded,0,0,image.getWidth(),image.getHeight(),null);draw.dispose();decoded.flush();
            var detected=detect(image);
            if(detected.isEmpty()) { image.flush(); return Optional.empty(); }
            var grid=detected.get(); var batches=new ArrayList<Batch>();
            for(int i=0;i<grid.rows().size();i+=3) {
                var rows=grid.rows().subList(i,Math.min(i+3,grid.rows().size()));
                int cardWidth=340,cardHeight=150;
                int canvasHeight=grid.headerBottom()-grid.headerTop()+16+rows.stream().mapToInt(r->56+((r.cells().size()+2)/3)*cardHeight).sum();
                var canvas=new BufferedImage(cardWidth*3,canvasHeight,BufferedImage.TYPE_INT_RGB);
                var g=canvas.createGraphics();g.setColor(Color.WHITE);g.fillRect(0,0,canvas.getWidth(),canvas.getHeight());
                int headerHeight=grid.headerBottom()-grid.headerTop()+3;
                g.drawImage(image,0,0,image.getWidth(),headerHeight,0,grid.headerTop(),image.getWidth(),grid.headerBottom()+3,null);
                int y=headerHeight+12;
                g.setFont(new Font(Font.SANS_SERIF,Font.BOLD,12));
                for(var row:rows) {
                    int rowHeight=Math.max(1,(int)Math.round(row.bottom().y(image.getWidth()/2.0)-row.top().y(image.getWidth()/2.0))-4);
                    var strip=new BufferedImage(image.getWidth(),rowHeight,BufferedImage.TYPE_INT_RGB);
                    // Flatten the two skewed row rules so neighboring rows cannot leak into a crop.
                    for(int x=0;x<image.getWidth();x++) for(int py=0;py<rowHeight;py++) {
                        double sourceY=row.top().y(x)+2+(py+.5)/rowHeight*(row.bottom().y(x)-row.top().y(x)-5);
                        int sy=Math.max(0,Math.min(image.getHeight()-1,(int)Math.round(sourceY)));
                        strip.setRGB(x,py,image.getRGB(x,sy));
                    }
                    g.setColor(Color.BLACK);g.drawString("ROW "+row.index(),4,y+20);
                    int dayWidth=grid.borders().get(0);
                    g.drawImage(strip,90,y,90+dayWidth,y+35,0,0,dayWidth,rowHeight,null);
                    y+=40;
                    int cellIndex=0;
                    for(var cell:row.cells()) {
                        int x1=grid.borders().get(cell.first()-1),x2=grid.borders().get(cell.last());
                        int cx=(cellIndex%3)*cardWidth,cy=y+(cellIndex/3)*cardHeight;
                        g.setColor(Color.GRAY);g.drawRect(cx+1,cy+1,cardWidth-3,cardHeight-3);
                        g.setColor(new Color(170,0,0));g.drawString(cell.id(),cx+8,cy+17);
                        double zoom=Math.min((cardWidth-16.0)/(x2-x1-4),(cardHeight-35.0)/rowHeight);
                        int cw=(int)((x2-x1-4)*zoom),ch=(int)(rowHeight*zoom);
                        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION,RenderingHints.VALUE_INTERPOLATION_BICUBIC);
                        g.drawImage(strip,cx+8,cy+27,cx+8+cw,cy+27+ch,x1+2,0,x2-2,rowHeight,null);
                        cellIndex++;
                    }
                    strip.flush();
                    y+=((cellIndex+2)/3)*cardHeight+16;
                }
                g.dispose();
                var out=new ByteArrayOutputStream();ImageIO.write(canvas.getSubimage(0,0,canvas.getWidth(),y),"png",out);
                canvas.flush();
                batches.add(new Batch("data:image/png;base64,"+Base64.getEncoder().encodeToString(out.toByteArray()),List.copyOf(rows)));
            }
            image.flush();
            return Optional.of(new Plan(grid,List.copyOf(batches)));
        } catch(IOException|IllegalArgumentException ex) { return Optional.empty(); }
    }

    Optional<Grid> detect(BufferedImage original) {
        // Work at bounded resolution. Callers render the same bounded image when using the result.
        if (original.getWidth() < 300 || original.getWidth() > 1200) return Optional.empty();
        BufferedImage enhanced = enhance(original);
        int w = enhanced.getWidth(), h = enhanced.getHeight();
        var candidates = new ArrayList<Line>();
        for (int y = 0; y < h; y++) {
            Line best = null;
            for (int angle=-15;angle<=15;angle++) {
                double slope=angle*.002;
                int start = 0, last = -1, hits = 0, gap = 0;
                for (int x = 0; x < w; x++) {
                    int py = (int) Math.round(y + slope * x);
                    boolean dark = dark(enhanced, x, py, false);
                    if (dark) { if (last < 0) start = x; last = x; hits++; gap = 0; }
                    else if (++gap > 12) {
                        int length = last - start + 1;
                        if (length >= w * .42 && hits >= length * .82 && (best == null || hits > best.strength()))
                            best = new Line(y, slope, start, last, hits);
                        last = -1; hits = 0; gap = 0;
                    }
                }
                int length = last - start + 1;
                if (length >= w * .42 && hits >= length * .82 && (best == null || hits > best.strength()))
                    best = new Line(y, slope, start, last, hits);
            }
            if (best != null) candidates.add(best);
        }
        candidates.sort(Comparator.comparingDouble(l -> l.y(w / 2.0)));
        var lines = new ArrayList<Line>();
        for (var candidate : candidates) {
            if (!lines.isEmpty() && Math.abs(candidate.y(w / 2.0) - lines.get(lines.size()-1).y(w / 2.0)) < 5) {
                if (candidate.strength() > lines.get(lines.size()-1).strength()) lines.set(lines.size()-1,candidate);
            } else lines.add(candidate);
        }
        var allLines=List.copyOf(lines);
        int longest=lines.stream().mapToInt(Line::strength).max().orElse(0);
        int longestSpan=lines.stream().mapToInt(line -> line.right()-line.left()).max().orElse(0);
        lines.removeIf(line -> line.strength()<longest*.68 || line.right()-line.left()<longestSpan*.8);
        List<Line> body = List.of();
        int bestStart = -1;
        for (int start = 0; start < lines.size(); start++) {
            var group = new ArrayList<Line>(); group.add(lines.get(start));
            double mean = 0;
            for (int j = start + 1; j < lines.size() && group.size() < 8; j++) {
                double gap = lines.get(j).y(w / 2.0) - group.get(group.size()-1).y(w / 2.0);
                if (gap < h * .045 || gap > h * .19 || (mean > 0 && (gap < mean * .65 || gap > mean * 1.4))) break;
                int overlap = Math.min(lines.get(j).right(), group.get(0).right()) - Math.max(lines.get(j).left(),group.get(0).left());
                if (overlap < w * .4) break;
                group.add(lines.get(j)); mean = (lines.get(j).y(w/2.0)-group.get(0).y(w/2.0))/(group.size()-1);
            }
            if (group.size() > body.size()) { body = group; bestStart = start; }
        }
        if (body.size() < 5) return Optional.empty();
        int ruleLeft=body.stream().mapToInt(Line::left).min().orElse(0),ruleRight=body.stream().mapToInt(Line::right).max().orElse(w-1);
        var refined=new ArrayList<Line>();
        for(var line:body) refined.add(refine(enhanced,line,ruleLeft,ruleRight));
        body=refined;
        double firstY = body.get(0).y(w/2.0), rowHeight = (body.get(body.size()-1).y(w/2.0)-firstY)/(body.size()-1);
        int scanTop = Math.max(0,(int)(firstY-rowHeight*.8)), scanBottom = (int)firstY-4;
        // If the first detected row is itself a header, its vertical separators are inside that row.
        boolean hasHeader=allLines.stream().anyMatch(line -> line.y(w/2.0)<firstY-10 && line.y(w/2.0)>firstY-rowHeight*1.6);
        if (bestStart == 0 && !hasHeader) { scanTop = (int)firstY+4; scanBottom = (int)body.get(1).y(w/2.0)-4; }
        if(scanBottom<=scanTop)return Optional.empty();
        var separators = new ArrayList<Integer>();
        for (int x = Math.max(0,body.get(0).left()); x <= Math.min(w-1,body.get(0).right()); x++) {
            int hits = 0;
            for (int y = scanTop; y <= scanBottom; y++) if (dark(enhanced,x,y,true)) hits++;
            if (hits >= (scanBottom-scanTop+1)*.83) {
                if (!separators.isEmpty() && x-separators.get(separators.size()-1)<4) separators.set(separators.size()-1,x);
                else separators.add(x);
            }
        }
        // A double rule next to the weekday column is one boundary, not a narrow extra session.
        for (int i=1;i<separators.size();) {
            if (separators.get(i)-separators.get(i-1)<w*.025) { separators.remove(i-1); }
            else i++;
        }
        if (separators.size()<5 || separators.size()>14) return Optional.empty();
        var borders = List.copyOf(separators.subList(1,separators.size())); // Exclude the weekday column.
        var widths = new ArrayList<Integer>();
        for (int i=1;i<borders.size();i++) widths.add(borders.get(i)-borders.get(i-1));
        var sorted = widths.stream().sorted().toList(); int median = sorted.get(sorted.size()/2);
        if (widths.stream().anyMatch(v -> v<median*.55 || v>median*1.8)) return Optional.empty();
        var rows = new ArrayList<Row>();
        int cellId=1;
        for (int i=0;i<body.size()-1;i++) {
            var top = body.get(i); var bottom = body.get(i+1);
            var cells = new ArrayList<Cell>(); int first = 1;
            for (int border=1;border<borders.size()-1;border++) {
                int x = borders.get(border);
                if (verticalRule(enhanced,x,top,bottom)) {
                    cells.add(new Cell("b"+(cellId++),first,border)); first=border+1;
                }
            }
            cells.add(new Cell("b"+(cellId++),first,borders.size()-1));
            rows.add(new Row(i+1,top,bottom,List.copyOf(cells)));
        }
        return Optional.of(new Grid(borders,List.copyOf(rows),Math.max(0,(int)(firstY-rowHeight*2)),(int)firstY));
    }

    private boolean verticalRule(BufferedImage image,int x,Line top,Line bottom) {
        int y1=(int)Math.ceil(top.y(x))+4,y2=(int)Math.floor(bottom.y(x))-4;
        if (y2-y1<12) return false;
        int drift=Math.max(3,image.getWidth()/100);
        for (int dx=-drift;dx<=drift;dx++) {
            int hits=0,longest=0,run=0,gaps=0;
            for(int y=y1;y<=y2;y++) {
                if(dark(image,x+dx,y,true)){hits++;run++;gaps=0;longest=Math.max(longest,run);}
                else if(++gaps>1){run=0;gaps=0;}
            }
            int length=y2-y1+1;
            if(hits>=length*.83 && longest>=length*.65) return true;
        }
        return false;
    }

    private Line refine(BufferedImage image,Line original,int left,int right) {
        long bestScore=Long.MIN_VALUE; Line best=original;
        for(int intercept=(int)original.intercept()-10;intercept<=(int)original.intercept()+10;intercept++) {
            for(int angle=-15;angle<=15;angle++) {
                double slope=angle*.002;int hits=0,contrast=0;
                for(int x=left;x<=right;x+=2) {
                    int y=(int)Math.round(intercept+slope*x),value=255;
                    for(int d=-1;d<=1;d++) if(y+d>=0 && y+d<image.getHeight()) value=Math.min(value,image.getRGB(x,y+d)&255);
                    if(value<235)hits++;contrast+=255-value;
                }
                long score=hits*10000L+contrast;
                if(score>bestScore){bestScore=score;best=new Line(intercept,slope,left,right,hits);}
            }
        }
        return best;
    }

    private boolean dark(BufferedImage image,int x,int y,boolean horizontalTolerance) {
        int tolerance=horizontalTolerance?1:2;
        for(int delta=-tolerance;delta<=tolerance;delta++) {
            int px=x+(horizontalTolerance?delta:0),py=y+(horizontalTolerance?0:delta);
            if(px>=0 && py>=0 && px<image.getWidth() && py<image.getHeight() && (image.getRGB(px,py)&255)<210) return true;
        }
        return false;
    }

    static BufferedImage enhance(BufferedImage source) {
        int w=source.getWidth(),h=source.getHeight(),radius=Math.max(6,Math.min(20,w/70));
        var integral=new long[(h+1)*(w+1)]; var gray=new int[w*h];
        for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
            int rgb=source.getRGB(x,y),g=((rgb>>16&255)*299+(rgb>>8&255)*587+(rgb&255)*114)/1000;
            gray[y*w+x]=g;int p=(y+1)*(w+1)+x+1;
            integral[p]=g+integral[p-1]+integral[p-w-1]-integral[p-w-2];
        }
        var result=new BufferedImage(w,h,BufferedImage.TYPE_INT_RGB);
        for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
            int x1=Math.max(0,x-radius),x2=Math.min(w,x+radius+1),y1=Math.max(0,y-radius),y2=Math.min(h,y+radius+1);
            double mean=(integral[y2*(w+1)+x2]-integral[y1*(w+1)+x2]-integral[y2*(w+1)+x1]+integral[y1*(w+1)+x1])/(double)((x2-x1)*(y2-y1));
            int value=255-(int)Math.min(255,Math.max(0,mean-gray[y*w+x]-2)*8);
            result.setRGB(x,y,(value<<16)|(value<<8)|value);
        }
        return result;
    }
}

/* Example Mandelbrot renderer.  Justin Bradley */

import java.awt.*;
import java.awt.image.*;
import javax.swing.*;
import java.io.*;
import com.sun.image.codec.jpeg.*;
import java.awt.font.TextLayout;
import java.awt.geom.AffineTransform;
import java.awt.geom.Rectangle2D;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Enumeration;

public class Fractal // extends JFrame
{ 
  public static void main(String args[])
  {
    Fractal f = new Fractal(args);
  }

  public Fractal(String args[])
  {
    Mandelbrot m;
    if(args.length > 1)
    {
      try
      {
	m = new Mandelbrot
	(
	  new Double(args[1]).doubleValue(),
	  new Double(args[2]).doubleValue(),
	  new Double(args[3]).doubleValue(),
	  new Double(args[4]).doubleValue(),
	  args[5],
	  new Integer(args[6]).intValue(),
	  new Integer(args[7]).intValue()
	);
      } 
      catch (Exception e) { m = new Mandelbrot(); }
    }
    else
      m = new Mandelbrot();

    if(args.length > 0 && args[0].equals("hide"))
    {
      // hidden
    }
    else
    {
/*
      addWindowListener(new WindowAdapter()
      {
	public void windowClosing(WindowEvent evt)
	{ System.exit(0); }
      });
      setSize(900, 700);
      getContentPane().add(m);
      show();
*/
    }
  }
}

class Mandelbrot extends JPanel
{ 
  private double SX = -2.025; // start value real
  private double SY = -1.125; // start value imaginary
  private double EX = 0.6;    // end value real
  private double EY = 1.125;  // end value imaginary
  private String filename = "out.jpg";
  private int width = 200;
  private int height = 200;

  private final int MAX = 256; // max iterations
  private static int x1, y1, xs, ys, xe, ye;
  private static double xstart, ystart, xend, yend, xzoom, yzoom;
  private static boolean action, finished;
  private static float xy;
  private BufferedImage picture;
  private Graphics g1;

  public Mandelbrot(double _SX, double _SY, double _EX, double _EY, String _filename, int _width, int _height)
  {
    // System.err.println("using supplied values");
    SX=_SX; SY=_SY; EX=_EX; EY=_EY;
    filename=_filename;
    width=_width; height=_height;
    go();
  }

  public Mandelbrot()
  {
    // System.err.println("using default values");
    go();
  }

  private void go()
  {
    setSize(width, height);
    init();
    start();
	try
	{
		String size = System.getProperty("tile.message.size");
		int s = 12;
		if(size != null && !"".equals(size))
		{
			s = Integer.parseInt(size);
			if(s <= 0) s = 12;
		}

		String message = System.getProperty("tile.message");
		if(message == null || "".equals(message))
		{
			message = "Rendered on:";
		}

		String h = System.getProperty("hostname.style"); // full|short|none
		if(h == null || "full".equals(h))
		{
			stamp(new String[] {message, getLocalHostName()}, s);
		}
		else if("short".equals(h))
		{
			stamp(new String[] {message, getLocalHostName().split("\\.")[0]}, s);
		}
		else if("none".equals(h))
		{
			stamp(new String[] {message}, s);
		}

	}catch(Exception ex){ex.printStackTrace();}
    write();
  }

  public void init() // all instances will be prepared
  {
    finished = false;
    x1 = getSize().width;
    y1 = getSize().height;
    xy = (float)x1 / (float)y1;
    picture = new BufferedImage(x1, y1, BufferedImage.TYPE_INT_RGB); 
    g1 = picture.getGraphics();
    finished = true;
  }

  public void stamp(String[] lines, int size)
  {

	Graphics2D g = picture.createGraphics();
	g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
	g.setRenderingHint(RenderingHints.KEY_FRACTIONALMETRICS, RenderingHints.VALUE_FRACTIONALMETRICS_ON);
	g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
	g.setFont(new Font("Arial", Font.BOLD, size));
	for(int i=0; i < lines.length; i++)
	{
		TextLayout tl = new TextLayout(lines[i], g.getFont(), g.getFontRenderContext());
		Rectangle2D bounds = tl.getBounds();
		double x = (picture.getWidth()-bounds.getWidth())/2 - bounds.getX();
		double y = ((picture.getHeight()-bounds.getHeight())/2 - bounds.getY())+(i*20);
		//Shape outline = tl.getOutline(g.getTransform());
		g.setPaint(Color.WHITE);
		tl.draw(g, (float)x, (float)y);
	}

	g.dispose();

  }

  public void destroy() // delete all instances 
  {
    if(finished)
    {
      picture = null;
      g1 = null;
      System.gc(); // garbage collection
    }
  }

  public void start()
  {
    action = false;
    startValue();
    xzoom = (xend - xstart) / (double)x1;
    yzoom = (yend - ystart) / (double)y1;
    mandelbrot();
  }

  public void write()
  {
    try
    {
      FileOutputStream fo = new FileOutputStream(filename);
      JPEGEncodeParam jep = JPEGCodec.getDefaultJPEGEncodeParam(picture);
      jep.setQuality(1.0f, true);
      JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(fo, jep);
      encoder.encode(picture);
      fo.close();
    }
    catch(Exception e) {}
  }

  public void paint(Graphics g){ update(g); }

  public void update(Graphics g)
  {
    g.drawImage(picture, 0, 0, this);
    g.setColor(Color.white);
    if(xs < xe)
    {
      if(ys < ye) g.drawRect(xs, ys, (xe - xs), (ye - ys));
      else g.drawRect(xs, ye, (xe - xs), (ys - ye));
    }
    else
    {
      if(ys < ye) g.drawRect(xe, ys, (xs - xe), (ye - ys));
      else g.drawRect(xe, ye, (xs - xe), (ys - ye));
    }
  }

  private void mandelbrot() // calculate all points
  {
    int x, y;
    float h, b, alt = 0.0f;

    action = false;
    for(x = 0; x < x1; x+=2)
      for(y = 0; y < y1; y++)
      {
        h = pointColour(xstart + xzoom * (double)x, ystart + yzoom * (double)y); // colour value
	if(h != alt)
	{
	  b = 1.0f - h * h; // brightness
	  g1.setColor(Color.getHSBColor(h, 0.8f, b));
	  alt = h;
	}
	g1.drawLine(x, y, x + 1, y);
      }
    action = true;
  }

  private float pointColour(double xValue, double yValue) // colour value from 0.0 to 1.0 by iterations
  {
    double r = 0.0, i = 0.0, m = 0.0;
    int j = 0;

    while((j < MAX) && (m < 4.0))
    {
      j++;
      m = r * r - i * i;
      i = 2.0 * r * i + yValue;
      r = m + xValue;
    }
    return (float)j / (float)MAX;
  }

  private void startValue() // reset start values
  {
    xstart = SX;
    ystart = SY;
    xend = EX;
    yend = EY;
    if((float)((xend - xstart) / (yend - ystart)) != xy )
    xstart = xend - (yend - ystart) * (double)xy;
  }

  /**
	 * Return the most useful hostname that can be found
	 *
	 * Each network interface is examined in turn.  Interfaces with private addresses are ignored.
	 * If all else fails the 'old' method of invoking InetAddress.getLocalHost() which often return a 
	 * rather unhelpful 'localhost.localdomain' from the loopback interface.
	 * @throws Exception
	 */
    private String getLocalHostName() throws Exception
    {
        String hostname = null;
        InetAddress ia;
        Enumeration nwis = NetworkInterface.getNetworkInterfaces();
        while(nwis.hasMoreElements())
        {
            NetworkInterface nwi = (NetworkInterface) nwis.nextElement();
            Enumeration ias = nwi.getInetAddresses();
            while(ias.hasMoreElements())
            {
                //Ignore IPV6 addresses
				try
				{
					ia = (Inet4Address) ias.nextElement();
					//Ignore Private Address Space
					if(ia.getHostAddress().matches("^10\\..+"))
					{
						continue;
					}
					if(ia.getHostAddress().matches("^172\\.16\\..+"))
					{
						continue;
					}
					if(ia.getHostAddress().matches("^192\\.168\\..+"))
					{
						continue;
					}
					//ignore localhost
					if(ia.getHostAddress().matches("127.0.0.1"))
					{
						continue;
					}
					hostname = ia.getHostName();
				}
				catch(ClassCastException cce)
				{
					//logger.debug("Skipping IPV6 InetAdress");
				}
            } //while2
            //last resort
            if(hostname == null)
            {
                //The old way - This often uses 127.0.0.1 which resolves to localhost.localdomain
                ia = InetAddress.getLocalHost();
                hostname = ia.getHostName();
            }
        } //while1
		//logger.info("Hostname: "+hostname);
        return hostname;
    } //getLocalHostName
}

/**
 * Displays a grid of tiles as a single composite image
 * - Assumes all image tiles are the same size
 * - Supports at least jpg, gif and png images
 * - Known not to support tif images without aditional java package
 * see http://java.sun.com/products/java-media/jai/downloads/download-iio.html
 *
 * Justin Bradley, OMII, 27/07/2005
 */

/*  spec file
rows
columns
# tiles
tile-filename
tile-filename
...
 
where rows and columns are integers
the ordering of the tiles are expected to be from left to right, top to bottom
blank lines and lines starting with # are ignored
 */

import java.nio.Buffer;
import java.util.*;
import java.awt.*;
import java.awt.image.*;
import java.awt.event.*;
import javax.swing.*;
import java.io.*;

public class TileImageClient extends JPanel
{
	public static final int COMPLETE = 1;
	public static final int INCOMPLETE = 0;
	private int status = INCOMPLETE;
	public int getStatus()
	{ return status; }
	
	public static void main(String args[])
	{
		TileImageClient tic = null;
		int size = 100;
                int scale_size = 0;
		
		if(args.length > 1)
		{
			try
			{ size = Integer.parseInt(args[1], 10); }
			catch(NumberFormatException nfe)
			{ ; }

			if(args.length > 2)
			{
				try
				{ scale_size = Integer.parseInt(args[2], 10); }
				catch(NumberFormatException nfe)
				{ ; }
			}
			else
			{
				scale_size = 0;
			}

			tic = new TileImageClient(args[0], size, scale_size);
		}
		else
		{
			System.out.println("Wrong number of arguments, supply the name of a specification file and default tile size.");
			System.exit(1);
		}
		
		JFrame mainFrame = new JFrame("Tile Image Client");
		mainFrame.addWindowListener(new WindowAdapter()
		{
			public void windowClosing(WindowEvent evt)
			{
				System.exit(0);
			}
		});
		
		mainFrame.setContentPane(tic);
		mainFrame.pack();
		mainFrame.setVisible(true);
		
		if(size > 0)
		{
			Refresher refresher = new Refresher(args[0], mainFrame, size, scale_size);
			refresher.start();
		}
	}
	
	private static class Refresher extends Thread
	{
		String file;
		JFrame frame;
		int size;
		int scale_size;
		
		public Refresher(String f, JFrame jf, int s, int ss)
		{
			file = f;
			frame = jf;
			size = s;
			scale_size = ss;
		}
		
		public void run()
		{
			for(;;)
			{
				TileImageClient tic = new TileImageClient(file, size, scale_size);
				frame.setContentPane(tic);
				frame.pack();
				if(tic.getStatus() == TileImageClient.COMPLETE)
				{
					System.out.println("All tiles are present");
					break;
				}
				try
				{ sleep(1000); }
				catch(java.lang.InterruptedException e)
				{ ; }
			}
		}
	}
	
	public TileImageClient(String specFile, int default_size, int scale_size)
	{
		super(new BorderLayout(), true);
		Vector filenames = new Vector();
		int rows = 0, columns = 0;
		
		try
		{
			BufferedReader reader = new BufferedReader(new FileReader(specFile));
			String line = null;
			int count = 1;
			while ((line=reader.readLine()) != null)
			{
				if(line.length() == 0 || line.startsWith("#"))
				{
					// skip blanks and comments
					continue;
				}
				else if(count == 1)
				{
					try
					{ rows = Integer.parseInt(line, 10); }
					catch(NumberFormatException nfe)
					{ System.err.println("Error reading number of rows"); System.exit(1); }
				}
				else if(count == 2)
				{
					try
					{ columns = Integer.parseInt(line, 10); }
					catch(NumberFormatException nfe)
					{ System.err.println("Error reading number of columns"); System.exit(1); }
				}
				else
				{
					filenames.add(line);
				}
				++count;
			}
			reader.close();
			
		}
		catch (IOException e)
		{
			System.err.println(e);
			System.exit(1);
		}
		
		ImagePanel ip = new ImagePanel(rows, columns, filenames, default_size, default_size, scale_size);
		
		if((rows * columns) == ip.getNumRead())
			status = COMPLETE;
		
		JScrollPane scrollPane = new JScrollPane(ip);
		scrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
		scrollPane.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
		
		removeAll();
		add(scrollPane, BorderLayout.CENTER);
	}
	
	/** JPanel derivative that displays a matrix of images */
	class ImagePanel extends JPanel
	{
		private int maxUnitIncrement = 1;
		private int numRead = 0;
		
		public ImagePanel(int rows, int columns, Vector filenames, int default_x, int default_y, int scale_size)
		{
			super(new GridLayout(rows, columns, 0, 0), true);
			double ref_x = 0.0, ref_y = 0.0;
			Iterator it = filenames.iterator();
			while(it.hasNext())
			{
				String f = (String) it.next();
				JPanel tile = new GraphicPanel(f, scale_size);
				add(tile);
				if(tile.getSize().getWidth() > 0.0)
				{
					ref_x = tile.getSize().getWidth();
					ref_y = tile.getSize().getHeight();
					++numRead;
				}
				else
				{
					ref_x = (double) default_x;
					ref_y = (double) default_y;
				}
			}
			
			// assume at all tiles are the same size.
			setPreferredSize(new Dimension((int) (ref_x * columns), (int) (ref_y * rows)));
		}
		
		public int getNumRead()
		{ return numRead; }
		
		/** Loads an image file and places it in a JPanel */
		private class GraphicPanel extends JPanel
		{
			private Image image;
			boolean complete = false;
			public GraphicPanel(String fileName, int scale_size)
			{
				super();
				File file = new File(fileName);
				try
				{
					if(file.exists())
					{
					    if(fileName.endsWith("jpg"))
					    {
						FileInputStream fis = new FileInputStream(file);
						byte[] buff = new byte[2];
						fis.skip(file.length()-2);
						fis.read(buff);
						if(buff[0] == -1 && buff[1] == -39)
						{
							//System.out.println("JPEG complete");
							complete = true;
						}
						//else System.out.println("Skipping incomplete image");
					    }
					    else complete = true; // have to assume that its complete
					}					
				} catch (IOException ex)
				{
					ex.printStackTrace();
				}
				if(!complete)
				{
					//Don't attempt to use partial images, instead use a non-existant file
					fileName = "foo";
				}
				
				// should not need this, but there is a bug in the jvm somewhere,
				// probably in some file caching routine				
				new ImageIcon(fileName).getImage().flush();
				
				if(scale_size == 0)
  					image = new ImageIcon(fileName).getImage();
				else
					image = new ImageIcon(fileName).getImage().getScaledInstance(scale_size, scale_size, Image.SCALE_FAST);
				setSize(image.getWidth(this), image.getHeight(this));
			}
			
			public void paintComponent(Graphics g)
			{
				super.paintComponent(g);
				g.drawImage(image, 0, 0, null);
			}
		}
	}
}


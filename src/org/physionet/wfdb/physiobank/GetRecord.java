/* ===========================================================
 * Download WFDB Records from PhysioNet Servers
 *              
 * ===========================================================
 *
 * (C) Copyright 2012, by Ikaro Silva
 *
 * Original Author:  Ikaro Silva
 *
 */ 

/** 
 * @author Ikaro Silva
 *  @version 1.0
 *  @since 1.0
 */

package org.physionet.wfdb.physiobank;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.net.URLConnection;

public class GetRecord {


	public static void dowloadRecord(String inputURL,String outputFile) throws IOException{
		File file =new File(outputFile);
		file.createNewFile();
		URL url = new URL( inputURL);
		URLConnection connection = url.openConnection();
		InputStream input = connection.getInputStream();
		byte[] buffer = new byte[4096];
		int n = - 1;

		OutputStream output = new FileOutputStream( file );
		while ( (n = input.read(buffer)) != -1)
		{
		    if (n > 0)
		    {
		        output.write(buffer, 0, n);
		    }
		}
		output.close();
	}
}

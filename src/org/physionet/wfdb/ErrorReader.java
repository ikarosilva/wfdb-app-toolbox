package org.physionet.wfdb;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ErrorReader extends Thread {
	InputStream is;
	Logger logger;
	Level level;

	public ErrorReader(InputStream is, Logger logger, Level level) {
		this.is=is;
		this.logger = logger;
		this.level = level;
	}
	public ErrorReader(InputStream is, Logger logger) {
		this(is, logger, Level.WARNING);
	}
	public void run(){
		try {
			InputStreamReader isr= new InputStreamReader(is);
			BufferedReader br = new BufferedReader(isr);
			String line = null;
			while ( ( line = br.readLine() )!= null ){
				logger.log(level, line);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}

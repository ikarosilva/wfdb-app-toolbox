package org.physionet.wfdb.physiobank;



public class PhysioNetSignal {

	private final String recordName;
	private Integer recordIndex=null;
	private String signalIndex=null;
	private String startTime=null;
	private String lengthTime=null;
	private String lengthSamples=null;
	private String samplingFrequency=null;
	private String Group=null;
	private String file=null;
	private String description=null;
	private String initialValue=null;
	private String gain=null;
	private String format=null;
	private String io=null;
	private String adcResolution=null;
	private String adcZero=null;
	private String baseline=null;
	private String checkSum=null;
	private double[][] data=null; //data in physical units

	//TODO: Consider overriding equals() and hashcode!
	
	public PhysioNetSignal(Integer mrecordIndex, String mrecName){
		setRecordIndex(mrecordIndex);
		recordName=mrecName;
	}

	public PhysioNetSignal(String mrecName){
		recordName=mrecName;
	}

	public void printSignalInfo(){
		System.out.println("DB/Record Name: " + recordName);
		System.out.println("\tRecord/Signal Index: " + recordIndex + "/" + signalIndex);
		System.out.println("\tGroup: " + Group);
		System.out.println("\tStart Time:\t\t" + startTime);
		System.out.println("\tLength Time:\t\t" + lengthTime);
		System.out.println("\tNumber of Samples:\t" + lengthSamples);
		System.out.println("\tSampling Frequency:\t" + samplingFrequency);
		System.out.println("\tFile:\t\t\t" + file);
		System.out.println("\tDescription:\t\t" + description);
		System.out.println("\tInitial Value:\t\t" + initialValue);
		System.out.println("\tGain:\t\t\t" + gain);
		System.out.println("\tFormat:\t\t\t" + format);
		System.out.println("\tI\\O:\t\t\t" + io);
		System.out.println("\tADC Resolution:\t\t" + adcResolution);
		System.out.println("\tADC Zero:\t\t" + adcZero);
		System.out.println("\tBaseline:\t\t" + baseline);
		System.out.println("\tChecksum:\t\t" + checkSum);

	}

	/*
	public void loadPhysicalData(){
		//Calls RDSAMP to get data for this signal
		Rdsamp rdsampexec = new Rdsamp();
		rdsampexec.setArgumentValue(Rdsamp.Arguments.stopTime, "s10");
		rdsampexec.setArgumentValue(Rdsamp.PrintTimeFormatLabel.p);
		rdsampexec.setArgumentValue(Rdsamp.Arguments.signalList,
									"[1]");
		rdsampexec.setArgumentValue(Rdsamp.Arguments.recordName,
					               dbName + "/" + recName);
		try {
			data=rdsampexec.execToDoubleArray();
		}catch (Exception e){
			System.err.println("Could not load data for signal: " +
						recName);
			e.printStackTrace();
		}
		
	}
	*/

	public double[][] getPhysicalData(){
		return data;
	}

	public String getRecordName() {
		return recordName;
	}

	public Integer getRecordIndex() {
		return recordIndex;
	}

	public void setRecordIndex(Integer recordIndex) {
		this.recordIndex = recordIndex;
	}

	public String getStartTime() {
		return startTime;
	}

	public void setStartTime(String startTime) {
		this.startTime = startTime;
	}

	public String getLengthTime() {
		return lengthTime;
	}

	public void setLengthTime(String lengthTime) {
		this.lengthTime = lengthTime;
	}

	public String getLengthSamples() {
		return lengthSamples;
	}

	public void setLengthSamples(String lengthSample) {
		this.lengthSamples = lengthSample;
	}

	public String getSamplingFrequency() {
		return samplingFrequency;
	}

	public void setSamplingFrequency(String samplingFrequency) {
		this.samplingFrequency = samplingFrequency;
	}

	public String getGroup() {
		return Group;
	}

	public void setGroup(String group) {
		Group = group;
	}

	public String getFile() {
		return file;
	}

	public void setFile(String file) {
		this.file = file;
	}

	public String getInitialValue() {
		return initialValue;
	}

	public void setInitialValue(String initialValue) {
		this.initialValue = initialValue;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getFormat() {
		return format;
	}

	public void setFormat(String format) {
		this.format = format;
	}

	public String getGain() {
		return gain;
	}

	public void setGain(String gain) {
		this.gain = gain;
	}

	public String getAdcResolution() {
		return adcResolution;
	}

	public void setAdcResolution(String adcResolution) {
		this.adcResolution = adcResolution;
	}

	public String getIo() {
		return io;
	}

	public void setIo(String io) {
		this.io = io;
	}

	public String getAdcZero() {
		return adcZero;
	}

	public void setAdcZero(String adcZero) {
		this.adcZero = adcZero;
	}

	public String getBaseline() {
		return baseline;
	}

	public void setBaseline(String baseline) {
		this.baseline = baseline;
	}

	public String getCheckSum() {
		return checkSum;
	}

	public void setCheckSum(String checksum) {
		this.checkSum = checksum;
	}

	public String getSignalIndex() {
		return signalIndex;
	}

	public void setSignalIndex(String string) {
		this.signalIndex = string;
	}

}

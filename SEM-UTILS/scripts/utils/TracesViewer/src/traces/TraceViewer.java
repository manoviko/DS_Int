package traces;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.channels.FileChannel;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.StringTokenizer;

public class TraceViewer {
	private static Set<Short> intFields = new HashSet<>();
	private static Set<Short> shortFields = new HashSet<>();
	private static Map<String, String> fieldNamesByTagId = new HashMap<>();

	static {
		intFields.add(Short.valueOf((short) 508));
		intFields.add(Short.valueOf((short) 512));
		intFields.add(Short.valueOf((short) 125));
		intFields.add(Short.valueOf((short) 126));
		intFields.add(Short.valueOf((short) 24));
		intFields.add(Short.valueOf((short) 27));
		intFields.add(Short.valueOf((short) 28));
		intFields.add(Short.valueOf((short) 1061));
		intFields.add(Short.valueOf((short) 1062));
		intFields.add(Short.valueOf((short) 119));
		intFields.add(Short.valueOf((short) 80));
		intFields.add(Short.valueOf((short) 115));
		intFields.add(Short.valueOf((short) 1058));
		intFields.add(Short.valueOf((short) 1048));
		intFields.add(Short.valueOf((short) 1057));
		intFields.add(Short.valueOf((short) 121));
		intFields.add(Short.valueOf((short) 122));
		intFields.add(Short.valueOf((short) 120));
		intFields.add(Short.valueOf((short) 86));
		intFields.add(Short.valueOf((short) 87));
		intFields.add(Short.valueOf((short) 1030));
		intFields.add(Short.valueOf((short) 127));
		intFields.add(Short.valueOf((short) 264));
		intFields.add(Short.valueOf((short) 1059));
		intFields.add(Short.valueOf((short) 1060));
		intFields.add(Short.valueOf((short) 65));
		intFields.add(Short.valueOf((short) 289));
		intFields.add(Short.valueOf((short) 292));
		intFields.add(Short.valueOf((short) 260));
		intFields.add(Short.valueOf((short) 261));
		intFields.add(Short.valueOf((short) 262));
		intFields.add(Short.valueOf((short) 1074));
		intFields.add(Short.valueOf((short) 286));
		intFields.add(Short.valueOf((short) 287));
		intFields.add(Short.valueOf((short) 294));
		intFields.add(Short.valueOf((short) 225));
		intFields.add(Short.valueOf((short) 327));
		intFields.add(Short.valueOf((short) 330));
		intFields.add(Short.valueOf((short) 331));
		intFields.add(Short.valueOf((short) 337));
		intFields.add(Short.valueOf((short) 806));
		intFields.add(Short.valueOf((short) 813));

		shortFields.add(Short.valueOf((short) 57));
		shortFields.add(Short.valueOf((short) 114));
		shortFields.add(Short.valueOf((short) 4));
		shortFields.add(Short.valueOf((short) 1025));
		shortFields.add(Short.valueOf((short) 3));
		shortFields.add(Short.valueOf((short) 29));
		shortFields.add(Short.valueOf((short) 123));
		shortFields.add(Short.valueOf((short) 801));
		shortFields.add(Short.valueOf((short) 802));
		shortFields.add(Short.valueOf((short) 811));
		shortFields.add(Short.valueOf((short) 817));

		fieldNamesByTagId.put(String.valueOf(105), "Transaction-UID");
		fieldNamesByTagId.put(String.valueOf(28), "Transaction-ISN");
		fieldNamesByTagId.put(String.valueOf(801), "Trace Type");
		fieldNamesByTagId.put(String.valueOf(58), "Arrival date");
		fieldNamesByTagId.put(String.valueOf(55), "Full Source Address");
		fieldNamesByTagId.put(String.valueOf(54), "Full Target Address");
		fieldNamesByTagId.put(String.valueOf(24), "Priority");
		fieldNamesByTagId.put(String.valueOf(57),
				"Send Notification Indication");
		fieldNamesByTagId.put(String.valueOf(4), "Validity Period");
		fieldNamesByTagId.put(String.valueOf(80), "Message Size");
		fieldNamesByTagId.put(String.valueOf(802), "Source Type");
		fieldNamesByTagId.put(String.valueOf(338), "Incoming Protocol");
		fieldNamesByTagId.put(String.valueOf(806), "Num Of Recipients");
		fieldNamesByTagId.put(String.valueOf(50), "Source EI ID");
		fieldNamesByTagId.put(String.valueOf(125), "Source EI Class number");
		fieldNamesByTagId.put(String.valueOf(126), "Source EI Group number");
		fieldNamesByTagId.put(String.valueOf(119), "DCS");
		fieldNamesByTagId.put(String.valueOf(114), "SM Class");
		fieldNamesByTagId.put(String.valueOf(3), "Language");
		fieldNamesByTagId.put(String.valueOf(20), "SM Text");
		fieldNamesByTagId.put(String.valueOf(120), "Message Reference Number");
		fieldNamesByTagId.put(String.valueOf(121), "Number of parts");
		fieldNamesByTagId.put(String.valueOf(122), "Message Sequence Number");
		fieldNamesByTagId.put(String.valueOf(804), "Read reply request");
		fieldNamesByTagId.put(String.valueOf(809), "Source Application ID");
		fieldNamesByTagId.put(String.valueOf(807), "Operator ID");
		fieldNamesByTagId.put(String.valueOf(814), "User Session ID");
		fieldNamesByTagId.put(String.valueOf(817), "HTTP Response Status");
		fieldNamesByTagId.put(String.valueOf(818), "SVC Error");
		fieldNamesByTagId.put(String.valueOf(819), "SVC Text");
		fieldNamesByTagId.put(String.valueOf(815), "VAS Application List");
		fieldNamesByTagId.put(String.valueOf(816), "Operation Detailed Info");
		fieldNamesByTagId.put(String.valueOf(820), "RCS Message ID");
		fieldNamesByTagId.put(String.valueOf(821), "Source Message Subtype");
		fieldNamesByTagId.put(String.valueOf(822), "Target Message Subtype");
		fieldNamesByTagId.put(String.valueOf(823), "Public Gruu");
		fieldNamesByTagId.put(String.valueOf(824), "SIP Instance");
		fieldNamesByTagId.put(String.valueOf(825), "Message Delivery Type");
		fieldNamesByTagId.put(String.valueOf(0), "SMSC ID");
		fieldNamesByTagId.put(String.valueOf(10003), "Source Address");
		fieldNamesByTagId.put(String.valueOf(10004), "Target Address");
		fieldNamesByTagId.put(String.valueOf(10006), "Trace Generator");
		fieldNamesByTagId.put(String.valueOf(105), "Transaction-UID");
		fieldNamesByTagId.put(String.valueOf(28), "Transaction-ISN");
		fieldNamesByTagId.put(String.valueOf(58), "Arrival date");
		fieldNamesByTagId.put(String.valueOf(34), "Event date");
		fieldNamesByTagId.put(String.valueOf(1030), "Event Num");
		fieldNamesByTagId.put(String.valueOf(123), "Event Type");
		fieldNamesByTagId.put(String.valueOf(811), "Target Type");
		fieldNamesByTagId.put(String.valueOf(812), "Target Application ID");
		fieldNamesByTagId.put(String.valueOf(55), "Full Source Address");
		fieldNamesByTagId.put(String.valueOf(54), "Full Target Address");
		fieldNamesByTagId.put(String.valueOf(57), "Notification");
		fieldNamesByTagId.put(String.valueOf(127), "General Error");
		fieldNamesByTagId.put(String.valueOf(60), "Diag Set");
		fieldNamesByTagId.put(String.valueOf(813), "Unified Error Id");
		fieldNamesByTagId.put(String.valueOf(808),
				"Additional Error Information");
		fieldNamesByTagId.put(String.valueOf(339), "Outgoing Protocol");
		fieldNamesByTagId.put(String.valueOf(29), "SM State");
		fieldNamesByTagId.put(String.valueOf(50), "Source EI ID");
		fieldNamesByTagId.put(String.valueOf(125), "Source EI Class number");
		fieldNamesByTagId.put(String.valueOf(126), "Source EI Group number");
		fieldNamesByTagId.put(String.valueOf(97), "Target EI ID");
		fieldNamesByTagId.put(String.valueOf(1061), "Target EI Class number");
		fieldNamesByTagId.put(String.valueOf(1062), "Target EI Group number");
	}

	public static void main(String[] args) {
		String firstParameter = null;
		String secondParameter = null;
		String thirdParameter = null;

		int numberOfParameters = args.length;
		if (numberOfParameters == 0) {
			System.out.print("Missing mandatory parameter.");
			System.out
					.print("TlvUtils 'tlv file name' [<configuration file path[;configuration file path]>] [<output file path>]");
			System.exit(-1);
		}
		if (numberOfParameters > 0) {
			firstParameter = args[0];
		}
		if ((numberOfParameters == 1) && (firstParameter.contains("help"))) {
			doHelp();
			return;
		}
		if (numberOfParameters > 1) {
			secondParameter = args[1];
		}
		if (numberOfParameters > 2) {
			thirdParameter = args[2];
		}
		TraceViewer tracesViewer = new TraceViewer();
		try {
			tracesViewer.loadTraceFile(firstParameter, secondParameter,
					thirdParameter);
		} catch (IOException e) {
			e.printStackTrace();
			System.out.println(e.getMessage());
		}
	}

	public String generateReportFromBinFile(ByteBuffer binaryCdrs,
			String traceFilename) {
		binaryCdrs.order(ByteOrder.LITTLE_ENDIAN);
		binaryCdrs.flip();

		StringBuilder traceReport = new StringBuilder("");
		traceReport.append(traceFilename);
		traceReport.append("\n");
		traceReport.append("\n");
		while (binaryCdrs.position() < binaryCdrs.limit()) {
			if (checkIfCdrEnds(binaryCdrs)) {
				traceReport.append("\n");
				if (binaryCdrs.position() == binaryCdrs.limit()) {
					break;
				}
			}
			if (checkIfCdrEnds(binaryCdrs)) {
				traceReport.append("\n");
				if (binaryCdrs.position() == binaryCdrs.limit()) {
					break;
				}
			}
			try {
				short talCode = binaryCdrs.getShort();
				short length = binaryCdrs.getShort();
				if (length < 1) {
					throw new Exception(
							"length is negative or zero (length = "
									+ length
									+ "). Probably an error caused it by reading from a wrong position in the binary file");
				}
				byte[] valueBytes = new byte[length];

				String columnTagId = generateFieldColumn("Tag#",
						String.valueOf(talCode), 4);
				traceReport.append(columnTagId);

				String columnName = (String) fieldNamesByTagId.get(String
						.valueOf(talCode));
				String columnFieldName = generateFieldColumn(null, columnName,
						25);
				traceReport.append(columnFieldName);

				String typeDescription = null;
				String tracedValue = null;
				if (shortFields.contains(Short.valueOf(talCode))) {
					short valueShort = binaryCdrs.getShort();
					typeDescription = "Short";
					tracedValue = String.valueOf(valueShort);
				} else if ((length != 4)
						|| (!intFields.contains(Short.valueOf(talCode)))) {
					binaryCdrs.get(valueBytes, 0, length);
					String valueString = new String(valueBytes);
					typeDescription = "String";
					tracedValue = valueString;
				} else {
					int valueInteger = binaryCdrs.getInt();
					typeDescription = "Integer";
					tracedValue = String.valueOf(valueInteger);
				}
				String columnTypeDescription = generateFieldColumn(null,
						typeDescription, 8);
				traceReport.append(columnTypeDescription);
				traceReport.append(tracedValue);

				traceReport.append("\n");
			} catch (Exception e) {
				e.printStackTrace();
				traceReport.append(" +Exception!!! ").append(e.getMessage());

				return traceReport.toString();
			}
		}
		return traceReport.toString();
	}

	private String generateFieldColumn(String columnName, String value,
			int lengthOfField) {
		if (value == null) {
			value = "";
		}
		int valueLength = value.length();
		int freeSpaceLength = lengthOfField - valueLength;

		StringBuffer sb = new StringBuffer();
		if ((columnName != null) && (!columnName.equals(""))) {
			sb.append(columnName);
			sb.append(" ");
		}
		sb.append(value);
		for (int i = 0; i < freeSpaceLength; i++) {
			sb.append(" ");
		}
		sb.append("| ");
		return sb.toString();
	}

	private boolean checkIfCdrEnds(ByteBuffer binCdrs) {
		byte nextByte = binCdrs.get();
		byte nextByte1 = binCdrs.get();
		if ((nextByte == 0) && (nextByte1 == 0)) {
			return true;
		}
		binCdrs.position(binCdrs.position() - 2);
		return false;
	}

	private void loadConfig(String configFilePath) {
		Properties prop = new Properties();
		FileInputStream fis = null;
		try {
			fis = new FileInputStream(configFilePath);
		} catch (FileNotFoundException e) {
			System.out.print("Failed to load file - the file doesn't exist ");
			System.out.print("Use default configuration!");
			return;
		}
		try {
			prop.load(fis);
			fis.close();
		} catch (Exception e) {
			System.out.print("Failed to load file - the file is invalid ");
			System.out.print("Use default configuration!");
		}
		Map<Integer, String> talids = new HashMap<>();
		Map<Integer, String> dataTypes = new HashMap<>();
		Enumeration<Object> keys = prop.keys();
		StringTokenizer st;
		while (keys.hasMoreElements()) {
			String key = keys.nextElement().toString();
			if ((key.contains("FIELD"))
					&& ((key.contains("talid")) || (key.contains("datatype")))) {
				st = new StringTokenizer(key, ".");
				st.nextToken();
				st.nextToken();
				st.nextToken();
				if (key.contains("talid")) {
					talids.put(Integer.valueOf(st.nextToken()), prop.get(key)
							.toString());
				} else {
					dataTypes.put(Integer.valueOf(st.nextToken()), prop
							.get(key).toString());
				}
			}
		}
		for (Integer key : dataTypes.keySet()) {
			if ((dataTypes.get(key) != null)
					&& (((String) dataTypes.get(key)).equals("2"))) {
				intFields.add(Short.valueOf((String) talids.get(key)));
			}
			if ((dataTypes.get(key) != null)
					&& (((String) dataTypes.get(key)).equals("3"))) {
				shortFields.add(Short.valueOf((String) talids.get(key)));
			}
		}
	}

	private void loadTraceFile(String traceFilename,
			String traceConfigFileNames, String reportFilename)
			throws FileNotFoundException, IOException {
		FileChannel fileChannel = null;
		FileInputStream fis = null;
		try {
			String[] strings = traceConfigFileNames.split(";");
			for (String string : strings) {
				if ((string != null) && (string.length() > 0)) {
					loadConfig(string);
				}
			}
			File binFile = new File(traceFilename);
			long fileSize = binFile.length();
			if (fileSize > 2147483647L) {
				System.out.println("can't handle files of " + fileSize
						+ "byes - maxs supported is " + 2147483647 + " bytes");
			}
			ByteBuffer readBuffer = ByteBuffer.allocate((int) fileSize);
			fis = new FileInputStream(binFile);
			fileChannel = fis.getChannel();
			fileChannel.read(readBuffer);

			String traceReport = generateReportFromBinFile(readBuffer,
					traceFilename);
			System.out.println(traceReport);

			writeReportFile(reportFilename, traceReport);
		} finally {
			if (fileChannel != null) {
				fileChannel.close();
			}
			if (fis != null) {
				fis.close();
			}
		}
	}

	private void writeReportFile(String reportFilename, String traceReport)
			throws IOException {
		if (reportFilename != null) {
			File file = new File(reportFilename);
			FileWriter fw = new FileWriter(file);

			fw.write(traceReport);
			fw.flush();
			fw.close();
		}
	}

	private static void doHelp() {
		System.out.println("Comverse Trace Viewer");
		System.out.println("\n");
		System.out
				.println("Open for preview generated binary trace files. The result can be written in report file.");
		System.out.println("\n");
		System.out
				.println("Usage:   TraceViewer [tracefilename] [<traces configuration file;> traces configuration file] [<reportFilename>]");
		System.out
				.println("\t\ttracefilename: The full path of binary trace file.");
		System.out
				.println("\t\ttraces configuration file: The full path of all needed traces configuration files separated by ;");
		System.out
				.println("\t\treportFilename: The full path of reportFilename where to be saved.");
		System.out.println("\n");
		System.out
				.println("Example: TraceViewer msg_trace.log.header.MGW.1.1.20140702144920 TraceEvent.config;TraceInfo.config tracesReport.txt");
	}
}

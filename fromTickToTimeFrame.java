import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;


public class fromTickToTimeFrame {

	/**
	 * @param args
	 * @throws IOException 
	 */
	public static void main(String[] args) throws IOException {
		
        String inputFile = "USDJPY-2015-08.csv";
		int period = 5;
		BufferedReader br = new BufferedReader(new FileReader("/home/edge7/Scrivania/AutoSystemTrading/historicalData/" + inputFile));
		PrintWriter out = new PrintWriter("/home/edge7/Scrivania/AutoSystemTrading/historicalData/" + inputFile + "_" + period);		

		String line= "";
		int counter = 0;
		double high = 0;
		double close = 0;
		double low = 11111110;
		String open = "";
		double init_time = 0;
		String startHour = "";
		while( ( line = br.readLine() )!= null)
		{
			String time_tmp = line.split(",")[1];
			time_tmp = time_tmp.split(":")[1]; //minutes
			double current_price = Double.parseDouble(line.split(",")[2]);
			if( counter == 0)
			{
				init_time = Double.parseDouble(time_tmp);
				open = line.split(",")[2];
			}
			counter ++;
			if( high < current_price)
				high = current_price;
			if( low > current_price)
				low = current_price;

			String tmp_ = line.split(",")[1].split(" ")[1];
            String hour_ = tmp_.split(":")[0]; 

			double current_time = Double.parseDouble(time_tmp);
			if( Math.abs(current_time - init_time) >= (period) )
			{
				counter = 0;
				close = current_price;
                System.out.println(line);
                String tmp = line.split(",")[1].split(" ")[1];
                String hour = tmp.split(":")[0]; 
                String minute = tmp.split(":")[1];
				out.write(Integer.parseInt(hour) + "," + Integer.parseInt(minute) + ","  + open + "," + high + "," + low + "," + close);
				out.write("\n");
				high = 0;
				low = 9999999;
				startHour = hour;
			}
			
		}
		br.close();
		out.close();
	}

}

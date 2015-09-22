import scala.collection.mutable.ListBuffer
import scala.io.Source
import scala.reflect.io.File

/**
 * Created by edge7 on 28/08/15.
 */
object MAs 
{
     val values = new ListBuffer[Double]();
     val period = 9;
     var index = 0;
     def getMA( close: Double) : Double =
     {
         if( values.length < period)
         {
             values.insert(index, close)
         }
         else
             values.update(index, close)

         index = index +1;
         index = index % period;

         val sum = values.sum;
         println("MEDIA " + sum/period.toDouble)
         println("VALORE ATTUALE " + close)
         (sum / period.toDouble);
     }
}
 object Williams
 {
     var valuesH = new ListBuffer[Double]();
     var valuesL = new ListBuffer[Double]();

     val period = 14;
     var index = 0;
     def getWilliams(higH: Double, loW: Double, close: Double ) = 
     {
         if( valuesH.length < 14)
         {   valuesH.insert(index, higH)
             valuesL.insert(index, loW);
         }
         else
         {
             valuesH.update(index, higH);
             valuesL.update(index, loW);
         }
         var cMax = -1000.0;
         var cLow = 10000.0;
         for( item <- valuesL)
              if( item < cLow )
                  cLow = item;

         for( item <- valuesH )
              if( item > cMax)
                  cMax = item;

         index = index +1;
         index = index % period;

         -100.0 *((cMax - close) / ( cMax - cLow ))

     }
 }
object RSI
{
    var avgLoss = 0.0;
    var avgGain = 0.0;
    var counter = 0.0;

    def getRSI( body:Double ) = 
    {
        counter = counter +1;
        var rsi = -1.0;
        if( counter < 14 )
        {
            if( body < 0 )
                avgLoss = avgLoss + Math.abs(body);
            else
                avgGain = avgGain + Math.abs(body);      
        }
        else
        {
           counter = 15;
           if( body > 0 )
               avgGain = ( avgGain * 13 + body) /14.0;
           else
               avgLoss = (avgLoss *13 + Math.abs(body))/14.0;

           val rs = avgGain / avgLoss;
           rsi = 100 - (100 /(rs + 1));
        }
        rsi
    }

}
object Percentage
{
  var values = new ListBuffer[Double]()
  var index = 0
  var max = 8
  var full = false 
  def add(value: Int)
  {
      if( ! full )
          values.insert(index, value)
      else
          values.update(index, value)
      index = index + 1
      index = index % max
      if( index == 0) full = true
      println("INDEX" + index)
      println("LEN " + values.length)
  }
  def getPercentageBullish() : Double =
  {
      var bull = 0
      for( value <- values)
           if( value > 0) 
               bull = bull +1     

      println("bull "+ bull)
      100*(bull.toDouble / max.toDouble)      

  }
}
object LinesAhead
{
  var linesAhead = new ListBuffer[String]()
  var index = 0
  var max = 5
  var lastMarket = 0;
  def add(line : String) =
  {
    if( linesAhead.length < max )
    {
      linesAhead.insert(index, line)
    }
    else
    {
      for( i <- (0) to (max -2) )
        linesAhead.update(i, linesAhead(i+1))

      linesAhead.update(max -1, line)
    }
    index = (index +1) % max
  }
  def printAll = 
  {
    for( item <- linesAhead)
         println(item)
  }
  def getMarket( value : Double ): Int =
  {
    for( item <- linesAhead) {
      val current = item.split(",")(5).toDouble
      //println("CURRENT " + current)
      //println("VALUE "+ value)
      //println("DIFF " + (current-value))
      /*TODO:  BUY, so use HIGH */
      if ((current - value) > 0.1) 
      { //BUY 
        if( lastMarket == 3 )
        {
          return 0;
        }
        lastMarket = 2;
        return 2

      }
      /*TODO: SELL, so use LOW */
      if ((current - value) < -0.1) { //SELL

        if(lastMarket == 3)
          return 0;
        lastMarket = 1;
        return 1
      }
    }
    lastMarket = 0;
    return 0
  }
}
object AverageHigh
{
  var values = new ListBuffer[Double]();
  var l = new ListBuffer[Double]()
  var index = 0;
  val threeshold = 1
  var ready = false;

  def add(value : Double) : Unit =
  {
    if( values.length < threeshold)
      values.insert(index, value)
    else
    {
      for( i <- (threeshold -1) to 1 by -1)
        values.update(i -1, values(i))

      values.update(threeshold -1, value)
      ready = true

    }
    index = (index +1 ) % threeshold
    //println("LEN" + values.length)
    return
  }
  def getAverage =
  {
    l = ListBuffer[Double]()
    (0 to values.length - 2).foreach { case i => l.insert(i, values(i + 1)*10 - values(i)*10) }
    val sum = values.sum
    //println("SUM " + sum)
    val ret = (sum / threeshold.toDouble)
    if( ! ready )
      -1.0
    else
      ret
  }
  def getSD: Double =
  {
    val average = getAverage
    val sd = Math.sqrt(l.map( x => (x - average)*(x - average)).sum / (threeshold).toDouble ).toDouble
    sd
  }
}
object AverageHigh1Hour
{
  var values = new ListBuffer[Double]();
  var l = new ListBuffer[Double]()
  var index = 0;
  val threeshold = 1
  var ready = false;

  def add(value : Double) : Unit =
  {
    if( values.length < threeshold)
      values.insert(index, value)
    else
    {
      for( i <- (threeshold -1) to 1 by -1)
        values.update(i -1, values(i))

      values.update(threeshold -1, value)
      ready = true

    }
    index = (index +1 ) % threeshold
    //println("LEN" + values.length)
    return
  }
  def getAverage =
  {
    l = ListBuffer[Double]()
    (0 to values.length - 2).foreach { case i => l.insert(i, values(i + 1)*10 - values(i)*10) }
    val sum = values.sum
    //println("SUM " + sum)
    val ret = (sum / threeshold.toDouble)
    if( ! ready )
      -1.0
    else
      ret
  }
  def getSD: Double =
  {
    val average = getAverage
    val sd = Math.sqrt(l.map( x => (x - average)*(x - average)).sum / (threeshold).toDouble ).toDouble
    sd
  }
}
object AverageLow1Hour
{
  var values = new ListBuffer[Double]();
  var l = new ListBuffer[Double]()
  var index = 0;
  val threeshold = 1
  var ready = false;

  def add(value : Double) : Unit =
  {
    if( values.length < threeshold)
      values.insert(index, value)
    else
    {
      for( i <- (threeshold -1) to 1 by -1)
        values.update(i -1, values(i))

      values.update(threeshold -1, value)
      ready = true

    }
    index = (index +1 ) % threeshold
    //println("LEN" + values.length)
    return
  }
  def getAverage =
  {
    l = ListBuffer[Double]()
    (0 to values.length - 2).foreach { case i => l.insert(i, values(i + 1)*10 - values(i)*10) }
    val sum = values.sum
    //println("SUM " + sum)
    val ret = (sum / threeshold.toDouble)
    if( ! ready )
      -1.0
    else
      ret
  }
  def getSD: Double =
  {
    val average = getAverage
    val sd = Math.sqrt(l.map( x => (x - average)*(x - average)).sum / (threeshold).toDouble ).toDouble
    sd
  }
}
object AverageLow
{
  var values = new ListBuffer[Double]();
  var l = new ListBuffer[Double]()
  var index = 0;
  val threeshold = 1
  var ready = false;

  def add(value : Double) : Unit =
  {
    if( values.length < threeshold)
      values.insert(index, value)
    else
    {
      for( i <- (threeshold -1) to 1 by -1)
        values.update(i -1, values(i))

      values.update(threeshold -1, value)
      ready = true

    }
    index = (index +1 ) % threeshold
    //println("LEN" + values.length)
    return
  }
  def getAverage =
  {
    l = ListBuffer[Double]()
    (0 to values.length - 2).foreach { case i => l.insert(i, values(i + 1)*10 - values(i)*10) }
    val sum = values.sum
    //println("SUM " + sum)
    val ret = (sum / threeshold.toDouble)
    if( ! ready )
      -1.0
    else
      ret
  }
  def getSD: Double =
  {
    val average = getAverage
    val sd = Math.sqrt(l.map( x => (x - average)*(x - average)).sum / (threeshold).toDouble ).toDouble
    sd
  }
}
object AverageBody
{
  var values = new ListBuffer[Double]();
  var l = new ListBuffer[Double]()
  var index = 0;
  val threeshold = 1
  var ready = false;

  def add(value : Double) : Unit =
  {
    if( values.length < threeshold)
      values.insert(index, value)
    else
    {
      for( i <- (threeshold -1) to 1 by -1)
        values.update(i -1, values(i))

      values.update(threeshold -1, value)
      ready = true

    }
    index = (index +1 ) % threeshold
    //println("LEN" + values.length)
    return
  }
  def getAverage =
  {
    l = ListBuffer[Double]()
    (0 to values.length - 2).foreach { case i => l.insert(i, values(i + 1)*10 - values(i)*10) }
    val sum = values.sum
    //println("SUM " + sum)
    val ret = (sum / threeshold.toDouble)
    if( ! ready )
      -1.0
    else
      ret
  }
  def getSD: Double =
  {
    val average = getAverage
    val sd = Math.sqrt(l.map( x => (x - average)*(x - average)).sum / (threeshold).toDouble ).toDouble
    sd
  }
}
object AverageBody1Hour
{
  var values = new ListBuffer[Double]();
  var l = new ListBuffer[Double]()
  var index = 0;
  val threeshold = 1
  var ready = false;

  def add(value : Double) : Unit =
  {
    if( values.length < threeshold)
      values.insert(index, value)
    else
    {
      for( i <- (threeshold -1) to 1 by -1)
        values.update(i -1, values(i))

      values.update(threeshold -1, value)
      ready = true

    }
    index = (index +1 ) % threeshold
    //println("LEN" + values.length)
    return
  }
  def getAverage =
  {
    l = ListBuffer[Double]()
    (0 to values.length - 2).foreach { case i => l.insert(i, values(i + 1)*10 - values(i)*10) }
    val sum = values.sum
    //println("SUM " + sum)
    val ret = (sum / threeshold.toDouble)
    if( ! ready )
      -1.0
    else
      ret
  }
  def getSD: Double =
  {
    val average = getAverage
    val sd = Math.sqrt(l.map( x => (x - average)*(x - average)).sum / (threeshold).toDouble ).toDouble
    sd
  }
}
object parseForModel
{
  // Return Body in Pips
  var oldHigh = 0.0
  var oldBody = 0.0
  var oldLow = 0.0
  var oldHighSign = 0
  var oldBodySign = 0
  var oldLowSign = 0
  var isBullishOrBearOld = 0;
  var values = new ListBuffer[Double]();
  var valuesHigh = new ListBuffer[Double]();
  var valuesLow = new ListBuffer[Double]();
  var threeshold = 5;
  var index = 0;
  var index_High = 0;
  var index_Low = 0;
  def addValueHigh( value : Double ) = 
  {
      if( valuesHigh.length < threeshold)
          valuesHigh.insert(index_High, value)
      else
      {  
          for( i <- (0) to threeshold -2)
           valuesHigh.update(i , valuesHigh(i +1))

          valuesHigh.update(threeshold -1, value)

    }
    index_High = (index_High +1 ) % threeshold
  }
  def getStringHigh() = 
  {
      var ret = "10";
      values.map( item => if( ret.equals("10")) ret = item + ""; else ret = ret + "," + item );
      ret   
  }
  def addValueLow( value : Double ) = 
  {
      if( valuesLow.length < threeshold)
          valuesLow.insert(index_Low, value)
      else
      {  
          for( i <- (0) to threeshold -2)
           valuesLow.update(i , valuesLow(i +1))

          valuesLow.update(threeshold -1, value)

    }
    index_Low = (index_Low +1 ) % threeshold
  }
  def getStringLow() = 
  {
      var ret = "10";
      values.map( item => if( ret.equals("10")) ret = item + ""; else ret = ret + "," + item );
      ret  
  }
  def diffFromAvg(value : Double) = 
  {
      val sum = values.sum 
      val avg = sum/threeshold
      value - avg 
  }
  def addValue( value : Double ) = 
  {
      if( values.length < threeshold)
          values.insert(index, value)
      else
      {  
          for( i <- (0) to threeshold -2)
           values.update(i , values(i +1))

          values.update(threeshold -1, value)

    }
    index = (index +1 ) % threeshold
  }
 

  def getString() = 
  {
      var ret = "10";
      values.map( item => if( ret.equals("10")) ret = item + ""; else ret = ret + "," + item );
      ret  
  }
  def getOldHigh(): Double  =
  {
      oldHigh
  }

  def computeBody( array: Array[String]): Double =
  {
      val open = array(2).toDouble
      val close = array(5).toDouble
      (open - close) * 10
  }
  def bullishOrBear( array: Array[String]) : Int =
  {
      val open = array(2).toDouble
      val close = array(5).toDouble
      if( ( open - close) > 0) return 0 // bear
      return 1 //bull
  }
  def computeHigh( array : Array[String]) : Double =
  {
      val bullOrBear = bullishOrBear(array)
      if( bullOrBear == 0 ) // bear
      {
          ( array(3).toDouble - array(2).toDouble ) * 10
      }
      else ( array(3).toDouble - array(5).toDouble) * 10
  }
  def computeLow( array : Array[String]) : Double =
  {
    val bullOrBear = bullishOrBear(array)
    if( bullOrBear == 0 ) // bear
    {
      ( array(5).toDouble - array(4).toDouble ) * 10
    }
    else ( array(2).toDouble - array(4).toDouble ) * 10
  }
  def encodeMinute( minute : String ) : String =
  {
      if( minute.equals("15")) "1"
      else if( minute.equals("30")) "2"
      else if(minute.equals("45")) "3"
      else "0"
  }
  def percent( current: Double, avr: Double): Double =
  {
      println("Media " + avr)
       if( avr == 0 ) return 0
       val per =  100* (current - avr)/avr
       println("per " + per)
       println("current " + current)
       val vali = per
       var res = vali
       res 
  }
  def percentSign( current: Double, avr: Double ): Int =
  {
       val per = 100* (current - avr)/avr
       if( per < 0 ) 0
       else 1
  }
  def main(args:Array[String]) =
  {
    val inputFile = "USDJPY-2015-08.csv_5"
    val averageHigh = AverageHigh
    val averageLow = AverageLow
    val averageBody = AverageBody
    val averageHigh1Hour = AverageHigh1Hour
    val averageLow1Hour = AverageLow1Hour
    val averageBody1Hour = AverageBody1Hour
    val linesAhead = LinesAhead
    val percentage = Percentage
    var williams = Williams
    val rsi = RSI 
    val mas = MAs
    var index = 0
    var currentChange = 0.0
    var priceOld = 0.0;
    var priceIndex = 0;
    var oldRsi = 0.0;
    var oldWilliams = 0.0;
    var oldDiffMas = 0.0
    // OPEN FILE RAW DATA
    val lineI = Source.fromFile("/home/edge7/Scrivania/AutoSystemTrading/historicalData/" + inputFile ).getLines()
    var oldChange= 0.0;
    // OPEN FILE RAW DATA
    for( lineAhead <- Source.fromFile("/home/edge7/Scrivania/AutoSystemTrading/historicalData/" + inputFile ).getLines())
    {
      // ADD LINE IN BUFFER_LIST
      linesAhead.add(lineAhead)
      index = index +1
      // After 6 Lines, start to process data
      if( index > 5)
      {
        val line = lineI.next()
        val array = line.split(",")
        println("LINE")
        println(line)
        println("ALL")
        priceIndex = priceIndex +1;
        priceIndex = (priceIndex % 4);
        linesAhead.printAll
        val hour = array(0)
        val minute = array(1).toInt / 5
        val open = array(2).toDouble
        val close = array(5).toDouble
        val output = linesAhead.getMarket(close)
        val high = computeHigh( array )
        val low = computeLow( array )
        val body = computeBody( array )        
        val upOrDown = { if(( close - open ) < 0 )0; 
                         else 1
                       }
        val trend = close - priceOld
        val will = williams.getWilliams(array(3).toDouble, array(4).toDouble, close)
        val movingAverageS = mas.getMA(close)
        val diffMA = 100.0*(close - movingAverageS);
        if( priceIndex == 0)
            priceOld = close;
        println("upOrDown " + upOrDown)
        percentage.add(upOrDown)
        val perc = percentage.getPercentageBullish
        print("PERC " + perc +"\n")
        val avrHigh = averageHigh.getAverage
        val avrLow = averageLow.getAverage
        val avrBody = averageBody.getAverage

        val isHighAbove =
                          {
                             percent(high, avrHigh)
                          }
        val isLowAbove = percent(low , avrLow)
        val isBodyAbove = percent(body , avrBody)
        val signHigh = percentSign(high, avrHigh)
        val signLow = percentSign(low, avrLow)
        val signBody = percentSign(body, avrBody)
        currentChange = body
        val isBullishOrBear = bullishOrBear(array)
        val diffFromAvgValue = diffFromAvg(body)
        addValue(body)
        addValueLow(low)
        addValueHigh(high)
        println("BODY " + body)
        var percentBody =100* (currentChange - oldChange)/(oldChange);
        if( oldChange == 0) percentBody = 0;
        val stringBullOrBear = getString
        val stringHigh = getStringHigh
        val stringLow = getStringLow 
        val rsiCurrent = rsi.getRSI(body);
        var diffRsi = rsiCurrent - oldRsi
        var diffWill = will - oldWilliams
        //println( "MEDIA " +average.getAverage)
        //println( "SD " +average.getSD)
        if( avrHigh != -1  && values.length == threeshold && rsiCurrent != -1.0)
        {
          val result = output + "," + hour + ","  + stringBullOrBear + "," + stringHigh + "," + stringLow +"," + rsiCurrent + "," + diffRsi + "," + diffMA + "," + oldDiffMas;
          File("/home/edge7/Scrivania/AutoSystemTrading/historicalData/" + inputFile + "_model").appendAll(result + "\n")

        }
        index = 18
        oldRsi = rsiCurrent
        oldWilliams = will 
        oldHigh = isHighAbove
        oldLow = isLowAbove
        oldBody = isBodyAbove
        oldLowSign = signLow
        oldBodySign = signBody
        oldHighSign = signHigh
        isBullishOrBearOld = isBullishOrBear
        averageHigh.add(high)
        averageLow.add(low)
        averageBody.add(body)
        oldChange = currentChange;
        oldDiffMas = diffMA
      }
      //println(index)



    }
  }
}

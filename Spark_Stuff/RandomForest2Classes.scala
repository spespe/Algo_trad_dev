import org.apache.spark.SparkContext
import org.apache.spark.mllib.tree.DecisionTree
import org.apache.spark.mllib.regression.LabeledPoint
import org.apache.spark.mllib.linalg.Vectors
import org.apache.spark.mllib.tree.configuration.Algo._
import org.apache.spark.mllib.tree.impurity.Gini
import org.apache.spark.mllib.tree.DecisionTree
import org.apache.spark.mllib.util.MLUtils
import org.apache.spark.rdd.RDD
import org.apache.spark.mllib.tree.RandomForest
import java.io.FileOutputStream
import java.io.ObjectOutputStream 

// Load and parse the data file.

/* My function    */

def classProbabilities( data: RDD[LabeledPoint]) : Array[ Double ] = 
{
	val countsByCategory = data.map( _.label).countByValue()
	val counts = countsByCategory.toArray.sortBy( _._1 ).map( _._2 )
	counts.map(_.toDouble / counts.sum )
}
/****************************/



//val trainingData = parsedData
//val testData = tdata.map { line =>
//  val parts = line.split(',').map(_.toDouble)
//  LabeledPoint(parts(0), Vectors.dense(parts.tail))
//}

//  Empty categoricalFeaturesInfo indicates all features are continuous.
val numClasses = 2
val categoricalFeaturesInfo = Map[Int, Int]( 0-> 24 )
val featureSubsetStrategy = "auto" // Let the algorithm choose.
val maxBins = 2048
var index = 0;
val data_ = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-01.csv_5_model")
val tdata = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-02.csv_5_model")
val marzo = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-03.csv_5_model")
val luglio= sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-07.csv_5_model")
val aprile = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-04.csv_5_model")
val maggio = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-05.csv_5_model")
val giugno = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-06.csv_5_model")
val data = data_.union(tdata).union(marzo).union(aprile).union(maggio).union(giugno).union(luglio)
val agosto = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-08.csv_5_model")
val parsedData = data.map { line =>
  val parts = line.split(',').map(_.toDouble)
  val class_ = { if( parts(0) == 2) 1; else if( parts(0) == 1) 0; else 5 
  }
  LabeledPoint(class_, Vectors.dense(parts.tail))
}.filter( x=> x.label != 5)

val validationSet = agosto.map { line =>
  val parts = line.split(',').map(_.toDouble)
  val class_ = { if( parts(0) == 2) 1; else if( parts(0) == 1) 0; else 5 
  }
  LabeledPoint(class_, Vectors.dense(parts.tail))
}.filter( x=> x.label != 5)

// Split the data into training and test sets (25% held out for testing)
val splits = parsedData.randomSplit(Array(0.75, 0.25))
val (trainingDataTmp, testData) = (splits(0), splits(1))

scala.tools.nsc.io.File("Risultati_USD_JPY_2_classes").appendAll("maxDepth" + "," + "numTrees" + "," + "testPer" + "," + "sellSignalsButBuy" + "," +
"sellSignalsOk"  + "," +
"BuySignalsButSell" + "," +
"BuySignalsButOut" + "," +
"BuySignalsOk" + "," +
"dico_1" + ","+
"tot_1" + ","+
"dico_0" + ","+
"tot_0 "+ ","+
"dico_2" + ","+
"tot_2" + ","+
"\n")

for(   maxDepth <- Array( 5,7, 10,12, 15, 17, 20, 25);
       cutOff <- Array(0);
       numTrees <- Array( 20, 50);	
       impurity <- Array("entropy"))
yield{

val trainingData = trainingDataTmp.map { line =>
          val r = scala.util.Random
          val v = r.nextInt(100)
          if( v < cutOff && v > 0) 
          {     
               if( line.label == 0)
                   List(LabeledPoint(5, line.features ))
               else if( v < 8) List(line, line)
               else List(line) 
          }
          else List(line)  
}.flatMap(identity).filter( x => x.label != 5 )

trainingData.cache 
testData.cache  
trainingDataTmp.cache 
val model = RandomForest.trainClassifier(trainingData, numClasses, categoricalFeaturesInfo,
  numTrees, featureSubsetStrategy, impurity, maxDepth, maxBins)

// Evaluate model on test instances and compute test error
val labelAndPreds = testData.map { point =>
  val prediction = model.predict(point.features)
  (point.label, prediction)
}
val testPer = labelAndPreds.filter(r => r._1 == r._2).count.toDouble / testData.count()

//println("Learned classification tree model:\n" + model.toDebugString)

val tot_1 = labelAndPreds.filter(r => r._1 == 1).count.toDouble
val tot_2 = labelAndPreds.filter(r => r._1 == 2).count.toDouble
val tot_0 = labelAndPreds.filter(r => r._1 == 0).count.toDouble
val ok_1 = labelAndPreds.filter(r => r._1 == 1 && r._2 == 1).count.toDouble
val dico_1 = labelAndPreds.filter(r => r._2 == 1).count.toDouble

ok_1/dico_1

val ok_2 = labelAndPreds.filter(r => r._1 == 2 && r._2 == 2).count.toDouble
val dico_2 = labelAndPreds.filter(r => r._2 == 2).count.toDouble

ok_2/dico_2

val ok_0 = labelAndPreds.filter(r => r._1 == 0 && r._2 == 0).count.toDouble
val dico_0 = labelAndPreds.filter(r => r._2 == 0).count.toDouble

ok_0/dico_0

println("Test performance Totale = " + testPer)
val sellSignalsButBuy = labelAndPreds.filter(r => r._1 == 1 && r._2 == 0).count.toDouble/dico_0
val sellSignalsOk = labelAndPreds.filter(r => r._1 == 0 && r._2 == 0).count.toDouble/dico_0

val BuySignalsButSell = labelAndPreds.filter(r => r._1 == 0 && r._2 == 1).count.toDouble/dico_1
val BuySignalsOk = labelAndPreds.filter(r => r._1 == 1 && r._2 == 1).count.toDouble/dico_1

val outSignalsOk = labelAndPreds.filter(r => r._1 == 0 && r._2 == 0).count.toDouble/dico_0
val trainPriorProbabilities = classProbabilities(trainingData)
val testPrior = classProbabilities(testData)
val random = trainPriorProbabilities.zip(testPrior).map {
												case(trainProb, testProb) => trainProb*testProb
											}.sum 
val myMetrics = sellSignalsOk * dico_2 - sellSignalsButBuy * dico_2 + BuySignalsOk * dico_1 - BuySignalsButSell*dico_1
println("Accuracy Random Classifier = " + random )
println("Test performance Totale = " + testPer)
val fos = new FileOutputStream("modelli/" + index + "_2_classes" )
  val oos = new ObjectOutputStream(fos)  
  oos.writeObject(model)  
  oos.close
  index = index +1;
       scala.tools.nsc.io.File("Risultati_USD_JPY_2_classes").appendAll(maxDepth + "," + numTrees + "," + testPer + "," + sellSignalsButBuy + "," +
sellSignalsOk  + "," + 
BuySignalsButSell + "," +
BuySignalsOk + "," +
dico_1 + ","+
tot_1 + ","+
dico_0 + ","+
tot_0 + ","+
dico_2 + ","+
tot_2 + ","+
impurity + ","+
cutOff + "," + myMetrics + "," + index + 
"\n")

       scala.tools.nsc.io.File("Risultati_USD_JPY_2_classes").appendAll("VALIDATION SET \n");

       val labelAndPredsV = validationSet.map { point =>
  val prediction = model.predict(point.features)
  (point.label, prediction)
  }
val testPerV = labelAndPredsV.filter(r => r._1 == r._2).count.toDouble / labelAndPredsV.count()
//println("Learned classification tree model:\n" + model.toDebugString)

val tot_1V = labelAndPredsV.filter(r => r._1 == 1).count.toDouble
val tot_2V = labelAndPredsV.filter(r => r._1 == 2).count.toDouble
val tot_0V = labelAndPredsV.filter(r => r._1 == 0).count.toDouble
val ok_1V = labelAndPredsV.filter(r => r._1 == 1 && r._2 == 1).count.toDouble
val dico_1V = labelAndPredsV.filter(r => r._2 == 1).count.toDouble

val ok_2V = labelAndPredsV.filter(r => r._1 == 2 && r._2 == 2).count.toDouble
val dico_2V = labelAndPredsV.filter(r => r._2 == 2).count.toDouble

val ok_0V = labelAndPredsV.filter(r => r._1 == 0 && r._2 == 0).count.toDouble
val dico_0V = labelAndPredsV.filter(r => r._2 == 0).count.toDouble

val sellSignalsButBuyV = labelAndPredsV.filter(r => r._1 == 1 && r._2 == 0).count.toDouble/dico_0V
val sellSignalsOkV = labelAndPredsV.filter(r => r._1 == 0 && r._2 == 0).count.toDouble/dico_0V

val BuySignalsButSellV = labelAndPredsV.filter(r => r._1 == 0 && r._2 == 1).count.toDouble/dico_1V
val BuySignalsOkV = labelAndPredsV.filter(r => r._1 == 1 && r._2 == 1).count.toDouble/dico_1V

val outSignalsOkV = labelAndPredsV.filter(r => r._1 == 0 && r._2 == 0).count.toDouble/dico_0V

val myMetricsV = sellSignalsOkV * dico_2V - sellSignalsButBuyV * dico_2V + BuySignalsOk * dico_1V - BuySignalsButSell*dico_1V

scala.tools.nsc.io.File("Risultati_USD_JPY_2_classes").appendAll(maxDepth + "," + numTrees + "," + testPerV + "," + sellSignalsButBuyV + "," +
sellSignalsOkV  + "," + 
BuySignalsButSellV + "," +
BuySignalsOkV + "," +
dico_1V + ","+
tot_1V + ","+
dico_0V + ","+
tot_0V + ","+
dico_2V + ","+
tot_2V + ","+
impurity + ","+
cutOff + "," + myMetricsV + "," + (index-1) + 
"\n")
}

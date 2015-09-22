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
val numClasses = 3
val categoricalFeaturesInfo = Map[Int, Int]( 0-> 24)
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
  var class_ = parts(0)
  if( class_  != 0)
      class_ = 1;

  LabeledPoint(class_, Vectors.dense(parts.tail))
}
val validationData = agosto.map { line =>
  val parts = line.split(',').map(_.toDouble)
  var class_ = parts(0)
  if( class_  != 0)
      class_ = 1;      
  LabeledPoint(class_, Vectors.dense(parts.tail))
}
// Split the data into training and test sets (25% held out for testing)
val splits = parsedData.randomSplit(Array(0.75, 0.25))
val (trainingDataTmp, testData) = (splits(0), splits(1))

scala.tools.nsc.io.File("Risultati_USD_JPY_MarketOrOutOFMArket").appendAll("maxDepth" + "," + "numTrees" +
 "," + "testPer"  + "," 
+ "MarketOk" + "," +
"MarketButOut" + "," +
"OutOk" + "," + 
"OutButIn" + "," +
"dico_1" + ","+
"tot_1" + ","+
"dico_0" + ","+
"tot_0 "+ ","+
"\n")

for(   maxDepth <- Array(5, 7, 12, 15, 17, 20, 25);
       cutOff <- Array(0, 20, 30, 40, 50, 60);
       numTrees <- Array( 20);	
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
var labelAndPreds = testData.map { point =>
  val prediction = model.predict(point.features)
  (point.label, prediction)
}
var testPer = labelAndPreds.filter(r => r._1 == r._2).count.toDouble / testData.count()
//println("Learned classification tree model:\n" + model.toDebugString)

var tot_1 = labelAndPreds.filter(r => r._1 == 1).count.toDouble
var tot_0 = labelAndPreds.filter(r => r._1 == 0).count.toDouble
var ok_1 = labelAndPreds.filter(r => r._1 == 1 && r._2 == 1).count.toDouble
var dico_1 = labelAndPreds.filter(r => r._2 == 1).count.toDouble

var ok_2 = labelAndPreds.filter(r => r._1 == 2 && r._2 == 2).count.toDouble
var dico_2 = labelAndPreds.filter(r => r._2 == 2).count.toDouble

var ok_0 = labelAndPreds.filter(r => r._1 == 0 && r._2 == 0).count.toDouble
var dico_0 = labelAndPreds.filter(r => r._2 == 0).count.toDouble

var inButOut = labelAndPreds.filter(r => r._1 == 0 && r._2 == 1).count.toDouble/dico_1
var inOk = labelAndPreds.filter(r => r._1 == 1 && r._2 == 1).count.toDouble/dico_1

var outButIn = labelAndPreds.filter(r => r._1 == 1 && r._2 == 0).count.toDouble/dico_0
var outOk = labelAndPreds.filter(r => r._1 == 0 && r._2 == 0).count.toDouble/dico_0

var trainPriorProbabilities = classProbabilities(trainingData)
var testPrior = classProbabilities(testData)
var random = trainPriorProbabilities.zip(testPrior).map {
												case(trainProb, testProb) => trainProb*testProb
											}.sum 
println("Accuracy Random Classifier = " + random )
println("Test performance Totale = " + testPer)

val fos = new FileOutputStream("modelli/" + index + "_marketOrOutOfMarket" )
  val oos = new ObjectOutputStream(fos)  
  oos.writeObject(model)  
  oos.close
  index = index +1;
       scala.tools.nsc.io.File("Risultati_USD_JPY_MarketOrOutOFMArket").appendAll(maxDepth + "," + numTrees + "," + 
        testPer + "," + inOk + "," +
inButOut + "," +
outOk + "," + 
outButIn + "," +
dico_1 + ","+
tot_1 + ","+
dico_0 + ","+
tot_0 + ","+
impurity + ","+
cutOff + "," + index + 
"\n")

// Evaluate model on test instances and compute test error
 labelAndPreds = validationData.map { point =>
  val prediction = model.predict(point.features)
  (point.label, prediction)
}
 testPer = labelAndPreds.filter(r => r._1 == r._2).count.toDouble / labelAndPreds.count()

//println("Learned classification tree model:\n" + model.toDebugString)
 scala.tools.nsc.io.File("Risultati_USD_JPY_MarketOrOutOFMArket").appendAll("VALID_ SET \n");
 tot_1 = labelAndPreds.filter(r => r._1 == 1).count.toDouble
 tot_0 = labelAndPreds.filter(r => r._1 == 0).count.toDouble
 ok_1 = labelAndPreds.filter(r => r._1 == 1 && r._2 == 1).count.toDouble
 dico_1 = labelAndPreds.filter(r => r._2 == 1).count.toDouble
 ok_2 = labelAndPreds.filter(r => r._1 == 2 && r._2 == 2).count.toDouble
 dico_2 = labelAndPreds.filter(r => r._2 == 2).count.toDouble
 ok_0 = labelAndPreds.filter(r => r._1 == 0 && r._2 == 0).count.toDouble
 dico_0 = labelAndPreds.filter(r => r._2 == 0).count.toDouble
 inButOut = labelAndPreds.filter(r => r._1 == 0 && r._2 == 1).count.toDouble/dico_1
 inOk = labelAndPreds.filter(r => r._1 == 1 && r._2 == 1).count.toDouble/dico_1
 outButIn = labelAndPreds.filter(r => r._1 == 1 && r._2 == 0).count.toDouble/dico_0
 outOk = labelAndPreds.filter(r => r._1 == 0 && r._2 == 0).count.toDouble/dico_0

 trainPriorProbabilities = classProbabilities(trainingData)
 testPrior = classProbabilities(testData)
 random = trainPriorProbabilities.zip(testPrior).map {
                        case(trainProb, testProb) => trainProb*testProb
                      }.sum 
println("Accuracy Random Classifier = " + random )
println("Test performance Totale = " + testPer)
scala.tools.nsc.io.File("Risultati_USD_JPY_MarketOrOutOFMArket").appendAll(maxDepth + "," + numTrees + "," + 
        testPer + "," + inOk + "," +
inButOut + "," +
outOk + "," + 
outButIn + "," +
dico_1 + ","+
tot_1 + ","+
dico_0 + ","+
tot_0 + ","+
impurity + ","+
cutOff + "," + index + 
"\n")
       
}

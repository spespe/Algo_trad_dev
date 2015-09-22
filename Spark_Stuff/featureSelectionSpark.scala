import org.apache.spark.SparkContext
import org.apache.spark.mllib.tree.DecisionTree
import org.apache.spark.mllib.regression.LabeledPoint
import org.apache.spark.mllib.linalg.Vectors
import org.apache.spark.mllib.tree.configuration.Algo._
import org.apache.spark.mllib.tree.impurity.Gini
import org.apache.spark.mllib.tree.DecisionTree
import org.apache.spark.mllib.util.MLUtils
import org.apache.spark.mllib.classification.NaiveBayes
import java.io.FileOutputStream
import java.io.ObjectOutputStream
import org.apache.spark.mllib.tree.RandomForest
import org.apache.spark.mllib.tree.model.RandomForestModel
import org.apache.spark.mllib.util.MLUtils
import java.io.FileInputStream
import java.io.ObjectInputStream
import java.io._

val data = sc.textFile("/user/hdfs/config/USDJPY-2015-08.csv_30_model")
data.cache 
val fos = new FileInputStream("modelli/3_segniVecchi")
val oos = new ObjectInputStream(fos)
val newModel = oos.readObject().asInstanceOf[org.apache.spark.mllib.tree.model.RandomForestModel]
var model: org.apache.spark.mllib.tree.model.RandomForestModel = null 
model = newModel

//  2 -> 2, 3 -> 2, 4 -> 2, 5-> 2, 6->2 ,7->2, 8->2,9->2
val lenFeatures = data.first.split(",").tail.length

for( features <- (-1 to 3) )
yield{		    
			val parsedData = data.map { line =>
			  val parts = line.split(',').map(_.toDouble)  			  
			  (features) match {
    			case -1 => println("CIAO");
    			case 0 => parts(1) = parts(1) + 4; //0-> 24
    			case 1 => parts(2) = (parts(2) +1 ) % 2 //
    			case _ => parts(features +1) = parts(features +1) + parts(features+1)*0.15
  			}
			  LabeledPoint(parts(0), Vectors.dense( Array(parts(1),parts(2),parts(3), parts(4) )))
			}

			val labelAndPreds = parsedData.map{point => 
			  val prediction = model.predict(point.features)
			  (point.label, prediction)
			}
			val testPer = labelAndPreds.filter(r => r._1 == r._2).count.toDouble / parsedData.count()
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
			val sellSignalsButBuy = labelAndPreds.filter(r => r._1 == 2 && r._2 == 1).count.toDouble/dico_1
			val sellSignalsOk = labelAndPreds.filter(r => r._1 == 1 && r._2 == 1).count.toDouble/dico_1
			val sellSignalButOut = labelAndPreds.filter(r => r._1 == 0 && r._2 == 1).count.toDouble/dico_1

			val BuySignalsButSell = labelAndPreds.filter(r => r._1 == 1 && r._2 == 2).count.toDouble/dico_2
			val BuySignalsButOut = labelAndPreds.filter(r => r._1 == 0 && r._2 == 2).count.toDouble/dico_2
			val BuySignalsOk = labelAndPreds.filter(r => r._1 == 2 && r._2 == 2).count.toDouble/dico_2

			val outSignalsOk = labelAndPreds.filter(r => r._1 == 0 && r._2 == 0).count.toDouble/dico_0

			val myMetrics = sellSignalsOk * dico_1 - sellSignalsButBuy * dico_1 + BuySignalsOk * dico_2 - BuySignalsButSell*dico_2

			println("Test performance Totale = " + testPer)
			sellSignalsButBuy 
			sellSignalsOk 
			sellSignalButOut
			BuySignalsButSell 
			BuySignalsButOut 
			BuySignalsOk 
			outSignalsOk 

			scala.tools.nsc.io.File("Risultati_USD_JPY_NOISE").appendAll( testPer + "," + sellSignalsButBuy + "," +
sellSignalsOk  + "," + sellSignalButOut + "," +
BuySignalsButSell + "," +
BuySignalsButOut + "," +
BuySignalsOk + "," +
outSignalsOk  + "," +
dico_1 + ","+
tot_1 + ","+
dico_0 + ","+
tot_0 + ","+
dico_2 + ","+
tot_2 + ","+ myMetrics + "," +
features + 
"\n")
}


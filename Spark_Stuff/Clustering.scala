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
import org.apache.spark.mllib.clustering.KMeans
import org.apache.spark.mllib.linalg.Vectors



//val trainingData = parsedData
//val testData = tdata.map { line =>
//  val parts = line.split(',').map(_.toDouble)
//  LabeledPoint(parts(0), Vectors.dense(parts.tail))
//}

//  Empty categoricalFeaturesInfo indicates all features are continuous.

val data_ = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-01.csv_5_model")
val tdata = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-02.csv_5_model")
val marzo = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-03.csv_5_model")
val luglio= sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-07.csv_5_model")
val aprile = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-04.csv_5_model")
val maggio = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-05.csv_5_model")
val giugno = sc.textFile("hdfs:///user/hdfs/config/USDJPY-2015-06.csv_5_model")
val data = data_.union(tdata).union(marzo).union(aprile).union(maggio).union(giugno).union(luglio)

val parsedData = data.map { line =>
  val parts = line.split(',').map(_.toDouble)
  (parts(0), Vectors.dense(parts.tail))
}
val dataToClustering = parsedData.values.cache() 

val numClusters = 5
val numIterations = 200000000
val model = KMeans.train(dataToClustering, numClusters, numIterations)

val clusterLabelCount = parsedData.map {
                case( label, datum ) =>
                  val cluster = model.predict(datum)
                  (cluster, label)
}.countByValue

clusterLabelCount.toSeq.sorted.foreach {
    case((cluster, label), count) =>
      println("Cluster " + cluster + " Label " + label + " count " + count )
}

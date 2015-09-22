
start=8
for i in `seq 1 8`;
    do
          echo "Sostituisco $start in $i"
          sed -i "s/2015-0$start/2015-0$i/g" parseForModel_2.scala
          scalac parseForModel_2.scala 
          scala parseForModel
          start=$i
    done
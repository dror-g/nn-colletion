#for e in 7 1033
function forki {

echo "wak $e"
if [ $e -eq $1 ]
then
continue
fi
#aw="$e"
#e=$2

i=0
diff=0
#while [ $i -le 10 ]
#while  (($diff < 98)) 
#while [ $(echo "$diff < 98"|bc) ]
while [ $(echo "$diff < 60"|bc) ]
do
bigg=`echo "$diff < 60"|bc`
if [ $bigg -eq 0 ]
then 
break
 fi
#ruby save_mlp.rb > /dev/null
#ruby save_mlp.rb $1 $2 
ruby save_mlp.rb $1 $e > /dev/null 
a8=`ruby check-bad.rb $1 $e|grep "\[0\]"|cut -d" " -f4|tr -d "\[,\]"` 
#echo "$e: $a8"
#a7=`ruby load_mlp.good.rb|grep "\[0\]"|cut -d" " -f4|tr -d "\[,\]"`
a7=`ruby check-good.rb $1 $e|grep "\[0\]"|cut -d" " -f4|tr -d "\[,\]"`
#echo "$1: $a7"
diff=`echo "100*($a7-$a8)"|bc`
echo $diff
i=$((i+1))
done
}

for e in `mysql -p seal --skip-column-names --batch -pqrstrL1$ -e "select D from train group by D"`
do
forki $1 $e & 
if [ $? -ne 0 ]
then 
exit 1
fi 
done



i=0
diff=0
#while [ $i -le 10 ]
#while  (($diff < 98)) 
#while [ $(echo "$diff < 98"|bc) ]
while [ $(echo "$diff < 98"|bc) ]
do
bigg=`echo "$diff < 98"|bc`
if [ $bigg -eq 0 ]
then 
break
 fi
ruby save_mlp.rb > /dev/null
a8=`ruby load_mlp.rb|grep "\[0\]"|cut -d" " -f4|tr -d "\[,\]"`
echo "8: $a8"
a7=`ruby load_mlp.good.rb|grep "\[0\]"|cut -d" " -f4|tr -d "\[,\]"`
echo "7: $a7"
diff=`echo "100*($a7-$a8)"|bc`
echo $diff
i=$((i+1))
done




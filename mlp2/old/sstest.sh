#for e in 7 1033

#echo "wak $e"
#aw="$e"
#e=$2

function forki() {
#echo "starting over!!!"
i=0
diff=0
#while [ $i -le 10 ]
#while  (($diff < 98)) 
#while [ $(echo "$diff < 98"|bc) ]
#while [ $(echo "$diff < 60"|bc) ]
#do
#bigg=`echo "$diff < 60"|bc`
#if [ $bigg -eq 0 ]
#then 
#break
# fi
#ruby save_mlp.rb > /dev/null
#ruby save_mlp.rb $1 $2 
ruby save_1vall.rb $1 > /dev/null 
for e in `mysql -p seal --skip-column-names --batch -pqrstrL1$ -e "select D from train group by D limit 10"`
do
a8=`ruby check-good_test.rb 7 $e|grep "\[0\]"|cut -d" " -f4|tr -d "\[,\]"` 
if [ $e -eq $1 ]
then
#bigger=`echo "$a8 > 0.7"|bc`
bigger=`echo "$a8 > 0.015"|bc`
#if [ $a8 -eq "0.8" ]
if [ $bigger = 1 ]
then
#echo "$a8 bigger $bigger"
#break
continue
else
echo "$a8 not big enough at $e"
forki $1
fi
else
smaller=`echo "$a8 < 0.0015"|bc`
#if [ $a8 -le "0.05" ]
if [ $smaller = 1 ]
then
#echo "$a8 smaller $smaller"
#break
continue
else
echo "$a8 not small enough at $e"
forki $1
fi
fi

done
}
#echo "$e: $a8"
#a7=`ruby load_mlp.good.rb|grep "\[0\]"|cut -d" " -f4|tr -d "\[,\]"`
#a7=`ruby new_check-good.rb $e|grep "\[0\]"|cut -d" " -f4|tr -d "\[,\]"`
#echo "$1: $a7"
#diff=`echo "100*($a7-$a8)"|bc`
#echo $diff
#i=$((i+1))
#done
#}

forki $1 #$e 
#done



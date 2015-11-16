long=()
while read line
do
if [ `echo $line | wc -w`  -lt '30' ]
then 
short=$line
else
#echo `cat /dev/urandom| tr -dc 0-9 |  head -c 14| sed 's/\(.\{1\}\)/\1 /g'`
long+=("$line")
if [ ${#long[@]} -gt 15 ]
then
echo $short
echo "${long[0]} ${long[1]} ${long[2]} ${long[3]} ${long[4]} ${long[5]} ${long[6]} ${long[7]} ${long[8]} ${long[9]} ${long[10]} ${long[11]} ${long[12]} ${long[13]} ${long[14]} ${long[15]}"
long=()
fi
fi
#done < reverse-5K-splt39output3.txt
done < reverse-5K.txt

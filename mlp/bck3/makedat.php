<?
error_reporting(0);



		$count=0;

$db=mysqli_connect("localhost","root","qrstrL1$","seal");
$master = mysqli_query($db, "select D from train group by D");
while($masterrow = mysqli_fetch_array($master))
{
	#file_put_contents("data/true.dat","");
	#file_put_contents("data/false.dat","");
	file_put_contents("data/train.tmp","");
#$db=mysqli_connect("localhost","root","qrstrL1$","seal");
$db1=mysqli_connect("localhost","root","qrstrL1$","seal");
$result = mysqli_query($db1, "select D from train group by D");
while($row = mysqli_fetch_array($result))
	{
	if($row['D'] == $masterrow['D']){
	$db2=mysqli_connect("localhost","root","qrstrL1$","seal");
	$res = mysqli_query($db, "select X,Y,Z from train where D = $row[D] limit 300");
	}else{	
	$db2=mysqli_connect("localhost","root","qrstrL1$","seal");
	$res = mysqli_query($db2, "select X,Y,Z from train where D = $row[D] limit 9");
	}
		$data=array();
		#$count=0;
#			echo "insert out $count\n"; 
		while($re = mysqli_fetch_array($res, MYSQLI_NUM))
		{
		#while($re = mysqli_fetch_row($res))
		#while($count <= 2) { 
			#$data['0']=$data['0'] . " " . implode(' ',$re);
			#echo $data['0'];
			#}
	#		echo "insert row $count\n"; 
			foreach ($re as &$ro) {
			$ro=$ro/100;
			}
			#$data['0'].=implode(' ',$re) . " ";
			#$data['0']=implode(',',$re) . ",";
			$data['0']=implode(',',$re);
			#file_put_contents("data/train.tmp",$data['0'] . ",",FILE_APPEND);
			file_put_contents("data/train.tmp",$data['0'] . ",",FILE_APPEND);
			$count++;

			if($count == '3') {
			if($row['D'] == $masterrow['D']){
			#file_put_contents("data/true.dat",$data['0'] . "\n",FILE_APPEND);
			file_put_contents("data/train.tmp","1\n",FILE_APPEND);
			}else{	
			file_put_contents("data/train.tmp","0\n",FILE_APPEND);
			#file_put_contents("data/false.dat",$data['0'] . "\n",FILE_APPEND);
			}
			$count=0;
			unset($data);
			}
		}
	#$data=explode(" ",$data[0]);
	#array_shift($data);
	#echo $data['0'];
	#$out=train($data,$row['D']);
	#if ($out[0] > '0') 
	#die;	
	#}
	}
	$out=train($masterrow['D']);
	echo "\n" . $masterrow['D'] . " is trained $out\n";
die;
}
mysqli_close($db);
?>

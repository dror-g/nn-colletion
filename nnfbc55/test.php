<?php

function bchexdec($hex)
{
	    $len = strlen($hex);
	        for ($i = 1; $i <= $len; $i++)
	        $dec = bcadd($dec, bcmul(strval(hexdec($hex[$i - 1])), bcpow('16', strval($len - $i))));
   
	    return $dec;
}

#$block = "000000000000000046c6a2cfbf9e5b822270edcd91ab9a2af0a13e7af3037895"; #trained
$block = "0000000000000001b809a28c51a8fa24e3baab2233641317a2e95cfbe213861d"; #2 new, 1 trained
#$block = "000000000000000155f35aeb2ded0158bf037bd30e846a8c5cd6ee0ec2152b5f"; #unseen
for ($i = 1; $i <= 3; $i++) {
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, "http://blockexplorer.com/rawblock/$block");
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

	#$data = json_decode(file_get_contents("http://blockexplorer.com/rawblock/$block"));
	$data = json_decode(curl_exec($ch));
	$block = "$data->prev_block";
	
	$data->prev_block = bchexdec($data->prev_block); 
	$data->prev_block = chunk_split($data->prev_block, 1, " "); 
	#$data->prev_block = hexdec($data->prev_block); 
	$data->mrkl_root = bchexdec($data->mrkl_root); 
	$data->mrkl_root = chunk_split($data->mrkl_root, 1, " "); 
	
	/*$prev_str = strlen($data->prev_block);
	if($prev_str == 116) $data->prev_block = "0 " . $data->prev_block;
	$mrkl_str = strlen($data->mrkl_root);
	if($mrkl_str == 154) $data->mrkl_root = "0 " . $data->mrkl_root;*/

	while(strlen($data->prev_block) < 118) $data->prev_block = "0 " . $data->prev_block;
	while(strlen($data->mrkl_root) < 156) $data->mrkl_root = "0 " . $data->mrkl_root;

	#$data->time = bchexdec($data->time); 
	#if(strlen($data->time) < 10)
	#	$data->time = 0 . $data->time; 
	$data->time = chunk_split($data->time, 1, " "); 

	#$data->bits = bchexdec($data->bits); 
	#if(strlen($data->bits) < 10)
	#	$data->bits = 0 . $data->bits; 
	$data->bits = chunk_split($data->bits, 1, " "); 

	#$data->nonce = bchexdec($data->nonce); 
	if(strlen($data->nonce) < 10)
		$data->nonce = 0 . $data->nonce; 
	$data->nonce = chunk_split($data->nonce, 1, " "); 

	$prev_str = strlen($data->prev_block);
	$mrkl_str = strlen($data->mrkl_root);
	
	#$sum = $data->prev_block . $data->mrkl_root . $data->time . $data->bits;
	#echo strlen($sum);
	#die;

	#echo "$data->prev_block$data->mrkl_root$data->time$data->bits\n";
	$totest=$data->prev_block . $data->mrkl_root . $data->time . $data->bits;
	$test=explode(" ", $totest);
	array_unshift($test,"");
	unset($test[0]);
	unset($test[157]);
	#print_r($test);
	for($e=1;$e<157;$e++) $test[$e] = $test[$e] / 10;
	#print_r($test);
	#echo "$data->prev_block |$prev_str|$mrkl_str| $data->mrkl_root | $data->time | $data->bits\n";
	#echo "$data->prev_block | $data->mrkl_root | $data->time | $data->bits\n";
	echo "requied: $data->nonce\n";
	if($prev_str != 118 || $mrkl_str != 156) die;

#}
	$train = fann_read_train_from_file("5K.txt");
	#$ann = fann_create_from_file("xor_float.net");
	$ann = fann_create_from_file("cascade_train2.net");
	fann_set_input_scaling_params($ann, $train , -1, 1);
	fann_scale_input($ann, $test);
	$out = fann_run($ann, $test);
	fann_set_output_scaling_params($ann, $train , -1, 1);
	fann_descale_output($ann, $out);
	print_r($out);
echo "SUCESS!";
}
?>



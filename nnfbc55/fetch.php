<?php

function bchexdec($hex)
{
	    $len = strlen($hex);
	        for ($i = 1; $i <= $len; $i++)
	        $dec = bcadd($dec, bcmul(strval(hexdec($hex[$i - 1])), bcpow('16', strval($len - $i))));
   
	    return $dec;
}

$block = "0000000000000001b8a1691057cd6639e56224d99f7f7d80e7b61f55be52d931"; 
#$block = "000000000000000046c6a2cfbf9e5b822270edcd91ab9a2af0a13e7af3037895"; #orig
for ($i = 1; $i <= 5000; $i++) {
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
	while(strlen($data->nonce) < 10) $data->nonce = 0 . $data->nonce; 
	$data->nonce = chunk_split($data->nonce, 1, " "); 

	$prev_str = strlen($data->prev_block);
	$mrkl_str = strlen($data->mrkl_root);
	
	#$sum = $data->prev_block . $data->mrkl_root . $data->time . $data->bits;
	#echo strlen($sum);
	#die;

	echo "$data->prev_block$data->mrkl_root$data->time$data->bits\n";
	#echo "$data->prev_block |$prev_str|$mrkl_str| $data->mrkl_root | $data->time | $data->bits\n";
	#echo "$data->prev_block | $data->mrkl_root | $data->time | $data->bits\n";
	echo "$data->nonce\n";
	if($prev_str != 118 || $mrkl_str != 156) die;

}
echo "SUCESS!";
?>



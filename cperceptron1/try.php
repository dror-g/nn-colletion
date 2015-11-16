<?php
include 'cperceptron.php';

$error='0.1';
$iter='1000';
$vel='0.7';

$trainIn = array(
    array(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
    array(1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1));

$trainOut = array(
#    array(1,1,1),
#    array(1,-1,1));
    array(1),
    array(-1));

$cp = new cperceptron();
$w = $cp->trainPS($trainIn, $trainOut, $error, $iter, $vel);

$test = $cp->matrix2Vector($trainIn, 1);
$res = $cp->prodMatrix($test, $w);
$out = $cp->signMatrix($res);
print_r($out);

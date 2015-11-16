<?php

##$ann = fann_create_sparse(0.4, 6, 13, 50, 30, 10, 10, 2);
##$ann = fann_create_sparse(0.4, 5, 12, 30, 10, 10, 1);

#$ann = fann_create_shortcut(2, 12, 2);


##$ann = fann_create_standard(3, 12, 6, 2);



#$data = fann_read_train_from_file("50K_formatted.txt");
#$data = fann_read_train_from_file("merged.txt2");
#$data = fann_read_train_from_file("affmat_part");
#$data = fann_read_train_from_file("affmat_few");
$data = fann_read_train_from_file("1000.txt");
fann_scale_input_train_data($data, 0, 0.9);
fann_scale_output_train_data($data, 0, 0.9);
##echo fann_num_input_train_data($data);
##echo fann_num_output_train_data($data);

$ann = fann_create_shortcut(2, fann_num_input_train_data($data), fann_num_output_train_data($data));
#$ann = fann_create_standard(6, fann_num_input_train_data($data),56,26, 32, 12, fann_num_output_train_data($data));
#$ann = fann_create_sparse(0.7, 3, fann_num_input_train_data($data),56, fann_num_output_train_data($data));
fann_init_weights($ann, $data);
#fann_set_training_algorithm($ann, FANN_TRAIN_INCREMENTAL);
#fann_set_training_algorithm($ann, FANN_TRAIN_QUICKPROP);
#fann_set_learning_rate($ann, 0.5);
fann_reset_MSE($ann);
fann_test_data($ann, $data);
#fann_set_cascade_output_stagnation_epochs($ann, 420);
#fann_set_cascade_candidate_change_fraction($ann, 8);
#fann_set_cascade_candidate_stagnation_epochs($ann, 120);
#fann_set_cascade_candidate_limit($ann, 10000.0);
##fann_set_cascade_max_out_epochs($ann,100);
##fann_set_cascade_max_cand_epochs($ann, 100);
##fann_set_cascade_num_candidate_groups($ann, 20);
#fann_set_callback($ann, 'erco');

#fann_train_on_data($ann, $data, 200, 10, 0.001) or die;
fann_cascadetrain_on_data($ann, $data, 1000, 10, 0.01); #nice! 
#fann_cascadetrain_on_data($ann, $data, 100, 100, 0.00001);  

echo "done";
#$arr =  fann_get_cascade_num_candidates($ann);
#print_r($ee);

fann_save($ann, "trained_100.net");
fann_destroy($ann);

?>

/*
  Fast Artificial Neural Network Library (fann)
  Copyright (C) 2003 Steffen Nissen (lukesky@diku.dk)
  
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.
  
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.
  
  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <stdio.h>

#include "fann.h"


int main()
{
	struct fann *ann;
	struct fann_train_data *train_data, *test_data;
	//const float desired_error = (const float)0.0;
	const float desired_error = (const float)0.1;
	unsigned int max_neurons = 100;
	unsigned int neurons_between_reports = 1;
	unsigned int bit_fail_train, bit_fail_test;
	float mse_train, mse_test;
	unsigned int i = 0;
	fann_type *output;
	fann_type steepness;
	int multi = 0;
	enum fann_activationfunc_enum activation;

	enum fann_train_enum training_algorithm = FANN_TRAIN_RPROP;
	printf("Reading data.\n");

	 
	train_data = fann_read_train_from_file("reverse-5K-10-624.txt");
	test_data = fann_read_train_from_file("reverse-5K-10-624.txt");

	//fann_scale_train_data(train_data, -1, 1);
	//fann_scale_train_data(test_data, -1, 1);
	//fann_scale_train_data(train_data, 0, 1);
	//fann_scale_train_data(test_data, 0, 1);
	
	printf("Creating network.\n");
	
	ann = fann_create_shortcut(2, fann_num_input_train_data(train_data), fann_num_output_train_data(train_data));
	//ann = fann_create_standard(4, fann_num_input_train_data(train_data), 24, 68, fann_num_output_train_data(train_data));
		
	//fann_set_cascade_activation_functions(ann, &activation, 1);		
	fann_set_training_algorithm(ann, training_algorithm);
	//fann_set_activation_function_hidden(ann, FANN_SIGMOID_SYMMETRIC);
	//fann_set_activation_function_hidden(ann, FANN_SIGMOID);
	fann_set_activation_function_output(ann, FANN_LINEAR);
	fann_set_train_error_function(ann, FANN_ERRORFUNC_LINEAR);
	fann_set_cascade_max_cand_epochs(ann, 1000);
	//	fann_set_learning_rate(ann, 0.9);
	//fann_set_cascade_weight_multiplier(ann, 4);
	//fann_set_cascade_candidate_limit(ann, 10);
	//fann_set_cascade_activation_functions(ann, FANN_SIGMOID, FANN_SIGMOID_SYMMETRIC, FANN_GAUSSIAN, FANN_GAUSSIAN_SYMMETRIC, FANN_ELLIOT, FANN_ELLIOT_SYMMETRIC, 6)
		fann_randomize_weights(ann, -9.0,9.0);
	
	if(!multi)
	{
		/*steepness = 0.5;*/
		steepness = 1;
		fann_set_cascade_activation_steepnesses(ann, &steepness, 1);
		//fann_set_cascade_candidate_stagnation_epochs(ann, 12);
		/*activation = FANN_SIN_SYMMETRIC;*/
		//activation = FANN_SIGMOID_SYMMETRIC;
		//activation = FANN_SIGMOID;
		
		//fann_set_cascade_activation_functions(ann, &activation, 1);		
		fann_set_cascade_num_candidate_groups(ann, 8);
	}	
		
	if(training_algorithm == FANN_TRAIN_QUICKPROP)
	{
		fann_set_learning_rate(ann, 0.35);
		//fann_randomize_weights(ann, -2.0,2.0);
		//fann_randomize_weights(ann, -9.0,9.0);
		fann_randomize_weights(ann, 0,9.0);
		//fann_randomize_weights(ann, 0.0,2.0);
	}
	
		activation = FANN_SIGMOID_SYMMETRIC;
		fann_set_cascade_activation_functions(ann, &activation, 1);		
	fann_set_bit_fail_limit(ann, 0.9);
	//fann_set_train_stop_function(ann, FANN_STOPFUNC_BIT);
	fann_set_train_stop_function(ann, FANN_STOPFUNC_MSE);
	fann_print_parameters(ann);
		
	fann_save(ann, "cascade_comp10-624.net");
	
	printf("Training network.\n");

	//fann_set_cascade_activation_steepnesses(ann, &steepness, 0.01);

	fann_cascadetrain_on_data(ann, train_data, max_neurons, neurons_between_reports, desired_error);
	//fann_train_on_data(ann, train_data, max_neurons, neurons_between_reports, desired_error);
	//fann_train_on_data(ann, train_data, 100, neurons_between_reports, desired_error);
	
	fann_print_connections(ann);
	
	mse_train = fann_test_data(ann, train_data);
	bit_fail_train = fann_get_bit_fail(ann);
	mse_test = fann_test_data(ann, test_data);
	bit_fail_test = fann_get_bit_fail(ann);
	
	printf("\nTrain error: %f, Train bit-fail: %d, Test error: %f, Test bit-fail: %d\n\n", 
		   mse_train, bit_fail_train, mse_test, bit_fail_test);
	
	for(i = 0; i < train_data->num_data; i++)
	{
		output = fann_run(ann, train_data->input[i]);
		if((train_data->output[i][0] >= 0 && output[0] <= 0) ||
		   (train_data->output[i][0] <= 0 && output[0] >= 0))
		{
	//		printf("ERROR: %f does not match %f\n", train_data->output[i][0], output[0]);
		}
	}
	
	printf("Saving network.\n");
	
	fann_save(ann, "cascade_comp10-624.net");
	
	printf("Cleaning up.\n");
	fann_destroy_train(train_data);
	fann_destroy_train(test_data);
	fann_destroy(ann);
	
	return 0;
}

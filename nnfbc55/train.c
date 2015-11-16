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

#include "fann.h"
//#include "doublefann.h"

int main()
{
	const unsigned int num_input = 156;
	const unsigned int num_output = 10;
	const unsigned int num_layers = 10;
	//const unsigned int num_neurons_hidden = 114,56;
	const float desired_error = (const float) 0.01;
	const unsigned int max_epochs = 1000;
	const unsigned int epochs_between_reports = 50;

	enum fann_activationfunc_enum activation;

	struct fann_train_data * data = NULL;
	//struct fann *ann = fann_create_standard(num_layers, num_input, num_neurons_hidden, num_output);
	//struct fann *ann = fann_create_standard(10, num_input, 32, 32, 32, 32, 32, 32, 32, num_output);
	//struct fann *ann = fann_create_standard(3, num_input, 12, num_output);
	//struct fann *ann = fann_create_sparse(0.4, 7, num_input, 12, 12, 12, 12, 12, num_output);
	struct fann *ann = fann_create_shortcut(2, num_input, num_output);
	//struct fann *ann = fann_create_sparse(0.4, num_layers, num_input, 114, 56, num_output);

	data = fann_read_train_from_file("5K.txt");

        fann_set_scaling_params(
                    ann,
                        data,
                        0,     /* New input minimum */
                        1,      /* New input maximum */
                        0,     /* New output minimum */
                        1);     /* New output maximum */

	fann_scale_train( ann, data );
	fann_shuffle_train_data(data);
	fann_init_weights(ann, data);

/*fann_set_cascade_output_stagnation_epochs(ann, 12);
fann_set_cascade_output_change_fraction(ann, 0.01);
fann_set_cascade_candidate_change_fraction(ann, 0.01);
fann_set_cascade_candidate_stagnation_epochs(ann, 12);
fann_set_cascade_candidate_limit(ann, 1000.0);
fann_set_cascade_max_out_epochs(ann,100);
fann_set_cascade_max_cand_epochs(ann, 100);
fann_set_cascade_num_candidate_groups(ann, 2);*/
fann_set_cascade_output_stagnation_epochs(ann, 4);
fann_set_cascade_output_change_fraction(ann, 0.01);
fann_set_cascade_candidate_change_fraction(ann, 0.01);
fann_set_cascade_candidate_stagnation_epochs(ann, 4);
fann_set_cascade_candidate_limit(ann, 100.0);
fann_set_cascade_max_out_epochs(ann,100);
fann_set_cascade_max_cand_epochs(ann, 100);
fann_set_cascade_num_candidate_groups(ann, 2);
//activation = FANN_SIGMOID_SYMMETRIC;
activation = FANN_ELLIOT;
fann_set_cascade_activation_functions(ann, &activation, 1); 

	//fann_set_training_algorithm(ann, FANN_TRAIN_INCREMENTAL);
	//fann_set_training_algorithm(ann, FANN_TRAIN_QUICKPROP);
	//fann_set_training_algorithm(ann, FANN_TRAIN_BATCH);
	//fann_set_activation_function_hidden(ann, FANN_ELLIOT);
	//fann_set_activation_function_output(ann, FANN_ELLIOT);
	//fann_set_train_error_function(ann, FANN_ERRORFUNC_TANH);
	//fann_set_train_stop_function(ann, FANN_STOPFUNC_BIT);
	fann_set_learning_rate(ann, 0.025);
	fann_reset_MSE(ann);

	//fann_train_on_file(ann, "5K.txt", max_epochs, epochs_between_reports, desired_error);
	//fann_train_on_data(ann, data, max_epochs, epochs_between_reports, desired_error);
	fann_cascadetrain_on_data(ann, data, 100, epochs_between_reports, desired_error);

	fann_save(ann, "xor_float.net");

	fann_destroy(ann);

	return 0;
}

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

int main()
{
	const unsigned int num_input = 156;
	const unsigned int num_output = 10;
	const unsigned int num_layers = 4;
	//const unsigned int num_neurons_hidden = 114,56;
	const float desired_error = (const float) 0.01;
	const unsigned int max_epochs = 2000;
	const unsigned int epochs_between_reports = 50;

	struct fann_train_data * data = NULL;
	//struct fann *ann = fann_create_standard(num_layers, num_input, num_neurons_hidden, num_output);
	//struct fann *ann = fann_create_standard(num_layers, num_input, 114, 56, num_output);
	//struct fann *ann = fann_create_shortcut(2, num_input, num_output);
	struct fann *ann = fann_create_gng(2, num_input);

	data = fann_read_train_from_file("5K.txt");

        fann_set_scaling_params(
                    ann,
                        data,
                        0,     /* New input minimum */
                        0.9,      /* New input maximum */
                        0,     /* New output minimum */
                        0.9);     /* New output maximum */

	fann_init_weights(ann, data);
	//fann_set_training_algorithm(ann, FANN_TRAIN_INCREMENTAL);
	fann_set_activation_function_hidden(ann, FANN_ELLIOT);
	fann_set_activation_function_output(ann, FANN_ELLIOT);
	fann_set_train_error_function(ann, FANN_ERRORFUNC_TANH);
	fann_set_learning_rate(ann, 0.7);
	fann_reset_MSE(ann);

	//fann_train_on_file(ann, "5K.txt", max_epochs, epochs_between_reports, desired_error);
	//fann_train_on_data(ann, data, max_epochs, epochs_between_reports, desired_error);
	fann_cascadetrain_on_data(ann, data, max_epochs, epochs_between_reports, desired_error);

	fann_save(ann, "xor_float.net");

	fann_destroy(ann);

	return 0;
}

#include <stdio.h>
#include "fann.h"

int main( int argc, char** argv )
{
	fann_type *calc_out;
//	float calc_out[10];
	unsigned int i;
	int ret = 0;
	struct fann *ann;
	struct fann_train_data *data;
	printf("Creating network.\n");
	ann = fann_create_from_file("cascade_train.net");
	if(!ann)
	{
		printf("Error creating ann --- ABORTING.\n");
		return 0;
	}
	//fann_print_connections(ann);
	//fann_print_parameters(ann);
	printf("Testing network.\n");
	data = fann_read_train_from_file("3.txt");
	//fann_scale_train_data(data, -1, 1);
	//fann_scale_train_data(data, -9, 9);
		//	printf("data1: %f\n", data->input[0][0]);
		//	printf("data2: %f\n", data->input[1][0]);
		//	printf("data3: %f\n", data->input[2][0]);

	for(i = 0; i < fann_length_train_data(data); i++)
	{
		fann_reset_MSE(ann);

//			fann_set_input_scaling_params(ann, data , -1, 1);
			//printf("data-pre: %f\n", data->input[i][0]);
//			fann_scale_input( ann, data->input[i] );
			//printf("data-post: %f\n", data->input[i][4]);
			//fann_descale_input( ann, data->input[i] );
			//printf("data-post2: %f\n", data->input[i][0]);
			calc_out = fann_run( ann, data->input[i] );
			fann_set_output_scaling_params(ann, data , 0, 9);
			//fann_descale_output( ann, calc_out );
		printf("Result %f original %f error %f\n",
			calc_out[0], data->output[i][0],
			(float) fann_abs(calc_out[0] - data->output[i][0]));
	}
	printf("Cleaning up.\n");
	fann_destroy_train(data);
	fann_destroy(ann);
	return ret;
}

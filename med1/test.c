/* 

 test.c 

 Experimental program run a data file of unknown images 

through a trained ANN (created by train.c) and determine 

if the images are ham or spam. 

 Note that the data file must be in the same format

as the data file used to create the ANN. 

 Author: Jason Bowling 

*/ 

#include <stdio.h> 

#include "fann.h" 

int main() 

{ 

 fann_type *calc_out; 

 unsigned int i; 

 float sum;

 int ret = 0; 

 struct fann *ann; 

 struct fann_train_data *data; 

 ann = fann_create_from_file("image_spam.net"); 

 if(!ann) 

 { 

 printf("Error creating ann --- ABORTING.\n"); 

 return 0; 

 } 

 data = fann_read_train_from_file("test.data"); 

 for(i = 0; i < fann_length_train_data(data); i++) 

 { 

 fann_reset_MSE(ann); 

 calc_out = fann_test(ann, data->input[i], data->output[i]); 

 printf("%f, should be %f, difference=%f\n", 

 calc_out[0], data->output[i][0], 

 (float) fann_abs(calc_out[0] - data->output[i][0])); 

 //sum = sum + (float) fann_abs(calc_out[0] - data->output[i][0]);
 if( (float) fann_abs(calc_out[0] - data->output[i][0]) > 1.5)
 {
	sum++;
 }
 } 
 //printf("average %f\n", sum / fann_length_train_data(data));
 printf("errors %f\n", sum );

 fann_destroy_train(data); 

 fann_destroy(ann); 

 return ret; 

} 

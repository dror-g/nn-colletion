/* 

 train.c 

 Experimental program to take a 

 FANN-formatted training file 

 and create an ANN. 

 Author: Jason Bowling 

*/ 

#include <stdio.h> 

#include "fann.h" 

int main() 

{ 

 fann_type *calc_out; 

 const unsigned int num_input = 22500; 

 const unsigned int num_output = 1; 

 //const unsigned int num_layers = 4; 
 const unsigned int num_layers = 4; 

 /* this value can be changed to tweak the network */ 

 const unsigned int num_neurons_hidden = 50; 
 //const unsigned int num_neurons_hidden = 150; 

const float desired_error = (const float) 0.02; 

 const unsigned int max_epochs = 15000; 
const unsigned int epochs_between_reports = 20; 

 float learning_rate = .5; 

 struct fann *ann; 

 struct fann_train_data *data; 

 int num_neurons = 0; 

 unsigned int i = 0; 

 unsigned int decimal_point; 

 /* CREATING NETWORK */ 

ann = fann_create_standard(num_layers, num_input, 

 num_neurons_hidden, 

 num_neurons_hidden, num_output); 

 /* reading training data */ 

 data = fann_read_train_from_file("training.data");

 fann_set_activation_steepness_hidden(ann, 1); 

 fann_set_activation_steepness_output(ann, 1); 

 fann_set_activation_function_hidden(ann, FANN_SIGMOID_SYMMETRIC); 

 fann_set_activation_function_output(ann, FANN_SIGMOID_SYMMETRIC); 

 fann_init_weights(ann, data); 

 /* 

 TRAINING NETWORK 

 run x epochs at learn rate .y 

 */ 

 //fann_set_learning_rate(ann, .7); 

 //fann_train_on_data(ann, data, 200, epochs_between_reports, .4); 
 //fann_train_on_data(ann, data, 500, epochs_between_reports, .002); 

 fann_set_learning_rate(ann, .5); 

 fann_train_on_data(ann, data,5000, epochs_between_reports, .2); 
 //fann_train_on_data(ann, data,50, epochs_between_reports, .2); 

 fann_set_learning_rate(ann, .2); 

 fann_train_on_data(ann, data,1000, epochs_between_reports, .15); 
 //fann_train_on_data(ann, data,100, epochs_between_reports, .15); 

 fann_set_learning_rate(ann, .1); 

 fann_train_on_data(ann, data,5000, epochs_between_reports, .002); 
 //fann_train_on_data(ann, data,200, epochs_between_reports, .00002); 

 /* TESTING NETWORK */ 

 printf("Testing network. %f\n", fann_test_data(ann, data)); 

 for(i = 0; i < fann_length_train_data(data); i++) 

 { 

 calc_out = fann_run(ann, data->input[i]); 

 /*printf("%f, should be %f, difference=%f\n", 

 calc_out[0], data->output[i][0], 

 fann_abs(calc_out[0] - data->output[i][0])); */

 } 

 /* SAVING NETWORK */ 

 fann_save(ann, "image_spam.net"); 

 /* CLEANING UP */ 

 fann_destroy_train(data);
fann_destroy(ann); 

 return 0; 

}

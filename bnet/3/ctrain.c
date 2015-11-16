void fann_run_many(struct fann **anns, fann_type * input,
               fann_type **output, int num_anns, int num_runs)
{
    unsigned int ann_num, i;
    
    printf("Running Scalar!\n");
   
    for(ann_num = 0; ann_num < num_anns; ++ann_num) {
        unsigned int num_outputs, num_inputs;
        struct fann *ann = anns[ann_num];
        
        num_inputs = ann->num_input;
        num_outputs = ann->num_output;
        
        for(i=0; i<num_runs; ++i)
            memcpy(&(output[ann_num][num_outputs*i]),
                   fann_run(ann, &input[num_inputs*i]),
                   sizeof(fann_type)*num_outputs);
    }
}

int main(int argc, char *argv[])
{
   fann_type *input, *output;
    int i, j;
//    int num_runs = 1000000;
    int num_runs = 6;
    
   struct fann *ann = fann_create_from_file("~/fann/tests/xor_float.net");
   assert(ann != NULL);
    
    // Use this to make sure we're linking to the right header
    int chk = ann->first_layer->num_inputs;
    
    //Get net params
    int num_in = fann_get_num_input(ann);
    int num_out = fann_get_num_output(ann);
    
   printf("Inputs:%5d Outputs:%5d Total:%5d\n", ann->num_input, ann->num_output, ann->num_neurons);
    
   input = (fann_type*)calloc(num_runs*num_in, sizeof(fann_type));
   output = (fann_type*)calloc(num_runs*num_out, sizeof(fann_type));
   
    //Make a gamut of input values
    for(i=0; i<num_runs*num_in; ++i){
        float dig_frac = ((float)(i % num_in)+1.0)/((float)num_in);
        float tot_frac = ((float)i)/((float)num_runs*num_in);
        input[i] = fmodf(tot_frac, dig_frac)*2.0/dig_frac-1.0;
    }
    
   fann_run_many(&ann, input, &output, 1, num_runs);
    
    //* // Use for output comparisons
    for(i=0; i<num_runs; ++i){
        for(j=0; j<num_in; ++j){
            printf("%9f ", input[i*num_in+j]);
        }
        printf("->");
        for(j=0; j<num_out; ++j){
            printf(" %9f", output[i*num_out+j]);
        }
        printf("\n");
    }//*/
    
    return 0;
}

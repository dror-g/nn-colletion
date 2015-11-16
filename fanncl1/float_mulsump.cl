#include </home/inferno/Soft/fann/src/inc.cl>
#ifndef NC
	#define NC 4096 //Neuron count
#endif
#ifndef ML
	#define ML 2048 //Max neurons in layer
#endif
#ifndef LC
	#define LC 4 //Layer count
#endif

__kernel void fillinput(__global fann_type* input, __global fann_neuron* neuronit, __global unsigned int *bias)
{
	//if(get_global_id(0)>get_global_size(0)) return;
	//printf("Tstpoint_fillinput");
	unsigned int x = clamp((unsigned int)get_global_id(0), (unsigned int)get_global_offset(0), (unsigned int)(get_global_offset(0)+get_global_size(0)-1));
	unsigned int  tx = x - get_global_offset(0);
	neuronit[tx].value = input[x];
	neuronit[*bias].value = 1.0;
	//printf("x == %u, tx == %u, input[x] == %f, neuronit[tx].value == %f\n", x, tx, input[x], neuronit[tx].value);
}

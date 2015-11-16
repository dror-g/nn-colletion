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
__kernel void fl_summ_all_in_1_fc( __global __read_only fann_type* weights, __global unsigned int* snpl,\
									__global fann_neuron* neuronit, __global unsigned int* offsets, __global unsigned int* globalsizes)
{
	/*unsigned int off = get_global_offset(0);
	__local size_t lidx;
	if (get_local_id(0)==1){
		lidx = snpl[off];
	}
	barrier(CLK_LOCAL_MEM_FENCE);*/
	__local fann_type values[NC], tvalues[ML];
	__local fann_type* lvalues;
	__local unsigned int loffsets[LC];
	__local unsigned int lglobalsizes[LC];
	__local size_t lidx;
	event_t event[2];
	event[0] = async_work_group_copy(loffsets, offsets, LC, 0);
	event[1] = async_work_group_copy(lglobalsizes, globalsizes, LC, 0);
	wait_group_events(2, &event);
	size_t idx, j, i, l16;
	fann_type neuron_sum, max_sum, steepness, value;
	float16 neuron_sum16;
	__global fann_type* weightsl;
	__global fann_type* gvalues;
	__global float16* weightsl16 ;
	__local float16* values16;
	__global fann_neuron* neurons;
	unsigned int x, first_con, num_connections;
	//printf("Find stall 1, gid=%lu\n", get_global_id(0));
	for(size_t cnt=1; cnt<LC; cnt++){ //LC!
		idx = snpl[offsets[cnt]];//lidx;
		gvalues = &neuronit[idx].value;
		event[0] = async_work_group_strided_copy(values, gvalues, offsets[cnt]-idx, 8, 0);//new: values->tvalues
		wait_group_events(1, &event);
		//printf("Find stall 2, gid=%lu, cnt=%d, lglobalsizes[cnt]==%d, loffsets[cnt]=%d\n", get_global_id(0), cnt, lglobalsizes[cnt], loffsets[cnt]);
		if(get_global_id(0) < globalsizes[cnt]){
			//printf("Find stall 3, gid=%lu, cnt=%d\n", get_global_id(0), cnt);
			x = get_global_id(0)+offsets[cnt];
			steepness = neuronit[x].activation_steepness;
			first_con = neuronit[x].first_con;
			num_connections = neuronit[x].last_con - first_con;
			weightsl = weights+first_con;
			j=0, i = 0;
			l16 = num_connections%16;
			weightsl16 = weightsl+l16;
			values16 = values+l16;//new: values->lvalues
			neuron_sum = 0.0;
			neuron_sum16 = (float16) 0.0;
			max_sum = 150.0/steepness;
			for(i=0; i !=l16; i++)
			{
				neuron_sum = mad(weightsl[i], values[i], neuron_sum);//new: values->lvalues
			}
		//	printf("Find stall 4, gid=%lu, cnt=%d\n", get_global_id(0), cnt);
			//for(j=0; j<100; j++) if(lvalues[j]!=tvalues[j]) printf("%d-%d) %f, %f, %d, %d\n", get_global_id(0), j, lvalues[j], tvalues[j], idx, ML);
			j=0;
			for(; i < num_connections; i+=16)
			{
				neuron_sum16 = mad(weightsl16[j], values16[j], neuron_sum16);
				j++;
			}
			//printf("Find stall 5, gid=%lu, cnt=%d\n", get_global_id(0), cnt);
			neuron_sum += neuron_sum16.s0+neuron_sum16.s1+neuron_sum16.s2+neuron_sum16.s3+neuron_sum16.s4+neuron_sum16.s5+neuron_sum16.s6\
			+neuron_sum16.s7+neuron_sum16.s8+neuron_sum16.s9+neuron_sum16.sa+neuron_sum16.sb+neuron_sum16.sc+neuron_sum16.sd+neuron_sum16.se+neuron_sum16.sf;
			neuron_sum = clamp((fann_type)(neuron_sum*steepness), (fann_type)(-max_sum), (fann_type)max_sum);
			neuronit[x].sum = neuron_sum;  //Sums to sums
			barrier(CLK_LOCAL_MEM_FENCE);
		    fann_activation_switch(neuronit[x].activation_function, neuron_sum, value);
		    neuronit[x].value = select(value, (fann_type)1.0, (int)(neuronit[x].first_con == neuronit[x].last_con)); //Values to values
		}
		//printf("Find stall 6, gid=%lu, cnt=%d\n", get_global_id(0), cnt);
		/*gvalues = &neuronit[(get_local_id(0)-1)*get_local_size].value;//new
		event = async_work_group_strided_copy(gvalues, values, NC, 8, 0);//new
		wait_group_events(1, &event);//new*/
		barrier(CLK_GLOBAL_MEM_FENCE);
		//printf("Find stall 7, gid=%lu, cnt=%d\n", get_global_id(0), cnt);
	}
	//printf("Find stall 8, gid=%lu\n", get_global_id(0));
	/*gvalues = &neuronit[0].value;//new
	event = async_work_group_strided_copy(gvalues, values, NC, 8, 0);//new
	wait_group_events(1, &event);//new*/
}

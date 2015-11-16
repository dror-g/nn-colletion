//#pragma OPENCL EXTENSION cl_khr_fp64 : enable
#include </home/inferno/Soft/fann/src/inc.cl>
#define MAX_LS 112
#ifndef LC
	#define LC 2 //Layer count
#endif
#ifndef NC
	#define NC 4096 //Neuron count
#endif
__kernel void memsetcl(__global fann_type* array)
{
	//if (get_global_id(0)>8704) printf("get_global_id(0) == %d\n", get_global_id(0));
	array[get_global_id(0)] = 0;
}

/*__kernel void fl_update_slopesp( __global fann_neuron* nrn, __global fann_type* error_begin, 
	    __global fann_type* train_slopes, __global unsigned int *cs1stc)
{
		unsigned int i=0, j, k;
		unsigned int x = clamp((uint)get_global_id(0), (uint)get_global_offset(0), (uint)(get_global_offset(0)+get_global_size(0)-1));
		int im = nrn[get_global_id(0)].last_con - nrn[get_global_id(0)].first_con;
		//printf("x = %u, ls = %u, gs = %u, gid = %u, lid = %u, grid = %u, last_con = %u\n", x, get_local_size(0), get_global_size(0), get_global_id(0), get_local_id(0),  get_group_id(0), nrn[get_global_id(0)].last_con);
		
		__global fann_type* ts = train_slopes+nrn[get_global_id(0)].first_con;
		
		fann_type tmp_error = error_begin[get_global_id(0)]; //Ok
		__global unsigned int* cs = cs1stc+nrn[get_global_id(0)].first_con;
		float16 tmps;
		for(; i!=im%16; i++)//im
		{
			j = cs[i];
			ts[i] = mad(tmp_error, nrn[j].value, ts[i]);
		}
		j = 0;
		__global fann_type* tsj = ts+i;
		__global float16* tsj16 = tsj;
		for(; i<im; i+=16)
		{
			tsj16[j] = mad((float16)tmp_error, (float16)(nrn[cs[i]].value, nrn[cs[i+1]].value, nrn[cs[i+2]].value, nrn[cs[i+3]].value, nrn[cs[i+4]].value,\
			nrn[cs[i+5]].value, nrn[cs[i+6]].value, nrn[cs[i+7]].value, nrn[cs[i+8]].value, nrn[cs[i+9]].value, nrn[cs[i+10]].value, nrn[cs[i+11]].value,\
			nrn[cs[i+12]].value, nrn[cs[i+13]].value, nrn[cs[i+14]].value, nrn[cs[i+15]].value), tsj16[j]);
			j++;
		}
		barrier(CLK_GLOBAL_MEM_FENCE);
}*/

__kernel void fl_update_slopespr( __global fann_neuron* neuronit, __global fann_type* error_begin, __global fann_type* train_slopes,\
														__global unsigned int* offsets, __global unsigned int* globalsizes)
{
	__local unsigned int loffsets[LC+1];
	__local unsigned int lglobalsizes[LC];
	__global fann_type* gvalues;
	event_t event[4];
	event[0] = async_work_group_copy(loffsets, offsets, LC+1, 0);
	event[1] = async_work_group_copy(lglobalsizes, globalsizes, LC, 0);
	wait_group_events(2, &event);
	unsigned int j, x, gid, lx, cn, clc, idx=0, off=0, k, nr, pnr, szp, dc;
	for(k=1; k<LC; k++){ //LC!
		szp = lglobalsizes[k-1];
		clc = (lglobalsizes[k]-1)*szp; //Sub bias neuron in current layer
		gvalues = &neuronit[loffsets[k-1]].value;
		for(j = 0; get_global_size(0)*j<clc; j++){//j < 1<<DV && 
			cn = get_global_id(0) + get_global_size(0)*j;
			pnr = cn % szp; //Neuron from prev layer at current conn.
			nr  = cn / szp; //Neuron from curr layer at current conn.
			idx = cn+off;//-wtr*(get_group_id(0)+j*get_num_groups(0));//
			if(cn<clc) train_slopes[idx] = mad(error_begin[nr+loffsets[k]], neuronit[(pnr+loffsets[k-1])].value, train_slopes[idx]);// values[cs1stc[j]] //
			//if(idx==8165 && cn<clc)printf("GPU: idx==%d, pnr==%d\n", idx, nr+loffsets[k]);
		}
		off+=clc;
	}	
	
	//train_slopes[j] = mad(error_begin[tmp_errors[x]], nrn[cs1stc[j]].value, train_slopes[j]);// values[cs1stc[j]] //
}

/*
__kernel void fl_comp_mse(__global fann_type* error_begincl, __global unsigned int* offset, __global fann_neuron* neuronit,
	__global fann_type* desired_output, __global fann_type* MSE_value, __global unsigned int* num_bit_fail,
		__global fann_type* bit_fail_limit)
{
	unsigned int x = get_global_id(0);//clamp((uint)get_global_id(0), (uint)get_global_offset(0), (uint)(get_global_offset(0)+get_global_size(0)-1)), 
	unsigned int off = get_global_offset(0);
	uint nx = x+*offset-off, tx = x - off;//off is only for desired_output
	fann_type neuron_value = neuronit[nx].value;
	fann_type neuron_diff = desired_output[x] - neuron_value;
	neuron_diff = fann_update_MSE(&MSE_value[tx], num_bit_fail, bit_fail_limit, &neuronit[nx], neuron_diff);
#ifdef ENABLEDTEF
		neuron_diff = clamp((fann_type) log((1.0 + neuron_diff) / (1.0 - neuron_diff)), (fann_type)-17.0, (fann_type)17.0);
#endif
	error_begincl[nx] = neuron_diff * fann_activation_derived(neuronit[nx].activation_function,\
				neuronit[nx].activation_steepness, neuron_value, neuronit[nx].sum);
	barrier(CLK_GLOBAL_MEM_FENCE);
}*/

__kernel void fl_uwirpr(__global fann_type *train_slopes, __global fann_type *weights, __global fann_type *prev_steps,
	__global fann_type *prev_train_slopes, __global float *increase_factor, __global float *decrease_factor,
	__global float *delta_min, __global float *delta_max)
{
	//if(get_global_id(0)>get_global_size(0)) return;
	unsigned int x = get_global_id(0);
	fann_type prev_step, slope, prev_slope, next_step, same_sign, currw = weights[x];
	prev_step = max(prev_steps[x], (fann_type) 0.0001);	// prev_step may not be zero because then the training will stop
	prev_slope = prev_train_slopes[x];
	slope = train_slopes[x];
	//printf("GPU: prev_slope== %f\n", prev_slope);
	same_sign = prev_slope * slope;
	slope = select((fann_type)0, slope, same_sign >= 0.0);
	next_step = select(max(prev_step * *decrease_factor, *delta_min),\
					   min(prev_step * *increase_factor, *delta_max),\
					   same_sign >= 0.0);
	weights[x] = select(min((fann_type)(currw+next_step), (fann_type)1500.0),\
						max((fann_type)-1500.0, (fann_type)(currw-next_step)),\
						slope < 0);
	barrier(CLK_GLOBAL_MEM_FENCE);
	prev_steps[x] = next_step;
	prev_train_slopes[x] = slope;
	train_slopes[x] = 0.0;
	barrier(CLK_GLOBAL_MEM_FENCE);
}

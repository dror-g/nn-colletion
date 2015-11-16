#include </home/inferno/Soft/fann/src/inc.cl>
#ifndef NC
	#define NC 1024 //Neuron count
#endif
#ifndef ML
	#define ML 1024 //Max neurons in layer
#endif
#ifndef LC
	#define LC 4 //Layer count
#endif
#ifndef DV
	#define DV 3//Left shift
#endif
/*
#ifndef FIRSTL
	#define FIRSTL//Left shift
#endif
#ifndef LASTL
	#define LASTL//Left shift
#endif
*/

__kernel void fl_summ_all_in_1_fc( __global __read_only fann_type* weights, __global fann_neuron* neuronit, __global unsigned int* offsets, __global unsigned int* globalsizes,\
								   __global fann_type* error_begincl, __global fann_type* desired_output, __global fann_type* MSE_value,\
								   __global unsigned int* num_bit_fail, __global fann_type* bit_fail_limit,
								   __global fann_type* input, __global unsigned int* in_off, __global unsigned int* out_off, __global unsigned int* gk)
{
	__local fann_type outpll[256];
	__local unsigned int loffsets[LC+1];
	__local unsigned int lglobalsizes[LC];
	__local unsigned int loff, ls, lk;
	event_t event[4];
	size_t idx, j=0, i, l16, k;
	fann_type neuron_sum, max_sum, steepness, value, sum;
	__global fann_type* gvalues;
	__global fann_type* gsums;
	__global fann_neuron* neurons;
	__global fann_type* ginput = input + *in_off;
	__global fann_type* gdesired_output = desired_output + *out_off;
	unsigned int N, x, gid, lx, cn, clc, cnt=0, off=0, lnr, nr, pnr, szp, flag = 0, lid, wtr;
	event[0] = async_work_group_copy(loffsets, offsets, LC+1, 0);
	event[1] = async_work_group_copy(lglobalsizes, globalsizes, LC, 0);
	wait_group_events(2, &event);
	//Must fill input values and add ann->num_input to inp_offset after
	lid = get_local_id(0);
#ifdef FIRSTL
	if(get_global_id(0)<lglobalsizes[0]-1){
		neuronit[get_global_id(0)].value = ginput[get_global_id(0)];
	}
#endif
	if(get_global_id(0)==0){
		neuronit[lglobalsizes[0]-1].value = 1.0;
#ifdef FIRSTL		
		*in_off += lglobalsizes[0]-1;
#endif
	}		
#ifdef FIRSTL
		k = 1;
#else
		k = *gk;
		off = (lglobalsizes[k-1]-1)*lglobalsizes[k-2] + (lglobalsizes[k-2]-1)*lglobalsizes[k-3];
#endif

	szp = lglobalsizes[k-1];
	clc = (lglobalsizes[k]-1)*szp; //Sub bias neuron in current layer
	gvalues = &neuronit[loffsets[k-1]].value;
	lx = lid/szp;
	N = max((uint)1, szp/get_local_size(0));
	clc = clc/N;
	wtr = max((uint)szp, get_local_size(0)); //weights to read
	for(j = 0; get_global_size(0)*j<clc; j++){//j < 1<<DV && 
		//event[0] = async_work_group_copy(lweights, &weights[off+wtr*(get_group_id(0)+j*get_num_groups(0))], wtr, 0);
		gid = get_global_id(0) + get_global_size(0)*j;
		cn  = gid;//select((uint)0, (uint)gid, gid<clc);
		pnr = (N*cn) % szp; //Neuron from prev layer at current conn.
		nr  = (N*cn) / szp; //Neuron from curr layer at current conn.
		x = select((uint)NC-1, nr + loffsets[k], gid<clc && pnr==0);
		idx = N*cn+off;//-wtr*(get_group_id(0)+j*get_num_groups(0));//
		outpll[lid] = gvalues[pnr*8] * weights[idx];//lvalues
		for(i=1; i<N; i++){// Repeat when stride increased
			outpll[lid] += gvalues[(pnr+i)*8] * weights[idx+i];//lvalues
		}

		barrier(CLK_LOCAL_MEM_FENCE);
		idx = min(szp, get_local_size(0));
		for(i=idx/2; lid%idx<i; i>>=1){
			outpll[lid] += outpll[lid+i];
		}
		barrier(CLK_LOCAL_MEM_FENCE);
		if(gid<clc && pnr==0 && nr<lglobalsizes[k]){
#ifdef  LASTL
			//printf("CPU %d) x==%d\n", k, x);
#endif
			steepness = neuronit[x].activation_steepness;
			max_sum = 150.0/steepness;
			neuron_sum = clamp((fann_type)(outpll[lid]*steepness), (fann_type)(-max_sum), (fann_type)max_sum);
			fann_activation_switch(neuronit[x].activation_function, neuron_sum, value);
			cnt++;
			neuronit[x].sum = neuron_sum;  //Sums to sums
			neuronit[x].value = value;//Values to values
			error_begincl[x] = 0; //zero errors at run.
		}
		barrier(CLK_LOCAL_MEM_FENCE);
	}
	if(get_global_id(0)==0){
		neuronit[loffsets[k+1]-1].value = 1.0;
		error_begincl[loffsets[k+1]-1] = 0.0;
		//printf("CPU %d) loffsets[k+1]-1==%d\n", k, loffsets[k+1]-1);
	}
	off += clc;
	barrier(CLK_GLOBAL_MEM_FENCE);//global_sync(flags, k);
	k++; //Layer count++
	szp = lglobalsizes[k-1];
	clc = (lglobalsizes[k]-1)*szp; //Sub bias neuron in current layer
	gvalues = &neuronit[loffsets[k-1]].value;
	lx = lid/szp;
	N = max((uint)1, szp/get_local_size(0));
	clc = clc/N;
	wtr = max((uint)szp, get_local_size(0)); //weights to read
	for(j = 0; get_global_size(0)*j<clc; j++){//j < 1<<DV && 
		gid = get_global_id(0) + get_global_size(0)*j;
		cn  = gid;//select((uint)0, (uint)gid, gid<clc);
		pnr = (N*cn) % szp; //Neuron from prev layer at current conn.
		nr  = (N*cn) / szp; //Neuron from curr layer at current conn.
		x = select((uint)NC+1, nr + loffsets[k], gid<clc && pnr==0);
		idx = N*cn+off;//-wtr*(get_group_id(0)+j*get_num_groups(0));//
		outpll[lid] = gvalues[pnr*8] * weights[idx];//lvalues
		for(i=1; i<N; i++){// Repeat when stride increased
			outpll[lid] += gvalues[(pnr+i)*8] * weights[idx+i];//lvalues
		}
		barrier(CLK_LOCAL_MEM_FENCE);
		idx = min(szp, get_local_size(0));
		for(i=idx/2; lid%idx<i; i>>=1){
			outpll[lid] += outpll[lid+i];
		}
		barrier(CLK_LOCAL_MEM_FENCE);
#ifdef  LASTL		
		if(pnr==0 && gid<clc && nr<lglobalsizes[LC-1]){
			//printf("CPU %d) x==%d\n", k, x);
#else
		if(pnr==0 && gid<clc){
#endif
			steepness = neuronit[x].activation_steepness;
			max_sum = 150.0/steepness;
			neuron_sum = clamp((fann_type)(outpll[lid]*steepness), (fann_type)(-max_sum), (fann_type)max_sum);
			fann_activation_switch(neuronit[x].activation_function, neuron_sum, value);
			cnt++;
			neuronit[x].sum = neuron_sum;  //Sums to sums
			neuronit[x].value = value;//Values to values
#ifdef  LASTL
			fann_type neuron_diff = gdesired_output[nr] - value;  //Must add ann->num_output to out_offset after
			neuron_diff = fann_update_MSE(&MSE_value[nr], num_bit_fail, bit_fail_limit, &neuronit[x], neuron_diff);
#ifdef ENABLEDTEF
			neuron_diff = clamp((fann_type) log((1.0 + neuron_diff) / (1.0 - neuron_diff)), (fann_type)-17.0, (fann_type)17.0);
#endif
			error_begincl[x] = neuron_diff * fann_activation_derived(neuronit[x].activation_function, neuronit[x].activation_steepness, value, neuron_sum);
#else
			error_begincl[x] = 0;	
#endif
		}
		barrier(CLK_LOCAL_MEM_FENCE);
	}
	if(get_global_id(0)==0){
		neuronit[loffsets[k+1]-1].value = 1.0;
		error_begincl[loffsets[k+1]-1] = 0.0;
		//printf("CPU %d) loffsets[k+1]-1==%d\n", k, loffsets[k+1]-1);
#ifndef LASTL
		*gk = k+1;
#else
		*out_off += lglobalsizes[LC-1]-1;
#endif
	}

}

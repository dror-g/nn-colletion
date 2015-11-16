//#pragma OPENCL EXTENSION cl_khr_fp64 : enable
#include </home/inferno/Soft/fann/src/inc.cl>
#define MAX_LS 112
#ifndef LC
	#define LC 2 //Layer count
#endif
#ifndef NC
	#define NC 4096 //Neuron count
#endif
#ifndef UC
	#define UC 1280 //compute Units Count (def for pitcairn)
#endif
#ifndef ML
	#define ML 128 //Max neurons in layer
#endif
#ifndef DV
	#define DV 3//Left shift
#endif

__kernel void 
fl_backprop_mse_all_in_1( __global fann_type* error_begin, __global fann_type* weights,	__global unsigned int* offsets, __global unsigned int* globalsizes)
{
	int k, x, j = 0, i = 0;
	uint cnti, cntii, nr, pnr, rc, cn, dc, clc, off=0, szp, szpr, gid, lid, N, idx;
	__local unsigned int loffsets[LC];
	__local unsigned int lglobalsizes[LC];
	__local fann_type outpll[256];
	__global fann_type*  gerror_begin;
	//lcsr lcssl[] = %lcssl%;
	fann_type sum;
	float16 tmpeb16;
	event_t event[2];
	event[0] = async_work_group_copy(loffsets, offsets, LC, 0);
	event[1] = async_work_group_copy(lglobalsizes, globalsizes, LC, 0);
	wait_group_events(2, &event);
	lid = get_local_id(0);
//	#pragma unroll 1
	for(k=1; k<LC; k++){ //LC!
		szp = lglobalsizes[k-1];
		clc = (lglobalsizes[k]-1)*szp; //Sub bias neuron in current layer
		off += clc; //Temporary. In global case must keep it from run
	}
	for (k=LC-2; k>0; k--) {
		szp = lglobalsizes[k+1]; //Fake (to fit in power of 2) size of next layer connected.
		szpr = lglobalsizes[k+1]-1; //Real szp. Sub bias neuron in next layer
		clc = szp*lglobalsizes[k];
		off -= szpr*lglobalsizes[k];
		gerror_begin = error_begin+loffsets[k+1];
        barrier(CLK_LOCAL_MEM_FENCE);
        N = max((uint)1, szp/get_local_size(0));
		clc = clc/N;
		for(j = 0; get_global_size(0)*j<clc; j++){
			gid = get_global_id(0) + get_global_size(0)*j;
			cn  = select((uint)0, (uint)gid, gid<clc);
			pnr  =  (N*cn) % szp;				//Neuron from next layer at current conn.
			nr   = (N*cn) / szp;				//Neuron from curr layer at current conn.
			dc = nr + lglobalsizes[k]*pnr + off;//???

			outpll[lid] = gerror_begin[pnr] * weights[dc];//
			for(i=1; i<N; i++){
				outpll[lid] += gerror_begin[(pnr+i)] * weights[dc+i*lglobalsizes[k]];//
			}
			barrier(CLK_LOCAL_MEM_FENCE);
			idx = min(szp, get_local_size(0));
			for(i=idx/2; lid%idx<i; i>>=1){
				outpll[lid] += outpll[lid+i];
			}
			x = nr + loffsets[k];
			sum = 0.0;
			
			if(pnr == 0 && gid<clc){
				error_begin[x] += outpll[get_local_id(0)];
			}
			barrier(CLK_GLOBAL_MEM_FENCE);
		}
		barrier(CLK_GLOBAL_MEM_FENCE);
	}
}

typedef float fann_type;

#define fann_linear_derive(steepness, value) (steepness)
#define fann_sigmoid_real(sum) (1.0f/(1.0f + exp(-2.0f * sum)))
#define fann_sigmoid_derive(steepness, value) (2.0f * steepness * value * (1.0f - value))
#define fann_sigmoid_symmetric_real(sum) (2.0f/(1.0f + exp(-2.0f * sum)) - 1.0f)
#define fann_sigmoid_symmetric_derive(steepness, value) steepness * (1.0f - (value*value))
#define fann_gaussian_real(sum) (exp(-sum * sum))
#define fann_gaussian_derive(steepness, value, sum) (-2.0f * sum * value * steepness * steepness)
#define fann_gaussian_symmetric_real(sum) ((exp(-sum * sum)*2.0f)-1.0f)
#define fann_gaussian_symmetric_derive(steepness, value, sum) (-2.0f * sum * (value+1.0f) * steepness * steepness)
#define fann_elliot_real(sum) (((sum) / 2.0f) / (1.0f + fabs(sum)) + 0.5f)
#define fann_elliot_derive(steepness, value, sum) (steepness * 1.0f / (2.0f *(1.0f + fabs(sum)) * (1.0f + fabs(sum))))
#define fann_elliot_symmetric_real(sum) ((sum) / (1.0f + fabs(sum)))
#define fann_elliot_symmetric_derive(steepness, value, sum) (steepness * 1.0f / ((1.0f + fabs(sum)) * (1.0f + fabs(sum))))
#define fann_sin_symmetric_real(sum) (sin(sum))
#define fann_sin_symmetric_derive(steepness, sum) (steepness*cos(steepness*sum))
#define fann_cos_symmetric_real(sum) (cos(sum))
#define fann_cos_symmetric_derive(steepness, sum) (steepness*-sin(steepness*sum))
#define fann_sin_real(sum) (sin(sum)/2.0f+0.5f)
#define fann_sin_derive(steepness, sum) (steepness*cos(steepness*sum)/2.0f)
#define fann_cos_real(sum) (cos(sum)/2.0f+0.5f)
#define fann_cos_derive(steepness, sum) (steepness*-sin(steepness*sum)/2.0f)
#define fann_clip(x, lo, hi) (((x) < (lo)) ? (lo) : (((x) > (hi)) ? (hi) : (x)))
#define fann_linear_func(v1, r1, v2, r2, sum) (((((r2)-(r1)) * ((sum)-(v1)))/((v2)-(v1))) + (r1))
#define fann_stepwise(v1, v2, v3, v4, v5, v6, r1, r2, r3, r4, r5, r6, min, max, sum) (sum < v5 ? (sum < v3 ? (sum < v2 ? (sum < v1 ? min : fann_linear_func(v1, r1, v2, r2, sum)) : fann_linear_func(v2, r2, v3, r3, sum)) : (sum < v4 ? fann_linear_func(v3, r3, v4, r4, sum) : fann_linear_func(v4, r4, v5, r5, sum))) : (sum < v6 ? fann_linear_func(v5, r5, v6, r6, sum) : max))

inline void AtomicAdd(volatile __global fann_type *source, const fann_type operand) {
    union {
        unsigned int intVal;
        fann_type floatVal;
    } newVal;
    union {
        unsigned int intVal;
        fann_type floatVal;
    } prevVal;
    do {
        prevVal.floatVal = *source;
        newVal.floatVal = prevVal.floatVal + operand;
    } while (atomic_cmpxchg((volatile __global unsigned int *)source, prevVal.intVal, newVal.intVal) != prevVal.intVal);
}

inline void AtomicMv(volatile __global fann_type *source, const fann_type operand) {
    union {
        unsigned int intVal;
        fann_type floatVal;
    } newVal;
    union {
        unsigned int intVal;
        fann_type floatVal;
    } prevVal;
    do {
        prevVal.floatVal = *source;
        newVal.floatVal = operand;
    } while (atomic_cmpxchg((volatile __global unsigned int *)source, prevVal.intVal, newVal.intVal) != prevVal.intVal);
}

enum fann_activationfunc_enum
{
	FANN_LINEAR = 0,
	FANN_THRESHOLD,
	FANN_THRESHOLD_SYMMETRIC,
	FANN_SIGMOID,
	FANN_SIGMOID_STEPWISE,
	FANN_SIGMOID_SYMMETRIC,
	FANN_SIGMOID_SYMMETRIC_STEPWISE,
	FANN_GAUSSIAN,
	FANN_GAUSSIAN_SYMMETRIC,
	/* Stepwise linear approximation to gaussian.
	 * Faster than gaussian but a bit less precise.
	 * NOT implemented yet.
	 */
	FANN_GAUSSIAN_STEPWISE,
	FANN_ELLIOT,
	FANN_ELLIOT_SYMMETRIC,
	FANN_LINEAR_PIECE,
	FANN_LINEAR_PIECE_SYMMETRIC,
	FANN_SIN_SYMMETRIC,
	FANN_COS_SYMMETRIC,
	FANN_SIN,
	FANN_COS
};
typedef struct
{
	/* Index to the first and last connection
	 * (actually the last is a past end index)
	 */
	unsigned int first_con;
	unsigned int last_con;
	unsigned int first_revcon;
	unsigned int last_revcon;
	/* The sum of the inputs multiplied with the weights */
	fann_type sum;
	/* The value of the activation function applied to the sum */
	fann_type value;
	/* The steepness of the activation function */
	fann_type activation_steepness;
	/* Used to choose which activation function to use */
	enum fann_activationfunc_enum activation_function;
} fann_neuron;

typedef struct
{
	int ic;
	int lc;
	int clc;
} lcsr;

typedef struct 
{
	__global fann_neuron *ns;
	} fann_neuronp;

fann_type fann_activation_derived(unsigned int activation_function,
								  fann_type steepness, fann_type value, fann_type sum)
{
	switch (activation_function)
	{
		case FANN_LINEAR:
		case FANN_LINEAR_PIECE:
		case FANN_LINEAR_PIECE_SYMMETRIC:
			return (fann_type) fann_linear_derive(steepness, value);
		case FANN_SIGMOID:
		case FANN_SIGMOID_STEPWISE:
			value = clamp(value, 0.01f, 0.99f);
			return (fann_type) fann_sigmoid_derive(steepness, value);
		case FANN_SIGMOID_SYMMETRIC:
		case FANN_SIGMOID_SYMMETRIC_STEPWISE:
			value = clamp(value, -0.98f, 0.98f);
			return (fann_type) fann_sigmoid_symmetric_derive(steepness, value);
		case FANN_GAUSSIAN:
			/* value = fann_clip(value, 0.01f, 0.99f); */
			return (fann_type) fann_gaussian_derive(steepness, value, sum);
		case FANN_GAUSSIAN_SYMMETRIC:
			/* value = fann_clip(value, -0.98f, 0.98f); */
			return (fann_type) fann_gaussian_symmetric_derive(steepness, value, sum);
		case FANN_ELLIOT:
			value = clamp(value, 0.01f, 0.99f);
			return (fann_type) fann_elliot_derive(steepness, value, sum);
		case FANN_ELLIOT_SYMMETRIC:
			value = clamp(value, -0.98f, 0.98f);
			return (fann_type) fann_elliot_symmetric_derive(steepness, value, sum);
		case FANN_SIN_SYMMETRIC:
			return (fann_type) fann_sin_symmetric_derive(steepness, sum);
		case FANN_COS_SYMMETRIC:
			return (fann_type) fann_cos_symmetric_derive(steepness, sum);
		case FANN_SIN:
			return (fann_type) fann_sin_derive(steepness, sum);
		case FANN_COS:
			return (fann_type) fann_cos_derive(steepness, sum);
	}
	return 0;
}

fann_type fann_update_MSE(__global fann_type* MSE_value, __global unsigned int* num_bit_fail, __global fann_type* bit_fail_limit,
 __global fann_neuron* neuron, fann_type neuron_diff)
{
	float neuron_diff2;
	
	switch (neuron->activation_function)
	{
		case FANN_LINEAR_PIECE_SYMMETRIC:
		case FANN_THRESHOLD_SYMMETRIC:
		case FANN_SIGMOID_SYMMETRIC:
		case FANN_SIGMOID_SYMMETRIC_STEPWISE:
		case FANN_ELLIOT_SYMMETRIC:
		case FANN_GAUSSIAN_SYMMETRIC:
		case FANN_SIN_SYMMETRIC:
		case FANN_COS_SYMMETRIC:
			neuron_diff = neuron_diff/2.0;
			break;
		case FANN_THRESHOLD:
		case FANN_LINEAR:
		case FANN_SIGMOID:
		case FANN_SIGMOID_STEPWISE:
		case FANN_GAUSSIAN:
		case FANN_GAUSSIAN_STEPWISE:
		case FANN_ELLIOT:
		case FANN_LINEAR_PIECE:
		case FANN_SIN:
		case FANN_COS:
			break;
	}

	neuron_diff2 = (float) (neuron_diff * neuron_diff);

	*MSE_value += neuron_diff2;

	/*printf("neuron_diff %f = (%f - %f)[/2], neuron_diff2=%f, sum=%f, MSE_value=%f, num_MSE=%d\n", neuron_diff, *desired_output, neuron_value, neuron_diff2, last_layer_begin->sum, ann->MSE_value, ann->num_MSE); */
	if(fabs(neuron_diff) >= *bit_fail_limit)
	{
		*num_bit_fail++;
	}
	
	return neuron_diff;
}

#define fann_activation_switch(activation_function, value, result) \
switch(activation_function) \
{ \
	case FANN_LINEAR: \
		result = (fann_type)value; \
        break; \
	case FANN_LINEAR_PIECE: \
		result = (fann_type)((value < 0) ? 0 : (value > 1) ? 1 : value); \
        break; \
	case FANN_LINEAR_PIECE_SYMMETRIC: \
		result = (fann_type)((value < -1) ? -1 : (value > 1) ? 1 : value); \
        break; \
	case FANN_SIGMOID: \
		result = (fann_type)fann_sigmoid_real(value); \
        break; \
	case FANN_SIGMOID_SYMMETRIC: \
		result = (fann_type)fann_sigmoid_symmetric_real(value); \
        break; \
	case FANN_SIGMOID_SYMMETRIC_STEPWISE: \
		result = (fann_type)fann_stepwise(-2.64665293693542480469e+00, -1.47221934795379638672e+00, -5.49306154251098632812e-01, 5.49306154251098632812e-01, 1.47221934795379638672e+00, 2.64665293693542480469e+00, -9.90000009536743164062e-01, -8.99999976158142089844e-01, -5.00000000000000000000e-01, 5.00000000000000000000e-01, 8.99999976158142089844e-01, 9.90000009536743164062e-01, -1, 1, value); \
        break; \
	case FANN_SIGMOID_STEPWISE: \
		result = (fann_type)fann_stepwise(-2.64665246009826660156e+00, -1.47221946716308593750e+00, -5.49306154251098632812e-01, 5.49306154251098632812e-01, 1.47221934795379638672e+00, 2.64665293693542480469e+00, 4.99999988824129104614e-03, 5.00000007450580596924e-02, 2.50000000000000000000e-01, 7.50000000000000000000e-01, 9.49999988079071044922e-01, 9.95000004768371582031e-01, 0, 1, value); \
        break; \
	case FANN_THRESHOLD: \
		result = (fann_type)((value < 0) ? 0 : 1); \
        break; \
	case FANN_THRESHOLD_SYMMETRIC: \
		result = (fann_type)((value < 0) ? -1 : 1); \
        break; \
	case FANN_GAUSSIAN: \
		result = (fann_type)fann_gaussian_real(value); \
        break; \
	case FANN_GAUSSIAN_SYMMETRIC: \
		result = (fann_type)fann_gaussian_symmetric_real(value); \
        break; \
	case FANN_ELLIOT: \
		result = (fann_type)fann_elliot_real(value); \
	    break; \
	case FANN_ELLIOT_SYMMETRIC: \
		result = (fann_type)fann_elliot_symmetric_real(value); \
        break; \
	case FANN_SIN_SYMMETRIC: \
		result = (fann_type)fann_sin_symmetric_real(value); \
        break; \
	case FANN_COS_SYMMETRIC: \
		result = (fann_type)fann_cos_symmetric_real(value); \
        break; \
	case FANN_SIN: \
		result = (fann_type)fann_sin_real(value); \
        break; \
	case FANN_COS: \
		result = (fann_type)fann_cos_real(value); \
        break; \
	case FANN_GAUSSIAN_STEPWISE: \
        result = 0; \
        break; \
}

/*
Fast Artificial Neural Network Library (fann)
Copyright (C) 2003 Steffen Nissen (lukesky@diku.dk)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <stdio.h>
#include "floatfann.h"

int main()
{
	fann_type *calc_out;
	fann_type input[9];
	int i;

	struct fann *ann = fann_create_from_file("comp.net");
//0 0 1 4 5 5 0 9 8 1 0 9 4 7
	/*input[0] = 0;
	input[1] = 0;
	input[2] = 1;
	input[3] = 4;
	input[4] = 5;
	input[5] = 5;
	input[6] = 0;
	input[7] = 9;
	input[8] = 8;
	input[9] = 1;
	input[10] = 0;
	input[11] = 9;
	input[12] = 4;
	input[13] = 7;*/
//0 7 1 2 3 7 9 6 5 3
	input[0] = 0;
	input[1] = 7;
	input[2] = 1;
	input[3] = 2;
	input[4] = 3;
	input[5] = 7;
	input[6] = 9;
	input[7] = 6;
	input[8] = 5;
	input[9] = 3;
	calc_out = fann_run(ann, input);

	//printf("xor test (%f,%f) -> %f\n", input[0], input[1], calc_out[0]);
	for(i = 0; i < 156; i++) {
        printf("%f ", calc_out[i]);
    	}
	printf("\n");
	//printf("0 7 1 2 3 7 9 6 5 3 test %f %f %f %f %f %f %f %f %f %f\n", calc_out[0], calc_out[1], calc_out[2], calc_out[3], calc_out[4], calc_out[5], calc_out[6], calc_out[7], calc_out[8], calc_out[9]);

	fann_destroy(ann);
	return 0;
}

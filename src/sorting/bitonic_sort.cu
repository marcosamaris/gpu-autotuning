/*
 * bitonic_sort.cu
 *
 */
 
#include <math.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <cuda_profiler_api.h>
//#include <cutil_inline.h>

// Convenience function for checking CUDA runtime API results
// can be wrapped around any runtime API call. No-op in release builds.
inline
cudaError_t checkCuda(cudaError_t result)
{
#if defined(DEBUG) || defined(_DEBUG)
  if (result != cudaSuccess) {
    fprintf(stderr, "CUDA Runtime Error: %s\n", cudaGetErrorString(result));
    assert(result == cudaSuccess);
  }
#endif
  return result;
}

 
 #define 	MAX_THREADS 	128
 //#define 	N 		32768
 
 int* r_values;
 int* d_values;

 void Init(int* values, int i, int N) {
        srand( time(NULL) );
	printf("\n------------------------------\n");
 
        if (i == 0) {
        // Uniform distribution
                printf("Data set distribution: Uniform\n");
                for (int x = 0; x < N; ++x) {
                        values[x] = rand() % 100;
                        //printf("%d ", values[x]);
                }
        }
        else if (i == 1) {
        // Gaussian distribution
        #define MEAN    100
        #define STD_DEV	5 
                printf("Data set distribution: Gaussian\n");
                float r;
                for (int x = 0; x < N; ++x) {
                        r  = (rand()%3 - 1) + (rand()%3 - 1) + (rand()%3 - 1);
                        values[x] = int( round(r * STD_DEV + MEAN) );
                        //printf("%d ", values[x]);
                }
        }
        else if (i == 2) {
        // Bucket distribution
                printf("Data set distribution: Bucket\n");
                int j = 0;
                for (int x = 0; x < N; ++x, ++j) {
                        if (j / 20 < 1)
                                values[x] = rand() % 20;
                        else if (j / 20 < 2)
                                values[x] = rand() % 20 + 20;
                        else if (j / 20 < 3)
                                values[x] = rand() % 20 + 40;
                        else if (j / 20 < 4)
                                values[x] = rand() % 20 + 60;
                        else if (j / 20 < 5)
                                values[x] = rand() % 20 + 80; 
                        if (j == 100)
                                j = 0;
                        //printf("%d ", values[x]);
                }
        }
        else if (i == 3) {
        // Sorted distribution
                printf("Data set distribution: Sorted\n");
                /*for (int x = 0; x < N; ++x)
                        print("%d ", values[x]);
		*/
 	}
        else if (i == 4) {
        // Zero distribution
                printf("Data set distribution: Zero\n");
                int r = rand() % 100;
                for (int x = 0; x < N; ++x) {
                        values[x] = r;
                        //printf("%d ", values[x]);
                }
        }
	printf("\n");
}
 
 // Kernel function
 __global__ static void Bitonic_Sort(int* values, int j, int k, int N) {
 	const unsigned long int idx = blockDim.x * blockIdx.x + threadIdx.x;

 	if (idx < N) {
 		int ixj = idx^j;
  		if (ixj > idx) {
 			if ((idx&k) == 0 && values[idx] > values[ixj]) {
				//exchange(idx, ixj);
				int tmp = values[idx];
				values[idx] = values[ixj];
				values[ixj] = tmp;
			}
			if ((idx&k) != 0 && values[idx] < values[ixj]) {
				//exchange(idx, ixj);
				int tmp = values[idx];
				values[idx] = values[ixj];
				values[ixj] = tmp;
			}
 		}	
 	}
}
 
 // program main
 int main(int argc, char** argv) {

	if (argc != 2) {
		fprintf(stderr, "Syntax: %s <Vector size Width> \n", argv[0]);
    		return EXIT_FAILURE;
	}

 	
	int N = atoi(argv[1]);
	size_t size = N * sizeof(long int);
	
	printf("./bitonic_sort starting with %d numbers...\n", N);
	srand( time(NULL) );

	int devId = 0;
	checkCuda( cudaSetDevice(devId) );
    	cudaDeviceReset();
	
	cudaDeviceProp prop;
	checkCuda( cudaGetDeviceProperties(&prop, devId) );
  	printf("Device: %s\n", prop.name);

 	//unsigned int hTimer;

 	
 	// allocate host memory
 	r_values = (int*)malloc(size);
	
	// allocate device memory
	cudaMalloc((void**)&d_values, size);
 	
	/* Types of data sets to be sorted:
	 *	1. Normal distribution
	 *	2. Gaussian distribution
	 *	3. Bucket distribution
	 *	4. Sorted Distribution
	 *	5. Zero Distribution
	 */

 	for (int i = 0; i < 1; ++i) {
		// initialize data set
 		Init(r_values, i, N);
 		 
 		// copy data to device
 		cudaMemcpy(d_values, r_values, size, cudaMemcpyHostToDevice) ;

		printf("Beginning kernel execution...\n");

 		
 		cudaThreadSynchronize() ;

		// execute kernel
       cudaProfilerStart(); 
		for (int k = 2; k <= N; k <<= 1) {
			for (int j = k >> 1; j > 0; j = j >> 1) {
				if (N < MAX_THREADS)
					Bitonic_Sort <<< 1, N >>> (d_values, j, k, N);
				else
					Bitonic_Sort <<< N / MAX_THREADS, MAX_THREADS >>> (d_values, j, k, N);
			}
		}
        cudaProfilerStop();
 		//cutilCheckMsg( "Kernel execution failed...\n" );
		//printf("Kernel execution failed...\n");
 
		cudaThreadSynchronize() ;

		//printf("\nKerned execution completed in %f ms\n", gpuTime);
 
 		// copy data back to host
		cudaMemcpy(r_values, d_values, size, cudaMemcpyDeviceToHost) ;

	 	// test print
	 	/*for (int i = 0; i < N; ++i) {
	 		printf("%d ", r_values[i]);
	 	}
	 	printf("\n");
		*/
	
		// test
		printf("\nTesting results...\n");
		for (int x = 0; x < N - 1; x++) {
			if (r_values[x] > r_values[x + 1]) {
				printf("Sorting failed.\n");
				break;
			}
			else
				if (x == N - 2)
					printf("SORTING SUCCESSFUL\n");
		}
	}

 	// free memory
 	cudaFree(d_values);
 	free(r_values);	
 	
 	cudaThreadExit();
  
}

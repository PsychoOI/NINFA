#include "lsl_common.h"

/* function [NumAvailable] = lsl_samples_available(LibHandle, Inlet) */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
    /* Handle for the desired field */
    mxArray *field;
    /* Temp pointer for function handle */
    uintptr_t *pTmp;
    /* Function handle */
    lsl_samples_available_t func;
    /* Input/output variables */
    uintptr_t inlet;
    unsigned result;

    /* Check number of input and output arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("2 input argument(s) required."); 
    }
    if (nlhs != 1) {
        mexErrMsgTxt("1 output argument(s) required."); 
    }

    /* Get function handle */
    field = mxGetField(prhs[0], 0, "lsl_samples_available");
    if (!field) {
        mexErrMsgTxt("The field 'lsl_samples_available' does not exist.");
    }
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp || mxGetNumberOfElements(field) == 0) {
        mexErrMsgTxt("The field 'lsl_samples_available' seems to be empty or invalid.");
    }
    func = (lsl_samples_available_t)(*pTmp);  // Proper dereference to obtain function pointer

    /* Get additional inputs */
    inlet = *(uintptr_t *)mxGetData(prhs[1]);
    
    /* Invoke function and return result */
    result = func((void*)inlet);  // Cast inlet to void* for the function call
    plhs[0] = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL); // Create output as unsigned int
    *(unsigned int *)mxGetData(plhs[0]) = result; // Store result safely
}

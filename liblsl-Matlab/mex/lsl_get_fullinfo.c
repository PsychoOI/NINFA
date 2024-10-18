#include "lsl_common.h"

/* function [StreamInfo] = lsl_get_fullinfo(LibHandle, Inlet, Timeout) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray* prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_get_fullinfo_t func;
    /* input/output variables */
    uintptr_t in;
    double timeout;
    streaminfo result;
    int errcode;

    if (nrhs != 3)
        mexErrMsgTxt("3 input argument(s) required."); 
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument(s) required."); 

    /* get function handle */
    field = mxGetField(prhs[0], 0, "lsl_get_fullinfo");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    
    pTmp = (uintptr_t*)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");

    /* Correctly assign the function pointer */
    func = (lsl_get_fullinfo_t)(*pTmp);  // Dereference to get the function pointer

    /* get additional inputs */
    in = *(uintptr_t*)mxGetData(prhs[1]);

    if (mxGetClassID(prhs[2]) != mxDOUBLE_CLASS)
        mexErrMsgTxt("The timeout argument must be passed as a double.");
    
    timeout = *(double*)mxGetData(prhs[2]);
    
    /* invoke the function */
    result = func((inlet)in, timeout, &errcode);  // Ensure correct casting to inlet
    if (errcode) {
        switch (errcode) {
            case lsl_timeout_error:
                mexErrMsgIdAndTxt("lsl:timeout_error", "The operation timed out.");
            case lsl_lost_error:
                mexErrMsgIdAndTxt("lsl:lost_error", "The stream has been lost.");
            case lsl_internal_error:
                mexErrMsgIdAndTxt("lsl:internal_error", "An internal error occurred.");
            default:
                mexErrMsgIdAndTxt("lsl:unknown_error", "An unknown error occurred.");
        }
    }

    /* Create output */
    plhs[0] = mxCreateNumericMatrix(1, 1, PTR_CLASS, mxREAL);
    *(uintptr_t*)mxGetData(plhs[0]) = (uintptr_t)result;  // Store the result pointer in the output
}

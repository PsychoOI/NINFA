#include "lsl_common.h"

/* function [TimeCorrection] = lsl_time_correction(LibHandle,Inlet,Timeout) */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
    /* Handle of the desired field */
    mxArray *field;
    /* Temp pointer */
    uintptr_t *pTmp;
    /* Function handle */
    lsl_time_correction_t func;
    /* Input/output variables */
    uintptr_t in;
    double timeout;
    double result;
    int errcode;
    
    /* Check the number of input and output arguments */
    if (nrhs != 3)
        mexErrMsgTxt("3 input argument(s) required."); 
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument(s) required."); 
    
    /* Get function handle */
    field = mxGetField(prhs[0], 0, "lsl_time_correction");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp || mxGetNumberOfElements(field) == 0)
        mexErrMsgTxt("The field seems to be empty.");
    
    func = (lsl_time_correction_t)(*pTmp);  // Correctly dereference to get function pointer
    
    /* Get additional inputs */
    in = *(uintptr_t *)mxGetData(prhs[1]);
    
    if (mxGetClassID(prhs[2]) != mxDOUBLE_CLASS)
        mexErrMsgTxt("The timeout argument must be passed as a double.");
    timeout = *(double *)mxGetData(prhs[2]);
    
    /* Invoke & return */
    result = func((void*)in, timeout, &errcode);  // Pass the inlet as a void pointer
    if (errcode) {
        if (errcode == lsl_timeout_error)
            mexErrMsgIdAndTxt("lsl:timeout_error", "The operation timed out.");
        if (errcode == lsl_lost_error)
            mexErrMsgIdAndTxt("lsl:lost_error", "The stream has been lost.");
        if (errcode == lsl_internal_error)
            mexErrMsgIdAndTxt("lsl:internal_error", "An internal error occurred.");
        mexErrMsgIdAndTxt("lsl:unknown_error", "An unknown error occurred.");
    }
    
    plhs[0] = mxCreateDoubleScalar(result);  // Create output variable
}

#include "lsl_common.h"

/* function Success = lsl_wait_for_consumers(LibHandle, Outlet, Timeout) */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
    /* Handle of the desired field */
    mxArray *field;
    /* Temp pointer */
    uintptr_t *pTmp;
    /* Function handle */
    lsl_wait_for_consumers_t func;
    /* Input/output variables */
    uintptr_t out;
    double timeout;
    int result;
    
    /* Check the number of input and output arguments */
    if (nrhs != 3)  // Corrected to expect 3 input arguments
        mexErrMsgTxt("3 input argument(s) required."); 
    if (nlhs != 0)  // No output expected
        mexErrMsgTxt("0 output argument(s) required."); 
    
    /* Get function handle */
    field = mxGetField(prhs[0], 0, "lsl_wait_for_consumers");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp || mxGetNumberOfElements(field) == 0)
        mexErrMsgTxt("The field seems to be empty.");
    
    func = (lsl_wait_for_consumers_t)(*pTmp);  // Correctly dereference to get function pointer
    
    /* Get additional inputs */
    out = *(uintptr_t *)mxGetData(prhs[1]);

    if (mxGetClassID(prhs[2]) != mxDOUBLE_CLASS)
        mexErrMsgTxt("The timeout argument must be passed as a double.");
    timeout = *(double *)mxGetData(prhs[2]);
    
    /* Invoke */
    result = func((void*)out, timeout);  // Cast out to void* to match the expected type
    
    /* If needed, you can provide some feedback on the success of the operation.
       If the function succeeds, we could do this in the future:
       plhs[0] = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
       *(double *)mxGetData(plhs[0]) = (double)result;  // Uncomment if you want to return result
    */
}

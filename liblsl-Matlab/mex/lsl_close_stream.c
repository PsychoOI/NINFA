#include "lsl_common.h"

/* function lsl_close_stream(LibHandle,inlet) */
void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray* prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    void **pTmp;  // Changed to void** to match the function pointer type
    /* function handle */
    lsl_close_stream_t func;  // Ensure this is the correct function pointer type
    /* input/output variables */
    void *inlet;  // Use void* to hold the inlet pointer
    
    if (nrhs != 2)
        mexErrMsgTxt("2 input argument(s) required."); 
    if (nlhs != 0)
        mexErrMsgTxt("0 output argument(s) required."); 
    
    /* get function handle */
    field = mxGetField(prhs[0], 0, "lsl_close_stream");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    
    pTmp = (void**)mxGetData(field);  // Cast to void**
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    
    func = (lsl_close_stream_t)(*pTmp);  // Dereference correctly
    
    /* get additional inputs */
    inlet = *(void**)mxGetData(prhs[1]);  // Use void* instead of uintptr_t
    
    /* invoke & return */
    func(inlet);  // Pass the inlet correctly
}

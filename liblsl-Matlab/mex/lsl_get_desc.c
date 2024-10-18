#include "lsl_common.h"

/* function [DescPtr] = lsl_get_desc(LibHandle, StreamInfo) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray* prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_get_desc_t func;
    /* input/output variables */
    uintptr_t info;
    xml_ptr desc;
    
    if (nrhs != 2)
        mexErrMsgTxt("2 input argument(s) required."); 
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument(s) required."); 
    
    /* get function handle */
    field = mxGetField(prhs[0], 0, "lsl_get_desc");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    pTmp = (uintptr_t*)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    
    /* Correct pointer type assignment */
    func = (lsl_get_desc_t)(*pTmp);  // Correct dereferencing to get function pointer
    
    /* get additional inputs */
    info = *(uintptr_t*)mxGetData(prhs[1]);
    
    /* invoke & return */
    desc = func((streaminfo)info);  // Cast info to the correct type
    plhs[0] = mxCreateNumericMatrix(1, 1, PTR_CLASS, mxREAL); // Use appropriate class for pointer
    *(uintptr_t*)mxGetData(plhs[0]) = (uintptr_t)desc;  // Store the pointer in the output
}

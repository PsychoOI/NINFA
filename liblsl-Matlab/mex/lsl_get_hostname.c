#include "lsl_common.h"

/* function [SessionID] = lsl_get_hostname(LibHandle,StreamInfo) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray *prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_get_hostname_t func;
    /* input/output variables */
    uintptr_t info;
    char *hostname;

    if (nrhs != 2)
        mexErrMsgTxt("2 input argument(s) required."); 
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument(s) required."); 

    /* get function handle */
    field = mxGetField(prhs[0], 0, "lsl_get_hostname");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    
    pTmp = (uintptr_t*)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    
    /* Correctly assign the function pointer */
    func = (lsl_get_hostname_t)(*pTmp);  // Dereference to get the function pointer

    /* get additional inputs */
    info = *(uintptr_t*)mxGetData(prhs[1]);

    /* invoke the function */
    hostname = func((streaminfo)info);  // Ensure correct casting to streaminfo

    /* create output string */
    plhs[0] = mxCreateString(hostname);
}

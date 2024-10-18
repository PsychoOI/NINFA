#include "lsl_common.h"

/* function [Version] = lsl_get_version(LibHandle,StreamInfo) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray *prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_get_version_t func;
    /* input/output variables */
    uintptr_t info;
    int version;
    
    /* Ensure the correct number of input/output arguments */
    if (nrhs != 2)
        mexErrMsgTxt("2 input argument(s) required."); 
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument(s) required."); 
    
    /* Get function handle */
    field = mxGetField(prhs[0], 0, "lsl_get_version");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    
    /* Dereference the function pointer correctly */
    func = (lsl_get_version_t)(*pTmp);
    
    /* Get the StreamInfo input */
    info = *(uintptr_t *)mxGetData(prhs[1]);
    
    /* Call the function and get the version */
    version = func((streaminfo)info);
    
    /* Return the version as a MATLAB double */
    plhs[0] = mxCreateDoubleScalar((double)version);
}

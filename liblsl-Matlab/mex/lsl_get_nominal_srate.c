#include "lsl_common.h"

/* function [NominalSRate] = lsl_get_nominal_srate(LibHandle, StreamInfo) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray *prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_get_nominal_srate_t func;
    /* input/output variable */
    uintptr_t info;
    double nominal_srate;

    if (nrhs != 2)
        mexErrMsgTxt("2 input argument(s) required."); 
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument(s) required."); 
    
    /* get function handle */
    field = mxGetField(prhs[0], 0, "lsl_get_nominal_srate");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    
    /* Correctly assign the function pointer */
    func = (lsl_get_nominal_srate_t)(*pTmp);  // Dereference to get the function pointer
    
    /* get additional inputs */
    info = *(uintptr_t *)mxGetData(prhs[1]);
    
    /* invoke & return */
    nominal_srate = func((streaminfo)info);  // Ensure correct casting to streaminfo
    
    /* create output */
    plhs[0] = mxCreateDoubleScalar(nominal_srate);  // Create a scalar output
}

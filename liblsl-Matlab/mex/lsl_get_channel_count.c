#include "lsl_common.h"

/* function [ChannelCount] = lsl_get_channel_count(LibHandle, StreamInfo) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray* prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_get_channel_count_t func;
    /* input/output variables */
    uintptr_t info;
    int channel_count;

    if (nrhs != 2)
        mexErrMsgTxt("2 input argument(s) required."); 
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument(s) required."); 
    
    /* get function handle */
    field = mxGetField(prhs[0], 0, "lsl_get_channel_count");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    
    pTmp = (uintptr_t*)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    
    /* Correctly retrieve function pointer */
    func = (lsl_get_channel_count_t)(*pTmp);  // Correct pointer assignment
    
    /* get additional inputs */
    info = *(uintptr_t*)mxGetData(prhs[1]);  // Assumes StreamInfo is passed as a pointer
    
    /* invoke & return */
    channel_count = func((streaminfo)info);  // Cast to appropriate type
    plhs[0] = mxCreateDoubleScalar((double)channel_count);  // Create output
}

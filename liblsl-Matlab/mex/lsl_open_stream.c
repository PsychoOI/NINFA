#include "lsl_common.h"

/* function lsl_open_stream(LibHandle, Inlet, Timeout) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray *prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_open_stream_t func;
    /* input/output variables */
    uintptr_t in;
    double timeout;
    int errcode;

    if (nrhs != 3)
        mexErrMsgTxt("3 input argument(s) required."); 
    if (nlhs != 0)
        mexErrMsgTxt("0 output argument(s) required."); 

    /* get function handle */
    field = mxGetField(prhs[0], 0, "lsl_open_stream");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    pTmp = (uintptr_t*)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    
    // Cast properly
    func = (lsl_open_stream_t)(*pTmp); // Dereference directly

    /* get additional inputs */
    in = *(uintptr_t*)mxGetData(prhs[1]);
    
    if (mxGetClassID(prhs[2]) != mxDOUBLE_CLASS)
        mexErrMsgTxt("The timeout argument must be passed as a double.");
    timeout = *(double*)mxGetData(prhs[2]);
    
    /* invoke & return */
    func((void *)in, timeout, &errcode); // Pass the correct pointer type

    if (errcode) {
        switch (errcode) {
            case lsl_timeout_error:
                mexErrMsgIdAndTxt("lsl:timeout_error", "The operation timed out.");
                break;
            case lsl_lost_error:
                mexErrMsgIdAndTxt("lsl:lost_error", "The stream has been lost.");
                break;
            case lsl_internal_error:
                mexErrMsgIdAndTxt("lsl:internal_error", "An internal error occurred.");
                break;
            default:
                mexErrMsgIdAndTxt("lsl:unknown_error", "An unknown error occurred.");
                break;
        }
    }    
}

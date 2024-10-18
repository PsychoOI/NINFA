#include "lsl_common.h"

/* function [UID] = lsl_get_uid(LibHandle,StreamInfo) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray *prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_get_uid_t func;
    /* input/output variables */
    uintptr_t info;
    char *uid;

    /* Check the number of input and output arguments */
    if (nrhs != 2)
        mexErrMsgTxt("2 input argument(s) required.");
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument(s) required.");

    /* Get function handle */
    field = mxGetField(prhs[0], 0, "lsl_get_uid");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");

    /* Correctly assign the function pointer */
    func = (lsl_get_uid_t)(*pTmp);  // Dereference the function pointer correctly

    /* Get the additional inputs */
    info = *(uintptr_t *)mxGetData(prhs[1]);

    /* Invoke the function and return the result */
    uid = func((streaminfo)info);  // Ensure proper casting to the 'streaminfo' type

    /* Return the result as a MATLAB string */
    plhs[0] = mxCreateString(uid);
}

#include "lsl_common.h"

/* function lsl_have_consumers(LibHandle, Outlet) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray *prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_have_consumers_t func;
    /* input/output variables */
    uintptr_t out;
    int result;

    /* Validate the number of inputs/outputs */
    if (nrhs != 2)
        mexErrMsgTxt("2 input argument(s) required.");
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument required.");

    /* Retrieve the function handle */
    field = mxGetField(prhs[0], 0, "lsl_have_consumers");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");

    /* Correctly dereference and cast the function pointer */
    func = (lsl_have_consumers_t)(*pTmp);

    /* Get the outlet object */
    out = *(uintptr_t *)mxGetData(prhs[1]);

    /* Invoke the function with the outlet */
    result = func((outlet)out);

    /* Return the result as a numeric value */
    plhs[0] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
    *(int *)mxGetData(plhs[0]) = result;
}

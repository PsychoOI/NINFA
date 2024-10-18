#include "lsl_common.h"

/* function lsl_set_processing(LibHandle, inlet, processing_flags) */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
    /* Handle for the desired field */
    mxArray *field;
    /* Temp pointer for function handle */
    uintptr_t *pTmp;
    /* Function handle */
    lsl_set_postprocessing_t func;
    /* Input variables */
    uintptr_t in;
    int proc_flag; // Change this to int assuming processing_options_t is defined as int in your context.
    
    /* Check number of input and output arguments */
    if (nrhs != 3) {
        mexErrMsgTxt("3 input argument(s) required."); 
    }
    if (nlhs != 0) {
        mexErrMsgTxt("0 output argument(s) required."); 
    }
    
    /* Get function handle */
    field = mxGetField(prhs[0], 0, "lsl_set_postprocessing");
    if (!field) {
        mexErrMsgTxt("The field 'lsl_set_postprocessing' does not seem to exist.");
    }
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp || mxGetNumberOfElements(field) == 0) {
        mexErrMsgTxt("The field 'lsl_set_postprocessing' seems to be empty or invalid.");
    }
    func = (lsl_set_postprocessing_t)(*pTmp);  // Correctly dereference to get function pointer
    
    /* Get additional inputs */
    in = *(uintptr_t *)mxGetData(prhs[1]);
    if (mxGetClassID(prhs[2]) != mxDOUBLE_CLASS) {
        mexErrMsgTxt("The processing flag must be passed as a double.");
    }
    proc_flag = (int)*(double *)mxGetData(prhs[2]);  // Convert double to int
    
    /* Invoke function */
    func((void*)in, proc_flag);  // Pass the inlet and processing options
}

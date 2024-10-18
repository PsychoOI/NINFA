#include "lsl_common.h"

/* function [XML] = lsl_get_xml(LibHandle,StreamInfo) */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray *prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_get_xml_t func;
    /* input/output variables */
    uintptr_t info;
    char *xml;
    
    /* Validate the number of inputs/outputs */
    if (nrhs != 2)
        mexErrMsgTxt("2 input argument(s) required.");
    if (nlhs != 1)
        mexErrMsgTxt("1 output argument required.");
    
    /* Retrieve the function handle */
    field = mxGetField(prhs[0], 0, "lsl_get_xml");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    
    /* Correctly dereference and cast the function pointer */
    func = (lsl_get_xml_t)(*pTmp);
    
    /* Get the streaminfo object */
    info = *(uintptr_t *)mxGetData(prhs[1]);
    
    /* Invoke the function and retrieve the XML string */
    xml = func((streaminfo)info);
    
    /* Return the XML string as a MATLAB string */
    plhs[0] = mxCreateString(xml);
}

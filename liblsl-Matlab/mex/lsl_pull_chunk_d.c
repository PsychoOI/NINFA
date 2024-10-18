#include "lsl_common.h"
#include <string.h>

/* function [ChunkData, Timestamps] = lsl_pull_chunk_d(LibHandle, Inlet, NumChannels) */

/* node in a chain of samples */
typedef struct bufnode_t {
    struct bufnode_t *next;
    double *buffer;
    double timestamp;
} bufnode_t;

/* free the entire chain */
void free_chain(bufnode_t *node) {
    if (node != NULL) {
        free(node->buffer);
        free_chain(node->next);
        free(node);
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_pull_sample_d_t func;

    /* input variables */
    void *in; // Change to void* for inlet
    int numchannels, k;
    double timeout = 0.0;
    /* output variables */    
    int errcode = 0, numobtained = 0;
    /* buffer chain */    
    bufnode_t *head = NULL; // Initialize head to NULL
    bufnode_t **cur = &head; // Pointer to the current position
    /* iterates for copying the data */
    double *chunkptr;
    double *timestampptr;

    if (nrhs != 3)
        mexErrMsgTxt("3 input argument(s) required."); 
    if (nlhs < 1)
        mexErrMsgTxt("At least 1 output argument(s) required."); 
    if (nlhs > 2)
        mexErrMsgTxt("At most 2 output argument(s) required."); 
    
    /* get function handle */
    field = mxGetField(prhs[0], 0, "lsl_pull_sample_d");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    pTmp = (uintptr_t *)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    
    // Cast the function pointer correctly
    func = (lsl_pull_sample_d_t)(*pTmp);
    
    /* get additional inputs */
    in = (void *)*(uintptr_t *)mxGetData(prhs[1]); // Cast to void*
    if (mxGetClassID(prhs[2]) != mxDOUBLE_CLASS)
        mexErrMsgTxt("The numchannels argument must be passed as a double.");
    numchannels = (int)*(double *)mxGetData(prhs[2]);

    /* pull samples in a loop */
    while (1) {
        /* allocate buffer space */
        *cur = (bufnode_t *)malloc(sizeof(bufnode_t));
        if (*cur == NULL) { // Check for malloc failure
            free_chain(head);
            mexErrMsgTxt("Memory allocation failed.");
        }
        (*cur)->buffer = (double *)malloc(numchannels * sizeof(double));
        if ((*cur)->buffer == NULL) { // Check for malloc failure
            free_chain(head);
            mexErrMsgTxt("Memory allocation for buffer failed.");
        }
        (*cur)->next = NULL;
        /* retrieve sample */
        (*cur)->timestamp = func(in, (*cur)->buffer, numchannels, timeout, &errcode);
        if (errcode) {
            break;
        }
        if ((*cur)->timestamp == 0.0) {
            break; // Stop if no timestamp is returned
        }
        cur = &((*cur)->next);
        numobtained++;
    }

    if (errcode) {
        /* error: free and throw */
        free_chain(head);
        if (errcode == lsl_timeout_error)
            mexErrMsgIdAndTxt("lsl:timeout_error", "The operation timed out.");
        if (errcode == lsl_lost_error)
            mexErrMsgIdAndTxt("lsl:lost_error", "The stream has been lost.");
        if (errcode == lsl_internal_error)
            mexErrMsgIdAndTxt("lsl:internal_error", "An internal error occurred.");
        mexErrMsgIdAndTxt("lsl:unknown_error", "An unknown error occurred.");
    } else {
        /* no error: first alloc MATLAB arrays */
        plhs[0] = mxCreateNumericMatrix(numchannels, numobtained, mxDOUBLE_CLASS, mxREAL);
        plhs[1] = mxCreateNumericMatrix(1, numobtained, mxDOUBLE_CLASS, mxREAL);
        /* then copy over all content */
        chunkptr = (double *)mxGetData(plhs[0]);
        timestampptr = (double *)mxGetData(plhs[1]);
        cur = &head;
        for (k = 0; k < numobtained; k++, chunkptr += numchannels, timestampptr++) {
            memcpy(chunkptr, (*cur)->buffer, sizeof(double) * numchannels);
            *timestampptr = (*cur)->timestamp;
            cur = &((*cur)->next);
        }
        /* then free the chain */
        free_chain(head);
    }
}

/*
 * MATLAB Compiler: 4.16 (R2011b)
 * Date: Wed May 30 18:25:01 2012
 * Arguments: "-B" "macro_default" "-W" "lib:libmatpower_4_1" "-T" "link:lib"
 * "-d" "U:\work\MATLAB\c_dll\matpower_4_1\libmatpower_4_1\src" "-w"
 * "enable:specified_file_mismatch" "-w" "enable:repeated_file" "-w"
 * "enable:switch_ignored" "-w" "enable:missing_lib_sentinel" "-w"
 * "enable:demo_license" "-v" "U:\work\MATLAB\c_dll\matpower_4_1\loadflow.m"
 * "U:\work\MATLAB\c_dll\matpower_4_1\mdisplay.m" 
 */

#include <stdio.h>
#define EXPORTING_libmatpower_4_1 1
#include "libmatpower_4_1.h"

static HMCRINSTANCE _mcr_inst = NULL;


#if defined( _MSC_VER) || defined(__BORLANDC__) || defined(__WATCOMC__) || defined(__LCC__)
#ifdef __LCC__
#undef EXTERN_C
#endif
#include <windows.h>

static char path_to_dll[_MAX_PATH];

BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, void *pv)
{
    if (dwReason == DLL_PROCESS_ATTACH)
    {
        if (GetModuleFileName(hInstance, path_to_dll, _MAX_PATH) == 0)
            return FALSE;
    }
    else if (dwReason == DLL_PROCESS_DETACH)
    {
    }
    return TRUE;
}
#endif
#ifdef __cplusplus
extern "C" {
#endif

static int mclDefaultPrintHandler(const char *s)
{
  return mclWrite(1 /* stdout */, s, sizeof(char)*strlen(s));
}

#ifdef __cplusplus
} /* End extern "C" block */
#endif

#ifdef __cplusplus
extern "C" {
#endif

static int mclDefaultErrorHandler(const char *s)
{
  int written = 0;
  size_t len = 0;
  len = strlen(s);
  written = mclWrite(2 /* stderr */, s, sizeof(char)*len);
  if (len > 0 && s[ len-1 ] != '\n')
    written += mclWrite(2 /* stderr */, "\n", sizeof(char));
  return written;
}

#ifdef __cplusplus
} /* End extern "C" block */
#endif

/* This symbol is defined in shared libraries. Define it here
 * (to nothing) in case this isn't a shared library. 
 */
#ifndef LIB_libmatpower_4_1_C_API
#define LIB_libmatpower_4_1_C_API /* No special import/export declaration */
#endif

LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV libmatpower_4_1InitializeWithHandlers(
    mclOutputHandlerFcn error_handler,
    mclOutputHandlerFcn print_handler)
{
    int bResult = 0;
  if (_mcr_inst != NULL)
    return true;
  if (!mclmcrInitialize())
    return false;
  if (!GetModuleFileName(GetModuleHandle("libmatpower_4_1"), path_to_dll, _MAX_PATH))
    return false;
    {
        mclCtfStream ctfStream = 
            mclGetEmbeddedCtfStream(path_to_dll, 
                                    58234);
        if (ctfStream) {
            bResult = mclInitializeComponentInstanceEmbedded(   &_mcr_inst,
                                                                error_handler, 
                                                                print_handler,
                                                                ctfStream, 
                                                                58234);
            mclDestroyStream(ctfStream);
        } else {
            bResult = 0;
        }
    }  
    if (!bResult)
    return false;
  return true;
}

LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV libmatpower_4_1Initialize(void)
{
  return libmatpower_4_1InitializeWithHandlers(mclDefaultErrorHandler, 
                                               mclDefaultPrintHandler);
}

LIB_libmatpower_4_1_C_API 
void MW_CALL_CONV libmatpower_4_1Terminate(void)
{
  if (_mcr_inst != NULL)
    mclTerminateInstance(&_mcr_inst);
}

LIB_libmatpower_4_1_C_API 
long MW_CALL_CONV libmatpower_4_1GetMcrID() 
{
  return mclGetID(_mcr_inst);
}

LIB_libmatpower_4_1_C_API 
void MW_CALL_CONV libmatpower_4_1PrintStackTrace(void) 
{
  char** stackTrace;
  int stackDepth = mclGetStackTrace(&stackTrace);
  int i;
  for(i=0; i<stackDepth; i++)
  {
    mclWrite(2 /* stderr */, stackTrace[i], sizeof(char)*strlen(stackTrace[i]));
    mclWrite(2 /* stderr */, "\n", sizeof(char)*strlen("\n"));
  }
  mclFreeStackTrace(&stackTrace, stackDepth);
}


LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV mlxLoadflow(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{
  return mclFeval(_mcr_inst, "loadflow", nlhs, plhs, nrhs, prhs);
}

LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV mlxMdisplay(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{
  return mclFeval(_mcr_inst, "mdisplay", nlhs, plhs, nrhs, prhs);
}

LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV mlfLoadflow(int nargout, mxArray** baseMVA, mxArray** bus, mxArray** 
                              gen, mxArray** branch, mxArray** success, mxArray* 
                              baseMVAIn, mxArray* busIn, mxArray* genIn, mxArray* 
                              branchIn, mxArray* areasIn, mxArray* gencostIn, mxArray* 
                              qlim, mxArray* dc, mxArray* alg, mxArray* tol, mxArray* 
                              max_it)
{
  return mclMlfFeval(_mcr_inst, "loadflow", nargout, 5, 11, baseMVA, bus, gen, branch, success, baseMVAIn, busIn, genIn, branchIn, areasIn, gencostIn, qlim, dc, alg, tol, max_it);
}

LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV mlfMdisplay(mxArray* in)
{
  return mclMlfFeval(_mcr_inst, "mdisplay", 0, 0, 1, in);
}

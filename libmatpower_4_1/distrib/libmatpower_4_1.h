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

#ifndef __libmatpower_4_1_h
#define __libmatpower_4_1_h 1

#if defined(__cplusplus) && !defined(mclmcrrt_h) && defined(__linux__)
#  pragma implementation "mclmcrrt.h"
#endif
#include "mclmcrrt.h"
#ifdef __cplusplus
extern "C" {
#endif

#if defined(__SUNPRO_CC)
/* Solaris shared libraries use __global, rather than mapfiles
 * to define the API exported from a shared library. __global is
 * only necessary when building the library -- files including
 * this header file to use the library do not need the __global
 * declaration; hence the EXPORTING_<library> logic.
 */

#ifdef EXPORTING_libmatpower_4_1
#define PUBLIC_libmatpower_4_1_C_API __global
#else
#define PUBLIC_libmatpower_4_1_C_API /* No import statement needed. */
#endif

#define LIB_libmatpower_4_1_C_API PUBLIC_libmatpower_4_1_C_API

#elif defined(_HPUX_SOURCE)

#ifdef EXPORTING_libmatpower_4_1
#define PUBLIC_libmatpower_4_1_C_API __declspec(dllexport)
#else
#define PUBLIC_libmatpower_4_1_C_API __declspec(dllimport)
#endif

#define LIB_libmatpower_4_1_C_API PUBLIC_libmatpower_4_1_C_API


#else

#define LIB_libmatpower_4_1_C_API

#endif

/* This symbol is defined in shared libraries. Define it here
 * (to nothing) in case this isn't a shared library. 
 */
#ifndef LIB_libmatpower_4_1_C_API 
#define LIB_libmatpower_4_1_C_API /* No special import/export declaration */
#endif

extern LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV libmatpower_4_1InitializeWithHandlers(
       mclOutputHandlerFcn error_handler, 
       mclOutputHandlerFcn print_handler);

extern LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV libmatpower_4_1Initialize(void);

extern LIB_libmatpower_4_1_C_API 
void MW_CALL_CONV libmatpower_4_1Terminate(void);



extern LIB_libmatpower_4_1_C_API 
void MW_CALL_CONV libmatpower_4_1PrintStackTrace(void);

extern LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV mlxLoadflow(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[]);

extern LIB_libmatpower_4_1_C_API 
bool MW_CALL_CONV mlxMdisplay(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[]);

extern LIB_libmatpower_4_1_C_API 
long MW_CALL_CONV libmatpower_4_1GetMcrID();



extern LIB_libmatpower_4_1_C_API bool MW_CALL_CONV mlfLoadflow(int nargout, mxArray** baseMVA, mxArray** bus, mxArray** gen, mxArray** branch, mxArray** success, mxArray* baseMVAIn, mxArray* busIn, mxArray* genIn, mxArray* branchIn, mxArray* areasIn, mxArray* gencostIn, mxArray* qlim, mxArray* dc, mxArray* alg, mxArray* tol, mxArray* max_it);

extern LIB_libmatpower_4_1_C_API bool MW_CALL_CONV mlfMdisplay(mxArray* in);

#ifdef __cplusplus
}
#endif
#endif

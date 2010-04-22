
/* hgmrfm.h
 * 
 * Copyright (C) 2007 Havard Rue
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * The author's contact information:
 *
 *       H{\aa}vard Rue
 *       Department of Mathematical Sciences
 *       The Norwegian University of Science and Technology
 *       N-7491 Trondheim, Norway
 *       Voice: +47-7359-3533    URL  : http://www.math.ntnu.no/~hrue  
 *       Fax  : +47-7359-3524    Email: havard.rue@math.ntnu.no
 *
 * RCSId: $Id: hgmrfm.h,v 1.25 2009/01/15 09:17:52 hrue Exp $
 *
 */

/*!
  \file hgmrfm.h
  \brief Typedefs for \c hgmrfm.c
*/

#ifndef __GMRFLib_HGMRFM_H__
#define __GMRFLib_HGMRFM_H__

#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef __cplusplus
# define __BEGIN_DECLS extern "C" {
# define __END_DECLS }
#else
# define __BEGIN_DECLS					       /* empty */
# define __END_DECLS					       /* empty */
#endif

__BEGIN_DECLS

/* 
 * 
 */
    typedef struct {
	int n;
	int N;

	/*
	 * no longer needed 
	 */
	// double *logprec_unstruct;
	// double **logprec_unstruct_omp;

	int *idx_map_f;
	int *idx_map_beta;
	int *idx_map_lc;

	int nf;
	GMRFLib_Qfunc_tp **f_Qfunc;
	void **f_Qfunc_arg;
	GMRFLib_graph_tp **f_graph;

	GMRFLib_Qfunc_tp ***ff_Qfunc;			       /* interaction */
	void ***ff_Qfunc_arg;

	int nbeta;
	double **covariate;
	double *prior_precision;

	int nlc;
	double lc_precision;
	double **lc_w;

	GMRFLib_graph_tp *eta_graph;
	GMRFLib_tabulate_Qfunc_tp *eta_Q;

	GMRFLib_graph_tp *lc_graph;
	GMRFLib_tabulate_Qfunc_tp *lc_Q;
} GMRFLib_hgmrfm_arg_tp;

typedef struct {

	/**
	 * The graph for the hgmrf-model
	 */
	GMRFLib_graph_tp *graph;

	/**
	 * The Qfunction for the hgmrf-model
	 */
	GMRFLib_Qfunc_tp *Qfunc;

	/**
	 * The arguments to GMRFLib_hgmrfm_tp::Qfunc
	 */
	void *Qfunc_arg;

	/**
	 * Linear constraints for the hgmrf-model (if any).
	 */
	GMRFLib_constr_tp *constr;
} GMRFLib_hgmrfm_tp;

typedef enum {
	GMRFLib_HGMRFM_TP_ETA = 1,
	GMRFLib_HGMRFM_TP_F,
	GMRFLib_HGMRFM_TP_BETA,
	GMRFLib_HGMRFM_TP_LC,
	GMRFLib_HGMRFM_TP___VOID = -1
} GMRFLib_hgmrfm_type_types_tp;

typedef struct {
	GMRFLib_hgmrfm_type_types_tp tp;
	int idx;
	int tp_idx;
} GMRFLib_hgmrfm_type_tp;

int GMRFLib_init_hgmrfm(GMRFLib_hgmrfm_tp ** hgmrfm, int n, double *logprec_unstruct, double **logprec_unstruct_omp,
			int nf, int **c, double **w, GMRFLib_graph_tp ** f_graph, GMRFLib_Qfunc_tp ** f_Qfunc,
			void **f_Qfunc_arg, char *f_sumzero, GMRFLib_constr_tp ** f_constr,
			GMRFLib_Qfunc_tp *** ff_Qfunc, void ***ff_Qfunc_arg,
			int nbeta, double **covariate, double *prior_precision, int nlc, double **lc_w, double *lc_precision);
GMRFLib_hgmrfm_type_tp GMRFLib_hgmrfm_what_type(int node, GMRFLib_hgmrfm_arg_tp * a);
double GMRFLib_hgmrfm_Qfunc(int node, int nnode, void *arg);
int GMRFLib_free_hgmrfm(GMRFLib_hgmrfm_tp * hgmrfm);

__END_DECLS
#endif

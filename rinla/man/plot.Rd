%%
%% WARNING! DO NOT EDIT!
%% This file is automatically generated from plot.R
%%
 \name{plot.inla}
 \alias{plot.inla}
 \alias{inla.plot}
 \title{Default INLA plotting}
 \description{
   Takes am \code{inla} object produced by \code{inla} and plot the results
 }
 \usage{
 \method{plot}{inla}(x,
              plot.fixed.effects = TRUE,
              plot.lincomb = TRUE,
              plot.random.effects = TRUE,
              plot.hyperparameters = TRUE,
              plot.predictor = TRUE,
              plot.q = TRUE,
              plot.cpo = TRUE,
              single = FALSE,
              postscript = FALSE,
              pdf = FALSE,
              prefix = "inla.plots/figure-",
              ...)
 }
 \arguments{
   \item{x}{A fitted  \code{inla} object produced by \code{inla} }
   \item{plot.fixed.effects}{Boolean indicating if posterior marginals
     for the fixed effects in the model should be plotted }
   \item{plot.lincomb}{Boolean indicating if posterior marginals
     for the linear combinations should be plotted }
   \item{plot.random.effects}{Boolean indicating if posterior mean and quantiles
     for the random effects in the model should be plotted  }
   \item{plot.hyperparameters}{Boolean indicating if posterior marginals
     for the hyperparameters in the model should be plotted }
   \item{plot.predictor}{Boolean indicating if posterior mean and quantiles
     for the linear predictor in the model should be plotted }
   \item{plot.q}{Boolean indicating if precision matrix should be displayed}
   \item{plot.cpo}{Boolean indicating if CPO/PIT valuesshould be plotted}
   \item{single}{Boolean indicating if there should be more than one plot per page
                 (FALSE) or just one (TRUE)}
   \item{postscript}{Boolean indicating if postscript files should be produced instead}
   \item{pdf}{Boolean indicating if PDF files should be produced instead}
   \item{prefix}{The prefix for the created files. Additional numbering and suffix is added.}
   \item{...}{Additional arguments to \code{postscript()}, \code{pdf()} or \code{dev.new()}.}
 }
 \value{The return value is a list of the files created (if any).}
 \author{Havard Rue \email{hrue@math.ntnu.no} }
 \seealso{\code{\link{inla}}}
 \examples{
\dontrun{
result = inla(...)
plot(result)
plot(result, single=TRUE)
plot(result, single=TRUE, pdf=TRUE, paper = "a4")
   }
 }
 \keyword{plot}

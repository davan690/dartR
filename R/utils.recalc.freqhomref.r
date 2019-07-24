#' A utility script to recalculate the the frequency of the homozygous reference SNP by locus after some populations have been deleted
#'
#' The locus metadata supplied by DArT has FreqHomRef included,
#' but the frequency of the homozygous reference will change when some individuals are removed from the dataset. 
#' This script recalculates the FreqHomRef and places these recalculated values in the appropriate place in the genlight object.
#' Note that the frequency of the homozygote reference SNPS is calculated from the individuals that could be scored.
#'
#' @param x -- name of the genlight object containing the SNP data [required]
#' @param verbose -- verbosity: 0, silent or fatal errors; 1, begin and end; 2, progress log ; 3, progress and results summary; 5, full report [default 2]
#' @return The modified genlight object
#' @author Arthur Georges (Post to \url{https://groups.google.com/d/forum/dartr})
#' @seealso \code{utils.recalc.metrics} for recalculating all metrics, \code{utils.recalc.callrate} for recalculating CallRate,
#' \code{utils.recalc.avgpic} for recalculating AvgPIC, \code{utils.recalc.freqhomsnp} for recalculating frequency of homozygous alternate,
#' \code{utils.recalc.freqhet} for recalculating frequency of heterozygotes, \code{gl.recalc.maf} for recalculating minor allele frequency,
#' \code{gl.recalc.rdepth} for recalculating average read depth
#' @examples
#' #result <- utils.recalc.freqhomref(testset.gl)

utils.recalc.freqhomref <- function(x, verbose=2) {

# TIDY UP FILE SPECS

  funname <- match.call()[[1]]

# FLAG SCRIPT START

  if (verbose < 0 | verbose > 5){
    cat("  Warning: Parameter 'verbose' must be an integer between 0 [silent] and 5 [full report], set to 2\n")
    verbose <- 2
  }

  if (verbose > 0) {
    cat("Starting",funname,"\n")
  }

# STANDARD ERROR CHECKING
  
  if(class(x)!="genlight") {
    cat("  Fatal Error: genlight object required!\n"); stop("Execution terminated\n")
  }
  # Work around a bug in adegenet if genlight object is created by subsetting
      if (nLoc(x)!=nrow(x@other$loc.metrics)) { stop("The number of rows in the loc.metrics table does not match the number of loci in your genlight object!")  }
  # Set a population if none is specified (such as if the genlight object has been generated manually)
    if (is.null(pop(x)) | is.na(length(pop(x))) | length(pop(x)) <= 0) {
      if (verbose >= 2){ cat("  Population assignments not detected, individuals assigned to a single population labelled 'pop1'\n")}
      pop(x) <- array("pop1",dim = nInd(x))
      pop(x) <- as.factor(pop(x))
    }
  # Check for monomorphic loci
    tmp <- gl.filter.monomorphs(x,verbose=0)
    if ((nLoc(tmp) < nLoc(x)) & verbose >= 2) {cat("  Warning: genlight object contains monomorphic loci\n")}

# FUNCTION SPECIFIC ERROR CHECKING

  if (is.null(x@other$loc.metrics$FreqHomRef)) {
    x@other$loc.metrics$FreqHomRef <- array(NA,nLoc(x))
    if (verbose >= 3){
      cat("  Locus metric FreqHomRef does not exist, creating slot @other$loc.metrics$FreqHomRef\n")
    }
  }  

# DO THE JOB

     t <- as.matrix(x)
     if (verbose >= 2) {cat("  Recalculating locus metric freqHomRef\n")}
     x@other$loc.metrics$FreqHomRef <- colMeans(t==0, na.rm = T)
# FLAG SCRIPT END

  if (verbose > 0) {
    cat("Completed:",funname,"\n")
  }
   
   return(x)
}

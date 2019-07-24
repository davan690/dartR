#' A utility script to recalculate the the minor allele frequency by locus, typically after some populations have been deleted
#'
#' The locus metadata supplied by DArT does not have MAF included, so it is calculated and
#' added to the locus.metadata by this script. The minimum allele frequency will change when
#' some individuals are removed from the dataset. This script recalculates the MAF and 
#' places these recalculated values in the appropriate place in the genlight object.
#'
#' @param x -- name of the genlight object containing the SNP data [required]
#' @param verbose -- verbosity: 0, silent or fatal errors; 1, begin and end; 2, progress log ; 3, progress and results summary; 5, full report [default 2]
#' @return The modified genlight dataset
#' @author Arthur Georges (Post to \url{https://groups.google.com/d/forum/dartr})
#' @seealso \code{utils.recalc.metrics} for recalculating all metrics, \code{utils.recalc.callrate} for recalculating CallRate,
#' \code{utils.recalc.freqhomref} for recalculating frequency of homozygous reference, \code{utils.recalc.freqhomsnp} for recalculating frequency of homozygous alternate,
#' \code{utils.recalc.freqhet} for recalculating frequency of heterozygotes, \code{gl.recalc.avgpic} for recalculating AvgPIC,
#' \code{gl.recalc.rdepth} for recalculating average read depth
#' @examples
#' #f <- dartR:::utils.recalc.maf(testset.gl)


utils.recalc.maf <- function(x, verbose=2) {
  
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

  if (is.null(x@other$loc.metrics$maf)) {
    if (verbose >= 3){
      cat("  Locus metric maf does not exist, creating slot @other$loc.metrics$maf\n")
    }
    x@other$loc.metrics$maf <- array(NA,nLoc(x))
  }

# DO THE JOB

  if (verbose >= 2) {cat("  Recalculating FreqHoms and FreqHets\n")}
  
  x <- utils.recalc.freqhets(x,verbose=verbose)
  x <- utils.recalc.freqhomref(x,verbose=verbose)
  x <- utils.recalc.freqhomsnp(x,verbose=verbose)
  
  # Calculate and plot overall MAF
  
  if (verbose >= 2) {cat("  Recalculating Minor Allele Frequency (MAF)\n")}

  alf <- gl.alf(x)[,2]
  x@other$loc.metrics$maf <- ifelse(alf>0.5,1-alf, alf)
  
# FLAG SCRIPT END

  if (verbose > 0) {
    cat("Completed:",funname,"\n")
  }
  return(x)
}  

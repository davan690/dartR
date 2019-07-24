#' Report number of private alleles possessed by an individual of unknown provenance
#'
#' This script calculates the number of private alleles possessed by a focal individual of unknown
#' provenance when compared to a series of target populations.
#' 
#' A private allele is an allele possessed by the focal individual, but absent from the target population. It differs from a fixed allelic difference in that the focal individual
#' may be heterozygous, in which case can share one but not both of its alleles with the target population.
#'
#' @param x -- name of the input genlight object [required]
#' @param id -- identity label of the focal individual whose provenance is unknown [required]
#' @param nmin -- minimum sample size for a target population to be included in the analysis [default 10]
#' @param threshold -- retain those populations for which the focal individual has private alleles less or equal in number than the threshold [default 0]
#' @param verbose -- verbosity: 0, silent or fatal errors; 1, begin and end; 2, progress log ; 3, progress and results summary; 5, full report [default 2]
#' @return A genlight object containing the focal individual (assigned to population "unknown") and 
#' populations for which the focal individual is not distinctive (number of loci with private alleles less than or equal to thresold t.
#' @export
#' @author Arthur Georges (bugs? Post to \url{https://groups.google.com/d/forum/dartr})
#' @examples
#' # Test run with a focal individual from the Macleay River (EmmacMaclGeor)
#' x <- gl.report.pa(testset.gl, id="UC_00146", nmin=10, threshold=1, verbose=2)

# Last amended 3-Feb-19

gl.report.pa <- function (x, id, nmin=10, threshold=0, verbose=2) {
  
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


  # Set a population if none is specified (such as if the genlight object has been generated manually)
    if (is.null(pop(x)) | is.na(length(pop(x))) | length(pop(x)) <= 0) {
      if (verbose >= 2){ cat("  Population assignments not detected, individuals assigned to a single population labelled 'pop1'\n")}
      pop(x) <- array("pop1",dim = nInd(x))
      pop(x) <- as.factor(pop(x))
    }

  # Check for monomorphic loci
    tmp <- gl.filter.monomorphs(x, verbose=0)
    if ((nLoc(tmp) < nLoc(x)) & verbose >= 2) {cat("  Warning: genlight object contains monomorphic loci\n")}

# FUNCTION SPECIFIC ERROR CHECKING

  test <- id%in%indNames(x)
  if (!all(test,na.rm=FALSE)) {
    cat("Fatal Error: nominated focal individual (of unknown provenance) is not present in the dataset!\n"); stop("Execution terminated\n")
  }
  if (nmin <=0){
    cat("    Warning: the minimum size of the target population must be greater than zero, set to 10\n")
    nmin <- 10
  }
  if (threshold < 0){
    cat("    Warning: the threshold for private alleles must be non-negative, set to 0\n")
    threshold <- 0
  }

# DO THE JOB

# Set a recommended minimum population size
  hard.min <- 10

# Assign the unknown individual to population 'unknown'
  vec <- as.vector(pop(x))
  vec[indNames(x)==id] <- "unknown"
  pop(x) <- as.factor(vec)
  
# Split the genlight object into one containing the unknown and one containing the remainding populations  
  unknowns <- x[pop(x)=="unknown",]
  knowns <- x[pop(x)!="unknown",]
  
# Remove all known populations with less than nmin individuals
  pop.keep <- levels(pop(knowns))[table(pop(knowns)) >= nmin]
  if (verbose >=2) {cat("  Retaining",length(pop.keep),"populations with sample size greater than or equal to",nmin,":",pop.keep,"\n\n")}
  pop.toss <- levels(pop(knowns))[table(pop(knowns)) < nmin]
  if (verbose >=2) {cat("  Discarding",length(pop.toss),"populations with sample size less than",nmin,":",pop.toss,"\n\n")}

  knowns <- knowns[pop(knowns) %in% pop.keep]

# Warn of populations retained with sizes less than the hard wired miniumum    
  pop.warn <- levels(pop(knowns))[table(pop(knowns)) < hard.min]
  if (length(pop.warn >= 1)) {
    if (verbose >=1) {cat("  Warning: Some retained populations have sample sizes less than",hard.min,":",pop.warn,"\n")}
    if (verbose >=1) {cat("    Substantial risk of private alleles arising as sampling error\n\n")}
  }  

# Report number of focal individuals (1) and number of target populations  
  n <- length(pop(unknowns))
  N <- length(levels(pop(knowns)))
  if (n != 1) {
    if (verbose >=0) {
      cat("  Fatal Error: Number of unknown focal individuals > 1; population label 'unknown' already in use\n"); stop("Terminating execution")
    }  
  }
  if (verbose >=2) {cat("  Assigning",n,"unknown individual(s) to",N,"target populations\n")}
  

# CALCULATE NUMBER OF LOCI WITH PRIVATE ALLELES
  
  # For each unknown individual
    for (i in 1:n) {
    # Grab the genotype of the unknown individual i
      unknown.ind <- as.matrix(unknowns[i])
    # Compare with each population
      count <- rep(0, N)
      count.NA <- rep(0, N)
      
      for (j in 1:N) {
        # Grab the genotypes for the known population j    
          known.pop <- as.matrix(knowns[pop(knowns)==levels(pop(knowns))[j]])
          
        # For each locus, count the number of non-private alleles  
          for (k in 1:nLoc(x)) {
            # Check to see if the unknown genotype is missing at locus k
              if (is.na(unknown.ind[k])) {
                count.NA[j] <- count.NA[j] + 1
              } else {  
                # Count the number of private alleles for each of unknown genotype 0,1,2
                  # Where the unknown focal individual is homozygous reference allele [aa]
                  if (unknown.ind[k]==0) {
                    # If all individuals in the target population are bb [not aa or ab] then focal individual has private allele [a]
                    if ( all(known.pop[,k]==2, na.rm=TRUE) )  { count[j] <- count[j] + 1}
                  }
                  # Where the unknown focal individual is homozygous for the alternate allele [bb]
                  if (unknown.ind[k]==2) {
                    # If all individuals in the target population are aa [not bb or ab] then focal individual has private allele [b]
                    if ( all(known.pop[,k]==0, na.rm=TRUE) ) { count[j] <- count[j] + 1}
                  }
                  # Where the unknown focal individual is heterozgous [ab]
                  if (unknown.ind[k]==1) {
                    # If all individuals in the target population are aa, then [b] is private or if bb, then [a] is private
                    if ( (all(known.pop[,k]==0, na.rm=TRUE) ) || (all(known.pop[,k]==2, na.rm=TRUE) ) ) { count[j] <- count[j] + 1}
                  }
              }
          }
      }

      # Print out results 

      if (verbose >=3) {
        cat("  Unknown individual:",id,"\n")
        cat("  Total number of SNP loci: ",nLoc(x),"\n\n")
        cat("  Table showing number of loci with private alleles\n")
        for (m in levels(as.factor(count))) {
          cat("   ",m,levels(pop(knowns))[count==m],"\n")
        } 
        cat("\n")
      }
  }    
      # Save the data in a new gl object

        index <- ((pop(x) %in% levels(pop(knowns))[count<=threshold]) | (as.character(pop(x)) == "unknown"))
        gl <- x[index,]
        gl <- gl.filter.monomorphs(gl, verbose=0)
        if (verbose >= 2) {
          if (threshold == 0) {
            cat("  Data retained for the unknown individual and remaining candidate source populations (zero loci with private alleles)\n")
            cat("  ",levels(pop(gl)),"\n\n")
          } else {
            cat("  Data retained for the unknown individual and remaining candidate source populations (",threshold,"or less loci with private alleles)\n")
            cat("  ",levels(pop(gl)),"\n\n")
          }
        }
  
# FLAG SCRIPT END

  if (verbose > 0) {
    cat("Completed:",funname,"\n")
  }
  
  return(gl)
  
}

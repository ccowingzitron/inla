##!\name{debug.graph}
##!\alias{debug.graph}
##!\alias{inla.debug.graph}
##!\title{Debug a graph-file}
##!\description{Debug a graph spesification, by checking the spesification along the way and signal an error if required."}
##!\usage{inla.debug.graph(graph.file)}
##!\arguments{
##!    \item{graph.file}{The filename of the graph.}
##!}
##!\value{
##! If an error is found, then an error message is shows, otherwise the graph-object returned by
##! \code{inla.read.graph()} is returned.
##!}
##!\author{Havard Rue \email{hrue@math.ntnu.no}}
##!\seealso{inla.read.graph}
##!\examples{
##!cat("2 1 1 2 2 1 1\n", file="g.dat")
##!g = inla.debug.graph("g.dat")
##!}

`inla.debug.graph` = function(graph.file) {

    ## read a graph with verbose output and try to detect any errors
    ## in the spesification along the way. This is ment as a tool to
    ## detect errors in the graph spesification only.

    stopifnot(file.exists(graph.file))

    xx = readLines(graph.file, encoding = "utf-8")
    
    cat("\n")
    cat("* File [", graph.file, "] consists of ", length(xx), " lines.\n", sep="")

    ## remove lines starting with '#'
    for(i in 1:length(xx)) {
        xx[i] = gsub("[ \t]+", " ", xx[i])
        xx[i] = gsub("/#.*/", "", xx[i])
        if (length(grep("/^[ \t]*$/", xx[i])) > 0) {
            xx[i] = NA
        }
    }
    xx = xx[!is.na(xx)]
    cat("* Number of lines left after removing empty lines:", length(xx), "\n")

    to.ints = function(text) {
        return (as.integer(unlist(sapply(text, function(x) strsplit(x, " ")))))
    }
    
    N = to.ints(xx[1])
    stopifnot(N > 0)

    cat("* Size of the graph is N=", N, "\n")

    for(i in 2:length(xx)) {
        cat("* Read line", i, "...")

        x = to.ints(xx[i])
        cat("node =", x[1], " number.of.neigbours=", x[2])
        check = (x[2] + 2L == length(x))
        if (!check) {
            cat("\n*** ERROR IN THIS LINE: x = ", x, "\n")
            stop("Number of neigbours  (x[2]) does not correspond to the number of elements in that line")
        }
        
        check = all(sapply(x[-2], function(ii, N) return (ii >= 1L & ii <= N), N=N))
        if (!check) {
            cat("\n*** ERROR IN THIS LINE: x = ", x, "\n")
            if (min(x[-2]) == 0L) {
                stop("Minimum node is 0, which is not/no longer, allowed.")
            } else {
                stop("One of more of the nodes are (x[-2]) outside the legal range: [1, ...,", N, "]\n")
            }
        }
        cat("  ok\n")
    }

    cat("\n")
    cat("\n")
    cat("* I will now try to read the graph properly using inla.read.graph().\n")
    cat("* If there are any errors in the following, then recall\n")
    cat("* that the numbering for lines and nodes, are 0-based (and NOT 1-based)!\n")

    return  (inla.read.graph(graph.file))
}
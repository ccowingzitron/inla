inla.dBind = function(...)
{
    A = list(...)
    if (length(A)<1)
        return(NULL)
    if (length(A)==1)
        return(A[[1]])
    B = A[[1]]
    for (k in 2:length(A)) {
        B = (rBind(cBind(B, Matrix(0, nrow(B), ncol(A[[k]]))),
                   cBind(Matrix(0, nrow(A[[k]]), ncol(B)), A[[k]])))
    }
    return(B)
}

inla.extract.el = function(M, ...)
{
    if (is.null(M))
        return(NULL)
    UseMethod("inla.extract.el", M)
}

inla.regex.match =  function(x, match) {
    return(strsplit(x, match)[[1]][1]=="")
}

inla.extract.el.matrix = function(M, match, by.row=TRUE)
{
    if (by.row) {
        return(M[sapply(rownames(M), inla.regex.match, match=match),,drop=FALSE])
    } else {
        return(M[,sapply(colnames(M), inla.regex.match, match=match),drop=FALSE])
    }
}

inla.extract.el.data.frame = function(M, match, by.row=TRUE)
{
    if (by.row) {
        return(M[sapply(rownames(M), inla.regex.match, match=match),,drop=FALSE])
    } else {
        return(M[,sapply(colnames(M), inla.regex.match, match=match),drop=FALSE])
    }
}

inla.extract.el.list = function(M, match)
{
    return(M[sapply(names(M), inla.regex.match, match=match)])
}



inla.spde.homogenise_B_matrix = function(B, n.spde, n.theta)
{
    if (!is.numeric(B))
        stop("B matrix must be numeric.")
    if (is.matrix(B)) {
        if ((nrow(B) != 1) && (nrow(B) != n.spde)) {
            stop(inla.paste(list("B matrix has",
                                 as.character(nrow(B)),
                                 "rows but should have 1 or",
                                 as.character(n.spde),
                                 sep=" ")))
        }
        if ((ncol(B) != 1) && (ncol(B) != 1+n.theta)) {
            stop(inla.paste(list("B matrix has",
                                 as.character(ncol(B)),
                                 "columns but should have 1 or",
                                 as.character(1+n.theta),
                                 sep=" ")))
        }
        if (ncol(B) == 1) {
            return(cbind(as.vector(B), matrix(0.0, n.spde, n.theta)))
        } else if (ncol(B) == 1+n.theta) {
            if (nrow(B) == 1) {
                return(matrix(as.vector(B), n.spde, 1+n.theta, byrow=TRUE))
            } else if (nrow(B) == n.spde) {
                return(B)
            }
        }
    } else { ## !is.matrix(B)
        if ((length(B) == 1) || (length(B) == n.spde)) {
            return(cbind(B, matrix(0.0, n.spde, n.theta)))
        } else if (length(B) == 1+n.theta) {
            return(matrix(B, n.spde, 1+n.theta, byrow=TRUE))
        } else {
            stop(inla.paste(list("Length of B vector is",
                                 as.character(length(B)),
                                 "but should be 1,",
                                 as.character(1+n.theta), "or",
                                 as.character(n.spde)),
                            sep=" "))
        }
    }
    stop(inla.paste(list("Unrecognised structure for B matrix"),
                    sep=" "))
}



inla.matern.cov = function(nu,kappa,x,d=1,corr=FALSE,theta, epsilon=1e-8)
{
    if (missing(theta)) { ## Ordinary Matern
        y = kappa*abs(x)
        if (corr) {
            ok = (y>=epsilon)
            if (nu<=0) {
                covariance = y*0
                covariance[!ok] = 1-y/epsilon
            } else {
                covariance = y*0
                covariance[ok] =
                    2^(1-nu)/gamma(nu) * (y[ok])^nu*besselK(y[ok], nu)
                if (any(!ok)) {
                    b = epsilon^(nu+1)*besselK(epsilon, nu-1)/
                        (gamma(nu)*2^(nu-1)-epsilon^nu*besselK(epsilon, nu))
                    yy = (y[!ok]/epsilon)^b
                    covariance[!ok] =
                        (1*(1-yy) +
                         (2^(1-nu)/gamma(nu)*
                          epsilon^nu*besselK(epsilon, nu))*yy)
                }
            }
            return(covariance)
        } else {
            ok = (y>=epsilon)
            covariance = y*0
            covariance[ok] =
                2^(1-nu)/gamma(nu+d/2)/(4*pi)^(d/2)/kappa^(2*nu)*
                    (y[ok])^nu*besselK(y[ok], nu)
            if (any(!ok)) {
                if (nu>0) { ## Regular Matern case
                    b = epsilon^(nu+1)*besselK(epsilon, nu-1)/
                        (gamma(nu)*2^(nu-1)-epsilon^nu*besselK(epsilon, nu))
                    yy = (y[!ok]/epsilon)^b
                    covariance[!ok] =
                        ((2^(1-nu)/gamma(nu+d/2)/(4*pi)^(d/2)/kappa^(2*nu))*
                         (gamma(nu)*2^(nu-1)*(1-yy) +
                          epsilon^nu*besselK(epsilon, nu)*yy))
                } else if (nu==0) { ## Limiting Matern case
                    g = 0.577215664901484 ## Euler's constant
                    covariance[!ok] =
                        2/gamma(d/2)/(4*pi)^(d/2)*
                            (-log(y[!ok]/2)-g)
                } else { ## (nu<0)
                    ## TODO: check this...
                    covariance[!ok] =
                        ((2^(1-nu)/gamma(nu+d/2)/(4*pi)^(d/2)/kappa^(2*nu)*
                          gamma(nu)*2^(nu-1))*(1-(y[!ok]/epsilon)) +
                         (2^(1-nu)/gamma(nu+d/2)/(4*pi)^(d/2)/kappa^(2*nu)*
                          epsilon^nu*besselK(epsilon, nu))*(y[!ok]/epsilon))
                }
            }
            return(covariance)
        }
    } else { ## Oscillating covariances
        y = abs(x)
        if (d>2L) {
            warning('Dimension > 2 not implemented for oscillating models.')
        }
        freq.max = 1000/max(y)
        freq.n = 10000
        w = seq(0,freq.max,length.out=freq.n)
        dw = w[2]-w[1]
        spec = 1/(2*pi)^d/(kappa^4+2*kappa^2*cos(pi*theta)*w^2+w^4)^((nu+d/2)/2)
       if (d==1L) {
            covariance = y*0+spec[1]*dw
        } else {
            covariance = y*0
        }
        for (k in 2:freq.n) {
            if (d==1L) {
                covariance = covariance+2*cos(y*w[k])*spec[k]*dw
            } else {
                covariance = covariance + w[k]*besselJ(y*w[k],0)*spec[k]*dw
            }
        }

        if (norm.corr) {
            noise.variance = 1/covariance[1]
        } else {
            noise.variance = 1
        }

        return(covariance*noise.variance)
    }
}


inla.matern.cov.s2 = function(nu,kappa,x,norm.corr=FALSE,theta=0)
{
    y = cos(abs(x))

    freq.max = 40L
    freq.n = freq.max+1L
    w = 0L:freq.max
    spec = 1/(kappa^4+2*kappa^2*cos(pi*theta)*w*(w+1)+w^2*(w+1)^2)^((nu+1)/2)
    leg = legendre.polynomials(freq.max)
    covariance = y*0
    for (k in 1:freq.n) {
        covariance = (covariance + (2*w[k]+1)/(4*pi)*spec[k]*
                      polynomial.values(leg[k],y)[[1]])
    }

    if (norm.corr) {
        noise.variance = 1/covariance[1]
    } else {
        noise.variance = 1
    }

    return(covariance*noise.variance)
}



inla.spde.models = function()
{
    types = c("spde1", "spde2")
    models = list()
    for (t in types) {
        models[[t]] =
            do.call(what=paste("inla.", t, ".models", sep=""),
                    args=list())
    }
    return(models)
}


inla.spde.sample = function(...)
{
    UseMethod("inla.spde.sample")
}

inla.spde.sample.default =
    function(precision, seed=NULL)
{
    return(inla.finn(precision,
                     seed=(inla.ifelse(is.null(seed),
                                       0L,
                                       seed)))$sample)
}

inla.spde.sample.inla.spde =
    function(spde, seed=NULL, ...)
{
    precision = inla.spde.precision(spde, ...)
    return(inla.spde.sample(precision, seed=seed))
}



inla.spde.precision = function(...)
{
    UseMethod("inla.spde.precision")
}

inla.spde.result = function(...)
{
    inla.require.inherits(list(...)[[1]], "inla", "First parameter")
    inla.require.inherits(list(...)[[2]], "character", "Second parameter")
    UseMethod("inla.spde.result", list(...)[[3]])
}







inla.spde.make.index = function(name, n.mesh, n.group=1, n.repl=1, n.field=n.mesh)
{
    if (!missing(n.field)) {
        warning("'n.field' is deprecated, please use 'n.mesh' instead.")
        if (missing(n.mesh) || is.null(n.mesh))
            n.mesh = n.field
    }
    name.group = paste(name, ".group", sep="")
    name.repl = paste(name, ".repl", sep="")
    out = list()
    out[[name]]       = rep(rep(1:n.mesh, times=n.group), times=n.repl)
    out[[name.group]] = rep(rep(1:n.group, each=n.field), times=n.repl)
    out[[name.repl]]  = rep(1:n.repl, each=n.field*n.group)
    return(out)
}

inla.spde.make.A =
    function(mesh = NULL,
             loc = NULL,
             index = NULL,
             group = NULL,
             repl = 1L,
             n.mesh = NULL,
             n.group = max(group),
             n.repl = max(repl),
             group.mesh = NULL,
             group.method = c("nearest", "S0", "S1"))
{
    if (is.null(mesh)) {
        if (is.null(n.mesh))
            stop("At least one of 'mesh' and 'n.mesh' must be specified.")
    } else {
        inla.require.inherits(mesh, c("inla.mesh", "inla.mesh.1d"), "'mesh'")
        n.mesh = mesh$n
    }
    if (!is.null(group.mesh)) {
        inla.require.inherits(mesh, "inla.mesh.1d", "'mesh'")
    }
    group.method = match.arg(group.method)

    ## Handle loc and index input semantics:
    if (is.null(loc)) {
        A.loc = Diagonal(n.mesh, 1)
    } else {
        if (is.null(mesh))
            stop("'loc' specified but 'mesh' is NULL.")
        if (inherits(mesh, "inla.mesh.1d")) {
            A.loc = inla.mesh.1d.A(mesh, loc=loc, method="linear")
        } else {
            A.loc = inla.mesh.project(mesh, loc=loc)$A
        }
    }
    if (is.null(index)) {
        index = 1:nrow(A.loc)
    }
    ## Now 'index' points into the rows of 'A.loc'

    ## Handle group semantics:
    if (is.null(group.mesh)) {
        if (is.null(group))
            group = rep(1L, length(index))
        else if (length(group) == 1)
            group = rep(group, length(index))
        else if (length(group) != length(index))
            stop(paste("length(group) != length(index): ",
                       length(group), " != ", length(index),
                       sep=""))
    } else {
        n.group = group.mesh$n
        if (is.null(group))
            group = rep(mesh$loc[1], length(index))
        else if (length(group) == 1)
            group = rep(group, length(index))
        else if (length(group) != length(index))
            stop(paste("length(group) != length(index): ",
                       length(group), " != ", length(index),
                       sep=""))
        print(group)
        if (group.method=="nearest") {
            group.index =
                inla.mesh.1d.bary(group.mesh, loc=group, method="nearest")
            group = group.index$index[,1]
        } else {
            group.index =
                inla.mesh.1d.bary(group.mesh, loc=group, method="linear")
            if (group.method=="S0") {
                group = group.index$index[,1]
            }
        }
        print(group.index)
    }

    ## Handle repl semantics:
    if (is.null(repl))
        repl = rep(1, length(index))
    else if (length(repl) == 1)
        repl = rep(repl, length(index))
    else if (length(repl) != length(index))
        stop(paste("length(repl) != length(index): ",
                   length(repl), " != ", length(index),
                   sep=""))

    A.loc = inla.as.dgTMatrix(A.loc[index,,drop=FALSE])

    if (!is.null(group.mesh) && (group.method=="S1")) {
        return(sparseMatrix(i=(1L+c(A.loc@i, A.loc@i)),
                            j=(1L+c(A.loc@j+
                                    n.mesh*(group.index$index[,1]-1L)+
                                    n.mesh*n.group*(repl-1L),
                                    A.loc@j+
                                    n.mesh*(group.index$index[,2]-1L)+
                                    n.mesh*n.group*(repl-1L))),
                               x=c(A.loc@x*group.index$bary[,1],
                               A.loc@x*group.index$bary[,2]),
                            dims=c(length(index), n.mesh*n.group*n.repl)))
    } else {
        return(sparseMatrix(i=(1L+A.loc@i),
                            j=(1L+A.loc@j+
                               n.mesh*(group-1L)+
                               n.mesh*n.group*(repl-1L)),
                            x=A.loc@x,
                            dims=c(length(index), n.mesh*n.group*n.repl)))
    }
}


rbind.inla.data.stack.info = function(...)
{
    l = list(...)
    names.tmp = do.call(c, lapply(l, function(x) x$names))
    ncol.tmp = do.call(c, lapply(l, function(x) x$ncol))

    ncol = c()
    names = list()
    for (k in 1:length(names.tmp)) {
        name = names(names.tmp)[k]
        if (!is.null(names[[name]])) {
            if (!identical(names[[name]],
                           names.tmp[[k]])) {
                stop("Name mismatch.")
            }
        }
        names[[name]] = names.tmp[[k]]

        if (!is.null(as.list(ncol)[[name]])) {
            if (ncol[name] != ncol.tmp[[k]]) {
                stop("ncol mismatch.")
            }
        }
        ncol[name] = ncol.tmp[[k]]
    }

    external.names = names(names)
    internal.names = do.call(c, names)

    data =
        do.call(rbind,
                lapply(l, function(x) {
                    missing.names =
                        setdiff(internal.names,
                                do.call(c, x$names))
                    if (length(missing.names)>0) {
                        df = matrix(NA, x$nrow, length(missing.names))
                        colnames(df) = missing.names
                        return(cbind(x$data, df))
                    } else {
                        return(x$data)
                    }
                }))

    offset = 0
    index = list()
    for (k in 1:length(l)) {
        for (j in 1:length(l[[k]]$index)) {
            if (is.null(index[[names(l[[k]]$index)[j]]])) {
                index[[names(l[[k]]$index)[j]]] = l[[k]]$index[[j]] + offset
            } else {
                index[[names(l[[k]]$index)[j]]] =
                    c(index[[names(l[[k]]$index)[j]]],
                      l[[k]]$index[[j]] + offset)
            }
        }
        offset = offset + l[[k]]$nrow
    }

    info =
        list(data=data,
             nrow=nrow(data),
             ncol=ncol,
             names=names,
             index=index)
    class(info) = "inla.data.stack.info"

    return(info)
}


inla.stack = function(...)
{
    UseMethod("inla.stack")
}


inla.stack.default = function(data, A, effects, tag=NULL, strict=TRUE, ...)
{
    input.nrow = function(x) {
        return(inla.ifelse(is.matrix(x) || is(x, "Matrix"),
                           nrow(x),
                           inla.ifelse(is.data.frame(x),
                                       rep(nrow(x), ncol(x)),
                                       length(x))))
    }
    input.ncol = function(x) {
        return(inla.ifelse(is.matrix(x) || is(x, "Matrix"),
                           ncol(x),
                           inla.ifelse(is.data.frame(x),
                                       rep(1L, ncol(x)),
                                       1L)))
    }

    input.list.nrow = function(l) {
        if (is.data.frame(l))
            return(input.nrow(l))
        return(do.call(c, lapply(l, input.nrow)))
    }
    input.list.ncol = function(l) {
        if (is.data.frame(l))
            return(input.ncol(l))
        return(do.call(c, lapply(l, input.ncol)))
    }
    input.list.names = function(l) {
        if (is.data.frame(l))
            return(colnames(l))
        is.df = sapply(l, is.data.frame)
        name = vector("list", length(l))
        if (!is.null(names(l)))
            name[!is.df] =
                lapply(names(l)[!is.df],
                       function(x) list(x))
        else
            name[!is.df] = ""
        name[is.df] =
            lapply(l[is.df],
                   function(x) as.list(colnames(x)))

        return(do.call(c, name))
    }


    parse.input.list = function(l, n.A, error.tag, tag="") {
        ncol = input.list.ncol(l)
        nrow = input.list.nrow(l)
        names = input.list.names(l)
        if ((n.A>1) && any(nrow==1)) {
            for (k in which(nrow==1)) {
                if (ncol[k]==1) {
                    l[[k]] = rep(l[[k]], n.A)
                    nrow[k] = n.A
                } else {
                    stop(paste(error.tag,
                               "Automatic expansion only available for scalars.",
                               sep=""))
                }
            }
        }

        if (length(unique(c(names, ""))) < length(c(names, ""))) {
            stop(paste(error.tag,
                       "All variables must have unique names\n",
                       "Names: ('",
                       paste(names, collapse="', '", sep=""),
                       "')",
                       sep=""))
        }

        for (k in 1:length(names)) {
            if (ncol[k]==1) {
                names(names)[k] = names[[k]][[1]]
                names[[k]] = c(names[[k]][[1]])
            } else {
                names(names)[k] = names[[k]][[1]]
                names[[k]] = paste(names[[k]][[1]], ".", 1:ncol[k], sep="")
            }
        }

        names(nrow) = names(names)
        names(ncol) = names(names)

        data = as.data.frame(do.call(cbind, l))
        names(data) = do.call(c, names)
        nrow = nrow(data)
        if ((n.A>1) && (nrow != n.A)) {
            stop(paste(error.tag,
                       "Mismatching row sizes: ",
                       paste(nrow, collapse=",", sep=""),
                       ", n.A=", n.A,
                       sep=""))
        }

        index = list(1:nrow)
        if (!is.null(tag)) {
            names(index) = tag
        }

        info = list(data=data, nrow=nrow, ncol=ncol, names=names, index=index)
        class(info) = "inla.data.stack.info"

        return(info)
    }


    if (length(list(...))>0)
        warning(paste("Extra argument '", names(list(...)), "' ignored.",
                      collapse="\n", sep=""))

    ## Check if only a single block was specified.
    if (!is.list(A)) {
        A = list(A)
        effects = list(effects)
    }
    if (length(A) != length(effects))
        stop(paste("length(A)=", length(A),
                   " should be equal to length(effects)=", length(effects), sep=""))

    n.effects = length(effects)

    eff = list()
    for (k in 1:n.effects) {
        if (is.data.frame(effects[[k]])) {
            eff[[k]] =
                parse.input.list(list(effects[[k]]),
                                 input.ncol(A[[k]]),
                                 paste("Effect block ", k, ":\n", sep=""),
                                 tag)
        } else {
            if (!is.list(effects[[k]])) {
                tmp =
                    inla.ifelse(is.null(names(effects)[k]),
                                "",
                                names(effects)[k])
                effects[[k]] = list(effects[[k]])
                names(effects[[k]]) = tmp
            }
            eff[[k]] =
                parse.input.list(effects[[k]],
                                 input.ncol(A[[k]]),
                                 paste("Effect block ", k, ":\n", sep=""),
                                 tag)
        }
    }

    for (k in 1:n.effects) {
        if (is.vector(A[[k]])) {
            A[[k]] = Matrix(A[[k]], input.nrow(A[[k]]), 1)
        }
        if ((input.ncol(A[[k]])==1) && (eff[[k]]$nrow>1)) {
            if (input.nrow(A[[k]])!=1)
                stop(paste("ncol(A) does not match nrow(effect) for block ",
                           k, ": ",
                           input.ncol(A[[k]]), " != ", eff[[k]]$nrow, sep=""))
            A[[k]] = Diagonal(eff[[k]]$nrow, A[[k]][1,1])
        } else if (input.ncol(A[[k]]) != eff[[k]]$nrow) {
            stop(paste("ncol(A) does not match nrow(effect) for block ",
                       k, ": ",
                       input.ncol(A[[k]]), " != ", eff[[k]]$nrow, sep=""))
        }
    }
    if (length(unique(input.list.nrow(A)))>1) {
        stop(paste("Row count mismatch for A: ",
                   paste(input.list.nrow(A), collapse=",", sep=""),
                   sep=""))
    }
    A.nrow = nrow(A[[1]])
    A.ncol = input.list.ncol(A)

    data =
        parse.input.list(inla.ifelse(is.data.frame(data),
                                     list(data),
                                     data),
                         A.nrow,
                         paste("Effect block ", k, ":\n", sep=""),
                         tag)

    effects = do.call(rbind, eff)

    A.matrix = do.call(cBind, A)
    A.nrow = nrow(A.matrix)
    A.ncol = ncol(A.matrix)

    if (length(unique(c(names(data$names), names(effects$names)))) <
        length(c(names(data$names), names(effects$names)))) {
        stop(paste("Names for data and effects must not coincide.\n",
                   "Data names:   ",
                   paste(names(data$names), collapse=", ", sep=""),
                   "\n",
                   "Effect names: ",
                   paste(names(effects$names), collapse=", ", sep=""),
                   sep=""))
    }

    stack = list(A=A.matrix, data=data, effects=effects)
    class(stack) = "inla.data.stack"

    return(stack)

}

inla.stack.inla.data.stack = function(...)
{
    S.input = list(...)

    data =
        do.call(rbind,
                lapply(S.input, function(x) x$data))
    effects =
        do.call(rbind,
                lapply(S.input, function(x) x$effects))
    A =
        do.call(inla.dBind,
                lapply(S.input, function(x) x$A))

    S.output = list(A=A, data=data, effects=effects)
    class(S.output) = "inla.data.stack"

    if (length(unique(c(names(data$names), names(effects$names)))) <
        length(c(names(data$names), names(effects$names)))) {
        stop(paste("Names for data and effects must not coincide.\n",
                   "Data names:   ",
                   paste(names(data$names), collapse=", ", sep=""),
                   "\n",
                   "Effect names: ",
                   paste(names(effects$names), collapse=", ", sep=""),
                   sep=""))
    }

    return(S.output)
}






inla.stack.index = function(stack, tag)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")

    return(list(data=as.vector(do.call(c, stack$data$index[tag])),
                effects=as.vector(do.call(c, stack$effects$index[tag]))))
}

inla.stack.data = function(stack, ...)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")

    do.extract = function(dat) {
        inla.require.inherits(dat, "inla.data.stack.info", "'dat'")

        out =
            lapply(names(dat$names),
                   function(x) inla.ifelse(dat$ncol[[x]]>1,
                                       matrix(do.call(c,
                                                      dat$data[dat$names[[x]]]),
                                              dat$nrow,
                                              dat$ncol[[x]]),
                                           as.vector(as.matrix(dat$data[dat$names[[x]]]))))
        names(out) = names(dat$names)

        return(out)
    }

    return(c(do.extract(stack$data),
             do.extract(stack$effects),
             list(...)))
}

inla.stack.A = function(stack)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")
    return(stack$A)
}
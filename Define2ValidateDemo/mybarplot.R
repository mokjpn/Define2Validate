## modified from original barplot method of validation package, to set different labels on the bar.

mybarplot <- 
          function(height, ..., order_by = c("fails","passes","nNA")
                   , stack_by = c("fails","passes","nNA")
                   , topn=Inf, add_legend=TRUE, add_exprs=FALSE
                   , colors=c(fails = "#FC8D59",passes = "#91CF60", nNA = "#FFFFBF")
          ){
            order_by <- match.arg(order_by)
            stopifnot(topn>0,is.character(order_by),is.logical(add_legend),is.logical(add_exprs))
            
            # get calls & values from confrontation object
            calls <- sapply(height$._calls, deparse)
            names(calls) <- names(height$._value)
            val <- values(height,drop=FALSE)
            
            # reorder colors to match stacking order
            colors <- colors[stack_by]
            
            # defaults for some optional parameters
            args <- list(...)
            argn <- names(args)
            if ( !'xlab' %in% argn ) args$xlab <- 'Items'
            if ( !'main' %in% argn ) args$main <- deparse(height$._call[[3]])
            
            # values with different dimensionality are plotted in different row.
            par(mfrow=c(length(val),1), mai=c(0.5,4, 0.5, 0.5))
            
            # create plots, one row for each dimension structure
            out <- lapply(seq_along(val), function(i){
              y <- val[[i]]
              count <- cbind(
                nNA = colSums(is.na(y))
                , fails = colSums(!y,na.rm=TRUE)
                , passes = colSums(y,na.rm=TRUE)
              )
              labels <- calls[colnames(y)]
              
              # how to order
              I <- order(count[,order_by])
              count <- count[I,,drop=FALSE]
              labels <- labels[I]
              
              if ( topn < Inf ){
                I <- order(count[,order_by],decreasing=TRUE)
                I <- 1:nrow(count) %in% I[1:min(topn,length(I))]
                count <- count[I,,drop=FALSE]
                labels <- calls[[i]][I]
              }
              # one extra, spurious horizontal bar is plotted so the legend can be put inside the plot.
              # This is admittedly ugly, but it make sure that the legend position scales when the
              # plot is printed to other devices (without the hassle of doing everything in 'grid')
              if ( !'names.arg' %in% argn ) args$names.arg <- c(rownames(count),"")
              arglist <- list(
                height=t(rbind(count[,stack_by],x=0))
                , horiz=TRUE
                , border=NA
                , las=1
                , col=c(colors,'#FFFFFF')
              )
              # actual plot
              p = do.call(barplot,c(arglist,args))[seq_along(labels)]
              
              # Add labels & legend
              if (add_exprs) text(0.1,p,labels,pos=4)
              
              if(add_legend){ 
                legend('topright'
                       , legend = stack_by
                       , fill=colors
                       , border='black'
                       , bty='n'
                       , horiz=TRUE
                       #          , inset=c(0,-0.1)
                       #          , xpd = TRUE
                )
              }
              p
            })
            par(xpd=FALSE)
            invisible(out)
          }

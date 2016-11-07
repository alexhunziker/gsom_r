############
#predict.r
############

# More pseudocode than anything else

predict.gsom <- function(gsom_model, df, retaindata=FALSE){
  
  if(is.null(gsom_model$nodes$predict)) stop("Wrong input, use trained gsom model for dependent values.")
  
  # Normalizing the training or testdata (min/max) in order to balance the impact
  # of the different properties of the dataframe
  min <- gsom_model$norm_param$min
  max <- gsom_model$norm_param$max
  df <- as.matrix(df)
  df <- t(apply(df, 1, function(x){(x-min)/ifelse(max==min,1,(max-min))}))
  
  codes <- rep(0, times=nrow(df))
  ndist <- rep(0, times=nrow(df))
  freq <- rep(0, times=nrow(gsom_model$nodes$weight))
  
  outc = .C("map_data",
            plendf = as.integer(nrow(df)),
            lennd = as.integer(nrow(gsom_model$nodes$weight)),
            dim = as.integer(ncol(gsom_model$nodes$weight)),
            df = as.double(df),
            weights =as.double(as.matrix(gsom_model$nodes$weight)), 
            codes = as.double(codes),
            ndist = as.double(ndist),
            freq = as.double(freq)
  )
  
  dist <- outc$ndist
  code <- outc$codes
  code = matrix(code, ncol= 1)
  
  predict = data.frame(ncol=gsom_model$nodes$predict)
  for(i in (1:nrow(df))){
    predict[i,] = gsom_model$nodes$predict[code[i],]
  }
  #preditc = 0;
  
  gsom_mapped = list();
  gsom_mapped[["nodes"]] = gsom_model$nodes
  gsom_mapped[["nodes"]]$error = NULL
  gsom_mapped[["nodes"]]$freq = outc$freq
  gsom_mapped[["prediction"]] = data.frame(codes=code, dist=dist, predict=predict)
  gsom_mapped[["norm_param"]] = gsom_model$scale
  if(retaindata) gsom_mapped[["data"]] == df;
  
  class(gsom_mapped) = "gsom"
  
  return(gsom_mapped)
  
}
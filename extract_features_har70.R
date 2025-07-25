# https://archive.ics.uci.edu/dataset/780/har70


f.meanDif <- function(x){
  acum <- 0.0
  for(i in 2:length(x)){
    acum <- acum + (x[i] - x[i-1])
  }
  mean(acum)
}

movingAverage <- function(x, n){
  #applies moving average filter to x with window of size n
  N <- length(x); s <- numeric(length=N)
  for(i in n:N){s[i] <- sum(x[(i-n+1):i]) / n}
  for(i in 1:(n-1)){s[i] <- sum(x[i:(i+n-1)]) / n}
  return(s)
}

processUser <- function(path, id, w){

  # path: path to files.
  # w: window length.
  # id: user id to process.
    
  df <- read.csv(paste0(path,id,".csv"))
  
  #print(sort(unique(df$label)))
  
  #50 Hz
  # From the documentation, labels are:
  # 1: walking
  # 3: shuffling
  # 4: stairs (ascending)
  # 5: stairs (descending)
  # 6: standing
  # 7: sitting
  # 8: lying

  # Omit 4 and 5 since there are not so many instances
  # and some users did not perform those activities.
  labels <- c(1,3,6,7,8)
  userdata <- NULL
  
  for(l in labels){
    tmp <- df[df$label==l,]
    tmp$back_x <- movingAverage(tmp$back_x, 10)
    tmp$back_y <- movingAverage(tmp$back_y, 10)
    tmp$back_z <- movingAverage(tmp$back_z, 10)
    
    tmp$thigh_x <- movingAverage(tmp$thigh_x, 10)
    tmp$thigh_y <- movingAverage(tmp$thigh_y, 10)
    tmp$thigh_z <- movingAverage(tmp$thigh_z, 10)
    
    starts <- seq(1,nrow(tmp),w)
    starts <- starts[-length(starts)]
    
    for(i in starts){
      block <- tmp[i:(i+w-1), ]
      
      # Extract features for the first (back) sensor.
      meanX <- mean(block$back_x); meanY <- mean(block$back_y); meanZ <- mean(block$back_z)
      sdX <- sd(block$back_x); sdY <- sd(block$back_y); sdZ <- sd(block$back_z)
      
      if(sdX == 0 | sdY == 0 | sdZ == 0){
        break;
      }
      
      maxX <- max(block$back_x); maxY <- max(block$back_y); maxZ <- max(block$back_z)
      minX <- min(block$back_x); minY <- min(block$back_y); minZ <- min(block$back_z)
      corXY <- cor(block$back_x,block$back_y); corXZ <- cor(block$back_x,block$back_z); corYZ <- cor(block$back_y,block$back_z)
      magnitude <- sqrt(block$back_x^2 + block$back_y^2 + block$back_z^2)
      meanMagnitude <- mean(magnitude)
      sdMagnitude <- sd(magnitude)
      auc <- sum(magnitude)
      meanDif <- f.meanDif(magnitude)
      
      # Second sensor.
      meanX2 <- mean(block$thigh_x); meanY2 <- mean(block$thigh_y); meanZ2 <- mean(block$thigh_z)
      sdX2 <- sd(block$thigh_x); sdY2 <- sd(block$thigh_y); sdZ2 <- sd(block$thigh_z)
      
      if(sdX2 == 0 | sdY2 == 0 | sdZ2 == 0){
        break;
      }
      
      maxX2 <- max(block$thigh_x); maxY2 <- max(block$thigh_y); maxZ2 <- max(block$thigh_z)
      minX2 <- min(block$thigh_x); minY2 <- min(block$thigh_y); minZ2 <- min(block$thigh_z)
      corXY2 <- cor(block$thigh_x,block$thigh_y); corXZ2 <- cor(block$thigh_x,block$thigh_z); corYZ2 <- cor(block$thigh_y,block$thigh_z)
      
      magnitude2 <- sqrt(block$thigh_x^2 + block$thigh_y^2 + block$thigh_z^2)
      meanMagnitude2 <- mean(magnitude2)
      sdMagnitude2 <- sd(magnitude2)
      auc2 <- sum(magnitude2)
      meanDif2 <- f.meanDif(magnitude2)
      
      
      res <- data.frame(userid=as.integer(id), label=l, 
                        meanX=meanX, 
                        meanY=meanY, 
                        meanZ=meanZ,
                        sdX=sdX, 
                        sdY=sdY, 
                        sdZ=sdZ,
                        maxX=maxX,
                        maxY=maxY,
                        maxZ=maxZ,
                        minX=minX,
                        minY=minY,
                        minZ=minZ,
                        corXY=corXY,
                        corXZ=corXZ, 
                        corYZ=corYZ,
                        meanMagnitude=meanMagnitude,
                        sdMagnitude=sdMagnitude,
                        auc=auc, 
                        meanDif=meanDif, 
                        meanX2=meanX2,
                        meanY2=meanY2,
                        meanZ2=meanZ2, 
                        sdX2=sdX2,
                        sdY2=sdY2,
                        sdZ2=sdZ2,
                        maxX2=maxX2,
                        maxY2=maxY2,
                        maxZ2=maxZ2,
                        minX2=minX2,
                        minY2=minY2,
                        minZ2=minZ2,
                        corXY2=corXY2,
                        corXZ2=corXZ2,
                        corYZ2=corYZ2, 
                        meanMagnitude2=meanMagnitude2,
                        sdMagnitude2=sdMagnitude2,
                        auc2=auc2, 
                        meanDif2=meanDif2)
      
      userdata <- rbind(userdata, res)
    }
    
  }
  return(userdata)
}

processAll <- function(path, w){
  
  # w: window length.
  
  # Only select users that performed all activities (excluding stairs).
  # 518 did not perform all activities (missed 8).
  users <- c(501,502,503,504,505,506,507,
             508,509,510,511,512,513,514,515,516,517
)
  
  dataset <- NULL
  
  for(u in users){
    print(paste0("processing user: ", u))
    tmp <- processUser(path,u,w)
    dataset <- rbind(dataset,tmp)
  }
  
  dataset <- dataset[complete.cases(dataset),]
  
  return(dataset)
}

# Path where de .dat files are located.
rawPath <- "har70plus/"

# Process the dataset.
# Set window length w to 150 wich is equivalent to 3 seconds
# since the sampling rate is 59hz.
dataset <- processAll(rawPath, 150)

# map integer labels to strings.
dataset$label[dataset$label==1] <- "walking"
dataset$label[dataset$label==3] <- "shuffling"
#dataset$label[dataset$label==4] <- "ascending_stairs"
#dataset$label[dataset$label==5] <- "descending_stairs"
dataset$label[dataset$label==6] <- "standing"
dataset$label[dataset$label==7] <- "sitting"
dataset$label[dataset$label==8] <- "lying"

# Print some info about the generated dataset.
table(dataset$userid, dataset$label)

# Write resulting dataset.
write.csv(dataset, "data.csv", quote = F, row.names = F)


#### Check which users performed which activities ####
files <- list.files(rawPath)

for(f in files){
  curr <- read.csv(paste0(rawPath,f))
  print(f)
  print(sort(unique(curr$label)))
}

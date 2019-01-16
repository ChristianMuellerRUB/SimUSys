# cleanTweets.r

cleanTweets <- function(tweet){
  
  # remove html links
  tweet <- gsub("(f|ht) (tp) (s?) (://) (.*) [.|/] (.*)", " ", tweet)
  
  # remove retweets
  tweet <- gsub("(RT|via) ((?:\\b\\W*@\\w+)+)", " ", tweet)
  if (grepl(x = tweet, pattern = "RT")) tweet <- NA
  
  # remove hashtags
  tweet <- gsub("#\\w+", " ", tweet)
  
  # remove people
  tweet <- gsub("@\\w+", " ", tweet)
  
  # remove punctuations
  tweet <- gsub("[[:punct:]]", " ", tweet)
  
  # remove numbers
  tweet <- gsub("[[:digit:]]", " ", tweet)
  
  # remove spaces
  tweet <- gsub("[ \t]{2,}", " ", tweet)
  tweet <- gsub("^\\s+|\\s+$", "", tweet)
  
  return(tweet)
  
}

cleanTweetsAndRemoveNAs <- function(Tweets){
  
  # create containers for information on outsorted elements
  keeps <- c()
  removes <- c()
  
  TweetsCleaned <- sapply(Tweets, cleanTweets)
  
  # find invalid data
  naPos <- which(is.na(TweetsCleaned))
  if (length(naPos) > 0){
    removes <- c(removes, naPos)
  }
  dupPos <- which(duplicated(TweetsCleaned))
  if (length(dupPos) > 0){
    removes <- c(removes, dupPos)
  }
  names(removes) = NULL
  removes <- unique(removes)
  
  # find valid data
  keeps <- which(!(1:length(TweetsCleaned) %in% removes))
  names(keeps) = NULL
  
  # remove NAs
  if (length(keeps) > 0){
    TweetsCleaned <- TweetsCleaned[keeps]
  }
  
  # reset names
  names(TweetsCleaned) = NULL
  
  # remove duplicates
  dupPos <- which(duplicated(TweetsCleaned))
  if (length(dupPos) > 0){
    TweetsCleaned <- TweetsCleaned[-dupPos]
  }
  
  return(list(TweetsCleaned, keeps, removes))
  
}
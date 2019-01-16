# twitterDownload.r
# gets sentiment data from twitter

# user input
args <- commandArgs()
scriptPath <- args[5]
studyAreaFile <- args[6]
outLoc <- args[7]
lan <- args[8]

wd <- paste0(scriptPath, "/twitterData")
setwd(wd)

Sys.setenv(JAVA_HOME='C:\\Program Files\\Java\\jre1.8.0_161')

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
Sys.chmod(scriptPath, mode = "0777", use_umask = TRUE)
try(
  for (i in 1:2){
    if (!require("devtools", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("devtools", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("rjson", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rjson", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("bit64", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("bit64", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("httr", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("httr", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("twitteR", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("twitteR", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("plyr", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("plyr", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("stringr", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("stringr", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("ggplot2", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("ggplot2", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("XLConnectJars", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("XLConnectJars", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("XLConnect", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("XLConnect", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("sentiment", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install_github("aloth/sentiment/sentiment")
    if (!require("SnowballC", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("SnowballC", lib = paste(scriptPath, "SnowballC", sep = "/"))
    if (!require("RColorBrewer", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("RColorBrewer", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("wordcloud", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("wordcloud", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("sp", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("sp", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("treemap", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("treemap", lib = paste(scriptPath, "libraries", sep = "/"))
  }
, silent = T)

# prepare containers/paths
if (!dir.exists(outLoc)) dir.create(outLoc)

# load data from local storage if present
if (file.exists(paste0(outLoc, "/tweets_raw.r"))){
  tweets_raw <- readRDS(file = paste0(outLoc, "/tweets_raw.r"))
} else {

  # setup OAuth
  api_key <- "#"
  api_secret <- "#"
  access_token <- "#"
  access_token_secret <- "#"
  setup_twitter_oauth(api_key, api_secret, access_token, access_token_secret)
  
  # prepare study area
  studyArea_orig <- readOGR(dirname(studyAreaFile), strsplit(basename(studyAreaFile), ".", fixed = T)[[1]][1], useC = F)
  WGSproj <- CRS("+init=epsg:4326")
  UTMproj <- CRS("+init=epsg:25832")
  studyArea <- spTransform(studyArea_orig, WGSproj)
  studyArea_UTM <- spTransform(studyArea_orig, UTMproj)
  bbox <- studyArea@bbox
  lat <- round(median(bbox[2,]), digits = 4)
  lng <- round(median(bbox[1,]), digits = 4)
  temp <- studyArea_UTM@bbox[2,]
  temp <- (temp[2] - temp[1])/1000
  radius <- round((temp/100 * 20) + temp)
  loc <- paste0(lat, ",", lng, ",", radius, "km")
  
  # prepare date
  until <- unlist(str_split(Sys.time(), " "))[1]
  temp <- as.POSIXlt(as.Date(until))
  temp$year <- temp$year-5
  since <- as.character(as.Date(temp))
  
  # get tweets
  tweets_raw <- searchTwitter("twitter", n = 500000, geocode = loc)
  saveRDS(tweets_raw, file = paste0(outLoc, "/tweets_raw.r"))
}
  
  
# prepare tweet data
tweets_lat <- sapply(tweets_raw, function(x) x$getLatitude())
tweets_lng <- sapply(tweets_raw, function(x) x$getLongitude())
tweets_unclean <- sapply(tweets_raw, function(x) x$getText())
source(paste(scriptPath, "/cleenTweets.r", sep = ""))
cleanRes <- cleanTweetsAndRemoveNAs(tweets_unclean)
tweets <- cleanRes[[1]]
tweets_kept <- cleanRes[[2]]
tweets_removed <- cleanRes[[3]]

# loading dictionary
source(paste0(scriptPath, "/xlsxTocsv.r"))
xlsxTocsv("SentiWS_v1_8c/positiv.xlsx", "SentiWS_v1_8c/positiv.csv", "Tabelle1") 
xlsxTocsv("SentiWS_v1_8c/negativ.xlsx", "SentiWS_v1_8c/negativ.csv", "Tabelle1") 
SentiWSToRObj <- function(tablepath){
  temp <- read.table(tablepath, sep = ";", as.is = T)
  temp <- unlist(c(temp[,-(2:3)]))
  temp <- temp[-which(grepl(x = temp, pattern = "Col"))]
  temp <- unique(temp)
  names(temp) <- NULL
  return(temp)
}

opinion.lexicon.pos <- SentiWSToRObj("SentiWS_v1_8c/positiv.csv")
opinion.lexicon.neg <- SentiWSToRObj("SentiWS_v1_8c/negativ.csv")

# compute score (sentiment analysis A - naive algorithm)
source(paste(scriptPath, "/getSentimentScore.r", sep = ""))
simpleRes <- rep(NA, times = length(tweets))
try(simpleRes <- getSentimentScore(tweets, words.positive = opinion.lexicon.pos, words.negative = opinion.lexicon.neg), silent = T)

# plot 1
pdf(paste0(outLoc, "/twitter_plots.pdf"), paper = "a4")

try(hist(simpleRes$score, xlab = "Sentiment score", main = ""), silent = T)

### derive sentiments (sentiment analysis B - Naive Bayes)
# get packages
print("Loading R-Packages...")
if (!require("Rstem", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install_url("http://www.omegahat.net/Rstem/Rstem_0.4-1.tar.gz")
library(sentiment)

# compute polarity
tweetsClassPol <- classify_polarity(tweets, algorithm = "bayes")
onlyPol <- tweetsClassPol[,4]

# rearrange data
tweets_lat_kept <- rep("", times = length(tweets))
for (i in 1:length(tweets_kept)){
  newEnt <- tweets_lat[[tweets_kept[i]]]
  if (length(newEnt) > 0) tweets_lat_kept[i] <- tweets_lat[[tweets_kept[i]]]
}
tweets_lng_kept <- rep("", times = length(tweets))
for (i in 1:length(tweets_kept)){
  newEnt <- tweets_lng[[tweets_kept[i]]]
  if (length(newEnt) > 0) tweets_lng_kept[i] <- tweets_lng[[tweets_kept[i]]]
}

sentimentDF <- data.frame(text = tweets, polarity = onlyPol, pos_p = tweetsClassPol[,1], neg_p = tweetsClassPol[,2],
                          pos_neg_p = tweetsClassPol[,3], lat = tweets_lat_kept, lng = tweets_lng_kept,
                          simpleScore = simpleRes$score, stringsAsFactors = F)


# add categorical information on classification certainty
sentimentDF <- cbind(sentimentDF, ratio_01 = 0, ratio_10 = 0)
sentimentDF[which(sentimentDF[,"pos_neg_p"] >= 1.01), "ratio_01"] <- 1
sentimentDF[which(sentimentDF[,"pos_neg_p"] <= 0.99), "ratio_01"] <- 1
sentimentDF[which(sentimentDF[,"pos_neg_p"] >= 10), "ratio_10"] <- 1
sentimentDF[which(sentimentDF[,"pos_neg_p"] <= 0.1), "ratio_10"] <- 1

# add numerical information on polarity
sentimentDF <- cbind(sentimentDF, pos2 = 0, neg2 = 0, posMinNeg = 0)
sentimentDF[which(sentimentDF[,"polarity"] == "positive"), "pos2"] <- 1
sentimentDF[which(sentimentDF[,"polarity"] == "negative"), "neg2"] <- 1
sentimentDF[,"posMinNeg"] <- sentimentDF[,"pos2"] - sentimentDF[,"neg2"]


# save results to file
saveRDS(sentimentDF, file = paste0(outLoc, "/sentimentDF.r"))
write.table(sentimentDF, file = paste0(outLoc, "/sentimentDF.csv"), sep = ";", dec = ".", row.names = F)


# plot polarity
ggplot(sentimentDF, aes(x = polarity)) +
  geom_bar(aes(y = ..count.., fill = polarity)) +
  scale_fill_brewer(palette = "RdGy") +
  ggtitle("Sentiment Analysis of Twitter Tweets - Polarity") +
  theme(legend.position = 'right') +
  ylab("Number of Tweets") +
  xlab("Polarity categories")

# plot polarity without uncertain classifications
sentimentDF_certain <- sentimentDF[which(sentimentDF[,"ratio_10"] == 1),]
ggplot(sentimentDF_certain, aes(x = polarity)) +
  geom_bar(aes(y = ..count.., fill = polarity)) +
  scale_fill_brewer(palette = "Pastel1") +
  ggtitle("Sentiment Analysis of Twitter Tweets - Polarity (after removal of uncertain classifications)") +
  theme(legend.position = 'right') +
  ylab("Number of Tweets") +
  xlab("Polarity categories")


try({
  tweets2 <- tweets
  for (i in 1:length(tweets2)){
    tweets2[i] <- gsub(tweets2[i], pattern = "ü", replacement = "ue")
    tweets2[i] <- gsub(tweets2[i], pattern = "ä", replacement = "ae")
    tweets2[i] <- gsub(tweets2[i], pattern = "ö", replacement = "oe")
    tweets2[i] <- gsub(tweets2[i], pattern = "Ü", replacement = "Ue")
    tweets2[i] <- gsub(tweets2[i], pattern = "Ä", replacement = "Ae")
    tweets2[i] <- gsub(tweets2[i], pattern = "Ö", replacement = "Oe")
    tweets2[i] <- gsub(tweets2[i], pattern = "ß", replacement = "ss")
    tweets2[i] <- gsub(tweets2[i], pattern = "í", replacement = " ")
    tweets2[i] <- gsub(tweets2[i], pattern = "½", replacement = " ")
    tweets2[i] <- gsub(tweets2[i], pattern = "³", replacement = " ")
    tweets2[i] <- gsub(tweets2[i], pattern = "Â", replacement = " ")
  }
  docs <- Corpus(VectorSource(tweets2))
  inspect(docs)
  toSpace <- content_transformer(function (x , pattern ) gsub(pattern, " ", x))
  docs <- tm_map(docs, toSpace, "/")
  docs <- tm_map(docs, toSpace, "@")
  docs <- tm_map(docs, toSpace, "\\|")
  docs <- tm_map(docs, toSpace, "ucue")
  
  # Convert the text to lower case
  docs <- tm_map(docs, content_transformer(tolower))
  
  # Remove numbers
  docs <- tm_map(docs, removeNumbers)
  
  # Remove english common stopwords
  docs <- tm_map(docs, removeWords, stopwords("german"))
  
  # Remove your own stop word
  # specify your stopwords as a character vector
  docs <- tm_map(docs, removeWords, c("die", "der", "das", "und", "ist", "mit", "the", "ich", "auf", "https", "and", "heute",
                                      "amp", "you", "for", "mal", "this", "hold", "mehr", "schon", "dass", "geht",
                                      "fuer", "ueber", "morgen", "beim", "with", "unsere", "immer", "via", "have", "wer", "gibt", 
                                      "from", "uhr", "freeroll", "that", "ÑÐ", "kommt", "neue", "tag", "sagt", "are",
                                      "what", "wufkaur", "new", "all", "einfach", "endlich", "gerade", "get", "your", "our",
                                      "found", "about", "being", "full", "hill", "stehen", "bevor", "its", "otr", "thats",
                                      "vielleicht", "wochen", "gesehen", "rein", "laesst", "world", "stimmt", "uebrigens",
                                      "sobre", "mtl", "these", "looking", "cute", "nennt", "their", "erklaert", "come",
                                      "days", "want", "been", "yours", "wall", "after", "kennt", "much", "follow", "face",
                                      "paar", "monat", "del", "series", "time", "out", "back", "but", "sagen", "dabei",
                                      "koennen", "ede", "sieht", "wurde", "sehen", "woche", "waere", "know", "how", "just",
                                      "more", "kommen", "warum", "today", "muessen", "sea", "wuerde", "fast", "last", "watch",
                                      "too", "encErr", ""))
  
  # Remove punctuations
  docs <- tm_map(docs, removePunctuation)
  
  # Eliminate extra white spaces
  docs <- tm_map(docs, stripWhitespace)
  dtm <- TermDocumentMatrix(docs)
  v <- sort(rowSums(as.matrix(dtm)), decreasing=TRUE)
  d <- data.frame(word = names(v),freq=v)
  
  wordcloud(words = d$word, freq = d$freq, min.freq = 1,
            max.words = 50, random.order = FALSE, rot.per = 0.35, 
            colors=brewer.pal(8, "Dark2"))

}, silent = T)


# create spatial points
val1 <- which(sentimentDF[,"lat"] != "")
val2 <- which(sentimentDF[,"lng"] != "")
val <- c(val1, val2)
val <- unique(val)
dat <- sentimentDF[val,]
coords_x <- as.numeric(dat[,"lng"])
coords_y <- as.numeric(dat[,"lat"])
coords <- cbind(coords_x, coords_y)
sp_p <- SpatialPoints(coords, proj4string = CRS("+init=epsg:4326"))
sp_dat <- SpatialPointsDataFrame(coords, dat, proj4string = CRS("+init=epsg:4326"))

# write spatial points to file
writeOGR(sp_dat, dsn = outLoc, layer = "TwitterData_spatial",
         driver = 'ESRI Shapefile', overwrite_layer = T)
saveRDS(dat, file = paste0(outLoc, "/spatialData.r"))
write.table(dat, file = paste0(outLoc, "/spatialData.csv"), sep = ";", dec = ".", row.names = F)


# nested plot
allTweets <- length(tweets_kept) + length(tweets_removed)
afterDataClearup <- length(tweets_kept)
withoutUncertainClasses <- nrow(sentimentDF_certain)
nSpatial <- length(which(dat[,"ratio_10"] == 1))
# tm_dat_1 <- rep("all tweets", times = 4)
tm_dat_1 <- c(paste0("all\ndownloaded\ntweets\n(", allTweets, ")"),
              paste0("all\ndownloaded\ntweets\n(", allTweets, ")"),
              paste0("all\ndownloaded\ntweets\n(", allTweets, ")"),
              paste0("all\ndownloaded\ntweets\n(", allTweets, ")"),
              paste0("all\ndownloaded\ntweets\n(", allTweets, ")"))
tm_dat_2 <- c(paste0("dismissed\nduring\ndata clean-up\n(", allTweets - afterDataClearup, ")"),
              paste0("kept\nduring\ndata clean-up\n(", afterDataClearup, ")"),
              paste0("kept\nduring\ndata clean-up\n(", afterDataClearup, ")"),
              paste0("kept\nduring\ndata clean-up\n(", afterDataClearup, ")"),
              paste0("kept\nduring\ndata clean-up\n(", afterDataClearup, ")"))
tm_dat_3 <- c(paste0("uncertain\nclassification\n(", afterDataClearup - withoutUncertainClasses, ")"),
              paste0("uncertain\nclassification\n(", afterDataClearup - withoutUncertainClasses, ")"),
              paste0("'certain'\nclassification\n(", withoutUncertainClasses, ")"),
              paste0("'certain'\nclassification\n(", withoutUncertainClasses, ")"),
              paste0("'certain'\nclassification\n(", withoutUncertainClasses, ")"))
tm_dat_4 <- c(paste0("no spatial\ninformation\navailable\n(", withoutUncertainClasses - nSpatial, ")"),
              paste0("no spatial\ninformation\navailable\n(", withoutUncertainClasses - nSpatial, ")"),
              paste0("no spatial\ninformation\navailable\n(", withoutUncertainClasses - nSpatial, ")"),
              "",
              paste0("spatial\ninformation\available\n(", nSpatial, ")"))
tm_dat_5 <- c(allTweets - afterDataClearup,
              afterDataClearup - withoutUncertainClasses,
              withoutUncertainClasses - nSpatial,
              (withoutUncertainClasses * nSpatial)^0.5,
              nSpatial)
tm_dat_6 <- c("#d90057", "#ef7c29", "#f0c55d", "#f0c55d", "#00a28b")

tm_dat <- data.frame(allTweets = tm_dat_1, afterDataClearup = tm_dat_2, withoutUncertainClasses = tm_dat_3, nSpatial = tm_dat_4,
                     vSize = tm_dat_5, vColor = tm_dat_6)

treemap(tm_dat, index = c("allTweets", "afterDataClearup", "withoutUncertainClasses", "nSpatial"),
        vSize = "vSize", vColor = "vColor", type = "color", bg.labels = 30, border.lwds = 1, border.col = tm_dat_6,
        title = "Number of downloaded tweets with usable information for analysis")

dev.off()

write.table(tm_dat, file = paste0(outLoc, "/numbersOnData.csv"), sep = ";", dec = ".", row.names = F)



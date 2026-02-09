library(tidyverse)

arguments<-commandArgs(trailingOnly=T)

#pca <- read_table(arguments[1], col_names = FALSE)
pca <- read.table(arguments[1], header =  FALSE)
eigenval <- scan(arguments[2])

if(length(arguments)==0){

    print("Arguments have to be supplied: ")
    print("1. Plink PCA eigenvector file .eigenvec, 2. Plink PCA eigenvalue file .eigenval")
    q()
}

 pca <- pca[,-1]
 names(pca)[1] <- "ind"
 names(pca)[2:ncol(pca)] <- paste0("PC", 1:(ncol(pca)-1))
 spp <- rep(NA, length(pca$ind))

spp[grep("ACS", pca$ind)] <- "ACS"
spp[grep("PLCO", pca$ind)] <- "PLCO"
spp[grep("OSTE", pca$ind)] <- "OSTE"
spp[grep("CCSS", pca$ind)] <- "CCSS"
spp[grep("ES", pca$ind)] <- "ES"
spp[grep("NRSTS", pca$ind)] <- "NRSTS"
spp[grep("LC_LC", pca$ind)] <- "LC"
spp[grep("EAGLE", pca$ind)] <- "EAGLE"

loc <- rep(NA, length(pca$ind))
loc[grep("ACS", pca$ind)] <- "CONTROL"
loc[grep("PLCO", pca$ind)] <- "CONTROL"
loc[grep("OSTE", pca$ind)] <- "CASE"
loc[grep("CCSS", pca$ind)] <- "CASE"
loc[grep("ES", pca$ind)] <- "CASE"
loc[grep("NRSTS", pca$ind)] <- "CASE"
loc[grep("LC_LC", pca$ind)] <- "CASE"
loc[grep("EAGLE", pca$ind)] <- "CONTROL"
# combine - if you want to plot each in different colours
spp_loc <- paste0(spp, "_", loc)
pca <- as_tibble(data.frame(pca, spp, loc, spp_loc))

out = dirname(normalizePath(arguments[1]))
pdf(paste0(out,'/PercentHist.pdf'))
pve <- data.frame(PC = 1:20, pve = eigenval/sum(eigenval)*100)
a <- ggplot(pve, aes(PC, pve)) + geom_bar(stat = "identity")
a + ylab("Percentage variance explained") + theme_light()
dev.off()

pdf(paste0(out,'/PC1-PC2.pdf'))

cumsum(pve$pve)
b <- ggplot(pca, aes(PC1, PC2, col = spp, shape = loc)) + geom_point(size = 1)
b <- b + scale_colour_manual(values = c("red", "blue", "yellow", "orange","green","brown","purple","pink"))
b <- b + coord_equal() + theme_light()
#b <- b + expand_limits(x = -0.02, y = -0.02)
b <- b + coord_fixed() 
b <- b + theme(aspect.ratio=1)
b + xlab(paste0("PC1 (", signif(pve$pve[1], 3), "%)")) + ylab(paste0("PC2 (", signif(pve$pve[2], 3), "%)"))
dev.off()

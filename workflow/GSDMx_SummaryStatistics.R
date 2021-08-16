#! /usr/local/bin/Rscript

# ---
# title: "GSDMx Summary Statistics"
# author: "Matthew Leipner: ETH Zürich, D-BSSE"
# date: "28 April 2021"
# output: 
#   pdf_document:
#   latex_engine: xelatex
# fig_width: 7
# fig_height: 4
# toc: true
# ---

  
#```{r setup, include=FALSE,echo=FALSE}
knitr::opts_chunk$set(echo = F)

options(tinytex.verbose = TRUE)

library(tidyverse)
library(knitr)
library(ggthemes)
library(ggsignif)
library(ggsn)
library(cowplot)
library(extrafont)
library(R.matlab)
library(gridExtra)
library(grid)

options(warn=-1)
opts_chunk$set(tidy.opts=list(width.cutoff=80),tidy=TRUE)
opts_chunk$set(fig.lp = '')
if(is_latex_output()) {
  plot_default <- knit_hooks$get("plot")
  knit_hooks$set(plot = function(x, options) { 
    x <- c(plot_default(x, options), "\\vspace{40pt}")
  })
}

# Set up ggplot axis label theme
My_Theme = theme(
  axis.title.x=element_blank(),
  axis.text.x=element_blank(),
  axis.ticks.x=element_blank(),
  axis.title.y = element_text(size = 32,color = "black"),
  axis.text.y = element_text(size=42,color = "black"),
  panel.grid.major = element_blank(), 
  panel.grid.minor = element_blank(),
  panel.border = element_rect(colour = "black", fill=NA, size=4),
  panel.background = element_blank(),
  legend.position = "none")

ymarker_size = 38
ylabel_size = 38

#```



#```{r Data Import 1, echo=FALSE}
# DATA IMPORT
# Import matlab pore files
matlab_dir <- "./analysis/oligomer_data/"

#fileList <- list.files(matlab_dir,"\\.mat",recursive = T,full.names = T)

outdir <- "./analysis/R_Figures/"

dir.create(file.path(outdir), showWarnings = FALSE)

#```



#```{r Data Import, echo=FALSE}
# DATA IMPORT
# *** direct import of text files into dataframe
fileList <- list.files(matlab_dir,"\\.txt")

# Extract image labels
labelList <- sapply(strsplit(fileList,"\\_statsTable.txt"),'[',1)

df <- data.frame(matrix(ncol = 7, nrow = 0))
for(i in 1:length(fileList)){
  df <- read.delim(paste(matlab_dir,fileList[i],sep = ""),stringsAsFactors=FALSE) %>%
    {cbind((.),Image = labelList[i],stringsAsFactors=FALSE)} %>%
    {rbind(df,(.))}
}

# Get rid of accidental rows with all zeros
df <- df %>%
  dplyr::filter(Diameter != 0)

# Add transmembrane flag if depth < -1
df$Transmembrane <- df$DepthAbs <= -2.0

df$poreTypes[df$poreTypes == 2] <- "Ring"
df$poreTypes[df$poreTypes == 3] <- "Slit"
df$poreTypes[df$poreTypes == 4] <- "Arc"


#```

#```{r Height Distribution, echo=FALSE}

# Set up ggplot axis label theme
Distribution_Theme = theme(
  axis.title.x=element_text(size=32,color = "black",family="Helvetica"),
  axis.text.x=element_text(size=36,color = "black",family="Helvetica"),
  axis.title.y = element_text(size = 32,color = "black",family="Helvetica"),
  axis.text.y = element_text(size=36,color = "black",family="Helvetica"),
  panel.grid.major = element_blank(), 
  panel.grid.minor = element_blank(),
  panel.border = element_blank(),
  panel.background = element_blank(),
  axis.line = element_line(colour = "black",size=3),
  axis.ticks = element_line(colour = "black",size=3),
  legend.position = "none")

se <- function(x){
  std_error <- sd(x)/sqrt(sum(!is.na(x)))
  return(std_error)
}

df_height <- df %>% 
  group_by(poreTypes,Transmembrane) %>%
  summarize_at(vars(Height),funs(n(),Mean = mean,sd = sd,se = se))

df_height$poreTypes <- factor(df_height$poreTypes , levels = c("Arc","Slit","Ring"))
df_height$Transmembrane <- as.factor(df_height$Transmembrane)

df_diameter <- df %>% 
  group_by(poreTypes,Transmembrane) %>%
  summarize_at(vars(Diameter),funs(n(),Mean = mean,sd = sd,se = se))

df_major_axis <- df %>% 
  group_by(poreTypes,Transmembrane) %>%
  summarize_at(vars(MajorAxis),funs(n(),Mean = mean,sd = sd,se = se))


# Height above membrane
p_bar_height <- ggplot(df_height,aes(x=poreTypes,y=Mean,fill = Transmembrane)) +
  geom_bar(stat="identity",position="dodge",color="black",size=2,width = 0.5) +
  Distribution_Theme + 
  scale_fill_grey(start = 0.2, end = 0.5) +
  xlab("Oligomer shape") +
  ylab("Height (nm)") +
  theme(axis.text.y = element_text(size=ymarker_size),
        axis.title.y = element_text(size=ylabel_size)) +
  scale_y_continuous(limits = c(0,3.5), breaks=c(0,1,2,3), expand = c(0, 0)) +
  geom_errorbar(aes(ymin=Mean-sd, ymax=Mean+sd), width=.2, size=2,
                position=position_dodge(.5)) +
  theme(legend.position = c(.3, 0.93),
        #legend.direction="horizontal",
        legend.title=element_blank(),
        legend.text = element_text(size = 30),
        axis.line = element_line(colour = 'black', size = 2),
        plot.margin = margin(t=5,b=5,r=5, l=50)) +
  scale_fill_manual(name = "Transmembrane", 
                    values = c("gray34","gray69"),
                    labels = c("Pre-pore", "Pore"))

ggsave(filename = paste(outdir,"","Height_Means.png",sep=""),
       width = 15, height = 15,units = "cm")

# Height Distribution

# calculate group means
means_height <- df %>% 
  group_by(poreTypes) %>%
  summarize_at(vars(Height),funs(n(),Mean = mean,sd = sd,se = se))
means_height$Mean <- round(means_height$Mean,2)
means_height$sd <- round(means_height$sd,2)
means_height$se <- round(means_height$se,2)
means_height$label1 <- paste(means_height$Mean,"±",means_height$se,"nm")
means_height$label2 <- paste("n<",means_height$n,">",sep="")

# Make normal distribution based on data

library(tidyverse)

bw <- 0.2  # Bin width for histogram

df_plot <- df[,c('Height','poreTypes')] %>% 
  group_by(poreTypes) %>% 
  nest(Height) %>% 
  mutate(y = map(data, ~ dnorm(
    .$Height, mean = mean(.$Height), sd = sd(.$Height),
  )  * bw )) %>%
  unnest(data,y)

plot_list = list()
types <- c("Arc","Slit","Ring")
for(i in 1:3){
  ctype <- types[i]
  p <- df_plot %>%
    filter(poreTypes == ctype) %>%
    
    {ggplot((.),aes(x=Height,)) +
        Distribution_Theme +
        geom_histogram(aes(y=..density..*bw),
                       breaks = seq(1, 4, by = bw), color="black", fill="grey",size=2) +
        geom_line(aes(y = y),size=3) +
        xlab("Oligomer height (nm)") +
        ylab("Relative count") +
        theme(axis.text.y = element_text(size=ymarker_size),
              axis.title.y = element_text(size=ylabel_size)) +
        scale_x_continuous(limits = c(1,4), breaks=c(1.5,2.5,3.5), expand = c(0, 0)) +
        scale_y_continuous(limits = c(0,0.5), breaks=c(0,0.1,0.2,0.3,0.4), expand = c(0, 0)) +
        #facet_wrap( ~ poreTypes, ncol=3) +
        geom_text(aes(x = -Inf, y = Inf, label = poreTypes, group = poreTypes),
                  size = 12,
                  hjust = -0.5,
                  vjust = 1.4,
                  inherit.aes = FALSE) +
        geom_text(aes(x = Mean, y = Inf, label = label1, group = NULL),
                  data = filter(means_height,poreTypes ==ctype), 
                  size = 12,
                  hjust = 0.5,
                  vjust = 3,
                  inherit.aes = FALSE) +
        geom_text(aes(x = Inf, y = -Inf, label = label2, group = NULL),
                  data = filter(means_height,poreTypes ==ctype), 
                  size = 12,
                  hjust = 1.1,
                  vjust = -6,
                  inherit.aes = FALSE)
    }
  
  plot_list[[i]] = p
  
  ggsave(filename = paste(outdir,"","Height_Distribution_",types[i],".png",sep=""),
         width = 17 , height = 16,units = "cm")
}

plot_grid(plot_list[[1]], plot_list[[2]], plot_list[[3]], p_bar_height, nrow = 1)

ggsave(filename = paste(outdir,"","Height_Distribution_Composite.png",sep=""),
       width = 68 , height = 16,units = "cm")


# Save excel versions of data
print("Height Statistics")
kable(df_height)
print("Diameter Statistics")
kable(df_diameter)
write.csv(df_height,paste(outdir,"","Height_Stats.csv",sep=""))
write.csv(df_diameter,paste(outdir,"","Diameter_Stats.csv",sep=""))
write.csv(df_major_axis,paste(outdir,"","MajorAxis_Stats.csv",sep=""))
write.csv(df_major_axis,paste(outdir,"","MajorAxis_Stats_noOutliers.csv",sep=""))
write.csv(df,paste(outdir,"","All_Pores_Raw_Data.csv",sep=""))

## Plot Diameter of Rings

# calculate group means
means_diameter <- df %>% 
  group_by(poreTypes) %>%
  summarize_at(vars(Diameter),funs(n(),Mean = mean,sd = sd,se = se))
means_diameter$Mean <- round(means_diameter$Mean,2)
means_diameter$sd <- round(means_diameter$sd,2)
means_diameter$se <- round(means_diameter$se,2)
means_diameter$label1 <- paste(means_diameter$Mean,"±",means_diameter$se,"nm")
means_diameter$label2 <- paste("n<",means_diameter$n,">",sep="")

bw <- 2  # Bin width for histogram

df_plot_Diameter <- df[,c('Diameter','poreTypes')] %>% 
  group_by(poreTypes) %>% 
  nest(Diameter) %>% 
  mutate(y = map(data, ~ dnorm(
    .$Diameter, mean = mean(.$Diameter), sd = sd(.$Diameter),
  )  * bw )) %>%
  unnest(data,y)

p <- df_plot_Diameter %>%
  filter(poreTypes == "Ring") %>%
  
  {ggplot((.),aes(x=Diameter,)) +
      Distribution_Theme +
      geom_histogram(aes(y=..density..*bw),
                     breaks = seq(10, 36, by = bw), color="black", fill="grey",size=2) +
      geom_line(aes(y = y),size=3) +
      xlab("Ring diameter (nm)") +
      ylab("Relative count") +
      theme(axis.text.y = element_text(size=ymarker_size),
            axis.title.y = element_text(size=ylabel_size)) +
      scale_x_continuous(limits = c(10,36), breaks=c(15,20,25,30), expand = c(0, 0)) +
      scale_y_continuous(limits = c(0,0.5), breaks=c(0,0.1,0.2,0.3,0.4), expand = c(0, 0)) +
      #facet_wrap( ~ poreTypes, ncol=3) +
      geom_text(aes(x = Mean, y = Inf, label = label1, group = NULL),
                data = filter(means_diameter,poreTypes ==ctype), 
                size = 12,
                hjust = 0.5,
                vjust = 3,
                inherit.aes = FALSE) +
      geom_text(aes(x = Inf, y = -Inf, label = label2, group = NULL),
                data = filter(means_diameter,poreTypes ==ctype), 
                size = 12,
                hjust = 1.1,
                vjust = -6,
                inherit.aes = FALSE)
  }

p

ggsave(filename = paste(outdir,"","Ring_Diameter_Distribution.png",sep=""),
       width = 17 , height = 16,units = "cm")

# Major Axis Calculations

# calculate group means
means_major_axis <- df %>% 
  group_by(poreTypes) %>%
  summarize_at(vars(MajorAxis),funs(n(),Mean = mean,sd = sd,se = se,Min = min, Max = max))
means_major_axis$Mean <- round(means_major_axis$Mean,2)
means_major_axis$sd <- round(means_major_axis$sd,2)
means_major_axis$se <- round(means_major_axis$se,2)
means_major_axis$label1 <- paste(means_major_axis$Mean,"±",means_major_axis$se,"nm")
means_major_axis$label2 <- paste("n<",means_major_axis$n,">",sep="")

p_bar_majorAxis <- ggplot(df_major_axis,aes(x=poreTypes,y=Mean,fill = Transmembrane)) +
  geom_bar(stat="identity",position="dodge",color="black",size=2,width = 0.5) +
  Distribution_Theme + 
  scale_fill_grey(start = 0.2, end = 0.5) +
  xlab("Oligomer type") +
  ylab("Width (nm)") +
  theme(axis.text.y = element_text(size=ymarker_size),
        axis.title.y = element_text(size=ylabel_size)) +
  scale_y_continuous(limits = c(0,60), breaks=c(0,10,20,30,40,50), expand = c(0, 0)) +
  geom_errorbar(aes(ymin=Mean-sd, ymax=Mean+sd), width=.2, size=2,
                position=position_dodge(.5)) +
  theme(legend.position = c(.5, 0.95),
        #legend.direction="horizontal",
        legend.title=element_blank(),
        legend.text = element_text(size = 24)) +
  scale_fill_manual(name = "Transmembrane", 
                    values = c("gray34", "gray69"),
                    labels = c("Transmembrane", "non-Transmembrane"))

ggsave(filename = paste(outdir,"","Major_Axis_Means.png",sep=""),
       width = 15, height = 15,units = "cm")

bw <- 3  # Bin width for histogram

# Major Axis Districbutions
# calculate normal curve overlay
df_plot_major_axis <- df[,c('MajorAxis','poreTypes')] %>% 
  group_by(poreTypes) %>% 
  nest(MajorAxis) %>% 
  mutate(y = map(data, ~ dnorm(
    .$MajorAxis, mean = mean(na.omit(.$MajorAxis)), sd = sd(na.omit(.$MajorAxis)),
  )  * bw )) %>%
  unnest(data,y)


plot_list_majorAxis = list()
for(i in 1:3){
  ctype <- types[i]
  p <- df_plot_major_axis %>%
    filter(poreTypes == ctype) %>%
    
    {ggplot((.),aes(x=MajorAxis,)) +
        Distribution_Theme +
        geom_histogram(aes(y=..density..*bw),
                       breaks = seq(0, 60, by = bw), color="black", fill="grey",size=2) +
        geom_line(aes(y = y),size=3) +
        xlab("Width (nm)") +
        ylab("Relative count") +
        theme(axis.text.y = element_text(size=ymarker_size),
              axis.title.y = element_text(size=ylabel_size)) +
        scale_x_continuous(limits = c(15,65), breaks=c(20,30,40,50,60), expand = c(0, 0)) +
        scale_y_continuous(limits = c(0,0.52), breaks=c(0,0.1,0.2,0.3,0.4), expand = c(0, 0)) +
        #facet_wrap( ~ poreTypes, ncol=3) +
        geom_text(aes(x = -Inf, y = Inf, label = poreTypes, group = poreTypes),
                  size = 12,
                  hjust = -0.5,
                  vjust = 1.4,
                  inherit.aes = FALSE) +
        geom_text(aes(x = 40, y = Inf, label = label1, group = NULL),
                  data = filter(means_major_axis,poreTypes ==ctype), 
                  size = 12,
                  hjust = 0.5,
                  vjust = 3,
                  inherit.aes = FALSE) +
        geom_text(aes(x = Inf, y = -Inf, label = label2, group = NULL),
                  data = filter(means_major_axis,poreTypes ==ctype), 
                  size = 12,
                  hjust = 1.1,
                  vjust = -6,
                  inherit.aes = FALSE)
    }
  
  plot_list_majorAxis[[i]] = p
  
  ggsave(filename = paste(outdir,"","MajorAxis_Distribution_",types[i],".png",sep=""),
         width = 17 , height = 16,units = "cm")
}

plot_grid(plot_list_majorAxis[[1]], plot_list_majorAxis[[2]], plot_list_majorAxis[[3]], p_bar_height, nrow = 1)

ggsave(filename = paste(outdir,"","MajorAxis_Distribution_Composite.png",sep=""),
       width = 68 , height = 16,units = "cm")

# Major axis outlier detection
df_plot_major_axis <- df[,c('MajorAxis','poreTypes')]

outliers_arc <- df_plot_major_axis %>%
  filter(poreTypes == "Arc") %>%
  {boxplot.stats((.)$MajorAxis)$out}
outliers_ring <- df_plot_major_axis %>%
  filter(poreTypes == "Ring") %>%
  {boxplot.stats((.)$MajorAxis)$out}
outliers_slit <- df_plot_major_axis %>%
  filter(poreTypes == "Slit") %>%
  {boxplot.stats((.)$MajorAxis)$out}

outliers_arc_ind <- which(df_plot_major_axis$MajorAxis %in% c(outliers_arc))
outliers_ring_ind <- which(df_plot_major_axis$MajorAxis %in% c(outliers_ring))
outliers_slit_ind <- which(df_plot_major_axis$MajorAxis %in% c(outliers_slit))

outliers_all <- c(outliers_arc_ind,outliers_ring_ind,outliers_slit_ind)

df_plot_major_axis[outliers_all,]$MajorAxis <- NA

# Calculate summ
means_major_axis_nooutliers <- df[-outliers_all,] %>% 
  group_by(poreTypes) %>%
  summarize_at(vars(MajorAxis),funs(n(),Mean = mean,sd = sd,se = se,Min = min, Max = max))
means_major_axis_nooutliers$Mean <- round(means_major_axis_nooutliers$Mean,2)
means_major_axis_nooutliers$sd <- round(means_major_axis_nooutliers$sd,2)
means_major_axis_nooutliers$se <- round(means_major_axis_nooutliers$se,2)
means_major_axis_nooutliers$Excl_Outliers <- c(length(outliers_arc),length(outliers_ring),length(outliers_slit))
means_major_axis_nooutliers$label1 <- paste(means_major_axis_nooutliers$Mean,"±",means_major_axis_nooutliers$se,"nm")
means_major_axis_nooutliers$label2 <- paste("n<",means_major_axis_nooutliers$n,">",sep="")

# calculate normal curve overlay
df_plot_major_axis <- df_plot_major_axis %>% 
  group_by(poreTypes) %>% 
  nest(MajorAxis) %>% 
  mutate(y = map(data, ~ dnorm(
    .$MajorAxis, mean = mean(na.omit(.$MajorAxis)), sd = sd(na.omit(.$MajorAxis)),
  )  * bw )) %>%
  unnest(data,y)


plot_list_majorAxis_outlier = list()
for(i in 1:3){
  ctype <- types[i]
  p <- df_plot_major_axis %>%
    filter(poreTypes == ctype) %>%
    
    {ggplot((.),aes(x=MajorAxis,)) +
        Distribution_Theme +
        geom_histogram(aes(y=..density..*bw),
                       breaks = seq(0, 60, by = bw), color="black", fill="grey",size=2) +
        geom_line(aes(y = y),size=3) +
        xlab("Width (nm)") +
        scale_x_continuous(limits = c(15,65), breaks=c(20,30,40,50,60), expand = c(0, 0)) +
        theme(axis.line = element_line(colour = 'black', size = 2)) +
        #facet_wrap( ~ poreTypes, ncol=3) +
        geom_text(aes(x = -Inf, y = Inf, label = poreTypes, group = poreTypes),
                  size = 12,
                  hjust = -0.5,
                  vjust = 1.4,
                  inherit.aes = FALSE) +
        geom_text(aes(x = 40, y = Inf, label = label1, group = NULL),
                  data = filter(means_major_axis_nooutliers,poreTypes ==ctype), 
                  size = 12,
                  hjust = 0.5,
                  vjust = 3,
                  inherit.aes = FALSE) +
        geom_text(aes(x = Inf, y = -Inf, label = label2, group = NULL),
                  data = filter(means_major_axis_nooutliers,poreTypes ==ctype), 
                  size = 12,
                  hjust = 1.1,
                  vjust = -6,
                  inherit.aes = FALSE)
    }
  if(i == 1){
    p <- p +
      ylab("Relative count") +
      theme(axis.text.y = element_text(size=ymarker_size),
            axis.title.y = element_text(size=ylabel_size)) +
      scale_y_continuous(limits = c(0,0.52), breaks=c(0,0.1,0.2,0.3,0.4), expand = c(0, 0)) #+
    #theme(plot.margin = margin(t=5,b=5,r=0, l=32))
  }else if(i==2){
    p <- p +
      ylab("") +
      scale_y_continuous(limits = c(0,0.52), breaks=c(), expand = c(0, 0)) #+
    #theme(plot.margin = margin(t=5,b=5,r=0, l=0))
    
  }else{
    p <- p +
      ylab("") +
      scale_y_continuous(limits = c(0,0.52), breaks=c(), expand = c(0, 0)) #+
    #theme(plot.margin = margin(t=5,b=5,r=52, l=0))
  }
  
  plot_list_majorAxis_outlier[[i]] = p
  
  ggsave(filename = paste(outdir,"","MajorAxis_Distribution_OmitOutlier_",types[i],".png",sep=""),
         width = 17 , height = 16,units = "cm")
}

#plot_grid(plot_list_majorAxis_outlier[[1]], plot_list_majorAxis_outlier[[2]], plot_list_majorAxis_outlier[[3]], nrow = 1)
g <- arrangeGrob(plot_list_majorAxis_outlier[[1]], plot_list_majorAxis_outlier[[2]], plot_list_majorAxis_outlier[[3]], 
                 nrow = 1, padding = 1)
ggsave(g, filename = paste(outdir,"","MajorAxis_noOutlier_Distribution_Composite.png",sep=""),
       width = 68 , height = 16,units = "cm")

# Major Axis boxplots

ggplot(df_plot_major_axis,aes(x=poreTypes)) +
  Distribution_Theme +
  geom_boxplot(aes(y=MajorAxis), color="black", fill="grey",size=2,outlier.colour="red", outlier.shape=8,
               outlier.size=4) +
  ylab("Width (nm)") +
  scale_y_continuous(limits = c(20,60), expand = c(0, 0))

ggsave(filename = paste(outdir,"","MajorAxis_Histograms.png",sep=""),
       width = 17 , height = 16,units = "cm")


#```


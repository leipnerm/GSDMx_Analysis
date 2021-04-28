#!/bin/bash

# GSDMx Analysis Pipeline

########################################
# DONT CHANGE HERE, CHANGE CONFIG FILE #
########################################

#################################
# DO NOT CHANGE BELOW THIS LINE #
#################################

# Make sure MATLAB is executable from command line
export PATH=$PATH:/Applications/MATLAB_R2021a.app/bin

# Run MATLAB script
matlab -nodesktop workflow/GSDMx_Analysis.m

# Run R Summary Statistics after matlab processing
R --slave -e 'rmarkdown::render("workflow/GSDMx_SummaryStatistics.Rmd", "pdf_document")'

# Clean up working directory by moving all logs reports to logs folder
mkdir -p logs
mv *.out logs
mv *.log logs

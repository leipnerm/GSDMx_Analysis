# GSDMx AFM Image Analysis Pipeline

ETH Zurich, D-BSSE, Biophysics Laboratory
Matthew Leipner


# Table of contents

* [Introduction](#introduction)
* [Requirements](#requirements)
* [Installation](#installation)
* [USAGE](#usage)
* [Pipeline Overview](#pipeline-overview)
* [Output files](#output-files)
* [Acknowledgements](#acknowledgements)
* [License](#license)

# INTRODUCTION
A fully automated analysis pipeline to take unprocessed, raw AFM data of GSDMx proteins (ie. no flattening or adjustments of any sort) and fully characterize and classify individual oligomers, generate summary statistics by oligmer subtype (arc, ring, slit) and pre-pore/pore classification (transmembrane or not). Options for time-lapse tracking on individual oligomers to identify stages of pore development will also be made available (currently WIP).

# REQUIREMENTS
* MATLAB Toolboxes/Add-Ons
    * Parallel Computing Toolbox
    * MATLAB Report Generator
    * Image Processing Toolbox
    * Curve Fitting Toolbox
    * Computer Vision Toolbox
    * Statistics and Machine Learning Toolbox

* R Packages
    * tidyverse
    * knitr
    * ggthemes
    * ggsignif
    * ggsn
    * cowplot
    * extrafont
    * R.matlab

# INSTALLATION
1. Download package using the following command:
    ```
    git clone https://github.com/xanubsl/GSDMx_Analysis.git
    ```
    
2. TBD
    
# USAGE
1. TBD

# PIPELINE OVERVIEW

TBD


# OUTPUT FILES
```
analysis
|
----MATLAB_files
|    |
|    Figure_All_Composite.png
|    ...
|
----R_Figures
     |
     figure1.png
     ...

```

# Acknowledgements

CODE
* Curve Intersection Code (InterX), by NS
        https://nl.mathworks.com/matlabcentral/fileexchange/22441-curve-intersections
* Aaron Ponti, Matlab image processing guide
* Open Nanoscope 6 AFM Images
        https://www.mathworks.com/matlabcentral/fileexchange/11515-open-nanoscope-6-afm-images

DATA ACQUISITION and EXPERIMENTAL DESIGN:
* Stefania Mari
* Daniel Muller
* Andreas Engel

# License

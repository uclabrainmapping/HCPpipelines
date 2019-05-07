#!/bin/bash 

echo "This script must be SOURCED to correctly setup the environment prior to running any of the other HCP scripts contained here"

export HCP_APP_DIR=/nafs/apps/HCPPipelines/64

# set path to some minor utilities we make use of
export PATH="${HCP_APP_DIR}/util:${PATH}"

# Set up FSL (if not already done so in the running environment)
# Uncomment the following 2 lines (remove the leading #) and correct the FSLDIR setting for your setup
export FSLDIR=${HCP_APP_DIR}/fsl/6.0.1-hcp
source ${FSLDIR}/etc/fslconf/fsl.sh > /dev/null 2>&1

# Let FreeSurfer know what version of FSL to use
# FreeSurfer uses FSL_DIR instead of FSLDIR to determine the FSL version
export FSL_DIR="${FSLDIR}"

# Set up FreeSurfer (if not already done so in the running environment)
# Uncomment the following 2 lines (remove the leading #) and correct the FREESURFER_HOME setting for your setup
export FREESURFER_HOME=${HCP_APP_DIR}/freesurfer/6.0.0-stable-pub
source ${FREESURFER_HOME}/SetUpFreeSurfer.sh > /dev/null 2>&1

# Set up specific environment variables for the HCP Pipeline
export HCPPIPEDIR=/nafs/narr/jpierce/hcppipe
export CARET7DIR=${HCP_APP_DIR}/workbench/1.3.2
export MSMBINDIR=${HCP_APP_DIR}/MSM_HOCR_v1
export MSMCONFIGDIR=${HCPPIPEDIR}/MSMConfig
export MATLAB_COMPILER_RUNTIME=${HCP_APP_DIR}/MCR/R2012b/v80
export FSL_FIXDIR=${HCP_APP_DIR}/fix

export HCPPIPEDIR_Templates=${HCPPIPEDIR}/global/templates
export HCPPIPEDIR_Bin=${HCPPIPEDIR}/global/binaries
export HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config

export HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts
export HCPPIPEDIR_FS=${HCPPIPEDIR}/FreeSurfer/scripts
export HCPPIPEDIR_PostFS=${HCPPIPEDIR}/PostFreeSurfer/scripts
export HCPPIPEDIR_fMRISurf=${HCPPIPEDIR}/fMRISurface/scripts
export HCPPIPEDIR_fMRIVol=${HCPPIPEDIR}/fMRIVolume/scripts
export HCPPIPEDIR_tfMRI=${HCPPIPEDIR}/tfMRI/scripts
export HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts
export HCPPIPEDIR_dMRITract=${HCPPIPEDIR}/DiffusionTractography/scripts
export HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts
export HCPPIPEDIR_tfMRIAnalysis=${HCPPIPEDIR}/TaskfMRIAnalysis/scripts

#try to reduce strangeness from locale and other environment settings
export LC_ALL=C
export LANGUAGE=C
#POSIXLY_CORRECT currently gets set by many versions of fsl_sub, unfortunately, but at least don't pass it in if the user has it set in their usual environment
unset POSIXLY_CORRECT

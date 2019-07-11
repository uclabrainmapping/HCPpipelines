#!/bin/bash

export STUDY_DIR="/nafs/narr/jpierce/out_r1"
export SUBJECT_LIST="k001702"

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname "${SCRIPT}")
. "${SCRIPT_DIR}/SetUpUCLAPipeline.sh"

# exit on any error
set -Eeuo pipefail

if [[ ${HCPPIPEDEBUG} == "true" ]]; then
  set -x
fi

# TODO: add sanity checks on CLI inputs

## Example data conversion here:
#export PATH="${HCP_APP_DIR}/dcm2niix/bin:${PATH}"
#heudiconv -d '/ifs/faculty/narr/schizo/CONNECTOME/{subject}/PRISMA_FIT_MRC35343/*/*HCP*/*_*/*' \
#  -s k001701 k001702 -f /nafs/narr/jpierce/hcppipe/runners/cmrr_heuristic.py -b   \ 
#  -o /nafs/narr/jpierce/out_r1

echo 'Removing first 10 volumes from rest and carit data. 
Unedited data saved to .nii.gz.uncut'
cd "${STUDY_DIR}"
for SUBJ in ${SUBJECT_LIST}; do
  BASE_WD="./sub-${SUBJ}/func"
  if [[ -f "${BASE_WD}/.truncated" ]]; then
    echo "${SUBJ}: Volumes removed in previous run, skipping..."
    continue
  else
   while read file; do
     echo "Calling fslroi on ${file}"
     mv "${file}" "${file}.uncut"
     fslroi "${file}.uncut" "${file}" 10 -1
   done < <(find . -regex "${BASE_WD}/sub-${SUBJ}_task-\(carit\|rest\)_acq-\(AP\|PA\)_run.*_bold.nii.gz")
   touch "${BASE_WD}/.truncated"
  fi
done

for SUBJ in ${SUBJECT_LIST}; do
  # order from:
  # https://wiki.humanconnectome.org/display/PublicData/HCP+Users+FAQ#HCPUsersFAQ-10.Whatistheorderofpipelinesforresting-statedata?
  
  # i) PreFreeSurfer
  "${SCRIPT_DIR}/1-PreFreeSurferPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subjlist="${SUBJ}"
  echo "Pre-FS Pipeline finished"
 
  # ii) FreeSurfer
  "${SCRIPT_DIR}/2-FreeSurferPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subject="${SUBJ}"
  echo "FS Pipeline Pipeline finished"

  # iii) PostFreeSurfer (using MSMSulc)
  "${SCRIPT_DIR}/3-PostFreeSurferPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subject="${SUBJ}"
  echo "Post-FS Pipeline finished"
  
  # iv) fMRIVolume 
  "${SCRIPT_DIR}/4-GenericfMRIVolumeProcessingPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subjlist="${SUBJ}"
  echo "fMRI Volume Processing Pipeline finished."

  # v) fMRISurface
  "${SCRIPT_DIR}/5-GenericfMRISurfaceProcessingPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subjlist="${SUBJ}"
  echo "fMRI Surface Processing Pipeline finished."
  
  # vi) ICA+FIX
  
  # vii) MSMAll
  
  # viii) GroupDeDrift

  # ix) DedriftAndResample (Apply MSMAll)

  # x) *Global Noise Removal* (not available publicly yet)
  
  # xi) Resting state analysis

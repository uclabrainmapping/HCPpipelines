#!/bin/bash

export STUDY_DIR='/nafs/narr/jpierce/out_r2'
export SUBJECT_LIST='k001701'
export LOG_DIR='/nafs/narr/jpierce/logs'

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname "${SCRIPT}")
. "${SCRIPT_DIR}/SetUpUCLAPipeline.sh"

if [[ ${HCPPIPEDEBUG} == "true" ]]; then
  set -x
  export HCPPIPEDEBUG
  if [[ ${USE_VALGRIND} == "true" ]]; then 
    RUN_PROF="valgrind --tool=massif --pages-as-heap=yes"
    SHOW_PROF="echo -n Peak memory use: "; "grep mem_heap_B $(ls -t "${LOG_DIR}/massif.out.*" | head -n1) | sed -e 's/mem_heap_B=\(.*\)/\1/' | sort -g | tail -n 1"
  else
    RUN_PROF=""
    SHOW_PROF=""
  fi
fi

# exit on any error
set -Eeuo pipefail

pushd "${LOG_DIR}"

# TODO: add sanity checks on CLI inputs

## Example data conversion here:
export PATH="${HCP_APP_DIR}/dcm2niix/bin:${PATH}"
echo "converting DICOMs into BIDS structured directory"
${RUN_PROF} heudiconv -d '/ifs/faculty/narr/schizo/CONNECTOME/{subject}/PRISMA_FIT_MRC35343/*/*HCP*/*_*/*' -s "${SUBJECT_LIST}" -f /nafs/narr/jpierce/hcppipe/runners/cmrr_heuristic.py -b -o "${STUDY_DIR}"
${SHOW_PROF}

echo 'Removing first 10 volumes from rest and carit data. 
Unedited data saved to .nii.gz.uncut'
pushd "${STUDY_DIR}"
for SUBJ in ${SUBJECT_LIST}; do
  BASE_WD="./sub-${SUBJ}/func"
  if [[ -f "${BASE_WD}/.truncated" ]]; then
    echo "${SUBJ}: Volumes removed in previous run, skipping..."
    continue
  else
   while read file; do
     echo "Calling fslroi on ${file}"
     mv "${file}" "${file}.uncut"
     ${RUN_PROF} fslroi "${file}.uncut" "${file}" 10 -1
     ${SHOW_PROF}
   done < <(find . -regex "${BASE_WD}/sub-${SUBJ}_task-\(carit\|rest\)_acq-\(AP\|PA\)_run.*_bold.nii.gz")
   touch "${BASE_WD}/.truncated"
  fi
done
popd

for SUBJ in ${SUBJECT_LIST}; do
  # order from:
  # https://wiki.humanconnectome.org/display/PublicData/HCP+Users+FAQ#HCPUsersFAQ-10.Whatistheorderofpipelinesforresting-statedata?
  
  # i) PreFreeSurfer
  ${RUN_PROF} "${SCRIPT_DIR}/1-PreFreeSurferPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subjlist="${SUBJ}"
  echo "Pre-FS Pipeline finished"
  ${SHOW_PROF}
 
  # ii) FreeSurfer
  ${RUN_PROF} "${SCRIPT_DIR}/2-FreeSurferPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subject="${SUBJ}"
  echo "FS Pipeline Pipeline finished"
  ${SHOW_PROF}

  # iii) PostFreeSurfer (using MSMSulc)
  ${RUN_PROF} "${SCRIPT_DIR}/3-PostFreeSurferPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subject="${SUBJ}"
  echo "Post-FS Pipeline finished"
  ${SHOW_PROF}
  
  # iv) fMRIVolume 
  ${RUN_PROF} "${SCRIPT_DIR}/4-GenericfMRIVolumeProcessingPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subjlist="${SUBJ}"
  echo "fMRI Volume Processing Pipeline finished."
  ${SHOW_PROF}

  # v) fMRISurface
  ${RUN_PROF} "${SCRIPT_DIR}/5-GenericfMRISurfaceProcessingPipelineBatch.sh" --StudyFolder="${STUDY_DIR}" --Subjlist="${SUBJ}"
  echo "fMRI Surface Processing Pipeline finished."
  ${SHOW_PROF}
  
  # vi) ICA+FIX
  #echo "${SCRIPT_DIR}
  
  # vii) MSMAll
  
  # viii) GroupDeDrift

  # ix) DedriftAndResample (Apply MSMAll)

  # x) *Global Noise Removal* (not available publicly yet)
  
  # xi) Resting state analysis
done 

popd

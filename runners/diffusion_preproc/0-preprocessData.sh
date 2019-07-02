#!/bin/bash
# Skullstrip T1s
set -Eeuo pipefail

#echo "Beginning data pre-processing for subject $1 at $(date)"

#/nafs/narr/jpierce/hcppipe/runners/1-PreFreeSurferPipelineBatch.sh --StudyDir="/nafs/narr/jpierce/out" --Subjlist="k001701 s001501"

#export HCPPIPEDEBUG=true

echo "Starting Diffusion Pre-processing Pipeline at $(date)"

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname "${SCRIPT}")

${SCRIPT_DIR}/1-DiffusionPreprocessingBatch.sh --StudyFolder="/nafs/narr/jpierce/newestout" --Subject="k001701"

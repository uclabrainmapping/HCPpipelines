#!/bin/bash
# Skullstrip T1s
set -Eeuo pipefail

#echo "Beginning data pre-processing for subject $1 at $(date)"

/nafs/narr/jpierce/hcppipe/runners/1-PreFreeSurferPipelineBatch.sh --StudyFolder="/nafs/narr/jpierce/out" --Subjlist="k001701 s001501"
/nafs/narr/jpierce/hcppipe/runners/2-FreeSurferPipelineBatch.sh --StudyFolder="/nafs/narr/jpierce/out" --Subjlist="k001701"
/nafs/narr/jpierce/hcppipe/runners/3-PostFreeSurferPipelineBatch.sh --StudyFolder="/nafs/narr/jpierce/out" --Subjlist="k001701"

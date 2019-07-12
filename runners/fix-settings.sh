# Settings file for FIX
# Modify these settings based on your system setup
FIXVERSION=1.06
#   (actually this version is 1.068 - see wiki page for details)

# Get the OS and CPU type
FSL_FIX_OS=$(uname -s)
FSL_FIX_ARCH=$(uname -m)

if [ -z "${FSL_FIXDIR}" ]; then
	if [ "X$0" = "X-bash" ]; then
		FSL_FIXDIR=$(pwd)
	else
	FSL_FIXDIR=$( cd "$(dirname "$0")" ; pwd)
	fi
	export FSL_FIXDIR
fi

# edit the following variables according to your local setup

# Part I MATLAB settings
# =======================
# Look for installed MATLAB
MATLAB_BIN=$(which matlab 2>/dev/null)
MCC_BIN=$(which mcc 2>/dev/null)

# Point this variable at your MATLAB install folder
if [ -z "${FSL_FIX_MATLAB_ROOT}" ]; then
       FSL_FIX_MATLAB_ROOT="$(dirname "${MATLAB_BIN}")/.."
       # On OS X this will most likely be something like /Applications/MATLAB_R20XX.app
fi

# Point this variable at your MATLAB command - this is usually $FSL_FIX_MATLAB_ROOT/bin/matlab
if [ -z "${FSL_FIX_MATLAB}" ]; then
	FSL_FIX_MATLAB="${MATLAB_BIN}"
fi

# Point this variable at your MATLAB compiler command - this is usually $FSL_FIX_MATLAB_ROOT/bin/mcc
if [ -z "${FSL_FIX_MCC}" ]; then
	FSL_FIX_MCC="${MCC_BIN}"
fi

# Point this variable at an installed MATLAB compiler runtime. This
# MUST be the same as the version given in the file MCR.version
# (which is populated when the software is compiled).
if [ -z "${FSL_FIX_MCRROOT}" ]; then
	FSL_FIX_MCRROOT="/nafs/apps/HCPPipelines/64/MCR/R2017b3"
fi

# This is name of the folder containing the compiled MATLAB functions
if [ -z "${FSL_FIX_MLCDIR}" ]; then
	FSL_FIX_MLCDIR="${FSL_FIXDIR}/compiled/${FSL_FIX_OS}/${FSL_FIX_ARCH}"
fi

if [ -z "${FSL_FIX_MCRV}" ]; then
	if [ -f "${FSL_FIX_MLCDIR}/MCR.version" ]; then
		FSL_FIX_MCRV=$(cat "${FSL_FIX_MLCDIR}/MCR.version")
	fi
fi

if [ ! -z "${FSL_FIX_MCRV}" -a -z "${FSL_FIX_MCR}" ]; then
	FSL_FIX_MCR="${FSL_FIX_MCRROOT}/${FSL_FIX_MCRV}"
fi

# See README for instructions on compilation of the MATLAB portions

# Set this to the MATLAB start-up options. Typically you will
# want to disable Java, display output, the desktop environment
# and the splash screen
if [ -z "${FSL_FIX_MLOPTS}" ]; then
	FSL_FIX_MLOPTS="-nojvm -nodisplay -nodesktop -nosplash"
fi

# Set this to the MATLAB 'evaluate string' option
if [ -z "${FSL_FIX_MLEVAL}" ]; then
	FSL_FIX_MLEVAL="-r"
fi
# Set this to the pass in file option
if [ -z "${FSL_FIX_MLFILE}" ]; then
	FSL_FIX_MLFILE="\<"
fi

# Part II Octave settings
# =======================
# Point this variable at your Octave command (or leave it blank to disable Octave mode)
# Linux:
if [ -z "${FSL_FIX_OCTAVE}" ]; then
	#FSL_FIX_OCTAVE="/usr/bin/octave"  #Linux
	#FSL_FIX_OCTAVE="/opt/local/bin/octave"	# Mac OS X installed via MacPorts
	FSL_FIX_OCTAVE=  # Disable Octave mode
fi

# Set this to the Octave start-up options. Typically you will need to
# enable 'MATLAB' mode (--traditional) and disable display output
if [ -z "${FSL_FIX_OCOPTS}" ]; then
	FSL_FIX_OCOPTS="--traditional -q --no-window-system"
fi

# Set this to the Octave 'evaluate string' option
if [ -z "${FSL_FIX_OCEVAL}" ]; then
	FSL_FIX_OCEVAL="--eval"
fi
# Set this to the pass in file option
if [ -z "${FSL_FIX_OCFILE}" ]; then
	FSL_FIX_OCFILE=""
fi

# Part III General settings
# =========================
# This variable selects how we run the MATLAB portions of FIX.
# It takes the values 0-2:
#   0 - Try running the compiled version of the function
#   1 - Use the MATLAB script version
#   2 - Use Octave script version
if [ -z "${FSL_FIX_MATLAB_MODE}" ]; then
	FSL_FIX_MATLAB_MODE=0
fi

# Set this to CIFTI Matlab Reader/Writer for use within HCP pipelines
# i.e., location of the ciftiopen.m, ciftisave.m, and ciftisavereset.m functions
# https://wiki.humanconnectome.org/display/PublicData/HCP+Users+FAQ#HCPUsersFAQ-2.HowdoyougetCIFTIfilesintoMATLAB?
# Note that the GIFTI library will need to be in your matlab/octave path as well (see previous link)
# This variable is only relevant if using FSL_FIX_MATLAB_MODE of 1 or 2.
# [If using the compiled version of FIX, the CIFTI I/O functionality is already part of the compiled executables].
if [ -z "${FSL_FIX_CIFTIRW}" ]; then
	FSL_FIX_CIFTIRW='/opt/fmrib/workbench_ciftireader/CIFTIMatlabReaderWriter';
fi
if [ -z "${FSL_FIX_WBC}" ]; then
	FSL_FIX_WBC="$(which wb_command 2>/dev/null)"
	if [ -z "${WBENCH}" ]; then
		# Set this to the location of the HCP Workbench command for your platform
		WBENCH="/nafs/apps/HCPPipelines/64/workbench/1.3.2"
		if [ "${FSL_FIX_OS}" = "Darwin" ]; then
			FSL_FIX_WBC="${WBENCH}/bin_macosx64/wb_command"
		elif [ "${FSL_FIX_OS}" = "Linux" ]; then
			FSL_FIX_WBC="${WBENCH}/bin_linux64/wb_command"
		fi
	fi
fi
export FSL_FIX_CIFTIRW FSL_FIX_WBC

# Set this to the location of the FSL MATLAB scripts
if [ -z "${FSLDIR}" ]; then
	echo "FSLDIR is not set!"
	exit 1
fi
FSL_FIX_FSLMATLAB=${FSLDIR}/etc/matlab

if [ -z "${FSL_FIX_R_CMD}" ]; then
	# Set this to the location of the R binary, e.g.
	# Linux: /usr/bin/R
	# macOS: $FSLDIR/fslpython/envs/fslpython/bin/R
	FSL_FIX_R_CMD=/nafs/apps/R/3.4.3/64/gcc4.8.5/bin/R
fi
#############################################################

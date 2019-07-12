#!/bin/bash
# Installs a multi-fix capable HCP Pipeline on cerebrum
#
set -Eeuo pipefail # do not change, script assumes this will catch errors
[[ -v _HCPDEBUG ]] && true # TODO

. /etc/rc.d/init.d/functions

SRC_DIR="/home/jpierce/src/HCPPipelines"
HCP_APP_DIR="/nafs/apps/HCPPipelines/64"
EPD_DIR="${HCP_APP_DIR}/epd-7.3-2-rh5"
MSM_DIR="${HCP_APP_DIR}/MSM_HOCR_v3-github"
FIX_DIR="${HCP_APP_DIR}/fix"
export FSLDIR="${HCP_APP_DIR}/fsl/6.0.1-hcp"
export FREESURFER_HOME="${HCP_APP_DIR}/freesurfer-6.0.0"

HCP_RUN_UTILS_URL='https://github.com/Washington-University/HCPpipelinesRunUtils/archive/v1.4.0.tar.gz'
HRUSHA256='245528859dffeead8f1e77d2bb3a9fa44c7ba9a4f91b38bc39b83f7ca2a0d849'
ANACONDA3_URL='https://repo.anaconda.com/archive/Anaconda3-5.3.1-Linux-x86_64.sh'
ANASHA256='d4c4256a8f46173b675dd6a62d12f566ed3487f932bab6bb7058f06c124bcc27'
FREESURFER_URL='ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz'
FSSHA256='9e68ee3fbdb80ab73d097b9c8e99f82bf4674397a1e59593f42bb78f1c1ad449'
EPD_URL='https://www.clear.rice.edu/comp140/downloads/epd/linux/epd-7.3-2-rh5-x86_64.sh'
EPDSHA256='868df97df367d5e9b722051eb6b5642fe56fa4d92a30c411c7756d41c41a229e'
FSL_URL='https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.1-centos7_64.tar.gz'
FSLSHA256='7aebc8d717d6a4ecca365d7aa6a5886871d4fcd26f8758522d90e08ce31381be'
#MSM_URL='https://github.com/ecr05/MSM_HOCR/archive/v3.0FSL.tar.gz'
#MSMSHA256='be74b54283e97bd6f880ac39019333e63f4605da90d2dc7b93895f8a11698cac'
MCR_URL='http://ssd.mathworks.com/supportfiles/downloads/R2017b/deployment_files/R2017b/installers/glnxa64/MCR_R2017b_glnxa64_installer.zip'
MCRSHA256='a01619b30f8cfd34a9a9cefe8323a2ada22a65722fc13b823dae36086ddd259f'
FIX_URL='http://www.fmrib.ox.ac.uk/~steve/ftp/fix.tar.gz'
FIXSHA256='ac62d54e418dc208c3d9e321a02c1cbff6349ec09ff682481a24aeb3c4a9dabb'

mkdir -p "${HCP_APP_DIR}"
pushd "${SRC_DIR}"

# use Developer Toolset 7 - gcc 7.3.1 that builds for CentOS 7 standard libs
. /opt/rh/devtoolset-7/enable

# install basic system pre-req packages
yum install -y curl tar gzip unzip git which \
  bzip2 bc hostname tcsh libgomp libGLU libXmu \
  qt5-qtbase libXrender xorg-x11-fonts-Type1 mesa-dri-drivers mesa-libGL-devel 

curl -fLs "${HCP_RUN_UTILS_URL}" | tee hcp_pipelines_run_utils.tar.gz | sha256sum -c <$(echo ${HRUSHA256})
tar -xzf hcp_pipelines_run_utils.tar.gz -C "${HCP_APP_DIR}"

echo -n "Installing anaconda + packages"
# install anaconda3 and any python packages needed down the pipe
curl -fLs "${ANACONDA3_URL}" | tee anaconda.sh | sha256sum -c <$(echo ${ANASHA256})
bash ./anaconda.sh -b -p "${HCP_APP_DIR}/anaconda3"
export PATH="${HCP_APP_DIR}/anaconda3/bin:${PATH}"
conda create -y --name singlepython3 python=3
source activate singlepython3
conda install -y requests
conda install -y pyqt pip
pip install -r << EOF
pydicom
dcmstack
nipype
nibabel
numpy
pybids
bids_validator
https://github.com/nipy/heudiconv/archive/master.zip
EOF
echo_success

# install freesurfer.
echo "Installing freesurfer"
curl -fL "${FREESURFER_URL}" -o freesurfer6.tgz
sha256sum -c <$(echo ${FSSHA256}) freesurfer6.tgz
mkdir -p "${FREESURFER_HOME}"
tar -C "${FREESURFER_HOME}" -xzf freesurfer6.tgz --strip-components=1
echo_success

# install enthought python distribution. assuming a utility requires python2.7
# here
echo -n "Installing EPD"
curl -fLs "${EPD_URL}" | tee epd.sh | sha256sum -c <$(echo ${EPDSHA256})
bash ./epd.sh -b -p "${EPD_DIR}"
export PATH="${EPD_DIR}/bin:${PATH}"
echo_success

sudo yum install -y python2-pip.noarch
pip2 install numpy
pip2 install nibabel==2.3.0 --install-option="--prefix=${EPD_DIR}"

# install fsl. this is the lengthiest d/l
# TODO parallelize with freesurfer if you're going to run this script very often
echo "Downloading FSL..."
curl -fL "${FSL_URL}" -o fslhcp.tgz
sha256sum -c <$(echo ${FSLSHA256}) fslhcp.tgz
mkdir -p "${FSLDIR}"
tar -xzf fslhcp.tgz -C "${FSLDIR}" --strip-components=1
echo "Running FSL post-install. It's not hanging, just thinking real hard."
"${FSLDIR}/etc/fslconf/post_install.sh" -f "${FSLDIR}"
echo_success

echo -n "Installing MSM with HOCR"
#curl -fLs "${MSM_URL}" | tee msm3.tgz | sha256sum -c <$(echo ${MSMSHA256})
git clone https://github.com/ecr05/MSM_HOCR.git
cd MSM_HOCR
. "${FSLDIR}/etc/fslconf/fsl.sh"
export FSLCONFDIR="${FSLDIR}/config"
export FSLDEVDIR="$(pwd)/build"
export FSLMACHTYPE='linux_64-gcc4.8'
mkdir -p "${FSLDEVDIR}" "${FSLDEVDIR}/extras" "${FSLDEVDIR}/extras/include" "${FSLDEVDIR}/extras/src"
cp -r extras/ELC1.04/ELC "${FSLDEVDIR}/extras/include/"
cp -r "${FSLDIR}/src/FastPDlib" "${FSLDEVDIR}/extras/src/"
make -j8 -C src/newmesh install
make -j8 -C src/DiscreteOpt install
make -j8 -C "${FSLDEVDIR}/extras/src/FastPDlib" install
make -j8 -C src/MSMRegLib install
make -j8 -C src/MSM install

mkdir -p ${MSM_DIR}
cp src/MSM/{surfconvert,msmapplywarp,estimate_metric_distortion,msm_metric_sim,msm,msmresample} ${MSM_DIR}/
echo_success

curl -fLs "${MCR_URL}" | tee mcr.zip | sha256sum -c <$(echo ${MCRSHA256})
mkdir mcr && cd "$_"
unzip ../mcr.zip 
./install -mode silent -agreetoLicense yes -destinationFolder /nafs/apps/HCPPipelines/64/MCR/R2017b/v93

curl -fLs "${FIX_URL}" | tee fix.tar.gz | sha256sum -c <$(echo ${FIXSHA256})
tar xvzf fix.tar.gz -C "${FIX_DIR}"
curl -fLs "https://raw.githubusercontent.com/uclabrainmapping/HCPpipelines/master/runners/fix-settings.sh" -o "${FIX_DIR}/settings.sh"


popd

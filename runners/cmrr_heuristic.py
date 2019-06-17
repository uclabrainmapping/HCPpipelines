import os

def create_key(template, outtype=('nii.gz'), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return (template, outtype, annotation_classes)


def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where

    allowed template fields - follow python string module:

    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """
    t1 = create_key('sub-{subject}/anat/sub-{subject}_T1w')
    t2 = create_key('sub-{subject}/anat/sub-{subject}_T2w')
    fieldmap = create_key('sub-{subject}/fmap/sub-{subject}_dir-{dir}_run-{item:02d}_epi')
    task = create_key('sub-{subject}/func/sub-{subject}_task-{task}_acq-{acq}_bold')
    task_sbref = create_key('sub-{subject}/func/sub-{subject}_task-{task}_acq-{acq}_sbref')
    #rest =        create_key('sub-{subject}/func/sub-{subject}_dir-{acq}_task-rest_run-{item:02d}_bold')
    #rest_sbref =  create_key('sub-{subject}/func/sub-{subject}_task-rest_acq-{acq}_run-{item:02d}_sbref')
    #face =        create_key('sub-{subject}/func/sub-{subject}_task-face_acq-{acq}_run-{item:02d}_bold')
    #face_sbref = create_key('sub-{subject}/func/sub-{subject}_task-face_acq-{acq}_run-{item:02d}_sbref')
    #carit = create_key('sub-{subject}/func/sub-{subject}_task-carit_run-{item:02d}_acq-{acq}_bold')
    #dwi = create_key('sub-{subject}/dwi/sub-{subject}_dir-{acq}_run-{item:02d}_dwi')
    #fmap_dwi = create_key('fmap/sub-{subject}_acq-dwi{acq}_dir-{dir}_run-{item:02d}_epi')


    info = {t1:[], t2:[], fieldmap:[], task:[], task_sbref:[]}

    for idx, s in enumerate(seqinfo):
        #if (s.dim3 == 208) and (s.dim4 == 1) and ('T1w' in s.protocol_name):
        if (s.protocol_name == 'T1w_MPR_vNav_4e') and ('NORM' in s.image_type):
            info[t1] = [s.series_id]
        #if (s.dim3 == 208) and ('T2w' in s.protocol_name):
        if (s.protocol_name == 'T2w_SPC_vNav') and ('NORM' in s.image_type):
            info[t2] = [s.series_id]
        if ('SpinEchoFieldMap' in s.protocol_name):
          info[fieldmap].append({'item': s.series_id,
                                 'dir': s.protocol_name.split('_')[1]})
        #if (s.dim4 >= 99) and (('dMRI_dir98_AP' in s.protocol_name) or ('dMRI_dir99_AP' in s.protocol_name)):
        #    acq = s.protocol_name.split('dMRI_')[1].split('_')[0] + 'AP'
        #    info[dwi].append({'item': s.series_id, 'acq': acq})
        #if (s.dim4 >= 99) and (('dMRI_dir98_PA' in s.protocol_name) or ('dMRI_dir99_PA' in s.protocol_name)):
        #    acq = s.protocol_name.split('dMRI_')[1].split('_')[0] + 'PA'
        #    info[dwi].append({'item': s.series_id, 'acq': acq})
        #if (s.dim4 == 1) and (('dMRI_dir98_AP' in s.protocol_name) or ('dMRI_dir99_AP' in s.protocol_name)):
        #    acq = s.protocol_name.split('dMRI_')[1].split('_')[0]
        #    info[fmap_dwi].append({'item': s.series_id, 'dir': 'AP', 'acq': acq})
        #if (s.dim4 == 1) and (('dMRI_dir98_PA' in s.protocol_name) or ('dMRI_dir99_PA' in s.protocol_name)):
        #    acq = s.protocol_name.split('dMRI_')[1].split('_')[0]
        #    info[fmap_dwi].append({'item': s.series_id, 'dir': 'PA', 'acq': acq})
        if (('tfMRI' in s.protocol_name) or ('rfMRI' in s.protocol_name)) and (s.dim4 != 1):
            info[task].append({'item': s.series_id,
                              'task': s.protocol_name.split('_')[1].lower(),
                              'acq': s.protocol_name.split('_')[2]})
        if (('tfMRI' in s.protocol_name) or ('rfMRI' in s.protocol_name)) and (s.dim4 == 1):
            info[task_sbref].append({'item': s.series_id,
                                    'task': s.protocol_name.split('_')[1].lower(),
                                    'acq': s.protocol_name.split('_')[2]})
        #if (s.dim4 == 488) and ('rfMRI_REST_AP' in s.protocol_name):
        #    info[rest].append({'item': s.series_id, 'acq': 'AP'})
        #if (s.dim4 == 1) and ('rfMRI_REST_AP' in s.protocol_name):
        #    info[rest_sbref].append({'item': s.series_id, 'acq': 'AP'})
        #if (s.dim4 == 488) and ('rfMRI_REST_PA' in s.protocol_name):
        #    info[rest].append({'item': s.series_id, 'acq': 'PA'})
        #if (s.dim4 == 1) and ('rfMRI_REST_PA' in s.protocol_name):
        #    info[fmap_rest].append({'item': s.series_id, 'acq': 'PA'})
        #if (s.dim4 == 338) and ('tfMRI_FACEMATCHING_AP' in s.protocol_name):
        #    info[face].append({'item': s.series_id, 'acq': 'AP'})
        #if (s.dim4 == 338) and ('tfMRI_FACEMATCHING_PA' in s.protocol_name):
        #    info[face].append({'item': s.series_id, 'acq': 'PA'})
        #if (s.dim4 == 1) and ('tfMRI_FACEMATCHING_AP' in s.protocol_name):
        #    info[fmap_face].append({'item': s.series_id, 'dir': 'AP', 'acq': ''})
        #if (s.dim4 == 1) and ('tfMRI_FACEMATCHING_PA' in s.protocol_name):
        #    info[fmap_face].append({'item': s.series_id, 'dir': 'AP', 'acq': ''})
        #if (s.dim4 == 300) and ('tfMRI_CARIT_PA' in s.protocol_name):
        #    info[carit].append({'item': s.series_id, 'acq': 'PA'})
        #if (s.dim4 == 1) and ('tfMRI_CARIT_PA' in s.protocol_name):
        #    info[fmap_carit].append({'item': s.series_id, 'dir': 'PA', 'acq': ''})
    return info

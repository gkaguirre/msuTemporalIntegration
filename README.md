# msuTemporalIntegration
Demo implementation of the Mattar 2016 exponential integration model using the forwardModel platform

The code can be configured using the Matlab package manager TbTb (https://github.com/ToolboxHub/ToolboxToolbox). Alternatively, the following repositories should be downloaded and placed on the Matlab path:

- https://github.com/gkaguirrelab/forwardModel
- https://github.com/freesurfer/freesurfer

There are hard-coded paths to the data and event files in the routine `demoMattarAdapt`. There are also a couple of parameters there that one could adjust (e.g., spatial smoothing).

Once you have the paths updated, run the demo. The demo script has the flag `fitOneVoxel` available at the start. Set this to `true`, and the routine will quickly (in seconds) fit the data for an example voxel. You can use this to confirm that your paths are working properly. Then, set `fitOneVoxel` to false and run the demo again. The routine will fit the model to all voxels. This takes about 40 minutes on a laptop with 10 CPU cores available for the parpool.

The results of the analysis will be written to the hard-coded save directory. The output includes a set of files in nii format that provide maps of the relevant parameter values.

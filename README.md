# whyhowtask_generic

Generic MATLAB/Psychtoolbox code for running custom editions of the Why/How Task, aka, the Levels of Inference (LOI) Task.

## Basic Usage

### Step 1: Build a design file

This should be an Excel (xlsx, ideally) spreadsheet like the `design_test1.xlsx` file included in this repository. Trials are represented by different rows in the spreadsheet.

### Step 2: Customize defaults in `task_defaults.m`

The `import_design.m` tool assumes the `task_defaults.m` file is in the same folder as it. The most important defaults to set before importing are:

- path definitions under `defaults.path`. For these, make sure your raw image files are located under the path defined in `defaults.path.rawimages`.
- timing information (all in seconds), as these are used to determine if there if the onsets between successive blocks/trials are long enough:

    - `firstISI`
    - `maxDur`
    - `inblockreminderDur`
    - `preblockquestionDur`

- the `defaults.screenres` parameter controls the resolution of the presentation slides that are saved in a mat-file (i.e., preloaded) when importing your design file

The other parameters are important to be aware of when you are preparing to run the actual experiment, but can (probably) be ignored for the design import step.

### Step 3: Basic usage of `import_design.m`

To import the design in the file `design_test1.xlsx` and save the stimulus slides:

```matlab
import_design('design_test1.xlsx')
```

You can also do a "dry run" of the import process where nothing gets saved at the end, which can be useful for validating your design file:

```matlab
import_design('design_test1.xlsx', 1)
```

### Step 4: Run the task with your imported design

If all went well, you should now be able to run your custom design with the `run_task` function.

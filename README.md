# Notice:

Copyright 2021, Martin Siemienski Andersen, PhD, Aalborg University, Denmark, All rights reserved.

Contact Information : mvan@hst.aau.dk
# Info

This file is provided by Martin Siemienski Andersen, PhD, Aalborg University, Denmark to end users as a programming example for use of IWORX in MATLAB. 
Andersen makes no claims as to the or intended application of this program and the user assumes all responsibility for its use.

# Prereq. for using the API :

Files needed: iwxDAQ API form https://iworx.com/research/iworx-api/
- At the time of this script, the download link was https://iworx.com/documents/iwxDAQ_v2.zip
- Unzip the /iwxDAQ folder and subfolders into the path with this script!
- You can read more about the different API calls in /iwxDAQ/x64/iwxDAQ.h

## Prereq. for using the API :
- An installed version of the Labscribe software.
    1) Open labscribe
    3) Go to SETTINGS 
        - Select device settings.
            - (i.e. press the preset IX12ECG-12LeadECG)
    4) Go to EDIT > PREFERENCES
        - Set Speed (per channel sampling rate) in dropdown menu, to specified sampling rate
        - press OK
    5) Go to FILE 
        - SAVE AS 
        - Select FILE TYPE: '*iwxset' 
        - set file name (%SETTINGS_FILE_NAME%)
        - Select save location as this script's working folder
- An Installed version of MATLAB (2021b used used for this example)
- In MATLAB
    1) Run the command : mex -setup c.
        - Follow the MATLAB instructions if any (you need a C compiler)
    2) Set SETTINGS_FILE_NAME in script to %SETTINGS_FILE_NAME%
    3) Ensure that the iwxDAQ folder ( including x32 and x64 subfolders) are in the same folder as this script
    4) Run script.
    5) Enjoy the magic of iwxDAQ!
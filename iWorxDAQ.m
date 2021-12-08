% # Notice:
% 
% Copyright 2021, Martin Siemienski Andersen, PhD, Aalborg University, 
% Denmark, All rights reserved.
% 
% Contact Information : mvan@hst.aau.dk
% # Info
% 
% This file is provided by Martin Siemienski Andersen, PhD, Aalborg University, 
% Denmark to end users as a programming example for use of IWORX in MATLAB. 
% Andersen makes no claims as to the or intended application of this program 
% and the user assumes all responsibility for its use.
% 
% # Prereq. for using the API :
% 
% Files needed: iwxDAQ API form https://iworx.com/research/iworx-api/
% - At the time of this script, 
%		the download link was https://iworx.com/documents/iwxDAQ_v2.zip
% - Unzip the /iwxDAQ folder and subfolders into the path with this script!
% - You can read more about the different API calls in /iwxDAQ/x64/iwxDAQ.h
% 
% ## Prereq. for using the API :
% - An installed version of the Labscribe software.
%     1) Open labscribe
%     3) Go to SETTINGS 
%         - Select device settings.
%             - (i.e. press the preset IX12ECG-12LeadECG)
%     4) Go to EDIT > PREFERENCES
%         - Set Speed (per channel sampling rate) in dropdown menu, 
%			to specified sampling rate
%         - press OK
%     5) Go to FILE 
%         - SAVE AS 
%         - Select FILE TYPE: '*iwxset' 
%         - set file name (%SETTINGS_FILE_NAME%)
%         - Select save location as this script's working folder
% - An Installed version of MATLAB (2021b used used for this example)
% - In MATLAB
%     1) Run the command : mex -setup c.
%         - Follow the MATLAB instructions if any (you need a C compiler)
%     2) Set SETTINGS_FILE_NAME in script to %SETTINGS_FILE_NAME%
%     3) Ensure that the iwxDAQ folder ( including x32 and x64 subfolders) 
%		are in the same folder as this script
%     4) Run script.
%     5) Enjoy the magic of iwxDAQ!

clear all;close all;clc

%% You can change me
SETTINGS_FILE_NAME = 'IX-ECG12SETTINGS.iwxset';
BUFFER_SIZE_SECONDS = 0.05;
TIME_SECONDS = 2;
CHANNEL_DATA_OFFSET_IN_PLOT = 10; % This is the offset of all the channels in plot

%% Dont change below here
IWORXDAQ = 'iwxDAQ';
STR_BUFFER_SIZE = 256;
max_grabs_per_second = int32(1/BUFFER_SIZE_SECONDS);

HEADER_PATH = 'iwxDAQ\x64\iwxDAQ.h'; % url for header
DLL_PATH = 'iwxDAQ\x64\iwxDAQ.dll'; % url for .dll

fprintf('Running the iWorxDAQ example script!\n')

%% ACTUAL CODE
loadlibrary(DLL_PATH, HEADER_PATH);

logfile = 'iworx.log';
bRet = calllib(IWORXDAQ, 'OpenIworxDevice', logfile);

% FindHardware
[bRet, model_number, model_name, serial_number] = calllib(IWORXDAQ, 'FindHardware', ...
	0, blanks(STR_BUFFER_SIZE), STR_BUFFER_SIZE, blanks(STR_BUFFER_SIZE), STR_BUFFER_SIZE); 

% Load a settings file that has been created with LabScribe
failed_LoadConf = calllib('iwxDAQ', 'LoadConfiguration', SETTINGS_FILE_NAME); 

% Get current sampling speed and num of channels
[failed_GetCurrentSamplingInfo, samplerate, num_analog_channels] = calllib(IWORXDAQ, 'GetCurrentSamplingInfo', 0, 0);
samplerate = int32(samplerate); % Matlab does not like singles (floats)
DATA_BUFFER_SIZE =  2^(nextpow2(samplerate * num_analog_channels / max_grabs_per_second)); % Lets just get a power of 2 for the buffer size
% Optional get some other parameters

[failed_GetSamplingSpeed, max_samplerate, min_samplerate, samplerate_is_shared] = calllib(IWORXDAQ, 'GetSamplingSpeed', 0, 0, 0);
[failed_GetNumChannels, analog_input_channels, analog_output_channels, digital_input_bits, digital_output_bits] = calllib(IWORXDAQ, 'GetNumChannels', 0, 0, 0, 0);


% Read Data and save it to file
chData = cell(1, num_analog_channels); % Allocate data array

fprintf('Current Model : %s\nSerial Number : %s\n', model_name, serial_number)
fprintf('Number of analog channels : %u\n', num_analog_channels)
fprintf('Samplerate : %u\n', samplerate)

%% Helper array for indecies
% if num_samples_per_ch > DATA_BUFFER_SIZE, a bigger buffer should be defined!)
% Notice: data is saved as [ch1(1), ch2(1), ch3(1)... chn(1), ch1(2), ch2(2), ch3(2)... chn(2), ...]
cntr = 0 : num_analog_channels : DATA_BUFFER_SIZE - num_analog_channels;
cur_len = 0;

% Setup a timer.
t = tic;

% Start Acquisition
failed_StartAcq = calllib(IWORXDAQ, 'StartAcq', DATA_BUFFER_SIZE); % setup internal buffer for 1 second worth of data.
while (toc(t)<TIME_SECONDS)
	[iRet, num_samples_per_ch, trig_index, trig_string, data] = calllib(IWORXDAQ, 'ReadDataFromDevice', ...
		0, 0, blanks(STR_BUFFER_SIZE), STR_BUFFER_SIZE, zeros(1, DATA_BUFFER_SIZE), DATA_BUFFER_SIZE);
	% Notice: data is saved as [ch1(1), ch2(1), ch3(1)... chn(1), ch1(2), ch2(2), ch3(2)... chn(2), ...]

	if num_samples_per_ch < 1
		% If there is no data, call read data in iwxDAQ again.
		continue
	end

	% Here we have an assert that is often an issue for the first data call
	pts_recorded = num_samples_per_ch * num_analog_channels;
	assert(pts_recorded<=DATA_BUFFER_SIZE, ...
		sprintf('!!! pts_recorded<=DATA_BUFFER_SIZE. Points recorded: %u, DATA_BUFFER_SIZE=%u. Increase BUFFER_SIZE_SECONDS!!!'...
		, pts_recorded, DATA_BUFFER_SIZE))

	
	indices = 1 : num_samples_per_ch;
	buffer_indices = cntr(indices); % cntr starts from 0!

	% Save data to file
	for idx_ch = 1 : num_analog_channels
		% From current length of data,
		chData{idx_ch}(cur_len + indices) = data(buffer_indices + idx_ch);
	end

	% update current length of data for each channel
	cur_len = cur_len + num_samples_per_ch; 
end

fprintf('Number of acquired samples per channel : %u\n', cur_len)

% print total duration of while loop.
toc(t)

%% Close down iwxDAQ
calllib(IWORXDAQ, 'StopAcq');
% Close the iWorx Device
calllib(IWORXDAQ, 'CloseIworxDevice');
% Unload the library
unloadlibrary(IWORXDAQ);



%% Plot recorded channels in figure.
PLOTME(model_name, chData, TIME_SECONDS, CHANNEL_DATA_OFFSET_IN_PLOT, cur_len, num_analog_channels)

function PLOTME(model_name, chData, TIME_SECONDS, CHANNEL_DATA_OFFSET_IN_PLOT, len_ch, num_analog_channels	)
	%% Plot results

	% Time data for plot, converted to seconds.
	time = seconds( TIME_SECONDS / double(len_ch) * double(0 : len_ch - 1) );
	XLIM = seconds([0, TIME_SECONDS]);
	ttl = sprintf('Model : %s', model_name);

	f = figure('Name', ttl);
	ax = gca(f);
	hold(ax, 'on')

	for i = 1:num_analog_channels
		% Plot each channel
		plot(ax, ...
			time, ...
			chData{i} + CHANNEL_DATA_OFFSET_IN_PLOT * (double(i) - 1) ...
			, 'DisplayName', sprintf('A%u', i) )
		% DisplayName is a readable method of naming legends
	end

	xlim(ax, XLIM)
	xlabel(ax, 'Time')
	ylabel(ax, 'Channel Data')
	title(ax, ttl)
	hold(ax, 'off')
	legend(ax, 'Location', 'northeastoutside')
end


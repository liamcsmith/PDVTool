classdef PdvTrace
%%%  An object for containing everything about a PDV trace. It will manage raw data storage (using ScopeTrace dependency), analysis via its interface with the bundled PDVAnalysis GUI (including analysis parameter storage, and analysis updating from prior analyses) and cable delay inputs.
% 
% ## Dependencies
% **ScopeTrace.m** - You can find this in a different repository on my profile.
% 
% ## Installation
% To have PDVTrace work correctly you will need to:
% 1) Edit the path on Line 24 of PDVTrace.m to give a suitable path to ScopeTrace.m, if you do not do this the PDVTrace object will not be able to read in data from the raw oscilloscope file!
% 2) edit the path on Line 92 of PDVAnalysis.m to give a suitable path to ScopeTrace.m, if you do not do this the GUI will not be able to read in data from raw data passed in via "Trace", nor will it be able to import raw data if launched without raw data input arguments!
% 
% ## InputArgs
% (all passed as Name-Value pairs, all optional [^1])
% [^1]: If you do not pass a FilePath then the object will use ScopeTrace to launch a file explorer to select and import a raw oscilloscope trace.
% 
% | Name          	| DataType      | Default      	| Description   											|
% | ------------- 	| ------------- | -------------	| ------------- 											|
% | "FilePath"    	| string        | N/A          	| Absolute or relative file path to a raw oscilloscope file. This will be imported using ScopeTrace 	|
% | "AnalysisParameters" 	| struct[^3] 	| N/A        	| The analysis parameter struct that is outputted from the PDVAnalysis GUI. 				|
% | "Delay" 		| numeric 	| 0.0 		| The cable delay asscoiated with this trace (including fiber & PDV channel delays) given in seconds. 	|
% | "Title" 		| string 	| 'Generic' 	| A title for the associated PDV Trace, passed to PDVAnalysis GUI for its UIFigure title 		|
% | "ProbeWavelengthNM" 	| numeric 	| 1550[^4] 	| The wavelength (in nm) of the probe laser.								|
% [^3]: I wouldn't worry about this field too much, PDV Trace will save the analysis parameters in a cache alongside the raw data file and then automatically repopulate this when you pass it a raw data file (that has an associated analysis cache file.
% [^4]: This sets the velocity scale and its important you get it correct (so note down when doing experiments). The default is set at 1550 (which I use always so as to avoid issues if i forget it).
    properties
        RawTrace
        Title
        AnalysisParameters
        Delay
        ProcessedTrace
        ProbeWavelengthNM
    end
    properties (Dependent)
        Time
        Velocity
        Error
    end
    properties (Dependent,Access=private)
        StartTimeUs
        EndTimeUs
        WindowSize
        Overlap
        StartFreqGHz
        EndFreqGHz
    end
    properties (Access=private)
        ScopeTracePath = '~/Documents/GitHub/ImportScope' % CHANGE ME TO SATISFY DEPENDENCY
    end
   
    methods
        function obj = PdvTrace(inputargs)
            arguments
                inputargs.FilePath              = 'Undefined';
                inputargs.AnalysisParameters    = 'Undefined';
                inputargs.Delay                 = 0;
                inputargs.ProcessedTrace        = 'Not Calculated';
                inputargs.Title                 = 'Generic PDV Trace'
                inputargs.ProbeWavelengthNM     = 1550;
            end
            obj.CheckDependency
            
            switch inputargs.FilePath
                case 'Undefined'
                    obj.RawTrace    = ScopeTrace;
                otherwise
                    obj.RawTrace    = ScopeTrace('FilePath', ...
                                                 inputargs.FilePath);
            end
            obj.AnalysisParameters  = inputargs.AnalysisParameters;
            obj.Delay               = inputargs.Delay;
            obj.ProcessedTrace      = inputargs.ProcessedTrace;
            obj.Title               = inputargs.Title;
            obj.ProbeWavelengthNM   = inputargs.ProbeWavelengthNM;
            clearvars inputargs
            
            % Loading Saved if it exists
            if isfile(obj.RawTrace.FilePath)
                [tmpfolder,tmpfile,~] = fileparts(obj.RawTrace.FilePath);
                tmpfile = fullfile(tmpfolder,[tmpfile,'PDVTrace.mat']);
                if isfile(tmpfile)
                    tmp = load(tmpfile);
                    if ischar(obj.AnalysisParameters)
                        obj.AnalysisParameters = tmp.AnalysisParameters;
                    end
                    if ischar(obj.ProcessedTrace)
                        obj.ProcessedTrace     = tmp.ProcessedTrace;
                    end
                    if ischar(obj.ProbeWavelengthNM)
                        obj.ProbeWavelengthNM = tmp.ProbeWavelengthNM;
                    end
                end
            end
        end
        function obj = Analyse(obj)
            obj.CheckDependency
            ParentFunctionInterfacingHandle = @ParentFunctionPullOutputs;
            if isstruct(obj.AnalysisParameters)
                if isstruct(obj.ProcessedTrace)
                    ChildApp.Handle = PdvAnalysis('ParentApp'           , ParentFunctionInterfacingHandle, ...
                                                  'Trace'               , obj.RawTrace, ...
                                                  'ProbeWavelengthNM'   , obj.ProbeWavelengthNM, ...
                                                  'Title'               , obj.Title, ...
                                                  'Parameters'          , obj.AnalysisParameters);
                else
                    ChildApp.Handle = PdvAnalysis('ParentApp'           , ParentFunctionInterfacingHandle, ...
                                                   'Trace'               , obj.RawTrace, ...
                                                   'ProbeWavelengthNM'   , obj.ProbeWavelengthNM, ...
                                                   'Title'               , obj.Title, ...
                                                   'Parameters'          , obj.AnalysisParameters, ...
                                                   'Automate'            , true);
                    
                end
            else
                    ChildApp.Handle = PdvAnalysis('ParentApp'               , ParentFunctionInterfacingHandle, ...
                                                   'Trace'                   , obj.RawTrace, ...
                                                   'ProbeWavelengthNM'       , obj.ProbeWavelengthNM, ...
                                                   'Title'                   , obj.Title);
            end
            
            waitfor(ChildApp.Handle)
            if isfield(ChildApp,'Outputs')
                % Parsing PDV Analysis outputs
                obj.ProcessedTrace = struct('Time'      , ChildApp.Outputs.Time, ...
                                            'Velocity'  , ChildApp.Outputs.Velocity, ...
                                            'Error'     , ChildApp.Outputs.Error);
                obj.AnalysisParameters = ChildApp.Outputs.Parameters;
                % Generating cache filename
                [filepath,name,~] = fileparts(obj.RawTrace.FilePath);
                filepath          = fullfile(filepath,[name,'PDVTrace']);
                % Creating Save struct
                PDVInfo           = struct('AnalysisParameters',obj.AnalysisParameters, ...
                                           'ProcessedTrace'    ,obj.ProcessedTrace,     ...
                                           'ProbeWavelengthNM' ,obj.ProbeWavelengthNM);
                % Saving to file
                save(filepath,'-struct','PDVInfo');
            end
            clearvars ChildApp
            
            function ParentFunctionPullOutputs(Outputs)
                if exist('Outputs','var')
                    ChildApp.Outputs = Outputs;
                end
            end
        end
        function obj = ResetAnalysis(obj)
            obj.AnalysisParameters = 'Not Defined';
            obj.ProcessedTrace     = 'Not Calculated';
            
            [filepath,name,~] = fileparts(obj.RawTrace.FilePath);
            filepath = fullfile(filepath,[name,'PDVTrace']);
            if isfile(filepath)
                delete(filepath)
            end
        end
        function       AnalysisSummary(obj)
            disp('PDV Trace Analysis:')
            disp(['Start Time [us]: ',obj.StartTimeUs])
            disp(['End Time [us]: ',obj.EndTimeUs])
            disp(['Start Frequency [GHz]: ',obj.StartFreqGHz])
            disp(['End Frequency [GHz]: ',obj.EndFreqGHz])
            disp(['Window Size [Samples]: ',obj.WindowSize])
            disp(['Overlap [Samples]: ',obj.Overlap])
        end
    end
    methods
        function Time       = get.Time(         obj)
            if ~isnan(obj.Delay)
                Time = obj.ProcessedTrace.Time - obj.Delay;
            else
                Time = obj.ProcessedTrace.Time;
            end
        end
        function Velocity   = get.Velocity(     obj)
            Velocity =  obj.ProcessedTrace.Velocity;
        end
        function Error      = get.Error(        obj)
            Error =  obj.ProcessedTrace.Error;
        end
        function StartTime  = get.StartTimeUs(  obj)
            if isstruct(obj.AnalysisParameters)
                StartTime = num2str(obj.AnalysisParameters.TransformProps.start_time * 1e6);
            else
                StartTime = 'Undefined';
            end
        end
        function EndTime    = get.EndTimeUs(    obj)
            if isstruct(obj.AnalysisParameters)
                EndTime = num2str(obj.AnalysisParameters.TransformProps.end_time * 1e6);
            else
                EndTime = 'Undefined';
            end
        end
        function StartFreq  = get.StartFreqGHz( obj)
            if isstruct(obj.AnalysisParameters)
                StartFreq = num2str(obj.AnalysisParameters.TransformProps.start_freq * 1e-9);
            else
                StartFreq = 'Undefined';
            end
        end
        function EndFreq    = get.EndFreqGHz(   obj)
            if isstruct(obj.AnalysisParameters)
                EndFreq = num2str(obj.AnalysisParameters.TransformProps.end_freq * 1e-9);
            else
                EndFreq = 'Undefined';
            end
        end
        function WindowSize = get.WindowSize(   obj)
            if isstruct(obj.AnalysisParameters)
                WindowSize = num2str(obj.AnalysisParameters.TransformProps.window_size);
            else
                WindowSize = 'Undefined';
            end
        end
        function Overlap    = get.Overlap(      obj)
            if isstruct(obj.AnalysisParameters)
                Overlap = num2str(obj.AnalysisParameters.TransformProps.overlap);
            else
                Overlap = 'Undefined';
            end
        end
        function              CheckDependency(  obj)
            if ~exist('ScopeTrace','file')
                addpath(obj.ScopeTracePath);
            end
        end
    end
end
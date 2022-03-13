classdef PdvTrace
% PdvTrace:  An object for containing everything about a PDV trace.
% 
% This object will manage raw data storage (using ScopeTrace dependency),
% analysis via its interface with the bundled PDVAnalysis GUI 
% (including analysis parameter storage, and analysis updating from prior 
% analyses) and cable delay inputs. 
%
% PdvTrace: Dependencies
% 
%   ScopeTrace - You can find this in a different repository on my profile.
% 
% PdvTrace: Installation
%
%   In order to use this class correctly you should:
%   
%   1 - Edit the value for the property ScopeTracePath. To find this you
%       can use the MATLAB documentation hyperlink or find 
%       %%ScopeTracePath%% in the PdvTrace.m file.
%   
%   2 - Edit the value for the property ScopeTracePath in PdvAnalysis.m. 
%       To find this you can use the MATLAB documentation hyperlink (in the
%       PdvAnalysis documentation) or find %%ScopeTracePath%% in
%       the PdvAnalysis.m file.
%   
%   Note: If you do not do these steps this object will not be able to 
%         interface with raw data properly.
%
% PdvTrace: Constructor Arguments (All given as Name Value Pairs):
%
%   "FilePath" - Absolute or relative file path to a raw oscilloscope file.
%                This will be imported using ScopeTrace.
%                               
%   "AnalysisParameters" - The analysis parameter struct that is outputted 
%                          from the PDVAnalysis GUI. [1]
%
%   "Delay" - The cable delay asscoiated with this trace (including fiber &
%              PDV channel delays) given in seconds. Default = 0.0
%                               
%   "Title" - A title for the associated PDV Trace, passed to PDVAnalysis
%             GUI for its UIFigure title.
%                               
%   "ProbeWavelengthNM" - The wavelength (in nm) of the probe laser. [2]
%                         Default = 1550
%   
%   Note: If run without arguments ScopeTrace will launch a file selection
%         diaglogue.
%
% See also ScopeTrace

    properties
        % RawTrace - This handles the raw data storage of the oscilloscope file. Including storage of any metadata and the ability to plot the raw data quickly.
        RawTrace ScopeTrace
        % Title - A title for the associated PDV Trace, passed to the PdvAnalysis GUI for its UIFigure title when using the Analyse() method.
        Title {mustBeText}
        % AnalysisParameters - The analysis parameter struct that is outputted from the PDVAnalysis GUI upon a successful analysis.
        AnalysisParameters struct
        % Delay - The cable delay asscoiated with this trace (including fiber & PDV channel delays) given in seconds.
        Delay {mustBeNumeric}
        % ProcessedTrace - This struct contains the results of a succesful PdvAnalysis. 
        ProcessedTrace struct
        % ProbeWavelengthNM - The wavelength (in nm) of the probe laser.
        ProbeWavelengthNM {mustBeNumeric}
        % ScopeTracePath - A valid path to a folder containing ScopeTrace, this must be correctly set for the script to work. If you set the default in the .m file it does not need setting each time.
        ScopeTracePath {mustBeFolder} = '~/Documents/GitHub/ImportScope'  %%ScopeTracePath%%
    end
    properties (Dependent)
        % Column vector containing time values for the analysed PDV trace.
        Time {mustBeNumeric}
        % Column vector containing velocity values for the analysed PDV trace.
        Velocity {mustBeNumeric}
        % Column vector containing velocity error values for the analysed PDV trace.
        Error {mustBeNumeric}
    end
    properties (Dependent,Access=private)
        StartTimeUs
        EndTimeUs
        WindowSize
        Overlap
        StartFreqGHz
        EndFreqGHz
    end
    methods
        function obj        = PdvTrace(InputArgs)
            %Valid Arguments - {"FilePath",  "AnalysisParameters",  "Delay",  "Title",  "ProbeWavelengthNM"}
            % 
            % INPUT "FilePath" - Absolute or relative file path to a raw 
            %                    oscilloscope file. This will be imported 
            %                    using ScopeTrace.
            %                               
            %       "AnalysisParameters" - The analysis parameter struct
            %                              that is outputted from the
            %                              PDVAnalysis GUI. [1]
            %                               
            %       "Delay" - The cable delay asscoiated with this trace
            %                 (including fiber & PDV channel delays) given
            %                 in seconds. Default = 0.0
            %                               
            %       "Title" - A title for the associated PDV Trace, passed
            %                 to PDVAnalysis GUI for its UIFigure title.
            %                               
            %       "ProbeWavelengthNM" - The wavelength (in nm) of the
            %                             probe laser. [2] Default = 1550
            %
            % OUTPUT  obj - The object.
            %
            % REMARKS   1) I wouldn't worry about this field too much,
            %              PDV Trace will save the analysis parameters in a
            %              cache alongside the raw data file and then
            %              automatically repopulate this when you pass it
            %              a raw data file (that has an associated
            %              analysis cache file.
            %           
            %           2) This sets the velocity scale and its important
            %               you get it correct (so note down when doing
            %               experiments). The default is set at 1550
            %               (which I use always so as to avoid issues if
            %               I forget it).
            %
            arguments         
                InputArgs.FilePath              = 'Undefined'; 
                InputArgs.AnalysisParameters    = 'Undefined';
                InputArgs.Delay                 = 0;
                InputArgs.ProcessedTrace        = 'Not Calculated';
                InputArgs.Title                 = 'Generic PDV Trace'
                InputArgs.ProbeWavelengthNM     = 1550;
            end
            obj.CheckDependency
            
            switch InputArgs.FilePath
                case 'Undefined'
                    obj.RawTrace    = ScopeTrace;
                otherwise
                    obj.RawTrace    = ScopeTrace('FilePath', ...
                                                 InputArgs.FilePath);
            end
            obj.AnalysisParameters  = InputArgs.AnalysisParameters;
            obj.Delay               = InputArgs.Delay;
            obj.ProcessedTrace      = InputArgs.ProcessedTrace;
            obj.Title               = InputArgs.Title;
            obj.ProbeWavelengthNM   = InputArgs.ProbeWavelengthNM;
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
        function obj        = Analyse(obj)
            %Analyse Run analysis on stored data using PDVAnalysis GUI.
            %
            % When using this method if you want to store the analysis
            % within scope trace you should click Return&Close when you've
            % finished with the GUI and are happy with the trace. Note that
            % if a ProcessedTrace already exists within the object it will
            % use the parameters from this trace as the starting state of
            % the GUI.
            %
            % INPUT   obj - The object.
            % 
            % OUTPUT  obj - The object, with an updated ProcessedData 
            %               and AnalysisParameter properties.
            %
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
        function obj        = ResetAnalysis(obj)
            %ResetAnalysis Remove a ProcessedTrace and clear the associated cache file.
            %
            % This method will remove any processed data and analysis 
            % parameters from the object, as well as deleting the cache of 
            % the processed data being deleted.
            %
            % INPUT   obj - The object.
            % 
            % OUTPUT  obj - The object, with freshly emptied 
            %               ProcessedTrace and AnalysisParameters
            %               properties.

            obj.AnalysisParameters = 'Not Defined';
            obj.ProcessedTrace     = 'Not Calculated';
            
            [filepath,name,~] = fileparts(obj.RawTrace.FilePath);
            filepath = fullfile(filepath,[name,'PDVTrace']);
            if isfile(filepath)
                delete(filepath)
            end
        end
        function              AnalysisSummary(obj)
            %AnalysisSummary Display analysis properties of ProcessedTrace.
            %
            % This method will display the analysis properties for the
            % ProcessedTrace stored within the object.
            %
            % INPUT   obj - The object.
            % 
            % OUTPUT  none - Output is not assignable, this functions
            %                purely to display the analysis properties, if
            %                you wish to access the properties see the
            %                AnalysisParameters field within the
            %                ProcessedTrace object property.
            disp('PDV Trace Analysis:')
            disp(['Start Time [us]: ',obj.StartTimeUs])
            disp(['End Time [us]: ',obj.EndTimeUs])
            disp(['Start Frequency [GHz]: ',obj.StartFreqGHz])
            disp(['End Frequency [GHz]: ',obj.EndFreqGHz])
            disp(['Window Size [Samples]: ',obj.WindowSize])
            disp(['Overlap [Samples]: ',obj.Overlap])
        end
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
    end
    methods (Access=private)
        function              CheckDependency(  obj)
            if ~exist('ScopeTrace','file')
                addpath(obj.ScopeTracePath);
            end
        end
    end
end
classdef PdvTrace
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
        function obj = PdvTrace(inputargs)
            arguments
                inputargs.FilePath              = 'Undefined';
                inputargs.AnalysisParameters    = 'Undefined';
                inputargs.Delay                 = 0;
                inputargs.ProcessedTrace        = 'Not Calculated';
                inputargs.Title                 = 'Generic PDV Trace'
                inputargs.ProbeWavelengthNM     = 1550;
            end
            
            if strcmp(inputargs.FilePath,'Undefined')
                obj.RawTrace            = ScopeTrace('FilePath',obj.GetFile);
            else
                obj.RawTrace            = ScopeTrace('FilePath',inputargs.FilePath);
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
            
            ParentFunctionInterfacingHandle = @ParentFunctionPullOutputs;
            
            if strcmp(obj.AnalysisParameters,'Undefined')
                ChildApp.Handle = PdvAnalysis('ParentApp'               , ParentFunctionInterfacingHandle, ...
                                              'Trace'                   , obj.RawTrace, ...
                                              'ProbeWavelengthNM'       , obj.ProbeWavelengthNM, ...
                                              'Title'                   , obj.Title);
            else
                if strcmp(obj.ProcessedTrace,'Not Calculated')
                    ChildApp.Handle = PdvAnalysis('ParentApp'           , ParentFunctionInterfacingHandle, ...
                                                  'Trace'               , obj.RawTrace, ...
                                                  'ProbeWavelengthNM'   , obj.ProbeWavelengthNM, ...
                                                  'Title'               , obj.Title, ...
                                                  'Parameters'          , obj.AnalysisParameters, ...
                                                  'Automate'            , true);
                else
                    ChildApp.Handle = PdvAnalysis('ParentApp'           , ParentFunctionInterfacingHandle, ...
                                                  'Trace'               , obj.RawTrace, ...
                                                  'ProbeWavelengthNM'   , obj.ProbeWavelengthNM, ...
                                                  'Title'               , obj.Title, ...
                                                  'Parameters'          , obj.AnalysisParameters);
                end
            end
            waitfor(ChildApp.Handle)
            
            if isfield(ChildApp,'Outputs')
                tmp = ChildApp.Outputs;
                
                obj.ProcessedTrace = struct('Time'      , tmp.Time, ...
                                            'Velocity'  , tmp.Velocity, ...
                                            'Error'     , tmp.Error);
                
                obj.AnalysisParameters = tmp.Parameters;
                
                % Saving to file
                [filepath,name,~] = fileparts(obj.RawTrace.FilePath);
                filepath = fullfile(filepath,[name,'PDVTrace']);
                PDVInfo = struct('AnalysisParameters',obj.AnalysisParameters,'ProcessedTrace',obj.ProcessedTrace,'ProbeWavelengthNM',obj.ProbeWavelengthNM);
                save(filepath,'-struct','PDVInfo');
            end
            clearvars ChildApp
            
            function ParentFunctionPullOutputs(Outputs)
                if exist('Outputs') %#ok<EXIST>
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
        function AnalysisSummary(obj)
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
        function Time       = get.Time(obj)
            if ~isnan(obj.Delay)
                Time = obj.ProcessedTrace.Time - obj.Delay;
            else
                Time = obj.ProcessedTrace.Time;
            end
        end
        
        function Velocity   = get.Velocity(obj)
            Velocity =  obj.ProcessedTrace.Velocity;
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
    
    methods (Static)
        function FullFilePath = GetFile
            [File,Path] = uigetfile('*');
            if ~isnumeric(File)
                FullFilePath = fullfile(Path,File);
            else
                FullFilePath = '';
            end
        end
    end
end
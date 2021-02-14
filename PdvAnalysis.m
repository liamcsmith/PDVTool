classdef PdvAnalysis < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        PdvAnalysisFigure               matlab.ui.Figure
        RawPlot                         matlab.ui.control.UIAxes
        CropPlot                        matlab.ui.control.UIAxes
        ProcessedPlot                   matlab.ui.control.UIAxes
        VelocityPlot                    matlab.ui.control.UIAxes
        CropSpectrogramButton           matlab.ui.control.Button
        ProcessBaselineButton           matlab.ui.control.Button
        SetROIButton                    matlab.ui.control.Button
        ConfirmRoiButton                matlab.ui.control.Button
        ShiftSwitchButton               matlab.ui.control.Button
        ExtractVelocitiesButton         matlab.ui.control.Button
        ReturnCloseButton               matlab.ui.control.Button
        ResetROIButton                  matlab.ui.control.Button
        BaselineCorrectionToggle        matlab.ui.control.Switch
        ReprocessRawButton              matlab.ui.control.Button
        ReadyLampLabel                  matlab.ui.control.Label
        ReadyLamp                       matlab.ui.control.Lamp
        RecalculateVelocitiesButton     matlab.ui.control.Button
        IdentifyOffsetButton            matlab.ui.control.Button
        RemoveOffsetButton              matlab.ui.control.Button
        RawNfftPtsEditFieldLabel        matlab.ui.control.Label
        RawNfftField                    matlab.ui.control.NumericEditField
        RawWindowSizePtsEditFieldLabel  matlab.ui.control.Label
        RawWindowSizeField              matlab.ui.control.NumericEditField
        StartTimesEditFieldLabel_2      matlab.ui.control.Label
        StartTimeField                  matlab.ui.control.NumericEditField
        EndTimesEditFieldLabel_2        matlab.ui.control.Label
        EndTimeField                    matlab.ui.control.NumericEditField
        MinFrequencyGHzEditFieldLabel_2  matlab.ui.control.Label
        MinFrequencyField               matlab.ui.control.NumericEditField
        MaxFrequencyGHzEditFieldLabel   matlab.ui.control.Label
        MaxFrequencyField               matlab.ui.control.NumericEditField
        CropNfftPtsEditFieldLabel_2     matlab.ui.control.Label
        CropNfftField                   matlab.ui.control.NumericEditField
        CropWindowSizePtsEditFieldLabel  matlab.ui.control.Label
        CropWindowSizeField             matlab.ui.control.NumericEditField
        CropOverlapPtsLabel             matlab.ui.control.Label
        CropOverlapField                matlab.ui.control.NumericEditField
        BreakoutStartTimesEditFieldLabel  matlab.ui.control.Label
        BreakoutStartTimeField          matlab.ui.control.NumericEditField
        BreakoutEndTimesEditFieldLabel  matlab.ui.control.Label
        BreakoutEndTimeField            matlab.ui.control.NumericEditField
        BaselineFrequencyGhzEditFieldLabel  matlab.ui.control.Label
        BaselineFrequencyField          matlab.ui.control.NumericEditField
        RemoveBaselineLabel             matlab.ui.control.Label
        ProbeLaserWavelengthnmLabel     matlab.ui.control.Label
        WavelengthField                 matlab.ui.control.NumericEditField
        OffsetSampleStartTimesLabel     matlab.ui.control.Label
        OffsetSampleStartTimeField      matlab.ui.control.NumericEditField
        OffsetSampleEndTimesLabel       matlab.ui.control.Label
        OffsetSampleEndTimeField        matlab.ui.control.NumericEditField
        ZeroVeloctymsLabel_2            matlab.ui.control.Label
        ZeroVelocityField               matlab.ui.control.NumericEditField
        FloatingBaselineToggle          matlab.ui.control.Switch
        FloatingBaselineLabel           matlab.ui.control.Label
        ImportTraceButton               matlab.ui.control.Button
        SaveFigureButton                matlab.ui.control.Button
        FigureChoiceDropDown            matlab.ui.control.DropDown
        ImportParametersButton          matlab.ui.control.Button
        BandwidthGHzLabel               matlab.ui.control.Label
        BandwidthField                  matlab.ui.control.NumericEditField
        ImportH5DatasetButton           matlab.ui.control.Button
        SaveFilematButton               matlab.ui.control.Button
        FileSaveDropDown                matlab.ui.control.DropDown
    end

    
    properties (Access = private)
        Data                    % Storage for time and voltage arrays, as well as a few trace dependat characteristics (fs and f0)
        RawTransform            % The raw transform and lines located on the raw transform plot
        CropTransform           % The crop transform and lines located on the crop transform plot
        ProcessedTransform      % The processed transform and lines located on the processed transform plot
        VelocityTransform       % The velocity transform and lines located on the velocity transform plot
        Velocity                = [];
        ChildApp                % Location for storing H5 dbpull app
        ParentApp               % Location for storing parent app
    end
    
    properties (Access = public)
    end
    
    properties (Dependent)
        RawProps
        TransformProps
        Outputs
    end
    
    methods
        function TransformProps = get.TransformProps(app)
            
            TransformProps.nfft         = app.CropNfftField.Value;
            TransformProps.window_size  = app.CropWindowSizeField.Value;
            TransformProps.overlap      = app.CropOverlapField.Value;
            
            [~, TransformProps.start_index] = min(abs(app.Data.t - (app.StartTimeField.Value * 1e-6)));
            [~, TransformProps.end_index]   = min(abs(app.Data.t - (app.EndTimeField.Value   * 1e-6)));
            TransformProps.start_time       = app.Data.t(TransformProps.start_index);
            TransformProps.end_time         = app.Data.t(TransformProps.end_index);
            
            TransformProps.start_freq   = app.MinFrequencyField.Value * 1e9;
            TransformProps.end_freq     = app.MaxFrequencyField.Value * 1e9;
        end
        function RawProps = get.RawProps(app)
            RawProps.start_time     = app.Data.t(1);
            RawProps.end_time       = app.Data.t(end);
            RawProps.start_index    = 1;
            RawProps.end_index      = numel(app.Data.t);
            RawProps.nfft           = app.RawNfftField.Value;
            RawProps.window_size    = app.RawWindowSizeField.Value;
            RawProps.start_freq     = 0;
            RawProps.end_freq       = app.BandwidthField.Value * 1e9;
            RawProps.overlap        = 0;
        end
        function Outputs = get.Outputs(app)
            
            if ~isempty(app.Velocity)
                Outputs.Time     = app.Velocity(:,1);
                Outputs.Velocity = app.Velocity(:,2);
                Outputs.Error    = app.Velocity(:,3);
            end
            
            Outputs.Parameters.RawProps        = app.RawProps;
            Outputs.Parameters.TransformProps  = app.TransformProps;
            
            Outputs.Parameters.BaselineRemoval = app.BaselineCorrectionToggle.Value;
            if strcmp(Outputs.Parameters.BaselineRemoval,'On')
                Outputs.Parameters.BaselineRemoval = struct('BreakoutStartTime',app.BreakoutStartTimeField.Value, ...
                                                            'BreakoutEndTime',app.BreakoutEndTimeField.Value, ...
                                                            'FloatingBaseline',app.FloatingBaselineToggle.Value);
            end
            
            if all(isfield(app.ProcessedTransform,{'roi','roiplot'}))
                Outputs.Parameters.ROI = struct('Mask',app.ProcessedTransform.roi.createMask,...
                                                'Points',app.ProcessedTransform.roi.Position);
            end
            
            Outputs.Parameters.ProbeWavelength        = app.WavelengthField.Value;
            Outputs.Parameters.VelocityScaleInversion = app.VelocityTransform.ScaleInversion;
            
            if app.ZeroVelocityField.Value ~= 0 || (app.OffsetSampleStartTimeField.Value ~=0 && app.OffsetSampleEndTimeField.Value ~= 0)
                Outputs.Parameters.VelocityOffset = struct('SampleStartTime',app.OffsetSampleStartTimeField.Value * 1e-6, ...
                                                           'SampleEndTime',app.OffsetSampleEndTimeField.Value * 1e-6);
            end
            
        end
    end
    
    methods (Access = private)
        % Functions for simplifying the code
        function app       = compute_raw_spectrogram(app)
            % Pulling raw settings (that could change) from the GUI
            Props = app.RawProps;
            
            % Setting some of the raw properties as default values for the
            % crop settings fields.
            app.StartTimeField.Value        = Props.start_time * 1e6;
            app.EndTimeField.Value          = Props.end_time   * 1e6;
            app.MinFrequencyField.Value     = Props.start_freq / 1e9;
            app.MaxFrequencyField.Value     = Props.end_freq   / 1e9;
            
            % Computing the raw transform
            app.RawTransform = compute_spectrogram(app,app.Data,Props);
            
            % Plotting the raw transform
            plot_freq_spectrogram(app,app.RawPlot,app.RawTransform,'Rough Spectrogram',Props)
            
            % Replotting guide lines
            StartTimeFieldValueChanged(app)
            EndTimeFieldValueChanged(app)
            MinFrequencyFieldValueChanged(app)
            MaxFrequencyFieldValueChanged(app)
        end
        function app       = compute_crop_spectrogram(app)
            
            % Computing cropped spectrogram
            app.CropTransform = compute_spectrogram(app,app.Data,app.TransformProps);
            
            % Plotting cropped spectrogram
            plot_freq_spectrogram(app,app.CropPlot,app.CropTransform,'Cropped Spectrogram')
        end
        
        % Functions relating to the spectrograms
        function [TimeVelocityAndError,Coeffs] = fit_gaussian(app,Time,signal,BestGuess) %#ok
            [xData, yData] = prepareCurveData( [], rescale(signal) );
            [Result,~] = fit(xData,yData,...
                             'gauss1',...
                             'Display','off',...
                             'Lower',[-Inf -Inf 0],...
                             'StartPoint',BestGuess);
            Coeffs = coeffvalues(Result);
            Errors = confint(Result);
            TimeVelocityAndError = [Time,Coeffs(1,2),Errors(2,2) - Errors(1,2)];
        end
        function transform = compute_spectrogram(app,data,props) %#ok
        
        [~, transform.F, transform.T, transform.P] = spectrogram(data.v(props.start_index:props.end_index),...
                                                                 props.window_size,...
                                                                 props.overlap,...
                                                                 linspace(props.start_freq,props.end_freq,props.nfft),...
                                                                 data.fs,...
                                                                 'yaxis');
        end
        function transform = compute_spectrogram_baseline_removed(app,data,props) %#ok
        
        [~, transform.F, transform.T, transform.P] = spectrogram(data.v_baseline_removed(props.start_index:props.end_index),...
                                                                 props.window_size,...
                                                                 props.overlap,...
                                                                 linspace(props.start_freq,props.end_freq,props.nfft),...
                                                                 data.fs,...
                                                                 'yaxis');
        end
        function             plot_freq_spectrogram(app,axes,transform,title,props)
            if ~exist('props') %#ok<EXIST> 
                props = app.TransformProps;
            end
            hold(axes,'off')
            imagesc(axes,...
                    1e6*(transform.T+props.start_time),...
                    1e-9*(transform.F),...
                    log10(transform.P),...
                    [min(min(log10(transform.P))) max(max(log10(transform.P)))])
            set(axes,'YDir','normal')
            set(axes,'TickLabelInterpreter','none')
            set(axes,'FontName','Helvetica')
            ylabel(axes,'Frequency (GHz)','Interpreter','none','FontName','Helvetica')
            xlabel(axes,'Time (us)','Interpreter','none','FontName','Helvetica')
            xlim(axes,[props.start_time props.end_time]*1e6)
            ylim(axes,[props.start_freq props.end_freq]./1e9)
            set(get(axes, 'title'), 'string', title)
            set(get(axes, 'title'), 'Interpreter', 'none')
            set(axes,'Layer','top')
        end
        function             plot_vel_spectrogram( app,axes) 
            hold(axes,"off")
            transform = app.VelocityTransform;
            TimeAxes = 1e6*(transform.T+app.TransformProps.start_time);
            imagesc(axes,...
                    TimeAxes,...
                    transform.velocity_scale, ...
                    log10(transform.P),...
                    [min(min(log10(transform.P))) max(max(log10(transform.P)))]);
            set(axes,'YAxisLocation','right')
            set(axes,'YDir','normal')
            set(axes,'TickLabelInterpreter','none')
            set(axes,'FontName','Helvetica')
            ylabel(axes,'Velocity (m/s)','Interpreter','none','FontName','Helvetica')
            xlabel(axes,'Time (us)','Interpreter','none','FontName','Helvetica')
            xlim(axes,[min(TimeAxes) max(TimeAxes)])
            ylim(axes,[min(transform.velocity_scale) max(transform.velocity_scale)])
            set(get(axes, 'title'), 'string', 'Velocity Spectrogram')
            set(get(axes, 'title'), 'Interpreter', 'none')
            set(axes,'Layer','top')
        end
    
        function LoadParameters(app,Parameters)
            % Raw Data
            PopulateRawFields
            if DataExists
                ReprocessRawButtonButtonPushed(app)
                ComputedRaw = true;
            else
                ComputedRaw = false;
            end
            
            % Crop Data
            PopulateCropFields
            if DataExists && ComputedRaw
                CropSpectrogramButtonPushed(app)
                ComputedCrop = true;
            else
                ComputedCrop = false;
            end
            
            % Baseline Removal
            if BaselineRemovalSpecified
                PopulateBaselineFields
                if ComputedCrop
                    ProcessBaselineButtonPushed(app)
                    ComputedProc = true;
                else
                    ComputedProc = false;
                end
            else
                ComputedProc = ComputedCrop;
            end
            
            % Region of interest
            if  ComputedProc && ValidRoiSpecified
                InsertRoi
            end
            
            % Processed Data
            if ComputedProc
                ConfirmRoiButtonButtonPushed(app)
                ComputedVel = true;
            else
                ComputedVel = false;
            end
            
            % Velocity Data
            if ComputedVel
                RecalculateVelocitiesButtonPushed(app)
                if InvertedVelocityScale
                    ShiftSwitchButtonButtonPushed(app)
                end
                ExtractVelocitiesButtonButtonPushed(app)
                if OffsetVelocities
                    PopulateVelocityOffsetFields
                    IdentifyOffsetButtonPushed(app)
                    RemoveOffsetButtonPushed(app)
                end
            end
            
            function PopulateRawFields
                app.RawNfftField.Value          = Parameters.RawProps.nfft;
                app.RawWindowSizeField.Value    = Parameters.RawProps.window_size;
                app.BandwidthField.Value        = Parameters.RawProps.end_freq / 1e9;
                app.WavelengthField.Value       = Parameters.ProbeWavelength;
            end
            function Out = DataExists
                Out = all(isfield(app.Data,{'t','v','fs'}));
            end
            function PopulateCropFields
                app.CropNfftField.Value       = Parameters.TransformProps.nfft;
                app.CropWindowSizeField.Value = Parameters.TransformProps.window_size;
                app.CropOverlapField.Value    = Parameters.TransformProps.overlap;
                
                app.StartTimeField.Value      = Parameters.TransformProps.start_time * 1e6;
                StartTimeFieldValueChanged(app)
                app.EndTimeField.Value        = Parameters.TransformProps.end_time   * 1e6;
                EndTimeFieldValueChanged(app)
                app.MinFrequencyField.Value = Parameters.TransformProps.start_freq   / 1e9;
                MinFrequencyFieldValueChanged(app)
                app.MaxFrequencyField.Value = Parameters.TransformProps.end_freq     / 1e9;
                MaxFrequencyFieldValueChanged(app)
            end
            function Out = BaselineRemovalSpecified
                Out = isstruct(Parameters.BaselineRemoval);
            end
            function PopulateBaselineFields
                app.BaselineCorrectionToggle.Value = 'On';
                app.BreakoutStartTimeField.Value   = Parameters.BaselineRemoval.BreakoutStartTime;
                BreakoutStartTimeFieldValueChanged(app)
                app.BreakoutEndTimeField.Value     = Parameters.BaselineRemoval.BreakoutEndTime;
                BreakoutEndTimeFieldValueChanged(app)
                app.FloatingBaselineToggle.Value   = Parameters.BaselineRemoval.FloatingBaseline;
            end
            function Out = ValidRoiSpecified
                Condition1 = isfield(Parameters,'ROI');
                if Condition1
                    Condition2 = all(size(Parameters.ROI.Mask) == size(app.ProcessedTransform.P));
                else
                    Condition2 = false;
                end
                Out = Condition1 && Condition2;
            end
            function InsertRoi
                app.ProcessedTransform.roi = drawpolygon(app.ProcessedPlot, ...
                                                        'Position',Parameters.ROI.Points, ...
                                                        'FaceAlpha',0,...
                                                        'Deletable',false);
            end
            function Out = InvertedVelocityScale
                Out = Parameters.VelocityScaleInversion;
            end
            function Out = OffsetVelocities
                Out = isfield(Parameters,'VelocityOffset');
            end
            function PopulateVelocityOffsetFields
                app.OffsetSampleStartTimeField.Value = Parameters.VelocityOffset.SampleStartTime  * 1e6;
                OffsetSampleStartTimeFieldValueChanged(app)
                app.OffsetSampleEndTimeField.Value   = Parameters.VelocityOffset.SampleEndTime  * 1e6;
                OffsetSampleEndTimeFieldValueChanged(app)
            end
        end
    end    
    methods (Access = public)
        function ParentAppPullOutputs(app,Outputs)  
            if exist('Outputs') %#ok<EXIST> 
                app.ChildApp.Outputs = Outputs;
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function PdvAnalysisStartup(app, inputargs)
            arguments
                app
                inputargs.Time      {mustBeNumeric};
                inputargs.Voltage   {mustBeNumeric};
                inputargs.Trace     
                inputargs.Parameters
                inputargs.Automate = false
                inputargs.Title     string
                inputargs.ParentApp
            end
            opengl HARDWAREBASIC
            
            app.ReadyLamp.Color = 'r';
            if isfield(inputargs,'Title')
                app.PdvAnalysisFigure.Name = inputargs.Title;
            end
            
            if isfield(inputargs,'ParentApp')
                app.ParentApp = inputargs.ParentApp;
            end
            
            if isfield(inputargs,'Trace')
                app.Data.t  = inputargs.Trace.time;
                app.Data.v  = inputargs.Trace.voltage;
                app.Data.fs = 1/abs(app.Data.t(2)-app.Data.t(1));
            elseif all(isfield(inputargs,{'Time','Voltage'}))
                app.Data.t  = inputargs.Time;
                app.Data.v  = inputargs.Voltage;
                app.Data.fs = 1/abs(app.Data.t(2)-app.Data.t(1));
            end
            
            if all(isfield(app.Data,{'t','v','fs'}))
                ReprocessRawButtonButtonPushed(app)
            end
                
            if isfield(inputargs,'Parameters')
                LoadParameters(app,inputargs.Parameters)
            end
            
            if inputargs.Automate && ~isempty(app.Velocity)
                ReturnCloseButtonButtonPushed(app)
            end
            
            
            app.ReadyLamp.Color = 'g';
            
        end

        % Button pushed function: CropSpectrogramButton
        function CropSpectrogramButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            app = compute_crop_spectrogram(app);
            
            % Copying data across to post baseline removal if baseline toggle set to 'off'
            if strcmp(app.BaselineCorrectionToggle.Value,'Off')
                % Copying cropped data to processed data
                app.ProcessedTransform = app.CropTransform;
                
                % Plotting processed spectrogram (has no baseline removal at the moment)
                plot_freq_spectrogram(app,app.ProcessedPlot,app.ProcessedTransform,'Processed Spectrogram')
            end
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ReprocessRawButton
        function ReprocessRawButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Refreshing values for nfft and window size from GUI
            app = compute_raw_spectrogram(app);
            
            % ReadyLamp to green
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: SetROIButton
        function SetROIButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Removing any current ROI
            ResetROIButtonButtonPushed(app,event)
            
            % Specifying ROI % SHIFT TO IMPOLY
            app.ProcessedTransform.roi = drawpolygon(app.ProcessedPlot,'FaceAlpha',0,'Deletable',false);
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ResetROIButton
        function ResetROIButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            if isfield(app.ProcessedTransform,{'roi'})
                delete(app.ProcessedTransform.roi)
                app.ProcessedTransform = rmfield(app.ProcessedTransform,{'roi'});
                if isfield(app.ProcessedTransform,'roiplot')
                    delete(app.ProcessedTransform.roiplot)
                    app.ProcessedTransform = rmfield(app.ProcessedTransform,{'roiplot'});
                end
            end
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ConfirmRoiButton
        function ConfirmRoiButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Copying processed data to velocity data
            app.VelocityTransform = app.ProcessedTransform;
            app.VelocityTransform.ScaleInversion = false;
            app.Velocity = [];
            
            % Applying the ROI if one has been set
            if isfield(app.ProcessedTransform,'roi')
                mask = app.ProcessedTransform.roi.createMask;
                app.ProcessedTransform.roi.Visible = 'off';
                roipts = app.ProcessedTransform.roi.Position;
                hold(app.ProcessedPlot,"on")
                app.ProcessedTransform.roiplot = plot(app.ProcessedPlot,[roipts(:,1);roipts(1,1)],[roipts(:,2);roipts(1,2)],'Color','k');
                app.VelocityTransform.P = app.VelocityTransform.P .* mask;
            end
                        
            % Removing any empty timesteps from velocity data
            col_to_remove = ~any(app.VelocityTransform.P); % THIS MIGHT HAVE AN ISSUE
            app.VelocityTransform.P(:,col_to_remove) = [];
            app.VelocityTransform.T(:,col_to_remove) = [];
            clearvars col_to_remove
            
            % Setting the velocity scale from the frequency scale
            app.VelocityTransform.velocity_scale = 0.5*(1e-9 * app.WavelengthField.Value)*app.VelocityTransform.F-app.ZeroVelocityField.Value;
            
            % Removing empty velocity regions from the data
            row_to_remove = ~any(app.VelocityTransform.P,2);
            app.VelocityTransform.P(row_to_remove,:) = [];
            app.VelocityTransform.F(row_to_remove,:) = [];
            app.VelocityTransform.velocity_scale(row_to_remove,:) = [];
            clearvars row_to_remove
            
            % Plotting the velocity spectrogram
            plot_vel_spectrogram(app,app.VelocityPlot)
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ShiftSwitchButton
        function ShiftSwitchButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Removing the extracted velocity line and the output field if they have been created.
            if isfield(app.VelocityTransform,'extracted_velocity_line')
                delete(app.VelocityTransform.extracted_velocity_line)
                app.VelocityTransform   = rmfield(app.VelocityTransform,'extracted_velocity_line');
                app.Velocity = [];
            end
            
            % Reversing the velocity scale to swap between upshift and downshift
            app.VelocityTransform.P = flip(app.VelocityTransform.P,1);
            app.VelocityTransform.ScaleInversion = ~app.VelocityTransform.ScaleInversion;
            
            % Replotting the velocity spectrogram
            plot_vel_spectrogram(app,app.VelocityPlot)
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ExtractVelocitiesButton
        function ExtractVelocitiesButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            if isfield(app.VelocityTransform,'extracted_velocity_line')
                delete(app.VelocityTransform.extracted_velocity_line)
                app.VelocityTransform   = rmfield(app.VelocityTransform,'extracted_velocity_line');
                app.Velocity = [];
            end
            
            app.Velocity = zeros(length(app.VelocityTransform.T),3);
            
            % Creating the initial guess for the gaussian fit
            [~,init_velocity_guess] = max(app.VelocityTransform.P(:,1)); %this finds the index
            Coeffs = [1 init_velocity_guess 10]; %the peak velocity is scaled down by the max velocity so, amplitude a=1. b is the index. c=10 is the std dev guess.
            
            % Fitting all following timesteps iteratively using previous fit as a guide.
            for i = 1:numel(app.VelocityTransform.T)
                [app.Velocity(i,:),Coeffs] = fit_gaussian(  app,...
                                                            app.VelocityTransform.T(i) + app.TransformProps.start_time,...
                                                            app.VelocityTransform.P(:,i),...
                                                            Coeffs);
            end
            
            % Mapping the velocity and error vectors from pixel space to velocity space.
            app.Velocity(:,2) = interp1(1:numel(app.VelocityTransform.velocity_scale), ...
                                        app.VelocityTransform.velocity_scale, ...
                                        app.Velocity(:,2));
            app.Velocity(:,3) = app.Velocity(:,3) * abs(app.VelocityTransform.velocity_scale(2)-app.VelocityTransform.velocity_scale(1));
            
            % Plotting the extracted velocity line
            hold(app.VelocityPlot,'on')
            app.VelocityTransform.extracted_velocity_line = plot(app.VelocityPlot,app.Velocity(:,1)*1e6,app.Velocity(:,2),'Color','r','LineWidth',1);
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ReturnCloseButton
        function ReturnCloseButtonButtonPushed(app, event)
            if isempty(app.ParentApp)
                assignin("base","PdvAnalysisData",app.Outputs);
            else
                if isa(app.ParentApp,'function_handle')
                    try app.ParentApp(app.Outputs)
                        PdvAnalysisCloseRequest(app)
                    catch 
                        DialogBox(app,'Parent app not correctly interfacing.')
                    end
                else
                    try ParentAppPullOutputs(app.ParentApp,app.Outputs) %#ok<ADMTHDINV> 
                        PdvAnalysisCloseRequest(app)
                    catch
                        DialogBox(app,'Parent app not correctly interfacing.')
                    end
                end
            end
            PdvAnalysisCloseRequest(app)
        end

        % Button pushed function: RecalculateVelocitiesButton
        function RecalculateVelocitiesButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Removing the extracted velocity line and the output field if they have been created.
            if isfield(app.VelocityTransform,'extracted_velocity_line')
                delete(app.VelocityTransform.extracted_velocity_line)
                app.VelocityTransform = rmfield(app.VelocityTransform,'extracted_velocity_line');
                app.Velocity = [];
            end
            
            % Recalculating velocity scale
            app.VelocityTransform.velocity_scale = 0.5*(1e-9 * app.WavelengthField.Value)*app.VelocityTransform.F-app.ZeroVelocityField.Value;
            
            % Replotting velocity spectrogram
            plot_vel_spectrogram(app,app.VelocityPlot)
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: IdentifyOffsetButton
        function IdentifyOffsetButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            try
                %Identifying indices of sample region
                [~, start_index] = min(abs(1e6*(app.VelocityTransform.T+app.TransformProps.start_time) - app.OffsetSampleStartTimeField.Value));
                [~, end_index]   = min(abs(1e6*(app.VelocityTransform.T+app.TransformProps.start_time) - app.OffsetSampleEndTimeField.Value));
                
                % Setting 'Zero' Velocity Field Value to the mean of sample region.
                app.ZeroVelocityField.Value = mean(app.Velocity(start_index:end_index,2));
                OffsetSampleStartTimeFieldValueChanged(app)
                OffsetSampleEndTimeFieldValueChanged(app)
            catch
                % Incase user has not extracted velocities
                ExtractVelocitiesButtonButtonPushed(app,event)
                IdentifyOffsetButtonPushed(app,event)
            end
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: RemoveOffsetButton
        function RemoveOffsetButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            try
                % Shifting velocity vector in app.output
                app.Velocity(:,2) = app.Velocity(:,2) - app.ZeroVelocityField.Value;
                
                % Shifting velocity scale
                app.VelocityTransform.velocity_scale = app.VelocityTransform.velocity_scale-app.ZeroVelocityField.Value;
                
                % Replotting the velocity spectrogram with corrected velocities.
                plot_vel_spectrogram(app,app.VelocityPlot)
                hold(app.VelocityPlot,'on')
                plot(app.VelocityPlot,app.Velocity(:,1)*1e6,app.Velocity(:,2),"Color",'r','LineWidth',1)
            catch
                % Incase user has not identified the offset prior to removing it.
                IdentifyOffsetButtonPushed(app)
                RemoveOffsetButtonPushed(app)
            end
            
            app.ReadyLamp.Color = 'g';
        end

        % Value changed function: BreakoutEndTimeField
        function BreakoutEndTimeFieldValueChanged(app, event)
            % Try to delete any existing line
            if isfield(app.CropTransform,'breakout_end_line')
                delete(app.CropTransform.breakout_end_line)
                app.CropTransform = rmfield(app.CropTransform,'breakout_end_line');
            end
            
            hold(app.CropPlot,'on')
            
            % Try to plot onto CropPlot
            try
                app.CropTransform.breakout_end_line = plot(app.CropPlot,([app.BreakoutEndTimeField.Value,app.BreakoutEndTimeField.Value]),([min(app.CropTransform.F) max(app.CropTransform.F)]*1e-9),'Color','k');
            catch
            end  
        end

        % Value changed function: BreakoutStartTimeField
        function BreakoutStartTimeFieldValueChanged(app, event)
            % Try to delete any existing line
            if isfield(app.CropTransform,'breakout_start_line')
                delete(app.CropTransform.breakout_start_line)
                app.CropTransform = rmfield(app.CropTransform,'breakout_start_line');
            end
            
            hold(app.CropPlot,'on')
            
            % Try to plot onto CropPlot
            try
                app.CropTransform.breakout_start_line = plot(app.CropPlot,([app.BreakoutStartTimeField.Value,app.BreakoutStartTimeField.Value]),([min(app.CropTransform.F) max(app.CropTransform.F)]*1e-9),'Color','k');    
            catch
            end
        end

        % Button pushed function: ProcessBaselineButton
        function ProcessBaselineButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % If we process the paseline the toggle should be set to 'On'
            if strcmp(app.BaselineCorrectionToggle.Value,'Off')
                app.BaselineCorrectionToggle.Value = 'On';
                drawnow
            end
            
            % Setting the properties to match those of the crop properties
            TempProps = app.TransformProps;
            
            % Changing the end time and index to select only the pre impact (breakout) region.
            TempProps.end_time        = app.BreakoutStartTimeField.Value * 1e-6;
            [~, TempProps.end_index]  = min(abs(app.Data.t - TempProps.end_time));
            TempProps.end_time        = app.Data.t(TempProps.end_index);
            
            % Changing the window length to that of the entire length of the signal.
            TempProps.window_size = TempProps.end_index - TempProps.start_index;
            
            % FFT of the entire signal in one window
            app.ProcessedTransform = compute_spectrogram(app,app.Data,TempProps);
            
            % Taking an initial guess at the baseline frequency
            f0_init_guess = app.ProcessedTransform.F(app.ProcessedTransform.P == max(app.ProcessedTransform.P));
            f0_init_guess_width = 20e6; % 20 Mhz either side of init f0 guess
            
            % Setting up a far narrower frequency range
            TempProps.start_freq = f0_init_guess - f0_init_guess_width;
            TempProps.end_freq   = f0_init_guess + f0_init_guess_width;
            TempProps.nfft       = numel(TempProps.start_freq:10:TempProps.end_freq);
            
            % Computing the transform in that narrow range with far greater resolution.
            app.ProcessedTransform = compute_spectrogram(app,app.Data,TempProps);
            clearvars f0_init_guess f0_init_guess_width
            
            app.Data.f0 = app.ProcessedTransform.F(app.ProcessedTransform.P == max(app.ProcessedTransform.P));
            clearvars freq_range
            
            % Setting Baseline frequency field with correct value
            app.BaselineFrequencyField.Value = app.Data.f0/1e9;
            drawnow
            
            % Resetting processed transform porperties
            TempProps = app.TransformProps;
            
            % Changing start time to the post breakout line
            TempProps.start_time          = app.BreakoutEndTimeField.Value / 1e6;
            [~, TempProps.start_index]    = min(abs(app.Data.t - TempProps.start_time));
            TempProps.start_time          = app.Data.t(TempProps.start_index);
            
            try
                % Try to move the end time to a time the width of the breakout region beyond the start time.
                TempProps.end_time            = (2*TempProps.start_time) - app.BreakoutStartTimeField.Value/1e6;
                [~, TempProps.end_index]      = min(abs(app.Data.t - TempProps.end_time));
                TempProps.end_time            = TempProps.end_index;
            catch
                % If this is not possible (ie beyond end of signal) use the crop end time.
                TempProps.end_time            = app.TransformProps.end_time;
                TempProps.end_index           = app.TransformProps.end_index;
            end
            
            %Creating functions for minimisation.
            function power = remove_baseline_float_on(app,A,Props)
                % Creating terms to match Dolan paper
                measured = app.Data.v(Props.start_index:Props.end_index);
                term_1 = A(1)*cos(2*pi*A(3)       *app.Data.t(Props.start_index:Props.end_index));
                term_2 = A(2)*sin(2*pi*A(3)       *app.Data.t(Props.start_index:Props.end_index));
                
                % Recreating signal
                signal = measured - term_1 - term_2;
                
                % Measuring power in baseline (50MHz width)
                power_bas = bandpower(signal,app.Data.fs,[app.Data.f0-2.5e7 app.Data.f0+2.5e7]); 
                
                % Measuring power in spectrogram region
                power_tot = bandpower(signal,app.Data.fs,[Props.start_freq Props.end_freq]);
                
                % Returning the fraction of the power in the spectrogram attributed to the baseline.
                power = power_bas/power_tot;
            end
            function power = remove_baseline_float_off(app,A,Props)
                    % Creating terms to match Dolan paper
                    measured    = app.Data.v(Props.start_index:Props.end_index);
                    term_1      = A(1)*cos(2*pi*app.Data.f0*app.Data.t(Props.start_index:Props.end_index));
                    term_2      = A(2)*sin(2*pi*app.Data.f0*app.Data.t(Props.start_index:Props.end_index));
                    
                    % Recreating signal
                    signal = measured - term_1 - term_2;
                    
                    power = bandpower(signal,app.Data.fs,[app.Data.f0-2.5e7 app.Data.f0+2.5e7]);
                    power_tot = bandpower(signal,app.Data.fs,[Props.start_freq Props.end_freq]);
                    power = power/power_tot;
            end
            
            % Minimising with either floating or fixed baseline
            if strcmp(app.FloatingBaselineToggle.Value,'On') % Floating baseline on
                % Minimising fractional baseline power to give A(1), A(2) and A(3).
                [A,~] = fminsearch(@(A)remove_baseline_float_on(app,A,TempProps),[0,0,app.Data.f0],optimset('MaxFunEvals',10000,'MaxIter',10000));
                
                % Creating inverse baseline signal
                baseline_1 = A(1)*cos(2*pi*A(3)*app.Data.t);
                baseline_2 = A(2)*sin(2*pi*A(3)*app.Data.t);
            else % Floating baseline off.
                % Minimising fractional baseline power to give A(1), A(2) and A(3).
                [A,~] = fminsearch(@(A)remove_baseline_float_off(app,A,TempProps),[0,0],optimset('MaxFunEvals',10000,'MaxIter',10000));
                
                % Creating inverse baseline signal
                baseline_1 = A(1) * cos(2*pi *app.Data.f0*app.Data.t);
                baseline_2 = A(2) * sin(2*pi *app.Data.f0*app.Data.t);
            end
            % Recreating signal with baseline removed
                app.Data.v_baseline_removed = app.Data.v - baseline_1 - baseline_2;
            
            % Computing processed spectrogram
            app.ProcessedTransform = compute_spectrogram_baseline_removed(app,app.Data,app.TransformProps);
            
            % Plotting baseline removed spectrogram
            plot_freq_spectrogram(app,app.ProcessedPlot,app.ProcessedTransform,'Processed Spectrogram')
            
            app.ReadyLamp.Color = 'g';
        end

        % Value changed function: StartTimeField
        function StartTimeFieldValueChanged(app, event)
            if isfield(app.Data,'t')
                [~, Idx] = min(abs(app.Data.t - (app.StartTimeField.Value * 1e-6)));
                app.StartTimeField.Value = app.Data.t(Idx) * 1e6;
            end
            
            if isfield(app.RawTransform,'start_time_line')
                delete(app.RawTransform.start_time_line)
                app.RawTransform = rmfield(app.RawTransform,'start_time_line');
            end
            
            hold(app.RawPlot,'on')
            
            % Try to plot onto RawPlot
            try
                app.RawTransform.start_time_line = plot(app.RawPlot,([app.StartTimeField.Value,app.StartTimeField.Value]),([min(app.RawTransform.F) max(app.RawTransform.F)]*1e-9),'Color','k');
            catch
            end
        end

        % Value changed function: EndTimeField
        function EndTimeFieldValueChanged(app, event)
            if isfield(app.Data,'t')
                [~, Idx] = min(abs(app.Data.t - (app.EndTimeField.Value * 1e-6)));
                app.EndTimeField.Value = app.Data.t(Idx) * 1e6;
            end
            
            if isfield(app.RawTransform,'end_time_line')
                delete(app.RawTransform.end_time_line)
                app.RawTransform = rmfield(app.RawTransform,'end_time_line');
            end
            
            hold(app.RawPlot,'on')
            
            % Try to plot onto RawPlot
            try
                app.RawTransform.end_time_line = plot(app.RawPlot,([app.EndTimeField.Value,app.EndTimeField.Value]),([min(app.RawTransform.F) max(app.RawTransform.F)]*1e-9),'Color','k');
            catch
            end
        end

        % Value changed function: MinFrequencyField
        function MinFrequencyFieldValueChanged(app, event)
            if isfield(app.RawTransform,'min_freq_line')
                delete(app.RawTransform.min_freq_line)
                app.RawTransform = rmfield(app.RawTransform,'min_freq_line');
            end
            
            hold(app.RawPlot,'on')
            
            % Try to plot onto RawPlot
            try
                app.RawTransform.min_freq_line = plot(app.RawPlot,([min(app.RawTransform.T)+app.RawProps.start_time max(app.RawTransform.T)+app.RawProps.start_time]*1e6),([app.MinFrequencyField.Value,app.MinFrequencyField.Value]),'Color','k');
            catch
            end
        end

        % Value changed function: MaxFrequencyField
        function MaxFrequencyFieldValueChanged(app, event)
            if isfield(app.RawTransform,'max_freq_line')
                delete(app.RawTransform.max_freq_line)
                app.RawTransform = rmfield(app.RawTransform,'max_freq_line');
            end
            
            hold(app.RawPlot,'on')
            
            % Try to plot onto RawPlot
            try
                app.RawTransform.max_freq_line = plot(app.RawPlot,([min(app.RawTransform.T)+app.RawProps.start_time max(app.RawTransform.T)+app.RawProps.start_time]*1e6),([app.MaxFrequencyField.Value,app.MaxFrequencyField.Value]),'Color','k');
            catch
            end
        end

        % Value changed function: OffsetSampleStartTimeField
        function OffsetSampleStartTimeFieldValueChanged(app, event)
            if isfield(app.VelocityTransform,'start_time_line')
                delete(app.VelocityTransform.start_time_line)
                app.VelocityTransform = rmfield(app.VelocityTransform,'start_time_line');
            end
            
            % Try to plot onto VelocityPlot
            try
                hold(app.VelocityPlot,'on')
                app.VelocityTransform.start_time_line = plot(app.VelocityPlot,([app.OffsetSampleStartTimeField.Value,app.OffsetSampleStartTimeField.Value]),([min(app.VelocityTransform.velocity_scale) max(app.VelocityTransform.velocity_scale)]),'Color','k');
            catch
            end
        end

        % Value changed function: OffsetSampleEndTimeField
        function OffsetSampleEndTimeFieldValueChanged(app, event)
            if isfield(app.VelocityTransform,'end_time_line')
                delete(app.VelocityTransform.end_time_line)
                app.VelocityTransform = rmfield(app.VelocityTransform,'end_time_line');
            end
            
            hold(app.VelocityPlot,'on')
            
            % Try to plot onto VelocityPlot
            try
                app.VelocityTransform.end_time_line = plot(app.VelocityPlot,([app.OffsetSampleEndTimeField.Value,app.OffsetSampleEndTimeField.Value]),([min(app.VelocityTransform.velocity_scale) max(app.VelocityTransform.velocity_scale)]),'Color','k');
            catch
            end
        end

        % Value changed function: BaselineCorrectionToggle
        function BaselineCorrectionToggleValueChanged(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            if strcmp(app.BaselineCorrectionToggle.Value,'Off')
                app.ProcessedTransform = app.CropTransform;
                plot_freq_spectrogram(app,app.ProcessedPlot,app.ProcessedTransform,'Processed Spectrogram')
            end
            
            app.ReadyLamp.Color = 'g';
            drawnow
        end

        % Button pushed function: ImportTraceButton
        function ImportTraceButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            %Importing scope file
            try
                waveform = ImportScope('Echo',false);
            catch
                waveform = [];
            end
            
            % Moving data into correct lcoations
            if isstruct(waveform) && all(isfield(waveform,{'time','voltage'}))
                app.Data.t = waveform.time;
                app.Data.v = waveform.voltage;
                app.Data.fs = 1/abs(app.Data.t(2) - app.Data.t(1));
                
                % Computing the raw spectrogram
                app = compute_raw_spectrogram(app);
            end
            
            % Jumping back to the UI
            figure(app.PdvAnalysisFigure)
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: SaveFigureButton
        function SaveFigureButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            switch app.FigureChoiceDropDown.Value
                case 'Raw'
                    obj = app.RawPlot;
                    SwapAxesSide = false;
                    Filename = 'RawPlot';
                case 'Cropped'
                    obj = app.CropPlot;
                    SwapAxesSide = true;
                    Filename = 'CropPlot';
                case 'Processed'
                    obj = app.ProcessedPlot;
                    SwapAxesSide = false;
                    Filename = 'ProcessedPlot';
                case 'Velocity'
                    obj = app.VelocityPlot;
                    SwapAxesSide = true;
                    Filename = 'VelocityPlot';
            end
            
            [Filename,Pathname] = uiputfile({'*.eps';'*.pdf';'*.tiff'}, ...
                                            'Select Save Location', ...
                                            Filename);
            
            % Jumping back to the UI
            figure(app.PdvAnalysisFigure)
                                        
            if SwapAxesSide
                obj.YAxisLocation = 'left';
            end
                                        
            if ischar(Pathname)
                if contains(Filename,'.eps')
                    exportgraphics(obj,fullfile(Pathname,Filename))
                elseif contains(Filename,'.pdf')
                    exportgraphics(obj,fullfile(Pathname,Filename),'ContentType',"vector")
                elseif contains(Filename,'tiff')
                    exportgraphics(obj,fullfile(Pathname,Filename),'Resolution',300)
                else
                    exportgraphics(obj,fullfile(Pathname,Filename))
                end
            end
            
            if SwapAxesSide
                obj.YAxisLocation = 'right';
            end
            
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ImportParametersButton
        function ImportParametersButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            uiopen("load");
            
            if exist('Parameters') %#ok<EXIST> 
                LoadParameters(app,Parameters)
            end
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ImportH5DatasetButton
        function ImportH5DatasetButtonPushed(app, event)
            app.ChildApp.Handle = H5Pull("ParentApp",app);
            waitfor(app.ChildApp.Handle)
            
            if isfield(app.ChildApp,'Outputs')
                tmp = app.ChildApp.Outputs;
                if size(tmp{4},1) == 1
                    tmp = ImportLecroyArray(tmp{4});
                    app.Data.t = tmp.time;
                    app.Data.v = tmp.voltage;
                    app.Data.fs = abs(app.Data.t(2) - app.Data.t(1));
                else
                    app.Data.t = tmp(:,1);
                    app.Data.v = tmp(:,2);
                    app.Data.fs = abs(app.Data.t(2) - app.Data.t(1));
                end
                
                ReprocessRawButtonButtonPushed(app)
            end
        end

        % Button pushed function: SaveFilematButton
        function SaveFilematButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            switch app.FileSaveDropDown.Value
                case 'Velocity'
                    Time        = app.Outputs.Time; %#ok
                    Velocity    = app.Outputs.Velocity; %#ok
                    Errors      = app.Outputs.Error; %#ok
                    
                    uisave({'Time','Velocity','Errors'},'PDVResult.mat')
                case 'Parameters'
                    Parameters = app.Outputs.Parameters; %#ok
                    
                    uisave({'Parameters'},'PDVParameters.mat')
            end
            
            % Jumping back to the UI
            figure(app.PdvAnalysisFigure)
            
            app.ReadyLamp.Color = 'g';
        end

        % Close request function: PdvAnalysisFigure
        function PdvAnalysisCloseRequest(app, event)
            delete(app)
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create PdvAnalysisFigure and hide until all components are created
            app.PdvAnalysisFigure = uifigure('Visible', 'off');
            app.PdvAnalysisFigure.Position = [5 5 1090 610];
            app.PdvAnalysisFigure.Name = 'PDV_TOOL';
            app.PdvAnalysisFigure.CloseRequestFcn = createCallbackFcn(app, @PdvAnalysisCloseRequest, true);
            app.PdvAnalysisFigure.Scrollable = 'on';

            % Create RawPlot
            app.RawPlot = uiaxes(app.PdvAnalysisFigure);
            title(app.RawPlot, 'Raw Spectrogram')
            xlabel(app.RawPlot, 'Time [us]')
            ylabel(app.RawPlot, 'Frequency [GHz]')
            app.RawPlot.PlotBoxAspectRatio = [1.01917808219178 1 1];
            app.RawPlot.FontSize = 10;
            app.RawPlot.TickLabelInterpreter = 'none';
            app.RawPlot.Box = 'on';
            app.RawPlot.BoxStyle = 'full';
            app.RawPlot.LineWidth = 1;
            app.RawPlot.NextPlot = 'replace';
            app.RawPlot.Position = [241 306 295 295];

            % Create CropPlot
            app.CropPlot = uiaxes(app.PdvAnalysisFigure);
            title(app.CropPlot, 'Cropped Spectrogram')
            xlabel(app.CropPlot, 'Time [us]')
            ylabel(app.CropPlot, 'Frequency [GHz]')
            app.CropPlot.PlotBoxAspectRatio = [1.02191780821918 1 1];
            app.CropPlot.FontSize = 10;
            app.CropPlot.TickLabelInterpreter = 'none';
            app.CropPlot.Box = 'on';
            app.CropPlot.BoxStyle = 'full';
            app.CropPlot.YAxisLocation = 'right';
            app.CropPlot.LineWidth = 1;
            app.CropPlot.NextPlot = 'replace';
            app.CropPlot.Position = [536 306 295 295];

            % Create ProcessedPlot
            app.ProcessedPlot = uiaxes(app.PdvAnalysisFigure);
            title(app.ProcessedPlot, 'Processed Spectrogram')
            xlabel(app.ProcessedPlot, 'Time [us]')
            ylabel(app.ProcessedPlot, 'Frequency [GHz]')
            app.ProcessedPlot.PlotBoxAspectRatio = [1.02191780821918 1 1];
            app.ProcessedPlot.FontSize = 10;
            app.ProcessedPlot.TickLabelInterpreter = 'none';
            app.ProcessedPlot.Box = 'on';
            app.ProcessedPlot.BoxStyle = 'full';
            app.ProcessedPlot.LineWidth = 1;
            app.ProcessedPlot.NextPlot = 'replace';
            app.ProcessedPlot.Position = [241 11 295 295];

            % Create VelocityPlot
            app.VelocityPlot = uiaxes(app.PdvAnalysisFigure);
            title(app.VelocityPlot, 'Velocity Spectrogram')
            xlabel(app.VelocityPlot, 'Time [us]')
            ylabel(app.VelocityPlot, 'Velocity [m/s]')
            app.VelocityPlot.PlotBoxAspectRatio = [1.02191780821918 1 1];
            app.VelocityPlot.FontSize = 10;
            app.VelocityPlot.TickLabelInterpreter = 'none';
            app.VelocityPlot.Box = 'on';
            app.VelocityPlot.BoxStyle = 'full';
            app.VelocityPlot.YAxisLocation = 'right';
            app.VelocityPlot.LineWidth = 1;
            app.VelocityPlot.NextPlot = 'replace';
            app.VelocityPlot.Position = [536 11 295 295];

            % Create CropSpectrogramButton
            app.CropSpectrogramButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.CropSpectrogramButton.ButtonPushedFcn = createCallbackFcn(app, @CropSpectrogramButtonPushed, true);
            app.CropSpectrogramButton.FontSize = 10;
            app.CropSpectrogramButton.Position = [91 131 140 20];
            app.CropSpectrogramButton.Text = 'Crop Spectrogram';

            % Create ProcessBaselineButton
            app.ProcessBaselineButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ProcessBaselineButton.ButtonPushedFcn = createCallbackFcn(app, @ProcessBaselineButtonPushed, true);
            app.ProcessBaselineButton.FontSize = 10;
            app.ProcessBaselineButton.Position = [841 491 140 20];
            app.ProcessBaselineButton.Text = 'Process';

            % Create SetROIButton
            app.SetROIButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.SetROIButton.ButtonPushedFcn = createCallbackFcn(app, @SetROIButtonButtonPushed, true);
            app.SetROIButton.FontSize = 10;
            app.SetROIButton.Position = [91 71 140 20];
            app.SetROIButton.Text = 'Set ROI';

            % Create ConfirmRoiButton
            app.ConfirmRoiButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ConfirmRoiButton.ButtonPushedFcn = createCallbackFcn(app, @ConfirmRoiButtonButtonPushed, true);
            app.ConfirmRoiButton.FontSize = 10;
            app.ConfirmRoiButton.Position = [91 11 140 20];
            app.ConfirmRoiButton.Text = 'Confirm ROI';

            % Create ShiftSwitchButton
            app.ShiftSwitchButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ShiftSwitchButton.ButtonPushedFcn = createCallbackFcn(app, @ShiftSwitchButtonButtonPushed, true);
            app.ShiftSwitchButton.FontSize = 10;
            app.ShiftSwitchButton.Position = [841 311 140 20];
            app.ShiftSwitchButton.Text = 'Upshift/Downshift';

            % Create ExtractVelocitiesButton
            app.ExtractVelocitiesButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ExtractVelocitiesButton.ButtonPushedFcn = createCallbackFcn(app, @ExtractVelocitiesButtonButtonPushed, true);
            app.ExtractVelocitiesButton.FontSize = 10;
            app.ExtractVelocitiesButton.Position = [841 281 140 20];
            app.ExtractVelocitiesButton.Text = 'Extract Velocities';

            % Create ReturnCloseButton
            app.ReturnCloseButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ReturnCloseButton.ButtonPushedFcn = createCallbackFcn(app, @ReturnCloseButtonButtonPushed, true);
            app.ReturnCloseButton.FontSize = 10;
            app.ReturnCloseButton.FontWeight = 'bold';
            app.ReturnCloseButton.Position = [841 69 240 22];
            app.ReturnCloseButton.Text = 'Return & Close';

            % Create ResetROIButton
            app.ResetROIButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ResetROIButton.ButtonPushedFcn = createCallbackFcn(app, @ResetROIButtonButtonPushed, true);
            app.ResetROIButton.FontSize = 10;
            app.ResetROIButton.Position = [91 41 140 20];
            app.ResetROIButton.Text = 'Reset ROI';

            % Create BaselineCorrectionToggle
            app.BaselineCorrectionToggle = uiswitch(app.PdvAnalysisFigure, 'slider');
            app.BaselineCorrectionToggle.ValueChangedFcn = createCallbackFcn(app, @BaselineCorrectionToggleValueChanged, true);
            app.BaselineCorrectionToggle.FontSize = 10;
            app.BaselineCorrectionToggle.Position = [869 581 45 20];

            % Create ReprocessRawButton
            app.ReprocessRawButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ReprocessRawButton.ButtonPushedFcn = createCallbackFcn(app, @ReprocessRawButtonButtonPushed, true);
            app.ReprocessRawButton.FontSize = 10;
            app.ReprocessRawButton.Position = [91 371 140 20];
            app.ReprocessRawButton.Text = 'Reprocess Raw';

            % Create ReadyLampLabel
            app.ReadyLampLabel = uilabel(app.PdvAnalysisFigure);
            app.ReadyLampLabel.HorizontalAlignment = 'right';
            app.ReadyLampLabel.FontSize = 10;
            app.ReadyLampLabel.Position = [1 581 120 20];
            app.ReadyLampLabel.Text = 'Ready';

            % Create ReadyLamp
            app.ReadyLamp = uilamp(app.PdvAnalysisFigure);
            app.ReadyLamp.Position = [211 581 20 20];

            % Create RecalculateVelocitiesButton
            app.RecalculateVelocitiesButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.RecalculateVelocitiesButton.ButtonPushedFcn = createCallbackFcn(app, @RecalculateVelocitiesButtonPushed, true);
            app.RecalculateVelocitiesButton.FontSize = 10;
            app.RecalculateVelocitiesButton.Position = [841 341 140 20];
            app.RecalculateVelocitiesButton.Text = 'Recalculate Velocities';

            % Create IdentifyOffsetButton
            app.IdentifyOffsetButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.IdentifyOffsetButton.ButtonPushedFcn = createCallbackFcn(app, @IdentifyOffsetButtonPushed, true);
            app.IdentifyOffsetButton.FontSize = 10;
            app.IdentifyOffsetButton.Position = [841 191 140 20];
            app.IdentifyOffsetButton.Text = 'Identify Offset';

            % Create RemoveOffsetButton
            app.RemoveOffsetButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.RemoveOffsetButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveOffsetButtonPushed, true);
            app.RemoveOffsetButton.FontSize = 10;
            app.RemoveOffsetButton.Position = [841 131 140 20];
            app.RemoveOffsetButton.Text = 'Remove Offset';

            % Create RawNfftPtsEditFieldLabel
            app.RawNfftPtsEditFieldLabel = uilabel(app.PdvAnalysisFigure);
            app.RawNfftPtsEditFieldLabel.HorizontalAlignment = 'right';
            app.RawNfftPtsEditFieldLabel.FontSize = 10;
            app.RawNfftPtsEditFieldLabel.Position = [1 461 120 20];
            app.RawNfftPtsEditFieldLabel.Text = 'Raw Nfft (Pts)';

            % Create RawNfftField
            app.RawNfftField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.RawNfftField.FontSize = 10;
            app.RawNfftField.Position = [131 461 100 20];
            app.RawNfftField.Value = 512;

            % Create RawWindowSizePtsEditFieldLabel
            app.RawWindowSizePtsEditFieldLabel = uilabel(app.PdvAnalysisFigure);
            app.RawWindowSizePtsEditFieldLabel.HorizontalAlignment = 'right';
            app.RawWindowSizePtsEditFieldLabel.FontSize = 10;
            app.RawWindowSizePtsEditFieldLabel.Position = [1 431 120 20];
            app.RawWindowSizePtsEditFieldLabel.Text = 'Raw Window Size (Pts)';

            % Create RawWindowSizeField
            app.RawWindowSizeField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.RawWindowSizeField.FontSize = 10;
            app.RawWindowSizeField.Position = [131 431 100 20];
            app.RawWindowSizeField.Value = 8192;

            % Create StartTimesEditFieldLabel_2
            app.StartTimesEditFieldLabel_2 = uilabel(app.PdvAnalysisFigure);
            app.StartTimesEditFieldLabel_2.HorizontalAlignment = 'right';
            app.StartTimesEditFieldLabel_2.FontSize = 10;
            app.StartTimesEditFieldLabel_2.Position = [1 341 120 20];
            app.StartTimesEditFieldLabel_2.Text = 'Start Time (탎)';

            % Create StartTimeField
            app.StartTimeField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.StartTimeField.ValueChangedFcn = createCallbackFcn(app, @StartTimeFieldValueChanged, true);
            app.StartTimeField.FontSize = 10;
            app.StartTimeField.Position = [131 341 100 20];

            % Create EndTimesEditFieldLabel_2
            app.EndTimesEditFieldLabel_2 = uilabel(app.PdvAnalysisFigure);
            app.EndTimesEditFieldLabel_2.HorizontalAlignment = 'right';
            app.EndTimesEditFieldLabel_2.FontSize = 10;
            app.EndTimesEditFieldLabel_2.Position = [1 311 120 20];
            app.EndTimesEditFieldLabel_2.Text = 'End Time (탎)';

            % Create EndTimeField
            app.EndTimeField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.EndTimeField.ValueChangedFcn = createCallbackFcn(app, @EndTimeFieldValueChanged, true);
            app.EndTimeField.FontSize = 10;
            app.EndTimeField.Position = [131 311 100 20];

            % Create MinFrequencyGHzEditFieldLabel_2
            app.MinFrequencyGHzEditFieldLabel_2 = uilabel(app.PdvAnalysisFigure);
            app.MinFrequencyGHzEditFieldLabel_2.HorizontalAlignment = 'right';
            app.MinFrequencyGHzEditFieldLabel_2.FontSize = 10;
            app.MinFrequencyGHzEditFieldLabel_2.Position = [1 281 120 20];
            app.MinFrequencyGHzEditFieldLabel_2.Text = 'Min Frequency (GHz)';

            % Create MinFrequencyField
            app.MinFrequencyField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.MinFrequencyField.ValueChangedFcn = createCallbackFcn(app, @MinFrequencyFieldValueChanged, true);
            app.MinFrequencyField.FontSize = 10;
            app.MinFrequencyField.Position = [131 281 100 20];

            % Create MaxFrequencyGHzEditFieldLabel
            app.MaxFrequencyGHzEditFieldLabel = uilabel(app.PdvAnalysisFigure);
            app.MaxFrequencyGHzEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxFrequencyGHzEditFieldLabel.FontSize = 10;
            app.MaxFrequencyGHzEditFieldLabel.Position = [1 251 120 20];
            app.MaxFrequencyGHzEditFieldLabel.Text = 'Max Frequency (GHz)';

            % Create MaxFrequencyField
            app.MaxFrequencyField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.MaxFrequencyField.ValueChangedFcn = createCallbackFcn(app, @MaxFrequencyFieldValueChanged, true);
            app.MaxFrequencyField.FontSize = 10;
            app.MaxFrequencyField.Position = [131 251 100 20];

            % Create CropNfftPtsEditFieldLabel_2
            app.CropNfftPtsEditFieldLabel_2 = uilabel(app.PdvAnalysisFigure);
            app.CropNfftPtsEditFieldLabel_2.HorizontalAlignment = 'right';
            app.CropNfftPtsEditFieldLabel_2.FontSize = 10;
            app.CropNfftPtsEditFieldLabel_2.Position = [1 221 120 20];
            app.CropNfftPtsEditFieldLabel_2.Text = 'Crop Nfft (Pts)';

            % Create CropNfftField
            app.CropNfftField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.CropNfftField.FontSize = 10;
            app.CropNfftField.Position = [131 221 100 20];
            app.CropNfftField.Value = 1024;

            % Create CropWindowSizePtsEditFieldLabel
            app.CropWindowSizePtsEditFieldLabel = uilabel(app.PdvAnalysisFigure);
            app.CropWindowSizePtsEditFieldLabel.HorizontalAlignment = 'right';
            app.CropWindowSizePtsEditFieldLabel.FontSize = 10;
            app.CropWindowSizePtsEditFieldLabel.Position = [1 191 120 20];
            app.CropWindowSizePtsEditFieldLabel.Text = 'Crop Window Size (Pts)';

            % Create CropWindowSizeField
            app.CropWindowSizeField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.CropWindowSizeField.FontSize = 10;
            app.CropWindowSizeField.Position = [131 191 100 20];
            app.CropWindowSizeField.Value = 512;

            % Create CropOverlapPtsLabel
            app.CropOverlapPtsLabel = uilabel(app.PdvAnalysisFigure);
            app.CropOverlapPtsLabel.HorizontalAlignment = 'right';
            app.CropOverlapPtsLabel.FontSize = 10;
            app.CropOverlapPtsLabel.Position = [1 161 120 20];
            app.CropOverlapPtsLabel.Text = 'Crop Overlap (Pts)';

            % Create CropOverlapField
            app.CropOverlapField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.CropOverlapField.FontSize = 10;
            app.CropOverlapField.Position = [131 161 100 20];

            % Create BreakoutStartTimesEditFieldLabel
            app.BreakoutStartTimesEditFieldLabel = uilabel(app.PdvAnalysisFigure);
            app.BreakoutStartTimesEditFieldLabel.FontSize = 10;
            app.BreakoutStartTimesEditFieldLabel.Position = [951 551 140 20];
            app.BreakoutStartTimesEditFieldLabel.Text = 'Breakout Start Time (탎)';

            % Create BreakoutStartTimeField
            app.BreakoutStartTimeField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.BreakoutStartTimeField.ValueChangedFcn = createCallbackFcn(app, @BreakoutStartTimeFieldValueChanged, true);
            app.BreakoutStartTimeField.FontSize = 10;
            app.BreakoutStartTimeField.Position = [841 551 100 20];

            % Create BreakoutEndTimesEditFieldLabel
            app.BreakoutEndTimesEditFieldLabel = uilabel(app.PdvAnalysisFigure);
            app.BreakoutEndTimesEditFieldLabel.FontSize = 10;
            app.BreakoutEndTimesEditFieldLabel.Position = [951 521 140 20];
            app.BreakoutEndTimesEditFieldLabel.Text = 'Breakout End Time (탎)';

            % Create BreakoutEndTimeField
            app.BreakoutEndTimeField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.BreakoutEndTimeField.ValueChangedFcn = createCallbackFcn(app, @BreakoutEndTimeFieldValueChanged, true);
            app.BreakoutEndTimeField.FontSize = 10;
            app.BreakoutEndTimeField.Position = [841 521 100 20];

            % Create BaselineFrequencyGhzEditFieldLabel
            app.BaselineFrequencyGhzEditFieldLabel = uilabel(app.PdvAnalysisFigure);
            app.BaselineFrequencyGhzEditFieldLabel.FontSize = 10;
            app.BaselineFrequencyGhzEditFieldLabel.Position = [951 461 140 20];
            app.BaselineFrequencyGhzEditFieldLabel.Text = 'Baseline Frequency (Ghz)';

            % Create BaselineFrequencyField
            app.BaselineFrequencyField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.BaselineFrequencyField.FontSize = 10;
            app.BaselineFrequencyField.Position = [841 461 100 20];

            % Create RemoveBaselineLabel
            app.RemoveBaselineLabel = uilabel(app.PdvAnalysisFigure);
            app.RemoveBaselineLabel.FontSize = 10;
            app.RemoveBaselineLabel.Position = [951 581 140 20];
            app.RemoveBaselineLabel.Text = ' Remove Baseline?';

            % Create ProbeLaserWavelengthnmLabel
            app.ProbeLaserWavelengthnmLabel = uilabel(app.PdvAnalysisFigure);
            app.ProbeLaserWavelengthnmLabel.FontSize = 10;
            app.ProbeLaserWavelengthnmLabel.Position = [951 371 140 20];
            app.ProbeLaserWavelengthnmLabel.Text = 'Probe Laser Wavelength (nm)';

            % Create WavelengthField
            app.WavelengthField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.WavelengthField.Position = [841 371 100 20];
            app.WavelengthField.Value = 1550;

            % Create OffsetSampleStartTimesLabel
            app.OffsetSampleStartTimesLabel = uilabel(app.PdvAnalysisFigure);
            app.OffsetSampleStartTimesLabel.FontSize = 10;
            app.OffsetSampleStartTimesLabel.Position = [951 250 140 20];
            app.OffsetSampleStartTimesLabel.Text = 'Offset Sample Start Time (탎)';

            % Create OffsetSampleStartTimeField
            app.OffsetSampleStartTimeField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.OffsetSampleStartTimeField.ValueChangedFcn = createCallbackFcn(app, @OffsetSampleStartTimeFieldValueChanged, true);
            app.OffsetSampleStartTimeField.Position = [841 251 100 20];

            % Create OffsetSampleEndTimesLabel
            app.OffsetSampleEndTimesLabel = uilabel(app.PdvAnalysisFigure);
            app.OffsetSampleEndTimesLabel.FontSize = 10;
            app.OffsetSampleEndTimesLabel.Position = [951 221 140 20];
            app.OffsetSampleEndTimesLabel.Text = 'Offset Sample End Time (탎)';

            % Create OffsetSampleEndTimeField
            app.OffsetSampleEndTimeField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.OffsetSampleEndTimeField.ValueChangedFcn = createCallbackFcn(app, @OffsetSampleEndTimeFieldValueChanged, true);
            app.OffsetSampleEndTimeField.Position = [841 221 100 20];

            % Create ZeroVeloctymsLabel_2
            app.ZeroVeloctymsLabel_2 = uilabel(app.PdvAnalysisFigure);
            app.ZeroVeloctymsLabel_2.FontSize = 10;
            app.ZeroVeloctymsLabel_2.Position = [951 160 140 20];
            app.ZeroVeloctymsLabel_2.Text = '''Zero'' Velocty (m/s)';

            % Create ZeroVelocityField
            app.ZeroVelocityField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.ZeroVelocityField.Position = [841 161 100 20];

            % Create FloatingBaselineToggle
            app.FloatingBaselineToggle = uiswitch(app.PdvAnalysisFigure, 'slider');
            app.FloatingBaselineToggle.FontSize = 10;
            app.FloatingBaselineToggle.Position = [870 431 45 20];
            app.FloatingBaselineToggle.Value = 'On';

            % Create FloatingBaselineLabel
            app.FloatingBaselineLabel = uilabel(app.PdvAnalysisFigure);
            app.FloatingBaselineLabel.FontSize = 10;
            app.FloatingBaselineLabel.Position = [951 431 140 20];
            app.FloatingBaselineLabel.Text = ' Floating Baseline';

            % Create ImportTraceButton
            app.ImportTraceButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ImportTraceButton.ButtonPushedFcn = createCallbackFcn(app, @ImportTraceButtonPushed, true);
            app.ImportTraceButton.FontSize = 10;
            app.ImportTraceButton.Position = [91 521 140 20];
            app.ImportTraceButton.Text = 'Import Trace';

            % Create SaveFigureButton
            app.SaveFigureButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.SaveFigureButton.ButtonPushedFcn = createCallbackFcn(app, @SaveFigureButtonPushed, true);
            app.SaveFigureButton.FontSize = 10;
            app.SaveFigureButton.Position = [841 39 130 22];
            app.SaveFigureButton.Text = 'Save Figure';

            % Create FigureChoiceDropDown
            app.FigureChoiceDropDown = uidropdown(app.PdvAnalysisFigure);
            app.FigureChoiceDropDown.Items = {'Raw', 'Cropped', 'Processed', 'Velocity'};
            app.FigureChoiceDropDown.FontSize = 10;
            app.FigureChoiceDropDown.Position = [981 41 100 20];
            app.FigureChoiceDropDown.Value = 'Raw';

            % Create ImportParametersButton
            app.ImportParametersButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ImportParametersButton.ButtonPushedFcn = createCallbackFcn(app, @ImportParametersButtonPushed, true);
            app.ImportParametersButton.FontSize = 10;
            app.ImportParametersButton.Position = [91 491 140 20];
            app.ImportParametersButton.Text = 'Import Parameters';

            % Create BandwidthGHzLabel
            app.BandwidthGHzLabel = uilabel(app.PdvAnalysisFigure);
            app.BandwidthGHzLabel.HorizontalAlignment = 'right';
            app.BandwidthGHzLabel.FontSize = 10;
            app.BandwidthGHzLabel.Position = [1 401 120 20];
            app.BandwidthGHzLabel.Text = 'Bandwidth (GHz)';

            % Create BandwidthField
            app.BandwidthField = uieditfield(app.PdvAnalysisFigure, 'numeric');
            app.BandwidthField.FontSize = 10;
            app.BandwidthField.Position = [131 401 100 20];
            app.BandwidthField.Value = 8;

            % Create ImportH5DatasetButton
            app.ImportH5DatasetButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.ImportH5DatasetButton.ButtonPushedFcn = createCallbackFcn(app, @ImportH5DatasetButtonPushed, true);
            app.ImportH5DatasetButton.FontSize = 10;
            app.ImportH5DatasetButton.Position = [91 551 140 20];
            app.ImportH5DatasetButton.Text = 'Import H5 Dataset';

            % Create SaveFilematButton
            app.SaveFilematButton = uibutton(app.PdvAnalysisFigure, 'push');
            app.SaveFilematButton.ButtonPushedFcn = createCallbackFcn(app, @SaveFilematButtonPushed, true);
            app.SaveFilematButton.FontSize = 10;
            app.SaveFilematButton.Position = [841 9 130 22];
            app.SaveFilematButton.Text = 'Save File (.mat)';

            % Create FileSaveDropDown
            app.FileSaveDropDown = uidropdown(app.PdvAnalysisFigure);
            app.FileSaveDropDown.Items = {'Velocity', 'Parameters'};
            app.FileSaveDropDown.FontSize = 10;
            app.FileSaveDropDown.Position = [981 11 100 20];
            app.FileSaveDropDown.Value = 'Velocity';

            % Show the figure after all components are created
            app.PdvAnalysisFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PdvAnalysis(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.PdvAnalysisFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)PdvAnalysisStartup(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.PdvAnalysisFigure)
        end
    end
end
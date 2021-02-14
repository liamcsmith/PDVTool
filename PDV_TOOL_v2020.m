classdef PDV_TOOL_v2020 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        figure1                         matlab.ui.Figure
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
        SaveVelocitiesButton            matlab.ui.control.Button
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
        SaveSessionButton               matlab.ui.control.Button
        SaveParametersButton            matlab.ui.control.Button
        ImportSessionButton             matlab.ui.control.Button
        SaveFigureButton                matlab.ui.control.Button
        DropDown                        matlab.ui.control.DropDown
        ImportParametersButton          matlab.ui.control.Button
        BandwidthGHzLabel               matlab.ui.control.Label
        BandwidthField                  matlab.ui.control.NumericEditField
        ImportH5DatasetButton           matlab.ui.control.Button
    end

    
    properties (Access = private)
        SessionID               % A quasiunique identifier for a session. Is double precision floating point time in seconds at original opening time.
        data                    % Storage for time and voltage arrays, as well as a few trace dependat characteristics (fs and f0)
        raw_props               % Properties of the raw transform
        raw_transform           % The raw transform and lines located on the raw transform plot
        crop_props              % Properties of the cropped transform
        crop_transform          % The crop transform and lines located on the crop transform plot
        processed_props         % Properties of the processed transform
        processed_transform     % The processed transform and lines located on the processed transform plot
        velocity_props          % Properties of the velocity transform
        velocity_transform      % The velocity transform and lines located on the velocity transform plot
        output                  % Time, Velocity and Error data from the fits of the velocity transform
        HDBPullChild            % Location for storing H5 dbpull app
    end
    
    properties (Access = public)
    end
    
    methods (Access = private)
        % Functions for simplifying the code
        function app       = compute_raw_spectrogram(app)
            % Pulling raw settings (that could change) from the GUI
            app = raw_props_gui_to_struct(app);
            
            % Fixing start and end times based on the data
            app.raw_props.start_time        = app.data.t(1);
            app.raw_props.end_time          = app.data.t(end);
            app.raw_props.start_index       = 1;
            app.raw_props.end_index         = numel(app.data.t);
            
            % Setting some of the raw properties as default values for the
            % crop settings fields.
            app.StartTimeField.Value        = app.raw_props.start_time * 1e6;
            app.EndTimeField.Value          = app.raw_props.end_time   * 1e6;
            
            app.MinFrequencyField.Value     = app.raw_props.start_freq / 1e9;
            app.MaxFrequencyField.Value     = app.raw_props.end_freq   / 1e9;
            
            % Computing the raw transform
            app.raw_transform = compute_spectrogram(app,app.data,app.raw_props);
            
            % Plotting the raw transform
            hold(app.RawPlot,'off')
            plot_freq_spectrogram(app,app.RawPlot,app.raw_transform,app.raw_props,'Rough Spectrogram')
            
            % Replotting guide lines
            StartTimeFieldValueChanged(app)
            EndTimeFieldValueChanged(app)
            MinFrequencyFieldValueChanged(app)
            MaxFrequencyFieldValueChanged(app)
        end
        function app       = compute_crop_spectrogram(app)
            
            % Setting properties for cropped spectrogram
            app = crop_props_gui_to_struct(app);
            
            % Computing cropped spectrogram
            app.crop_transform = compute_spectrogram(app,app.data,app.crop_props);
            
            % Plotting cropped spectrogram
            hold(app.CropPlot,'off')
            plot_freq_spectrogram(app,app.CropPlot,app.crop_transform,app.crop_props,'Cropped Spectrogram')
        end
        function app       = raw_props_gui_to_struct(app)
            app.raw_props.nfft          = app.RawNfftField.Value;
            app.raw_props.window_size   = app.RawWindowSizeField.Value;
            app.raw_props.start_freq    = 0;
            app.raw_props.end_freq      = app.BandwidthField.Value * 1e9;
            app.raw_props.overlap           = 0;
        end
        function app       = crop_props_gui_to_struct(app)
            app.crop_props.nfft         = app.CropNfftField.Value;
            app.crop_props.window_size  = app.CropWindowSizeField.Value;
            app.crop_props.overlap      = app.CropOverlapField.Value;
            
            app.crop_props.start_time   = app.StartTimeField.Value * 1e-6;
            app.crop_props.end_time     = app.EndTimeField.Value * 1e-6;
            try
            [~, app.crop_props.start_index] = min(abs(app.data.t - app.crop_props.start_time));
            [~, app.crop_props.end_index]   = min(abs(app.data.t - app.crop_props.end_time));
            app.crop_props.start_time       = app.data.t(app.crop_props.start_index);
            app.crop_props.end_time         = app.data.t(app.crop_props.end_index);
            catch
            end
            app.crop_props.start_freq   = app.MinFrequencyField.Value * 1e9;
            app.crop_props.end_freq     = app.MaxFrequencyField.Value * 1e9;
        end
        function app       = raw_props_struct_to_gui(app)
            app.RawNfftField.Value       = app.raw_props.nfft;
            app.RawWindowSizeField.Value = app.raw_props.window_size;
            app.raw_props.start_freq     = 0;
            app.BandwidthField.Value     = app.raw_props.end_freq / 1e9;
            app.raw_props.overlap        = 0;
        end
        function app       = crop_props_struct_to_gui(app)
            app.CropNfftField.Value         = app.crop_props.nfft;
            app.CropWindowSizeField.Value   = app.crop_props.window_size;
            app.CropOverlapField.Value      = app.crop_props.overlap;
            
            app.StartTimeField.Value = app.crop_props.start_time / 1e-6;
            app.EndTimeField.Value   = app.crop_props.end_time / 1e-6;
            
            app.MinFrequencyField.Value = app.crop_props.start_freq / 1e9;
            app.MaxFrequencyField.Value = app.crop_props.end_freq / 1e9;
        end
        
        % Functions relating to the spectrograms
        function fitresult = fit_gaussian(app,signal,start_points) %#ok
            signal = (signal-min(signal))/max(signal);%scale the signal down to peak = 1
            [xData, yData] = prepareCurveData( [], signal );

            % ft = fittype( 'gauss1' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            opts.Display = 'Off';
            opts.Lower = [-Inf -Inf 0];
            opts.StartPoint = start_points;

            [fitresult,~] = fit( xData, yData, 'gauss1', opts );
            
            fitresult = [coeffvalues(fitresult) ; confint(fitresult)]; %outputs the a,b,c coeffs of the gaussian fit,
            % as well as the coeff values at the 95% confidence interval boundaires
            % fitresult
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
        function             plot_freq_spectrogram(app,axes,transform,props,title) %#ok
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
        end
        function             plot_vel_spectrogram( app,axes,transform,props,title) %#ok
            imagesc(axes,...
                    1e6*(transform.T+props.start_time),...
                    transform.velocity_scale, ...
                    log10(transform.P),...
                    [min(min(log10(transform.P))) max(max(log10(transform.P)))]);
            set(axes,'YAxisLocation','right')
            set(axes,'YDir','normal')
            set(axes,'TickLabelInterpreter','none')
            set(axes,'FontName','Helvetica')
            ylabel(axes,'Velocity (m/s)','Interpreter','none','FontName','Helvetica')
            xlabel(axes,'Time (us)','Interpreter','none','FontName','Helvetica')
            xlim(axes,[props.start_time props.end_time]*1e6)
            ylim(axes,[min(transform.velocity_scale) max(transform.velocity_scale)])
            set(get(axes, 'title'), 'string', title)
            set(get(axes, 'title'), 'Interpreter', 'none')
        end
        
        %% Each import function
        function waveform  = ImportScope(app) %ok
            %% Getting file
            [filename,pathname] = uigetfile('*');
            
            %% Checking file format
            if strcmp(filename(end-2:end),'trc')
                file_type = 'lecroy';
            elseif strcmp(filename(end-2:end),'wfm')
                file_type = 'tek_wfm';
            elseif strcmp(filename(end-2:end),'isf')
                file_type = 'tek_isf';
            else
                disp('Unknown filetype, check selection.')
                file_type = NaN;
            end
            
            %% Setting filename into correct format
            filename = [pathname,filename];
            clearvars pathname
            
            %% Importing file based on previosuly determined file type.
            if ~isnan(file_type)
                if strcmp(file_type,'lecroy')
                    waveform = ImportScopeLecroy(app,filename);
                elseif strcmp(file_type,'tek_wfm')
                    waveform = ImportScopeTekWFM(app,filename);
                elseif strcmp(file_type,'tek_isf')
                    waveform = ImportScopeTekISF(app,filename);
                end
            end
            
        end
        function waveform  = ImportScopeTekISF(app,filename) %#ok
            %% Initialising Locations & Waveform Variables and opening the binary file.
            fid = fopen(filename,'r'); % Opening the file that has been selected
            
            waveform = struct(); %Building the waveform struct
            locations = struct(); % building the locations struct, this is used for working out where to read the data in the file, locations found by Liam on 4054 isf file, could vary scope to scope as no specific format for tek scopes.
            
            %% Reading in the opening 1000 bytes, converting to character and then finding the endian-ness
            
            data = fread(fid,1000,'*char')'; %#ok
            locations.byte_order = find_location('BYT_O');
            waveform.information.byte_order = data(locations.byte_order.start:locations.byte_order.start+locations.byte_order.length); %#ok
            
            %% Closing then reopening the file with the correct endianness
            
            fclose(fid);
            if strcmp(waveform.information.byte_order,'MSB') % if most significant byte first then big-endian
                fopen(filename,'r','ieee-be');
            elseif strcmp(waveform.information.byte_order,'LSB') % if least significant bye first then little-endian
                fopen(filename,'r','ieee-le');
            else % if its neither of these then something has gone very wrong
                waveform = NaN;
                disp('WAVEFORM NOT IMPORTED CORRECTLY, PLEASE SAFE AS .CSV & SNED .ISF TO LIAM.')
                return
            end
            clearvars filename %not needed anymore so saving RAM
            
            %% Importing the header information first getting lcoations then pulling the information
            
            get_locations
            get_informations
            clean_strings
            
            clearvars locations
            
            %% Finding the start fo the data array and then calculating the no of points in said array
            fseek(fid,regexp(data,'#','once'),'bof'); %#ok
            
            clearvars data
            no_of_points = str2double(fread(fid,1,'*char'));
            no_of_points = str2double(fread(fid,no_of_points,'*char')');
            
            if ~waveform.information.no_of_points * waveform.information.bytes_per_point == no_of_points || ~waveform.information.bits_per_point/8 == waveform.information.bytes_per_point
                waveform = NaN;
                disp('WAVEFORM NOT IMPORTED CORRECTLY, PLEASE SAFE AS .CSV & SNED .ISF TO LIAM.')
                return
            end
            clearvars -except fid waveform
            
            %% Reading the Curve data
            if waveform.information.bytes_per_point == 1
                waveform.voltage = fread(fid,waveform.information.no_of_points,'int8');
            elseif waveform.information.bytes_per_point == 2
                waveform.voltage = fread(fid,waveform.information.no_of_points,'int16');
            else
                waveform = NaN;
            end
            
            %% Creating the time and voltage fields.
            waveform.voltage = waveform.information.vertical_zero + waveform.information.vertical_scale_factor * (waveform.voltage - waveform.information.vertical_offset);
            waveform.time = waveform.information.horizontal_interval * ((1:waveform.information.no_of_points)' - waveform.information.trigger_point_offset);
            
            %% Cleaning the information struct
            clean_information_struct
            
            %% Checking at the end of the file
            fread(fid,1); %sometimes need to read off the end of file for some reason
            if ~feof(fid) %checking to ensure we are at the end of the file (we should be)
                waveform = NaN;
                disp('WAVEFORM NOT IMPORTED CORRECTLY, PLEASE SAFE AS .CSV & SNED .ISF TO LIAM.')
                return
            end
            
            %% packaging for output
            
            fclose(fid);
            clearvars ans fid
            
            %% functions nested to make the code easier to read
            function get_locations
                locations.no_of_points              = find_location('NR_P');
                locations.bytes_per_point           = find_location('BYT_N');
                locations.bits_per_point            = find_location('BIT_N');
                locations.encoding                  = find_location('ENC');
                locations.binary_format             = find_location('BN_F');
                locations.byte_order                = find_location('BYT_O');
                locations.waveform_identifier       = find_location('WFI');
                locations.point_format              = find_location('PT_F');
                locations.horizontal_unit           = find_location('XUN');
                locations.horizontal_interval       = find_location('XIN');
                locations.horizontal_zero           = find_location('XZE');
                locations.trigger_point_offset      = find_location('PT_O');
                locations.vertical_unit             = find_location('YUN');
                locations.vertical_scale_factor     = find_location('YMU');
                locations.vertical_offset           = find_location('YOF');
                locations.vertical_zero             = find_location('YZE');
                locations.vertical_scale            = find_location('VSCALE');
                locations.horizontal_scale          = find_location('HSCALE');
                locations.vertical_position_unknown = find_location('VPOS');
                locations.vertical_offset_unknown   = find_location('VOFFSET');
                locations.horizontal_delay_unknown  = find_location('HDELAY');
            end
            function [location] = find_location(string)
                location = struct();
                location.start = regexp(data,string,'once'); %#ok %finding the start of the entry
                location.start = location.start + regexp(data(location.start:end),' ','once'); %#ok % finding the space in between entry and value
                location.length = regexp(data(location.start:end),';','once')-2; %#ok
            end
            
            function get_informations
                waveform.information.no_of_points              = str2double(get_information(locations.no_of_points));
                waveform.information.bytes_per_point           = str2double(get_information(locations.bytes_per_point));
                waveform.information.bits_per_point            = str2double(get_information(locations.bits_per_point));
                waveform.information.encoding                  = get_information(locations.encoding);
                waveform.information.binary_format             = get_information(locations.binary_format);
                waveform.information.byte_order                = get_information(locations.byte_order);
                waveform.information.waveform_identifier       = get_information(locations.waveform_identifier);
                waveform.information.point_format              = get_information(locations.point_format);
                waveform.information.horizontal_unit           = get_information(locations.horizontal_unit);
                waveform.information.horizontal_interval       = str2double(get_information(locations.horizontal_interval));
                waveform.information.horizontal_zero           = str2double(get_information(locations.horizontal_zero));
                waveform.information.trigger_point_offset      = str2double(get_information(locations.trigger_point_offset));
                waveform.information.vertical_unit             = get_information(locations.vertical_unit);
                waveform.information.vertical_scale_factor     = str2double(get_information(locations.vertical_scale_factor));
                waveform.information.vertical_offset           = str2double(get_information(locations.vertical_offset));
                waveform.information.vertical_zero             = str2double(get_information(locations.vertical_zero));
                waveform.information.vertical_scale            = str2double(get_information(locations.vertical_scale));
                waveform.information.horizontal_scale          = str2double(get_information(locations.horizontal_scale));
                waveform.information.vertical_position_unknown = get_information(locations.vertical_offset_unknown);
                waveform.information.horizontal_delay_unknown  = get_information(locations.horizontal_delay_unknown);
            end
            function [out] = get_information(location)
                out = data(location.start:location.start+location.length); %#ok
            end
            
            function clean_strings
                waveform.information.waveform_identifier    = regexprep(waveform.information.waveform_identifier,'"','');
                waveform.information.horizontal_unit        = regexprep(waveform.information.horizontal_unit,'"','');
                waveform.information.vertical_unit          = regexprep(waveform.information.vertical_unit,'"','');
            end
            function clean_information_struct
                %% Removing feilds containing information needed by the end user
                waveform.information = rmfield(waveform.information,'byte_order');
                waveform.information = rmfield(waveform.information,'bits_per_point');
                waveform.information = rmfield(waveform.information,'encoding');
                waveform.information = rmfield(waveform.information,'binary_format');
                waveform.information = rmfield(waveform.information,'point_format');
                waveform.information = rmfield(waveform.information,'horizontal_zero');
                waveform.information = rmfield(waveform.information,'trigger_point_offset');
                waveform.information = rmfield(waveform.information,'vertical_offset');
                waveform.information = rmfield(waveform.information,'vertical_zero');
                waveform.information = rmfield(waveform.information,'vertical_scale');
                waveform.information = rmfield(waveform.information,'horizontal_scale');
                waveform.information = rmfield(waveform.information,'vertical_position_unknown');
                waveform.information = rmfield(waveform.information,'horizontal_delay_unknown');
                
                %% Changing field name to match horizontal feilds
                waveform.information.vertical_interval = waveform.information.vertical_scale_factor;
                waveform.information = rmfield(waveform.information,'vertical_scale_factor');
                
            end
            
        end
        function waveform  = ImportScopeTekWFM(app,filename) 
            
            %% Initialising Locations & Waveform Variables and opening the binary file.
            fid = fopen(filename,'r'); % Opening the file that has been selected
            
            %% Creating waveform and locations structs
            waveform = struct(); %Building the waveform struct
            locations = struct(); % building the locations struct, this is used for working out where to read the data in the file, locations found by Liam on 4054 isf file, could vary scope to scope as no specific format for tek scopes.
            
            %% Determining the byte orde (LE or BE) then closing and reopening the file with the appropriate format.
            
            byte_order = fread(fid,1,'ushort'); %reading the byte order
            fclose(fid);
            
            if byte_order==61680 %equivalent to hexidecimal 0xF0F0, which is big endian
                fid = fopen(filename,'r','ieee-be'); %reopening file with big endian format
            elseif byte_order == 3855 %equivalent to hexidecimal 0x0F0F, which is little endian
                fid = fopen(filename,'r','ieee-le'); %reopening file with litee endian format
            else
                waveform = NaN;
                return
            end
            
            clearvars filename byte_order ans
            
            %% Importing the Waveform static file information and the Waveform header
            
            get_Waveform_static_file_information_locations
            get_Waveform_static_file_information
            
            get_Waveform_Header_locations
            get_Waveform_Header
            decipher_Waveform_Header_enums
            
            %% Checking file before importing the curve object
            % Making sure there are no FastFrame objects, if so I need to carefully
            % check the file.
            if waveform.Waveform_static_file_information.N_number_of_FastFrames_minus_one ~= 0
                disp('Waveform not processed correctly, contact Liam and keep the .wfm file to supply for testing')
                waveform = NaN;
                return
            end
            
            % Making sure the file is of the 3rd Revision format (the 7254 uses this
            % format, if not then the locations ALL change becuase Tektronix are not
            % very sensible.
            if ~strcmp(waveform.Waveform_static_file_information.Version_number,'WFM#003')
                disp('Waveform not processed correctly, contact Liam and keep the .wfm file to supply for testing')
                waveform = NaN;
                return
            end
            
            % Making sure there is only 1 curve recorded, if not then i need to check
            % the file.
            if waveform.Waveform_header.Reference_file_data.Curve_ref_count ~= 1
                disp('Waveform not processed correctly, contact Liam and keep the .wfm file to supply for testing')
                waveform = NaN;
                return
            end
            
            %% Importing the FastFrame Frames, CurveBuffer & Checksum
            
            get_FastFrame_Frames_locations
            get_FastFrame_Frames
            
            get_CurveBuffer_locations
            get_CurveBuffer
            
            %% More checking of the file
            % Checking to ensure there are no FastFrame objects.
            if locations.fast_frame_frames.N_WfmUpdateSpec_object ~= locations.CurveBuffer.Curve_buffer || locations.fast_frame_frames.N_WfmCurveSpec_objects ~= locations.CurveBuffer.Curve_buffer
                disp('Waveform not processed correctly, contact Liam and keep the .wfm file to supply for testing')
                waveform = NaN;
                return
            end
            
            %% Importing the WfmFileChecksum
            
            get_WfmFileChecksum_locations
            get_WfmFileChecksum
            
            %% Nested functions to make the script simpler to read.
            
            function get_Waveform_static_file_information_locations
                %location ref                                                                          location  format              length in bytes
                locations.Waveform_static_file_information.Byte_order_verification                   = 0;        %unsigned short     2
                locations.Waveform_static_file_information.Version_number                            = 3;        %char               8
                locations.Waveform_static_file_information.Number_of_digits_in_byte_count            = 10;       %char               1
                locations.Waveform_static_file_information.Number_of_bytes_to_the_end_of_file        = 11;       %longint            4
                locations.Waveform_static_file_information.Number_of_bytes_per_point                 = 15;       %char               1
                locations.Waveform_static_file_information.Byte_offset_to_beginning_of_curve_buffer  = 16;       %long int           4
                locations.Waveform_static_file_information.Waveform_label                            = 40;       %char               32
                locations.Waveform_static_file_information.N_number_of_FastFrames_minus_one          = 72;       %unsigned long      4
                locations.Waveform_static_file_information.Size_of_the_waveform_header_in_bytes      = 76;       %unsigned short     2
            end
            function get_Waveform_static_file_information
                waveform.Waveform_static_file_information.Byte_order_verification                   = ReadUShort(app,fid,locations.Waveform_static_file_information.Byte_order_verification);                           %unsigned short     2
                waveform.Waveform_static_file_information.Version_number                            = ReadChar(app,fid,  locations.Waveform_static_file_information.Version_number,7);                                  %char               8
                waveform.Waveform_static_file_information.Number_of_digits_in_byte_count            = ReadChar(app,fid,  locations.Waveform_static_file_information.Number_of_digits_in_byte_count,1,'DoNotConvert');   %char               1
                waveform.Waveform_static_file_information.Number_of_bytes_to_the_end_of_file        = 15 + ReadLong(app,fid,  locations.Waveform_static_file_information.Number_of_bytes_to_the_end_of_file);                %longint            4
                waveform.Waveform_static_file_information.Number_of_bytes_per_point                 = ReadChar(app,fid,  locations.Waveform_static_file_information.Number_of_bytes_per_point,1,'DoNotConvert');        %char               1
                waveform.Waveform_static_file_information.Byte_offset_to_beginning_of_curve_buffer  = ReadLong(app,fid,  locations.Waveform_static_file_information.Byte_offset_to_beginning_of_curve_buffer);          %long int           4
                waveform.Waveform_static_file_information.Waveform_label                            = ReadChar(app,fid,  locations.Waveform_static_file_information.Waveform_label,32);                                 %char               32
                waveform.Waveform_static_file_information.N_number_of_FastFrames_minus_one          = ReadULong(app,fid, locations.Waveform_static_file_information.N_number_of_FastFrames_minus_one);                  %unsigned long      4
                waveform.Waveform_static_file_information.Size_of_the_waveform_header_in_bytes      = ReadUShort(app,fid,locations.Waveform_static_file_information.Size_of_the_waveform_header_in_bytes);              %unsigned short     2
            end
            
            function get_Waveform_Header_locations
                %location ref                                                                             location  format              length in bytes
                locations.Waveform_header.Reference_file_data.SetType                                   = 78;       %enum (int)         4
                locations.Waveform_header.Reference_file_data.WfmCnt                                    = 82;       %unsigned long      4
                locations.Waveform_header.Reference_file_data.Wfm_update_specification_count            = 110;      %unsigned long      4
                locations.Waveform_header.Reference_file_data.Imp_dim_ref_count                         = 114;      %unsigned long      4
                locations.Waveform_header.Reference_file_data.Exp_dim_ref_count                         = 118;      %unsigned long      4
                locations.Waveform_header.Reference_file_data.Data_type                                 = 122;      %enum (int)         4
                locations.Waveform_header.Reference_file_data.Curve_ref_count                           = 142;      %unsigned long      4
                locations.Waveform_header.Reference_file_data.Number_of_requested_fast_frames           = 146;      %unsigned long      4
                locations.Waveform_header.Reference_file_data.Number_of_aquired_fast_frames             = 150;      %unsigned long      4
                locations.Waveform_header.Reference_file_data.Summary_frame_type                        = 154;      %unsigned short     2
                locations.Waveform_header.Reference_file_data.Pix_map_display_format                    = 156;      %enum (int)         4
                locations.Waveform_header.Reference_file_data.Pix_map_max_value                         = 160;      %unsigned long long 8
                
                
                locations.Waveform_header.Explicit_Dimension_1.Dim_scale                                = 168;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.Dim_offset                               = 176;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.Dim_size                                 = 184;      %unsigned long      4
                locations.Waveform_header.Explicit_Dimension_1.Units                                    = 188;      %char               20
                locations.Waveform_header.Explicit_Dimension_1.Dim_extent_min                           = 208;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.Dim_extent_max                           = 216;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.Dim_resolution                           = 224;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.Dim_ref_point                            = 232;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.Format                                   = 240;      %enum(int)          4
                locations.Waveform_header.Explicit_Dimension_1.Storage_type                             = 244;      %enum(int)          4
                locations.Waveform_header.Explicit_Dimension_1.N_value                                  = 248;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_1.Over_range                               = 252;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_1.Under_range                              = 256;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_1.High_range                               = 260;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_1.Row_range                                = 264;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_1.User_scale                               = 268;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.User_units                               = 276;      %char               20
                locations.Waveform_header.Explicit_Dimension_1.User_offset                              = 296;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.Point_density                            = 304;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.HRef_in_percent                          = 312;      %double             8
                locations.Waveform_header.Explicit_Dimension_1.TrigDelay_in_seconds                     = 320;      %double             8
                
                locations.Waveform_header.Explicit_Dimension_2.Dim_scale                                = 328;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.Dim_offset                               = 336;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.Dim_size                                 = 344;      %unsigned long      4
                locations.Waveform_header.Explicit_Dimension_2.Units                                    = 348;      %char               20
                locations.Waveform_header.Explicit_Dimension_2.Dim_extent_min                           = 368;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.Dim_extent_max                           = 376;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.Dim_resolution                           = 384;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.Dim_ref_point                            = 392;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.Format                                   = 400;      %enum(int)          4
                locations.Waveform_header.Explicit_Dimension_2.Storage_type                             = 404;      %enum(int)          4
                locations.Waveform_header.Explicit_Dimension_2.N_value                                  = 408;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_2.Over_range                               = 412;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_2.Under_range                              = 416;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_2.High_range                               = 420;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_2.Low_range                                = 424;      %4byte              4
                locations.Waveform_header.Explicit_Dimension_2.User_scale                               = 428;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.User_units                               = 436;      %char               20
                locations.Waveform_header.Explicit_Dimension_2.User_offset                              = 456;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.Point_density                            = 464;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.HRef_in_percent                          = 472;      %double             8
                locations.Waveform_header.Explicit_Dimension_2.TrigDelay_in_seconds                     = 480;      %double             8
                
                locations.Waveform_header.Implicit_Dimension_1.Dim_scale                                = 488;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.Dim_offset                               = 496;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.Dim_size                                 = 504;      %unsigned long      4
                locations.Waveform_header.Implicit_Dimension_1.Units                                    = 508;      %char               20
                locations.Waveform_header.Implicit_Dimension_1.Dim_extent_min                           = 528;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.Dim_extent_max                           = 536;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.Dim_resolution                           = 544;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.Dim_ref_point                            = 552;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.Spacing                                  = 560;      %enum(int)          4
                locations.Waveform_header.Implicit_Dimension_1.User_scale                               = 564;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.User_units                               = 572;      %char               20
                locations.Waveform_header.Implicit_Dimension_1.User_offset                              = 592;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.Point_density                            = 600;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.HRef_in_percent                          = 608;      %double             8
                locations.Waveform_header.Implicit_Dimension_1.TrigDelay_in_seconds                     = 616;      %double             8
                
                locations.Waveform_header.Implicit_Dimension_2.Dim_scale                                = 624;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.Dim_offset                               = 632;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.Dim_size                                 = 640;      %unsigned long      4
                locations.Waveform_header.Implicit_Dimension_2.Units                                    = 644;      %char               20
                locations.Waveform_header.Implicit_Dimension_2.Dim_extent_min                           = 664;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.Dim_extent_max                           = 672;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.Dim_resolution                           = 680;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.Dim_ref_point                            = 688;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.Spacing                                  = 696;      %enum(int)          4
                locations.Waveform_header.Implicit_Dimension_2.User_scale                               = 700;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.User_units                               = 708;      %char               20
                locations.Waveform_header.Implicit_Dimension_2.User_offset                              = 728;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.Point_density                            = 736;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.HRef_in_percent                          = 744;      %double             8
                locations.Waveform_header.Implicit_Dimension_2.TrigDelay_in_seconds                     = 752;      %double             8
                
                locations.Waveform_header.TimeBase_Info1.Real_point_spacing                             = 760;      %unsigned long      4
                locations.Waveform_header.TimeBase_Info1.Sweep                                          = 764;      %enum(int)          4
                locations.Waveform_header.TimeBase_Info1.Type_of_base                                   = 768;      %enum(int)          4
                
                locations.Waveform_header.TimeBase_Info2.Real_point_spacing                             = 772;      %unsigned long      4
                locations.Waveform_header.TimeBase_Info2.Sweep                                          = 776;      %enum(int)          4
                locations.Waveform_header.TimeBase_Info2.Type_of_base                                   = 780;      %enum(int)          4
                
                locations.Waveform_header.WfmUpdateSpec.Real_point_offset                               = 784;      %unsigned long      4
                locations.Waveform_header.WfmUpdateSpec.TT_offset                                       = 788;      %double             8
                locations.Waveform_header.WfmUpdateSpec.Frac_sec                                        = 796;      %double             8
                locations.Waveform_header.WfmUpdateSpec.Gmt_sec                                         = 804;      %long               4
                
                locations.Waveform_header.WfmCurveObject.State_flags                                    = 808;      %unsigned long      4
                locations.Waveform_header.WfmCurveObject.Type_of_check_sum                              = 812;      %enum(int)          4
                locations.Waveform_header.WfmCurveObject.Check_sum                                      = 816;      %short              2
                locations.Waveform_header.WfmCurveObject.Precharge_start_offset                         = 818;      %unsigned long      4
                locations.Waveform_header.WfmCurveObject.Data_start_offset                              = 822;      %unsigned long      4
                locations.Waveform_header.WfmCurveObject.Postcharge_start_offset                        = 826;      %unsigned long      4
                locations.Waveform_header.WfmCurveObject.Postcharge_stop_offset                         = 830;      %unsigned long      4
                locations.Waveform_header.WfmCurveObject.End_of_curve_buffer                            = 834;      %unsigned long      4
                
            end
            function get_Waveform_Header
                %% Importing Reference file data
                waveform.Waveform_header.Reference_file_data.SetType                         = ReadEnumTek(app,fid,  locations.Waveform_header.Reference_file_data.SetType);                                %enum (int)         4
                waveform.Waveform_header.Reference_file_data.WfmCnt                          = ReadULong(app,fid, locations.Waveform_header.Reference_file_data.WfmCnt);                                 %unsigned long      4
                waveform.Waveform_header.Reference_file_data.Wfm_update_specification_count  = ReadULong(app,fid, locations.Waveform_header.Reference_file_data.Wfm_update_specification_count);         %unsigned long      4
                waveform.Waveform_header.Reference_file_data.Imp_dim_ref_count               = ReadULong(app,fid, locations.Waveform_header.Reference_file_data.Imp_dim_ref_count);                 %unsigned long      4
                waveform.Waveform_header.Reference_file_data.Exp_dim_ref_count               = ReadULong(app,fid, locations.Waveform_header.Reference_file_data.Exp_dim_ref_count);                 %unsigned long      4
                waveform.Waveform_header.Reference_file_data.Data_type                       = ReadEnumTek(app,fid,  locations.Waveform_header.Reference_file_data.Data_type);                              %enum (int)         4
                waveform.Waveform_header.Reference_file_data.Curve_ref_count                 = ReadULong(app,fid, locations.Waveform_header.Reference_file_data.Curve_ref_count);                        %unsigned long      4
                waveform.Waveform_header.Reference_file_data.Number_of_requested_fast_frames = ReadULong(app,fid, locations.Waveform_header.Reference_file_data.Number_of_requested_fast_frames);            %unsigned long      4
                waveform.Waveform_header.Reference_file_data.Number_of_aquired_fast_frames   = ReadULong(app,fid, locations.Waveform_header.Reference_file_data.Number_of_aquired_fast_frames);              %unsigned long      4
                waveform.Waveform_header.Reference_file_data.Summary_frame_type              = ReadUShort(app,fid,locations.Waveform_header.Reference_file_data.Summary_frame_type);                     %unsigned short     2
                waveform.Waveform_header.Reference_file_data.Pix_map_display_format          = ReadEnumTek(app,fid,  locations.Waveform_header.Reference_file_data.Pix_map_display_format);                 %enum (int)         4
                waveform.Waveform_header.Reference_file_data.Pix_map_max_value               = ReadULong(app,fid, locations.Waveform_header.Reference_file_data.Pix_map_max_value);                      %unsigned long long 8
                
                %% Importing explicit dimension information
                if waveform.Waveform_header.Reference_file_data.Exp_dim_ref_count > 0
                    waveform.Waveform_header.Explicit_Dimension_1.Dim_scale                 = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.Dim_scale);                                  %double             8
                    waveform.Waveform_header.Explicit_Dimension_1.Dim_offset                = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.Dim_offset);                                 %double             8
                    waveform.Waveform_header.Explicit_Dimension_1.Dim_size                  = ReadULong(app,fid, locations.Waveform_header.Explicit_Dimension_1.Dim_size);                                   %unsigned long      4
                    waveform.Waveform_header.Explicit_Dimension_1.Units                     = ReadChar(app,fid,  locations.Waveform_header.Explicit_Dimension_1.Units,20);                                   %char               20
                    waveform.Waveform_header.Explicit_Dimension_1.Dim_extent_min            = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.Dim_extent_min);                             %double             8
                    waveform.Waveform_header.Explicit_Dimension_1.Dim_extent_max            = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.Dim_extent_max);                             %double             8
                    waveform.Waveform_header.Explicit_Dimension_1.Dim_resolution            = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.Dim_resolution);                             %double             8
                    waveform.Waveform_header.Explicit_Dimension_1.Dim_ref_point             = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.Dim_ref_point);                              %double             8
                    waveform.Waveform_header.Explicit_Dimension_1.Format                    = ReadEnumTek(app,fid,  locations.Waveform_header.Explicit_Dimension_1.Format);                                     %enum(int)          4
                    waveform.Waveform_header.Explicit_Dimension_1.Storage_type              = ReadEnumTek(app,fid,  locations.Waveform_header.Explicit_Dimension_1.Storage_type);                               %enum(int)          4
                    %         waveform.Waveform_header.Explicit_Dimension_1.n_value                                  = 246;      %4byte              4
                    %         waveform.Waveform_header.Explicit_Dimension_1.over_range                               = 250;      %4byte              4
                    %         waveform.Waveform_header.Explicit_Dimension_1.under_range                              = 254;      %4byte              4
                    %         waveform.Waveform_header.Explicit_Dimension_1.high_range                               = 258;      %4byte              4
                    %         waveform.Waveform_header.Explicit_Dimension_1.low_range                                = 262;      %4byte              4
                    waveform.Waveform_header.Explicit_Dimension_1.User_scale                = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.User_scale);                                 %double             8
                    waveform.Waveform_header.Explicit_Dimension_1.User_units                = ReadChar(app,fid,  locations.Waveform_header.Explicit_Dimension_1.User_units,20);                              %char               20
                    waveform.Waveform_header.Explicit_Dimension_1.User_offset               = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.User_offset);                                %double             8
                    waveform.Waveform_header.Explicit_Dimension_1.Point_density             = ReadULong(app,fid, locations.Waveform_header.Explicit_Dimension_1.Point_density);                              %unsigned long      4
                    waveform.Waveform_header.Explicit_Dimension_1.HRef_in_percent           = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.HRef_in_percent);                            %double             8
                    waveform.Waveform_header.Explicit_Dimension_1.TrigDelay_in_seconds      = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_1.TrigDelay_in_seconds);                       %double             8
                end
                if waveform.Waveform_header.Reference_file_data.Exp_dim_ref_count > 1
                    waveform.Waveform_header.Explicit_Dimension_2.Dim_scale                 = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.Dim_scale);                                  %double             8
                    waveform.Waveform_header.Explicit_Dimension_2.Dim_offset                = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.Dim_offset);                                 %double             8
                    waveform.Waveform_header.Explicit_Dimension_2.Dim_size                  = ReadULong(app,fid, locations.Waveform_header.Explicit_Dimension_2.Dim_size);                                   %unsigned long      4
                    waveform.Waveform_header.Explicit_Dimension_2.Units                     = ReadChar(app,fid,  locations.Waveform_header.Explicit_Dimension_2.Units,20);                                   %char               20
                    waveform.Waveform_header.Explicit_Dimension_2.Dim_extent_min            = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.Dim_extent_min);                             %double             8
                    waveform.Waveform_header.Explicit_Dimension_2.Dim_extent_max            = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.Dim_extent_max);                             %double             8
                    waveform.Waveform_header.Explicit_Dimension_2.Dim_resolution            = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.Dim_resolution);                             %double             8
                    waveform.Waveform_header.Explicit_Dimension_2.Dim_ref_point             = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.Dim_ref_point);                              %double             8
                    waveform.Waveform_header.Explicit_Dimension_2.Format                    = ReadEnumTek(app,fid,  locations.Waveform_header.Explicit_Dimension_2.Format);                                     %enum(int)          4
                    waveform.Waveform_header.Explicit_Dimension_2.Storage_type              = ReadEnumTek(app,fid,  locations.Waveform_header.Explicit_Dimension_2.Storage_type);                               %enum(int)          4
                    %         waveform.Waveform_header.Explicit_Dimension_2.n_value                                  = 402;      %4byte              4
                    %         waveform.Waveform_header.Explicit_Dimension_2.over_range                               = 406;      %4byte              4
                    %         waveform.Waveform_header.Explicit_Dimension_2.under_range                              = 410;      %4byte              4
                    %         waveform.Waveform_header.Explicit_Dimension_2.high_range                               = 414;      %4byte              4
                    %         waveform.Waveform_header.Explicit_Dimension_2.low_range                                = 418;      %4byte              4
                    waveform.Waveform_header.Explicit_Dimension_2.User_scale                = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.User_scale);                                 %double             8
                    waveform.Waveform_header.Explicit_Dimension_2.User_units                = ReadChar(app,  fid,locations.Waveform_header.Explicit_Dimension_2.User_units,20);                              %char               20
                    waveform.Waveform_header.Explicit_Dimension_2.User_offset               = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.User_offset);                                %double             8
                    waveform.Waveform_header.Explicit_Dimension_2.Point_density             = ReadULong(app, fid,locations.Waveform_header.Explicit_Dimension_2.Point_density);                              %unsigned long      4
                    waveform.Waveform_header.Explicit_Dimension_2.HRef_in_percent           = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.HRef_in_percent);                            %double             8
                    waveform.Waveform_header.Explicit_Dimension_2.TrigDelay_in_seconds      = ReadDouble(app,fid,locations.Waveform_header.Explicit_Dimension_2.TrigDelay_in_seconds);                       %double             8
                end
                
                %% Importing implicit dimension information
                if waveform.Waveform_header.Reference_file_data.Imp_dim_ref_count > 0
                    waveform.Waveform_header.Implicit_Dimension_1.Dim_scale                 = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.Dim_scale);                                  %double             8
                    waveform.Waveform_header.Implicit_Dimension_1.Dim_offset                = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.Dim_offset);                                 %double             8
                    waveform.Waveform_header.Implicit_Dimension_1.Dim_size                  = ReadULong(app, fid,locations.Waveform_header.Implicit_Dimension_1.Dim_size);                                   %unsigned long      4
                    waveform.Waveform_header.Implicit_Dimension_1.Units                     = ReadChar(app,  fid,locations.Waveform_header.Implicit_Dimension_1.Units,20);                                   %char               20
                    waveform.Waveform_header.Implicit_Dimension_1.Dim_extent_min            = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.Dim_extent_min);                             %double             8
                    waveform.Waveform_header.Implicit_Dimension_1.Dim_extent_max            = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.Dim_extent_max);                             %double             8
                    waveform.Waveform_header.Implicit_Dimension_1.Dim_resolution            = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.Dim_resolution);                             %double             8
                    waveform.Waveform_header.Implicit_Dimension_1.Dim_ref_point             = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.Dim_ref_point);                              %double             8
                    waveform.Waveform_header.Implicit_Dimension_1.Spacing                   = ReadEnumTek(app,  fid,locations.Waveform_header.Implicit_Dimension_1.Spacing);                                    %enum(int)          4
                    waveform.Waveform_header.Implicit_Dimension_1.User_scale                = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.User_scale);                                 %double             8
                    waveform.Waveform_header.Implicit_Dimension_1.User_units                = ReadChar(app,  fid,locations.Waveform_header.Implicit_Dimension_1.User_units,20);                              %char               20
                    waveform.Waveform_header.Implicit_Dimension_1.User_offset               = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.User_offset);                                %double             8
                    waveform.Waveform_header.Implicit_Dimension_1.Point_density             = ReadULong(app, fid,locations.Waveform_header.Implicit_Dimension_1.Point_density);                              %unsigned long      4
                    waveform.Waveform_header.Implicit_Dimension_1.HRef_in_percent           = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.HRef_in_percent);                            %double             8
                    waveform.Waveform_header.Implicit_Dimension_1.TrigDelay_in_seconds      = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_1.TrigDelay_in_seconds);                       %double             8
                end
                if waveform.Waveform_header.Reference_file_data.Imp_dim_ref_count > 1
                    waveform.Waveform_header.Implicit_Dimension_2.Dim_scale                 = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.Dim_scale);                                  %double             8
                    waveform.Waveform_header.Implicit_Dimension_2.Dim_offset                = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.Dim_offset);                                 %double             8
                    waveform.Waveform_header.Implicit_Dimension_2.Dim_size                  = ReadULong(app, fid,locations.Waveform_header.Implicit_Dimension_2.Dim_size);                                   %unsigned long      4
                    waveform.Waveform_header.Implicit_Dimension_2.Units                     = ReadChar(app,  fid,locations.Waveform_header.Implicit_Dimension_2.Units,20);                                   %char               20
                    waveform.Waveform_header.Implicit_Dimension_2.Dim_extent_min            = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.Dim_extent_min);                             %double             8
                    waveform.Waveform_header.Implicit_Dimension_2.Dim_extent_max            = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.Dim_extent_max);                             %double             8
                    waveform.Waveform_header.Implicit_Dimension_2.Dim_resolution            = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.Dim_resolution);                             %double             8
                    waveform.Waveform_header.Implicit_Dimension_2.Dim_ref_point             = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.Dim_ref_point);                              %double             8
                    waveform.Waveform_header.Implicit_Dimension_2.Spacing                   = ReadEnumTek(app,  fid,locations.Waveform_header.Implicit_Dimension_2.Spacing);                                    %enum(int)          4
                    waveform.Waveform_header.Implicit_Dimension_2.User_scale                = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.User_scale);                                 %double             8
                    waveform.Waveform_header.Implicit_Dimension_2.User_units                = ReadChar(app,  fid,locations.Waveform_header.Implicit_Dimension_2.User_units,20);                              %char               20
                    waveform.Waveform_header.Implicit_Dimension_2.User_offset               = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.User_offset);                                %double             8
                    waveform.Waveform_header.Implicit_Dimension_2.Point_density             = ReadULong(app, fid,locations.Waveform_header.Implicit_Dimension_2.Point_density);                              %unsigned long      4
                    waveform.Waveform_header.Implicit_Dimension_2.HRef_in_percent           = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.HRef_in_percent);                            %double             8
                    waveform.Waveform_header.Implicit_Dimension_2.TrigDelay_in_seconds      = ReadDouble(app,fid,locations.Waveform_header.Implicit_Dimension_2.TrigDelay_in_seconds);                       %double             8
                end
                
                %% Importing TimeBase Information
                if waveform.Waveform_header.Reference_file_data.Curve_ref_count > 0
                    waveform.Waveform_header.TimeBase_Info1.Real_point_spacing              = ReadULong(app,fid,locations.Waveform_header.TimeBase_Info1.Real_point_spacing);                                %unsigned long      4
                    waveform.Waveform_header.TimeBase_Info1.Sweep                           = ReadEnumTek(app, fid,locations.Waveform_header.TimeBase_Info1.Sweep);                                             %enum(int)          4
                    waveform.Waveform_header.TimeBase_Info1.Type_of_base                    = ReadEnumTek(app, fid,locations.Waveform_header.TimeBase_Info1.Type_of_base);                                      %enum(int)          4
                end
                if waveform.Waveform_header.Reference_file_data.Curve_ref_count > 1
                    waveform.Waveform_header.TimeBase_Info2.Real_point_spacing              = ReadULong(app,fid,locations.Waveform_header.TimeBase_Info2.Real_point_spacing);                                %unsigned long      4
                    waveform.Waveform_header.TimeBase_Info2.Sweep                           = ReadEnumTek(app, fid,locations.Waveform_header.TimeBase_Info2.Sweep);                                             %enum(int)          4
                    waveform.Waveform_header.TimeBase_Info2.Type_of_base                    = ReadEnumTek(app, fid,locations.Waveform_header.TimeBase_Info2.Type_of_base);                                      %enum(int)          4
                end
                
                %% Importing Waveform Update Spec
                waveform.Waveform_header.WfmUpdateSpec.Real_point_offset                = ReadULong(app, fid,locations.Waveform_header.WfmUpdateSpec.Real_point_offset);                                %unsigned long      4
                waveform.Waveform_header.WfmUpdateSpec.TT_offset                        = ReadDouble(app,fid,locations.Waveform_header.WfmUpdateSpec.TT_offset);                                         %double             8
                waveform.Waveform_header.WfmUpdateSpec.Frac_sec                         = ReadDouble(app,fid,locations.Waveform_header.WfmUpdateSpec.Frac_sec);                                          %double             8
                waveform.Waveform_header.WfmUpdateSpec.Gmt_sec                          = ReadLong(app,  fid,locations.Waveform_header.WfmUpdateSpec.Gmt_sec);                                           %long               4
                
                %% Importing Waveform Curve Objects
                waveform.Waveform_header.WfmCurveObject.State_flags                     = ReadULong(app,fid,locations.Waveform_header.WfmCurveObject.State_flags);                                       %unsigned long      4
                waveform.Waveform_header.WfmCurveObject.Type_of_check_sum               = ReadEnumTek(app, fid,locations.Waveform_header.WfmCurveObject.Type_of_check_sum);                                 %enum(int)          4
                waveform.Waveform_header.WfmCurveObject.Check_sum                       = ReadShort(app,fid,locations.Waveform_header.WfmCurveObject.Check_sum);                                         %short              2
                waveform.Waveform_header.WfmCurveObject.Precharge_start_offset          = ReadULong(app,fid,locations.Waveform_header.WfmCurveObject.Precharge_start_offset);                            %unsigned long      4
                waveform.Waveform_header.WfmCurveObject.Data_start_offset               = ReadULong(app,fid,locations.Waveform_header.WfmCurveObject.Data_start_offset);                                 %unsigned long      4
                waveform.Waveform_header.WfmCurveObject.Postcharge_start_offset         = ReadULong(app,fid,locations.Waveform_header.WfmCurveObject.Postcharge_start_offset);                           %unsigned long      4
                waveform.Waveform_header.WfmCurveObject.Postcharge_stop_offset          = ReadULong(app,fid,locations.Waveform_header.WfmCurveObject.Postcharge_stop_offset);                            %unsigned long      4
                waveform.Waveform_header.WfmCurveObject.End_of_curve_buffer             = ReadULong(app,fid,locations.Waveform_header.WfmCurveObject.End_of_curve_buffer);                               %unsigned long      4
                
            end
            function decipher_Waveform_Header_enums
                %% Deciphering Enums in Reference_file_data
                if waveform.Waveform_header.Reference_file_data.SetType == 0
                    waveform.Waveform_header.Reference_file_data.SetType = 'Single Waveform Set';
                elseif waveform.Waveform_header.Reference_file_data.SetType == 1
                    waveform.Waveform_header.Reference_file_data.SetType = 'FastFrame Set';
                    disp('This waveform contains FastFrame data, it will not have imported correctly, save as .dat and give the .wfm to Liam')
                    waveform = Nan;
                    return
                else
                    disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                    waveform = Nan;
                    return
                end
                if waveform.Waveform_header.Reference_file_data.Data_type == 0
                    waveform.Waveform_header.Reference_file_data.Data_type = 'WFMDATA_SCALAR_MEAS';
                elseif waveform.Waveform_header.Reference_file_data.Data_type == 1
                    waveform.Waveform_header.Reference_file_data.Data_type = 'WFMDATA_SCALAR_CONST';
                elseif waveform.Waveform_header.Reference_file_data.Data_type == 2
                    waveform.Waveform_header.Reference_file_data.Data_type = 'WFMDATA_VECTOR';
                elseif waveform.Waveform_header.Reference_file_data.Data_type == 4
                    waveform.Waveform_header.Reference_file_data.Data_type = 'WFMDATA_INVALID';
                elseif waveform.Waveform_header.Reference_file_data.Data_type == 5
                    waveform.Waveform_header.Reference_file_data.Data_type = 'WFMDATA_WFMDB';
                elseif waveform.Waveform_header.Reference_file_data.Data_type == 6
                    waveform.Waveform_header.Reference_file_data.Data_type = 'WFMDATA_DIGITAL';
                else
                    disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                    waveform = Nan;
                    return
                end
                if waveform.Waveform_header.Reference_file_data.Pix_map_display_format == 0
                    waveform.Waveform_header.Reference_file_data.Pix_map_display_format = 'DSY_FORMAT_INVALID';
                elseif waveform.Waveform_header.Reference_file_data.Pix_map_display_format == 1
                    waveform.Waveform_header.Reference_file_data.Pix_map_display_format = 'DSY_FORMAT_YT';
                elseif waveform.Waveform_header.Reference_file_data.Pix_map_display_format == 2
                    waveform.Waveform_header.Reference_file_data.Pix_map_display_format = 'DSY_FORMAT_XY';
                elseif waveform.Waveform_header.Reference_file_data.Pix_map_display_format == 3
                    waveform.Waveform_header.Reference_file_data.Pix_map_display_format = 'DSY_FORMAT_XYZ';
                else
                    disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                    waveform = Nan;
                    return
                end
                
                %% Deciphering enums in Explicit_Dimension section(s)
                if waveform.Waveform_header.Reference_file_data.Exp_dim_ref_count > 0
                    if waveform.Waveform_header.Explicit_Dimension_1.Format == 0
                        waveform.Waveform_header.Explicit_Dimension_1.Format = 'int16';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Format == 1
                        waveform.Waveform_header.Explicit_Dimension_1.Format = 'int32';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Format == 2
                        waveform.Waveform_header.Explicit_Dimension_1.Format = 'uint32';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Format == 3
                        waveform.Waveform_header.Explicit_Dimension_1.Format = 'uint64';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Format == 4
                        waveform.Waveform_header.Explicit_Dimension_1.Format = 'float32';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Format == 5
                        waveform.Waveform_header.Explicit_Dimension_1.Format = 'float64';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Format == 6
                        waveform.Waveform_header.Explicit_Dimension_1.Format = 'uint8';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Format == 7
                        waveform.Waveform_header.Explicit_Dimension_1.Format = 'int8';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Format == 8
                        waveform.Waveform_header.Explicit_Dimension_1.Format = 'EXP_INVALID_DATA_FORMAT';
                    else
                        disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                        waveform = Nan;
                        return
                    end
                    if waveform.Waveform_header.Explicit_Dimension_1.Storage_type == 0
                        waveform.Waveform_header.Explicit_Dimension_1.Storage_type = 'EXPLICIT_SAMPLE';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Storage_type == 1
                        waveform.Waveform_header.Explicit_Dimension_1.Storage_type = 'EXPLICIT_MIN_MAX';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Storage_type == 2
                        waveform.Waveform_header.Explicit_Dimension_1.Storage_type = 'EXPLICIT_VERT_HIST';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Storage_type == 3
                        waveform.Waveform_header.Explicit_Dimension_1.Storage_type = 'EXPLICIT_HOR_HIST';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Storage_type == 4
                        waveform.Waveform_header.Explicit_Dimension_1.Storage_type = 'EXPLICIT_ROW_ORDER';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Storage_type == 5
                        waveform.Waveform_header.Explicit_Dimension_1.Storage_type = 'EXPLICIT_COLUMN_ORDER';
                    elseif waveform.Waveform_header.Explicit_Dimension_1.Storage_type == 6
                        waveform.Waveform_header.Explicit_Dimension_1.Storage_type = 'EXPLICIT_INVALID_STORAGE';
                    else
                        disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                        waveform = Nan;
                        return
                    end
                end
                if waveform.Waveform_header.Reference_file_data.Exp_dim_ref_count > 1
                    if waveform.Waveform_header.Explicit_Dimension_2.Format == 0
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'int16';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Format == 1
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'int32';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Format == 2
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'uint32';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Format == 3
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'uint64';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Format == 4
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'float32';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Format == 5
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'float64';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Format == 6
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'uint8';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Format == 7
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'int8';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Format == 8
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'EXP_INVALID_DATA_FORMAT';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Format == 9
                        waveform.Waveform_header.Explicit_Dimension_2.Format = 'DIMENSION NOT IN USE';
                    else
                        disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                        waveform = Nan;
                        return
                    end
                    if waveform.Waveform_header.Explicit_Dimension_2.Storage_type == 0
                        waveform.Waveform_header.Explicit_Dimension_2.Storage_type = 'EXPLICIT_SAMPLE';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Storage_type == 1
                        waveform.Waveform_header.Explicit_Dimension_2.Storage_type = 'EXPLICIT_MIN_MAX';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Storage_type == 2
                        waveform.Waveform_header.Explicit_Dimension_2.Storage_type = 'EXPLICIT_VERT_HIST';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Storage_type == 3
                        waveform.Waveform_header.Explicit_Dimension_2.Storage_type = 'EXPLICIT_HOR_HIST';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Storage_type == 4
                        waveform.Waveform_header.Explicit_Dimension_2.Storage_type = 'EXPLICIT_ROW_ORDER';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Storage_type == 5
                        waveform.Waveform_header.Explicit_Dimension_2.Storage_type = 'EXPLICIT_COLUMN_ORDER';
                    elseif waveform.Waveform_header.Explicit_Dimension_2.Storage_type == 6
                        waveform.Waveform_header.Explicit_Dimension_2.Storage_type = 'EXPLICIT_INVALID_STORAGE';
                    else
                        disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                        waveform = Nan;
                        return
                    end
                end
                
                %% Deciphering enums in TimeBase_Info secition(s)
                if waveform.Waveform_header.Reference_file_data.Curve_ref_count > 0
                    if waveform.Waveform_header.TimeBase_Info1.Sweep == 0
                        waveform.Waveform_header.TimeBase_Info1.Sweep = 'SWEEP_ROLL';
                    elseif waveform.Waveform_header.TimeBase_Info1.Sweep == 1
                        waveform.Waveform_header.TimeBase_Info1.Sweep = 'SWEEP_SAMPLE';
                    elseif waveform.Waveform_header.TimeBase_Info1.Sweep == 2
                        waveform.Waveform_header.TimeBase_Info1.Sweep = 'SWEEP_ET';
                    elseif waveform.Waveform_header.TimeBase_Info1.Sweep == 3
                        waveform.Waveform_header.TimeBase_Info1.Sweep = 'SWEEP_INVALID';
                    else
                        disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                        waveform = Nan;
                        return
                    end
                    if waveform.Waveform_header.TimeBase_Info1.Type_of_base == 0
                        waveform.Waveform_header.TimeBase_Info1.Type_of_base = 'BASE_TIME';
                    elseif waveform.Waveform_header.TimeBase_Info1.Type_of_base == 1
                        waveform.Waveform_header.TimeBase_Info1.Type_of_base = 'BASE_SPECTRAL_MAG';
                    elseif waveform.Waveform_header.TimeBase_Info1.Type_of_base == 2
                        waveform.Waveform_header.TimeBase_Info1.Type_of_base = 'BASE_SPRECTRAL_PHASE';
                    elseif waveform.Waveform_header.TimeBase_Info1.Type_of_base == 3
                        waveform.Waveform_header.TimeBase_Info1.Type_of_base = 'BASE_INVALID';
                    else
                        disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                        waveform = Nan;
                        return
                    end
                end
                if waveform.Waveform_header.Reference_file_data.Curve_ref_count > 1
                    if waveform.Waveform_header.TimeBase_Info2.Sweep == 0
                        waveform.Waveform_header.TimeBase_Info2.Sweep = 'SWEEP_ROLL';
                    elseif waveform.Waveform_header.TimeBase_Info2.Sweep == 1
                        waveform.Waveform_header.TimeBase_Info2.Sweep = 'SWEEP_SAMPLE';
                    elseif waveform.Waveform_header.TimeBase_Info2.Sweep == 2
                        waveform.Waveform_header.TimeBase_Info2.Sweep = 'SWEEP_ET';
                    elseif waveform.Waveform_header.TimeBase_Info2.Sweep == 3
                        waveform.Waveform_header.TimeBase_Info2.Sweep = 'SWEEP_INVALID';
                    else
                        disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                        waveform = Nan;
                        return
                    end
                    if waveform.Waveform_header.TimeBase_Info2.Type_of_base == 0
                        waveform.Waveform_header.TimeBase_Info2.Type_of_base = 'BASE_TIME';
                    elseif waveform.Waveform_header.TimeBase_Info2.Type_of_base == 1
                        waveform.Waveform_header.TimeBase_Info2.Type_of_base = 'BASE_SPECTRAL_MAG';
                    elseif waveform.Waveform_header.TimeBase_Info2.Type_of_base == 2
                        waveform.Waveform_header.TimeBase_Info2.Type_of_base = 'BASE_SPRECTRAL_PHASE';
                    elseif waveform.Waveform_header.TimeBase_Info2.Type_of_base == 3
                        waveform.Waveform_header.TimeBase_Info2.Type_of_base = 'BASE_INVALID';
                    else
                        disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                        waveform = Nan;
                        return
                    end
                end
                
                %% Deciphering enums in WfmCurveObject
                if waveform.Waveform_header.WfmCurveObject.Type_of_check_sum == 0
                    waveform.Waveform_header.WfmCurveObject.Type_of_check_sum = 'NO_CHECKSUM';
                elseif waveform.Waveform_header.WfmCurveObject.Type_of_check_sum == 1
                    waveform.Waveform_header.WfmCurveObject.Type_of_check_sum = 'CTYPE_CRC16';
                elseif waveform.Waveform_header.WfmCurveObject.Type_of_check_sum == 2
                    waveform.Waveform_header.WfmCurveObject.Type_of_check_sum = 'CTYPE_SUM16';
                elseif waveform.Waveform_header.WfmCurveObject.Type_of_check_sum == 3
                    waveform.Waveform_header.WfmCurveObject.Type_of_check_sum = 'CTYPE_CRC32';
                elseif waveform.Waveform_header.WfmCurveObject.Type_of_check_sum == 4
                    waveform.Waveform_header.WfmCurveObject.Type_of_check_sum = 'CTYPE_SUM32';
                else
                    disp('This waveform has not imported correctly, save as .dat and give the .wfm to Liam')
                    waveform = Nan;
                    return
                end
                
            end
            
            function get_FastFrame_Frames_locations
                locations.fast_frame_frames.N_WfmUpdateSpec_object = 78 + waveform.Waveform_static_file_information.Size_of_the_waveform_header_in_bytes;
                locations.fast_frame_frames.N_WfmCurveSpec_objects = 78 + waveform.Waveform_static_file_information.Size_of_the_waveform_header_in_bytes + (24 * waveform.Waveform_static_file_information.N_number_of_FastFrames_minus_one);
            end
            function get_FastFrame_Frames
                %% This has not been written, however I don't have any FastFrame_Frames examples to write from, so will once i have the need.
            end
            
            function get_CurveBuffer_locations
                locations.CurveBuffer.Curve_buffer                       = waveform.Waveform_static_file_information.Byte_offset_to_beginning_of_curve_buffer;
            end
            function get_CurveBuffer
                
                number_of_data_points = waveform.Waveform_header.Implicit_Dimension_1.Dim_size;
                if number_of_data_points ~= waveform.Waveform_header.WfmCurveObject.Postcharge_stop_offset / waveform.Waveform_static_file_information.Number_of_bytes_per_point
                    disp('Error in format of waveform curve data, save alternate format and give Liam the .wfm')
                end
                data_point_format = waveform.Waveform_header.Explicit_Dimension_1.Format;
                waveform.CurveBuffer.Curve_buffer  = ReadDefinedFormat(app,fid,locations.CurveBuffer.Curve_buffer,number_of_data_points,data_point_format);
                clearvars number_of_data_points data_point_format
                
            end
            
            function get_WfmFileChecksum_locations
                locations.CurveBufferWfmFileChecksum.Waveform_file_checksum   = waveform.Waveform_static_file_information.Byte_offset_to_beginning_of_curve_buffer+waveform.Waveform_header.WfmCurveObject.End_of_curve_buffer; % Needs correcting as this assumes no user marks.
            end
            function get_WfmFileChecksum % WRITE ME
                frewind(fid)
                waveform.WfmFileChecksum.Waveform_file_checksum_calculated = sum(fread(fid,838+500032,'uchar'));
                waveform.WfmFileChecksum.Waveform_file_checksum = ReadULongLong(app,fid,locations.CurveBufferWfmFileChecksum.Waveform_file_checksum);
            end
            
            if waveform.WfmFileChecksum.Waveform_file_checksum_calculated == waveform.WfmFileChecksum.Waveform_file_checksum
                %disp('Checksum matches, File imported correctly')
            else
                disp('File Not imported correctly, record in different format and send .wfm to Liam')
            end
            
            %% Moving through to the end of the file (there seems to be a single blank byte which may be involved with the USER MARKS not being used but not sure.
            
            blank_line_count = 0;
            while ~feof(fid)
                blank_line_count = blank_line_count+1;
                fread(fid,1,'int8');
            end
            
            if blank_line_count == 1
                %disp('Single Blank byte at end of file, as expected')
            else
                disp('More blank lines than expected, below is the number recorded')
                disp(blank_line_count)
            end
            clearvars blank_line_count
            
            %% Creating Voltage & Time Series
            if waveform.Waveform_header.Reference_file_data.Curve_ref_count == 1
                waveform.voltage    = (waveform.CurveBuffer.Curve_buffer * waveform.Waveform_header.Explicit_Dimension_1.Dim_scale)+waveform.Waveform_header.Explicit_Dimension_1.Dim_offset;
                waveform.time       = (((1:waveform.Waveform_header.Implicit_Dimension_1.Dim_size) * waveform.Waveform_header.Implicit_Dimension_1.Dim_scale) + waveform.Waveform_header.Implicit_Dimension_1.Dim_offset)';
            else
                disp('Time and Voltage series for curve not generated correctly, record in different format and send .wfm to Liam')
            end
            
            %% Creating info struct containing extra information in understandable format
            
            waveform.info.horizontal_resolution         = waveform.Waveform_header.Implicit_Dimension_1.Dim_scale;
            waveform.info.vertical_resolution           = waveform.Waveform_header.Explicit_Dimension_1.Dim_scale;
            waveform.info.horizontal_unit               = waveform.Waveform_header.Implicit_Dimension_1.Units;
            waveform.info.vertical_unit                 = waveform.Waveform_header.Explicit_Dimension_1.Units;
            waveform.info.no_of_points                  = waveform.Waveform_header.Implicit_Dimension_1.Dim_size;
            waveform.info.time_of_aquisition            = datetime(waveform.Waveform_header.WfmUpdateSpec.Gmt_sec,'ConvertFrom','posixtime'); %Reckon scope clock wrong
            waveform.info.version_number                = waveform.Waveform_static_file_information.Version_number;
            waveform.info.no_of_bytes_per_data_point    = waveform.Waveform_static_file_information.Number_of_bytes_per_point;
            waveform.info.waveform_label                = waveform.Waveform_static_file_information.Waveform_label;
            
            waveform = rmfield(waveform,'Waveform_header');
            waveform = rmfield(waveform,'WfmFileChecksum');
            waveform = rmfield(waveform,'Waveform_static_file_information');
            waveform = rmfield(waveform,'CurveBuffer');
            
            clearvars locations
            
        end
        function waveform  = ImportScopeLecroy(app,filename) 
            %% Initialising Variables and opening the binary file.
            waveform = struct(); %Building the waveform struct
            
            fid = fopen(filename,'r'); % Opening the file that has been selected
            
            %% Finind the start location of the binary files, all lecroy binary files start with the characters WAVEDESC which is used as a reference location
            
            init_offset_search = fread(fid,50,'char')';
            offset = strfind(init_offset_search,'WAVEDESC') - 1;
            get_locations
            
            %% Closing and reopening the file such that the byte order (HIFIRST or LOFIRST) is considered.
            if logical(ReadEnumLecroy(app,fid,waveform.locations.COMM_ORDER))
                fclose(fid);
                fid=fopen(filename,'r','ieee-le');		% HIFIRST
            else
                fclose(fid);
                fid=fopen(filename,'r','ieee-be');		% LOFIRST
            end
            clearvars filename init_offset_search COMM_ORDER ans
            
            %% Reading information from the file, each
            get_waveform_info
            
            waveform_raw = waveform; %Need info settings in raw format for a few bits, so copy struct in raw from before mapping Enums to their meaning.
            decipher_enum
            
            read_user_text
            get_trigtime_array
            get_ris_time_array
            read_voltages
            read_second_voltages
            generate_time_series
            
            %% Removing unneccessary information from the waveform struct before it is returned
            waveform = rmfield(waveform,'locations');
            fid = fclose(fid);
            clearvars waveform_raw offset fid
            
            %% Functions contained within the master function, these serve to simplify the code
            function get_locations
                waveform.locations.TEMPLATE_NAME        = offset+ 16; %string
                waveform.locations.COMM_TYPE            = offset+ 32; %enum
                waveform.locations.COMM_ORDER           = offset+ 34; %enum
                waveform.locations.WAVE_DESCRIPTOR      = offset+ 36;	%long length of the descriptor block
                waveform.locations.USER_TEXT            = offset+ 40;	%long  length of the usertext block
                waveform.locations.RES_DESC1            = offset+ 44; %long
                waveform.locations.TRIGTIME_ARRAY       = offset+ 48; %long
                waveform.locations.RIS_TIME_ARRAY       = offset+ 52; %long
                waveform.locations.RES_ARRAY            = offset+ 56; %long
                waveform.locations.WAVE_ARRAY_1         = offset+ 60;	%long length (in Byte) of the sample array
                waveform.locations.WAVE_ARRAY_2         = offset+ 64; %long length (in Byte) of the optional second sample array
                waveform.locations.RES_ARRAY2           = offset+ 68; %long
                waveform.locations.RES_ARRAY3           = offset+ 72; %long
                waveform.locations.INSTRUMENT_NAME      = offset+ 76; %string
                waveform.locations.INSTRUMENT_NUMBER    = offset+ 92; %long
                waveform.locations.TRACE_LABEL          = offset+ 96; %string
                waveform.locations.RESERVED1            = offset+ 112; %word
                waveform.locations.RESERVED2            = offset+ 114; %word
                waveform.locations.WAVE_ARRAY_COUNT     = offset+ 116; %long
                waveform.locations.PNTS_PER_SCREEN      = offset+ 120; %long
                waveform.locations.FIRST_VALID_PNT      = offset+ 124; %long
                waveform.locations.LAST_VALID_PNT       = offset+ 128; %long
                waveform.locations.FIRST_POINT          = offset+ 132; %long
                waveform.locations.SPARSING_FACTOR      = offset+ 136; %long
                waveform.locations.SEGMENT_INDEX        = offset+ 140; %long
                waveform.locations.SUBARRAY_COUNT       = offset+ 144; %long
                waveform.locations.SWEEPS_PER_AQG       = offset+ 148; %long
                waveform.locations.POINTS_PER_PAIR      = offset+ 152; %word
                waveform.locations.PAIR_OFFSET          = offset+ 154; %word
                waveform.locations.VERTICAL_GAIN        = offset+ 156; %float
                waveform.locations.VERTICAL_OFFSET      = offset+ 160; %float
                waveform.locations.MAX_VALUE            = offset+ 164; %float
                waveform.locations.MIN_VALUE            = offset+ 168; %float
                waveform.locations.NOMINAL_BITS         = offset+ 172; %word
                waveform.locations.NOM_SUBARRAY_COUNT   = offset+ 174; %word
                waveform.locations.HORIZ_INTERVAL       = offset+ 176; %float
                waveform.locations.HORIZ_OFFSET         = offset+ 180; %double
                waveform.locations.PIXEL_OFFSET         = offset+ 188; %double
                waveform.locations.VERTUNIT             = offset+ 196; %unit_definition
                waveform.locations.HORUNIT              = offset+ 244; %unit_definition
                waveform.locations.HORIZ_UNCERTAINTY    = offset+ 292; %float
                waveform.locations.TRIGGER_TIME         = offset+ 296; %time_stamp
                waveform.locations.ACQ_DURATION         = offset+ 312; %float
                waveform.locations.RECORD_TYPE          = offset+ 316; %enum
                waveform.locations.PROCESSING_DONE      = offset+ 318; %enum
                waveform.locations.RESERVED5            = offset+ 320; %word
                waveform.locations.RIS_SWEEPS           = offset+ 322; %word
                waveform.locations.TIMEBASE             = offset+ 324; %enum
                waveform.locations.VERT_COUPLING		= offset+ 326; %enum
                waveform.locations.PROBE_ATT			= offset+ 328; %float
                waveform.locations.FIXED_VERT_GAIN      = offset+ 332; %enum
                waveform.locations.BANDWIDTH_LIMIT      = offset+ 334; %enum
                waveform.locations.VERTICAL_VERNIER     = offset+ 336; %enum
                waveform.locations.ACQ_VERT_OFFSET      = offset+ 340; %float
                waveform.locations.WAVE_SOURCE          = offset+ 344; %enum
            end
            function get_waveform_info
                waveform.info.template_name           = ReadString(app,fid,waveform.locations.TEMPLATE_NAME);
                waveform.info.comm_type               = ReadEnumLecroy(app,fid,waveform.locations.COMM_TYPE);
                waveform.info.comm_order              = ReadEnumLecroy(app,fid,waveform.locations.COMM_ORDER);
                waveform.info.wave_descriptor         = ReadLong(app,fid,waveform.locations.WAVE_DESCRIPTOR);
                waveform.info.user_text               = ReadLong(app,fid,waveform.locations.USER_TEXT);
                waveform.info.res_desc1               = ReadLong(app,fid,waveform.locations.RES_DESC1);
                waveform.info.trigtime_array          = ReadLong(app,fid,waveform.locations.TRIGTIME_ARRAY);
                waveform.info.ris_time_array          = ReadLong(app,fid,waveform.locations.RIS_TIME_ARRAY);
                waveform.info.res_array               = ReadLong(app,fid,waveform.locations.RES_ARRAY);
                waveform.info.wave_array1             = ReadLong(app,fid,waveform.locations.WAVE_ARRAY_1);
                waveform.info.wave_array2             = ReadLong(app,fid,waveform.locations.WAVE_ARRAY_2);
                waveform.info.res_array2              = ReadLong(app,fid,waveform.locations.RES_ARRAY2);
                waveform.info.res_array3              = ReadLong(app,fid,waveform.locations.RES_ARRAY3);
                waveform.info.instrument_name         = ReadString(app,fid,waveform.locations.INSTRUMENT_NAME);
                waveform.info.instrument_number       = ReadLong(app,fid,waveform.locations.INSTRUMENT_NUMBER);
                waveform.info.trace_label             = ReadString(app,fid,waveform.locations.TRACE_LABEL);
                waveform.info.reserved1               = ReadWord(app,fid,waveform.locations.RESERVED1);
                waveform.info.reserved2               = ReadWord(app,fid,waveform.locations.RESERVED2);
                waveform.info.wave_array_count        = ReadLong(app,fid,waveform.locations.WAVE_ARRAY_COUNT);
                waveform.info.points_per_screen       = ReadLong(app,fid,waveform.locations.PNTS_PER_SCREEN);
                waveform.info.first_valid_point       = ReadLong(app,fid,waveform.locations.FIRST_VALID_PNT);
                waveform.info.last_valid_point        = ReadLong(app,fid,waveform.locations.LAST_VALID_PNT);
                waveform.info.first_point             = ReadLong(app,fid,waveform.locations.FIRST_POINT);
                waveform.info.sparsing_factor         = ReadLong(app,fid,waveform.locations.SPARSING_FACTOR);
                waveform.info.segment_index           = ReadLong(app,fid,waveform.locations.SEGMENT_INDEX);
                waveform.info.subarray_count          = ReadLong(app,fid,waveform.locations.SUBARRAY_COUNT);
                waveform.info.sweeps_per_aqg          = ReadLong(app,fid,waveform.locations.SWEEPS_PER_AQG);
                waveform.info.points_per_pair         = ReadWord(app,fid,waveform.locations.POINTS_PER_PAIR);
                waveform.info.pair_offset             = ReadWord(app,fid,waveform.locations.PAIR_OFFSET);
                waveform.info.vertical_gain           = ReadFloat(app,fid,waveform.locations.VERTICAL_GAIN);
                waveform.info.vertical_offset         = ReadFloat(app,fid,waveform.locations.VERTICAL_OFFSET);
                waveform.info.max_value               = ReadFloat(app,fid,waveform.locations.MAX_VALUE);
                waveform.info.min_value               = ReadFloat(app,fid,waveform.locations.MIN_VALUE);
                waveform.info.nominal_bits            = ReadWord(app,fid,waveform.locations.NOMINAL_BITS);
                waveform.info.nom_subarray_count      = ReadWord(app,fid,waveform.locations.NOM_SUBARRAY_COUNT);
                waveform.info.horizontal_interval     = ReadFloat(app,fid,waveform.locations.HORIZ_INTERVAL);
                waveform.info.horizontal_offset       = ReadDouble(app,fid,waveform.locations.HORIZ_OFFSET);
                waveform.info.pixel_offset            = ReadDouble(app,fid,waveform.locations.PIXEL_OFFSET);
                waveform.info.vertical_unit           = ReadUnitDefinition(app,fid,waveform.locations.VERTUNIT);
                waveform.info.horizontal_unit         = ReadUnitDefinition(app,fid,waveform.locations.HORUNIT);
                waveform.info.horizontal_uncertainty  = ReadFloat(app,fid,waveform.locations.HORIZ_UNCERTAINTY);
                waveform.info.trigger_time            = ReadTimestamp(app,fid,waveform.locations.TRIGGER_TIME);
                waveform.info.acq_duration            = ReadFloat(app,fid,waveform.locations.ACQ_DURATION);
                waveform.info.recording_type          = ReadEnumLecroy(app,fid,waveform.locations.RECORD_TYPE);
                waveform.info.processing_done         = ReadEnumLecroy(app,fid,waveform.locations.PROCESSING_DONE);
                waveform.info.reserved5               = ReadWord(app,fid,waveform.locations.RESERVED5);
                waveform.info.ris_sweeps              = ReadWord(app,fid,waveform.locations.RIS_SWEEPS);
                waveform.info.timebase                = ReadEnumLecroy(app,fid,waveform.locations.TIMEBASE);
                waveform.info.vertical_coupling       = ReadEnumLecroy(app,fid,waveform.locations.VERT_COUPLING);
                waveform.info.probe_attenuation       = ReadFloat(app,fid,waveform.locations.PROBE_ATT);
                waveform.info.fixed_vertical_gain     = ReadEnumLecroy(app,fid,waveform.locations.FIXED_VERT_GAIN);
                waveform.info.bandwidth_limit         = ReadEnumLecroy(app,fid,waveform.locations.BANDWIDTH_LIMIT);
                waveform.info.vertical_vernier        = ReadFloat(app,fid,waveform.locations.VERTICAL_VERNIER);
                waveform.info.acq_vertical_offset     = ReadFloat(app,fid,waveform.locations.ACQ_VERT_OFFSET);
                waveform.info.wave_source             = ReadEnumLecroy(app,fid,waveform.locations.WAVE_SOURCE);
            end
            function decipher_enum
                tmp = ['byte';'word'];
                waveform.info.comm_type = tmp(1+waveform.info.comm_type,:);
                
                tmp = ['HIFIRST';'LOFIRST'];
                waveform.info.comm_order = tmp(1+waveform.info.comm_order,:);
                
                tmp=[
                    'single_sweep      ';	'interleaved       '; 'histogram         ';
                    'graph             ';	'filter_coefficient'; 'complex           ';
                    'extrema           ';	'sequence_obsolete '; 'centered_RIS      ';
                    'peak_detect       '];
                waveform.info.recording_type = deblank(tmp(1+waveform.info.recording_type,:));
                
                tmp=[
                    'no_processing';   'fir_filter   '; 'interpolated ';   'sparsed      ';
                    'autoscaled   ';   'no_result    '; 'rolling      ';   'cumulative   '];
                waveform.info.processing_done		= deblank(tmp (1+waveform.info.processing_done,:));
                
                if waveform.info.timebase == 100
                    waveform.info.timebase = 'EXTERNAL';
                else
                    tmp=[
                        '1 ps / div  ';'2 ps / div  ';'5 ps / div  ';'10 ps / div ';'20 ps / div ';'50 ps / div ';'100 ps / div';'200 ps / div';'500 ps / div';
                        '1 ns / div  ';'2 ns / div  ';'5 ns / div  ';'10 ns / div ';'20 ns / div ';'50 ns / div ';'100 ns / div';'200 ns / div';'500 ns / div';
                        '1 us / div  ';'2 us / div  ';'5 us / div  ';'10 us / div ';'20 us / div ';'50 us / div ';'100 us / div';'200 us / div';'500 us / div';
                        '1 ms / div  ';'2 ms / div  ';'5 ms / div  ';'10 ms / div ';'20 ms / div ';'50 ms / div ';'100 ms / div';'200 ms / div';'500 ms / div';
                        '1 s / div   ';'2 s / div   ';'5 s / div   ';'10 s / div  ';'20 s / div  ';'50 s / div  ';'100 s / div ';'200 s / div ';'500 s / div ';
                        '1 ks / div  ';'2 ks / div  ';'5 ks / div  '];
                    waveform.info.timebase = deblank(tmp(1+waveform.info.timebase,:));
                end
                
                tmp=['DC_50_Ohms'; 'ground    ';'DC 1MOhm  ';'ground    ';'AC 1MOhm  '];
                waveform.info.vertical_coupling		= deblank(tmp(1+waveform.info.vertical_coupling,:));
                
                tmp=[
                    '1 uV / div  ';'2 uV / div  ';'5 uV / div  ';'10 uV / div ';'20 uV / div ';'50 uV / div ';'100 uV / div';'200 uV / div';'500 uV / div';
                    '1 mV / div  ';'2 mV / div  ';'5 mV / div  ';'10 mV / div ';'20 mV / div ';'50 mV / div ';'100 mV / div';'200 mV / div';'500 mV / div';
                    '1 V / div   ';'2 V / div   ';'5 V / div   ';'10 V / div  ';'20 V / div  ';'50 V / div  ';'100 V / div ';'200 V / div ';'500 V / div ';
                    '1 kV / div  '];
                waveform.info.fixed_vertical_gain = deblank(tmp(1+waveform.info.fixed_vertical_gain,:));
                
                tmp=['off'; 'on '];
                waveform.info.bandwidth_limit	= deblank(tmp(1+waveform.info.bandwidth_limit,:));
                
                if waveform.info.wave_source == 9
                    waveform.info.wave_source = 'UNKNOWN';
                else
                    tmp=['C1     ';'C2     ';'C3     ';'C4     ';'UNKNOWN'];
                    waveform.info.wave_source = deblank(tmp (1+waveform.info.wave_source,:));
                end
                
                clearvars tmp
                
            end
            function read_user_text
                if logical(waveform.info.user_text)
                    disp('THIS FILE CONTAINS INFORMATION THAT MAY NOT HAVE BEEN IMPORTED, PLEASE SAVE AS .dat ON SCOPE AND SEND LIAM THE .trc FILE')
                    fseek(fid,offset+waveform.info.wave_descriptor,'bof');
                    waveform.usertext = fread(fid,waveform.info.user_text,'char');
                end
            end
            function get_trigtime_array
                if logical(waveform.info.trigtime_array)
                    disp('THIS FILE CONTAINS INFORMATION THAT MAY NOT HAVE BEEN IMPORTED, PLEASE SAVE AS .dat ON SCOPE AND SEND LIAM THE .trc FILE')
                    waveform.trigtime_array.trigger_time = [];
                    waveform.trigtime_array.trigger_offset = [];
                    for i = 0:(waveform.info.nom_subarray_count-1)
                        waveform.trigtime_array.trigger_time(i+1) = ReadDouble(app,fid,offset+waveform.info.wave_descriptor + waveform.info.user_text + (i*16));
                        waveform.trigtime_array.trigger_offset(i+1) = ReadDouble(app,fid,offset+waveform.info.wave_descriptor + waveform.info.user_text + (i*16) + 8);
                    end
                    waveform.trigtime_array.trigger_time = ReadDouble(app,fid,offset+waveform.info.wave_descriptor + waveform.info.user_text);
                    waveform.trigtime_array.trigger_offset = ReadDouble(app,fid,offset+waveform.info.wave_descriptor + waveform.info.user_text + 8);
                end
            end
            function get_ris_time_array
                if logical(waveform.info.ris_time_array)
                    disp('THIS FILE CONTAINS INFORMATION THAT MAY NOT HAVE BEEN IMPORTED, PLEASE SAVE AS .dat ON SCOPE AND SEND LIAM THE .trc FILE')
                    fseek(fid,offset+waveform.info.wave_descriptor + waveform.info.user_text+waveform.info.trigtime_array,'bof');
                    waveform.ris_time_array.ris_offset = fread(fid,waveform.info.ris_sweeps,'float64');
                end
            end
            function read_voltages
                fseek(fid, offset + waveform_raw.info.wave_descriptor + waveform_raw.info.user_text + waveform_raw.info.trigtime_array + waveform.info.ris_time_array, 'bof');
                if logical(waveform_raw.info.comm_type) %word
                    waveform.voltage=fread(fid,waveform.info.wave_array1, 'int16');
                else %byte
                    waveform.voltage=fread(fid,waveform.info.wave_array1,'int8');
                end
                
                waveform.voltage = waveform.voltage * waveform.info.vertical_gain - waveform.info.vertical_offset;
            end
            function read_second_voltages
                if logical(waveform.info.wave_array2)
                    disp('THIS FILE CONTAINS INFORMATION THAT MAY NOT HAVE BEEN IMPORTED, PLEASE SAVE AS .dat ON SCOPE AND SEND LIAM THE .trc FILE')
                    if ~logical(points_per_pair)
                        fseek(fid, offset + waveform_raw.info.wave_descriptor + waveform_raw.info.user_text + waveform_raw.info.trigtime_array + waveform.info.ris_time_array +waveform.info.wave_array1 , 'bof');
                        if logical(waveform_raw.info.comm_type) %word
                            waveform.voltage=fread(fid,waveform.info.wave_array1, 'int16');
                        else %byte
                            waveform.voltage=fread(fid,waveform.info.wave_array1,'int8');
                        end
                        waveform.voltage2 = waveform.voltage2 * waveform.info.vertical_gain - waveform.info.vertical_offset;
                    else
                        fseek(fid, offset + waveform_raw.info.wave_descriptor + waveform_raw.info.user_text + waveform_raw.info.trigtime_array + waveform.info.ris_time_array +waveform.info.wave_array1 , 'bof');
                        if logical(waveform_raw.info.comm_type) %word
                            waveform.voltage=fread(fid,2*(waveform.info.wave_array1/waveform.info.points_per_pair), 'int16');
                        else %byte
                            waveform.voltage=fread(fid,2*(waveform.info.wave_array1/waveform.info.points_per_pair),'int8');
                        end
                        waveform.voltage2 = waveform.voltage2 * waveform.info.vertical_gain - waveform.info.vertical_offset;
                    end
                    
                end
            end
            function generate_time_series
                waveform.time = (0:waveform.info.wave_array_count-1) * waveform.info.horizontal_interval + waveform.info.horizontal_offset;
                waveform.time = waveform.time(:);
            end
            
        end
        
        %% Low level import functions for scope import
        function s = ReadString(        app,fid,Addr) %#ok
           	fseek(fid,Addr,'bof'); %move to the address listed in relation to the beginning of the file
           	s=deblank(fgets(fid,16)); %read the next 16 characters of the line (all strings in lecroy binary file are 16 characters long)
        end
        function e = ReadEnumLecroy(    app,fid,Addr) %#ok
            fseek(fid,Addr,'bof');
            e = fread(fid,1,'int16');
        end
        function w = ReadWord(          app,fid,Addr) %#ok
           	fseek(fid,Addr,'bof');
           	w=fread(fid,1,'int16');
        end
        function d = ReadDouble(        app,fid,Addr) %#ok
           	fseek(fid,Addr,'bof');
           	d=fread(fid,1,'float64');
        end
        function s = ReadUnitDefinition(app,fid,Addr) %#ok
           	fseek(fid,Addr,'bof'); %move to the address listed in relation to the beginning of the file
           	s=deblank(fgets(fid,48)); %read the next 48 characters of the line (all strings in lecroy binary file are 16 characters long)
        end
        function t = ReadTimestamp(     app,fid,Addr) %#ok
            fseek(fid,Addr,'bof');
            
            seconds	= fread(fid,1,'float64');
            minutes	= fread(fid,1,'int8');
            hours	= fread(fid,1,'int8');
            days	= fread(fid,1,'int8');
            months	= fread(fid,1,'int8');
            year	= fread(fid,1,'int16');
            
            t=sprintf('%i.%i.%i, %i:%i:%2.0f', days, months, year, hours, minutes, seconds);
        end
        function l = ReadULong(         app,fid,Addr) %#ok
            fseek(fid,Addr,'bof');
            l = fread(fid,1,'ulong');
        end
        function l = ReadULongLong(     app,fid,Addr) %#ok
            fseek(fid,Addr,'bof');
            l = fread(fid,1,'int64');
        end
        function s = ReadUShort(        app,fid,Addr) %#ok
            fseek(fid,Addr,'bof');
            s = fread(fid,1,'ushort');
        end
        function f = ReadFloat(         app,fid,Addr) %#ok
           	fseek(fid,Addr,'bof');
           	f=fread(fid,1,'float');
        end
        function l = ReadLong(          app,fid,Addr) %#ok
           	fseek(fid,Addr,'bof');
           	l=fread(fid,1,'long');
        end
        function s = ReadShort(         app,fid,Addr) %#ok
            fseek(fid,Addr,'bof');
            s = fread(fid,1,'short');
        end
        function c = ReadChar(          app,fid,Addr,No_of_char,DoNotConvert) %#ok
           	fseek(fid,Addr,'bof');
            if nargin < 4
                DoNotConvert = 'Convert';
            end
            if ~strcmp(DoNotConvert,'DoNotConvert')
                c = char(fread(fid,No_of_char,'char')');
            else
                c = fread(fid,No_of_char,'char')';
            end
        end
        function e = ReadEnumTek(       app,fid,Addr) %#ok
            fseek(fid,Addr,'bof');
            e = fread(fid,1,'int');
        end
        function c = ReadDefinedFormat( app,fid,Addr,No_of_elem,format) %#ok
            fseek(fid,Addr,'bof');
            c = fread(fid,No_of_elem,format);
        end
    end
    
    methods (Access = public)
        function ParentAppPullOutputs(app,Outputs)  
            if isstruct(Outputs)
                Outputs = Outputs.Dataset1;
                try
                    % Importing data variables into app properties
                    app.data.t  = Outputs.time;
                    app.data.v  = Outputs.voltage;
                    app.data.fs = 1/abs(app.data.t(2) - app.data.t(1));
                    
                    % Computing the raw spectrogram
                    app = compute_raw_spectrogram(app);
                catch
                end
                
                raw_props_gui_to_struct(app);
                crop_props_gui_to_struct(app);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function PDV_TOOLOpeningFcn(app, t, v)
            app.ReadyLamp.Color = 'r';
            
            % Setting SessionID
            app.SessionID = datenum(clock);
            
            % Trying to process data if the fn is run with inputs
            try
                % Importing data variables into app properties
                app.data.t  = t;
                app.data.v  = v;
                app.data.fs = 1/abs(t(2) - t(1));
                
                % Computing the raw spectrogram
                app = compute_raw_spectrogram(app);
            catch
            end
            
            app = raw_props_gui_to_struct(app);
            app = crop_props_gui_to_struct(app);
            
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
                app.processed_transform = app.crop_transform;
                app.processed_props     = app.crop_props;
                
                % Plotting processed spectrogram (has no baseline removal at the moment)
                plot_freq_spectrogram(app,app.ProcessedPlot,app.processed_transform,app.processed_props,'Processed Spectrogram')
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
            
            % Creating pop-out figure
            roifig  = figure();
            roiax   = axes(roifig);
            plot_freq_spectrogram(app,roiax,app.processed_transform,app.processed_props,'Please Draw ROI')
            
            % Specifying ROI
            [app.processed_transform.roi,app.processed_transform.roi_x,app.processed_transform.roi_y] = roipoly();
            
            % Closing figure and clearing figure and axis handles
            close(gcf)
            clearvars roiax roifig
            
            % Jumping back to the UI
            figure(app.figure1)
            
            % Adding ROI to the processed plot
            hold(app.ProcessedPlot,'on')
            app.processed_transform.roiplot = plot(app.ProcessedPlot,app.processed_transform.roi_x,app.processed_transform.roi_y,'k');
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ResetROIButton
        function ResetROIButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Attempting to delete the plot of the ROI from processedPlot  and then remove the ROI field from the processed_transform struct.
            try delete(app.processed_transform.roiplot)
                app.processed_transform = rmfield(app.processed_transform,{'roiplot,roi,roi_x,roi_y'});
            catch 
            end
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ConfirmRoiButton
        function ConfirmRoiButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Copying processed data to velocity data
            app.velocity_props = app.processed_props;
            app.velocity_transform = app.processed_transform;
            
            % Applying the ROI if one has been set
            try
                app.velocity_transform.P = app.velocity_transform.P .* app.processed_transform.roi;
            catch
            end
                        
            % Removing any empty timesteps from velocity data
            col_to_remove = ~any(app.velocity_transform.P); % THIS MIGHT HAVE AN ISSUE
            app.velocity_transform.P(:,col_to_remove) = [];
            app.velocity_transform.T(:,col_to_remove) = [];
            clearvars col_to_remove
            
            % Setting the velocity scale from the frequency scale
            app.velocity_transform.velocity_scale = 0.5*(1e-9 * app.WavelengthField.Value)*app.velocity_transform.F-app.ZeroVelocityField.Value;
            
            % Plotting the velocity spectrogram
            plot_vel_spectrogram(app,app.VelocityPlot,app.velocity_transform,app.velocity_props,'Velocity Spectrogram')
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ShiftSwitchButton
        function ShiftSwitchButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Removing the extracted velocity line and the output field if they have been created.
            try delete(app.velocity_transform.extracted_velocity_line)
                app.output = rmfield(app.output,{'time','velocity','errors'});
            catch
            end
            
            % Reversing the velocity scale to swap between upshift and downshift
            app.velocity_transform.P = flip(app.velocity_transform.P,1);
            
            % Replotting the velocity spectrogram
            hold(app.VelocityPlot,"off")
            plot_vel_spectrogram(app,app.VelocityPlot,app.velocity_transform,app.velocity_props,'Velocity Spectrogram')
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ExtractVelocitiesButton
        function ExtractVelocitiesButtonButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Creating the initial guess for the gaussian fit
            init_velocity_guess = find(app.velocity_transform.P(:,1)==max(app.velocity_transform.P(:,1))); %this finds the index
            init_guess = [1 init_velocity_guess 10]; %the peak velocity is scaled down by the max velocity so, amplitude a=1. b is the index. c=10 is the std dev guess.

            % Initialise the velocity vector in app.output, contains the three fitted gauss coeffs at every time step.
            app.output.velocity = zeros(3,3,length(app.velocity_transform.T));
            
            % Fitting the first timestep from the initial guess
            app.output.velocity(:,:,1) = fit_gaussian(app,app.velocity_transform.P(:,1),init_guess);
            
            % Fitting all following timesteps iteratively using previous fit as a guide.
            for i = 2:size(app.velocity_transform.P,2)
                app.output.velocity(:,:,i) = fit_gaussian(app,app.velocity_transform.P(:,i),app.output.velocity(1,:,i-1)); %set the start_points guess as the previous steps coeffs
            end
            
            % Creating the output time vector
            app.output.time     = app.velocity_transform.T + app.velocity_props.start_time;
            
            % Rearranging velocity vector to give actual velocity vector and error vector.
            app.output.errors   = squeeze(app.output.velocity(3,2,:)-app.output.velocity(2,2,:));
            app.output.velocity = round(squeeze(app.output.velocity(1,2,:)));
            
            % Mapping the velocity and error vectors from pixel space to velocity space.
            app.output.velocity = app.velocity_transform.velocity_scale(app.output.velocity);
            app.output.errors   = app.output.errors * abs(app.velocity_transform.velocity_scale(2)-app.velocity_transform.velocity_scale(1));
            
            % Plotting the extracted velocity line
            hold(app.VelocityPlot,'on')
            app.velocity_transform.extracted_velocity_line = plot(app.VelocityPlot,app.output.time*1e6,app.output.velocity,'Color',[0 0.447 0.741]);
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: SaveVelocitiesButton
        function SaveVelocitiesButtonButtonPushed(app, event)
            % Mapping the output struct to the output variables
            time        = app.output.time; %#ok
            velocity    = app.output.velocity; %#ok
            errors      = app.output.errors; %#ok

            uisave({'time','velocity','errors'},'PDVTOOL.mat')
            clearvars time velocity errors
        end

        % Button pushed function: RecalculateVelocitiesButton
        function RecalculateVelocitiesButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Removing the extracted velocity line and the output field if they have been created.
            try delete(app.velocity_transform.extracted_velocity_line)
                app.output = rmfield(app.output,{'time','velocity','errors'});
            catch
            end
            
            % Recalculating velocity scale
            app.velocity_transform.velocity_scale = 0.5*(1e-9 * app.WavelengthField.Value)*app.velocity_transform.F-app.ZeroVelocityField.Value;
            
            % Replotting velocity spectrogram
            hold(app.VelocityPlot,"off")
            plot_vel_spectrogram(app,app.VelocityPlot,app.velocity_transform,app.velocity_props,'Velocity Spectrogram')
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: IdentifyOffsetButton
        function IdentifyOffsetButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            try
                %Identifying indices of sample region
                [~, start_index] = min(abs(1e6*(app.velocity_transform.T+app.velocity_props.start_time) - app.OffsetSampleStartTimeField.Value));
                [~, end_index]   = min(abs(1e6*(app.velocity_transform.T+app.velocity_props.start_time) - app.OffsetSampleEndTimeField.Value));
                
                % Setting 'Zero' Velocity Field Value to the mean of sample region.
                app.ZeroVelocityField.Value = mean(app.output.velocity(start_index:end_index));
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
                app.output.velocity = app.output.velocity - app.ZeroVelocityField.Value;
                
                % Shifting velocity scale
                app.velocity_transform.velocity_scale = app.velocity_transform.velocity_scale-app.ZeroVelocityField.Value;
                
                % Replotting the velocity spectrogram with corrected velocities.
                hold(app.VelocityPlot,'off')
                plot_vel_spectrogram(app,app.VelocityPlot,app.velocity_transform,app.velocity_props,'Velocity Spectrogram')
                hold(app.VelocityPlot,'on')
                plot(app.VelocityPlot,app.output.time*1e6,app.output.velocity,"Color",[0 0.447 0.741])
                OffsetSampleStartTimeFieldValueChanged(app,event)
                OffsetSampleEndTimeFieldValueChanged(app,event)
            catch
                % Incase user has not identified the offset prior to removing it.
                IdentifyOffsetButtonPushed(app,event)
                RemoveOffsetButtonPushed(app,event)
            end
            
            app.ReadyLamp.Color = 'g';
        end

        % Value changed function: BreakoutEndTimeField
        function BreakoutEndTimeFieldValueChanged(app, event)
            % Try to delete any existing line
            try
                delete(app.crop_transform.breakout_end_line)
            catch 
            end
            
            hold(app.CropPlot,'on')
            
            % Try to plot onto CropPlot
            try
                app.crop_transform.breakout_end_line = plot(app.CropPlot,([app.BreakoutEndTimeField.Value,app.BreakoutEndTimeField.Value]),([min(app.crop_transform.F) max(app.crop_transform.F)]*1e-9),'Color','k');
            catch
            end  
        end

        % Value changed function: BreakoutStartTimeField
        function BreakoutStartTimeFieldValueChanged(app, event)
            % Try to delete any existing line
            try
                delete(app.crop_transform.breakout_start_line)
            catch 
            end
            
            hold(app.CropPlot,'on')
            
            % Try to plot onto CropPlot
            try
                app.crop_transform.breakout_start_line = plot(app.CropPlot,([app.BreakoutStartTimeField.Value,app.BreakoutStartTimeField.Value]),([min(app.crop_transform.F) max(app.crop_transform.F)]*1e-9),'Color','k');    
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
            app.processed_props = app.crop_props;
            
            % Changing the end time and index to select only the pre impact (breakout) region.
            app.processed_props.end_time        = app.BreakoutStartTimeField.Value * 1e-6;
            [~, app.processed_props.end_index]  = min(abs(app.data.t - app.processed_props.end_time));
            app.processed_props.end_time        = app.data.t(app.processed_props.end_index);
            
            % Changing the window length to that of the entire length of the signal.
            app.processed_props.window_size = app.processed_props.end_index - app.processed_props.start_index;
            
            % FFT of the entire signal in one window
            app.processed_transform = compute_spectrogram(app,app.data,app.processed_props);
            
            % Taking an initial guess at the baseline frequency
            f0_init_guess = app.processed_transform.F(app.processed_transform.P == max(app.processed_transform.P));
            f0_init_guess_width = 20e6; % 20 Mhz either side of init f0 guess
            
            % Setting up a far narrower frequency range
            app.processed_props.start_freq = f0_init_guess - f0_init_guess_width;
            app.processed_props.end_freq   = f0_init_guess + f0_init_guess_width;
            app.processed_props.nfft       = numel(app.processed_props.start_freq:10:app.processed_props.end_freq);
            
            % Computing the transform in that narrow range with far greater resolution.
            app.processed_transform = compute_spectrogram(app,app.data,app.processed_props);
            clearvars f0_init_guess f0_init_guess_width
            
            app.data.f0 = app.processed_transform.F(app.processed_transform.P == max(app.processed_transform.P));
            clearvars freq_range
            
            % Setting Baseline frequency field with correct value
            app.BaselineFrequencyField.Value = app.data.f0/1e9;
            drawnow
            
            % Resetting processed transform porperties
            app.processed_props = app.crop_props;
            
            % Changing start time to the post breakout line
            app.processed_props.start_time          = app.BreakoutEndTimeField.Value / 1e6;
            [~, app.processed_props.start_index]    = min(abs(app.data.t - app.processed_props.start_time));
            app.processed_props.start_time          = app.data.t(app.processed_props.start_index);
            
            try
                % Try to move the end time to a time the width of the breakout region beyond the start time.
                app.processed_props.end_time            = (2*app.processed_props.start_time) - app.BreakoutStartTimeField.Value/1e6;
                [~, app.processed_props.end_index]      = min(abs(app.data.t - app.processed_props.end_time));
                app.processed_props.end_time            = app.data.t(app.processed_props.end_index);
            catch
                % If this is not possible (ie beyond end of signal) use the crop end time.
                app.processed_props.end_time            = app.crop_props.end_time;
                app.processed_props.end_index           = app.crop_props.end_index;
            end
            
            %Creating functions for minimisation.
            function power = remove_baseline_float_on(app,A)
                % Creating terms to match Dolan paper
                measured = app.data.v(app.processed_props.start_index:app.processed_props.end_index);
                term_1 = A(1)*cos(2*pi*A(3)       *app.data.t(app.processed_props.start_index:app.processed_props.end_index));
                term_2 = A(2)*sin(2*pi*A(3)       *app.data.t(app.processed_props.start_index:app.processed_props.end_index));
                
                % Recreating signal
                signal = measured - term_1 - term_2;
                
                % Measuring power in baseline (50MHz width)
                power_bas = bandpower(signal,app.data.fs,[app.data.f0-2.5e7 app.data.f0+2.5e7]); 
                
                % Measuring power in spectrogram region
                power_tot = bandpower(signal,app.data.fs,[app.processed_props.start_freq app.processed_props.end_freq]);
                
                % Returning the fraction of the power in the spectrogram attributed to the baseline.
                power = power_bas/power_tot;
            end
            function power = remove_baseline_float_off(app,A)
                    % Creating terms to match Dolan paper
                    measured    = app.data.v(app.processed_props.start_index:app.processed_props.end_index);
                    term_1      = A(1)*cos(2*pi*app.data.f0*app.data.t(app.processed_props.start_index:app.processed_props.end_index));
                    term_2      = A(2)*sin(2*pi*app.data.f0*app.data.t(app.processed_props.start_index:app.processed_props.end_index));
                    
                    % Recreating signal
                    signal = measured - term_1 - term_2;
                    
                    power = bandpower(signal,app.data.fs,[app.data.f0-2.5e7 app.data.f0+2.5e7]);
                    power_tot = bandpower(signal,app.data.fs,[app.processed_props.start_freq app.processed_props.end_freq]);
                    power = power/power_tot;
            end
            
            % Minimising with either floating or fixed baseline
            if strcmp(app.FloatingBaselineToggle.Value,'On') % Floating baseline on
                % Minimising fractional baseline power to give A(1), A(2) and A(3).
                [A,~] = fminsearch(@(A)remove_baseline_float_on(app,A),[0,0,app.data.f0],optimset('MaxFunEvals',10000,'MaxIter',10000));
                
                % Creating inverse baseline signal
                baseline_1 = A(1)*cos(2*pi*A(3)*app.data.t);
                baseline_2 = A(2)*sin(2*pi*A(3)*app.data.t);
            else % Floating baseline off.
                % Minimising fractional baseline power to give A(1), A(2) and A(3).
                [A,~] = fminsearch(@(A)remove_baseline_float_off(app,A),[0,0],optimset('MaxFunEvals',10000,'MaxIter',10000));
                
                % Creating inverse baseline signal
                baseline_1 = A(1) * cos(2*pi *app.data.f0*app.data.t);
                baseline_2 = A(2) * sin(2*pi *app.data.f0*app.data.t);
            end
            % Recreating signal with baseline removed
                app.data.v_baseline_removed = app.data.v - baseline_1 - baseline_2;
            
            % Resetting spectrogram porperties to match the crop transform
            app.processed_props = app.crop_props;
            
            % Computing processed spectrogram
            app.processed_transform = compute_spectrogram_baseline_removed(app,app.data,app.processed_props);
            
            % Plotting baseline removed spectrogram
            plot_freq_spectrogram(app,app.ProcessedPlot,app.processed_transform,app.processed_props,'Processed Spectrogram')
            
            app.ReadyLamp.Color = 'g';
        end

        % Value changed function: StartTimeField
        function StartTimeFieldValueChanged(app, event)

            try
                delete(app.raw_transform.start_time_line)
            catch 
            end
            
            hold(app.RawPlot,'on')
            
            % Try to plot onto RawPlot
            try
                app.raw_transform.start_time_line = plot(app.RawPlot,([app.StartTimeField.Value,app.StartTimeField.Value]),([min(app.raw_transform.F) max(app.raw_transform.F)]*1e-9),'Color','k');
                app.crop_props.start_time = app.StartTimeField.Value * 1e-6;
            catch
            end
        end

        % Value changed function: EndTimeField
        function EndTimeFieldValueChanged(app, event)
            
            try
                delete(app.raw_transform.end_time_line)
            catch 
            end
            
            hold(app.RawPlot,'on')
            
            % Try to plot onto RawPlot
            try
                app.raw_transform.end_time_line = plot(app.RawPlot,([app.EndTimeField.Value,app.EndTimeField.Value]),([min(app.raw_transform.F) max(app.raw_transform.F)]*1e-9),'Color','k');
                app.crop_props.end_time = app.endTimeField.Value * 1e-6;
            catch
            end
        end

        % Value changed function: MinFrequencyField
        function MinFrequencyFieldValueChanged(app, event)
            try
                delete(app.raw_transform.min_freq_line)
            catch 
            end
            
            hold(app.RawPlot,'on')
            
            % Try to plot onto RawPlot
            try
                app.raw_transform.min_freq_line = plot(app.RawPlot,([min(app.raw_transform.T)+app.raw_props.start_time max(app.raw_transform.T)+app.raw_props.start_time]*1e6),([app.MinFrequencyField.Value,app.MinFrequencyField.Value]),'Color','k');
                app.crop_props.min_freq = app.MinFrequencyField * 1e9;
            catch
            end
        end

        % Value changed function: MaxFrequencyField
        function MaxFrequencyFieldValueChanged(app, event)
            try
                delete(app.raw_transform.max_freq_line)
            catch 
            end
            
            hold(app.RawPlot,'on')
            
            % Try to plot onto RawPlot
            try
                app.raw_transform.max_freq_line = plot(app.RawPlot,([min(app.raw_transform.T)+app.raw_props.start_time max(app.raw_transform.T)+app.raw_props.start_time]*1e6),([app.MaxFrequencyField.Value,app.MaxFrequencyField.Value]),'Color','k');
                app.crop_props.max_freq = app.MaxFrequencyField.Value * 1e9;
            catch
            end
        end

        % Value changed function: OffsetSampleStartTimeField
        function OffsetSampleStartTimeFieldValueChanged(app, event)
            try
                delete(app.velocity_transform.start_time_line)
            catch 
            end
            
            hold(app.VelocityPlot,'on')
            
            % Try to plot onto VelocityPlot
            try
                app.velocity_transform.start_time_line = plot(app.VelocityPlot,([app.OffsetSampleStartTimeField.Value,app.OffsetSampleStartTimeField.Value]),([min(app.velocity_transform.velocity_scale) max(app.velocity_transform.velocity_scale)]),'Color','k');
            catch
            end
        end

        % Value changed function: OffsetSampleEndTimeField
        function OffsetSampleEndTimeFieldValueChanged(app, event)
            try
                delete(app.velocity_transform.end_time_line)
            catch 
            end
            
            hold(app.VelocityPlot,'on')
            
            % Try to plot onto VelocityPlot
            try
                app.velocity_transform.end_time_line = plot(app.VelocityPlot,([app.OffsetSampleEndTimeField.Value,app.OffsetSampleEndTimeField.Value]),([min(app.velocity_transform.velocity_scale) max(app.velocity_transform.velocity_scale)]),'Color','k');
            catch
            end
        end

        % Value changed function: BaselineCorrectionToggle
        function BaselineCorrectionToggleValueChanged(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Need to write this, currently doesnt do anything.
            if strcmp(app.BaselineCorrectionToggle.Value,'Off')
                % Pulling the crop transford and props through to the processed transform and props.
                app.processed_transform = app.crop_transform;
                app.processed_props    = app.crop_props;
                    
                % Plotting processed spectrogram (has no baseline removal at the moment)
                plot_freq_spectrogram(app,app.ProcessedPlot,app.processed_transform,app.processed_props,'Processed Spectrogram')
            end
            
            app.ReadyLamp.Color = 'g';
            drawnow
        end

        % Button pushed function: ImportTraceButton
        function ImportTraceButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            %Importing scope file
            app.figure1.Visible = 'off';
            waveform = ImportScope(app);
            app.figure1.Visible = 'on';
            
            % Moving data into correct lcoations
            app.data.t = waveform.time;
            app.data.v = waveform.voltage;
            
            % Setting properties for raw spectrogram
            app.data.fs = 1/abs(app.data.t(2) - app.data.t(1));
            
            % Computing the raw spectrogram
            app = compute_raw_spectrogram(app);
            
            % Loading properties from the gui to the structs
            app = raw_props_gui_to_struct(app);
            app = crop_props_gui_to_struct(app);
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: SaveParametersButton
        function SaveParametersButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Pulling properties to app
            app = raw_props_struct_to_gui(app);
            app = crop_props_gui_to_struct(app);
            
            fields = {  'SessionID',...
                        'raw_props',...
                        'crop_props',...
                        'processed_props',...
                        'velocity_props',...
                        'Value_WavelengthField',....
                        'Value_BaselineCorrectionToggle',...
                        'Value_FloatingBaselineToggle',...
                        'Value_BreakoutStartTimeField',...
                        'Value_BreakoutEndTimeField',...
                        'Value_BaselineFrequencyField',...
                        'Value_OffsetSampleStartTimeField',...
                        'Value_OffsetSampleEndTimeField',...
                        'Value_ZeroVelocityField'};
            
             
            for i = 1:length(fields)
                field = fields{i};
                if length(field)>6
                    if strcmp(field(1:6),'Value_')
                        parameters.(field) = app.(field(7:end)).Value;
                    else
                        try parameters.(field) = app.(field);
                        catch
                        end
                    end
                else
                    try parameters.(field) = app.(field);
                    catch
                    end
                end
            end
            
            app.figure1.Visible = 'off';
            uisave('parameters',['PDVTOOL_session_',replace(num2str(parameters.SessionID),'.',''),'_parameters.mat']) %#ok
            app.figure1.Visible = 'on';
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: SaveFigureButton
        function SaveFigureButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            % Creating pop-out figure
            popoutfig  = figure();
            popoutax   = axes(popoutfig);
            
            if strcmp(app.DropDown.Value,'Raw')
                try
                    hold(popoutax,'off')
                    plot_freq_spectrogram(app,popoutax,app.raw_transform,app.raw_props,'Raw Spectrogram')
                    hold(popoutax,'on')
                    set(gca,'DefaultAxesFontName', 'Helvetica')
                    set(gca,'DefaultAxesFontSize', 12)
                    set(gca,'DefaultTextInterpreter', 'none')
                    set(gca,'DefaultTextFontUnits','Point')
                    set(gca,'DefaultTextFontSize', 12)
                    savefig(popoutfig,'Raw_Spectrogram.fig')
                    pause(3)
                catch
                end 
            elseif strcmp(app.DropDown.Value,'Cropped')
                try
                    hold(popoutax,'off')
                    plot_freq_spectrogram(app,popoutax,app.crop_transform,app.crop_props,'Cropped Spectrogram')
                    savefig(popoutfig,'Cropped_Spectrogram.fig')
                    pause(3)
                catch
                end 
            elseif strcmp(app.DropDown.Value,'Processed')
                try
                    hold(popoutax,'off')
                    plot_freq_spectrogram(app,popoutax,app.processed_transform,app.processed_props,'Processed Spectrogram')
                    hold(popoutax,'on')
                    try
                        % Plot ROI
                    catch
                    end
                    savefig(popoutfig,'Processed_Spectrogram.fig')
                    pause(3)
                catch
                end 
            elseif strcmp(app.DropDown.Value,'Velocity')
                try
                    hold(popoutax,'off')
                    plot_vel_spectrogram(app,popoutax,app.velocity_transform,app.velocity_props,'Velocity Spectrogram')
                    hold(popoutax,'on')
                    try
                        plot(popoutax,app.output.time*1e6,app.output.velocity,"Color",[0 0.447 0.741])
                    catch
                    end
                    savefig(popoutfig,'Velocity_Spectrogram.fig')
                    pause(3)
                catch
                end 
            end
            close(gcf)
            
            % Jumping back to the UI
            figure(app.figure1)
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: SaveSessionButton
        function SaveSessionButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            app = raw_props_gui_to_struct(app);
            app = crop_props_gui_to_struct(app);
            
            fields = {  'SessionID',...
                        'data',...
                        'raw_props',...
                        'raw_transform',...
                        'crop_props',...
                        'crop_transform',...
                        'processed_props',...
                        'processed_transform',...
                        'velocity_props',...
                        'output',...
                        'Value_WavelengthField',....
                        'Value_BaselineCorrectionToggle',...
                        'Value_FloatingBaselineToggle',...
                        'Value_BreakoutStartTimeField',...
                        'Value_BreakoutEndTimeField',...
                        'Value_BaselineFrequencyField',...
                        'Value_OffsetSampleStartTimeField',...
                        'Value_OffsetSampleEndTimeField',...
                        'Value_ZeroVelocityField'};
                    
            for i = 1:length(fields)
                field = fields{i};
                if length(field)>6
                    if strcmp(field(1:6),'Value_')
                        session.(field) = app.(field(7:end)).Value;
                    else
                        try session.(field) = app.(field);
                        catch
                        end
                    end
                else
                    try session.(field) = app.(field);
                    catch
                    end
                end
            end
            
            app.figure1.Visible = 'off';
            uisave('session',['PDVTOOL_session_',replace(num2str(session.SessionID),'.',''),'.mat']) %#ok
            app.figure1.Visible = 'on';
                
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ImportSessionButton
        function ImportSessionButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            %% Getting file
            app.figure1.Visible = 'off';
            [filename,pathname] = uigetfile('*');
            imported_data = load([pathname,filename]);
            imported_data = imported_data.session;
            app.figure1.Visible = 'on';
            
            
            fields = {  'SessionID',...
                        'data',...
                        'raw_props',...
                        'raw_transform',...
                        'crop_props',...
                        'crop_transform',...
                        'processed_props',...
                        'processed_transform',...
                        'velocity_props',...
                        'output',...
                        'Value_WavelengthField',....
                        'Value_BaselineCorrectionToggle',...
                        'Value_FloatingBaselineToggle',...
                        'Value_BreakoutStartTimeField',...
                        'Value_BreakoutEndTimeField',...
                        'Value_BaselineFrequencyField',...
                        'Value_OffsetSampleStartTimeField',...
                        'Value_OffsetSampleEndTimeField',...
                        'Value_ZeroVelocityField'};
                    
            for i = 1:length(fields)
                field = fields{i};
                if isfield(imported_data,field)
                    if length(field)>6
                        if strcmp(field(1:6),'Value_')
                            app.(field(7:end)).Value = imported_data.(field);
                        else
                            app.(field) = imported_data.(field);
                        end
                    else
                        app.(field) = imported_data.(field);
                    end
                end
            end
            
            % clearing the imported data
            clearvars imported_data
            
            % Passing raw & crops props back into the gui
            raw_props_struct_to_gui(app);
            crop_props_struct_to_gui(app);
            
            
            % If there was a file in the session then plot the raw
            % transfrom
            if ~isempty(app.raw_transform)
                plot_freq_spectrogram(app,app.RawPlot,app.raw_transform,app.raw_props,'Rough Spectrogram')
                StartTimeFieldValueChanged(app,event)
                EndTimeFieldValueChanged(app,event)
                MinFrequencyFieldValueChanged(app,event)
                MaxFrequencyFieldValueChanged(app,event)
            end
            
            % If a cropped transform was made then plot it
            if ~isempty(app.crop_transform)
                plot_freq_spectrogram(app,app.CropPlot,app.crop_transform,app.crop_props,'Cropped Spectrogram')
                if strcmp(app.BaselineCorrectionToggle.Value,'On')
                    BreakoutStartTimeFieldValueChanged(app,event)
                    BreakoutEndTimeFieldValueChanged(app,event)
                end
            end
            
            % If a processed transform was made then plot it
            if ~isempty(app.processed_transform)
                plot_freq_spectrogram(app,app.ProcessedPlot,app.processed_transform,app.processed_props,'Processed Spectrogram')
                if isfield(app.processed_transform,'roiplot')
                    hold(app.ProcessedPlot,'on');
                    app.processed_transform = rmfield(app.processed_transform,'roiplot');
                    app.processed_transform.roiplot = plot(app.ProcessedPlot,app.processed_transform.roi_x,app.processed_transform.roi_y,'k');
                end
                
            end
            
            % If a velocity transform was made then plot it
            if ~isempty(app.velocity_transform)
                plot_vel_spectrogram(app,app.VelocityPlot,app.velocity_transform,app.velocity_props,'Processed Spectrogram')
                if ~isempty(app.output)
                    hold(app.VelocityPlot,'on')
                    app.velocity_transform.extracted_velocity_line = plot(app.VelocityPlot,app.output.time*1e6,app.output.velocity,'Color',[0 0.447 0.741]);
                end
                if isfield(app.velocity_transform,'start_time_line')
                    OffsetSampleStartTimeFieldValueChanged(app,event)
                end
                if isfield(app.velocity_transform,'end_time_line')
                    OffsetSampleEndTimeFieldValueChanged(app,event)
                end
            end
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ImportParametersButton
        function ImportParametersButtonPushed(app, event)
            app.ReadyLamp.Color = 'r';
            drawnow
            
            DataExists = isfield(app,'data');
            
            %% Getting file
            app.figure1.Visible = 'off';
            [filename,pathname] = uigetfile('*');
            imported_data = load([pathname,filename]);
            imported_data = imported_data.parameters;
            app.figure1.Visible = 'on';
            
            fields = {  'raw_props',...
                        'crop_props',...
                        'processed_props',...
                        'velocity_props',...
                        'Value_WavelengthField',....
                        'Value_BaselineCorrectionToggle',...
                        'Value_FloatingBaselineToggle',...
                        'Value_BreakoutStartTimeField',...
                        'Value_BreakoutEndTimeField',...
                        'Value_BaselineFrequencyField',...
                        'Value_OffsetSampleStartTimeField',...
                        'Value_OffsetSampleEndTimeField',...
                        'Value_ZeroVelocityField'};
            
             
            for i = 1:length(fields)
                field = fields{i};
                if isfield(imported_data,field)
                    if length(field)>6
                        if strcmp(field(1:6),'Value_')
                            app.(field(7:end)).Value = imported_data.(field);
                        else
                            app.(field) = imported_data.(field);
                        end
                    else
                        app.(field) = imported_data.(field);
                    end
                end
            end
            
            
            
            if DataExists
                raw_props_struct_to_gui(app)
                ReprocessRawButtonButtonPushed(app)
            end
            
            if ~isempty(app.crop_props)
                crop_props_struct_to_gui(app);
                
            end
            
            app.ReadyLamp.Color = 'g';
        end

        % Button pushed function: ImportH5DatasetButton
        function ImportH5DatasetButtonPushed(app, event)
            app.HDBPullChild = H5DBPull(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create figure1 and hide until all components are created
            app.figure1 = uifigure('Visible', 'off');
            app.figure1.Position = [5 5 1140 640];
            app.figure1.Name = 'PDV_TOOL';
            app.figure1.Scrollable = 'on';

            % Create RawPlot
            app.RawPlot = uiaxes(app.figure1);
            title(app.RawPlot, '')
            xlabel(app.RawPlot, '')
            ylabel(app.RawPlot, '')
            app.RawPlot.PlotBoxAspectRatio = [1.01917808219178 1 1];
            app.RawPlot.FontSize = 10;
            app.RawPlot.TickLabelInterpreter = 'none';
            app.RawPlot.NextPlot = 'replace';
            app.RawPlot.Position = [251 321 310 310];

            % Create CropPlot
            app.CropPlot = uiaxes(app.figure1);
            title(app.CropPlot, '')
            xlabel(app.CropPlot, '')
            ylabel(app.CropPlot, '')
            app.CropPlot.PlotBoxAspectRatio = [1.02191780821918 1 1];
            app.CropPlot.FontSize = 10;
            app.CropPlot.TickLabelInterpreter = 'none';
            app.CropPlot.YAxisLocation = 'right';
            app.CropPlot.NextPlot = 'replace';
            app.CropPlot.Position = [561 321 310 310];

            % Create ProcessedPlot
            app.ProcessedPlot = uiaxes(app.figure1);
            title(app.ProcessedPlot, '')
            xlabel(app.ProcessedPlot, '')
            ylabel(app.ProcessedPlot, '')
            app.ProcessedPlot.PlotBoxAspectRatio = [1.02191780821918 1 1];
            app.ProcessedPlot.FontSize = 10;
            app.ProcessedPlot.TickLabelInterpreter = 'none';
            app.ProcessedPlot.NextPlot = 'replace';
            app.ProcessedPlot.Position = [251 11 310 310];

            % Create VelocityPlot
            app.VelocityPlot = uiaxes(app.figure1);
            title(app.VelocityPlot, '')
            xlabel(app.VelocityPlot, '')
            ylabel(app.VelocityPlot, '')
            app.VelocityPlot.PlotBoxAspectRatio = [1.02191780821918 1 1];
            app.VelocityPlot.FontSize = 10;
            app.VelocityPlot.TickLabelInterpreter = 'none';
            app.VelocityPlot.YAxisLocation = 'right';
            app.VelocityPlot.NextPlot = 'replace';
            app.VelocityPlot.Position = [561 11 310 310];

            % Create CropSpectrogramButton
            app.CropSpectrogramButton = uibutton(app.figure1, 'push');
            app.CropSpectrogramButton.ButtonPushedFcn = createCallbackFcn(app, @CropSpectrogramButtonPushed, true);
            app.CropSpectrogramButton.FontSize = 10;
            app.CropSpectrogramButton.Position = [101 131 140 20];
            app.CropSpectrogramButton.Text = 'Crop Spectrogram';

            % Create ProcessBaselineButton
            app.ProcessBaselineButton = uibutton(app.figure1, 'push');
            app.ProcessBaselineButton.ButtonPushedFcn = createCallbackFcn(app, @ProcessBaselineButtonPushed, true);
            app.ProcessBaselineButton.FontSize = 10;
            app.ProcessBaselineButton.Position = [881 521 140 20];
            app.ProcessBaselineButton.Text = 'Process';

            % Create SetROIButton
            app.SetROIButton = uibutton(app.figure1, 'push');
            app.SetROIButton.ButtonPushedFcn = createCallbackFcn(app, @SetROIButtonButtonPushed, true);
            app.SetROIButton.FontSize = 10;
            app.SetROIButton.Position = [101 71 140 20];
            app.SetROIButton.Text = 'Set ROI';

            % Create ConfirmRoiButton
            app.ConfirmRoiButton = uibutton(app.figure1, 'push');
            app.ConfirmRoiButton.ButtonPushedFcn = createCallbackFcn(app, @ConfirmRoiButtonButtonPushed, true);
            app.ConfirmRoiButton.FontSize = 10;
            app.ConfirmRoiButton.Position = [101 11 140 20];
            app.ConfirmRoiButton.Text = 'Confirm ROI';

            % Create ShiftSwitchButton
            app.ShiftSwitchButton = uibutton(app.figure1, 'push');
            app.ShiftSwitchButton.ButtonPushedFcn = createCallbackFcn(app, @ShiftSwitchButtonButtonPushed, true);
            app.ShiftSwitchButton.FontSize = 10;
            app.ShiftSwitchButton.Position = [881 311 140 20];
            app.ShiftSwitchButton.Text = 'Upshift/Downshift';

            % Create ExtractVelocitiesButton
            app.ExtractVelocitiesButton = uibutton(app.figure1, 'push');
            app.ExtractVelocitiesButton.ButtonPushedFcn = createCallbackFcn(app, @ExtractVelocitiesButtonButtonPushed, true);
            app.ExtractVelocitiesButton.FontSize = 10;
            app.ExtractVelocitiesButton.Position = [881 281 140 20];
            app.ExtractVelocitiesButton.Text = 'Extract Velocities';

            % Create SaveVelocitiesButton
            app.SaveVelocitiesButton = uibutton(app.figure1, 'push');
            app.SaveVelocitiesButton.ButtonPushedFcn = createCallbackFcn(app, @SaveVelocitiesButtonButtonPushed, true);
            app.SaveVelocitiesButton.FontSize = 10;
            app.SaveVelocitiesButton.Position = [881 101 140 20];
            app.SaveVelocitiesButton.Text = 'Save Velocities';

            % Create ResetROIButton
            app.ResetROIButton = uibutton(app.figure1, 'push');
            app.ResetROIButton.ButtonPushedFcn = createCallbackFcn(app, @ResetROIButtonButtonPushed, true);
            app.ResetROIButton.FontSize = 10;
            app.ResetROIButton.Position = [101 41 140 20];
            app.ResetROIButton.Text = 'Reset ROI';

            % Create BaselineCorrectionToggle
            app.BaselineCorrectionToggle = uiswitch(app.figure1, 'slider');
            app.BaselineCorrectionToggle.ValueChangedFcn = createCallbackFcn(app, @BaselineCorrectionToggleValueChanged, true);
            app.BaselineCorrectionToggle.FontSize = 10;
            app.BaselineCorrectionToggle.Position = [909 611 45 20];

            % Create ReprocessRawButton
            app.ReprocessRawButton = uibutton(app.figure1, 'push');
            app.ReprocessRawButton.ButtonPushedFcn = createCallbackFcn(app, @ReprocessRawButtonButtonPushed, true);
            app.ReprocessRawButton.FontSize = 10;
            app.ReprocessRawButton.Position = [101 371 140 20];
            app.ReprocessRawButton.Text = 'Reprocess Raw';

            % Create ReadyLampLabel
            app.ReadyLampLabel = uilabel(app.figure1);
            app.ReadyLampLabel.HorizontalAlignment = 'right';
            app.ReadyLampLabel.FontSize = 10;
            app.ReadyLampLabel.Position = [11 611 120 20];
            app.ReadyLampLabel.Text = 'Ready';

            % Create ReadyLamp
            app.ReadyLamp = uilamp(app.figure1);
            app.ReadyLamp.Position = [221 611 20 20];

            % Create RecalculateVelocitiesButton
            app.RecalculateVelocitiesButton = uibutton(app.figure1, 'push');
            app.RecalculateVelocitiesButton.ButtonPushedFcn = createCallbackFcn(app, @RecalculateVelocitiesButtonPushed, true);
            app.RecalculateVelocitiesButton.FontSize = 10;
            app.RecalculateVelocitiesButton.Position = [881 341 140 20];
            app.RecalculateVelocitiesButton.Text = 'Recalculate Velocities';

            % Create IdentifyOffsetButton
            app.IdentifyOffsetButton = uibutton(app.figure1, 'push');
            app.IdentifyOffsetButton.ButtonPushedFcn = createCallbackFcn(app, @IdentifyOffsetButtonPushed, true);
            app.IdentifyOffsetButton.FontSize = 10;
            app.IdentifyOffsetButton.Position = [881 191 140 20];
            app.IdentifyOffsetButton.Text = 'Identify Offset';

            % Create RemoveOffsetButton
            app.RemoveOffsetButton = uibutton(app.figure1, 'push');
            app.RemoveOffsetButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveOffsetButtonPushed, true);
            app.RemoveOffsetButton.FontSize = 10;
            app.RemoveOffsetButton.Position = [881 131 140 20];
            app.RemoveOffsetButton.Text = 'Remove Offset';

            % Create RawNfftPtsEditFieldLabel
            app.RawNfftPtsEditFieldLabel = uilabel(app.figure1);
            app.RawNfftPtsEditFieldLabel.HorizontalAlignment = 'right';
            app.RawNfftPtsEditFieldLabel.FontSize = 10;
            app.RawNfftPtsEditFieldLabel.Position = [11 461 120 20];
            app.RawNfftPtsEditFieldLabel.Text = 'Raw Nfft (Pts)';

            % Create RawNfftField
            app.RawNfftField = uieditfield(app.figure1, 'numeric');
            app.RawNfftField.FontSize = 10;
            app.RawNfftField.Position = [141 461 100 20];
            app.RawNfftField.Value = 512;

            % Create RawWindowSizePtsEditFieldLabel
            app.RawWindowSizePtsEditFieldLabel = uilabel(app.figure1);
            app.RawWindowSizePtsEditFieldLabel.HorizontalAlignment = 'right';
            app.RawWindowSizePtsEditFieldLabel.FontSize = 10;
            app.RawWindowSizePtsEditFieldLabel.Position = [11 431 120 20];
            app.RawWindowSizePtsEditFieldLabel.Text = 'Raw Window Size (Pts)';

            % Create RawWindowSizeField
            app.RawWindowSizeField = uieditfield(app.figure1, 'numeric');
            app.RawWindowSizeField.FontSize = 10;
            app.RawWindowSizeField.Position = [141 431 100 20];
            app.RawWindowSizeField.Value = 8192;

            % Create StartTimesEditFieldLabel_2
            app.StartTimesEditFieldLabel_2 = uilabel(app.figure1);
            app.StartTimesEditFieldLabel_2.HorizontalAlignment = 'right';
            app.StartTimesEditFieldLabel_2.FontSize = 10;
            app.StartTimesEditFieldLabel_2.Position = [11 341 120 20];
            app.StartTimesEditFieldLabel_2.Text = 'Start Time (탎)';

            % Create StartTimeField
            app.StartTimeField = uieditfield(app.figure1, 'numeric');
            app.StartTimeField.ValueChangedFcn = createCallbackFcn(app, @StartTimeFieldValueChanged, true);
            app.StartTimeField.FontSize = 10;
            app.StartTimeField.Position = [141 341 100 20];

            % Create EndTimesEditFieldLabel_2
            app.EndTimesEditFieldLabel_2 = uilabel(app.figure1);
            app.EndTimesEditFieldLabel_2.HorizontalAlignment = 'right';
            app.EndTimesEditFieldLabel_2.FontSize = 10;
            app.EndTimesEditFieldLabel_2.Position = [11 311 120 20];
            app.EndTimesEditFieldLabel_2.Text = 'End Time (탎)';

            % Create EndTimeField
            app.EndTimeField = uieditfield(app.figure1, 'numeric');
            app.EndTimeField.ValueChangedFcn = createCallbackFcn(app, @EndTimeFieldValueChanged, true);
            app.EndTimeField.FontSize = 10;
            app.EndTimeField.Position = [141 311 100 20];

            % Create MinFrequencyGHzEditFieldLabel_2
            app.MinFrequencyGHzEditFieldLabel_2 = uilabel(app.figure1);
            app.MinFrequencyGHzEditFieldLabel_2.HorizontalAlignment = 'right';
            app.MinFrequencyGHzEditFieldLabel_2.FontSize = 10;
            app.MinFrequencyGHzEditFieldLabel_2.Position = [11 281 120 20];
            app.MinFrequencyGHzEditFieldLabel_2.Text = 'Min Frequency (GHz)';

            % Create MinFrequencyField
            app.MinFrequencyField = uieditfield(app.figure1, 'numeric');
            app.MinFrequencyField.ValueChangedFcn = createCallbackFcn(app, @MinFrequencyFieldValueChanged, true);
            app.MinFrequencyField.FontSize = 10;
            app.MinFrequencyField.Position = [141 281 100 20];

            % Create MaxFrequencyGHzEditFieldLabel
            app.MaxFrequencyGHzEditFieldLabel = uilabel(app.figure1);
            app.MaxFrequencyGHzEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxFrequencyGHzEditFieldLabel.FontSize = 10;
            app.MaxFrequencyGHzEditFieldLabel.Position = [11 251 120 20];
            app.MaxFrequencyGHzEditFieldLabel.Text = 'Max Frequency (GHz)';

            % Create MaxFrequencyField
            app.MaxFrequencyField = uieditfield(app.figure1, 'numeric');
            app.MaxFrequencyField.ValueChangedFcn = createCallbackFcn(app, @MaxFrequencyFieldValueChanged, true);
            app.MaxFrequencyField.FontSize = 10;
            app.MaxFrequencyField.Position = [141 251 100 20];

            % Create CropNfftPtsEditFieldLabel_2
            app.CropNfftPtsEditFieldLabel_2 = uilabel(app.figure1);
            app.CropNfftPtsEditFieldLabel_2.HorizontalAlignment = 'right';
            app.CropNfftPtsEditFieldLabel_2.FontSize = 10;
            app.CropNfftPtsEditFieldLabel_2.Position = [11 221 120 20];
            app.CropNfftPtsEditFieldLabel_2.Text = 'Crop Nfft (Pts)';

            % Create CropNfftField
            app.CropNfftField = uieditfield(app.figure1, 'numeric');
            app.CropNfftField.FontSize = 10;
            app.CropNfftField.Position = [141 221 100 20];
            app.CropNfftField.Value = 1024;

            % Create CropWindowSizePtsEditFieldLabel
            app.CropWindowSizePtsEditFieldLabel = uilabel(app.figure1);
            app.CropWindowSizePtsEditFieldLabel.HorizontalAlignment = 'right';
            app.CropWindowSizePtsEditFieldLabel.FontSize = 10;
            app.CropWindowSizePtsEditFieldLabel.Position = [11 191 120 20];
            app.CropWindowSizePtsEditFieldLabel.Text = 'Crop Window Size (Pts)';

            % Create CropWindowSizeField
            app.CropWindowSizeField = uieditfield(app.figure1, 'numeric');
            app.CropWindowSizeField.FontSize = 10;
            app.CropWindowSizeField.Position = [141 191 100 20];
            app.CropWindowSizeField.Value = 512;

            % Create CropOverlapPtsLabel
            app.CropOverlapPtsLabel = uilabel(app.figure1);
            app.CropOverlapPtsLabel.HorizontalAlignment = 'right';
            app.CropOverlapPtsLabel.FontSize = 10;
            app.CropOverlapPtsLabel.Position = [11 161 120 20];
            app.CropOverlapPtsLabel.Text = 'Crop Overlap (Pts)';

            % Create CropOverlapField
            app.CropOverlapField = uieditfield(app.figure1, 'numeric');
            app.CropOverlapField.FontSize = 10;
            app.CropOverlapField.Position = [141 161 100 20];

            % Create BreakoutStartTimesEditFieldLabel
            app.BreakoutStartTimesEditFieldLabel = uilabel(app.figure1);
            app.BreakoutStartTimesEditFieldLabel.HorizontalAlignment = 'right';
            app.BreakoutStartTimesEditFieldLabel.FontSize = 10;
            app.BreakoutStartTimesEditFieldLabel.Position = [991 581 140 20];
            app.BreakoutStartTimesEditFieldLabel.Text = 'Breakout Start Time (탎)';

            % Create BreakoutStartTimeField
            app.BreakoutStartTimeField = uieditfield(app.figure1, 'numeric');
            app.BreakoutStartTimeField.ValueChangedFcn = createCallbackFcn(app, @BreakoutStartTimeFieldValueChanged, true);
            app.BreakoutStartTimeField.FontSize = 10;
            app.BreakoutStartTimeField.Position = [881 581 100 20];

            % Create BreakoutEndTimesEditFieldLabel
            app.BreakoutEndTimesEditFieldLabel = uilabel(app.figure1);
            app.BreakoutEndTimesEditFieldLabel.HorizontalAlignment = 'right';
            app.BreakoutEndTimesEditFieldLabel.FontSize = 10;
            app.BreakoutEndTimesEditFieldLabel.Position = [991 551 140 20];
            app.BreakoutEndTimesEditFieldLabel.Text = 'Breakout End Time (탎)';

            % Create BreakoutEndTimeField
            app.BreakoutEndTimeField = uieditfield(app.figure1, 'numeric');
            app.BreakoutEndTimeField.ValueChangedFcn = createCallbackFcn(app, @BreakoutEndTimeFieldValueChanged, true);
            app.BreakoutEndTimeField.FontSize = 10;
            app.BreakoutEndTimeField.Position = [881 551 100 20];

            % Create BaselineFrequencyGhzEditFieldLabel
            app.BaselineFrequencyGhzEditFieldLabel = uilabel(app.figure1);
            app.BaselineFrequencyGhzEditFieldLabel.HorizontalAlignment = 'right';
            app.BaselineFrequencyGhzEditFieldLabel.FontSize = 10;
            app.BaselineFrequencyGhzEditFieldLabel.Position = [991 491 140 20];
            app.BaselineFrequencyGhzEditFieldLabel.Text = 'Baseline Frequency (Ghz)';

            % Create BaselineFrequencyField
            app.BaselineFrequencyField = uieditfield(app.figure1, 'numeric');
            app.BaselineFrequencyField.FontSize = 10;
            app.BaselineFrequencyField.Position = [881 491 100 20];

            % Create RemoveBaselineLabel
            app.RemoveBaselineLabel = uilabel(app.figure1);
            app.RemoveBaselineLabel.FontSize = 10;
            app.RemoveBaselineLabel.Position = [991 611 140 20];
            app.RemoveBaselineLabel.Text = ' Remove Baseline?';

            % Create ProbeLaserWavelengthnmLabel
            app.ProbeLaserWavelengthnmLabel = uilabel(app.figure1);
            app.ProbeLaserWavelengthnmLabel.FontSize = 10;
            app.ProbeLaserWavelengthnmLabel.Position = [991 371 140 20];
            app.ProbeLaserWavelengthnmLabel.Text = 'Probe Laser Wavelength (nm)';

            % Create WavelengthField
            app.WavelengthField = uieditfield(app.figure1, 'numeric');
            app.WavelengthField.Position = [881 371 100 20];
            app.WavelengthField.Value = 1550;

            % Create OffsetSampleStartTimesLabel
            app.OffsetSampleStartTimesLabel = uilabel(app.figure1);
            app.OffsetSampleStartTimesLabel.FontSize = 10;
            app.OffsetSampleStartTimesLabel.Position = [991 250 140 20];
            app.OffsetSampleStartTimesLabel.Text = 'Offset Sample Start Time (탎)';

            % Create OffsetSampleStartTimeField
            app.OffsetSampleStartTimeField = uieditfield(app.figure1, 'numeric');
            app.OffsetSampleStartTimeField.ValueChangedFcn = createCallbackFcn(app, @OffsetSampleStartTimeFieldValueChanged, true);
            app.OffsetSampleStartTimeField.Position = [881 251 100 20];

            % Create OffsetSampleEndTimesLabel
            app.OffsetSampleEndTimesLabel = uilabel(app.figure1);
            app.OffsetSampleEndTimesLabel.FontSize = 10;
            app.OffsetSampleEndTimesLabel.Position = [991 221 140 20];
            app.OffsetSampleEndTimesLabel.Text = 'Offset Sample End Time (탎)';

            % Create OffsetSampleEndTimeField
            app.OffsetSampleEndTimeField = uieditfield(app.figure1, 'numeric');
            app.OffsetSampleEndTimeField.ValueChangedFcn = createCallbackFcn(app, @OffsetSampleEndTimeFieldValueChanged, true);
            app.OffsetSampleEndTimeField.Position = [881 221 100 20];

            % Create ZeroVeloctymsLabel_2
            app.ZeroVeloctymsLabel_2 = uilabel(app.figure1);
            app.ZeroVeloctymsLabel_2.FontSize = 10;
            app.ZeroVeloctymsLabel_2.Position = [991 160 140 20];
            app.ZeroVeloctymsLabel_2.Text = '''Zero'' Velocty (m/s)';

            % Create ZeroVelocityField
            app.ZeroVelocityField = uieditfield(app.figure1, 'numeric');
            app.ZeroVelocityField.Position = [881 161 100 20];

            % Create FloatingBaselineToggle
            app.FloatingBaselineToggle = uiswitch(app.figure1, 'slider');
            app.FloatingBaselineToggle.FontSize = 10;
            app.FloatingBaselineToggle.Position = [910 461 45 20];
            app.FloatingBaselineToggle.Value = 'On';

            % Create FloatingBaselineLabel
            app.FloatingBaselineLabel = uilabel(app.figure1);
            app.FloatingBaselineLabel.FontSize = 10;
            app.FloatingBaselineLabel.Position = [991 461 140 20];
            app.FloatingBaselineLabel.Text = ' Floating Baseline';

            % Create ImportTraceButton
            app.ImportTraceButton = uibutton(app.figure1, 'push');
            app.ImportTraceButton.ButtonPushedFcn = createCallbackFcn(app, @ImportTraceButtonPushed, true);
            app.ImportTraceButton.FontSize = 10;
            app.ImportTraceButton.Position = [101 551 140 20];
            app.ImportTraceButton.Text = 'Import Trace';

            % Create SaveSessionButton
            app.SaveSessionButton = uibutton(app.figure1, 'push');
            app.SaveSessionButton.ButtonPushedFcn = createCallbackFcn(app, @SaveSessionButtonPushed, true);
            app.SaveSessionButton.FontSize = 10;
            app.SaveSessionButton.Position = [881 11 140 20];
            app.SaveSessionButton.Text = 'Save Session';

            % Create SaveParametersButton
            app.SaveParametersButton = uibutton(app.figure1, 'push');
            app.SaveParametersButton.ButtonPushedFcn = createCallbackFcn(app, @SaveParametersButtonPushed, true);
            app.SaveParametersButton.FontSize = 10;
            app.SaveParametersButton.Position = [881 71 140 20];
            app.SaveParametersButton.Text = 'Save Parameters';

            % Create ImportSessionButton
            app.ImportSessionButton = uibutton(app.figure1, 'push');
            app.ImportSessionButton.ButtonPushedFcn = createCallbackFcn(app, @ImportSessionButtonPushed, true);
            app.ImportSessionButton.FontSize = 10;
            app.ImportSessionButton.Position = [101 521 140 20];
            app.ImportSessionButton.Text = 'Import Session';

            % Create SaveFigureButton
            app.SaveFigureButton = uibutton(app.figure1, 'push');
            app.SaveFigureButton.ButtonPushedFcn = createCallbackFcn(app, @SaveFigureButtonPushed, true);
            app.SaveFigureButton.FontSize = 10;
            app.SaveFigureButton.Position = [881 41 140 20];
            app.SaveFigureButton.Text = 'Save Figure';

            % Create DropDown
            app.DropDown = uidropdown(app.figure1);
            app.DropDown.Items = {'Raw', 'Cropped', 'Processed', 'Velocity'};
            app.DropDown.FontSize = 10;
            app.DropDown.Position = [1031 41 100 20];
            app.DropDown.Value = 'Raw';

            % Create ImportParametersButton
            app.ImportParametersButton = uibutton(app.figure1, 'push');
            app.ImportParametersButton.ButtonPushedFcn = createCallbackFcn(app, @ImportParametersButtonPushed, true);
            app.ImportParametersButton.FontSize = 10;
            app.ImportParametersButton.Position = [101 491 140 20];
            app.ImportParametersButton.Text = 'Import Parameters';

            % Create BandwidthGHzLabel
            app.BandwidthGHzLabel = uilabel(app.figure1);
            app.BandwidthGHzLabel.HorizontalAlignment = 'right';
            app.BandwidthGHzLabel.FontSize = 10;
            app.BandwidthGHzLabel.Position = [11 401 120 20];
            app.BandwidthGHzLabel.Text = 'Bandwidth (GHz)';

            % Create BandwidthField
            app.BandwidthField = uieditfield(app.figure1, 'numeric');
            app.BandwidthField.FontSize = 10;
            app.BandwidthField.Position = [141 401 100 20];
            app.BandwidthField.Value = 8;

            % Create ImportH5DatasetButton
            app.ImportH5DatasetButton = uibutton(app.figure1, 'push');
            app.ImportH5DatasetButton.ButtonPushedFcn = createCallbackFcn(app, @ImportH5DatasetButtonPushed, true);
            app.ImportH5DatasetButton.FontSize = 10;
            app.ImportH5DatasetButton.Position = [101 581 140 20];
            app.ImportH5DatasetButton.Text = 'Import H5 Dataset';

            % Show the figure after all components are created
            app.figure1.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PDV_TOOL(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.figure1)

            % Execute the startup function
            runStartupFcn(app, @(app)PDV_TOOLOpeningFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.figure1)
        end
    end
end
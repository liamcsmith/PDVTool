# PdvAnalysis
A tool for analysing photon doppler velocimetry data with MATLAB.
Can be run without inputs by simply running the PdvAnalysis.m function or using the following syntax options

% Importing data from within the app: PdvAnalysis()

% Basic Route of passing inputs: PdvAnalysis('Time',obj_1Darray,'Voltage',obj_1Darray)

% Passing in ScopeTrace output cleanly: PdvAnalysis('Trace',obj_importscopeoutput)

% For identifying what trace you're working on: PdvAnalysis('Title',obj_string)

% Variable will created from previous analysis. Can be used to re enter a previous analysis: PdvAnalysis('Parameters',obj_parametervariable)  		
							  
% Fully programmatic analysis of supplied data with supplied parameters: PdvAnalysis('Automate',obj_logical) 			
							  
If you want to run this within a function please insert the following nested function inside your function or script then see the included examples or speak to me.


# Legacy Tools
**PDV_TOOL_v2020**
A legacy tool for analysing photon doppler velocimetry data with MATLAB.
Can be run without inputs by simply running the PDV_TOOL.m function or using the following syntax
PDV_TOOL(t,v)
Where t & v are timeseries column vectors represtenting time and voltage of the photodiode output.

**PDV_Analysis_Legacy**
The prior version of PDVAnalysis, this one is ~4x slower at extracting velocities (although it arguably has slightly better error calculation on velocity fits). It also has a dependency on ImportScope rather than ScopeTrace (the latter being much faster for alomost every filetype).

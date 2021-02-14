# PdvAnalysis
A tool for analysing photon doppler velocimetry data with MATLAB.
Can be run without inputs by simply running the PdvAnalysis.m function or using the following syntax options
PdvAnalysis('Time',<TimeArray>,'Voltage',<VoltageArray>) 	% Basic Route
PdvAnalysis('Trace',<ImportScopeOutput>)			% Passing in ImportScope output cleanly
PdvAnalysis('Title',<FigureTitle>) 			% For identifying what trace you're
							  working on.
PdvAnalysis('Parameters',<ParametersVariable>)  		% Variable will created from previous 
							  analysis. Can be used to re enter a
							  previous analysis
PdvAnalysis('Automate',<logical>) 			% Fully programmatic analysis of supplied
							  data with supplied parameters.


If you want to run this within a function please insert the following nested function inside your function or script then see the included examples or speak to me.

# PDV_TOOL_v2020
A legacy tool for analysing photon doppler velocimetry data with MATLAB.
Can be run without inputs by simply running the PDV_TOOL.m function or using the following syntax
PDV_TOOL(t,v)
Where t & v are timeseries column vectors represtenting time and voltage of the photodiode output.

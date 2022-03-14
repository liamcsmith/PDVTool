# PDVTrace
## Summary
An object for containing everything about a PDV trace. This object will manage raw data storage (using `ScopeTrace` dependency), analysis via its interface with the bundled PDVAnalysis GUI (including analysis parameter storage, and analysis updating from prior analyses) and cable delay inputs.

## Dependencies
* `ScopeTrace`: You can find this in a different repository on my profile.

## Installation
To have `PDVTrace` work correctly you will need to:
1) Edit the value for the property `ScopeTracePath`. To find this you can use the MATLAB documentation hyperlink or find `%%ScopeTracePath%%` in the `PdvTrace` file.
2) Edit the value for the property `ScopeTracePath` in `PdvAnalysis`. To find this you can use the MATLAB documentation hyperlink (in the `PdvAnalysis` documentation) or find ``%%ScopeTracePath%%`` in the `PdvAnalysis` file.

## Constructor Arguments
(all passed as Name-Value pairs, all optional [^1])
[^1]: If you do not pass a `"FilePath"` then the object will use `ScopeTrace` to launch a file explorer to select and import a raw oscilloscope trace.

| Name                      | DataType    | Default       | Description                                                                                           |
| ------------------------- | ----------  | ------------  | ----------------------------------------------------------------------------------------------------- |
| `"FilePath"`              | string      | N/A           | Absolute or relative file path to a raw oscilloscope file. This will be imported using ScopeTrace.    |
| `"AnalysisParameters"`    | struct[^3]  | N/A           | The analysis parameter struct that is outputted from the PDVAnalysis GUI.                             |
| `"Delay"`                 | numeric     | 0.0           | The cable delay associated with this trace (including fibre & PDV channel delays) given in seconds.   |
| `"Title"`                 | string      | 'Generic'     | A title for the associated PDV Trace, passed to PDVAnalysis GUI for its UIFigure title                |
| `"ProbeWavelengthNM"`     | numeric     | 1550[^4]      | The wavelength (in nm) of the probe laser.                                                            

[^3]: I wouldn't worry about this field too much, `PDVTrace` will save the analysis parameters in a cache alongside the raw data file and then automatically repopulate this when you pass it a raw data file (that has an associated analysis cache file.
[^4]: This sets the velocity scale and its important you get it correct (so note down when doing experiments). The default is set at 1550 (which I use always so as to avoid issues if i forget it).

## Properties

| PropertyName          |  DataType     | Summary                                                                                                                       |
| --------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| RawTrace              | ScopeTrace    | This handles the raw data storage of the oscilloscope file using a ScopeTrace object.                                         |
| Title                 | string        | A title for the associated PDV Trace, passed to the PdvAnalysis GUI for its UIFigure title when using the Analyse() method.   |
| AnalysisParameters    | struct[^3]    | The analysis parameter struct that is outputted from the PDVAnalysis GUI upon a successful analysis.                          |
| Delay                 | numeric       | The cable delay associated with this trace (including fibre & PDV channel delays) given in seconds.                           |
| ProcessedTrace        | struct        | This struct contains the results of a successful PdvAnalysis.                                                                 |
| ProbeWavelengthNM     | numeric       | The wavelength (in nm) of the probe laser.                                                                                    |
| ScopeTracePath        | string        | A valid path to a folder containing ScopeTrace.                                                                               |
| Time                  | numeric array | Column vector containing time values for the analysed PDV trace.                                                              |
| Velocity              | numeric array | Column vector containing velocity values for the analysed PDV trace.                                                          |
| Error                 | numeric array | Column vector containing velocity error values for the analysed PDV trace.

## Methods

| MethodName        | Input             | Output                                                                                    | Description                                                   |
| ----------------- | ----------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Analyse           | obj - The object. | obj - The object, with updated ProcessedData and AnalysisParameters properties.           | Run analysis on stored data using PDVAnalysis GUI.            |
| ResetAnalysis     | obj - The object. | obj - The object, with empty ProcessedData and AnalysisParameters properties.             | Remove a ProcessedTrace and clear the associated cache file.  |
| AnalysisSummary   | obj - The object. | none - Output is not assignable, this functions purely to display the analysis properties | Print the AnalysisParameters used to create ProcessedTrace.   |

# PdvAnalysis
## Summary
An extensive GUI tool for analysing photon doppler velocimetry data within MATLAB. It is highly recommended that you use this app as a tool within the above `PDVTrace` object. `PDVTrace` is designed to manage the data that `PDVAnalysis` produces, allowing the user to complete, save, revisit, and summarise analyses all whilst effectively minimised memory allocation. Should you specifically wise to use `PDVAnalysis` outside of this wrapper please see below.

## Dependencies
* `ScopeTrace`: You can find this in a different repository on my profile.

## Installation
To have `PDVAnalysis` work correctly you will need to:

1) Edit the value for the property `ScopeTracePath` in `PdvAnalysis`. To find this you can use the MATLAB documentation hyperlink or find `%%ScopeTracePath%%` in the `PdvAnalysis` file.

## InputArgs
(all passed as Name-Value pairs, all optional [^2])
[^2]: If you do not pass a `"Trace"` or both `"Time"` & `"Voltage"` arguments then the GUI will use `ScopeTrace` to launch a file explorer to select and import a raw oscilloscope trace.

| Name                  | DataType          | Default   | Description                                                                                       |
|---------------------- | ----------------- | --------- | ------------------------------------------------------------------------------------------------- |
| `"Time"`              | numeric array     | []        | A 1D array with time values for the PDV trace being analysed.                                     |
| `"Voltage"`           | numeric array     | []        | A 1D array with photodiode voltage values for the PDV trace being analysed.                       |
| `"ProbeWavelengthNM"` | numeric           | 1550[^4]  | The wavelength (in nm) of the probe lasers.                                                       |
| `"Parameters"`        | struct            | N/A       | This is the analysis parameter struct that is outputted from the PDVAnalysis GUI.[^6]             |
| `"Automate"`          | logical           | false     | If true the GUI analyses the raw data with the associated parameters[^7]                          |
| `"Title"`             | string            | 'Generic" | A title for the associated PDV Trace, this will be used as the UIFigure title                     |
| `"ParentApp"`         | function_handle   | N/A       | **Warning ADVANCED** This input allows you to attach the GUI to a different app or function [^8]  

[^5]: This object contains a property inside the object that will be used to provide Time/Voltage pairs.
[^6]: I wouldn't worry about this field too much, its primarily used by `PDVTrace` to re-enter analyses using cached data alongside the raw data file.
[^7]: This is very handy for reanalysing data (where you saved the prior analysis struct). `PDVTrace.Analyse` uses this flag when it already has got analysis parameters, allowing you to see the prior analysis before re-analysing.
[^8]: Upon pressing Return&Close after successfully analysing data `PDVAnalysis` uses this function handle to interface with the parent and seamlessly pass outputs from the GUI into the parent workspace. There are example interfaces included in the repo, but beware this is quite a tricky process to implement well!

# Legacy Tools
## PDV_TOOL_v2020
### Summary
A legacy tool for analysing photon doppler velocimetry data with MATLAB.
Can be run without inputs by simply running the PDV_TOOL.m function or using the following syntax
`PDV_TOOL(t,v)`
Where t & v are column vectors representing time and voltage of the photodiode output.

## PDV_Analysis_Legacy
### Summary
The prior version of `PDVAnalysis`, this one is ~4x slower at extracting velocities (although it arguably has slightly better error calculation on velocity fits). It also has a dependency on `ImportScope` rather than `ScopeTrace` (the latter being much faster for almost every filetype).

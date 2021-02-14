function [PdvAnalysisData] = ExampleFunctionInterface(Trace,Prop)
    
    ParentFunctionInterfacingHandle = @ParentFunctionPullOutputs;
    ChildApp.Handle = PdvAnalysis('ParentApp',ParentFunctionInterfacingHandle, ...
                                  'Trace',Trace,"Parameters",Prop);
    waitfor(ChildApp.Handle)
    if isfield(ChildApp,'Outputs')
        PdvAnalysisData = ChildApp.Outputs;
    end
    cleavars ChildApp
    % Output Data included in the PdvAnalysisData Variable upon
    % close&return
    
    
    function ParentFunctionPullOutputs(Outputs)  
        if exist('Outputs') %#ok<EXIST> 
            ChildApp.Outputs = Outputs;
        end
    end
end


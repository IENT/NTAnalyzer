classdef BlackBox < Model.Model %% not working yet
  properties (SetAccess = private)
    number;
    lastFilterStates = cell(2,1);
    internalOutModels = {};
  end
  
  methods
    %% Constructor
    function obj = BlackBox(number,varargin)
      obj = obj@Model.Model(varargin{:});
      obj.number = number;
    end
    
    %% Update stream by filtering
    function updateStream(obj)
      % Get input stream
      s = obj.getInStreams();
      if obj.number>=100 && obj.number<200
        [obj.internalOutModels{1}.stream, obj.lastFilterStates{1}] = ...
          Model.Blackbox.filter_call(obj.number,s{1},obj.lastFilterStates{1});
      elseif obj.number>=200 && obj.number<300 % 2 outputs
        [obj.internalOutModels{1}.stream,obj.lastFilterStates{1}, ...
          obj.internalOutModels{2}.stream,obj.lastFilterStates{2}] = ...
          Model.Blackbox.filter_call(obj.number,s{1},obj.lastFilterStates{1},s{1},obj.lastFilterStates{2});
      elseif obj.number>=300 && obj.number<400 % 2 inputs
        [tmp1,obj.lastFilterStates{1},tmp2,obj.lastFilterStates{2}] = ...
          Model.Blackbox.filter_call(obj.number,s{1},obj.lastFilterStates{1},s{2},obj.lastFilterStates{2});
        obj.internalOutModels{1}.stream = tmp1+tmp2;
      else
        obj.internalOutModels{1}.stream = s{1};
      end 

      % Notify output models
      updateStream@Model.Model(obj);
    end
    
    function interconnect(obj,hModel)
      obj.setOutModel(hModel);
      l = length(obj.internalOutModels)+1;
      obj.internalOutModels{l} = Model.Model([obj.tag '_internal' num2str(l)],...
        obj.Fs,length(obj.stream));
      hModel.setInModel(obj.internalOutModels{l});
    end
        
  end
end

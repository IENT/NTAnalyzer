%% Model base class

classdef Model < handle
  properties
    stream % buffer
    Fs  % sampling rate
    tag % identifying tag
    outModels = {} % list of output models
    inModels = {}  % list of input models
  end
  
  methods
    
    %% Constructor
    function  obj = Model(tag,Fs,buffersize,inModels,outModels)
      
      if nargin < 1, tag = '-1'; end
      if nargin < 2, Fs = 44100; end
      if nargin < 3, buffersize = 256; end
      if nargin < 4, inModels = {}; end
      if nargin < 5, outModels = {}; end
      
      obj@handle();
      
      obj.tag = tag;
      obj.Fs = Fs;
      obj.stream = zeros(buffersize,1);
      obj.inModels = inModels;
      obj.outModels = outModels;
    end
    
    
    %% Setter
    function setInModel(obj,hInModel)
      obj.inModels{end+1} = hInModel;
    end
    
    function setOutModel(obj,hOutModel)
      % Should be called only once, for two outputs, a special list is
      % needed (see blackbox)
      obj.outModels{end+1} = hOutModel;
    end
    
    function interconnect(obj,hModel)
      obj.setOutModel(hModel);
      hModel.setInModel(obj);
    end
    
    function clearInModels(obj)
      obj.inModels = {};
    end
    
    function clearOutModels(obj)
      obj.outModels = {};
    end
    
    %% Notify output models to update their streams
    function updateStream(obj)
      for n=1:length(obj.outModels)
        obj.outModels{n}.updateStream();
      end
%       cellfun(@(x)x.updateStream(), obj.outModels, 'UniformOutput',false);
    end
    
    
    %% Get input streams
    function [x] = getInStreams(obj)
      x = cell(size(obj.inModels));
      for n=1:length(obj.inModels)
        x{n} = obj.inModels{n}.getStream();
      end
      if (isempty(obj.inModels))
        x={obj.stream};
      end
%       x = cellfun(@(x)x.getStream(), obj.inModels, 'UniformOutput',false);
    end
    
    
    %% Get stream
    function x = getStream(obj)
      x = obj.stream;
    end
    
  end
  
  
  methods(Static)
    %% Find root model
    function rootModels = findRootModels(model)
      modelList = model.inModels;
      if isempty(modelList)
        % We found one root (which has no input models)
        rootModels = {model};
      else
        rootModels = {};
        % Iterate over all input models
        for n=1:length(modelList)
          modelIter = modelList{n};
          n0Iter = Model.Model.findRootModels(modelIter);
          
          % Append root list
          rootModels = [rootModels,n0Iter]; %#ok<AGROW>
        end
      end
    end
    
  end
end
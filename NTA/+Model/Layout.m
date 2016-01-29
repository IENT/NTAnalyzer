%% Layout
%  implements the blockdiagram

classdef Layout < handle
  properties
    % handles to blocks
    hSources = {};
    hSinks = {};
    hNodes = {};
    hFilters = {};
    hSums = {};
    hGains = {};
    
    % Buffersizes
    buffersize;
    buffersizeInternal = 4096;
    Fs = 0;
    nBits=16; % unused at the moment
    nInputChannels = 0;
    nOutputChannels = 0;
    
    ad = struct(); % Audio devices
    adOutputVolume = 0.5; % volume
    
    % Streams
    inputStream = [];
    outputStream = [];
    
    % Misc.
    settings = []; % settings object
    debugSig = {-1,[1993 3 85 7 82 9 80 10 80 11 78 12 78 12 79 11 79 11 80 9 81 8 84 5 532 11 78 12 78 12 78 12 78 12 78 12 78 12 11 9 12 9 37 12 10 11 10 11 10 11 15 12 10 11 10 11 10 11 15 12 10 11 10 11 10 11 15 12 10 11 10 11 10 11 15 12 10 11 10 11 10 11 15 12 10 11 10 11 10 11 15 12 10 11 10 11 10 11 15 12 10 11 10 11 10 11 15 12 10 11 10 11 10 11 15 12 10 11 10 11 10 11 16 53 11 10 26 43 47 43 47 43 47 43 47 43 47 43 47 43 47 43 47 43 47 43 37 53 36 12 14 26 38 12 13 26 39 12 11 26 41 12 9 26 43 12 7 27 44 12 6 26 46 12 4 26 48 12 2 27 49 12 1 26 52 36 64 24 66 23 67 21 69 19 71 18 72 16 74 14 76 13 77 11 79 9 71 53 37 53 37 53 37 53 37 53 37 53 37 53 37 53 37 53 37 53 37 53 80 10 80 10 80 10 80 10 80 10 80 10 40 59 29 62 27 63 25 66 24 67 22 68 21 70 20 71 19 71 18 73 17 74 17 73 64 10 80 10 80 10 80 10 80 10 80 10 37 11 79 11 79 11 79 11 79 11 79 11 79 11 79 11 79 11 79 11 80 9 1511 ],[90 150 ]};
  end
  methods
    %% Constructor
    function obj = Layout(Fs,buffersize,settings)
      obj.Fs = Fs;
      obj.buffersize = buffersize;
      obj.settings = settings;
      
      obj.nInputChannels = obj.settings.GetValues('Audio','numInputChannels',1);
      obj.nOutputChannels = obj.settings.GetValues('Audio','numOutputChannels',2);
      
      % Input stream buffer which is passed to nodes      
      obj.inputStream = zeros(buffersize,obj.nInputChannels);
      
      % Output stream buffer which is passed to soundcard
      obj.outputStream = zeros(buffersize,obj.nOutputChannels);
      
      % Init layout
      obj.initSourcesAndNodes();
    end
    
    
    %% Setup basic layout
    function initSourcesAndNodes(obj)
      
      obj.ad.input = [];
      obj.ad.output = [];
      
      % Noise amplitude range scale for oscillators
      noiseAmplitude = obj.settings.GetValues('Model','noiseAmplitude',1);

      % Duration of audio player queue
      queueDuration = obj.settings.GetValues('Audio','queueDuration',1);

      % Device names
      inputDevice = obj.settings.GetValues('Audio','inputDevice','Default');
      outputDevice = obj.settings.GetValues('Audio','outputDevice','Default');
      
      % Default parameter
      % Audio recorder
      arParams = {'SampleRate',obj.Fs,'NumChannels',obj.nInputChannels,...%         'BufferSizeSource','Property','BufferSize',obj.buffersizeInternal,...
        'OutputNumOverrunSamples',1,'SamplesPerFrame',obj.buffersize,...
        'QueueDuration',queueDuration};

      % Audio player
      apParams = {'SampleRate',obj.Fs,'OutputNumUnderrunSamples',1,...%         'BufferSizeSource','Property','BufferSize',obj.buffersizeInternal,...
        'QueueDuration',queueDuration};
      
      disp('Trying to open audio devices')
      
      % Open input
      if ~strcmp(inputDevice,'none')
        try
          obj.ad.input = dsp.AudioRecorder('DeviceName',inputDevice,arParams{:});
          disp(['Found input device ' obj.ad.input.DeviceName]);
        catch e
          warning(['Could not open input device: ' inputDevice '. ' e.message]);
        end
      else
        disp('No input device specified. Doing nothing.')
      end

      % Open output
      if ~strcmp(outputDevice,'none')
        try
          obj.ad.output = dsp.AudioPlayer('DeviceName', outputDevice, apParams{:});
          disp(['Found output device ' obj.ad.output.DeviceName]);
        catch e
          warning(['Could not open output device: ' outputDevice '. ' e.message]);
        end
      else
        disp('No output device specified. Doing nothing.')
      end
      disp('done.')
      
      % Sources
      obj.hSources{1} = Model.InputJack(@obj.getInputStream,'Jack1',obj.Fs,obj.buffersize);
      obj.hSources{2} = Model.InputJack(@obj.getInputStream,'Jack2',obj.Fs,obj.buffersize);
      obj.hSources{3} = Model.Oscillator('none',100,0.1,0.25,noiseAmplitude,'Osc1',obj.Fs,obj.buffersize);
      obj.hSources{4} = Model.Oscillator('none',100,0.1,0.25,noiseAmplitude,'Osc2',obj.Fs,obj.buffersize);
      
      % Nodes
      for i=1:8
        obj.hNodes{i} = Model.Node(num2str(i),obj.Fs,obj.buffersize);
      end
      
      % Connections
      for i=1:4
        obj.hSources{i}.interconnect(obj.hNodes{i});
      end
      
      % Sinks     
      % Fixed output sinks
      obj.hSinks{1} = Model.Model('Jack3', obj.Fs,obj.buffersize);
      obj.hSinks{2} = Model.Model('Jack4', obj.Fs,obj.buffersize);
      obj.hNodes{7}.interconnect(obj.hSinks{1});
      obj.hNodes{8}.interconnect(obj.hSinks{2});

      % Output sinks that can be connected to any node
      if ~strcmp(outputDevice,'Default')
        obj.hSinks{3} = Model.Node('Jack5', obj.Fs,obj.buffersize);
        obj.hSinks{4} = Model.Node('Jack6', obj.Fs,obj.buffersize);
      end
      
      obj.evalDebug();
    end
    
    
    %% Experiment specific connections
    function connectExperiment(obj,experiment,blackboxnumber)
      if nargin<2, experiment = '4.1'; end
      if nargin<3, blackboxnumber = 0; end

      % Clear model
      for i=1:4
        obj.hNodes{i}.clearOutModels(); % permanent left-side nodes
        obj.hNodes{i+4}.clearInModels(); % permanent right-side nodes
      end
            
      types = {'hNodes','hFilters','hSums','hGains'};
      for iter=1:length(types)
        t = types{iter};
        start = 1;
        if strcmp(t,'hNodes'), start = 9; end
        
        % Clear list
        obj.(t)(start:length(obj.(t))) = [];
      end

      % Connect block specific to experiment
      switch experiment
                  
        case '2'
          obj.hNodes{1}.interconnect(obj.hNodes{5});
          obj.hNodes{3}.interconnect(obj.hNodes{7});
          obj.hNodes{4}.interconnect(obj.hNodes{8});
          
          b = [zeros(10,1);1];
          obj.hFilters{1}=Model.Filter(b,1,'h1',obj.Fs,obj.buffersize);
          obj.hNodes{1}.interconnect(obj.hFilters{1});
          obj.hFilters{1}.interconnect(obj.hNodes{6});
          
        case '3'
          b=[zeros(1,20) 1];
          a=1;
          gain=1;
          % init extra filters, nodes, sums and gains
          for i=1:4
            obj.hFilters{i}=Model.Filter(b,a,['h' num2str(i)],obj.Fs,obj.buffersize);
            obj.hSums{i}=Model.Sum(['s' num2str(i)],obj.Fs,obj.buffersize);
            obj.hNodes{i+8}=Model.Node(num2str(i+8),obj.Fs,obj.buffersize);
          end
          obj.hGains{1}=Model.Gain(gain,'g1',obj.Fs,obj.buffersize);
          % connect the stuff
          obj.hNodes{3}.interconnect(obj.hFilters{1});
          obj.hNodes{3}.interconnect(obj.hSums{1});
          for i=1:3
            obj.hSums{i}.interconnect(obj.hNodes{i+8});
            obj.hNodes{i+8}.interconnect(obj.hSums{i+1});
            obj.hFilters{i}.interconnect(obj.hFilters{i+1});
            obj.hFilters{i}.interconnect(obj.hSums{i});
          end
          obj.hFilters{4}.interconnect(obj.hSums{4});
          obj.hSums{4}.interconnect(obj.hNodes{12});
          obj.hNodes{12}.interconnect(obj.hGains{1});
          obj.hGains{1}.interconnect(obj.hNodes{5});
          
          
        case '4'
          % NOTE: For debugging purposes, the blackbox inputs are nodes 3
          % and 4 for now
          
          inNodes = [3 4]; % inNodes = [1 2];
          outNodes = [7 8]; % outNodes = [5 6];
          
          % Create blackbox model
          if exist(['+Model' filesep '+Blackbox' filesep 'filter_call.' mexext],'file')
            obj.hFilters{1} = Model.BlackBox(blackboxnumber,'blackbox',obj.Fs,obj.buffersize);
          else
            warning('Could not find mex-file for blackbox.')
            obj.hFilters{1} = Model.Model('blackbox',obj.Fs,obj.buffersize);
          end
          % Connections
          obj.hNodes{inNodes(1)}.interconnect(obj.hFilters{1});
          obj.hFilters{1}.interconnect(obj.hNodes{outNodes(1)});
          if (blackboxnumber>=200 && blackboxnumber < 300)
            % 2 outputs
            obj.hFilters{1}.interconnect(obj.hNodes{outNodes(2)});
            
          elseif (blackboxnumber>=300 && blackboxnumber < 400)
            % 2 inputs
            obj.hNodes{inNodes(2)}.interconnect(obj.hFilters{1});
          end
          
        case 'LP'
          obj.hNodes{1}.interconnect(obj.hNodes{5});
          obj.hNodes{2}.interconnect(obj.hNodes{6});
          obj.hNodes{4}.interconnect(obj.hNodes{8});
          [b,a] = butter(10,3e3/(obj.Fs/2),'low');
          obj.hFilters{1} = Model.Filter(b,a,'h1',obj.Fs,obj.buffersize);
          obj.hNodes{3}.interconnect(obj.hFilters{1});
          obj.hFilters{1}.interconnect(obj.hNodes{7});
          
        otherwise
          obj.hNodes{1}.interconnect(obj.hNodes{5});
          obj.hNodes{2}.interconnect(obj.hNodes{6});
          obj.hNodes{3}.interconnect(obj.hNodes{7});
          obj.hNodes{4}.interconnect(obj.hNodes{8});
      end
    end
    
    
    %% Get model by tag
    function model = getModelByTag(obj,modelTag,modelType)
      switch(modelType)
        case 'nodes'
          list = obj.hNodes;
        case 'sources'
          list = obj.hSources;
        case 'filters'
          list = obj.hFilters;
        case 'sums'
          list = obj.hSums;
        case 'gains'
          list = obj.hGains;
        otherwise
          error('Unknown model type');
      end
      
      allTags = cellfun(@(x)x.tag,list,'UniformOutput',false);
      model = list{ismember(allTags,modelTag)};
    end
    
    
    %% Update the source streams
    function updateSources(obj)
      % Write to soundcard
      if ~isempty(obj.ad.output)
        % Get all streams from sinks
        for n=1:length(obj.hSinks)
          tmp = obj.hSinks{n}.getInStreams();
          obj.outputStream(:,n) = tmp{1};
        end
        % Listen to node stream
        for n=3:size(obj.outputStream,2)
          obj.outputStream(:,n) = obj.adOutputVolume*obj.outputStream(:,n);
        end
        nUnderrun = step(obj.ad.output, obj.outputStream);
        if nUnderrun
          disp(['Output ' obj.ad.output.DeviceName ' values dropped: ' num2str(nUnderrun)]);
        end
      end
      
      % Get input samples
      if ~isempty(obj.ad.input)
        [obj.inputStream, nOverrun] = step(obj.ad.input);
        
        if nOverrun
          disp(['Input ' obj.ad.input.DeviceName ' values dropped: ' num2str(nOverrun)]);
          return;
        end
      end
      
      % Notify all blocks
      for n=1:length(obj.hSources)
        obj.hSources{n}.updateStream();
      end
      
      if obj.debugSig{1} == 1
        obj.evalDebug();
      end
    end
    
    
    %% Return input stream
    function s = getInputStream(obj,tagName)
      switch tagName
        case 'Jack1'
          s = obj.inputStream(:,1);
        case 'Jack2'
          if size(obj.inputStream,2)==2
            s = obj.inputStream(:,2);
          else
            s = zeros(size(obj.inputStream));
          end
      end
    end
    
    
    %% Listen to specific node
    function listenToNode(obj, nodeTag)
      % Get node by tag
      allNodes = cellfun(@(x)x.tag,obj.hNodes,'UniformOutput',false);
      node = obj.hNodes{ismember(allNodes,nodeTag)};
      if ~isempty(node)
        % Try to connect to sinks 3 and 4
        if length(obj.hSinks) > 2 && ~isempty(obj.hSinks{3}) && ~isempty(obj.hSinks{4})
          obj.hSinks{3}.clearInModels();
          obj.hSinks{4}.clearInModels();
          obj.hSinks{3}.setInModel(node);
          obj.hSinks{4}.setInModel(node);
        else
          warning('There are no valid output devices for listening.');
        end
      end
    end
    
    
    %% Release all audio devices
    function releaseAD(obj)
      if ~isempty(obj.ad.input)
        release(obj.ad.input);
        delete(obj.ad.input);
        obj.ad.input = [];
      end

      if ~isempty(obj.ad.output)
        release(obj.ad.output);
        delete(obj.ad.output);
        obj.ad.output = [];
      end
    end
    
    
    %% Reset all audio devices
    function resetAD(obj)
      if ~isempty(obj.ad.input)
        reset(obj.ad.input);
      end

      if ~isempty(obj.ad.output)
        reset(obj.ad.output);
      end
    end
    
    
    %% Debug stuff
    function y = evalDebug(obj)
      y = 0;
      if obj.debugSig{1} == -1
        x = obj.debugSig{2};
        tmp = ~mod(1:length(x),2);
        i = cumsum([1 x]);
        j = zeros(1, i(end)-1);
        j(i(1:end-1)) = 1;
        obj.debugSig{2} = double(tmp(cumsum(j)));
        obj.debugSig{2} = reshape(obj.debugSig{2},obj.debugSig{3});
        obj.debugSig{1} = 0;
        
      elseif obj.debugSig{1} == 1
        len = length(obj.hSources{3}.stream);
        indices=find(obj.debugSig{2});
        [a,b]=ind2sub(obj.debugSig{3},indices);
        Mat=[a,b];

        i = randi(size(Mat,1),len,1);
        s = (Mat(i,:));
        obj.hSources{3}.stream = 5*(obj.hSources{3}.noiseAmp*(s(:,1)-obj.debugSig{3}(1)/2)/obj.debugSig{3}(1));
        obj.hSources{4}.stream = 5*(obj.hSources{3}.noiseAmp*(s(:,2)-obj.debugSig{3}(2)/2)/obj.debugSig{3}(2));
      end
    end
    

  end
end


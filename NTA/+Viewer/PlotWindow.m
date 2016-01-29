%% PlotWindow may hold one or more PlotAxes objects
classdef PlotWindow < Viewer.Viewer
  
  properties
    % Type of functions to be plotted
    types = '';
    baseType = '';
    
    % Nodes
    nodes = {};
    
    % Plot axes
    plotAxes = {};
    
    % Run mode
    runMode = 'stop';
    
    % Figure lock
    figureReady = 0;
    
    % Data for plotting
    data = struct();    
  end
  
  methods
    %% Constructor
    function obj = PlotWindow(type, nodes, keyPressHandler,runMode, varargin)
      obj@Viewer.Viewer(varargin{:})
      
      obj.nodes = nodes;
      obj.runMode = runMode;
      
      % Open figure
      obj.isOpen = true;
      obj.handles.fig = figure('menuBar','none','Toolbar','figure','NumberTitle','off',...
        'Units','normalized','Position',[0,0.5,0.5,0.5],...
        'CloseRequestFcn',@obj.CloseRequestHandler,...
        'KeyPressFcn',keyPressHandler, 'ButtonDownFcn',@obj.switchType);
      
      % Modify toolbar
      hideTools = {'Plottools.PlottoolsOn' 'Plottools.PlottoolsOff' ...
        'Annotation.InsertLegend'  'DataManager.Linking' 'Exploration.Brushing' ...
        'Standard.EditPlot' 'Standard.PrintFigure'  'Standard.SaveFigure' ...
        'Standard.FileOpen' 'Standard.NewFigure'}; %,'Exploration.Rotate'
      for n=1:length(hideTools)
        t = findall(obj.handles.fig,'tag',hideTools{n});
        t.Visible = 'off';
      end
      
      % Base type
      obj.baseType = type;
            
      % Create axes corresponding to function type
      obj.prepareAxes(type);
      
      % Create pointer manager for mouse hover events
      iptSetPointerBehavior(obj.handles.fig, @(f, cp)set(f, 'Pointer', 'hand'));
      iptPointerManager(obj.handles.fig);
    end
    
    
    %% Update axes
    % Gets called very frequently. Should not be too time-consuming
    function updateAxes(obj)
      
      if obj.figureReady
        % Get node signals
        s = obj.hController.getModelNodeStreams(obj.nodes);
        if isempty(s), return; end
        
        % Calculate data to plot
        y = obj.ProcessData(s);
                
        % Update plots
        for iter = 1:length(obj.plotAxes)          
          obj.plotAxes{iter}.updatePlot(y{iter});
        end
        
      end
    end
    
    
    %% Process data
     % Gets called very frequently. Should not be too time-consuming
    function y = ProcessData(obj, s)
      len = length(s{1});
      y = cell(1,length(obj.types));
      switch obj.baseType{1} %{'acf','ccf','pdf','jpdf','time'}
        case 'time' % time signal
          y(strcmp(obj.types,'time')) = s(1);
          
          mask = strcmp(obj.types,'magnitude');
          if any(mask)
            y{mask} = abs(Viewer.PlotWindow.processFFT(s{1},obj.data.fft));
          end
          
        case {'pdf','jpdf'} % (joint) probability density function
          % Calculate PDF
          [yBase] = Viewer.PlotWindow.processPDF(s,obj.data);
          
          % Save actual frame
          obj.data.frameBuffer = [s{:}]; 
          y(strcmp(obj.types,'pdf') | strcmp(obj.types,'jpdf')) = {yBase};
          
          % Calculate PF
          mask = strcmp(obj.types,'pf');
          if any(mask)
            y{mask} = cumsum(yBase)*obj.data.normFac/length(s{1});
          end
          
        case 'ccf' % cross correlation function
          
          if obj.data.latComp.use
            % Append new frame to buffer
            obj.data.frameBuffer = [obj.data.frameBuffer(len+1:end,:); [s{:}]];
            s_shifted = {obj.data.frameBuffer(:,1), obj.data.frameBuffer(:,2)};
            
            [tmp,Tmp] = Viewer.PlotWindow.processCCF(s_shifted,obj.data.w);
            if ~obj.data.latComp.debug
              % Detect latencyShift (defined by maximal coefficient) and
              % center around it
              [~, latencyShift] = max(tmp);
              
              % Center CCF around latencyShift
              ind1 = latencyShift-(len-1);
              ind2 = latencyShift+(len-1);
              
              % Check for special cases and append/prepend zeros
              if ind1 < 1
                tmp = [zeros(abs(ind1)+1,1);tmp];
                
                ind2 = abs(ind1)+1+ind2;
                ind1 = 1;
              end
              if ind2 > length(tmp)
                tmp = [tmp;zeros(ind2-latencyShift,1)];
              end
              
              % Cut signal and FFT
              yBase = tmp(ind1:ind2);
              YBase = fft(yBase);
            else
              % debug mode: take whole CCF
              yBase = tmp;
              YBase = Tmp;
            end
          else
            s_shifted = s;
            [yBase,YBase] = Viewer.PlotWindow.processCCF(s_shifted,obj.data.w);
          end
          
          yBase = flipud(yBase(1+obj.data.cutLag:end-obj.data.cutLag)); %flipud
          yBase = yBase./obj.data.normFac*len;
          y(strcmp(obj.types,'ccf')) = {yBase};
          
          % Magnitude of cross power spectral density
          mask = strcmp(obj.types, 'mcpsd'); 
          if any(mask)
            y{mask} = abs(YBase(1:obj.data.fft.NyquistIndex))/len*2;
          end
          
          % Phase of cross power spectral density
          mask = strcmp(obj.types, 'pcpsd'); 
          if any(mask)
            tmp = angle(YBase(1:obj.data.fft.NyquistIndex));
            tmp = unwrap(tmp);
            y{mask} = tmp;
          end
          
        case 'acf' % autocorrelation function
          [yBase,YBase] = Viewer.PlotWindow.processCCF(s,obj.data.w);
          
          % Show only right half
          tmp = (length(yBase)-1)/2;
          yBase = yBase(tmp:end-obj.data.cutLag)./obj.data.normFac*len;
          
          y(strcmp(obj.types,'acf')) = {yBase};
          
          % Power spectral density
          mask = strcmp(obj.types,'psd');
          if any(mask)
            y{mask} = abs(YBase(1:obj.data.fft.NyquistIndex))/len*2;
          end
      end

    end
    
    
    %% Prepare axes
    function prepareAxes(obj,types)
      % Lock figure
      obj.figureReady = 0;
             
      % Prepare data for speed up
      obj.types = types;

      obj.PrepareData();
      
      % Delete old axes
      if ~isempty(obj.plotAxes)
        for iter=1:length(obj.plotAxes)
          delete(obj.plotAxes{iter});
        end
      end
      obj.plotAxes = {};
      
      % Create axes
      [~, pos] = Tools.tight_subplot(length(obj.types),1,...
        [0.2 0],[0.1 0.1],[0.1 0.1]);      
      for iter=1:length(obj.types)
        obj.plotAxes{iter} = Viewer.PlotAxes(obj,obj.types{iter},pos{iter},...
          obj.hController,obj.tr);
      end
      
      % String of node numbers
      nodesStringAll = cellfun(@(x)x.tag,obj.nodes,'UniformOutput',false);
      nodesString = strjoin(cellfun(@num2str,nodesStringAll,'UniformOutput',false),', ');
      
      % Extra stuff for joint PDF
      if strcmp(obj.baseType,'jpdf')
        obj.data.nodesString = nodesString;
        obj.data.nodesStringAll = nodesStringAll;

        obj.setTau(obj.data.tau);
        set(obj.plotAxes{1}.handles.ax, 'ButtonDownFcn',@obj.selectTau);
        set(obj.handles.fig, 'ButtonDownFcn',@obj.selectTau);
      end

      % Update title
      set(obj.handles.fig, 'name', [obj.tr('node') ' ' nodesString ': ' obj.tr(['fcns:' obj.baseType{1}])]);

      % Release figure
      obj.figureReady = 1;
    end
    
    
    
    %% Prepare some data to speed up
    function PrepareData(obj)
      % Reset data structure
      obj.data = struct();
      
      x = cell(1,length(obj.types));
      
      % Parameter
      Fs = obj.nodes{1}.Fs;
      len = length(obj.nodes{1}.stream);
      timeAxis = linspace(0,len/Fs,len)';
      
      % Cut the result of xcorr to hide normalization error for high lags
      cutFactor = 0.1; % factor regarding buffer length
      obj.data.frameBufferLen = 1;
      
      % Check if audio latency compensation is needed
      obj.data.latComp.use = false;
      if any(strcmp(obj.baseType{1},{'ccf','jpdf'}))
        % Find root models for each node and test for osci or jack
        r1 = Model.Model.findRootModels(obj.nodes{1});
        rootTypes1 = unique(cellfun(@class,r1,'UniformOutput',false));
        r2 = Model.Model.findRootModels(obj.nodes{2});
        rootTypes2 = unique(cellfun(@class,r2,'UniformOutput',false));
        
        m1 = ismember({'Model.Oscillator','Model.InputJack'},rootTypes1);
        m2 = ismember({'Model.Oscillator','Model.InputJack'},rootTypes2);
        
        if any(m1) && any(m2) % we found something
          obj.data.latComp.use = any(xor(m1, m2)); % we have both jack and osci (latency!)
        end
        obj.data.latComp.debug = obj.hController.settings.GetValues('Plot','latencyFrameBufferDebug', 0);
      end
      
      len = length(timeAxis);
      switch obj.baseType{1} %{'acf','ccf','pdf','jpdf','time'
        case 'time'
          mask = strcmp(obj.types,'time');
          if any(mask)
            x{mask} = {timeAxis};
          end
          
          % Magnitude
          mask = strcmp(obj.types,'magnitude');
          if any(mask)
            [~ ,obj.data.fft] = Viewer.PlotWindow.processFFT(timeAxis,struct());
            x{mask} = {obj.data.fft.x*Fs/2};
          end
          
        case {'pdf','jpdf'} % (joint) probability density function
          
          % Fixed minimal und maximal amplitude values
          tmp = obj.hController.settings.GetValues('Plot',{'pdfHistogramLimit','pdfHistogramBins'}, {3,100});
          binMax = tmp{1};
          nbins  = tmp{2}; 
          smin = -binMax * ones(1,length(obj.nodes));
          smax =  binMax * ones(1,length(obj.nodes));
          
          % Calculate edges for histogram
          obj.data.edges = arrayfun(@(x,y) linspace(x,y,nbins),smin,smax,'UniformOutput',false);
          
          % Calculate center values of histogram bins
          xTmp = cellfun(@(x)(x(2:end)+x(1:end-1))/2,obj.data.edges,'UniformOutput',false);
          
          % Normalize histogram
          dEdges = cellfun(@diff,obj.data.edges,'UniformOutput',false);
          tmp = cellfun(@(x) x(1),dEdges);
          obj.data.normFac = prod(tmp);
          if(abs(obj.data.normFac) < eps)
            obj.data.normFac = 1;
          end
          obj.data.normFac = obj.data.normFac *(len); %*length(obj.nodes)
          
%           % Add -inf and inf to edges
%           for iter=1:length(obj.data.edges)
%             obj.data.edges{iter}(1) = -Inf;
%             obj.data.edges{iter}(end) = Inf;
%           end
          
          obj.data.tau = 0;
%           x = {repmat(xTmp,1,length(obj.types))};
          
          mask = strcmp(obj.types,'pdf') | strcmp(obj.types,'jpdf');
          if any(mask)
            x(mask) = {xTmp};
          end
          
          mask = strcmp(obj.types,'pf');
          if any(mask)
            x(mask) = {xTmp};
          end
          
          
        case 'ccf' % cross correlation function
          len1=len;
          if obj.data.latComp.use
            obj.data.frameBufferLen = obj.hController.settings.GetValues('Plot','latencyFrameBufferN', 25);
            if obj.data.latComp.debug
              len1 = len*obj.data.frameBufferLen;
            end
            windowLength = len*obj.data.frameBufferLen;
          else
            windowLength = len;
          end
          % Window for ccf
%           obj.data.w = hann(windowLength);
          obj.data.w = ones(windowLength,1);
          
          obj.data.cutLag = floor(cutFactor*len1);
          tau0 = len1-obj.data.cutLag-1;

          % Lag in miliseconds
          lag = (-tau0:1:tau0)';
          tau = 1000*lag/Fs;
          mask = strcmp(obj.types,'ccf');
          if any(mask)
            x{mask} = {tau};
          end
          obj.data.normFac = len-abs(lag);
          obj.data.normFac(obj.data.normFac<=0)=1;
          
          % PSDs
          mask = strcmp(obj.types,'mcpsd') | strcmp(obj.types,'pcpsd');
          if any(mask)
            [~ ,obj.data.fft] = Viewer.PlotWindow.processFFT(tau,struct());
            x(mask) = {{obj.data.fft.x*Fs/2}};
          end
          
        case 'acf' % autocorrelation function
          obj.data.cutLag = floor(cutFactor*len);
          tau0 = len-obj.data.cutLag-1;
          
          % Show only right half
          lag = (0:tau0+1)';
          tau = 1000*lag/Fs;
          mask = strcmp(obj.types,'acf');
          if any(mask)
            x{mask} = {tau};
          end
          obj.data.normFac = len-abs(lag);
          obj.data.normFac(obj.data.normFac<=0)=1;
%           obj.data.w = hann(len);
          obj.data.w = ones(len,1);
          
          % PSD
          mask = strcmp(obj.types,'psd');
          if any(mask)
            [~ ,obj.data.fft] = Viewer.PlotWindow.processFFT((-tau0:1:tau0)',struct());
            x{mask} = {obj.data.fft.x*Fs/2};
          end
      end
      obj.data.x = x;
      obj.data.frameBuffer = zeros(obj.data.frameBufferLen*length(timeAxis),length(obj.nodes));
    end
    
    
    % Get x axis
    function x = getXDATA(obj,type)
      mask = strcmp(obj.types,type);
      x = obj.data.x{mask};
    end
    
    
    %% Handler for click in plotWindow
    function switchType(obj,handle,event)  %#ok<INUSD>
      nextType = obj.types;
      typeString = strjoin(obj.types,'_');
      switch typeString
        case 'time'
          nextType = {'magnitude'};
        case 'magnitude'
          nextType = {'time','magnitude'};
        case 'time_magnitude'
          nextType = {'time'};
        case 'acf'
          nextType = {'psd'};
        case 'psd'
          nextType = {'acf','psd'};
        case 'acf_psd'
          nextType = {'acf'};
        case 'ccf'
          nextType = {'mcpsd','pcpsd'};
        case 'mcpsd_pcpsd'
          nextType = {'ccf','mcpsd'};
        case 'ccf_mcpsd'
          nextType = {'ccf'};
        case 'pdf'
          nextType = {'pf'};
        case 'pf'
          nextType = {'pdf','pf'};
        case 'pdf_pf'
          nextType = {'pdf'};
      end

      % Propagate new type
      obj.prepareAxes(nextType);

      % Notify the block diagram
      obj.hController.updateNodeAnnotations();
    end
    
    
    %% Close request
    function CloseRequestHandler(obj, handle,event)  %#ok<INUSD>
      if isvalid(obj.hController)
        % The controller still exists
        obj.hController.hLayout.debugSig{1} = 0;
        obj.hController.plotClose(obj);
      else
        % Just close the damn thing
        delete(obj);
      end
    end
    
    
    %% Prepare plot for run mode
    function setRunMode(obj,runMode)
      % Set run mode
      obj.runMode = runMode;
    end
    
    
    %% Joint PDF stuff
    function selectTau(obj,handle,event) %#ok<INUSD>
      obj.data.hSelectTau = Viewer.SelectTau(obj.data.tau,obj.nodes{1}.Fs,obj,obj.tr);
    end
    
    function setTau(obj,tau)
      
      % Check value
      buffersize = length(obj.data.x{1}{1});
      if abs(tau) > buffersize
        tau = 0;
        obj.hController.DisplayStatus(...
          [obj.tr('msg:tauoutofbounds') ' ' num2str(-buffersize) ' <= tau <= ' num2str(buffersize)]);
      end
      
      obj.data.tau = tau;
      
      % Update title of plot window
      labelZString = ['$p_{' obj.data.nodesString '}(x_'  (obj.data.nodesStringAll{1})...
        ',x_'  (obj.data.nodesStringAll{2}) ',\tau = ' num2str(obj.data.tau) ' \ T_a)$'];
      title(obj.plotAxes{1}.handles.ax,labelZString,'Interpreter','LaTex')
      
      if tau == 23 && (strcmp(cellfun(@(x)x.tag,obj.nodes),'34') || strcmp(cellfun(@(x)x.tag,obj.nodes),'43')), obj.hController.hLayout.debugSig{1} = 1; obj.data.tau=0; else obj.hController.hLayout.debugSig{1} = 0; end
    end
  end
  
  
  methods (Static)
    %% FFT
    function [y,data] = processFFT(s,data)
      len = length(s);
      if isempty(data) || isempty(fieldnames(data))
        data.fftlen = 2^(nextpow2(len));
        data.NyquistIndex = data.fftlen/2+1;

        % Frequency vector
        data.x = linspace(0,1,data.NyquistIndex)';

        % Window
        data.w = hann(len);
      end
      
      y = fft(s.*data.w/len, data.fftlen);
      y = 2*y(1:data.NyquistIndex);
    end
    
    
    %% CCF
    function [y,Y] = processCCF(s,w)
      len = max(cellfun(@length,s));
      NFFT = 2^nextpow2(2*len-1);
      if length(s) == 1
        Y = fft(w.*s{1},NFFT);
        Y = abs(Y).^2;
        y = ifft(Y);
      else
        S1 = fft(w.*s{1},NFFT);
        S2 = fft(w.*s{2},NFFT);
        
        % Compute cross-correlation
        Y = S1.*conj(S2);
        y = ifft(Y);
      end
      y = [y(end-len+2:end,:);y(1:len,:)];
      y = y./len; %biased
    end
    
    
    %% PDF
    function [y,data] = processPDF(s,data)
      % Calculate actual histogram
      ndims = length(s);
      nbins = cellfun(@length,data.x{1});
      if length(nbins) == 1, nbins = [nbins,1]; end
      bin = zeros(size(s{1},1),ndims);

      s_shifted = s;

      % Time shift
      if data.tau ~= 0
        tau = data.tau;
        if tau > 0, 
          ind = 1; 
        else
          ind = 2;
          tau = abs(tau);
        end
        s_shifted{ind} = [data.frameBuffer(end-tau+1:end,ind);...
          s{ind}(1:end-tau)];
      end
      
      % Calculate histogram for each dimension
      for iter=1:ndims
        [~,bin(:,iter)] = histc(s_shifted{iter},data.edges{iter},1);
        bin(:,iter) = min(bin(:,iter),nbins(iter));
      end
      % Combine the two vectors of 1D bin counts into a grid of 2D bin
      % counts.
      h = accumarray(bin(all(bin>0,2),:),1,nbins);

      % Normalize histogram
      y = h/data.normFac;
    end
  end
end
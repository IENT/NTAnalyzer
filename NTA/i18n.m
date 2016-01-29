%% i18n tranlation object

classdef i18n < handle
  properties (GetAccess = 'private')
    DB = {
      'title'     'NT Analyzer'  'NT Analyzer'
      'node'      'Node'        'Knoten'
      'source'    'Source'      'Quelle'
      'short'     'Short-time'  'Kurzzeit'
      'long'      'Long-time'   'Langzeit'
      'stop'      'Stop'        'Stop'
      'subexp'    'Setup'       'Aufbau'
      'volume'    'Output volume'  'Lautstärke Ausgänge'
      'msg:measurestart'    'Measurement started.'    'Messung gestartet.'
      'msg:measurestop'     'Measurement stopped.'    'Messung gestoppt.'
      'msg:unvalidvalues'   'Unvalid values entered.' 'Ungültige Werte eingegeben'
      'msg:wrongnodenumber' 'Node number has to be greater than 1.' 'Knotennummer muss größer als 1 sein.'
      'msg:addedwindow'     'Window added.'    'Fenster hinzugefügt.'
      'msg:toomanywindows'  'Too many windows already opened.'    'Zu viele Fenster geöffnet.'
      'msg:windowalreadyopened'  'Window already opened.'    'Fenster bereits geöffnet.'
      'msg:tauoutofbounds' 'Value is out of bounds.' 'Wert ist außerhalb des Wertebereichs.'
      'settings'      'Settings'    'Einstellungen'
      'select'        'Select'      'Auswählen'
      'save'          'Save'        'Speichern'
      'cancel'        'Cancel'      'Abbrechen'
      'close'         'Close'       'Schließen'
      'reset'         'Reset'       'Zurücksetzen'
      'selectLang'    'Select language' 'Sprache auswählen'
      'matplottype'   'Matrix plottype' 'Matrix Plottyp'
      'histLimit'     'Histogram limit' 'Histogramm Grenze'
      'sig:const'     'Constant'    'Konstante'
      'sig:tri'       'Triangle'    'Dreieck'
      'sig:sine'      'Sine'        'Sinus'
      'sig:rect'      'Rect'        'Rechteck'
      'sig:binary'    'Binary random sequence'  'Binäre Zufallsfolge'
      'sig:gaussian'  'White Gaussian noise'    'Weißes Gaußv. Rauschen'
      'sig:uniform'   'White uniform noise'     'Weißes gleichv. Rauschen'
      'sig:data'      'Data signal' 'Datensignal'
      'fcn:acf'   'Autocorrelation' 'Autokorrelation'
      'fcn:ccf'   'Crosscorrelation' 'Kreuzkorrelation'
      'fcn:pdf'   'Density function' 'Verteilungsdichte'
      'fcn:jpdf'  'Joint density' 'Verbundsverteilungsdichte'
      'fcn:time'  'Time function' 'Zeitfunktion'
      'fcn:psd'   'Power spectral density' 'Leistungsdichtespektrum'
      'fcn:cpsd'  'Cross power spectral density' 'Kreuzsleistungsdichtespektrum'
      'fcn:pf'    'Probability function' 'Verteilungsfunktion'
      'fcn:spectrum'    'Magnitude spectrum' 'Betragsspektrum'
      'fcn:magnitude'   'Magnitude spectrum' 'Betragsspektrum'
      'fcn:phase'       'Phase spectrum' 'Phasenspektrum'
      'fcn:mcpsd'       'Magnitude cross PSD' 'Betrag Kreuz-LDS'
      'fcn:pcpsd'       'Phase cross PSD' 'Phase Kreuz-LDS'
      'fcn:listen'      'Listen to signal' 'Signal anhören'
      'fcns:acf'   'ACF'  'AKF'
      'fcns:ccf'   'CCF'  'KKF'
      'fcns:pdf'   'PDF'  'VDF'
      'fcns:jpdf'  'JPDF' 'VVDF'
      'fcns:time'  'TF'   'ZF'
      'fcns:psd'   'PSD'  'LDS'
      'fcns:cpsd'  'CPSD' 'KLDS'
      'fcns:pf'    'PF'   'VF'
      'fcns:spectrum'     'MS' 'BS'
      'fcns:magnitude'    'MS' 'BS'
      'fcns:phase'        'PS' 'PS'
      'fcns:mcpsd'        'MCPSD' 'BKLDS'
      'fcns:pcpsd'        'PCPSD' 'PKLDS'
      'fcns:listen'        'Listen' 'Anhören'
      'dp:blackbox'       'Number between 100 and 103'  'Zahl zwischen 100 und 103'
      'dt:blackbox'       'Blackbox No.'  'Blackbox Nr.'
      'dt:secondnode'     'Select node'   'Knoten auswählen'
      'dt:selecttau'     'Select tau'   'Tau auswählen'
      'signaltype'  'Signal type'   'Signaltyp'
      'frequency'   'Frequency'     'Frequenz'
      'amplitude'   'Amplitude'     'Amplitude'
      'duty'        'Duty cycle'    'Tastverhältnis'
      'samplingperiod'        'Sampling period'    'Abtastrate'
      'lp', 'LP','TP'
      'plotperiod', 'Plot refresh rate', 'Plotaktualisierungsrate'
      'about',    'About', 'Über'
      'none'        'None'  'Null'
    };
    
  end
  properties (GetAccess = 'public')
    lang = 'de';
    langs = {'en','de'};
  end
  
  methods
    %% Constructor
    function obj = i18n(lang)
      if nargin == 1
        obj.setLang(lang);
      end
    end
    
    %% Set language
    function obj = setLang(obj,l)
      mask = ismember(obj.langs,l);
      if ~any(mask), error('Unknown language'); end
      obj.lang = l;
    end
    
    %% Find translation
    function translatedStr = translate(obj,str,lang)
      
      if nargin == 3, obj.lang = lang; end

      % Find ID of language
      langID = find(ismember(obj.langs,obj.lang))+1;
      if isempty(langID), langID = 3; end

      % Find string in DB
      mask = ismember(obj.DB(:,1),str);

      if sum(mask) == 1
        translatedStr = obj.DB{mask,langID};
      else
        % If string was not found, return first string
        translatedStr = [upper(str(1)),str(2:end)];
        warning(['i18n: Could not find translation for ' str]);
      end
    end
    
    
    %% Overload () operator
    function B = subsref(obj,A)
      switch A(1).type
        case '()'
          B = obj.translate(A.subs{:});
        otherwise
          B = builtin('subsref', obj, A);
          % TODO: check for nargout of function to be called here
      end
    end
  end
end
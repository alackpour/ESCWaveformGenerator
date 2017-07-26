classdef waveform %< threeGPPChannel
    %waveform generator combines radar signal from file and LTE signal
    %  parameters:
    %             Radar,LTE , and AWGN statuses
    %             LTE channel state
    %             freq offsets
    %             additional gains
    % Two modes of operations:
    %                         Dynamic, generate a signal in segments
    %                         Static, generate and save the signal
    %   See also, signalFile, threeGPPChannel
    
    properties
        Fs
        samplesPerSegment
        totalTime
        numRadarSignals      %number of Radar Signals
        radarStatus          logical%radar status
        radarStartTime
        radarSignal          radarSignalFromFile
        radarGain            %Radar gain
        radarFreqOffset      %Radar freq offeset MHz
        numLTESignals
        LTEStatus            logical%vector row logic [LTE1 LTE2]
        LTEStartTime
        LTESignal            signalFromFile
        LTEGain              %LTE gain vector row size numLTESignals
        LTEFreqOffset        %LTE freq offeset vector [f1 f2]
        LTEChState           logical% logical scalar enable disbale 3gpp channel effect
        LTEChType            cell
        LTEChannel           threeGPPChannel
        numABISignals
        ABIStatus            logical% Adjacent Band Interference
        ABIStartTime
        ABISignal            radarSignalFromFile
        ABIGain              %ABI gain
        ABIFreqOffset        %ABI freq offeset MHz
        AWGNStatus           logical%AWGN channel status
        AWGNVar              %noise variance
        writeScaleFactor      %save scale factor
        %        saveWaveformFileId
        waveformToFile       signalToFile
        success
        targetSIR
        SIRdBmin
        SIRdBmax
        SIRdBmean
        SIRData
        signalOut
        errorColl
    end
    
    properties (Access=private)
        saveFileNamePath
    end
    
    methods
        function this=waveform(Fs)
            
            if nargin > 0
                this.Fs=Fs;
            end
        end
        
        function this=set.Fs(this,Fs)
            this.Fs=Fs;
        end
        
        function  this=set.samplesPerSegment(this,samplesPerSegment)
            this.samplesPerSegment=samplesPerSegment;
        end
        
        function this=set.totalTime(this,totalTime)
            this.totalTime=totalTime;
        end
        
        function this=set.numRadarSignals(this,numRadarSignals)
            this.numRadarSignals=numRadarSignals;
        end
        function this=set.numLTESignals(this,numLTESignals)
            this.numLTESignals=numLTESignals;
        end
        function this=set.numABISignals(this,numABISignals)
            this.numABISignals=numABISignals;
        end
        
        function this=set.radarStartTime(this,radarStartTime)
            this.radarStartTime=radarStartTime;
        end
        function this=set.LTEStartTime(this,LTEStartTime)
            this.LTEStartTime=LTEStartTime;
        end
        function this=set.ABIStartTime(this,ABIStartTime)
            this.ABIStartTime=ABIStartTime;
        end
        
        function this=set.targetSIR(this,targetSIR)
            this.targetSIR=targetSIR;
        end
        
        function this=setupRadarSignal(this,radarMeasFiles,radarMetaFile,radarSeekPositionSamples,readScale)
            IQDirection='QI';
            EOFAction='Rzeros';
            if length(radarMeasFiles)~=this.numRadarSignals
                
                error('waveform:RadarSignal',...
                    'Error. \n number radarMeasFiles does not match numRadarSignals');
            end
            
            if nargin<4
                % set default seek position to zero
                radarSeekPositionSamples=zeros(size(1,this.numRadarSignals));
            end
            for I=1:this.numRadarSignals
                this.radarSignal(I)=radarSignalFromFile(radarMeasFiles{I},IQDirection,EOFAction,radarMetaFile);
                this.radarSignal(I).samplesPerSegment=this.samplesPerSegment;
                if nargin>4
                    this.radarSignal(I)=setReadScale(this.radarSignal(I),readScale);
                else
                    this.radarSignal(I)=setReadScale(this.radarSignal(I));
                end
                this.radarSignal(I)=initInputFile(this.radarSignal(I));
                this.radarSignal(I)=setSeekPositionSamples(this.radarSignal(I),radarSeekPositionSamples(I));
                %check if peak file exist for each radar signal
                pksFileName=strcat(radarMeasFiles{I}(1:end-length('dec01.dat')),'pks.mat');
                if  (exist(pksFileName, 'file') == 2)
                    this.SIRData(I).original=load(pksFileName);
                    this.SIRData(I).Bw=2e6;
                    this.SIRData(I).window=1e-3;
                end
%              this.SIRData(I)=readPeaks(radarMeasFiles{I});
            end
            
        end
        
%         function pks=readPeaks(radarMeasFile)
%             
%             pksFileName=strcat(radarMeasFile(1:end-length('dec01.dat')),'pks.mat');
%             if  (exist(pksFileName, 'file') == 2)
%                 pks.original=load(pksFileName);
%                 pks.Bw=2e6;
%                 pks.window=1e-3;
%             else
%                 pks=[];
%             end
%         end
        
        function this=setupABISignal(this,ABIMeasFiles,ABIMetaFile,ABIseekPositionSamples,readScale)
            IQDirection='QI';
            EOFAction='Rzeros';
            if length(ABIMeasFiles)~=this.numABISignals
                
                error('waveform:RadarSignals',...
                    'Error. \n number ABIMeasFiles does not match numABISignals');
            end
            
            if nargin<4
                % set default seek position to zero
                ABIseekPositionSamples=zeros(size(1,this.numABISignals));
            end
            for I=1:this.numABISignals
                this.ABISignal(I)=radarSignalFromFile(ABIMeasFiles{I},IQDirection,EOFAction,ABIMetaFile);
                this.ABISignal(I).samplesPerSegment=this.samplesPerSegment;
                if nargin>4
                    this.ABISignal(I)=setReadScale(this.ABISignal(I),readScale);
                else
                    this.ABISignal(I)=setReadScale(this.ABISignal(I));
                end
                this.ABISignal(I)=initInputFile(this.ABISignal(I));
                this.ABISignal(I)=setSeekPositionSamples(this.ABISignal(I),ABIseekPositionSamples(I));
            end
            
        end
        
        function this=setupLTESignal(this,LTESignalPaths,LTEReadScale,LTEseekPositionSamples)
            %LTEReadScale is the scale applied to the signal read from the file
            %LTEGain is the gain applied to LTE signal while mixing
            %expect a cell array of file names
            IQDirection='IQ';
            if length(LTESignalPaths)~=this.numLTESignals || length(LTEReadScale)~=this.numLTESignals
                
                error('waveform:LTESignal',...
                    'Error. \n number LTESignalPaths and/or LTEReadScale does not match numLTESignals');
            end
            
            if nargin<4
                % set default seek position to zero
                LTEseekPositionSamples=zeros(size(1,this.numLTESignals));
            end
            for I=1:this.numLTESignals
                this.LTESignal(I)=signalFromFile(LTESignalPaths{I},IQDirection);
                this.LTESignal(I).samplesPerSegment=this.samplesPerSegment;
                this.LTESignal(I)=setReadScale(this.LTESignal(I),LTEReadScale(I));
                this.LTESignal(I)=initInputFile(this.LTESignal(I));
                this.LTESignal(I)=setSeekPositionSamples(this.LTESignal(I),LTEseekPositionSamples(I));
            end
        end
        
        function this=setupLTEChannel(this)
            if ~isempty(this.Fs)|| ~isempty(this.numLTESignals) || ~isempty(this.LTEChType)
                if length(this.LTEChType)==this.numLTESignals
                    this.LTEChannel=threeGPPChannel(this.Fs,this.numLTESignals,this.LTEChType);
                    this.LTEChannel=initCh(this.LTEChannel);
                else
                    error('waveform:LTESignal',...
                        'Error. \n length(LTEChType) does not equal numLTESignals');
                end
                
            else
                error('waveform:LTESignal',...
                    'Error. \n One or more variable is not set: Fs , numLTESignals, LTEChType');
            end
        end
        
        function this=updateSamplesPerSegment(this)
            for I=1:this.numLTESignals
                this.LTESignal(I).samplesPerSegment=this.samplesPerSegment;
            end
            
            for I=1:this.numRadarSignals
                this.radarSignal(I).samplesPerSegment=this.samplesPerSegment;
            end
            
            for I=1:this.numABISignals
                this.ABISignal(I).samplesPerSegment=this.samplesPerSegment;
            end
        end
        
        function this=setupWaveformToFile(this,saveFileNamePath)
            this.saveFileNamePath=saveFileNamePath;
            this.waveformToFile=signalToFile(saveFileNamePath,'IQ');
            this.waveformToFile=setWriteScale(this.waveformToFile,this.writeScaleFactor);
            this.waveformToFile=initOutputFile(this.waveformToFile);
        end
        
        function this=setStatus(this,radarStatus,LTEStatus, AWGNStatus)
            this.radarStatus=radarStatus;
            this.LTEStatus=LTEStatus;
            this.AWGNStatus=AWGNStatus;
        end
        function this=set.radarStatus(this,radarStatus)
            this.radarStatus=radarStatus;
        end
        function this=set.LTEStatus(this,LTEStatus)
            this.LTEStatus=LTEStatus;
        end
        function this=set.AWGNStatus(this,AWGNStatus)
            this.AWGNStatus=AWGNStatus;
        end
        
        function this=setFreqOffset(this,radarFreqOffset,LTEFreqOffset,ABIFreqOffset)
            this.radarFreqOffset=radarFreqOffset;
            this.LTEFreqOffset=LTEFreqOffset;
            this.ABIFreqOffset=ABIFreqOffset;
        end
        function this=set.radarFreqOffset(this,radarFreqOffset)
            this.radarFreqOffset=radarFreqOffset;
        end
        function this=set.LTEFreqOffset(this,LTEFreqOffset)
            this.LTEFreqOffset=LTEFreqOffset;
        end
        function this=set.ABIFreqOffset(this,ABIFreqOffset)
            this.ABIFreqOffset=ABIFreqOffset;
        end
        
        function this=setGainVar(this,radarGain,LTEGain,ABIGain,AWGNVar)
            this.radarGain=radarGain;
            this.LTEGain=LTEGain;
            this.ABIGain=ABIGain;
            this.AWGNVar=AWGNVar;
        end
        function this=set.radarGain(this,radarGain)
            this.radarGain=radarGain;
        end
        function this=set.LTEGain(this,LTEGain)
            this.LTEGain=LTEGain;
        end
        function this=set.ABIGain(this,ABIGain)
            this.ABIGain=ABIGain;
        end
        function this=set.AWGNVar(this,AWGNVar)
            this.AWGNVar=AWGNVar;
        end
        
        function waveformsMeta=getWaveformInfo(this,type)
            %two types 'meta', or 'parameters'
            if nargin >1 && strcmp(type,'meta')
                waveformFieldsRemove={'radarSignal','LTESignal','LTEChannel','ABISignal',...
                    'signalOut','waveformToFile','errorColl'};
            elseif nargin >1 && strcmp(type,'parameters')
                waveformFieldsRemove={'radarSignal','LTESignal','LTEChannel','ABISignal',...
                    'signalOut','waveformToFile','errorColl','success','SIRdBmin','SIRdBmax',...
                    'SIRdBmean','SIRData'};
            elseif nargin >1 && strcmp(type,'gains')
                waveformFieldsRemove={'Fs','samplesPerSegment','totalTime','numRadarSignals',...
                    'radarStatus','radarStartTime','radarFreqOffset','numLTESignals','LTEStatus',...
                    'LTEStartTime','LTEFreqOffset','LTEChState','LTEChType','numABISignals',...
                    'ABIStatus','ABIStartTime','ABIFreqOffset','AWGNStatus','targetSIR',...
                    'radarSignal','LTESignal','LTEChannel','ABISignal',...
                    'signalOut','waveformToFile','errorColl','success','SIRdBmin','SIRdBmax',...
                    'SIRdBmean','SIRData'};
            else
                waveformFieldsRemove={};
            end
            
            %waveformsMeta=struct(this);
            %waveformsMeta=rmfield(waveformsMeta,waveformFieldsRemove);
            fldNames=properties(this);
            fldNames=fldNames(~ismember(fldNames,waveformFieldsRemove));
            for I=1:length(fldNames)
                fldValues{I}=this.(fldNames{I});
            end
            waveformsMeta=cell2struct(fldValues',fldNames,1);
        end
        
        function [this,t0,interfBndPowr]=generateWaveformSegment(this,t0,bndPowrStatus,Bw)
            t=t0+(0:this.samplesPerSegment-1).'*1/this.Fs;
            
            LTESigsActive=any(this.LTEStatus);
            radarSigsActive=any(this.radarStatus);
            ABISigsActive=any(this.ABIStatus);
%             for I=1:this.numLTESignals
%                 this.LTESignal(I).samplesPerSegment=this.samplesPerSegment;
%             end
%             for I=1:this.numRadarSignals
%                 this.radarSignal(I).samplesPerSegment=this.samplesPerSegment;
%             end
%             for I=1:this.numABISignals
%                 this.ABISignal(I).samplesPerSegment=this.samplesPerSegment;
%             end
            
            interfBndPowr=nan(this.numRadarSignals,1);
            
            if LTESigsActive
                %preallocate for LTE
                LTESig=complex(zeros(this.samplesPerSegment,this.numLTESignals));
                for I=1:this.numLTESignals
                    if this.LTEStatus(I)
                        LTESigFromFile=readSamples(this.LTESignal(I));
                        LTESigShifted=this.LTEGain(I)*(LTESigFromFile.*exp(1i*(2*pi*this.LTEFreqOffset(I))*t));
                        if this.LTEChState
                            %LTESigCh(:,I)=step(this.LTECh(I).Ch,LTESigShifted);
                            LTESig(:,I)=this.LTEChannel.Ch{I}(LTESigShifted);
                        else
                            LTESig(:,I)=LTESigShifted;
                        end
                        this.LTESignal(I)=seekNextPositionSamples(this.LTESignal(I));
                    end
                end
                LTESigOut=sum(LTESig,2);
            else
                LTESigOut=complex(0,0);
            end
            
            if ABISigsActive
                %preallocate for ABI
                ABISig=complex(zeros(this.samplesPerSegment,this.numABISignals));
                for I=1:this.numABISignals
                    if this.ABIStatus(I)
                        ABISigFromFile=readSamples(this.ABISignal(I));
                        ABISig(:,I)=this.ABIGain(I)*(ABISigFromFile.*exp(1i*(2*pi*this.ABIFreqOffset(I))*t));
                        this.ABISignal(I)=seekNextPositionSamples(this.ABISignal(I));
                    end
                end
                ABISigOut=sum(ABISig,2);
            else
                ABISigOut=complex(0,0);
            end
            
            if this.AWGNStatus
                WGN=sqrt(this.AWGNVar)*(randn(this.samplesPerSegment,1)+1i*randn(this.samplesPerSegment,1))/sqrt(2);
            else
                WGN=complex(zeros(this.samplesPerSegment,1));
            end
            interfNoiseSig=LTESigOut+ABISigOut+WGN;
            if bndPowrStatus
                for I=1:this.numRadarSignals
                    interfBndPowr(I,1)=dspFun.bandPowerC(interfNoiseSig,this.Fs,[this.radarFreqOffset(I)-Bw/2 this.radarFreqOffset(I)+Bw/2]);
                end
            end
            
            if radarSigsActive
                %preallocate for Radar signal
                radarSig=complex(zeros(this.samplesPerSegment,this.numRadarSignals));
                for I=1:this.numRadarSignals
                    if this.radarStatus(I)
                        RadarSigFromFile=readSamples(this.radarSignal(I));
                        radarSig(:,I)=this.radarGain(I)*(RadarSigFromFile.*exp(1i*(2*pi*this.radarFreqOffset(I))*t));
                        this.radarSignal(I)=seekNextPositionSamples(this.radarSignal(I));
                    end
                end
                radarSigOut=sum(radarSig,2);
            else
                %radarSigOut=complex(0,0);
                radarSigOut=complex(zeros(this.samplesPerSegment,1));
            end
            
            this.signalOut=radarSigOut+interfNoiseSig;
            t0=t(end)+1/this.Fs;
        end
        
        
        function [this]=generateFullWaveform(this)
            t0=0;
            NumOfSeg=floor(this.totalTime/(this.samplesPerSegment*1/this.Fs));
            this.totalTime=NumOfSeg*(this.samplesPerSegment*1/this.Fs);
            % radarStartTime length must be equal to number of Radar signals
            if length(this.radarStartTime)~=this.numRadarSignals
                this.errorColl.mixSignal= MException('mixSignal:Initialization', ...
                    'radarStartTime length must equal numRadarSignals');
                throw(this.errorColl.mixSignal);
            end
            % Radar start segment index start from 1
            if ~isempty(this.radarStartTime)
                radarStartSeg=round(this.radarStartTime./(this.samplesPerSegment*1/this.Fs))+1;
            else
                radarStartSeg=ones(1,this.numRadarSignals);
            end
            if ~isempty(this.LTEStartTime)
                LTEStartSeg=round(this.LTEStartTime./(this.samplesPerSegment*1/this.Fs))+1;
            else
                %start LTE from the beginning if not set
                LTEStartSeg=ones(1,this.numLTESignals);
            end
            if ~isempty(this.ABIStartTime)
                ABIStartSeg=round(this.ABIStartTime./(this.samplesPerSegment*1/this.Fs))+1;
            else
                %start ABI from the beginning if not set
                ABIStartSeg=ones(1,this.numABISignals);
            end
            % update to exact radar start time
            this.radarStartTime=((radarStartSeg-1)*this.samplesPerSegment)./this.Fs;
            
            if   ~isempty(this.SIRData) && isfield(this.SIRData,'original')
                calculateSIRFlag=true;
            end
            
            if calculateSIRFlag
                %init vars
                % this.SIRData length must be equal to number of Radar signals
                %Expects: this.SIRData(I).original
                % struct array with fields for each radar I:
                % locs
                % pks
                % Window
                % BW
                if length(this.SIRData)~=this.numRadarSignals
                    this.errorColl.misSignalSIR= MException('mixSignal:SIRInitialization', ...
                        'Peaks must be a vector of structs(pks and locs) with length equal numRadarSignals');
                    throw(this.errorColl.misSignalSIR);
                end
                try
                    %SIRDataf=struct([]);
                    for I=1:this.numRadarSignals
                        %peakLocations(I,:)=this.radarStartTime(I)+SIRpks(I).locs; %adjusted peak location
                        %SIRpks.pks are peak amplitudes
                        %SIRpks.locs location (time) of peaks in the orignal file
                        %SIRpks.BW is the bandwidth to calculate SIR centered at Radar freq offeset (MHz)
                        %SIRpks.Window is the time window to calculate SIR centered peak loc (sec)
                        initialSeek(I)=getSeekPositionSamples(this.radarSignal(I));
                        numberOfPeaks=length(this.SIRData(I).original.locs);
                        this.SIRData(I).numberOfPeaks=numberOfPeaks;
                        %SIRDataf(I).orginalPeaks=SIRpks(I).pks;
                        this.SIRData(I).peakLocations=this.radarStartTime(I)+this.SIRData(I).original.locs-initialSeek(I)*1/this.Fs;%peakLocations(I,:);
                        this.SIRData(I).radarPeakPower=zeros(1,numberOfPeaks);
                        this.SIRData(I).interferencePower=zeros(1,numberOfPeaks);
                        this.SIRData(I).powerCalcLocations=zeros(1,numberOfPeaks);
                        leftOverToNextSeg(I)=0;
                        freqRange(I,:)=[this.radarFreqOffset(I)-this.SIRData(I).Bw/2, this.radarFreqOffset(I)+this.SIRData(I).Bw/2];
                        halfWindowSamp(I)=round((this.SIRData(I).window/(1/this.Fs))/2);
                        forwardLastInterfernceWindow(:,I)=zeros(halfWindowSamp(I)*2,1);
                        %
                    end
                    
                catch errmsg_process
                    this.errorColl.mixSignalSIR=errmsg_process;
                end
            end
            
            LTESigsActive=any(this.LTEStatus);
            ABISigsActive=any(this.ABIStatus);
            radarSigsActive=any(this.radarStatus);
%             for I=1:this.numLTESignals
%                 this.LTESignal(I).samplesPerSegment=this.samplesPerSegment;
%             end
%             
%             for I=1:this.numRadarSignals
%                 this.radarSignal(I).samplesPerSegment=this.samplesPerSegment;
%             end
%             
%             for I=1:this.numABISignals
%                 this.ABISignal(I).samplesPerSegment=this.samplesPerSegment;
%             end
            
            try
                errmsg_process=[];
                for sgmnt=1:NumOfSeg
                    t=t0+(0:this.samplesPerSegment-1).'*1/this.Fs;
                    if LTESigsActive
                        %preallocate for LTE
                        LTESig=complex(zeros(this.samplesPerSegment,this.numLTESignals));
                        for I=1:this.numLTESignals
                            if (this.LTEStatus(I) && sgmnt>=LTEStartSeg(I))
                                LTESigFromFile=readSamples(this.LTESignal(I));
                                LTESigShifted=this.LTEGain(I)*(LTESigFromFile.*exp(1i*(2*pi*this.LTEFreqOffset(I))*t));
                                if this.LTEChState
                                    %LTESigCh(:,I)=step(this.LTECh(I).Ch,LTESigShifted);
                                    LTESig(:,I)=this.LTEChannel.Ch{I}(LTESigShifted);
                                else
                                    LTESig(:,I)=LTESigShifted;
                                end
                                this.LTESignal(I)=seekNextPositionSamples(this.LTESignal(I));
                            end
                        end
                        LTESigOut=sum(LTESig,2);
                    else
                        LTESigOut=complex(0,0);
                    end
                    if ABISigsActive
                        %preallocate for LTE
                        ABISig=complex(zeros(this.samplesPerSegment,this.numABISignals));
                        for I=1:this.numABISignals
                            if (this.ABIStatus(I) && sgmnt>=ABIStartSeg(I))
                                ABISigFromFile=readSamples(this.ABISignal(I));
                                ABISig(:,I)=this.ABIGain(I)*(ABISigFromFile.*exp(1i*(2*pi*this.ABIFreqOffset(I))*t));
                                this.ABISignal(I)=seekNextPositionSamples(this.ABISignal(I));
                            end
                        end
                        ABISigOut=sum(ABISig,2);
                    else
                        ABISigOut=complex(0,0);
                    end
                    
                    
                    if this.AWGNStatus
                        WGN=sqrt(this.AWGNVar)*(randn(this.samplesPerSegment,1)+1i*randn(this.samplesPerSegment,1))/sqrt(2);
                    else
                        WGN=complex(zeros(this.samplesPerSegment,1));
                    end
                    interfNoiseSig=LTESigOut+ABISigOut+WGN;
                    
                    if radarSigsActive
                        %preallocate for Radar signal
                        radarSig=complex(zeros(this.samplesPerSegment,this.numRadarSignals));
                        for I=1:this.numRadarSignals
                            if (this.radarStatus(I) && sgmnt>=radarStartSeg(I))
                                RadarSigFromFile=readSamples(this.radarSignal(I));
                                radarSig(:,I)=this.radarGain(I)*(RadarSigFromFile.*exp(1i*(2*pi*this.radarFreqOffset(I))*t));
                                this.radarSignal(I)=seekNextPositionSamples(this.radarSignal(I));
                                if calculateSIRFlag
                                    %calculate SIR based on peakLocations
                                    %find closest index to peakLocations time
                                    % expects peaks separation is larger
                                    % than segment size and Window
                                    if leftOverToNextSeg(I)>0
                                        % claculate interfernce if peak was close to the end in prev. segment
                                        interfernceWindow=[forwardLastInterfernceWindow((end-leftOverToNextSeg(I)+1):end,I);interfNoiseSig(1:(2*halfWindowSamp(I)-leftOverToNextSeg(I)))];
                                        % disp(['interfernceWindow=',num2str(length(interfernceWindow))])
                                        % disp(['2*halfWindowSamp(I)=',num2str(2*halfWindowSamp(I))])
                                        this.SIRData(I).interferencePower(leftOverToNextSegidx_peaksLocs(I))=dspFun.bandPowerC(interfernceWindow,this.Fs,freqRange(I,:));
                                        % reset leftOverToNextSeg
                                        leftOverToNextSeg(I)=0;
                                        % disp(['leftOverToNextSeg(I)>0interfernceWindow=',num2str(length(interfernceWindow))])
                                    end
                                    
                                    idx_peaksLocs=find(this.SIRData(I).peakLocations>=t(1) & this.SIRData(I).peakLocations<=t(end)); % pulses between start and end of t;
                                    if ~isempty(idx_peaksLocs)
                                        for J=1:length(idx_peaksLocs)
                                            % adjust to the beginning of the segment, and find the peak loc in samples
                                            % while above centerOfPeakSamp gives a close result of peak locs in samples,
                                            % we want to correct this by getting the max closest to previously calculated peak
                                            [peakMag,centerOfPeakSamp]=max(abs(radarSig(:,I)));
                                            startOfPeakWindow=centerOfPeakSamp-halfWindowSamp(I);
                                            endOfPeakWindow=centerOfPeakSamp+halfWindowSamp(I);
                                            this.SIRData(I).powerCalcLocations(idx_peaksLocs(J))=t0+(centerOfPeakSamp*1/this.Fs);
                                            % calculate power of radar at peak location
                                            this.SIRData(I).radarPeakPower(idx_peaksLocs(J))=peakMag^2;
                                            % disp(['this.samplesPerSegment=',num2str(this.samplesPerSegment)]);
                                            % disp(['startOfPeakWindow=',num2str(startOfPeakWindow)]);
                                            % disp(['endOfPeakWindow=',num2str(endOfPeakWindow)]);
                                            if startOfPeakWindow<=0
                                                % use interfernce window from last seg if peak is close to the beginning
                                                interfernceWindow=[forwardLastInterfernceWindow((end+startOfPeakWindow+1):end,I);interfNoiseSig(1:endOfPeakWindow)];
                                                this.SIRData(I).interferencePower(idx_peaksLocs(J))=dspFun.bandPowerC(interfernceWindow,this.Fs,freqRange(I,:));
                                                
                                                % disp(['startOfPeakWindow<=0interfernceWindow=',num2str(length(interfernceWindow))])
                                                % disp(['forwardLastInterfernceWindow((end+startOfPeakWindow+1):end,I)=',num2str(length(forwardLastInterfernceWindow((end+startOfPeakWindow+1):end,I)))])
                                                % disp(['interfNoiseSig(1:endOfPeakWindow)=',num2str(length(interfNoiseSig(1:endOfPeakWindow)))])
                                            elseif endOfPeakWindow>this.samplesPerSegment
                                                leftOverToNextSeg(I)=endOfPeakWindow-this.samplesPerSegment;
                                                leftOverToNextSegidx_peaksLocs(I)=idx_peaksLocs(J);
                                                %interfernceWindow=interfNoiseSig(startOfPeakWindow:end);
                                                %forwardInterfernceWindow(:,I)=interfNoiseSig(1:startOfPeakWindowend);
                                            else
                                                interfernceWindow=interfNoiseSig((startOfPeakWindow+1):endOfPeakWindow);
                                                this.SIRData(I).interferencePower(idx_peaksLocs(J))=dspFun.bandPowerC(interfernceWindow,this.Fs,freqRange(I,:));
                                                % disp(['elseinterfernceWindow=',num2str(length(interfernceWindow))])
                                            end
                                            
                                        end
                                    end
                                    % record last size of window
                                    forwardLastInterfernceWindow(:,I)=interfNoiseSig((end-halfWindowSamp(I)*2+1):end);
                                end
                            end
                            
                        end
                        radarSigOut=sum(radarSig,2);
                    else
                        %radarSigOut=complex(0,0);
                        radarSigOut=complex(zeros(this.samplesPerSegment,1));
                    end
                    % interfNoiseSig=LTESig+WGN;
                    signalOutLocal=radarSigOut+interfNoiseSig;
                    writeSamples(this.waveformToFile,signalOutLocal);
                    t0=t(end)+1/this.Fs;
                    
                end
                
                this=resetSignalFiles(this);
                
                
                if calculateSIRFlag
                    %this.SIRData=SIRDataf;
                    for I=1:this.numRadarSignals
                        %this.SIRData(I).Window=SIRpks(I).Window;
                        this.SIRData(I).FreqRange=freqRange(I,:);
                        this.SIRdBmin(:,I)=10*log10(min(this.SIRData(I).radarPeakPower./this.SIRData(I).interferencePower,[],'omitnan'));
                        this.SIRdBmax(:,I)=10*log10(max(this.SIRData(I).radarPeakPower./this.SIRData(I).interferencePower,[],'omitnan'));
                        this.SIRdBmean(:,I)=10*log10(mean(this.SIRData(I).radarPeakPower./this.SIRData(I).interferencePower,'omitnan'));
                    end
                end
                
                jsonFilePath=strcat(this.saveFileNamePath(1:end-3),'json');
                [SaveJsonFileId,errmsg_write_json]=fopen(jsonFilePath,'w','n','UTF-8');
                waveformMeta=getWaveformInfo(this,'meta');
                if isempty(errmsg_write_json)
                    fwrite(SaveJsonFileId,jsonencode(waveformMeta),'char');
                else
                    this.errorColl.WaveFormWriteJson=errmsg_write_json;
                end
            catch errmsg_process
                this.errorColl.mixSignal=errmsg_process;
            end
            %end
            %if isempty(errmsg_write) && isempty(errmsg_process)
            
            if  isempty(errmsg_process)
                this.success.flag=true;
                
            else
                this.success.flag=false;
                this.success.message='Failed to generate';  
            end
        end
        
        
        function this=estimateGainsFromTargetSIR(this)
            % estimate and set radarGain, LTEgain, ABIgain, and writeScaleFactor
            samplesPerSegmentF=this.samplesPerSegment;
            tempSamplesPerSegment=round(this.SIRData(1).window/(1/this.Fs));
            t=1/this.Fs*(0:(tempSamplesPerSegment-1)).';
            this.samplesPerSegment=tempSamplesPerSegment;
            
            %disable LTE channel state
            tempLTEChstate=this.LTEChState;
            this.LTEChState=false;
            
            this=updateSamplesPerSegment(this);
            for I=1:this.numRadarSignals
                %first estimate noise power, needs pks and locs
                [ this.radarSignal(I),sigma_w2(I,1),medianPeak(I,1),noiseEst(:,I),maxPeak(I,1),maxPeakLoc(I)]=estimateRadarNoise(this.radarSignal(I), this.Fs,this.SIRData(I).original);
                % save current seek position
                currentRadarSeekPosisionSamples(I)=getSeekPositionSamples(this.radarSignal(I));
                % find location of max peak
                %[~,maxPksIndx(I)]=max(this.SIRData(I).original.pks);
                % half 1msec (window) from each side
                %approxCenterOfPeaks(I)=(this.SIRData(I).original.locs(maxPksIndx(I))-this.SIRData(I).window)/(1/Fs);
                peakSeekPositionSamples(I)=(maxPeakLoc(I)-this.SIRData(I).window/2)/(1/this.Fs);
                this.radarSignal(I)=setSeekPositionSamples(this.radarSignal(I), peakSeekPositionSamples(I));
                radarSignalData(:,I) =double(this.radarStatus(I))*readSamples(this.radarSignal(I)).*exp(1i*2*pi*this.radarFreqOffset(I)*t);
                this.radarSignal(I)=setSeekPositionSamples(this.radarSignal(I),  currentRadarSeekPosisionSamples(I));
            end
            
            for I=1:this.numLTESignals
                currentLTESeekPosisionSamples(I)=getSeekPositionSamples(this.LTESignal(I));
                LTESignalData(:,I) =double(this.LTEStatus(I))*readSamples(this.LTESignal(I)).*exp(1i*2*pi*this.LTEFreqOffset(I)*t);
                this.LTESignal(I)=setSeekPositionSamples(this.LTESignal(I),  currentLTESeekPosisionSamples(I));
            end
            
            for I=1:this.numABISignals
                currentABISeekPosisionSamples(I)=getSeekPositionSamples(this.ABISignal(I));
                ABISignalData(:,I) =double(this.ABIStatus(I))*readSamples(this.ABISignal(I)).*exp(1i*2*pi*this.ABIFreqOffset(I)*t);
                this.ABISignal(I)=setSeekPositionSamples(this.ABISignal(I),  currentABISeekPosisionSamples(I));
            end
            
            P_KTB_dB=-174-30;
            peakPowerThreshold_dB=-89-30;%-119 dB
            
            noisePSD_dB=pow2db(sigma_w2./this.Fs);
            medianPeakPowOrig_dB=pow2db((medianPeak).^2);
            
            
            noisePowAdjustfactor=ones(this.numRadarSignals,1);
            noiseAdjustfactor_dB=P_KTB_dB-noisePSD_dB;
            noisePowAdjustfactor(noiseAdjustfactor_dB<0)=db2pow(noiseAdjustfactor_dB(noiseAdjustfactor_dB<0));
            noiseVolAdjustfactor=sqrt(noisePowAdjustfactor);
            peakPowAdjustfactor=db2pow(peakPowerThreshold_dB-medianPeakPowOrig_dB);
            peakVolAdjustfactor=sqrt(peakPowAdjustfactor);
            rdrGainLowUpVol=[peakVolAdjustfactor,noiseVolAdjustfactor];
            
            % nedd to make sure that peakVolAdjustfactor<noiseVolAdjustfactor otherwise
            % either don't use this waveform or set it to noiseVolAdjustfactor
            RDRSig=(rdrGainLowUpVol(:,2).').*radarSignalData;
            
            %
            dBMin=3;
            dBMax=6;
            LTEBandwidth=10e6;
            avrgLTEPSD=pow2db(mean(abs(LTESignalData).^2,1).'/LTEBandwidth);
            LTEGainsAboveKTB=randi([dBMin,dBMax],2,1);
            LTEGainsPow=db2pow((P_KTB_dB+LTEGainsAboveKTB)-avrgLTEPSD);
            LTEGainsVol=sqrt(LTEGainsPow);
            % in case of LTEStatus is 0, check for inf and set the gain to zero
            LTEGainsVol(isinf(LTEGainsVol))=0;
            LTESig=(LTEGainsVol.').*LTESignalData;
            
            SIRtargetNum=db2pow(this.targetSIR);
            
            %this needs to be corrected according to ADCscale (i.e. for each ADCscale the noise floor is the same)
            % should result to noise floor of ABI signals at KTB
            %ABIGainsVol=rdrGainLowUpVol(2,2)*ones(this.numABISignals,1);
            ABIGainsVol=rdrGainLowUpVol(2,2)*double(this.ABIStatus).';
            ABISig=(ABIGainsVol.').*ABISignalData;
            
            % set awgn var at KTB
            AWGNVarF=db2pow(P_KTB_dB)*this.Fs;
            WGN=double(this.AWGNStatus)*sqrt(AWGNVarF)*(randn(this.samplesPerSegment,1)+1i*randn(this.samplesPerSegment,1))/sqrt(2);
            
            yI=sum(LTESig,2)+sum(ABISig,2)+WGN;
            
            freqRange=[this.radarFreqOffset(1)-this.SIRData(1).Bw/2 this.radarFreqOffset(1)+this.SIRData(1).Bw/2];
            GI=sqrt(max(abs(RDRSig(:,1)))^2/(SIRtargetNum*dspFun.bandPowerC(yI,this.Fs,freqRange)));
            
            yIGI=GI*yI;
            GR2nd=ones(this.numRadarSignals,1);
            %GR2nd=this.radarStatus.';
            for I=2:this.numRadarSignals
                freqRange=[this.radarFreqOffset(I)-this.SIRData(I).Bw/2 this.radarFreqOffset(I)+this.SIRData(I).Bw/2];
                GR2nd(I)=double(this.radarStatus(I))*sqrt((SIRtargetNum*dspFun.bandPowerC(RDRSig(:,1)+yIGI,this.Fs,freqRange))/max(abs(RDRSig(:,I)))^2);
            end

            radarGainF=rdrGainLowUpVol(:,2).*GR2nd;
            radarGainF(isnan(radarGainF))=0;
            LTEGainF=GI*LTEGainsVol;
            LTEGainF(isnan(LTEGainF))=0;
            ABIGainF=GI*ABIGainsVol;
            ABIGainF(isnan(ABIGainF))=0;
            AWGNVarF=GI^2*AWGNVarF*this.AWGNStatus;
            AWGNVarF(isnan(AWGNVarF))=0;
            WGN=this.AWGNStatus*sqrt(AWGNVarF)*(randn(this.samplesPerSegment,1)+1i*randn(this.samplesPerSegment,1))/sqrt(2);
           
            %sigPInterf1=RDRSig(:,1)+yIGI+GR2nd(2)*RDRSig(:,2);
            sigPInterf=sum((radarGainF.').*radarSignalData,2)+sum((LTEGainF.').*LTESignalData,2)+sum((ABIGainF.').*ABISignalData,2)+WGN; % this should be equal to sigPInterf
            %sum(sigPInterf-sigPInterf1)
            
%             %scale by average PSD
%             avrgPSD=mean(abs(sigPInterf).^2)/this.Fs;
%             constPSD=-130-30;
%             constMultiply=sqrt(db2pow(constPSD)/avrgPSD);
            
            %scale by peaks>> min(median for each radar) >>-89 db
            refLoad=50;
            meadianPeakPowMinus89dBm=db2pow(peakPowerThreshold_dB-(min(pow2db((radarGainF.*medianPeak).^2))-pow2db(refLoad)));
            constMultiply=sqrt(meadianPeakPowMinus89dBm);
            
            radarGainF=constMultiply*radarGainF;
            LTEGainF=constMultiply*LTEGainF;
            ABIGainF=constMultiply*ABIGainF;
            AWGNVarF=constMultiply^2*AWGNVarF;
            sigPInterf=constMultiply*sigPInterf;

            minINT16=double(intmin('int16'));
            maxINT16=double(intmax('int16'));
            boundGuarddBMag=20;
            minData=min(min(real(sigPInterf),min(imag(sigPInterf))));
            maxData=max(max(real(sigPInterf),max(imag(sigPInterf))));
            scaleFactor=min(maxINT16/(maxData*db2mag(boundGuarddBMag)),minINT16/(minData*db2mag(boundGuarddBMag)));
            % round to lowest order of 10\times half number of integer digits
            numDigits=numel(num2str(floor(scaleFactor)));
            halfNumDigits=floor(numDigits/2);
            scaleFactor=floor(scaleFactor/(10^halfNumDigits))*(10^halfNumDigits);
            
            %restore samples per segment value
            this.samplesPerSegment=samplesPerSegmentF;
            this=updateSamplesPerSegment(this);
            %restore LTE channel state
            this.LTEChState=tempLTEChstate;
            %set gain value
            %expects row vectors
            this=setGainVar(this,radarGainF.',LTEGainF.',ABIGainF.',AWGNVarF);
            this.writeScaleFactor=scaleFactor;
            
            
            
        end
        
        function this=resetSignalFiles(this)
            if ~isempty(this.waveformToFile)
                this.waveformToFile=resetSignalToFile(this.waveformToFile);
            end
            
            if ~isempty(this.radarSignal)
                for I=1:this.numRadarSignals
                    this.radarSignal(I)=resetSignalFromFile(this.radarSignal(I));
                end
            end
            
            if ~isempty(this.LTESignal)
                for I=1:this.numLTESignals
                    this.LTESignal(I)=resetSignalFromFile(this.LTESignal(I));
                end
            end
            
            if ~isempty(this.ABISignal)
                for I=1:this.numABISignals
                    this.ABISignal(I)=resetSignalFromFile(this.ABISignal(I));
                end
            end
        end
        
    end
end


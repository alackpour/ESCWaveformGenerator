...%% Legal Disclaimer
...% NIST-developed software is provided by NIST as a public service. 
...% You may use, copy and distribute copies of the software in any medium,
...% provided that you keep intact this entire notice. You may improve,
...% modify and create derivative works of the software or any portion of
...% the software, and you may copy and distribute such modifications or
...% works. Modified works should carry a notice stating that you changed
...% the software and should note the date and nature of any such change.
...% Please explicitly acknowledge the National Institute of Standards and
...% Technology as the source of the software.
...% 
...% NIST-developed software is expressly provided "AS IS." NIST MAKES NO
...% WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY
...% OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY
...% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
...% AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS THAT THE
...% OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, OR
...% THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY 
...% REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS 
...% THEREOF, INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY,
...% RELIABILITY, OR USEFULNESS OF THE SOFTWARE.
...% 
...% You are solely responsible for determining the appropriateness of
...% using and distributing the software and you assume all risks
...% associated with its use, including but not limited to the risks and
...% costs of program errors, compliance with applicable laws, damage to 
...% or loss of data, programs or equipment, and the unavailability or
...% interruption of operation. This software is not intended to be used in
...% any situation where a failure could cause risk of injury or damage to
...% property. The software developed by NIST employees is not subject to
...% copyright protection within the United States.
classdef waveformGenerator<executor
    %REWRITE using executor
    %   Detailed explanation goes here
    
    properties
        %waveforms              waveform
        waveformsMap
        shortFile              logical
    end
    
    methods
        % construct waveforms objects numFiles
        % estimate variables for SIRdB
        % set variables
        % start parallel%%%done
        % run serial
        % run parallel
        function this=waveformGenerator(numFiles)
            this=this@executor(numFiles);
            %this.waveforms(1:numFiles,1)=waveform;
        end
        
        
        
        function this=initRadarWaveforms(this)
            %setup Radar signals for all files
        end
        
        function this=initLTEWaveforms(this)
            %setup LTE signals  and channels for all files
        end
        
        function this=initABIWaveforms(this)
            %setup ABI signals for all files
        end
        
        function this=initWaveformOutputFiles(this)
            %setup output files for all waveforms
        end
        
        function varMat=createVar(this,fixedVar,methodVar,boundsVar,stepVar)
            
            switch methodVar
                case 'Fix'
                    varMat=repmat(fixedVar,[this.numFiles,1]);
                case 'Random'
                    varMat=randi(boundsVar.',this.numFiles,1);
                case 'Vary'
                    var1=(boundsVar(1):stepVar:boundsVar(2)).';
                    numRepeat=ceil(this.numFiles/length(var1));
                    varMat=repmat(var1,numRepeat,1);
                    varMat=varMat(1:this.numFiles,:);
            end
        end
        
        function filePaths=getFilePaths(this,directoryName,fileType)
            fileTypes={'LTE','radarOne','radarThree','radarOnePeaks'};
            radarCodeTable=cell2table({...
                '00', 'No radar';...
                '01', 'Only Radar 1';...
                '02', '1st of 2 Radar 1';...
                '03', '2nd of 2 Radar 1';...
                '04', 'Radar 3, section 1';...
                '05', 'Radar 3, section 2';...
                '06', 'Radar 3, section 3';...
                '07', 'Radar 3, section 4';...
                '08', 'Radar 3, section 5';...
                },'VariableNames',{'radarCode','codeDescription'});
            % LTE files in separate dir, all radar files and radarone peaks in one dir
            switch fileType
                case fileTypes{1}
                    EXT='dat';
                    extSearch=strcat('*.',EXT);
                    dirSearch=fullfile(directoryName,extSearch);
                    dr = dir(dirSearch);
                case fileTypes{2}
                    EXT='dat';
                    dr=[];
                    for I=2:4
                        extSearch=strcat('*',radarCodeTable.('radarCode'){I},'.',EXT);dirSearch=fullfile(directoryName,extSearch);
                        dr = [dr; dir(dirSearch)];
                    end
                case fileTypes{3}
                    EXT='dat';
                    dr=[];
                    for I=5:9
                        extSearch=strcat('*',radarCodeTable.('radarCode'){I},'.',EXT);dirSearch=fullfile(directoryName,extSearch);
                        dr = [dr; dir(dirSearch)];
                    end
                case fileTypes{4}
                    EXT='mat';
                    extSearch=strcat('*pks.',EXT);
                    dirSearch=fullfile(directoryName,extSearch);
                    dr = dir(dirSearch);
                otherwise
                    error('waveformGenerator:getFilePaths',...
                        'Error. \n Select appropriate file type');
            end
            if ~isempty(dr)
                for f_in=1:length(dr)
                    file_name_cell{f_in}= dr(f_in).name;
                end
                file_name_cell=utilFun.sortByNumbers(file_name_cell);
                for f_in=1:length(dr)
                    filePaths{f_in,1}= fullfile(directoryName,file_name_cell{f_in});
                end
            else
                error('waveformGenerator:getFilePaths',...
                    'Error. \n Input directory is empty');
            end
        end
        
        function radarOneSNR=estimateRadarOneSNR(this,Fs,radarFileSources,radarMetaFile,radarFilePeaks)
            segTime=1e-3;
            samplesPerSegment=round(segTime/(1/Fs));
            radarMeasFilesAllTrim = cellfun(@(x) x(1:end-length('_dec01.dat')), radarFileSources, 'un', 0);
            radarFilePeaksTrim = cellfun(@(x) x(1:end-length('_pks.mat')), radarFilePeaks, 'un', 0);
            [radarHavePeakFile,radarIndx]=ismember(radarMeasFilesAllTrim ,radarFilePeaksTrim);
            %isRadarOne=false(length(radarMeasFilesAll),1);
            J=0;
            for I=1:length(radarFileSources)%I=1:length(files)
                %radarCode=str2double(radarMeasFilesAll{I}(end-length('00.dat')+1:end-length('.dat')));
                % if ismember(radarCode,[1,2,3])
                if  radarHavePeakFile(I)
                    %peakFilePath=[radarMeasFilesAll{I}(1:(end-length('dec01.dat'))),'pks.mat'];
                    J=J+1;
                    radarPeaks=load(radarFilePeaks{radarIndx(I)});
                    testNoise=radarSignalFromFile(radarFileSources{I},'QI','Rnormal');
                    testNoise.samplesPerSegment=samplesPerSegment;
                    testNoise=setRadarMetaFile(testNoise,radarMetaFile);
                    testNoise=setReadScale(testNoise);
                    testNoise=initInputFile(testNoise);
                    [testNoise,~,medianPeak,noiseEst,maxPeak,~]=estimateRadarNoise(testNoise,Fs,radarPeaks);
                    testNoise=resetSignalFromFile(testNoise);
                    
                    SNRMax(J,1)=pow2db(maxPeak^2/dspFun.bandPowerfiltC(noiseEst,Fs,[0-1e6 0+1e6]));
                    SNRMedian(J,1)=pow2db(medianPeak^2/dspFun.bandPowerfiltC(noiseEst,Fs,[0-1e6 0+1e6]));
                end
            end
            radarFileSources=radarFileSources(radarHavePeakFile);
            %radarOneSNR=table(radarMeasFilesAll(isRadarOne),SNROrigMaxALL, SNROrigMedianALL);
            radarOneSNR=table(radarFileSources,SNRMax, SNRMedian);
            radarOneSNR = sortrows(radarOneSNR,{'SNRMedian','SNRMax'},'descend');
            
        end
        
        function this=initWaveformsMap(this,genParameters)
            
            %assign parameters from waveformsMap to waveform objects
            %'FilePath','FileSource','Fs','ADCScale','SPN43FcMHz','Radar3Present','SensorSaturation',...
            %'SPN432ndInstanceFcMHz','Antenna','SPN43PeakPowerdBm','LOMHz','ReferenceLeveldBm'
%             this.useParallel= genParameters.SignalMulti.UseParallel;
%             this.NumWorkers=genParameters.SignalMulti.NumberOfWorkers;
           try
            this.shortFile=genParameters.Signal.ShortFile;
            radarStartTimeMat=[createVar(this,genParameters.Signal.StartTime.Radar1,genParameters.SignalMulti.Method.Radar1StartTime,...
                genParameters.SignalMulti.Bounds.Radar1StartTime,genParameters.SignalMulti.Step.Radar1StartTime),...
                createVar(this,genParameters.Signal.StartTime.Radar2,genParameters.SignalMulti.Method.Radar2StartTime,...
                genParameters.SignalMulti.Bounds.Radar2StartTime,genParameters.SignalMulti.Step.Radar2StartTime)];
            
            ABIStartTimeMat=createVar(this,genParameters.Signal.StartTime.ABI,genParameters.SignalMulti.Method.ABIStartTime,...
                genParameters.SignalMulti.Bounds.ABIStartTime,genParameters.SignalMulti.Step.ABIStartTime);
            
            LTEStartTimeMat=[createVar(this,genParameters.Signal.StartTime.LTE1,'Fix',[0,0],0),...
                createVar(this,genParameters.Signal.StartTime.LTE2,'Fix',[0,0],0)];
            
            radarFreqOffsetMat=[createVar(this,genParameters.Signal.FrequencyOffset.Radar1,genParameters.SignalMulti.Method.Radar1Frequency,...
                genParameters.SignalMulti.Bounds.Radar1Frequency,genParameters.SignalMulti.Step.Radar1Frequency),...
                createVar(this,genParameters.Signal.FrequencyOffset.Radar2,genParameters.SignalMulti.Method.Radar2Frequency,...
                genParameters.SignalMulti.Bounds.Radar2Frequency,genParameters.SignalMulti.Step.Radar2Frequency)];
            
            ABIFreqOffsetMat=createVar(this,genParameters.Signal.FrequencyOffset.ABI,genParameters.SignalMulti.Method.ABIFrequency,...
                genParameters.SignalMulti.Bounds.ABIFrequency,genParameters.SignalMulti.Step.ABIFrequency);
            
            LTEFreqOffsetMat=[createVar(this,genParameters.Signal.FrequencyOffset.LTE1,'Fix',[0,0],0),...
                createVar(this,genParameters.Signal.FrequencyOffset.LTE2,'Fix',[0,0],0)];
            
            targetSIRMat=createVar(this,genParameters.Signal.TargetSIR,genParameters.SignalMulti.Method.TargetSIR,...
                genParameters.SignalMulti.Bounds.TargetSIR,genParameters.SignalMulti.Step.TargetSIR);
            ThreeGPPChTypes=get3GPPTypes(threeGPPChannel);
            switch genParameters.SignalMulti.Method.LTEChannelType
                case 'Fix'
                    LTEChannelTypeMat=repmat(struct2cell(genParameters.Signal.LTEChannelType).',[this.numFiles,1]);
                case 'Random'
                    indx=randi([1,length(ThreeGPPChTypes)],this.numFiles,genParameters.Signal.numLTESignals);
                    LTEChannelTypeMat=ThreeGPPChTypes(indx);
                case 'Vary'
                    var1=(1:length(ThreeGPPChTypes)).';
                    numRepeat=ceil(this.numFiles/length(var1));
                    indx=repmat(var1,numRepeat,genParameters.Signal.numLTESignals);
                    indx=indx(1:this.numFiles,:);
                    LTEChannelTypeMat=ThreeGPPChTypes(indx);
            end
            
            parameterNames=fields(getWaveformInfo(waveform,'parameters')); % get availeble parmaters from wavefroms
            signalSourceDest={'radarSignalSource';'radarFileMeta';'LTESignalSource';'ABISignalSource';'waveformPath';...
                'ManualRadarReadScale'; 'RadarReadScale'; 'LTEReadScaleFactor'};
            allParameters=[parameterNames;signalSourceDest];
            this.waveformsMap=cell(this.numFiles,1);
            samplesPerSegment=round(genParameters.Signal.('SegmentProcessTime')*genParameters.Signal.('Fs'));
            
            radarFileSources=getFilePaths(this,genParameters.Signal.Source.Path.RadarDir,'radarOne');
            radarFilePeaks=getFilePaths(this,genParameters.Signal.Source.Path.RadarDir,'radarOnePeaks');
            ABIFileSources=getFilePaths(this,genParameters.Signal.Source.Path.RadarDir,'radarThree');
            LTEFileSources=getFilePaths(this,genParameters.Signal.Source.Path.LTEDir,'LTE');
            %assignin('base','radarMeasFilesAll',radarFileSources)
            %assignin('base','radarFilePeaks',radarFilePeaks)
            radarOneSNR=estimateRadarOneSNR(this,genParameters.Signal.('Fs'),radarFileSources,genParameters.Signal.Source.Path.radarMetaFile,radarFilePeaks);
            %assignin('base','radarOneSNR',radarOneSNR)
            SNRMedianLow=45;
            SNRMedianHigh=70;
            radarFileSourcesSelect=radarOneSNR.radarFileSources((radarOneSNR.('SNRMedian')>SNRMedianLow & radarOneSNR.('SNRMedian')<SNRMedianHigh));
 
            numDigits=numel(num2str(this.numFiles));
            waveformFileNameFormat=strcat('%0',num2str(numDigits),'d');
            for I=1:this.numFiles
                this.waveformsMap{I}=containers.Map(allParameters,cell(1,length(allParameters)));
                this.waveformsMap{I}('Fs')=genParameters.Signal.('Fs');
                this.waveformsMap{I}('samplesPerSegment')=samplesPerSegment;
                this.waveformsMap{I}('totalTime')=genParameters.Signal.('TotalProcessTime');
                this.waveformsMap{I}('numRadarSignals')=genParameters.Signal.('numRadarSignals');
                this.waveformsMap{I}('radarStatus')=[genParameters.Signal.Status.Radar1 genParameters.Signal.Status.Radar2];
                this.waveformsMap{I}('radarStartTime')=radarStartTimeMat(I,:);
                this.waveformsMap{I}('radarGain')=[genParameters.Signal.Gain.Radar1 genParameters.Signal.Gain.Radar2];% will be modified from gain estimation function;
                this.waveformsMap{I}('radarFreqOffset')=radarFreqOffsetMat(I,:);
                this.waveformsMap{I}('numLTESignals')=genParameters.Signal.('numLTESignals');
                this.waveformsMap{I}('LTEStatus')=[genParameters.Signal.Status.LTE1 genParameters.Signal.Status.LTE2];
                this.waveformsMap{I}('LTEStartTime')=LTEStartTimeMat(I,:);
                this.waveformsMap{I}('LTEGain')=[genParameters.Signal.Gain.LTE1 genParameters.Signal.Gain.LTE2];% will be modified from gain estimation function;
                this.waveformsMap{I}('LTEFreqOffset')=LTEFreqOffsetMat(I,:);
                this.waveformsMap{I}('LTEChState')=genParameters.Signal.LTEChannelStatus;
                this.waveformsMap{I}('LTEChType')=LTEChannelTypeMat(I,:);
                this.waveformsMap{I}('numABISignals')=genParameters.Signal.('numABISignals');
                this.waveformsMap{I}('ABIStatus')=genParameters.Signal.Status.ABI;
                this.waveformsMap{I}('ABIStartTime')=ABIStartTimeMat(I,:);
                this.waveformsMap{I}('ABIGain')=genParameters.Signal.Gain.ABI;% will be modified from gain estimation function;
                this.waveformsMap{I}('ABIFreqOffset')=ABIFreqOffsetMat(I,:);
                this.waveformsMap{I}('AWGNStatus')=genParameters.Signal.AWGNStatus;
                this.waveformsMap{I}('AWGNVar')=genParameters.Signal.('AWGNVariance');% will be modified from gain estimation function;
                this.waveformsMap{I}('writeScaleFactor')=genParameters.Signal.('WriteScaleFactor'); % will be modified from gain estimation function;               
                
                this.waveformsMap{I}('gainEstimateMethod')=genParameters.Signal.GainMethod;
                this.waveformsMap{I}('PowerLevels_dBm')=genParameters.Signal.PowerLevels_dBm;
                this.waveformsMap{I}('targetSIR')=targetSIRMat(I);
                this.waveformsMap{I}('measParameters')=genParameters.Signal.measParameters;
                
                this.waveformsMap{I}('waveformPath')=fullfile(genParameters.Signal.Destination.Path,...
                    strcat(genParameters.Signal.Destination.FileNamePrefix,sprintf(waveformFileNameFormat,I),'.dat'));
                % select source files
                %selectFileIndx=randi([1,length(radarFileSourcesSelect)],genParameters.Signal.('numRadarSignals'),1);
                selectFileIndx=randperm(length(radarFileSourcesSelect),genParameters.Signal.('numRadarSignals'));
                this.waveformsMap{I}('radarSignalSource')=radarFileSourcesSelect(selectFileIndx);
                this.waveformsMap{I}('radarFileMeta')=genParameters.Signal.Source.Path.radarMetaFile;
                %selectFileIndx=randi([1,length(LTEFileSources)],genParameters.Signal.('numLTESignals'),1);
                selectFileIndx=randperm(length(LTEFileSources),genParameters.Signal.('numLTESignals'));
                this.waveformsMap{I}('LTESignalSource')=LTEFileSources(selectFileIndx);
                %selectFileIndx=randi([1,length(ABIFileSources)],genParameters.Signal.('numABISignals'),1);
                selectFileIndx=randperm(length(ABIFileSources),genParameters.Signal.('numABISignals'));
                this.waveformsMap{I}('ABISignalSource')=ABIFileSources(selectFileIndx);
                this.waveformsMap{I}('ManualRadarReadScale')=genParameters.Signal.('ManualRadarReadScale');
                this.waveformsMap{I}('RadarReadScale')=genParameters.Signal.('RadarReadScale');
                this.waveformsMap{I}('LTEReadScaleFactor')=genParameters.Signal.('LTEReadScaleFactor');
            end
            
           catch ME
               this.ERROR.initWaveformsMap=ME;
           end
            
         %assignin('base','initwaveformsMap',this.waveformsMap);  
            
        end
        
        function waveformsObj=setupWaveforms(this)
            fclose('all');
            waveformsObj(1:this.numFiles,1)=waveform;
            for I=1:this.numFiles
                waveformsObj(I).('Fs')=this.waveformsMap{I}('Fs');
                waveformsObj(I).('samplesPerSegment')=this.waveformsMap{I}('samplesPerSegment');
                waveformsObj(I).('totalTime')=this.waveformsMap{I}('totalTime');
                waveformsObj(I).('numRadarSignals')=this.waveformsMap{I}('numRadarSignals');
                waveformsObj(I).('radarStatus')=this.waveformsMap{I}('radarStatus');
                waveformsObj(I).('radarStartTime')=this.waveformsMap{I}('radarStartTime');
                waveformsObj(I).('radarGain')=this.waveformsMap{I}('radarGain');
                waveformsObj(I).('radarFreqOffset')=this.waveformsMap{I}('radarFreqOffset');
                waveformsObj(I).('numLTESignals')=this.waveformsMap{I}('numLTESignals');
                waveformsObj(I).('LTEStatus')=this.waveformsMap{I}('LTEStatus');
                waveformsObj(I).('LTEStartTime')=this.waveformsMap{I}('LTEStartTime');
                waveformsObj(I).('LTEGain')=this.waveformsMap{I}('LTEGain');
                waveformsObj(I).('LTEFreqOffset')=this.waveformsMap{I}('LTEFreqOffset');
                waveformsObj(I).('LTEChState')=this.waveformsMap{I}('LTEChState');
                waveformsObj(I).('LTEChType')=this.waveformsMap{I}('LTEChType');
                waveformsObj(I).('numABISignals')=this.waveformsMap{I}('numABISignals');
                waveformsObj(I).('ABIStatus')=this.waveformsMap{I}('ABIStatus');
                waveformsObj(I).('ABIStartTime')=this.waveformsMap{I}('ABIStartTime');
                waveformsObj(I).('ABIGain')=this.waveformsMap{I}('ABIGain');
                waveformsObj(I).('ABIFreqOffset')=this.waveformsMap{I}('ABIFreqOffset');
                waveformsObj(I).('AWGNStatus')=this.waveformsMap{I}('AWGNStatus');
                waveformsObj(I).('AWGNVar')=this.waveformsMap{I}('AWGNVar');
                waveformsObj(I).('writeScaleFactor')=this.waveformsMap{I}('writeScaleFactor');
                waveformsObj(I).('gainEstimateMethod')=this.waveformsMap{I}('gainEstimateMethod');
                waveformsObj(I).('PowerLevels_dBm')=this.waveformsMap{I}('PowerLevels_dBm');
                waveformsObj(I).('targetSIR')=this.waveformsMap{I}('targetSIR');
                waveformsObj(I).('measParameters')=this.waveformsMap{I}('measParameters');
                % setup file sources is initiated in the generation process
                % because parfor looses file ids
            end
        end
        
        function [this,waveformsObj]=executeSequential(this)
            %generate signals sequentially
            waveformsObj=setupWaveforms(this);
%             forwardToMaxPeakFlag=this.shortFile;
            try            
                for I=1:this.numFiles
                    waveformsObjElement=waveformsObj(I);
                    waveformsMapElement=this.waveformsMap{I};
                    waveformsObj(I)=generateWaveform(this,waveformsObjElement,waveformsMapElement);
                end
                
                this=updateWaveformMapGains(this,waveformsObj);
                saveWaveformMetaToJSON(this);
            
            catch ME
                this.ERROR.sequentialGen=ME;
            end
            
        end
        
        function [this,waveformsObj]=executeParallel(this)
            %generate signals in parallel
            waveformsObj=setupWaveforms(this);
%             forwardToMaxPeakFlag=this.shortFile;
            try
                parfor I=1:this.numFiles
                    waveformsObjElement=waveformsObj(I);
                    waveformsMapElement=this.waveformsMap{I};
                    waveformsObj(I)=generateWaveform(this,waveformsObjElement,waveformsMapElement);
                    
                end
                this=updateWaveformMapGains(this,waveformsObj);
                saveWaveformMetaToJSON(this);
            
            catch ME
                this.ERROR.parallelGen=ME;
            end
            
        end
        
        function saveWaveformMetaToJSON(this)
            [saveDir,fileName]=fileparts(this.waveformsMap{1}('waveformPath'));
            numDigits=numel(num2str(this.numFiles));
            jsonMapFilePath=fullfile(saveDir,strcat(fileName(1:end-numDigits),'WaveformMap.json'));
            waveformMapJSON=jsonencode(this.waveformsMap);
            [SaveJsonFileId,errmsg_write_json]=fopen(jsonMapFilePath,'w','n','UTF-8');
            fwrite(SaveJsonFileId,waveformMapJSON,'char');
        end
        
        function waveformsObjElement=generateWaveform(this,waveformsObjElement,waveformsMapElement) %TODO reorg code
            waveformsObjElement=setupLTEChannel(waveformsObjElement);
            waveformsObjElement=setupLTESignal(waveformsObjElement, waveformsMapElement('LTESignalSource')...
                ,waveformsMapElement('LTEReadScaleFactor')*ones(1,waveformsMapElement('numLTESignals')),...
                zeros(1,waveformsMapElement('numLTESignals')));
            
            if ~waveformsMapElement('ManualRadarReadScale')
                waveformsObjElement=setupRadarSignal(waveformsObjElement,waveformsMapElement('radarSignalSource'),...
                    waveformsMapElement('radarFileMeta'),zeros(1,waveformsMapElement('numRadarSignals')));
                waveformsObjElement=setupABISignal( waveformsObjElement,waveformsMapElement('ABISignalSource'),...
                    waveformsMapElement('radarFileMeta'),zeros(1,waveformsMapElement('numABISignals')));
            else
                waveformsObjElement=setupRadarSignal(waveformsObjElement,waveformsMapElement('radarSignalSource'),...
                    waveformsMapElement('radarFileMeta'),zeros(1,waveformsMapElement('numRadarSignals')),...
                    waveformsMapElement('RadarReadScale')*ones(1,waveformsMapElement('numRadarSignals')));
                waveformsObjElement=setupABISignal(waveformsObjElement,waveformsMapElement('ABISignalSource'),...
                    waveformsMapElement('radarFileMeta'),zeros(1,waveformsMapElement('numABISignals')),...
                    waveformsMapElement('RadarReadScale')*ones(1,waveformsMapElement('numABISignals')));
            end
            waveformsObjElement=setupWaveformToFile(waveformsObjElement,waveformsMapElement('waveformPath'));
            waveformsObjElement=estimateGains(waveformsObjElement);
%             waveformsObj(I)=generateFullWaveform(waveformsObj(I),forwardToMaxPeakFlag);
            waveformsObjElement=generateFullWaveform(waveformsObjElement,this.shortFile);
        end
        
        function this=updateWaveformMapGains(this,waveformsObj)
            for I=1:this.numFiles
                this.waveformsMap{I}('radarGain')=waveformsObj(I).('radarGain');
                this.waveformsMap{I}('LTEGain')=waveformsObj(I).('LTEGain');
                this.waveformsMap{I}('ABIGain')=waveformsObj(I).('ABIGain');
                this.waveformsMap{I}('AWGNVar')=waveformsObj(I).('AWGNVar');
                this.waveformsMap{I}('writeScaleFactor')=waveformsObj(I).('writeScaleFactor');
            end
        end
        
        
        function this=runGenerator(this)
            this=runExecutor(this);
        end
        
        function this=resetWaveformGenerator(this)
            %rest wavefoms object
        end
    end
    
end


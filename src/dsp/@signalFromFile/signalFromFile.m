classdef signalFromFile
    %IQ data signal reader
    %   Read binary data from measurement files
    % Example usage:
    %     files_path='C:\measFilesDir';
    %     file_name='measFile.dat';
    %     measFile=fullfile(files_path,file_name);
    %
    %     testwaveform=signalFromFile(measFile);
    %     testwaveform=setreadScale(testwaveform,1);
    %     testwaveform=initInputFile(testwaveform);
    %     seekPositionSamples=0;
    %     testwaveform=setSeekPositionSamples(testwaveform,seekPositionSamples);
    %     samplesPerSegment=50e3;
    %     testwaveform=setSamplesPerSegment(testwaveform,samplesPerSegment);
    %     ------
    %     measData=readSamples(testwaveform);
    %     testwaveform=seekNextPositionSamples(testwaveform);    
    %     -------

    
    properties (Access=protected)
        readScale
        inputFile
        inputFileID
%        radarMetaFile
        seekPositionSamples
        signalFromFileInfo
%        radarInfoTable
    end
    properties (Access=private)
    inputIQDirectionNum
    end
    properties (Access=public)
        samplesPerSegment
        inputIQDirection
        EOFAction % fills the remaining samples with zeros or Return zeros size samplesPerSegment(default): 'Rzeros', rewind to bof: 'Rewind', Return empty []: 'Rempty' 
        signalFromFileERROR
    end

    properties(Constant)
    bytesPerSample=4;
    %combinedFrontEndGain=10.6;
   % combinedFrontEndGain=sqrt(db2pow(19.8)); % San Diego release 
   % combinedFrontEndGain=sqrt(db2pow(22.2)); % Virginia Beach release
 %  combinedFrontEndGain=1;
    end
    
    methods
       % function this=signalFromFile(inputFileName,inputIQDirection,EOFAction,radarMetaFile)
        function this=signalFromFile(InputFile,inputIQDirection,EOFAction)    
            switch nargin
                case 0
                    %set default IQ direction
                    this.inputIQDirection='QI';
                    %set default EOF action
                    this.EOFAction='Rzeros';
                case 1
                    this.inputFile=InputFile;
                    %set default IQ direction
                    this.inputIQDirection='QI';
                    %set default EOF action
                    this.EOFAction='Rzeros';
                case 2
                    this.inputFile=InputFile;
                    this.inputIQDirection=inputIQDirection;
                    %set default EOF action
                    this.EOFAction='Rzeros';
                case 3
                    this.inputFile=InputFile;
                    this.inputIQDirection=inputIQDirection;
                    this.EOFAction=EOFAction;
%                 case 4
%                     this.inputFileName=InputFileName;
%                     this.inputIQDirection=inputIQDirection;
%                     this.EOFAction=EOFAction;
%                     this.radarMetaFile=radarMetaFile;
%                     this=readRadarMetaTable(this);
            end

            
        end
        


        
        function this=setInputFile(this,InputFile)
            this.inputFile=InputFile;
        end
                
%         function this=setRadarMetaFile(this,radarMetaFile)
%             this.radarMetaFile=radarMetaFile;
%             this=readRadarMetaTable(this);
%         end
        
        
        function this=setSeekPositionSamples(this,seekPositionSamples)
            this.seekPositionSamples=seekPositionSamples;
        end
        
        function this=set.samplesPerSegment(this,samplesPerSegment)
            if ~isempty(this.inputFile)
             signalTime=getSignalTime(this);
            if samplesPerSegment<=floor(signalTime.totalNumberOfSamples) && samplesPerSegment>=1
            this.samplesPerSegment=samplesPerSegment;
            else
              this.signalFromFileERROR.samplesPerSegment= MException('signalFromFile:samplesPerSegment', ...
                    'samplesPerSegment must be >=1 and <= %d',floor(signalTime.totalNumberOfSamples));
                throw(this.signalFromFileERROR.samplesPerSegment);
            end
            else
                this.samplesPerSegment=samplesPerSegment;
            end
        end
        
        function this=set.EOFAction(this,EOFAction)
            EOFActionOptions={'Rzeros','Rewind','Rempty','Rnormal'};
            if ismember(EOFAction,EOFActionOptions)
            this.EOFAction=EOFAction;
            else
                this.signalFromFileERROR.EOFAction= MException('signalFromFile:EOFActionInitialization', ...
                    'EOFAction must be one of these options: %s',strjoin(EOFActionOptions));
                throw(this.signalFromFileERROR.EOFAction);
            end
        end
        
        function this=set.inputIQDirection(this,inputIQDirection)
            inputIQDirectionOptions={'IQ','QI'};
            if ismember(inputIQDirection,inputIQDirectionOptions)
                this.inputIQDirection=inputIQDirection;
            else
                this.signalFromFileERROR.inputIQDirection= MException('signalFromFile:inputIQDirection', ...
                    'inputIQDirection must be one of these options: %s',strjoin(inputIQDirectionOptions));
                throw(this.signalFromFileERROR.inputIQDirection);
            end
            
        end

         function this=setReadScale(this,readScale)
%              if nargin<2
%                  if ~isempty(this.radarInfoTable) && ~isempty(this.inputFile)
%                      [~,FileName,FileExt] = fileparts(this.inputFile);
%                      this.readScale=this.radarInfoTable.ADCScaleFactor(ismember(this.radarInfoTable.FileName,[FileName,FileExt]))/this.combinedFrontEndGain;
%                     % disp(num2str(this.radarInfoTable.ADCScaleFactor(ismember(this.radarInfoTable.FileName,[FileName,FileExt]))))
%                  else
%                      this.ERROR.setReadScale= MException('signalFromFile:RadarMeta', ...
%                                 'No appropriate radar meta data found');
%                      throw(this.ERROR.setReadScale);
%                  end
%              else
                 this.readScale=readScale;
%              end
         end
         
         function seekPositionSamples=getSeekPositionSamples(this)
             seekPositionSamples=this.seekPositionSamples;
         end

         
        function signalFromFileInfo=getSignalInfo(this)
        signalFromFileInfo.readScale=this.readScale;
        signalFromFileInfo.inputFile=this.inputFile;
%        signalFromFileInfo.radarMetaFile=this.radarMetaFile;
        signalFromFileInfo.inputFileID=this.inputFileID;
        signalFromFileInfo.seekPositionSamples=this.seekPositionSamples;
        signalFromFileInfo.samplesPerSegment=this.samplesPerSegment;
%         if ~isempty(this.radarInfoTable) && ~isempty(this.inputFile)
%             [~,FileName,FileExt] = fileparts(this.inputFile);
%             logicalIndex=ismember(this.radarInfoTable.FileName,[FileName,FileExt]);
%             signalFromFileInfo.radarFileIndex=find(logicalIndex);
%             signalFromFileInfo.radarInfoTable=this.radarInfoTable(logicalIndex,:);
%         else
%             signalFromFileInfo.radarInfoTable=[];
%         end
        end
        
        function signalTime=getSignalTime(this,Fs)
            if ~isempty(this.inputFile)
                 fInfo=dir(this.inputFile);
                 signalTime.totalNumberOfSamples=fInfo.bytes/this.bytesPerSample;
                 if nargin >1
                 signalTime.timeSec=signalTime.totalNumberOfSamples*1/Fs;
                 end
            else
                signalTime=[];
            end
        
        end
        
        
%          function this=readRadarMetaTable(this)
%             %% Import the data
%             if exist(this.radarMetaFile, 'file') == 2
%                 %MSGID='MATLAB:table:ModifiedAndSavedVarnames';warning('off', MSGID);
%                 this.radarInfoTable=readtable(this.radarMetaFile);
%             else
%              this.radarInfoTable=[];   
%             end
%         end
        
        function this=initInputFile(this)
            %errmsg = '';
            switch this.inputIQDirection
                case 'IQ'
                    
                    this.inputIQDirectionNum=[1 2];
                case 'QI'
                    this.inputIQDirectionNum=[2 1];
            end

            if isfield(this,'inputFileID') && this.inputFileID>=3
                fclose(this.inputFileID);
            end
            
            if exist(this.inputFile, 'file') == 2
            [ InputFileID,errmsg]=fopen(this.inputFile,'r','l','UTF-8');
            else
                errmsg='file does not exist';
            end
            
            if isempty(errmsg)
                this.inputFileID=InputFileID;
            end
        end
        
        function samplesData = readSamples(this)
            seekPosition=this.bytesPerSample*this.seekPositionSamples;
            status=fseek( this.inputFileID,seekPosition,'bof'); %return 0 if success, o.w. -1   
            % rewind if eof and EOF action is Rwind 
            [Data_Vec_Interleaved,count]=fread(this.inputFileID,2*this.samplesPerSegment,'int16=>double');
            % we always request even number of data bc of IQ
            % if file is not standard, check last segment
            if feof(this.inputFileID)
                    if mod(count,2) % if count is odd ignore last value
                        Data_Vec_Interleaved=Data_Vec_Interleaved(1:end-1);
                        count=count-1;
                    end
                
                    switch this.EOFAction
                        case 'Rzeros'
                            % pad with zeros the rest of the array or return zeros
                            Data_Vec_Interleaved=[Data_Vec_Interleaved;zeros(2*this.samplesPerSegment-count,1)];
                            %Data_Vec_Interleaved= padarray(Data_Vec_Interleaved,[2*this.samplesPerSegment-count,0],'post');
                        case 'Rempty' % in this case empty last segment
                            if count~=2*this.samplesPerSegment
                            Data_Vec_Interleaved=[];
                            end
                        case 'Rewind'
                            frewind(this.inputFileID)
                            % set seek position to zero
                            [Data_Vec_Interleaved1,~]=fread(this.inputFileID,2*this.samplesPerSegment-count,'int16=>double');
                            Data_Vec_Interleaved=[Data_Vec_Interleaved;Data_Vec_Interleaved1];
                            % set seek position so when
                            % seekNextPositionSamples() is called, seek
                            % position is adjusted
                            this=setSeekPositionSamples(this,count/2-this.samplesPerSegment);
                        case 'Rnormal' % do nothing
                        otherwise
                            this.signalFromFileERROR.signalFromFile= MException('signalFromFile:EOFAction', ...
                                'EOF action not set properly');
                            throw(this.signalFromFileERROR.readSamples);
                            
                    end
              
            end
            DataIQ=reshape(Data_Vec_Interleaved.',2,[]).';
            %clear Data_Vec_Interleaved
            % Note I&Q are switched in the radar meas files
            Data_Vector_c=complex(DataIQ(:,this.inputIQDirectionNum(1)),DataIQ(:,this.inputIQDirectionNum(2)));
            %clear DataIQ

            samplesData=Data_Vector_c*this.readScale;
        end
        
        function this=seekNextPositionSamples(this)
                this.seekPositionSamples=this.seekPositionSamples+this.samplesPerSegment;  
        end
        
%         function [this,sigmaW2,medianPeak,noiseEst,maxPeak,maxPeakLoc]=estimateRadarNoise(this,Fs,peakFilePath)
%             segTime=0.8e-3;
%             advancefromPeak=0.05e-3;
%             pks=load(peakFilePath);
%             [maxPeak,maxPeakLocIndx]=max(pks.pks);
%             medianPeak=median(pks.pks,'omitnan');
%             samplesPerSegmentTemp=this.samplesPerSegment;
%             seekPositionSamplesTemp=this.seekPositionSamples;
%             this.samplesPerSegment=round(segTime/(1/Fs));
%             maxPeakLoc=pks.locs(maxPeakLocIndx);
%             seekTime=maxPeakLoc+advancefromPeak;
%             this=setSeekPositionSamples(this,round(seekTime/(1/Fs)));
%             noiseEst =readMeasData(this);
%             sigmaW2=sum(abs(noiseEst).^2)/length(noiseEst);
%             this.samplesPerSegment=samplesPerSegmentTemp;
%             this.seekPositionSamples=seekPositionSamplesTemp;
%         end
        
        function this=resetSignalFromFile(this)
            if this.inputFileID~= -1
                fids=fopen('all');
                if any(this.inputFileID==fids)
                fclose(this.inputFileID);
                end
            end

        end
        
    end
    
end

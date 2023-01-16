function [idxD] = find_directsound(IR,fs)

    len_dirsound = 0.003; %Angenommene länge des Direktschalls ab dem Anfang in [s]
    range_firstRef = 0.003; %Bereich nach dem Direktschall indem die erste Reflexion angenommen wird in [s]

    %% Finde index directsound and first reflection and calc ITDG
    idxD_offset = round(fs*(len_dirsound/2));
        
    %Find the start index of the directsound
    %idxD_start(idx) = find(IR(:)>0.05*max(abs(IR(:))),1);
    
    %Find the peak index of the directsound
    mph = 0.1; %MinPeakHeight
    mpd = fs*.001; % minimum peak distance; neglecting other peaks in the vicinity of the true peak
    tmp = abs(IR)/max(abs(IR));
    [~,idxD_peak] = findpeaks(tmp,'MinPeakDistance',mpd,'MinPeakHeight',mph,'NPeaks',1);
    
    idxD = idxD_peak;
    if(isempty(idxD))
        error('idxD not found')
    end
% MIT License
% 
% Copyright (c) 2021 Gloria Dal Santo
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%
% Code Modifications: Paul Popp; TU Ilmenau 2022

function synthesizedBRIR = interpolateBRIR_1D(sourceBRIR_1, sourcePos_1, sourceBRIR_2, sourcePos_2, newPos, mixingTime, fs, plots)
    % ---------------------------------------------------- %
    % synthesizedBRIR = interpolateBRIR_1D(sourceBRIR_1, sourcePos_1, sourceBRIR_2, sourcePos_2, newPos, plot)
    % This function interpolates a BRIR between 2 Positions
    % Main functionality taken from Gloria Dal Santo
    % https://github.com/gdalsanto/music-player-for-binaural-spatialization
    % ---------------------------------------------------- %
    %   sourceBRIR_1:       first BRIR
    %   sourcePos_1:        measurement position of first BRIR (only 1 axis)
    %   sourceBRIR_2:       second BRIR
    %   sourcePos_2:        measurement position of second BRIR (only 1 axis)
    %   newPos:             new position which should be synthesized (only 1 axis)
    %   mixingTime:         Sample where the mixing time begins
    %   fs:                 sampling frequency
    %   plots:              show plots (1) or not (0)
    %
    %   synthesizedBRIR:    synthesized BRIR with position newPos
    % ---------------------------------------------------- %

    % TODO: improve peak detection and include mixing time detection

    addpath ./functions
    h = struct();                   % structure that stores h1, h2, h_int, and 
                                    % all the intermediate vectors
    ovlp = 100;                     % overlapping samples for crossover between direct+Early and late reverb
    fc = 150;                       % cutoff frequency Hz
    block_size = 600;               % block size for warping in samples, should be less than 600 samples

    if length(sourceBRIR_1) < length(sourceBRIR_2)
        sourceBRIR_1 = vertcat(sourceBRIR_1, zeros(length(sourceBRIR_2) - length(sourceBRIR_1), 2));
    elseif length(sourceBRIR_1) > length(sourceBRIR_2)
        sourceBRIR_2 = vertcat(sourceBRIR_2, zeros(length(sourceBRIR_1) - length(sourceBRIR_2), 2));
    end

    for leftRight = 1:2
        h.h1.ir = double(sourceBRIR_1(:,leftRight))';
        h.h2.ir = double(sourceBRIR_2(:,leftRight))';
        
        alpha = (newPos-sourcePos_1)/(sourcePos_2-sourcePos_1);
        N = size(h.h1.ir,2);        % BRIR length in samples
        
        %% Windowing of the BRIRs
        % separation of the direct+ealry reflection from the late reverberation
        
        % direct and ealry reflections
        h.h1.he.ir = h.h1.ir(1:mixingTime);
        h.h2.he.ir = h.h2.ir(1:mixingTime);
        % late reverberation 
         
        h.h1.lr.ir = h.h1.ir(mixingTime-ovlp:end);
        h.h2.lr.ir = h.h2.ir(mixingTime-ovlp:end);
        
        %% Dual-band processing of the direct+early reflections
        % to separate the frequency components a 3rd order Butterworth filter is
        % applied twice, forward and backward (zero phase filter)
        
        
        % compute the filter coefficients 
        [bL,aL] = butter(3,fc/(fs/2),'low' ); 
        [bH,aH] = butter(3,fc/(fs/2),'high'); 
        % zero-phase filtering 
        h.h1.he.low = filtfilt(bL,aL,h.h1.he.ir);
        h.h1.he.high = filtfilt(bH,aH,h.h1.he.ir);
        h.h2.he.low = filtfilt(bL,aL,h.h2.he.ir);
        h.h2.he.high = filtfilt(bH,aH,h.h2.he.ir);
        
        clear bL aL bH aH
        
        % find peaks peaks
        min_distance = 100;
        [pks, n_pks] = find_peaks(h.h1.he.high, h.h2.he.high, min_distance);
        
        % gravity point
        for i = 1:n_pks 
            % location of the gravity point
            pks.h1.grav(i) = floor((1-alpha)*pks.h1.loc(i) + alpha*pks.h2.loc(i));
            pks.h2.grav(i) = pks.h1.grav(i);
            % number of samples from peak to gravity point
            pks.h1.dmax(i) = abs(pks.h1.grav(i)-pks.h1.loc(i));
            pks.h2.dmax(i) = abs(pks.h2.grav(i)-pks.h2.loc(i));    
        end
        
        if plots
            % plot
            figure('Renderer', 'painters', 'Position', [10 10 900 600]);
            subplot(2,1,1);
            plot(h.h1.he.high); hold on; plot(pks.h1.loc, pks.h1.amp, 'o'); xline(pks.h1.grav(1)); xline(pks.h1.grav(2));
            xlim([350, 800]); ylim([-0.25, 0.25])
            title('Direct + early reflection at 3.0 m','interpreter','latex','FontSize',14)
            legend('$h_e^1$','peaks','gravity points','interpreter','latex','FontSize',12);
            xlabel('Samples','interpreter','latex','FontSize',14);
            ylabel('Amplitude','interpreter','latex','FontSize',14)
            subplot(2,1,2);
            plot(h.h2.he.high); hold on; plot(pks.h2.loc, pks.h2.amp, 'o'); xline(pks.h2.grav(1)); xline(pks.h2.grav(2));
            xlim([350, 800]); ylim([-0.25, 0.25])
            title('Direct + early reflection at 4.4 m','interpreter','latex','FontSize',14)
            legend('$h_e^2$','peaks','gravity points','interpreter','latex','FontSize',12);
            xlabel('Samples','interpreter','latex','FontSize',14);
            ylabel('Amplitude','interpreter','latex','FontSize',14)
        end
        
        % warping
        
        % creation of separated block where to perform warping
        blck = block_size/2 - 1;  % (block size)/2 -1
        for i = 1 : n_pks
            if pks.h1.loc(i)-blck <= 0
                pks.h1.warp.(['warp_' num2str(i)]) = h.h1.he.high(1:pks.h1.loc(i)+blck); 
                pks.h1.wapr_loc(i) = pks.h1.loc(i);
                pks.h1.warp.(['index_warp_' num2str(i)]) = 1:pks.h1.loc(i)+blck;
            else 
                pks.h1.warp.(['warp_' num2str(i)]) = h.h1.he.high(pks.h1.loc(i)-blck:pks.h1.loc(i)+blck);
                pks.h1.wapr_loc(i) = 50;
                pks.h1.warp.(['index_warp_' num2str(i)]) = pks.h1.loc(i)-blck:pks.h1.loc(i)+blck;
            end
            if pks.h2.loc(i)-blck <= 0
                pks.h2.warp.(['warp_' num2str(i)]) = h.h2.he.high(1:pks.h2.loc(i)+blck);
                pks.h2.wapr_loc(i) = pks.h2.loc(i);
                pks.h2.warp.(['index_warp_' num2str(i)]) = 1:pks.h2.loc(i)+blck;
            else 
                pks.h2.warp.(['warp_' num2str(i)]) = h.h2.he.high(pks.h2.loc(i)-blck:pks.h2.loc(i)+blck);
                pks.h2.wapr_loc(i) = 50;
                pks.h2.warp.(['index_warp_' num2str(i)]) = pks.h2.loc(i)-blck:pks.h2.loc(i)+blck;
            end    
        end
        
        % move the blocks toward the gravity point and streach the part with lowest
        % energy
        for i = 1:n_pks
            % move peak in h1 to the right
            if pks.h1.grav(i) > pks.h1.loc(i)   
                [indx_1,~,~] = low_energy(pks.h1.warp.(['warp_' num2str(i)]),pks.h1.wapr_loc(i),1); 
                [indx_2,~,~] = low_energy(pks.h2.warp.(['warp_' num2str(i)]),pks.h2.wapr_loc(i),0); 
                % move peak in h1 to the right
                for j = 1:pks.h1.dmax(i)
                    pks.h1.warp.(['warp_' num2str(i)]) = [pks.h1.warp.(['warp_' num2str(i)])(1:indx_1)...
                        mean([ pks.h1.warp.(['warp_' num2str(i)])(indx_1) pks.h1.warp.(['warp_' num2str(i)])(indx_1+1)])...
                        pks.h1.warp.(['warp_' num2str(i)])(indx_1+1:end-1)];
                    indx_1 = indx_1+2;
                end
                % move peak in h2 to the left
                for j = 1:pks.h2.dmax(i)
                    pks.h2.warp.(['warp_' num2str(i)]) = [pks.h2.warp.(['warp_' num2str(i)])(2:indx_2)...
                        mean([ pks.h2.warp.(['warp_' num2str(i)])(indx_2) pks.h2.warp.(['warp_' num2str(i)])(indx_2+1)])...
                        pks.h2.warp.(['warp_' num2str(i)])(indx_2+1:end)];
                    indx_2 = indx_2+2;
                end
            % move peak in h1 to the left
            elseif pks.h1.grav(i) < pks.h1.loc(i)
                [indx_1,~,~] = low_energy(pks.h1.warp.(['warp_' num2str(i)]),pks.h1.wapr_loc(i),0); 
                [indx_2,~,~] = low_energy(pks.h2.warp.(['warp_' num2str(i)]),pks.h2.wapr_loc(i),1); 
                % move peak in h1 to the right
                for j = 1:pks.h1.dmax(i)
                    pks.h1.warp.(['warp_' num2str(i)]) = [pks.h1.warp.(['warp_' num2str(i)])(2:indx_1)...
                        mean([ pks.h1.warp.(['warp_' num2str(i)])(indx_1) pks.h1.warp.(['warp_' num2str(i)])(indx_1+1)])...
                        pks.h1.warp.(['warp_' num2str(i)])(indx_1+1:end)];
                    indx_1 = indx_1+2;
                end
                % move peak in h2 to the left
                for j = 1:pks.h2.dmax(i)
                    pks.h2.warp.(['warp_' num2str(i)]) = [pks.h2.warp.(['warp_' num2str(i)])(1:indx_2)...
                        mean([ pks.h2.warp.(['warp_' num2str(i)])(indx_2) pks.h2.warp.(['warp_' num2str(i)])(indx_2+1)])...
                        pks.h2.warp.(['warp_' num2str(i)])(indx_2+1:end-1)];
                    indx_2 = indx_2+2;
                end
            end  
        end
        % substitute the warpped section in the original location
        for i = 1 : n_pks
            h.h1.he.high(pks.h1.warp.(['index_warp_' num2str(i)])) = pks.h1.warp.(['warp_' num2str(i)]);
            h.h2.he.high(pks.h2.warp.(['index_warp_' num2str(i)])) = pks.h2.warp.(['warp_' num2str(i)]);   
        end
        
        if plots
            % plots
            figure('Renderer', 'painters', 'Position', [10 10 900 600]);
            subplot(2,1,1);
            plot(h.h1.he.high); hold on; plot(pks.h1.warp.(['index_warp_' num2str(1)]), pks.h1.warp.(['warp_' num2str(1)])); 
            plot(pks.h1.warp.(['index_warp_' num2str(2)]), pks.h1.warp.(['warp_' num2str(2)])); xline(pks.h1.grav(1),'.'); xline(pks.h1.grav(2),'.');
            xlim([350, 800]); ylim([-0.25, 0.25])
            title('Direct + early reflection at $20^o$ - \textit{warped}','interpreter','latex','FontSize',14)
            legend('$h_e^1$','$h_{e, w1}^1$','$h_{e, w2}^1$','gravity points','interpreter','latex','FontSize',12);
            xlabel('Samples','interpreter','latex','FontSize',14);
            ylabel('Amplitude','interpreter','latex','FontSize',14)
            subplot(2,1,2);
            plot(h.h2.he.high); hold on; plot(pks.h2.warp.(['index_warp_' num2str(1)]), pks.h2.warp.(['warp_' num2str(1)])); 
            plot(pks.h2.warp.(['index_warp_' num2str(2)]), pks.h2.warp.(['warp_' num2str(2)])); xline(pks.h2.grav(1)); xline(pks.h2.grav(2));
            xlim([350, 800]); ylim([-0.25, 0.25])
            title('Direct + early reflection at $40^o$ - \textit{warped}','interpreter','latex','FontSize',14)
            legend('$h_e^2$','$h_{e, w1}^2$','$h_{e, w2}^2$','gravity points','interpreter','latex','FontSize',12);
            xlabel('Samples','interpreter','latex','FontSize',14);
            ylabel('Amplitude','interpreter','latex','FontSize',14)
        end
        %% Final Mix
        
        % linear interpolation of the low frequency components
        h.h_int.he.low = h.h1.he.low + (h.h2.he.low - h.h1.he.low)/2;
        
        % linear interpolation between warped high frequency components
        h.h_int.he.high = h.h1.he.high + (h.h2.he.high - h.h1.he.high)/2;
        h.h_int.he.he_int = h.h_int.he.low + h.h_int.he.high;
        
        % linear interpolation of the late reverberations
        h.h_int.hr = (1-alpha)*h.h1.lr.ir+alpha*h.h2.lr.ir;
        
        % crossover weights
        w = sqrt(((1:ovlp)-1)/(ovlp-1));
        
        % final result 
        h.h_int.ir = [h.h_int.he.he_int(1:mixingTime-ovlp) ...
            (h.h_int.he.he_int(mixingTime-ovlp+1:end).*(1-w) + w.*h.h_int.hr(1:ovlp))...
            h.h_int.hr(ovlp:end)];
        
        synthesizedBRIR(:,leftRight) = h.h_int.ir;
    end


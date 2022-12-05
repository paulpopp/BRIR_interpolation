function synthesizedBRIR = interpolateBRIR_2D(sourceBRIR_1, sourcePos_1, sourceBRIR_2, sourcePos_2, sourceBRIR_3, sourcePos_3, sourceBRIR_4, sourcePos_4, newPos, mixingTime, fs, plots)
    % ---------------------------------------------------- %
    % synthesizedBRIR = interpolateBRIR_2D(sourceBRIR_1, sourcePos_1, sourceBRIR_2, sourcePos2, sourceBRIR_3, sourcePos_3, sourceBRIR_4, sourcePos_4, newPos, mixingTime, fs, plots)
    % This function interpolates a BRIR between 4 Positions.
    % sourcePos_1 and sourcePos_2 should share the 2nd coordinate
    % sourcePos_3 and sourcePos_4 should share the 2nd coordinate
    % ---------------------------------------------------- %
    %   sourceBRIR_1:       first BRIR
    %   sourcePos_1:        measurement position of first BRIR (2D)
    %   sourceBRIR_2:       second BRIR
    %   sourcePos_2:        measurement position of second BRIR (2D)
    %   sourceBRIR_3:       third BRIR
    %   sourcePos_3:        measurement position of third BRIR (2D)
    %   sourceBRIR_4:       fourth BRIR
    %   sourcePos_4:        measurement position of fourth BRIR (2D)
    %   newPos:             new position which should be synthesized (2D)
    %   mixingTime:         Sample where the mixing time begins
    %   fs:                 sampling frequency
    %   plots:              show plots (1) or not (0)
    %
    %   synthesizedBRIR:    synthesized BRIR with position newPos
    % ---------------------------------------------------- %
    
    % Throw errors when Positions do not meet expectations
    if sourcePos_1(2) ~= sourcePos_2(2)
        error("Positions 1 and 2 don't share the same second coordinate.")
    end
    if sourcePos_3(2) ~= sourcePos_4(2)
        error("Positions 3 and 4 don't share the same second coordinate.")
    end
    
    % Check if all Positions are in a line or interpolated Position is on the same axis as Pos1 and Pos2 --> only 1D interpolation needed
    if sourcePos_1(2) == (sourcePos_3(2) && sourcePos_2(2) == sourcePos_4(2)) || newPos(2) == sourcePos_1(2)
        synthesizedBRIR = interpolateBRIR_1D(sourceBRIR_1, sourcePos_1(1), sourceBRIR_2, sourcePos_2(1), newPos(1), mixingTime, fs, plots);
        
    elseif newPos(2) == sourcePos_3(2)
        synthesizedBRIR = interpolateBRIR_1D(sourceBRIR_3, sourcePos_3(1), sourceBRIR_4, sourcePos_4(1), newPos(1), mixingTime, fs, plots);

    % If all Positions span a rectangle 2D interpolation is needed
    else
        tempBRIR_1 = interpolateBRIR_1D(sourceBRIR_1, sourcePos_1(1), sourceBRIR_2, sourcePos_2(1), newPos(1), mixingTime, fs, plots);
        tempPos_1 = [newPos(1) sourcePos_1(2)];
        tempBRIR_2 = interpolateBRIR_1D(sourceBRIR_3, sourcePos_3(1), sourceBRIR_4, sourcePos_4(1), newPos(1), mixingTime, fs, plots);
        tempPos_2 = [newPos(1) sourcePos_3(2)];
    
        synthesizedBRIR = interpolateBRIR_1D(tempBRIR_1, tempPos_1(2), tempBRIR_2, tempPos_2(2), newPos(2), mixingTime, fs, plots);
    end


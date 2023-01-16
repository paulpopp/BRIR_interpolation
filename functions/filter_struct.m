function filteredStruct = filter_struct(s, field, values)
    % Initialize the output struct array
    %filteredStruct = struct();

    % Keep track of the current index in the filtered struct array
    idx = 1;

    % Loop through each element of the struct array
    for i = 1:numel(s)
        % Check if the current element has a value for the specified field that is in the values array
        if ismember(s(i).(field), values, 'rows')
            % If it is, add it to the filtered struct array
            filteredStruct(idx) = s(i);
            idx = idx + 1;
        end
    end
end

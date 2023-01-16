function arr = remove_zeros(arr)
    % Find the first and last non-zero rows
    first_nonzero_row = find(any(arr,2), 1, 'first');
    last_nonzero_row = find(any(arr,2), 1, 'last');
    
    % Extract submatrix with only non-zero rows and columns
    arr = arr(first_nonzero_row:last_nonzero_row, :);
end

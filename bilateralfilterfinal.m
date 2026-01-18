% Function to apply bilateral filter to a 3D seismic cube
function filtered_seismic = apply_bilateral_filter(seismic_data, sigma_color, sigma_spatial)
    % Apply a bilateral filter to each slice of 3D seismic data
    % :param seismic_data: 3D matrix of seismic data
    % :param sigma_color: Color sigma for the bilateral filter
    % :param sigma_spatial: Spatial sigma for the bilateral filter
    % :return: Filtered 3D seismic data

    % Initialize the output array
    filtered_seismic = zeros(size(seismic_data));

    % Loop over each slice (2D image) in the 3D seismic data
    for i = 1:size(seismic_data, 3)
        slice_data = seismic_data(:, :, i);

        % Normalize the slice to [0, 1]
        norm_slice = (slice_data - min(slice_data(:))) / (max(slice_data(:)) - min(slice_data(:)));

        % Apply bilateral filter
        filtered_slice = imbilatfilt(norm_slice, sigma_color, sigma_spatial);

        % Restore the original scale
        filtered_seismic(:, :, i) = filtered_slice * (max(slice_data(:)) - min(slice_data(:))) + min(slice_data(:));

        fprintf('Applied bilateral filter to slice %d/%d\n', i, size(seismic_data, 3));
    end
end

% Function to load 3D seismic data from a SEG-Y file
function seismic_cube = load_segy_3d(input_file)
    % Load SEG-Y file info
    info = segyinfo(input_file);

    % Read the seismic data and headers
    [seismic_data, headers] = segyread(input_file);
    
    % Reshape seismic data into a 3D cube (Inline, Crossline, Time/Depth)
    % Assuming headers have inline and crossline information
    inlines = unique([headers.Inline]);
    crosslines = unique([headers.Crossline]);
    
    seismic_cube = zeros(length(inlines), length(crosslines), info.SamplesPerTrace);
    
    for i = 1:length(headers)
        inline_idx = find(inlines == headers(i).Inline);
        crossline_idx = find(crosslines == headers(i).Crossline);
        seismic_cube(inline_idx, crossline_idx, :) = seismic_data(:,i);
    end
end

% Function to save 3D seismic data back to SEG-Y file
function save_segy_3d(output_file, input_file, enhanced_data)
    % Read the original SEG-Y file structure
    [seismic_data, headers] = segyread(input_file);
    
    % Flatten the 3D enhanced data to 2D
    enhanced_data_flattened = reshape(enhanced_data, size(seismic_data));

    % Write the enhanced data back to a SEG-Y file
    segywrite(output_file, enhanced_data_flattened, headers);
end

% Example usage
input_file = 'filename.sgy';
output_file = 'filename.sgy';

% Load the seismic cube (3D seismic data)
seismic_cube = load_segy_3d(input_file);

% Apply the bilateral filter to enhance river channels
sigma_color = 0.1;
sigma_spatial = 15;
filtered_cube = apply_bilateral_filter(seismic_cube, sigma_color, sigma_spatial);

% Save the enhanced seismic data
save_segy_3d(output_file, input_file, filtered_cube);

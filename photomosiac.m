function [] = photomosiac()
%%  Preparation
patch_ratio = 100; % Number of patch spanning width of img
%Default patch directory (only if saving patchs)
patch_dir = strcat(pwd, filesep, 'patchs');

output_file_name = 'result.jpg';

interval = 1;

%List of file types
file_types = {['*.JPEG;*.JPG'],'MATLAB Graphical Files'};
comp_file_types = {'JPEG' 'JPG'};

% Get main image and directory of images

img_path  = './target_image.jpeg';
img_dir  = './test2'
%
ref_img = imread(img_path);
scale  = 0.5;
ref_img = imresize( ref_img , scale ) ;
img_size = size(ref_img);
img_size = img_size(1:2); % get first two parameters  


% Set size for patch based on original size
patch_pixels = floor(img_size(1)/patch_ratio);
patch_size = [patch_pixels patch_pixels];
%Make sure h/w are proportional to patch size
new_height = floor(img_size(2)/patch_pixels);
num_tiles = [patch_ratio new_height];
new_size = [patch_ratio new_height].*patch_pixels;
ref_img = imresize(ref_img, new_size);

% Get all directory images
dir_files = dir(img_dir);
mosaic_ind = 1;

for dir_ind = 1:length(dir_files)
    if ~dir_files(dir_ind).isdir
        file_name = dir_files(dir_ind).name;
        mosaic_files{mosaic_ind} = file_name;
        mosaic_ind = mosaic_ind+1;
    end
end

% Resize directory images into patchs

num_files = length(mosaic_files);
mosaic_imgs = cell(1, num_files);
%mkdir(patch_dir);
%Resize each image
for mosaic_ind = 1:num_files
    img = imread([img_dir, filesep, mosaic_files{mosaic_ind}]);
    %if read in grayscale img
    if size(img, 3) == 1
        img = ind2rgb(img, gray(256));
    end
    res_img = uint8(imresize(img, patch_size));
    patchs{mosaic_ind} = res_img;
   
end

%% Begin to match 
for mosaic_ind = 1:num_files
    %calc average vals for patchs
    cur_patch = patchs{mosaic_ind};
    RGB_vals{mosaic_ind} = mean(reshape(cur_patch, [], 3), 1);
end


%% For each tile of image find closest matching patch
pic_map = zeros(num_tiles);
tiles_done = 0;
for row_tile = 1:num_tiles(1)
    for col_tile = 1:num_tiles(2)
        closest = 1;
        shortest_dist = 1000;
        %get mean vals for the image tiles
        cur_tile = ref_img(patch_pixels*(row_tile-1)+1:patch_pixels*(row_tile), ...
        patch_pixels*(col_tile-1)+1:patch_pixels*(col_tile),:);
        cur_RGB = mean(reshape(cur_tile, [], 3), 1);
        %find the closest patch to each tile
        for patch_tile = 1:num_files
            dist = calc_distance(RGB_vals{patch_tile}, cur_RGB);
            %if new pt is closer
            if dist < shortest_dist
                if isempty(find( ...
                        pic_map(max(row_tile-interval,1): ...
                        min(row_tile+interval,num_tiles(1)),... 
                        max(col_tile-interval,1): ...
                        min(col_tile+interval,num_tiles(2))) ... 
                        == patch_tile, 1))
                    shortest_dist = dist;
                    pic_map(row_tile, col_tile) = patch_tile;
                end
            end
        end
        tiles_done = tiles_done + 1;
    end
end


% visualize
for row_tile = 1:num_tiles(1)
    cur_row = patchs{pic_map(row_tile, 1)};
    for col_tile = 2:num_tiles(2)
        cur_row = horzcat(cur_row, patchs{pic_map(row_tile, col_tile)});
    end
    if row_tile == 1
        mosaic = cur_row;
    else
        mosaic = vertcat(mosaic, cur_row);
        clear cur_row;
    end
end


imshow(mosaic)
%abs(mosaic-ref_img)
imwrite(mosaic, output_file_name, 'jpg');
end

function distance = calc_distance(pt1, pt2)
    %distance = sqrt(sum((pt1-pt2).^2));
    distance = (sum(abs(pt1-pt2)));
end
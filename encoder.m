clear;
clc;
Y = double(im2gray(imread("diff_size.png")));
figure(1);
imshow(Y,[]);

%padding
padding_r = mod(size(Y,1),8);
if (mod(size(Y,1),8) > 0)
    Y = [Y ; zeros(mod(size(Y,1),8), size(Y,2))];
    
end

padding_c = mod(size(Y,2),8);
if (mod(size(Y,2),8) > 0)
    Y = [Y  zeros(size(Y,1), mod(size(Y,2),8))];
end

%ycbcr = rgb2ycbcr(img);
%Y = ycbcr(:,:,1);
%CB = ycbcr(:,:,2);
%CR = ycbcr(:,:,3);
quantization = [[16 11 10 16 24 40 51 61];
                [12 12 14 19 26 58 60 55];
                [14 13 16 24 40 57 69 56];
                [14 17 22 29 51 87 80 62];
                [18 22 37 56 68 109 103 77];
                [24 35 55 64 81 104 113 92];
                [49 64 78 87 103 121 120 101];
                [ 72 92 95 98 112 100 103 99]];

quantization = quantization ./ (50/25);% value to be taken from user
%% 

arr = [];
%yet to pad zeros for left out pixels
for i=1:8:size(Y, 1)-7
    for j = 1:8:size(Y, 2)-7
        patch = Y(i:i+7, j:j+7);
        dct_patch = dct2(patch);
        quantized = round(dct_patch./quantization);
        arr = [arr;zig_zag(quantized)];
    end
end

function arr = zig_zag(quantized)
    arr = [];
    r=1; c=1;
    direction = -1;
    while(1)
            if r==1 || r==8
                if(c+1 > size(quantized,2))
                    arr = [arr quantized(r,c)];
                else
                    arr = [arr quantized(r,c) quantized(r,c+1)];
                end
                if r == 8
                    r=r-1;
                    c=c+2;
                    direction = +1;
                else
                    r=r+1; 
                    direction = -1;
                end
            elseif c==1 || c==8
                if(r+1 > size(quantized,1))
                    arr = [arr quantized(r,c)];
                else
                    arr = [arr quantized(r,c) quantized(r+1,c)];
                end
                if c==8
                    r=r+2;
                    c=c-1;
                    direction = -1;
                else
                    c=c+1;
                    direction = +1;
                end
            else
                arr = [arr quantized(r,c)];
                r=r-direction;
                c=c+direction;
            end
            if(r>8 || c>8)
                break;
            end
        end
end

%% 


%RLE encoding
DC = [];
RLE_encoded = [];
for i=1:size(arr,1)
    zero_count=0;
    for j=2:size(arr,2)
        if arr(i,j) == 0
            zero_count = zero_count + 1;
        else
            RLE_encoded = [RLE_encoded zero_count arr(i,j)];
            zero_count = 0;
        end
    end
    RLE_encoded = [RLE_encoded 0 0];
    DC = [DC arr(i,1)];
end

%subtracting the DCs
encoded_dc = [DC(1)];
for i=2:size(DC,2)
    diff = DC(i) - DC(i-1);
    encoded_dc = [encoded_dc diff];
end
%% 

%creating frequency table
[unique_dc, ~, idx_dc] = unique(encoded_dc);
dc_freq = accumarray(idx_dc, 1);
dc_frequency_table = [unique_dc', dc_freq];

[unique_ac, ~, idx_ac] = unique(RLE_encoded);
ac_freq = accumarray(idx_ac, 1);
ac_frequency_table = [unique_ac', ac_freq];

%flattened_ac = vertcat(RLE_encoded{:});
%[unique_ac, ~, idx_ac] = unique(flattened_ac, 'rows');
%ac_freq = accumarray(idx_ac, 1);
%ac_frequency_table = [unique_ac', ac_freq];

%converting the 2d array to str for huffman encoding
%str_ac = cell(size(flattened_ac, 1), 1);
%for i = 1:size(flattened_ac, 1)
%    str_ac{i} = mat2str(flattened_ac(i, :));
%end

%symbols = cell(size(unique_ac, 1), 1);
%for i = 1:size(unique_ac, 1)
%    symbols{i} = mat2str(unique_ac(i, :));
%end
%% 


%huffman code creation
[dict_dc, avglen] = huffmandict(unique_dc, dc_frequency_table(:,2)/sum(dc_frequency_table(:,2)));
[dict_ac, avglen_ac] = huffmandict(unique_ac, ac_frequency_table/sum(ac_frequency_table));


%huffman encoding
huff_encoded_dc = huffmanenco(encoded_dc, dict_dc);
huff_encoded_ac = huffmanenco(RLE_encoded, dict_ac);


%decoded2D = cellfun(@eval, str_ac, 'UniformOutput', false);
%decoded2D = vertcat(decoded2D{:});

%% 

%creating the jpg file

width = size(Y,2);
height = size(Y, 1);
channels = 1; 
padding_length = 0;

quant_table = reshape(quantization,1,[]);

%we will store the huffman tables as it is 

%u8_encoded_dc = ubit1(huff_encoded_dc);
%u8_encoded_ac = ubit1(huff_encoded_ac);

size_encode_ac = size(huff_encoded_ac,2);
size_encode_dc = size(huff_encoded_dc,2);


size_dict_ac = size(dict_ac,1);
size_dict_dc = size(dict_dc,1);

%% 

symbol_dc = cell2mat(dict_dc(:,1));
symbol_ac = cell2mat(dict_ac(:,1));

result_dc = cell(size(dict_dc(:,2)));
cellArray = dict_dc(:,2);
for i = 1:numel(cellArray)
    elements = cellArray{i};
    
    numElements = numel(elements);
    result_dc{i} = [numElements, elements];
end

result_ac = cell(size(dict_ac(:,2)));
cellArray = dict_ac(:,2);
for i = 1:numel(cellArray)
    elements = cellArray{i};
    
    numElements = numel(elements);
    result_ac{i} = [numElements, elements];
end


%% 
fileID = fopen("comp.mv", "w");
fwrite(fileID, width, 'uint32');
fwrite(fileID, height, 'uint32');
fwrite(fileID, channels, 'uint8');
fwrite(fileID, padding_r, 'uint8');
fwrite(fileID, padding_c, 'uint8');

fwrite(fileID, quant_table, 'float');

fwrite(fileID, size_dict_dc, 'uint32');
fwrite(fileID, size_dict_ac, 'uint32');

fwrite(fileID, symbol_dc, 'int32');
fwrite(fileID, symbol_ac, 'int32');

for i = 1:numel(result_dc)
    fwrite(fileID, result_dc{i}(1), 'uint32');
    for j=2:result_dc{i}(1)+1
        fwrite(fileID, result_dc{i}(j), 'ubit1');
    end
end

for i = 1:numel(result_ac)
    fwrite(fileID, result_ac{i}(1), 'uint32');
    for j=2:result_ac{i}(1)+1
        fwrite(fileID, result_ac{i}(j), 'ubit1');
    end
end

fwrite(fileID, size_encode_dc, 'uint32');
fwrite(fileID, size_encode_ac, 'uint32');

fwrite(fileID, huff_encoded_dc, 'ubit1');
fwrite(fileID, huff_encoded_ac, 'ubit1');

fclose(fileID);
%% 

img = imread("diff_size.png");
imwrite(img, "libOut.jpg", 'jpg');

%% 

libOut = dir("libOut.jpg");
fprintf("size of JPEG file created by Matlab : %d\n", libOut.bytes);



orig = dir("diff_size.png");
fprintf("size of original PNG image : %d\n", orig.bytes);

comp = dir("comp.mv");
fprintf("size of JPEG file created by our code : %d\n", comp.bytes);
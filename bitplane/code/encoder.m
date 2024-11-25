clear;
clc;
img = double(im2gray(imread("diff_size.png")));
[row,column] = size(img);

img = floor(img./16);

img = reshape(img,1,[]);
diff = img;
for i = 2:size(img,2)
    diff(i) = img(i-1) - img(i);
end

[unique_val, ~, idx_val] = unique(diff);
freq = accumarray(idx_val, 1);
frequency_table = [unique_val', freq];

%huffman code creation
[dict, avglen] = huffmandict(unique_val, frequency_table(:,2)/sum(frequency_table(:,2)));

%huffman encoding
huff_encoded = huffmanenco(diff, dict);
%huff_decoded = huffmandeco(huff_encoded,dict);
%imshow(reshape(huff_decoded,row,column),[]);

%% 

size_dict = size(dict,1);
symbol = cell2mat(dict(:,1));

result = cell(size(dict(:,2)));
cellArray = dict(:,2);
for i = 1:numel(cellArray)
    elements = cellArray{i};
    numElements = numel(elements);
    result{i} = [numElements, elements];
end

size_encode = size(huff_encoded,2);


%% 
fileID = fopen("comp.mv", "w");
fwrite(fileID, row, 'uint32');
fwrite(fileID, column, 'uint32');

fwrite(fileID, size_dict, 'uint32');
fwrite(fileID, symbol, 'int32');

for i = 1:numel(result)
    fwrite(fileID, result{i}(1), 'uint32');
    for j=2:result{i}(1)+1
        fwrite(fileID, result{i}(j), 'ubit1');
    end
end

fwrite(fileID, size_encode, 'uint32');
fwrite(fileID, huff_encoded, 'ubit1');

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
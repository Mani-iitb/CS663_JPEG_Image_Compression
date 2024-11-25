clear;
clc;

fileID = fopen("comp.mv", "r");

row = fread(fileID, 1, 'uint32');
column = fread(fileID, 1, 'uint32');

size_dict = fread(fileID,1,"uint32");
symbol = fread(fileID, size_dict, "int32");

result = cell(size_dict,1);
for i = 1:numel(result)
    size_ele = fread(fileID, 1, "uint32");
    elements = fread(fileID, size_ele, "ubit1");
    result{i} = reshape(elements,1,[]);
end

dict = cell(size_dict,2);
dict(:,1) = num2cell(symbol);
dict(:,2) = result;

size_encode = fread(fileID, 1, "uint32");

u8_encoded = fread(fileID, size_encode, "ubit1");

fclose(fileID);

%% huffman decoding
huff_decoded = huffmandeco(u8_encoded,dict);
huff_decoded = reshape(huff_decoded,1,[]);

decoded = [huff_decoded(1)];
for i=2:size(huff_decoded,2)
    added = huff_decoded(i) + decoded(i-1);
    decoded = [decoded added];
end

%% 
decoded = 255 - (decoded.*16);
img = reshape(decoded,row,column);
figure(1);
imshow(img, []);
imwrite(uint8(img),'bitplane_reconstructed.jpg');

%% 

currentImage = "./diff_size.png";
Orig = double(im2gray(imread(currentImage)));

images = dir("./*.mv");
orig_image = dir("./diff_size.png");

error = Orig - img;
rmseValues = sqrt(mean(error(:).^2));

fprintf("RMSE : %d\n", rmseValues);

%Compression ratio
origFileSize = orig_image(1).bytes;
compFileSize = images(1).bytes;
compression = origFileSize / compFileSize;

fprintf("Compression ratio : %f\n", compression);
clear;
clc;

fileID = fopen("comp.mv", "r");

orig_row = fread(fileID, 1, 'uint32');
orig_col = fread(fileID, 1, 'uint32');
width = fread(fileID, 1, 'uint32');
height = fread(fileID, 1, 'uint32');
channels = fread(fileID, 1, 'uint8');
padding_r = fread(fileID, 1, 'uint8');
padding_c = fread(fileID, 1, 'uint8');

size_mean = fread(fileID, 1,"uint8");
meanImage = fread(fileID, size_mean, "uint8");
size_eig_vec = fread(fileID, 1,"uint32");
top_eigenvectors = fread(fileID, size_eig_vec, "float");

quant_table = fread(fileID, 64, 'float');
quant_table = reshape(quant_table, [], 8);

size_dict_dc = fread(fileID,1,"uint32");
size_dict_ac = fread(fileID,1,"uint32");

symbol_dc = fread(fileID, size_dict_dc, "int32");
symbol_ac = fread(fileID, size_dict_ac, "int32");

result_dc = cell(size_dict_dc,1);
for i = 1:numel(result_dc)
    size_ele = fread(fileID, 1, "uint32");
    elements = fread(fileID, size_ele, "ubit1");
    result_dc{i} = reshape(elements,1,[]);
end

dict_dc = cell(size_dict_dc,2);
dict_dc(:,1) = num2cell(symbol_dc);
dict_dc(:,2) = result_dc;

result_ac = cell(size_dict_ac,1);
for i = 1:numel(result_ac)
    size_ele = fread(fileID, 1, "uint32");
    elements = fread(fileID, size_ele, "ubit1");
    result_ac{i} = reshape(elements,1,[]);
end

dict_ac = cell(size_dict_ac,2);
dict_ac(:,1) = num2cell(symbol_ac);
dict_ac(:,2) = result_ac;

size_encode_dc = fread(fileID, 1, "uint32");
size_encode_ac = fread(fileID, 1, "uint32");

u8_encoded_dc = fread(fileID, size_encode_dc, "ubit1");
u8_encoded_ac = fread(fileID, size_encode_ac, "ubit1");

fclose(fileID);

%% huffman decoding
huff_decoded_dc = huffmandeco(u8_encoded_dc,dict_dc);
huff_decoded_dc = reshape(huff_decoded_dc,1,[]);

huff_decoded_ac = huffmandeco(u8_encoded_ac,dict_ac);
huff_decoded_ac = reshape(huff_decoded_ac,1,[]);

%% 

decoded_dc = [huff_decoded_dc(1)];
for i=2:size(huff_decoded_dc,2)
    added = huff_decoded_dc(i) + decoded_dc(i-1);
    decoded_dc = [decoded_dc added];
end

zerocount=0;
zigzaged=[];
arr=[];
for i=1:size(huff_decoded_ac,2)
    if (mod(i,2) == 1)
        zerocount = huff_decoded_ac(1,i);
    else
        if (huff_decoded_ac(1,i) == 0)
            arr = [arr zeros(1,63-size(arr,2))];
            zigzaged = [zigzaged; arr];
            arr=[];
        else
            if zerocount == 0
                arr = [arr huff_decoded_ac(1,i)];
            else
                arr = [arr zeros(1,zerocount) huff_decoded_ac(1,i)];
            end
        end
    end
end

zigzaged = [reshape(decoded_dc,[],1), zigzaged];


%% de zig-zaging

inv_dcted = zeros(height,width);
r=1;c=1;
for i=1:size(zigzaged,1)
    arr = deZigZag(zigzaged(i,:));
    arr = arr.*quant_table;
    inversed = idct2(arr);
    inv_dcted(r:r+7,c:c+7) = inversed;
    c=mod(c+8,width);
    if c==1
        r=mod(r+8,height);
    end
end

function arr = deZigZag(zigzaged)
    arr = zeros(8,8);
    r=1; c=1; j=1;
    direction=-1;
    while(1)
            if r==1 || r==8
                if(c+1 > size(arr,2))
                    arr(r, c) = zigzaged(j);
                    j=j+1;
                else
                    arr(r,c) = zigzaged(j);
                    arr(r,c+1) = zigzaged(j+1);
                    j=j+2;
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
                if(r+1 > size(arr,1))
                    arr(r, c) = zigzaged(j);
                    j=j+1;
                else
                    arr(r,c) = zigzaged(j);
                    arr(r+1,c) = zigzaged(j+1);
                    j=j+2;
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
                arr(r, c) = zigzaged(j);
                j=j+1;
                r=r-direction;
                c=c+direction;
            end
            if(r>8 || c>8)
                break;
            end
    end
end

%% 
top_eigenvectors = reshape(top_eigenvectors, 64, []);
reconstructedImage = top_eigenvectors * inv_dcted + meanImage;
image = zeros(orig_col,orig_row);
k=1;
for i=1:8:orig_row-7
    for j = 1:8:orig_col-7
        image(i:i+7, j:j+7) = reshape(reconstructedImage(:,k),8,8);
        k=k+1;
    end
end

%% 

%inv_dcted = inv_dcted(1:size(inv_dcted,1)-padding_r, 1:size(inv_dcted,2)-padding_c);

figure(2);
imshow(image, []);
imwrite(uint8(image),'PCA_JPEG_reconstructed.jpg');

%% 

currentImage = "./diff_size.png";
Orig = double(im2gray(imread(currentImage)));

images = dir("./*.mv");
orig_image = dir("./diff_size.png");

error = Orig - image;
rmseValues = sqrt(mean(error(:).^2));

fprintf("RMSE : %d\n", rmseValues);

%Compression ratio
origFileSize = orig_image(1).bytes;
compFileSize = images(1).bytes;
compression = origFileSize / compFileSize;

fprintf("Compression ratio : %f\n", compression);

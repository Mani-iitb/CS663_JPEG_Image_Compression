clear;

images = dir("./images/*.png");
numImages = length(images);
disp(numImages);
for z = 1:numImages
    currentImage = images(z).name;
    currentImage = "./images/"+currentImage;
    img = imread(currentImage);
    ycbcr = rgb2ycbcr(img);
    Y = double(ycbcr(:,:,1));
    Cb = double(ycbcr(:,:,2));
    Cr = double(ycbcr(:,:,3));
    %padding
    padding_r = mod(size(Y,1),8);
    if (padding_r > 0)
        Y = [Y ; zeros(padding_r, size(Y,2))];
        Cb = [Cb ; zeros(padding_r, size(Cb,2))];
        Cr = [Cr ; zeros(padding_r, size(Cr,2))];
    end
    
    padding_c = mod(size(Y,2),8);
    if (padding_c > 0)
        Y = [Y  zeros(size(Y,1), padding_c)];
        Cb = [Cb  zeros(size(Cb,1), padding_c)];
        Cr = [Cr  zeros(size(Cr,1), padding_c)];
    end

    for y=5:10:85
        output_image = "img"+num2str(z)+"_"+num2str(y)+".mv";
       
        % Process each component (Y, Cb, Cr) independently
        process_component(Y, "Y"+output_image, y);
        process_component(Cb, "Cb"+output_image, y);
        process_component(Cr, "Cr"+output_image, y);
    
       
    end
end

function process_component(component, name, q_num)

     quantization = [[16 11 10 16 24 40 51 61];
                        [12 12 14 19 26 58 60 55];
                        [14 13 16 24 40 57 69 56];
                        [14 17 22 29 51 87 80 62];
                        [18 22 37 56 68 109 103 77];
                        [24 35 55 64 81 104 113 92];
                        [49 64 78 87 103 121 120 101];
                        [ 72 92 95 98 112 100 103 99]];
        
     quantization = quantization .* (50/q_num);

     arr = [];
        %yet to pad zeros for left out pixels
        for i=1:8:size(component, 1)-7
            for j = 1:8:size(component, 2)-7
                patch = component(i:i+7, j:j+7);
                dct_patch = dct2(patch);
                quantized = round(dct_patch./quantization);
                arr = [arr;zig_zag(quantized)];
            end
        end
        
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
    
        %creating frequency table
        [unique_dc, ~, idx_dc] = unique(encoded_dc);
        dc_freq = accumarray(idx_dc, 1);
        dc_frequency_table = [unique_dc', dc_freq];
        
        [unique_ac, ~, idx_ac] = unique(RLE_encoded);
        ac_freq = accumarray(idx_ac, 1);
        ac_frequency_table = [unique_ac', ac_freq];
        
    
        %huffman code creation
        [dict_dc, avglen] = huffmandict(unique_dc, dc_frequency_table(:,2)/sum(dc_frequency_table(:,2)));
       
        if numel(unique_ac) == 1
            dict_ac = {unique_ac, [0]}; % Single symbol with trivial encoding
            avglen_ac = 0; % No meaningful average length
        else
            [dict_ac, avglen_ac] = huffmandict(unique_ac, ac_frequency_table(:,2)/sum(ac_frequency_table(:,2)));
        end
        
        %huffman encoding
        huff_encoded_dc = huffmanenco(encoded_dc, dict_dc);
        huff_encoded_ac = huffmanenco(RLE_encoded, dict_ac);
    
        width = size(component,2);
        height = size(component, 1);
               
        quant_table = reshape(quantization,1,[]);
    
        size_encode_ac = size(huff_encoded_ac,2);
        size_encode_dc = size(huff_encoded_dc,2);
        
        
        size_dict_ac = size(dict_ac,1);
        size_dict_dc = size(dict_dc,1);
    
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

        pad_r = mod(size(component,1),8);
        pad_c = mod(size(component,2),8);
    
        fileID = fopen(name, "w");
        fwrite(fileID, width, 'uint32');
        fwrite(fileID, height, 'uint32');
        
        fwrite(fileID, pad_r, 'uint8');
        fwrite(fileID, pad_c, 'uint8');
        
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
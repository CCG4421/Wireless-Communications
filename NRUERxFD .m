classdef NRUERxFD < matlab.System
    % 5G NR UE receiver with optional Sparse-MMSE channel estimation
    properties
        % Configurations
        carrierConfig;    
        pdschConfig;      
        waveformConfig;   

        % Parameters
        sigFreq = 7;      
        sigTime = 3;      
        lenFreq = 21;     
        Wtime;            
        bitsPerSym = 2;   

        % Internal data
        rxGrid;           
        chanEstGrid;      
        noiseEst;         
        pdschChan;        
        pdschSym;         
        pdschSymEq;       
        rxBits;           

        % New: Sparse-MMSE toggle
        useSparse = false;
        sparseAlpha = 0.1;   % e.g., 10% max value as threshold
        useAdaptiveTau = false; % ✅ 新增：控制是否使用自适应门限
    end

    methods
        function obj = NRUERxFD(carrierConfig, pdschConfig, varargin)
            obj.carrierConfig = carrierConfig;
            obj.pdschConfig = pdschConfig;
            obj.waveformConfig = nrOFDMInfo(obj.carrierConfig);

            if nargin >= 1
                obj.set(varargin{:});
            end
        end

        function chanEst(obj, rxGrid)
            % Compute DM-RS-based channel estimation

            % Get TX DM-RS symbols and indices
           dmrsInd = nrPDSCHDMRSIndices(obj.carrierConfig, obj.pdschConfig);
            dmrsSymTx = nrPDSCHDMRS(obj.carrierConfig, obj.pdschConfig);

            % RX DM-RS symbols
            dmrsSymRx = rxGrid(dmrsInd);

            % Raw LS estimate
            hEstRaw = dmrsSymRx ./ dmrsSymTx;

            % Symbol and subcarrier indices
            [~, symNum, scInd] = ind2sub(size(rxGrid), dmrsInd);
            dmrsSymNum = unique(symNum);
            nSym = length(dmrsSymNum);
nRB = obj.carrierConfig.NSizeGrid;    % 资源块数
nSC = nRB * 12;                        % 每个RB有12个子载波


            chanEstDmrs = zeros(nSC, nSym);
            noiseEstDmrs = zeros(nSym, 1);

            for i = 1:nSym
                idx = find(symNum == dmrsSymNum(i));
                subInd = scInd(idx);
                raw = hEstRaw(idx);

                % MMSE smoothing (via kernelReg)
                [chanEstDmrs(:, i), ~] = kernelReg(subInd, raw, nSC, obj.lenFreq, obj.sigFreq);

                % Noise estimate (residual)
                hSmooth = chanEstDmrs(subInd, i);
                noiseEstDmrs(i) = mean(abs(raw - hSmooth).^2);
            end

            obj.noiseEst = mean(noiseEstDmrs);

            % Time interpolation
[I, J] = meshgrid(1:14, 1:nSym); % I: 1~14 (OFDM symbols), J: DMRS symbols
D = abs( dmrsSymNum(J) - I );          % D is [nSym_DMRS × 14]
W0 = exp(-0.5 * (D.^2) / obj.sigTime^2);
W = W0 ./ sum(W0, 1);                  % Normalize over rows

            obj.Wtime = W;

            chanEst = chanEstDmrs * W;

if obj.useSparse
    if obj.useAdaptiveTau
        tau = obj.sparseAlpha * sqrt(obj.noiseEst);  % Adaptive τ
    else
        tau = obj.sparseAlpha * max(abs(chanEst(:)));  % Fixed τ
    end
    chanEst = sparseThreshold(chanEst, tau);
end



            obj.chanEstGrid = chanEst;
        end
    end

    
methods (Access = protected)
    function rxBits = stepImpl(obj, rxGrid, chanGrid, noiseVar)
        % Performs channel estimation, equalization and demodulation
        % for one slot of OFDM symbols.

        if nargin >= 3
            obj.chanEstGrid = chanGrid;
            obj.noiseEst = noiseVar;
        else
            obj.chanEst(rxGrid);
        end

        % Get PDSCH indices
        pdschInd = nrPDSCHIndices(obj.carrierConfig, obj.pdschConfig);

        % === Debug: check index range ===
        if any(pdschInd > numel(rxGrid))
            error("PDSCH indices exceed rxGrid dimensions.");
        end
        if any(pdschInd > numel(obj.chanEstGrid))
            error("PDSCH indices exceed chanEstGrid dimensions.");
        end

        % Extract PDSCH symbols and channel estimates
        obj.pdschSym = rxGrid(pdschInd);
        obj.pdschChan = obj.chanEstGrid(pdschInd);

        % === Debug: NaN check before equalization ===
        if any(isnan(obj.pdschChan(:)))
            error("❌ pdschChan contains NaN before equalization.");
        end
        if isnan(obj.noiseEst)
            warning("⚠️ noiseEst is NaN. Assigning default value 1e-3.");
            obj.noiseEst = 1e-3;
        end

        % MMSE Equalization with safe division
        denom = abs(obj.pdschChan).^2 + obj.noiseEst;
        denom(denom == 0) = eps;

        obj.pdschSymEq = obj.pdschSym .* conj(obj.pdschChan) ./ denom;

        % === Debug: check post-equalization ===
        if any(isnan(obj.pdschSymEq(:)))
            warning("⚠️ pdschSymEq contains NaNs! Displaying NaN indices:");
            disp(find(isnan(obj.pdschSymEq)));
        end

        % Demodulation
        M = 2^obj.bitsPerSym;
        rxBits = qamdemod(obj.pdschSymEq, M, 'OutputType', 'bit', ...
            'UnitAveragePower', true);
    end
end

end


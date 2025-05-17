function plotChanCompare(estGrid, trueGrid)
%PLOTCHANCOMPARE Visually compare estimated and true channel grids
%
% Usage:
%   plotChanCompare(estGrid, trueGrid)
%
% estGrid and trueGrid must be 2D matrices (e.g., 72x14)

    if nargin < 2
        error('Provide both estimated and true channel grids.');
    end

    figure;
    subplot(1,3,1);
    imagesc(abs(trueGrid));
    title('True Channel Magnitude');
    xlabel('OFDM Symbol');
    ylabel('Subcarrier');
    colorbar;

    subplot(1,3,2);
    imagesc(abs(estGrid));
    title('Estimated Channel Magnitude');
    xlabel('OFDM Symbol');
    colorbar;

    subplot(1,3,3);
    imagesc(abs(trueGrid - estGrid));
    title('Estimation Error (|true - est|)');
    xlabel('OFDM Symbol');
    colorbar;
end

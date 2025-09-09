clc
clear;
close all;

rng(2022,'twister')

NR  = 0.30;

loaddataname = 'Data\balloons_ms.mat';
loadedData = load(loaddataname);

fieldfilename = 'imgDouble';
D      = loadedData.(fieldfilename);
sizeD = size(D);

Xim    = double(D)./65535;
idx    = randsample(numel(Xim),round(NR*numel(Xim)));
D(idx) = randi(65536,1,length(idx))-1;
D = double(D)./65535;

D = double(D);
% Xim = double(Xim)./255;

ndim = length(sizeD);

addpath(genpath('Evaluation'));
addpath(genpath('Model'));
addpath(genpath('Function'));

Dh = D;

hyperparameters.tau_a_0 = 1e-6;
hyperparameters.tau_b_0 = 1e-6;
hyperparameters.lambda_a_0 = 1e-6;
hyperparameters.lambda_b_0 = 1e-6;
hyperparameters.epsilon_a_0 = 1e-6;
hyperparameters.epsilon_b_0 = 1e-6;
MAX_Iter = 500;

Rank = [0, 60, 6;
    0, 0, 6;
    0, 0, 0;];

FCTN_vb = FCTN_model(Dh, Rank, hyperparameters); % get model
FCTN_vb = FCTN_vb.initialize();  % init model
tic;
FCTN_vb = FCTN_vb.run(MAX_Iter);       % train


Xrecovery = FCTN_vb.hat;

Timecost = toc;
[PSNR,SSIM,FSIM,ergas] = MSIQA(Xim.*255, Xrecovery.*255);

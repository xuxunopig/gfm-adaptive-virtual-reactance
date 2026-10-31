function p = Model_A_parameters()
% MODEL_A_PARAMETERS Unified Model A settings (per unit, seconds, radians).
% Source: case2M_1L_voltagestability{,simulationdata}.m and paper Eqs. (1)-(5).
p.baseMVA = 100;
p.freq = 60;
p.M = 5.0224;
p.D = 6;
p.K = 12;
p.Dq = 60;
% The original code's Xe=0.1 ALREADY contains the paper's xe+xL1.
% Only their sum is identifiable from that code. Do not add xL1 twice.
p.xe = 0.1;
p.xL1 = 0;
p.xL2 = 0.24;
p.PL = 1.2;
p.QL = 0.3;
p.VS = 1;
p.thetaS = 0;
p.Pref = 1;
% Reproduce the original V_G=1 power-flow operating point, without using
% rounded/stale PFsolution values. These are FIXED references thereafter.
theta = asin((p.Pref-p.PL)*p.xL2);
V = exp(1i*theta);
Qbus = p.QL + (1-cos(theta))/p.xL2;
I = conj((p.Pref+1i*Qbus)/V);
Ei = V + 1i*(p.xe+p.xL1)*I;
p.Eref = abs(Ei);
p.Qref = imag(Ei*conj(I));
p.Ithresh = 1.1;
p.Imax = 1.5;         % Design target, NOT an extra circular current limiter.
p.SigmaXR = 5;
p.Vmax = 1;
% Restore paper VI: original case file explicitly overwrites KVI with zero.
p.KVI = (p.Vmax-(p.xe+p.xL1)*p.Imax) / ...
    (p.Imax*p.SigmaXR*(p.Imax-p.Ithresh));
p.omegaVI = 2*pi*10;
% Paper's admissible analysis range; NOT a saturation in Eq. (4).
p.xvmax = p.KVI*p.SigmaXR*(p.Imax-p.Ithresh);
p.faultEnabled = 1;
p.tFault = 0.1;
p.tClear = 0.32;
p.Rf = 0.01;          % Three-phase shunt at G, original Ybus_modification.
p.Xf = 0;             % Zero reproduces the original resistive fault.
p.faultLoadToZ = 1;   % Explicit requested fault-only extension, not hidden.
p.Vswitch = 1;        % ACTUAL executable threshold in runsimulation.m.
p.tStop = 3;
p.solver = 'ode15s';
p.maxStep = 0.001;
p.relTol = 1e-7;
p.absTol = 1e-9;
p.initTol = 1e-9;
p.residualTol = 1e-7;
p.showFigures = true;
p.saveResults = true;
p.outputDir = fullfile(fileparts(mfilename('fullpath')), 'Model_A_results');
end

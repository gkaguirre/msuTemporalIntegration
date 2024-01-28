function x0 = initial(obj)
% Returns initial guess for the model parameters
%
% Syntax:
%   x0 = obj.initial()
%
% Description:
%   Initial values for the prf_timeShift model. Rationale is as follows:
%       x, y :  Center of the stimulus
%       sigma:  1 or 10 pixels, depending upon obj.scale
%       gain :  Set by obj.typicalGain
%       exp  :  Locked to 0.05, following Benson et al, 2018, HCP 7T data
%       shift:  Zero HRF temporal shift      
%
% Inputs:
%   none
%
% Optional key/value pairs:
%   none
%
% Outputs:
%   x0                    - 1xnParams vector.
%


% Obj variables
typicalGain = obj.typicalGain;
nParams = obj.nParams;
nGainParams = obj.nGainParams;
nAdaptParams = obj.nAdaptParams;

% Assign the x0 variable
x0 = zeros(1,nParams);

% Initialize the model with the gain parameters at the typicalGain
x0(1:nGainParams) = typicalGain;

% set the mu parameter to 0.5, and the adaptGain to the typicalGain
x0(nGainParams+1) = 0.5;
x0(nGainParams+2) = typicalGain;

% x0 HRF: Flobs population mean amplitudes
x0(nGainParams+nAdaptParams+1:nParams) = [0.86, 0.09, 0.01];


end


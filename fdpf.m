function [V, converged, i] = ...
  fdpf(Ybus, Sbus, V0, Bp, Bpp, ref, pv, pq, tol, max_it)
%FDPF  Solves the power flow using a fast decoupled method.
%   [V, CONVERGED, I] = FDPF(YBUS, SBUS, V0, BP, BPP, REF, PV, PQ, TOL, MAX_IT)
%   solves for bus voltages given the full system admittance matrix (for
%   all buses), the complex bus power injection vector (for all buses),
%   the initial vector of complex bus voltages, the FDPF matrices B prime
%   and B double prime, and column vectors with the lists of bus indices
%   for the swing bus, PV buses, and PQ buses, respectively. The bus voltage
%   vector contains the set point for generator (including ref bus)
%   buses, and the reference angle of the swing bus, as well as an initial
%   guess for remaining magnitudes and angles.
%
%   Returns the
%   final complex voltages, a flag which indicates whether it converged
%   or not, and the number of iterations performed.
%
%   See also RUNPF.

%% argument validation
if nargin < 10
  V = 0;
  converged = 0;
  i = 0;
  return;
end

%% initialize
converged = 0;
i = 0;
V = V0;
Va = angle(V);
Vm = abs(V);

%% set up indexing for updating V
npv = length(pv);
npq = length(pq);

%% evaluate initial mismatch
mis = (V .* conj(Ybus * V) - Sbus) ./ Vm;
P = real(mis([pv; pq]));
Q = imag(mis(pq));

%% check tolerance
normP = norm(P, inf);
normQ = norm(Q, inf);
if normP < tol && normQ < tol
  converged = 1;
end

%% reduce B matrices
Bp = Bp([pv; pq], [pv; pq]);
Bpp = Bpp(pq, pq);

%% factor B matrices
[Lp, Up, Pp] = lu(Bp);
[Lpp, Upp, Ppp] = lu(Bpp);

%% do P and Q iterations
while (~converged && i < max_it)
    %% update iteration counter
    i = i + 1;

    %%-----  do P iteration, update Va  -----
    dVa = -( Up \  (Lp \ (Pp * P)));

    %% update voltage
    Va([pv; pq]) = Va([pv; pq]) + dVa;
    V = Vm .* exp(1j * Va);

    %% evalute mismatch
    mis = (V .* conj(Ybus * V) - Sbus) ./ Vm;
    P = real(mis([pv; pq]));
    Q = imag(mis(pq));
    
    %% check tolerance
    normP = norm(P, inf);
    normQ = norm(Q, inf);
    if normP < tol && normQ < tol
        converged = 1;
        break;
    end

    %%-----  do Q iteration, update Vm  -----
    dVm = -( Upp \ (Lpp \ (Ppp * Q)) );

    %% update voltage
    Vm(pq) = Vm(pq) + dVm;
    V = Vm .* exp(1j * Va);

    %% evalute mismatch
    mis = (V .* conj(Ybus * V) - Sbus) ./ Vm;
    P = real(mis([pv; pq]));
    Q = imag(mis(pq));
    
    %% check tolerance
    normP = norm(P, inf);
    normQ = norm(Q, inf);
    if normP < tol && normQ < tol
        converged = 1;
        break;
    end
end

end

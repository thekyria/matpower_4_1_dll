function [bus, gen, branch] = pfsoln(baseMVA, bus0, gen0, branch0, Ybus, Yf, Yt, V, ref, pv, pq)
%PFSOLN  Updates bus, gen, branch data structures to match power flow soln.
%   [BUS, GEN, BRANCH] = PFSOLN(BASEMVA, BUS0, GEN0, BRANCH0, ...
%                                   YBUS, YF, YT, V, REF, PV, PQ)

%   MATPOWER
%   $Id: pfsoln.m,v 1.20 2011/05/17 15:16:05 cvs Exp $
%   by Ray Zimmerman, PSERC Cornell
%   Copyright (c) 1996-2010 by Power System Engineering Research Center (PSERC)
%
%   This file is part of MATPOWER.
%   See http://www.pserc.cornell.edu/matpower/ for more info.
%
%   MATPOWER is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published
%   by the Free Software Foundation, either version 3 of the License,
%   or (at your option) any later version.
%
%   MATPOWER is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with MATPOWER. If not, see <http://www.gnu.org/licenses/>.
%
%   Additional permission under GNU GPL version 3 section 7
%
%   If you modify MATPOWER, or any covered work, to interface with
%   other modules (such as MATLAB code and MEX-files) available in a
%   MATLAB(R) or comparable environment containing parts covered
%   under other licensing terms, the licensors of MATPOWER grant
%   you additional permission to convey the resulting work.

%% define named indices into bus, gen, branch matrices
% bus related indexes
PD = 3;
QD = 4;
VM = 8;
VA = 9;
% generator related indexes
GEN_BUS = 1;
PG = 2;
QG = 3;
QMAX = 4;
QMIN = 5;
GEN_STATUS = 8;
% branch related indexes
F_BUS = 1;
T_BUS = 2;
BR_STATUS = 11;
PF = 14;
QF = 15;
PT = 16;
QT = 17;

%% initialize return values
bus     = bus0;
gen     = gen0;
branch  = branch0;

%%----- update bus voltages -----
bus(:, VM) = abs(V);
bus(:, VA) = angle(V) * 180 / pi;

%%----- update Qg for all gens and Pg for slack bus(es) -----
%% generator info
on = find(gen(:, GEN_STATUS) > 0);      %% which generators are on?
gbus = gen(on, GEN_BUS);                %% what buses are they at?

%% compute total injected bus powers
Sbus = V(gbus) .* conj(Ybus(gbus, :) * V);

%% update Qg for all generators
gen(:, QG) = zeros(size(gen, 1), 1);                %% zero out all Qg
gen(on, QG) = imag(Sbus) * baseMVA + bus(gbus, QD); %% inj Q + local Qd
%% ... at this point any buses with more than one generator will have
%% the total Q dispatch for the bus assigned to each generator. This
%% must be split between them. We do it first equally, then in proportion
%% to the reactive range of the generator.

if length(on) > 1
    %% build connection matrix, element i, j is 1 if gen on(i) at bus j is ON
    nb = size(bus, 1);
    ngon = size(on, 1);
    Cg = sparse((1:ngon)', gbus, ones(ngon, 1), ngon, nb);

    %% divide Qg by number of generators at the bus to distribute equally
    ngg = Cg * sum(Cg)';    %% ngon x 1, number of gens at this gen's bus
    gen(on, QG) = gen(on, QG) ./ ngg;

    %% divide proportionally
    Cmin = sparse((1:ngon)', gbus, gen(on, QMIN), ngon, nb);
    Cmax = sparse((1:ngon)', gbus, gen(on, QMAX), ngon, nb);
    Qg_tot = Cg' * gen(on, QG);     %% nb x 1 vector of total Qg at each bus
    Qg_min = sum(Cmin)';            %% nb x 1 vector of min total Qg at each bus
    Qg_max = sum(Cmax)';            %% nb x 1 vector of max total Qg at each bus
    ig = find(Cg * Qg_min == Cg * Qg_max);  %% gens at buses with Qg range = 0
    Qg_save = gen(on(ig), QG);
    gen(on, QG) = gen(on, QMIN) + ...
        (Cg * ((Qg_tot - Qg_min)./(Qg_max - Qg_min + eps))) .* ...
            (gen(on, QMAX) - gen(on, QMIN));    %%    ^ avoid div by 0
    gen(on(ig), QG) = Qg_save;
end                                             %% (terms are mult by 0 anyway)

%% update Pg for slack gen(s)
for k = 1:length(ref)
    refgen = find(gbus == ref(k));              %% which is(are) the reference gen(s)?
    gen(on(refgen(1)), PG) = real(Sbus(refgen(1))) * baseMVA ...
                            + bus(ref(k), PD);  %% inj P + local Pd
    if length(refgen) > 1       %% more than one generator at this ref bus
        %% subtract off what is generated by other gens at this bus
        gen(on(refgen(1)), PG) = gen(on(refgen(1)), PG) ...
                                - sum(gen(on(refgen(2:length(refgen))), PG));
    end
end

%%----- update/compute branch power flows -----
out = find(branch(:, BR_STATUS) == 0);      %% out-of-service branches
br = find(branch(:, BR_STATUS));            %% in-service branches
Sf = V(branch(br, F_BUS)) .* conj(Yf(br, :) * V) * baseMVA; %% complex power at "from" bus
St = V(branch(br, T_BUS)) .* conj(Yt(br, :) * V) * baseMVA; %% complex power injected at "to" bus
branch(br, [PF, QF, PT, QT]) = [real(Sf) imag(Sf) real(St) imag(St)];
branch(out, [PF, QF, PT, QT]) = zeros(length(out), 4);

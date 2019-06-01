function Sbus = makeSbus(baseMVA, bus, gen)
%MAKESBUS   Builds the vector of complex bus power injections.
%   SBUS = MAKESBUS(BASEMVA, BUS, GEN) returns the vector of complex bus
%   power injections, that is, generation minus load. Power is expressed
%   in per unit.
%
%   See also MAKEYBUS.

%   MATPOWER
%   $Id: makeSbus.m,v 1.13 2010/04/26 19:45:25 ray Exp $
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

%% define named indices into bus, gen matrices
% bus related indexes
PD = 3;
QD = 4;
% generator related indexes
GEN_BUS = 1;
PG = 2;
QG = 3;
GEN_STATUS = 8;

%% generator info
on = find(gen(:, GEN_STATUS) > 0);      %% which generators are on?
gbus = gen(on, GEN_BUS);                %% what buses are they at?

%% form net complex bus power injection vector
nb = size(bus, 1);
ngon = size(on, 1);
Cg = sparse(gbus, (1:ngon)', ones(ngon, 1), nb, ngon);  %% connection matrix
                                                        %% element i, j is 1 if
                                                        %% gen on(j) at bus i is ON
Sbus =  ( Cg * (gen(on, PG) + 1j * gen(on, QG)) ... %% power injected by generators
           - (bus(:, PD) + 1j * bus(:, QD)) ) / ... %% plus power injected by loads
        baseMVA;                                    %% converted to p.u.

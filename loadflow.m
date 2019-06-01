function [baseMVA, bus, gen, branch, success] = ...
  loadflow(baseMVAIn, busIn, genIn, branchIn, areasIn, gencostIn, qlim, dc, alg, tol, max_it )
%LOADFLOW Runs a loadflow
%   [BASEMVA, BUS, GEN, BRANCH, SUCCESS] = ...
%     LOADFLOW(BASEMVA, BUS, GEN, BRANCH, AREAS, GENCOST, QLIM, DC, ALG, TOL, MAX_IT)
%
%   If the ENFORCE_Q_LIMS option is set to true (default is false) then, if
%   any generator reactive power limit is violated after running the AC power
%   flow, the corresponding bus is converted to a PQ bus, with Qg at the
%   limit, and the case is re-run. The voltage magnitude at the bus will
%   deviate from the specified value in order to satisfy the reactive power
%   limit. If the reference bus is converted to PQ, the first remaining PV
%   bus will be used as the slack bus for the next iteration. This may
%   result in the real power output at this generator being slightly off
%   from the specified values.
%
%   qlim = 0;    enforce gen reactive power limits at expense of |V|
%                 0 - do NOT enforce limits
%                 1 - enforce limits, simultaneous bus type conversion
%                 2 - enforce limits, one-at-a-time bus type conversion
%   dc = 0;      DC modeling for power flow & OPF
%                 0 - use AC formulation & corresponding algorithm opts
%                 1 - use DC formulation, ignore AC algorithm options
%   alg = 1;     AC power flow algorithm
%                 1 - Newton's method            
%                 2 - Fast-Decoupled (XB version)
%                 3 - Fast-Decoupled (BX version)
%                 4 - Gauss-Seidel               
%   tol = 1e-8;  termination tolerance on per unit P & Q mismatch
%   max_it = 10; maximum number of iteration
%                 10 - for Newton's method
%                 30 - for Fast-Decoupled
%                 1000 - for Gauss-Seidel

%%-----  initialize  -----
%% define named indices into bus, gen, branch matrices
% bus related indexes
PQ = 1;
REF = 3;
BUS_TYPE = 2;
PD = 3;
QD = 4;
GS = 5;
VM = 8;
VA = 9;
% branch related indexes
PF = 14;
QF = 15;
PT = 16;
QT = 17;
% generator related indexes
GEN_BUS = 1;
PG = 2;
QG = 3;
QMAX = 4;
QMIN = 5;
VG = 6;
GEN_STATUS = 8;

%% initialize output arguments
success = 0;
baseMVA = 0;
bus = 0;
gen = 0;
branch = 0;

%% argument validation
if nargin < 5
  return;
end

% debug print
% display(baseMVAIn);
% display(busIn);
% display(genIn);
% display(branchIn);
% display(areasIn);
% display(gencostIn);

%% read input arguments
mpc.baseMVA = baseMVAIn;
mpc.bus = busIn;
mpc.gen = genIn;
mpc.branch = branchIn;
mpc.areas = areasIn;
mpc.gencost = gencostIn;

%% add zero columns to branch for flows if needed
if size(mpc.branch,2) < QT
  mpc.branch=[mpc.branch zeros(size(mpc.branch, 1), QT-size(mpc.branch,2))];
end

%% convert to internal indexing
mpc = ext2int(mpc);
baseMVA = mpc.baseMVA;
bus = mpc.bus;
gen = mpc.gen;
branch = mpc.branch;
display('loadflow(): Internal indexing created');

%% get bus index lists of each type of bus
[ref, pv, pq] = bustypes(bus, gen);
display('loadflow(): Bus index lists retrieved');

%% generator info
on = find(gen(:, GEN_STATUS) > 0);      %% which generators are on?
gbus = gen(on, GEN_BUS);                %% what buses are they at?
display('loadflow(): Generator info retrieved');

%%-----  run the power flow  -----
if dc                               %% DC formulation
  display('loadflow(): Running DC formulation');
  %% initial state
  Va0 = bus(:, VA) * (pi/180);
  display('loadflow(): Initial state calculated');
  
  %% build B matrices and phase shift injections
  [B, Bf, Pbusinj, Pfinj] = makeBdc(baseMVA, bus, branch);
  display('loadflow(): B matrix built');
  
  %% compute complex bus power injections (generation - load)
  %% adjusted for phase shifters and real shunts
  Pbus = real(makeSbus(baseMVA, bus, gen)) - Pbusinj - bus(:, GS) / baseMVA;
  display('loadflow(): Complex bus power injections computed');
  
  %% "run" the power flow
  Va = dcpf(B, Pbus, Va0, ref, pv, pq);
  display('loadflow(): DCPF run');
  
  %% update data matrices with solution
  branch(:, [QF, QT]) = zeros(size(branch, 1), 2);
  branch(:, PF) = (Bf * Va + Pfinj) * baseMVA;
  branch(:, PT) = -branch(:, PF);
  bus(:, VM) = ones(size(bus, 1), 1);
  bus(:, VA) = Va * (180/pi);
  display('loadflow(): Solution matrices update');
  %% update Pg for slack generator (1st gen at ref bus)
  %% (note: other gens at ref bus are accounted for in Pbus)
  %%      Pg = Pinj + Pload + Gs
  %%      newPg = oldPg + newPinj - oldPinj
  refgen = zeros(size(ref));
  for k = 1:length(ref)
    temp = find(gbus == ref(k));
    refgen(k) = on(temp(1));
  end
  gen(refgen, PG) = gen(refgen, PG) + (B(ref, :) * Va - Pbus(ref)) * baseMVA;
  display('loadflow(): Slack update');
  
  success = 1;
else                                %% AC formulation
  display('loadflow(): Running AC formulation');
  %% initial state
  % V0    = ones(size(bus, 1), 1);            %% flat start
  V0  = bus(:, VM) .* exp(sqrt(-1) * pi/180 * bus(:, VA));
  V0(gbus) = gen(on, VG) ./ abs(V0(gbus)).* V0(gbus);
  
  if qlim
    ref0 = ref;                         %% save index and angle of
    Varef0 = bus(ref0, VA);             %%   original reference bus(es)
    limited = [];                       %% list of indices of gens @ Q lims
    fixedQg = zeros(size(gen, 1), 1);   %% Qg of gens at Q limits
  end
  repeat = 1;
  display('loadflow(): Initial state calculated');
  while (repeat)
    %% build admittance matrices
    [Ybus, Yf, Yt] = makeYbus(baseMVA, bus, branch);
    
    %% compute complex bus power injections (generation - load)
    Sbus = makeSbus(baseMVA, bus, gen);
    
    %% run the power flow
    if alg == 1
      [V, success, iterations] = newtonpf(Ybus, Sbus, V0, ref, pv, pq, tol, max_it);
    elseif alg == 2 || alg == 3
      [Bp, Bpp] = makeB(baseMVA, bus, branch, alg);
      [V, success, iterations] = fdpf(Ybus, Sbus, V0, Bp, Bpp, ref, pv, pq, tol, max_it);
    elseif alg == 4
      [V, success, iterations] = gausspf(Ybus, Sbus, V0, ref, pv, pq, tol, max_it);
    else
      success = 0;
      break;
    end
    
    %% update data matrices with solution
    [bus, gen, branch] = pfsoln(baseMVA, bus, gen, branch, Ybus, Yf, Yt, V, ref, pv, pq);
    
    if qlim             %% enforce generator Q limits
      %% find gens with violated Q constraints
      mx = find( gen(:, GEN_STATUS) > 0 & gen(:, QG) > gen(:, QMAX) );
      mn = find( gen(:, GEN_STATUS) > 0 & gen(:, QG) < gen(:, QMIN) );
      
      if ~isempty(mx) || ~isempty(mn)  %% we have some Q limit violations
        if isempty(pv)
          success = 0;
          break;
        end
        
        %% one at a time?
        if qlim == 2    %% fix largest violation, ignore the rest
          [~, k] = max([gen(mx, QG) - gen(mx, QMAX);
            gen(mn, QMIN) - gen(mn, QG)]);
          if k > length(mx)
            mn = mn(k-length(mx));
            mx = [];
          else
            mx = mx(k);
            mn = [];
          end
        end
        
        %% save corresponding limit values
        fixedQg(mx) = gen(mx, QMAX);
        fixedQg(mn) = gen(mn, QMIN);
        mx = [mx;mn];
        
        %% convert to PQ bus
        gen(mx, QG) = fixedQg(mx);      %% set Qg to binding limit
        gen(mx, GEN_STATUS) = 0;        %% temporarily turn off gen,
        for i = 1:length(mx)            %% (one at a time, since
          bi = gen(mx(i), GEN_BUS);   %%  they may be at same bus)
          bus(bi, [PD,QD]) = ...      %% adjust load accordingly,
            bus(bi, [PD,QD]) - gen(mx(i), [PG,QG]);
        end
        if length(ref) > 1 && any(bus(gen(mx, GEN_BUS), BUS_TYPE) == REF)
          error('Sorry, MATPOWER cannot enforce Q limits for slack buses in systems with multiple slacks.');
        end
        bus(gen(mx, GEN_BUS), BUS_TYPE) = PQ;   %% & set bus type to PQ
        
        %% update bus index lists of each type of bus
        [ref, pv, pq] = bustypes(bus, gen);
        limited = [limited; mx];
      else
        repeat = 0; %% no more generator Q limits violated
      end
    else
      repeat = 0;     %% don't enforce generator Q limits, once is enough
    end
  end
  display('loadflow(): ACPF main loop terminated');
  if qlim && ~isempty(limited)
    %% restore injections from limited gens (those at Q limits)
    gen(limited, QG) = fixedQg(limited);    %% restore Qg value,
    for i = 1:length(limited)               %% (one at a time, since
      bi = gen(limited(i), GEN_BUS);      %%  they may be at same bus)
      bus(bi, [PD,QD]) = ...              %% re-adjust load,
        bus(bi, [PD,QD]) + gen(limited(i), [PG,QG]);
    end
    gen(limited, GEN_STATUS) = 1;               %% and turn gen back on
    display('loadflow(): Injections for Q-limited gens restored');
    if ref ~= ref0
      %% adjust voltage angles to make original ref bus correct
      bus(:, VA) = bus(:, VA) - bus(ref0, VA) + Varef0;
      display('loadflow(): Voltage angles adjusted');
    end
  end
end

mpc.success = success;

%%-----  output results  -----
%% convert back to original bus numbering & print results
mpc.bus = bus;
mpc.gen = gen;
mpc.branch = branch;
results = int2ext(mpc);

%% zero out result fields of out-of-service gens & branches
if ~isempty(results.order.gen.status.off)
  results.gen(results.order.gen.status.off, [PG QG]) = 0;
end
if ~isempty(results.order.branch.status.off)
  results.branch(results.order.branch.status.off, [PF QF PT QT]) = 0;
end

%% save solved case
baseMVA = results.baseMVA;
bus = results.bus;
gen = results.gen;
branch = results.branch;
display('loadflow(): Loadflow succesfully completed!');

end
%% ֱ�����ų��� DC Optimal Power Flow

%% YALMIP

% ���ߣ������
% ���䣺luoqingju@qq.com
% ��������ѧ����ѧԺ
% �ۺ��ǻ���Դϵͳ�Ż�����������Ŷ� ISESOOC ��˼��

clc
clear

%% Small Transmission System Test Cases
% mpc0 = case6ww;
% mpc0 = case9;
mpc0 = case14;
% mpc0 = case24_ieee_rts;
% mpc0 = case30;
% mpc0 = case_ieee30;
% mpc0 = case39;
% mpc0 = case57;
% mpc0 = case118;
% mpc0 = case145;
% mpc0 = case300;

%% PEGASE European System Test Cases
% mpc0 = case89pegase;
% mpc0 = case1354pegase;
% mpc0 = case2869pegase;
% mpc0 = case9241pegase;
% mpc0 = case13659pegase;

%% RTE French System Test Cases
% mpc0 = case1888rte;
% mpc0 = case1951rte;
% mpc0 = case2848rte;
% mpc0 = case2868rte;
% mpc0 = case6468rte;
% mpc0 = case6470rte;
% mpc0 = case6495rte;
% mpc0 = case6515rte;

%%  Polish System Test Cases
% mpc0 = case2383wp;
% mpc0 = case2736sp;
% mpc0 = case2737sop;
% mpc0 = case2746wop;
% mpc0 = case2746wp;
% mpc0 = case3012wp;
% mpc0 = case3120sp;
% mpc0 = case3375wp;

%%  ACTIV Synthetic Grid Test Cases
% mpc0 = case_ACTIVSg200;
% mpc0 = case_ACTIVSg500;
% mpc0 = case_ACTIVSg2000;
% mpc0 = case_ACTIVSg10k;
% mpc0 = case_ACTIVSg25k;
% mpc0 = case_ACTIVSg70k;

%% ��ʼ����������
init_case;

%% ���߱���
Pg = sdpvar(ng, 1, 'full'); % �������
Pl = sdpvar(nl, 1, 'full'); % ��·�й�
Va = sdpvar(nb, 1, 'full'); % ��ѹ���

%% Լ������
cons = []; % ��ʼ��Լ��
cons = [cons, Cg * Pg - Cl * Pl == Pd + Gs]; % �ڵ㹦��ƽ��
cons = [cons, Pl == Cl' * Va ./ BR_x + Pfinj]; % ��·����Լ��
cons = [cons, Va(slack) == Va_ref]; % ƽ��ڵ��ѹ���Լ��
cons = [cons, Pmin <= Pg <= Pmax]; %#ok<*CHAIN> % ���������������
cons = [cons, -flow_max <= Pl <= flow_max]; % ��·����������

%% Ŀ�꺯��
obj = (Pg .* Qpg)' * Pg + cpg' * Pg + sum(kpg); % ����ɱ�

%% ���
ops = sdpsettings('verbose', 2, 'solver', 'gurobi');
sol = optimize(cons, obj, ops);

% ���������־
if sol.problem ~= 0
    sol.info
    yalmiperror(sol.problem)
    return
end
obj = value(obj);
Pg = value(Pg);
Pl = value(Pl);
Va = value(Va);

%% ��MATPOWER�Ա�
res = rundcopf(mpc0);

disp('ϵͳ�ܳɱ�������')
disp(norm(res.f-obj))
disp('ϵͳ�ܳɱ������')
disp(norm((res.f - obj)/res.f))

% �����ж�����Ž⣬�������Ž���ܲ�һ��
% disp('���������������')
% disp(norm( res.gen(res.gen(:, GEN_STATUS)>0, PG)./mpc0.baseMVA - Pg ))
% disp('��·�й����ʾ�����')
% disp(norm( res.branch(res.branch(:, BR_STATUS)==1, PF)./mpc0.baseMVA - Pl ))
% disp('��ѹ��Ǿ�����')
% disp(norm( res.bus(:, VA)./180.*pi - Va ))

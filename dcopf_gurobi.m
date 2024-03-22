%% ֱ�����ų��� DC Optimal Power Flow

%% GUROBI

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

%% ���߱�������
nx = 0; % ������
idx_x_Pg = nx + (1:ng)'; % �����������
nx = nx + ng;
idx_x_Pl = nx + (1:nl)'; % ��·�й�����
nx = nx + nl;
idx_x_Va = nx + (1:nb)'; % ��ѹ�������
nx = nx + nb;

%% Լ����������

ne = 0; % ��ʽԼ����
idx_e_bus = ne + (1:nb)'; % �ڵ㹦��ƽ��Լ������
ne = ne + nb;
idx_e_Pl = ne + (1:nl)'; % ��·����Լ������
ne = ne + nl;
idx_e_Va_ref = ne + 1; % ƽ��ڵ��ѹ���Լ������
ne = ne + 1;

ni = 0; % ����ʽԼ����
% ������������Լ������ֱ�����뵽gurobi�У�һ�㲻��ҪдΪ����ʽԼ��

%% Լ������
Ae = sparse(ne, nx); % ��ʽԼ�� Ae * x = be
be = zeros(ne, 1); % ��ʽԼ�� Ae * x = be
Ai = sparse(ni, nx); % ����ʽԼ�� Ai * x <= bi
bi = zeros(ni, 1); % ����ʽԼ�� Ai * x <= bi

% cons = [cons, Cg * Pg - Cl * Pl == Pd + Gs]; % �ڵ㹦��ƽ��
Ae(idx_e_bus, idx_x_Pg) = Cg;
Ae(idx_e_bus, idx_x_Pl) = -Cl;
be(idx_e_bus) = Pd + Gs;

% cons = [cons, Pl == Cl' * Va ./ BR_x + Pfinj]; % ��·����Լ��
Ae(idx_e_Pl, idx_x_Pl) = speye(nl);
Ae(idx_e_Pl, idx_x_Va) = -sparse(1:nl, 1:nl, 1./BR_x, nl, nl) * Cl';
be(idx_e_Pl) = Pfinj;

% cons = [cons, Va(slack) == Va_ref]; % ƽ��ڵ��ѹ���Լ��
Ae(idx_e_Va_ref, idx_x_Va(slack)) = 1;
be(idx_e_Va_ref) = Va_ref;

%% ����������
lb = -Inf(nx, 1); % ��ʼ������������
ub = Inf(nx, 1);

% cons = [cons, Pmin <= Pg <= Pmax]; %#ok<*CHAIN> % ���������������
lb(idx_x_Pg) = Pmin; % ���������������
ub(idx_x_Pg) = Pmax;

% cons = [cons, -flow_max <= Pl <= flow_max]; % ��·����������
lb(idx_x_Pl) = -flow_max; % ��·����������
ub(idx_x_Pl) = flow_max;

%% Ŀ�꺯��
% obj = (Pg .* Qpg)' * Pg + cpg' * Pg + sum(kpg); % ����ɱ�
Q = sparse(nx, nx);
Q(idx_x_Pg, idx_x_Pg) = sparse(1:ng, 1:ng, Qpg, ng, ng);
c = zeros(nx, 1);
c(idx_x_Pg) = cpg;

%% ���
model.Q = Q;
model.obj = c;
model.A = [Ai; Ae];
model.rhs = [bi; be];
model.sense = [char('<'*ones(ni, 1)); char('='*ones(ne, 1))];
model.vtype = char('c'*ones(nx, 1));
model.modelsense = 'min';
model.lb = lb;
model.ub = ub;
model.objcon = sum(kpg);

result = gurobi(model);
if (strcmp(result.status, 'OPTIMAL') == 1)
    x = result.x;
else
    result.status
    return
end

obj = result.objval;
Pg = x(idx_x_Pg);
Pl = x(idx_x_Pl);
Va = x(idx_x_Va);

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

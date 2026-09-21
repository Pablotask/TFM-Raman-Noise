%% PRUEBA DEFINITIVA DE CARACTERIZACIÓN DE SCATTERING RAMAN STOKES
% CON CONEXIÓN A INTERNET; ESCENARIO REAL DE COMUNICACIONES ÓPTICAS
%%%%%%%%%%%%%% (signal moved from 1550nm to 1310nm) %%%%%%%%%%%%%%

clear;
close all;
clc;

% ==========================================================
% Parámetros iniciales
% ==========================================================

% Distancias (km)
L = [0 2 10 12];

% Potencia del láser TX menos lo correspondiente a la salida 10% del
% divisor de haz 90:10
P_dBm = -17.46;
P_W = 1e-3*10^(P_dBm/10);

% Fichero fijo de referencia --> dark counts per second
dark      = readtable('counter_trace_dark_counts.csv');

% Atenuaciones (medidas normalizadas de Np/km)
alpha1_eff = ((0.185*2/11.795)+(0.248*9.795/11.795)); % 1550 nm
alpha1 = alpha1_eff/4.343; 
alpha2_eff = ((0.378*2/11.795)+(0.355*9.795/11.795)); % 1310 nm
alpha2 = alpha2_eff/4.343;
delta = alpha2-alpha1; 

% Parámetros detector
T_gate = 5e-9;
Tau    = 10e-6;
eta    = 0.10;
f      = 50e6;

% Parámetros propios de la energía del fotón
h = 6.62607015e-34; 
c = 299792458; 
lambda = 1550e-9; 
Eph = h*c/lambda; 

% ==========================================================
% Parámetros del bootstrap para L = 0 m
% ==========================================================
B_boot = 10000;          % número de réplicas bootstrap
conf_boot = 0.95;        % nivel de confianza
alpha_boot = 1-conf_boot;

% ==========================================================
% Cargar ficheros
% ==========================================================

d0   = readtable('antistokes_conexion_internet_sin_distancia.csv');
d2   = readtable('antistokes_conexion_internet_2km.csv');
d10  = readtable('antistokes_conexion_internet_10km.csv');
d12  = readtable('antistokes_conexion_internet_12km.csv');

% ==========================================================
% Extraer cuentas
% ==========================================================

y1 = dark{:,2};
y2 = d0{:,2};
y3 = d2{:,2};
y4 = d10{:,2};
y5 = d12{:,2};

% ==========================================================
% Igualar tamaños para boxplot
% ==========================================================

N = min([length(y1),length(y2), ...
         length(y3),length(y4), ...
         length(y5)]);

datos = [y1(1:N), y2(1:N), ...
         y3(1:N), y4(1:N), ...
         y5(1:N)];

% ==========================================================
% Boxplots
% ==========================================================

% figure('Color','w','Position',[100 100 1400 550])
% 
% boxplot(datos,...
%     'Labels',{'Dark','0 m','2 km',...
%               '10 km','12 km'},...
%     'Symbol','.');
% 
% h = findobj(gca,'Tag','Box');
% 
% colores = [
%     0.15 0.15 0.15
%     0.00 0.45 0.74
%     0.00 0.75 0.75
%     0.47 0.67 0.19
%     0.93 0.69 0.13
%     0.85 0.33 0.10
%     0.64 0.08 0.18
%     0.49 0.18 0.56
%     1.00 0.00 0.70
% ];
% 
% for j = 1:length(h)
%     patch(get(h(j),'XData'),...
%           get(h(j),'YData'),...
%           colores(end-j+1,:),...
%           'FaceAlpha',0.75);
% end
% 
% hold on
% 
% medias = mean(datos);
% 
% plot(1:length(datos(1,:)),medias,...
%     'kd',...
%     'MarkerFaceColor','k',...
%     'MarkerSize',8)
% 
% grid on
% 
% ylabel('Cuentas por segundo')
% title(['Scattering Raman Anti-Stokes (' sufijo ')'])
% 
% set(gca,'FontSize',12)

% ==========================================================
% Raman neto
%
% Para L = 0 km:
%   se hace un bootstrap de la diferencia de medias
%   entre las cuentas medidas y las cuentas en oscuridad.
%
% Para el resto de longitudes:
%   se mantiene el cálculo original, restando dark_mean.
% ==========================================================

% Corrección muestra a muestra
dark_counts = y1 ./ (1 - y1 .* Tau);

Raman = zeros(4,1);
Raman_std = zeros(4,1);


% ==========================================================
% CASO L = 0 km --> BOOTSTRAP
% ==========================================================

n_dark = length(y1);
n_0km  = length(y2);

boot_diff = zeros(B_boot,1);

for b = 1:B_boot

    % Remuestreo con reemplazamiento
    idx_dark = randi(n_dark, n_dark, 1);
    idx_0km  = randi(n_0km, n_0km, 1);

    % Datos remuestreados
    y_dark_boot = y1(idx_dark);
    y_0km_boot  = y2(idx_0km);

    % Corrección de tiempo muerto muestra a muestra
    y_dark_corr = y_dark_boot ./ (1 - y_dark_boot .* Tau);
    y_0km_corr  = y_0km_boot  ./ (1 - y_0km_boot  .* Tau);

    % Diferencia de medias corregidas para esta réplica
    boot_diff(b) = mean(y_0km_corr) - mean(y_dark_corr);

end

% Intervalo de confianza bootstrap percentil
CI_0km = prctile(boot_diff, ...
    [100*alpha_boot/2, 100*(1-alpha_boot/2)]);

% Incertidumbre bootstrap de la diferencia
Raman_std(1) = std(boot_diff);


% ==========================================================
% DIFERENCIA OBSERVADA A 0 km
% ==========================================================

% Corrección de tiempo muerto
y2_corr = y2 ./ (1 - y2 .* Tau);

% Raman neto observado
Raman_0km_obs = mean(y2_corr) - mean(dark_counts);

% ¿Existe evidencia de un exceso positivo respecto a dark?
Raman0_detectado = CI_0km(1) > 0;


% ==========================================================
% RESTO DE LONGITUDES
% ==========================================================

% Corrección por tiempo muerto
y3_corr = y3 ./ (1 - y3 .* Tau);
y4_corr = y4 ./ (1 - y4 .* Tau);
y5_corr = y5 ./ (1 - y5 .* Tau);

% Raman neto
Raman(1) = Raman_0km_obs;                       % 0 km --> Graficamos igualmente
Raman(2) = mean(y3_corr) - mean(dark_counts);   % 2 km
Raman(3) = mean(y4_corr) - mean(dark_counts);   % 10 km
Raman(4) = mean(y5_corr) - mean(dark_counts);   % 12 km

% Desviación típica de los valores corregidos
Raman_std(2) = std(y3_corr);
Raman_std(3) = std(y4_corr);
Raman_std(4) = std(y5_corr);


% ==========================================================
% MOSTRAR ESTADÍSTICAS
% ==========================================================

fprintf('\n====================================================\n');
fprintf('Resultados para la potencia de transmisión\n');
fprintf('====================================================\n');

nombres = {'0 km','2 km','10 km','12 km'};

for k = 1:length(Raman)

    fprintf('%s\n',nombres{k});
    fprintf('   Raman medio = %.2f cps\n',Raman(k));
    fprintf('   Desviación típica = %.2f cps\n',Raman_std(k));

    if k == 1

        fprintf('   IC bootstrap %.1f%% = [%.2f, %.2f] cps\n',...
            100*conf_boot,...
            CI_0km(1),...
            CI_0km(2));

        if Raman0_detectado
            fprintf('   Resultado: exceso positivo respecto a dark\n');
        else
            fprintf('   Resultado: no se distingue de dark\n');
        end

        fprintf('\n');

    end

end

% % Traspaso de unidades: cps a dBm
% R_ideal = ((R./(1-R.*Tau))-(dark_mean/(1-dark_mean*Tau)));
% % Pclick = 1-e.^(-eta*mu) --> R_ideal = P_click*f =  [1-e.^(-eta*mu)]*f
% % 1-(R_ideal/f) = e.^(-eta*mu) --> Ln(1-(R_ideal/f)) = -eta*mu -->
% % mu = -[Ln(1-(R_ideal/f))]/eta
% mu = -[log(1-(R_ideal./f))]/eta;
% Prx_Raman_dBm = 10*log10((mu.*E_foton_1550nm*1000)/T_gate);

% Corrección del tiempo muerto (dark counts ya restadas)
R_corr = Raman./(1-Raman*Tau);
R_net = R_corr;
R_net(R_net<0)=0;

% Tasa media de fotones (por ventana de detección)
Pclick = R_net/f;
mu = -log(1-Pclick)/eta;

% Potencia Raman equivalente (W)
Praman = mu*Eph/T_gate;

%=========================================================
% Ajuste del modelo físico del paper (ecuación 3)
% Caso particular --> alpha1 ~= alpha2
%=========================================================

%%%%%%%%%%%% Ajuste global %%%%%%%%%%%%

Lfit = L(:);
Ptx = P_W*ones(size(Lfit));
Y = Praman(:);

% Fórmula del paper --> Y=Aβ2​+ε, modelo lineal clásico 
% con A conocida, Beta2 desconocida y épsilon el error experimental
A = Ptx./delta.*(exp(-alpha1*Lfit)-exp(-alpha2*Lfit));

% Estimador de mínimos cuadrados --> Se pretende resolver el problema
% J(β2​)=i=1∑N​(yi​−β2​Ai​)^2, que se traduce en J(β2​)=(Y−Aβ2​)T(Y−Aβ2​)
% Derivando con respecto a Beta2, igualando a 0 y despejando beta2,
% se obtiene la siguiente expresión:
beta1 = (A'*Y)/(A'*A);

% Predicción 
Ymodelo = beta1*A;

% Residuos
res = Y-Ymodelo;

% Error cuadrático medio
MSE = mean(res.^2);

% Varianza residual
sigma2 = sum(res.^2)/(length(Y)-1);

% Incertidumbre de beta2
sigma_beta = sqrt(sigma2/(A'*A));

% Cómputo de resultados de estimación y error
fprintf('AJUSTE GLOBAL\n');
fprintf('beta1 = %.3e ± %.3e km^-1\n',beta1,sigma_beta);
fprintf('MSE  = %.3e W^2\n',MSE);
fprintf('\n');

%=========================================================
% Comparación entre medidas experimentales y modelo
%=========================================================

figure('Color','w','Position',[250 150 900 600]);
hold on
grid on
box on

scatter(L,...
        10*log10(Praman*1000),...
        90,...
        'filled',...
        'MarkerFaceColor',[0 0.45 0.74]);

xx = linspace(0,12.15,500);

Axx = P_W/delta.*(exp(-alpha1*xx)-exp(-alpha2*xx));

Ymodelo = beta1*Axx;

plot(xx,...
     10*log10(Ymodelo*1000),...
     '--',...
     'Color','r',...
     'LineWidth',2);

xlabel('Longitud de fibra (km)','FontSize',14)
ylabel('Potencia Raman (dBm)','FontSize',14)

title('Modelo Raman AntiStokes - Escenario de comunicaciones real','FontSize',16)

legend('Datos experimentales',...
       'Modelo teórico',...
       'Location','best')

set(gca,'FontSize',13)



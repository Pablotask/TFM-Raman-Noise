%% PRUEBA DEFINITIVA DE CARACTERIZACIÓN DE SCATTERING RAMAN ANTI-STOKES 
%%%%%%%%%%%%%%%% (signal moved from 1310nm to 1550nm) %%%%%%%%%%%%%%%%

clear;
close all;
clc;

% ==========================================================
% Parámetros iniciales
% ==========================================================

% Distancias (km)
L = [0 2 10 12];

% Potencias (dBm)
potencias_dBm = [0 4 8 12];
potencias = {'0dBm','4dBm','8dBm','12dBm'};

% Fichero fijo de referencia --> dark counts per second
dark      = readtable('counter_trace_antistokes_dark_counts.csv');

% Configuración de colores para el ajuste de las curvas
coloresPotencia = [
    0.00 0.45 0.74   % azul
    0.85 0.33 0.10   % naranja
    0.47 0.67 0.19   % verde
    0.49 0.18 0.56   % morado
];

% Guardado sucesivo de las curvas 
Praman_all = []; 
Longitudes_all = []; 
PotenciaTX_all = []; 

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

% Identificador de cada escenario (potencia)
marcadores = {'o','s','^','d'};

% ==========================================================
% Parámetros del bootstrap para L = 0 m
% ==========================================================
B_boot = 10000;          % número de réplicas bootstrap
conf_boot = 0.95;        % nivel de confianza
alpha_boot = 1-conf_boot;

rng(1);                  % para reproducibilidad

for p = 1:length(potencias)

    sufijo = potencias{p};

    % ==========================================================
    % Cargar ficheros
    % ==========================================================

    d0        = readtable(['counter_trace_antistokes_sindistancia_' sufijo '.csv']);
    %d150      = readtable(['counter_trace_antistokes_150m_' sufijo '.csv']);
    d2km      = readtable(['counter_trace_antistokes_2km_' sufijo '.csv']);
    %d2km150   = readtable(['counter_trace_antistokes_2km150m_' sufijo '.csv']);
    d10km     = readtable(['counter_trace_antistokes_10km_' sufijo '.csv']);
    %d10km150  = readtable(['counter_trace_antistokes_10km150m_' sufijo '.csv']);
    d12km     = readtable(['counter_trace_antistokes_12km_' sufijo '.csv']);
    %d12km150  = readtable(['counter_trace_antistokes_12km150m_' sufijo '.csv']);

    % ==========================================================
    % Extraer cuentas
    % ==========================================================

    y1 = dark{:,2};
    y2 = d0{:,2};
    %y3 = d150{:,2};
    %y3 = y3(y3~=0);
    y3 = d2km{:,2};
    %y5 = d2km150{:,2};
    y4 = d10km{:,2};
    %y7 = d10km150{:,2};
    y5 = d12km{:,2};
    %y9 = d12km150{:,2};

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

    figure('Color','w','Position',[100 100 1400 550])

    boxplot(datos,...
        'Labels',{'Dark','0 km','2 km',...
                  '10 km','12 km'},...
        'Symbol','.');

    h = findobj(gca,'Tag','Box');

    colores = [
        0.15 0.15 0.15
        0.00 0.45 0.74
        0.00 0.75 0.75
        0.47 0.67 0.19
        0.93 0.69 0.13
        0.85 0.33 0.10
        0.64 0.08 0.18
        0.49 0.18 0.56
        1.00 0.00 0.70
    ];

    for j = 1:length(h)
        patch(get(h(j),'XData'),...
              get(h(j),'YData'),...
              colores(end-j+1,:),...
              'FaceAlpha',0.75);
    end

    hold on

    medias = mean(datos);

    plot(1:length(datos(1,:)),medias,...
        'kd',...
        'MarkerFaceColor','k',...
        'MarkerSize',8)

    grid on

    ylabel('Cuentas por segundo')
    title(['Scattering Raman Anti-Stokes (' sufijo ')'])

    set(gca,'FontSize',12)

    % ==========================================================
    % Histogramas
    % ==========================================================

    figure('Color','w','Position',[100 100 1400 550])

    etiquetas = {'Dark','0 m','2 km','10 km','12 km'};

    % Límites comunes para todos los histogramas
    datos_validos = datos(~isnan(datos));
    edges = linspace(min(datos_validos),max(datos_validos),21);

    tiledlayout(1,5,'TileSpacing','compact','Padding','compact');

    for j = 1:size(datos,2)

        nexttile

        histogram(datos(:,j),...
            'BinEdges',edges,...
            'FaceColor',colores(end-j+1,:),...
            'FaceAlpha',0.75,...
            'EdgeColor','k');

        grid on
        xlabel('Cuentas por segundo')
        ylabel('Frecuencia')
        title(etiquetas{j})

        set(gca,'FontSize',12)

    end

    sgtitle(['Distribuciones de cuentas Raman Anti-Stokes (TX ' sufijo ')'],...
    'FontSize',18,...
    'FontWeight','bold');

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
    
    dark_counts = y1 ./ (1 - y1 .* Tau);
    
    Raman = zeros(4,1);
    Raman_std = zeros(4,1);
    
    % ==========================================================
    % CASO L = 0 km --> BOOTSTRAP
    % ==========================================================
    
    n_dark = length(y1);
    n_0m   = length(y2);
    
    boot_diff = zeros(B_boot,1);
    
    for b = 1:B_boot
    
        % Remuestreo con reemplazamiento
        idx_dark = randi(n_dark, n_dark, 1);
        idx_0m   = randi(n_0m, n_0m, 1);
        
        % Datos remuestreados
        y_dark_boot = y1(idx_dark);
        y_0m_boot   = y2(idx_0m);
        
        % Corrección de tiempo muerto muestra a muestra
        y_dark_corr = y_dark_boot ./ (1 - y_dark_boot .* Tau);
        y_0m_corr   = y_0m_boot   ./ (1 - y_0m_boot   .* Tau);
        
        % Diferencia de medias corregidas para esta réplica
        boot_diff(b) = mean(y_0m_corr) - mean(y_dark_corr);
    
    end
    
    % Intervalo de confianza bootstrap percentil
    CI_0m = prctile(boot_diff, ...
        [100*alpha_boot/2, 100*(1-alpha_boot/2)]);
    
    % Incertidumbre bootstrap de la diferencia
    Raman_std(1) = std(boot_diff);
    
    % Diferencia de medias observada, con corrección de tiempo muerto
    y2_corr = y2 ./ (1 - y2 .* Tau);
    
    Raman_0m_obs = mean(y2_corr) - mean(dark_counts);
    
    % ¿Existe evidencia de un exceso positivo respecto a dark?
    Raman0_detectado = CI_0m(1) > 0;
    
    if Raman0_detectado
    
        % Hay evidencia de un exceso positivo
        Raman(1) = Raman_0m_obs;
    
    else
    
        % No se puede distinguir de las cuentas en oscuridad
        % Raman(1) = NaN; 
        % --> si queremos lo que grafique igualmente, comentamos esta línea
    
    end
    
    
    % ==========================================================
    % RESTO DE LONGITUDES --> MÉTODO ORIGINAL
    % ==========================================================
    
    % Corrección por tiempo muerto
    y3_corr = y3 ./ (1 - y3 .* Tau);
    y4_corr = y4 ./ (1 - y4 .* Tau);
    y5_corr = y5 ./ (1 - y5 .* Tau);
    
    % Raman neto
    Raman(1) = Raman_0m_obs;               % 0 km --> Graficamos igualmente
    Raman(2) = mean(y3_corr) - mean(dark_counts);  % 2 km
    Raman(3) = mean(y4_corr) - mean(dark_counts);  % 10 km
    Raman(4) = mean(y5_corr) - mean(dark_counts);  % 12 km
    
    % Desviación típica de los valores corregidos
    Raman_std(1) = std(y2_corr);
    Raman_std(2) = std(y3_corr);
    Raman_std(3) = std(y4_corr);
    Raman_std(4) = std(y5_corr);

    fprintf('\n==================================================\n');
    fprintf('Potencia TX = %s\n',sufijo);
    fprintf('====================================================\n');
    
    nombres = {'0 km','2 km','10 km','12 km'};
    
    for k = 1:length(Raman)
    
        fprintf('%s\n',nombres{k});
        fprintf('   Raman medio = %.2f cps\n',Raman(k));
        fprintf('   Desviación típica = %.2f cps\n',Raman_std(k));
    
        if k == 1
    
            fprintf('   IC bootstrap %.1f%% = [%.2f, %.2f] cps\n',...
                100*conf_boot,...
                CI_0m(1),...
                CI_0m(2));
    
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
    
    R_net = Raman;
   
    % Tasa media de fotones (por ventana de detección)
    Pclick = R_net/f;
    mu = -log(1-Pclick)/eta;
   
    % Potencia Raman equivalente (W)
    Praman = mu*Eph/T_gate;
    % Potencias incidentes (dBm --> W)
    P_dBm = potencias_dBm(p);
    P_W = 1e-3*10^(P_dBm/10);

    % Variables de acumulación
    Praman_all = [Praman_all, Praman]; 
    Longitudes_all = [Longitudes_all, L]; 
    PotenciaTX_all = [PotenciaTX_all, P_W*ones(size(L))];
    
end

%=========================================================
% Ajuste del modelo físico del paper (ecuación 3)
% Caso particular --> alpha1 ~= alpha2
%=========================================================

%%%%%%%%%%%% Ajuste global %%%%%%%%%%%%

Lfit = Longitudes_all(:);
Ptx  = PotenciaTX_all(:);
Y    = Praman_all(:);

% Fórmula del paper --> Y=Aβ2​+ε, modelo lineal clásico 
% con A conocida, Beta2 desconocida y épsilon el error experimental
A = Ptx./delta.*(exp(-alpha1*Lfit)-exp(-alpha2*Lfit));

% Estimador de mínimos cuadrados --> Se pretende resolver el problema
% J(β2​)=i=1∑N​(yi​−β2​Ai​)^2, que se traduce en J(β2​)=(Y−Aβ2​)T(Y−Aβ2​)
% Derivando con respecto a Beta2, igualando a 0 y despejando beta2,
% se obtiene la siguiente expresión:
beta2 = (A'*Y)/(A'*A);

% Predicción 
Ymodelo = beta2*A;

% Residuos
res = Y-Ymodelo;

% Error cuadrático medio
MSE = mean(res.^2);

% Varianza residual
sigma2 = sum(res.^2)/(length(Y)-1);

% Incertidumbre de beta2
sigma_beta = sqrt(sigma2/(A'*A));

% Cómputo de resultados de estimación y error
fprintf('\nAJUSTE GLOBAL\n');
fprintf('beta2 = %.3e ± %.3e km^-1\n',beta2,sigma_beta);
fprintf('MSE  = %.3e W^2\n',MSE);
fprintf('\n');
fprintf('AJUSTE INDIVIDUAL\n');

%%%%%%%%%%%% Ajuste individual %%%%%%%%%%%%

beta_ind  = zeros(length(potencias),1);
sigma_ind = zeros(length(potencias),1);
MSE_ind   = zeros(length(potencias),1);

for p = 1:length(potencias)

    P_W = 1e-3*10^(potencias_dBm(p)/10);

    idx = abs(PotenciaTX_all-P_W)<1e-15;

    Lp = Longitudes_all(idx).';
    Yp = Praman_all(idx).';

    % Fórmula del paper --> Y=Aβ2​+ε, modelo lineal clásico 
    % con A conocida, Beta2 desconocida y épsilon el error experimental
    Ap = P_W/delta.*(exp(-alpha1*Lp)-exp(-alpha2*Lp));

    % Estimador de mínimos cuadrados --> Se pretende resolver el problema
    % J(β2​)=i=1∑N​(yi​−β2​Ai​)^2, que se traduce en J(β2​)=(Y−Aβ2​)T(Y−Aβ2​)
    % Derivando con respecto a Beta2, igualando a 0 y despejando beta2,
    % se obtiene la siguiente expresión:
    beta_ind(p) = (Ap'*Yp)/(Ap'*Ap);

    % Predicción 
    Ym = beta_ind(p)*Ap;

    % Residuos
    res = Yp-Ym;

    % Error cuadrático medio
    MSE_ind(p) = mean(res.^2);

    % Varianza residual
    sigma2 = sum(res.^2)/(length(Yp)-1);

    % Incertidumbre de beta2
    sigma_ind(p) = sqrt(sigma2/(Ap'*Ap));

    % Cómputo de resultados de estimación y error 
    fprintf('%2d dBm: beta2 = %.3e ± %.3e km^-1   MSE = %.3e W^2\n',...
        potencias_dBm(p),...
        beta_ind(p),...
        sigma_ind(p),...
        MSE_ind(p));

end

%=========================================================
% Comparación entre medidas experimentales y modelo
%=========================================================

figResumen = figure('Color','w','Position',[250 150 1200 700]);
hold on
grid on
box on

for p = 1:length(potencias)

    % Potencia de transmisión (W)
    P_W = 1e-3*10^(potencias_dBm(p)/10);

    % Puntos experimentales
    idx = abs(PotenciaTX_all-P_W)<1e-15;

    Lexp = Longitudes_all(idx);
    Yexp = Praman_all(idx);

    scatter(Lexp,...
        10*log10(Yexp*1000),...
        80,...
        coloresPotencia(p,:),...
        marcadores{p},...
        'filled');

    % Curva teórica utilizando el beta ajustado para todas las potencias
    xx = linspace(0,12.15,500);

    Axx = P_W/delta.*(exp(-alpha1*xx)-exp(-alpha2*xx));

    % Ymodelo = beta_ind(p)*Axx;
    Ymodelo = beta2*Axx;

    plot(xx,...
        10*log10(Ymodelo*1000),...
        '--',...
        'Color',coloresPotencia(p,:),...
        'LineWidth',2);

end

xlabel('Longitud de fibra (km)','FontSize',14)
ylabel('Potencia Raman (dBm)','FontSize',14)
title('Modelo Scattering Raman Anti-Stokes frente a medidas experimentales','FontSize',16)

legend({'Datos 0 dBm','Modelo 0 dBm',...
        'Datos 4 dBm','Modelo 4 dBm',...
        'Datos 8 dBm','Modelo 8 dBm',...
        'Datos 12 dBm','Modelo 12 dBm'},...
        'Location','best')

set(gca,'FontSize',13)

%% PLOT MINIMALISTA DE LA EVOLUCIÓN DE LA POTENCIA RAMAN

% =========================================================
% Gráfica del modelo físico + máximo
% =========================================================

figure('Color','w');

% Distancia de 0 a 20 km
xx = linspace(0,20,1000);

% Modelo físico evaluado en toda la distancia
Ymodelo_plot = beta2 .* Pplot./delta .* ...
    (exp(-alpha1.*xx) - exp(-alpha2.*xx));

% Conversión a dBm
Ymodelo_dB = 10*log10(Ymodelo_plot*1000);

% Colores
colorCurva = [0.85 0.05 0.05];    % Rojo
colorMax   = [0.10 0.35 0.90];    % Azul intenso para destacar el máximo

% ---------------------------------------------------------
% Curva del modelo
% ---------------------------------------------------------

plot(xx, Ymodelo_dB, ...
    '-', ...
    'Color', colorCurva, ...
    'LineWidth', 3);

hold on;

% ---------------------------------------------------------
% Localización del máximo
% ---------------------------------------------------------

[Ymax, idxMax] = max(Ymodelo_dB);
xMax = xx(idxMax);

% ---------------------------------------------------------
% Línea vertical discontinua
% Solo desde el eje X hasta el máximo
% ---------------------------------------------------------

yl = ylim;

plot([xMax xMax], [yl(1) Ymax], ...
    '--', ...
    'Color', colorMax, ...
    'LineWidth', 1.3);

% ---------------------------------------------------------
% Señalización vistosa del punto máximo
% ---------------------------------------------------------

plot(xMax, Ymax, ...
    'o', ...
    'MarkerSize', 13, ...
    'MarkerFaceColor', colorMax, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', 2.5);

% ---------------------------------------------------------
% Etiqueta del máximo
% ---------------------------------------------------------

text(xMax, Ymax, ...
    sprintf('  Maximum: %.2f km',xMax), ...
    'Color', colorMax, ...
    'FontName', 'Arial', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'VerticalAlignment', 'bottom', ...
    'HorizontalAlignment', 'left');

% ---------------------------------------------------------
% Configuración de la gráfica
% ---------------------------------------------------------

xlim([0 20]);

xlabel('Distance (km)');
ylabel('a.u. (arbitrary units)');
title('Raman Noise Power Along the Fiber');

% No mostrar valores numéricos del eje Y
yticks([]);

% Fondo blanco y estética minimalista
set(gca, ...
    'Color', 'w', ...
    'FontName', 'Arial', ...
    'FontSize', 13, ...
    'LineWidth', 1.2, ...
    'TickDir', 'out');

grid off;
box off;

hold off;




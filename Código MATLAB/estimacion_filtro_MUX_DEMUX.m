%% ================================================================
%  ESTIMACION DE LA RESPUESTA ESPECTRAL DE MUX Y DEMUX
%  Datos de la primera pagina del PDF
%
%  Modelo principal:
%       Filtro gaussiano en potencia + suelo de aislamiento
%
%  Si el error del modelo gaussiano supera el umbral definido,
%  se prueba automaticamente un modelo lorentziano.
% ================================================================

clear;
clc;
close all;

% ---------------------------------------------------------------
% 1. DATOS DE PARTIDA
% ---------------------------------------------------------------

% Longitudes de onda de los canales caracterizados [nm]
lambda = [1310 1330 1510 1550];

% Longitudes de onda de los dos laser de entrada [nm]
lambda0 = [1310 1550];

% Potencia de transmision
PTX_dBm = 0;

% ---------------------------------------------------------------
% Datos medidos de recepcion [dBm]
%
% Cada columna corresponde a:
%   columna 1 -> laser TX = 1310 nm
%   columna 2 -> laser TX = 1550 nm
%
% Cada fila corresponde a:
%   1310, 1330, 1510, 1550 nm
% ---------------------------------------------------------------

RX_MUX = [ ...
    -1.03   -63.53;
   -34.06   -60.88;
   -63.50   -38.62;
   -62.43    -2.06 ];

RX_DEMUX = [ ...
    -1.65   -64.66;
   -37.08   -61.90;
   -61.95   -38.06;
   -59.40    -1.50 ];

% ---------------------------------------------------------------
% Conversión de recepcion a atenuacion
%
% A[dB] = PTX[dBm] - PRX[dBm]
%
% Como PTX = 0 dBm:
% A[dB] = -PRX[dBm]
% ---------------------------------------------------------------

ATT_MUX   = PTX_dBm - RX_MUX;
ATT_DEMUX = PTX_dBm - RX_DEMUX;


% ---------------------------------------------------------------
% 2. PARAMETROS DE LA ESTIMACION
% ---------------------------------------------------------------

% Umbral de RMSE a partir del cual se prueba otro modelo
% Este valor es configurable.
umbral_RMSE = 2.0;      % [dB]

% Mallado fino para dibujar las curvas
lambda_plot = linspace(1280,1580,1200);


% ---------------------------------------------------------------
% 3. AJUSTE DE MUX
% ---------------------------------------------------------------

resultado_MUX = struct();

for k = 1:2

    % Datos para este laser
    y = ATT_MUX(:,k).';
    
    % Centro de la banda
    l0 = lambda0(k);

    % -----------------------------------------------------------
    % AJUSTE GAUSSIANO
    % -----------------------------------------------------------
    
    [pG, rmseG, errG, yG] = ajustar_gaussiana( ...
        lambda, y, l0);

    modelo_seleccionado = 'Gaussiana';
    p_final = pG;
    rmse_final = rmseG;
    error_final = errG;

    % -----------------------------------------------------------
    % Si el error gaussiano es demasiado grande,
    % probar con una Lorentziana, por ejemplo
    % -----------------------------------------------------------

    if rmseG > umbral_RMSE

        [pL, rmseL, errL, yL] = ajustar_lorentziana( ...
            lambda, y, l0);

        % Nos quedamos con el modelo de menor error
        if rmseL < rmseG
            modelo_seleccionado = 'Lorentziana';
            p_final = pL;
            rmse_final = rmseL;
            error_final = errL;
            yG = yL;
        end
    end

    % -----------------------------------------------------------
    % Guardar resultados
    % -----------------------------------------------------------

    resultado_MUX(k).lambda0 = l0;
    resultado_MUX(k).modelo = modelo_seleccionado;
    resultado_MUX(k).parametros = p_final;
    resultado_MUX(k).RMSE = rmse_final;
    resultado_MUX(k).error_max = max(abs(error_final));

    % Curva para representar
    if strcmp(modelo_seleccionado,'Gaussiana')
        y_plot = modelo_gaussiano( ...
            lambda_plot, p_final, l0);
    else
        y_plot = modelo_lorentziano( ...
            lambda_plot, p_final, l0);
    end

    resultado_MUX(k).lambda_plot = lambda_plot;
    resultado_MUX(k).y_plot = y_plot;

end


% ---------------------------------------------------------------
% 4. AJUSTE DE DEMUX
% ---------------------------------------------------------------

resultado_DEMUX = struct();

for k = 1:2

    % Datos para este laser
    y = ATT_DEMUX(:,k).';

    % Centro de la banda
    l0 = lambda0(k);

    % -----------------------------------------------------------
    % AJUSTE GAUSSIANO
    % -----------------------------------------------------------

    [pG, rmseG, errG, yG] = ajustar_gaussiana( ...
        lambda, y, l0);

    modelo_seleccionado = 'Gaussiana';
    p_final = pG;
    rmse_final = rmseG;
    error_final = errG;

    % -----------------------------------------------------------
    % Si el error es demasiado grande,
    % probar con una Lorentziana, por ejemplo
    % -----------------------------------------------------------

    if rmseG > umbral_RMSE

        [pL, rmseL, errL, yL] = ajustar_lorentziana( ...
            lambda, y, l0);

        if rmseL < rmseG
            modelo_seleccionado = 'Lorentziana';
            p_final = pL;
            rmse_final = rmseL;
            error_final = errL;
            yG = yL;
        end
    end

    % -----------------------------------------------------------
    % Guardar resultados
    % -----------------------------------------------------------

    resultado_DEMUX(k).lambda0 = l0;
    resultado_DEMUX(k).modelo = modelo_seleccionado;
    resultado_DEMUX(k).parametros = p_final;
    resultado_DEMUX(k).RMSE = rmse_final;
    resultado_DEMUX(k).error_max = max(abs(error_final));

    % Curva para representar
    if strcmp(modelo_seleccionado,'Gaussiana')
        y_plot = modelo_gaussiano( ...
            lambda_plot, p_final, l0);
    else
        y_plot = modelo_lorentziano( ...
            lambda_plot, p_final, l0);
    end

    resultado_DEMUX(k).lambda_plot = lambda_plot;
    resultado_DEMUX(k).y_plot = y_plot;

end


% ---------------------------------------------------------------
% 5. REPRESENTACION MUX
% ---------------------------------------------------------------

figure('Name','Respuesta estimada MUX','Color','w');
hold on;
grid on;
box on;

% Curva 1310 nm -> azul
plot(resultado_MUX(1).lambda_plot, ...
     resultado_MUX(1).y_plot, ...
     'b-', 'LineWidth',2);

% Curva 1550 nm -> rojo
plot(resultado_MUX(2).lambda_plot, ...
     resultado_MUX(2).y_plot, ...
     'r-', 'LineWidth',2);

% Puntos medidos -> negros
plot(lambda, ATT_MUX(:,1), ...
     'ko', ...
     'MarkerFaceColor','k', ...
     'MarkerSize',7, ...
     'LineWidth',1.2);

plot(lambda, ATT_MUX(:,2), ...
     'ks', ...
     'MarkerFaceColor','k', ...
     'MarkerSize',7, ...
     'LineWidth',1.2);

xlabel('Longitud de onda (nm)');
ylabel('Atenuacion (dB)');
title('MUX - Respuesta espectral estimada');

legend( ...
    'Ajuste TX 1310 nm', ...
    'Ajuste TX 1550 nm', ...
    'Datos TX 1310 nm', ...
    'Datos TX 1550 nm', ...
    'Location','best');

xlim([1280 1580]);


% ---------------------------------------------------------------
% 6. REPRESENTACION DEMUX
% ---------------------------------------------------------------

figure('Name','Respuesta estimada DEMUX','Color','w');
hold on;
grid on;
box on;

% Curva 1310 nm -> azul
plot(resultado_DEMUX(1).lambda_plot, ...
     resultado_DEMUX(1).y_plot, ...
     'b-', 'LineWidth',2);

% Curva 1550 nm -> rojo
plot(resultado_DEMUX(2).lambda_plot, ...
     resultado_DEMUX(2).y_plot, ...
     'r-', 'LineWidth',2);

% Puntos medidos -> negros
plot(lambda, ATT_DEMUX(:,1), ...
     'ko', ...
     'MarkerFaceColor','k', ...
     'MarkerSize',7, ...
     'LineWidth',1.2);

plot(lambda, ATT_DEMUX(:,2), ...
     'ks', ...
     'MarkerFaceColor','k', ...
     'MarkerSize',7, ...
     'LineWidth',1.2);

xlabel('Longitud de onda (nm)');
ylabel('Atenuacion (dB)');
title('DEMUX - Respuesta espectral estimada');

legend( ...
    'Ajuste TX 1310 nm', ...
    'Ajuste TX 1550 nm', ...
    'Datos TX 1310 nm', ...
    'Datos TX 1550 nm', ...
    'Location','best');

xlim([1280 1580]);


% ---------------------------------------------------------------
% 7. RESULTADOS POR TERMINAL
% ---------------------------------------------------------------

fprintf('\n');
fprintf('===============================================================\n');
fprintf('        ESTIMACION DE LA RESPUESTA ESPECTRAL\n');
fprintf('===============================================================\n');

fprintf('\nUmbral para cambiar de modelo: %.2f dB RMSE\n', umbral_RMSE);


% ------------------------- MUX --------------------------

fprintf('\n------------------------- MUX --------------------------\n');

for k = 1:2

    p = resultado_MUX(k).parametros;

    % p(1) = Amin
    % p(2) = DeltaA
    % p(3) = sigma/gamma

    Amin   = p(1);
    Afloor = p(1) + p(2);
    sigma  = p(3);

    FWHM = 2*sqrt(2*log(2))*sigma;

    fprintf('\nTX = %d nm\n', resultado_MUX(k).lambda0);
    fprintf('Modelo seleccionado : %s\n', ...
        resultado_MUX(k).modelo);
    fprintf('Atenuacion minima   : %.3f dB\n', Amin);
    fprintf('Atenuacion de suelo : %.3f dB\n', Afloor);
    fprintf('Sigma               : %.3f nm\n', sigma);
    fprintf('FWHM gaussiana      : %.3f nm\n', FWHM);
    fprintf('RMSE                : %.3f dB\n', ...
        resultado_MUX(k).RMSE);
    fprintf('Error maximo        : %.3f dB\n', ...
        resultado_MUX(k).error_max);

    % Tabla de puntos
    fprintf('\n   lambda(nm)    Medido(dB)    Estimado(dB)    Error(dB)\n');

    if strcmp(resultado_MUX(k).modelo,'Gaussiana')
        y_est = modelo_gaussiano(lambda,p,resultado_MUX(k).lambda0);
    else
        y_est = modelo_lorentziano(lambda,p,resultado_MUX(k).lambda0);
    end

    y_med = ATT_MUX(:,k).';

    for n = 1:length(lambda)
        fprintf('   %8.0f      %9.3f      %11.3f     %9.3f\n', ...
            lambda(n), y_med(n), y_est(n), y_est(n)-y_med(n));
    end

end


% ------------------------ DEMUX -------------------------

fprintf('\n------------------------- DEMUX -------------------------\n');

for k = 1:2

    p = resultado_DEMUX(k).parametros;

    Amin   = p(1);
    Afloor = p(1) + p(2);
    sigma  = p(3);

    FWHM = 2*sqrt(2*log(2))*sigma;

    fprintf('\nTX = %d nm\n', resultado_DEMUX(k).lambda0);
    fprintf('Modelo seleccionado : %s\n', ...
        resultado_DEMUX(k).modelo);
    fprintf('Atenuacion minima   : %.3f dB\n', Amin);
    fprintf('Atenuacion de suelo : %.3f dB\n', Afloor);
    fprintf('Sigma               : %.3f nm\n', sigma);
    fprintf('FWHM gaussiana      : %.3f nm\n', FWHM);
    fprintf('RMSE                : %.3f dB\n', ...
        resultado_DEMUX(k).RMSE);
    fprintf('Error maximo        : %.3f dB\n', ...
        resultado_DEMUX(k).error_max);

    fprintf('\n   lambda(nm)    Medido(dB)    Estimado(dB)    Error(dB)\n');

    if strcmp(resultado_DEMUX(k).modelo,'Gaussiana')
        y_est = modelo_gaussiano(lambda,p,resultado_DEMUX(k).lambda0);
    else
        y_est = modelo_lorentziano(lambda,p,resultado_DEMUX(k).lambda0);
    end

    y_med = ATT_DEMUX(:,k).';

    for n = 1:length(lambda)
        fprintf('   %8.0f      %9.3f      %11.3f     %9.3f\n', ...
            lambda(n), y_med(n), y_est(n), y_est(n)-y_med(n));
    end

end


fprintf('\n===============================================================\n');
fprintf('Fin de la estimacion.\n');
fprintf('===============================================================\n');


%% ===============================================================
% FUNCIONES AUXILIARES
% ================================================================

function [p_best, rmse_best, error_best, y_best] = ...
                 ajustar_gaussiana(x,y,lambda0)

    % -----------------------------------------------------------
    % Parametros internos:
    %
    % p(1) = Amin
    % p(2) = DeltaA = Afloor - Amin
    % p(3) = sigma
    %
    % Se optimizan sus logaritmos para garantizar que sean > 0.
    % -----------------------------------------------------------

    opts = optimset( ...
        'Display','off', ...
        'MaxIter',10000, ...
        'MaxFunEvals',100000, ...
        'TolX',1e-10, ...
        'TolFun',1e-10);

    mejor_SSE = inf;

    % Multistart para evitar depender de una unica inicializacion
    sigma0_list = [5 10 20 40 80];

    amin0 = max(min(y),1e-3);
    delta0 = max(max(y)-min(y),1e-3);

    for s0 = sigma0_list

        q0 = log([amin0 delta0 s0]);

        funcion_objetivo = @(q) ...
            sum((modelo_gaussiano_q(x,q,lambda0)-y).^2);

        q = fminsearch(funcion_objetivo,q0,opts);

        p = exp(q);

        y_est = modelo_gaussiano(x,p,lambda0);

        error = y_est-y;

        SSE = sum(error.^2);

        if SSE < mejor_SSE
            mejor_SSE = SSE;
            p_best = p;
            y_best = y_est;
            error_best = error;
        end

    end

    rmse_best = sqrt(mean(error_best.^2));

end


function y = modelo_gaussiano_q(x,q,lambda0)

    p = exp(q);
    y = modelo_gaussiano(x,p,lambda0);

end


function y = modelo_gaussiano(x,p,lambda0)

    Amin  = p(1);
    Delta = p(2);
    sigma = p(3);

    Afloor = Amin + Delta;

    % Potencias relativas en escala lineal
    Ppeak  = 10.^(-Amin/10);
    Pfloor = 10.^(-Afloor/10);

    % Respuesta gaussiana en potencia
    Pout = Pfloor + ...
        (Ppeak-Pfloor).* ...
        exp(-0.5*((x-lambda0)./sigma).^2);

    % Conversión a dB de atenuacion
    y = -10*log10(Pout);

end


function [p_best, rmse_best, error_best, y_best] = ...
                 ajustar_lorentziana(x,y,lambda0)

    opts = optimset( ...
        'Display','off', ...
        'MaxIter',10000, ...
        'MaxFunEvals',100000, ...
        'TolX',1e-10, ...
        'TolFun',1e-10);

    mejor_SSE = inf;

    gamma0_list = [5 10 20 40 80];

    amin0 = max(min(y),1e-3);
    delta0 = max(max(y)-min(y),1e-3);

    for g0 = gamma0_list

        q0 = log([amin0 delta0 g0]);

        funcion_objetivo = @(q) ...
            sum((modelo_lorentziano_q(x,q,lambda0)-y).^2);

        q = fminsearch(funcion_objetivo,q0,opts);

        p = exp(q);

        y_est = modelo_lorentziano(x,p,lambda0);

        error = y_est-y;

        SSE = sum(error.^2);

        if SSE < mejor_SSE
            mejor_SSE = SSE;
            p_best = p;
            y_best = y_est;
            error_best = error;
        end

    end

    rmse_best = sqrt(mean(error_best.^2));

end


function y = modelo_lorentziano_q(x,q,lambda0)

    p = exp(q);
    y = modelo_lorentziano(x,p,lambda0);

end


function y = modelo_lorentziano(x,p,lambda0)

    Amin  = p(1);
    Delta = p(2);
    gamma = p(3);

    Afloor = Amin + Delta;

    % Potencias relativas en escala lineal
    Ppeak  = 10.^(-Amin/10);
    Pfloor = 10.^(-Afloor/10);

    % Respuesta lorentziana en potencia
    Pout = Pfloor + ...
        (Ppeak-Pfloor)./ ...
        (1+((x-lambda0)./gamma).^2);

    % Conversion a dB de atenuacion
    y = -10*log10(Pout);

end
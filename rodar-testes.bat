@echo off
rem Mede os 3 servicos em sequencia (cerca de 4 min e meio cada)
rem e depois gera os graficos e preenche o README.md com o graficos.py.
rem Antes: o sistema ligado (docker compose up -d --build) e a massa de dados carregada.
rem Uso: dois cliques = medicao 1.  Para a medicao 2, no cmd: rodar-testes.bat 2
cd /d "%~dp0"
set MEDICAO=%1
if "%MEDICAO%"=="" set MEDICAO=1
set PASTA=resultados\medicao-%MEDICAO%
if not exist %PASTA%\bruto mkdir %PASTA%\bruto
call :servico login
call :servico eventos
call :servico presenca
echo.
echo ===== Graficos e README =====
python graficos.py %MEDICAO%
echo.
echo Pronto. Abra o README.md desta pasta para ver as medicoes.
pause
exit /b

:servico
echo.
echo ===== Medicao %MEDICAO%, servico: %1 =====
k6 run --out csv=%PASTA%\bruto\%1.csv --summary-export %PASTA%\%1.json %1.js
exit /b

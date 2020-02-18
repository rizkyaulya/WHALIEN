@echo off
cd /d %~dp0
set /p benchreset= This process will remove all(!) benchmarking data. Are you sure you want to continue? [Y/N] 
IF /I "%benchreset%"=="Y" (
	if exist "Stats\Miners\*_HashRate.txt" del "Stats\Miners\*_HashRate.txt"
	if exist "Stats\*_HashRate.txt" del "Stats\*_HashRate.txt"
	ECHO Success. RainbowMiner will rebenchmark all needed algorithm.
	PAUSE
)

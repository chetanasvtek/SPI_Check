@ECHO OFF
cls
 
ECHO "Creating working library"
vlib work
IF errorlevel 2 (
    ECHO failed to create library
    GOTO done:
)
for /f %%i in ('powershell -Command "Get-Random -Maximum 4294967295"') do set RSEED=%%i
 
ECHO "============compilation=========="
:: FIX: Added +define+SIM to enable NAND gate delays
vlog -f files.f +acc
 
IF ERRORLEVEL 1 (
    ECHO there was an error, fix it and try again
    GOTO done:
)
 
IF ERRORLEVEL 2 (
    ECHO there was an error, fix it and try again
    GOTO done:
)
 
ECHO "===============simulation================"
vsim -do "add wave -r *; run -all; quit" tb_register_block
IF errorlevel 2 (
    ECHO there was an error, fix it and try again  
    GOTO done:
)  
 
:done
ECHO Done
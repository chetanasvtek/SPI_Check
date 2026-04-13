@ECHO OFF

ECHO "Creating working library"
vlib work
IF errorlevel 2 (
	ECHO failed to create library
	GOTO done:
)

ECHO "invoking ==============> vlog CALIBRATION_SUBADCNOM_TOP_12b8b_MODE_DIG_CAL.sv CALIBRATION_SUBADCNOM_TOP_12b8b_MODE_DIG_CAL_TB.sv" 
vlog -f files.f +acc
IF errorlevel 2 (
	ECHO there was an error, fix it and try again
	GOTO done:
)

ECHO "invoking ==============> vsim CALIBRATION_SUBADCNOM_TOP_12b8b_MODE_DIG_CAL_TB"
vsim -c -do "add wave -r /*; run -all; quit" SPI_ctrl1_slave_tb
IF errorlevel 2 (
	ECHO there was an error, fix it and try again
	GOTO done:
)

:done
ECHO Done
@echo off
setlocal EnableDelayedExpansion

:: use first argument as output file
set output="%1"
set filename=%~n1
set fancyname="%filename%                    "
echo == %filename%.ls ==
echo /*=====================*\>  %output%
echo ^|* !fancyname:~1,19! *^|>> %output%
echo \*=====================*/>> %output%
echo.>> %output%

set compiled="%2"
shift
shift

:: append file to the output
setlocal EnableDelayedExpansion
:append
	set filename="%~nx1"&& set filename=!filename:~1,-1!
	:: escape filenames
	echo - !filename!
	echo /*@source !filename! */>> %output%
	if "%~x1"==".js" (
		echo ``>>  %output%
		type %1 >> %output%
		echo.>>    %output%
		echo ``>>  %output%
	) else (
		type %1 >> %output%
	)
	echo.>> %output%
	echo.>> %output%

:: check for next argument
shift
if not "%~1"=="" goto append

:: compile merged LiveScript file
lsc.cmd -b -p -c %output% > %compiled%

:: end
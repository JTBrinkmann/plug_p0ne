@echo off

set output=plug_p0ne
echo == assembling plug_p0ne ==
echo /*=====================*\>    %output%.ls
echo ^|*      plug_p0ne      *^|>> %output%.ls
echo \*=====================*/>>   %output%.ls
echo.>> %output%.ls

set file=p0ne.auxiliaries.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=jtb.module2.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.perf.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.sjs.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.base.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

:: set file=p0ne.chat.ls
:: echo /*@source %file% */>> %output%.ls
:: type %file%             >> %output%.ls
:: echo.>> %output%.ls
:: echo.>> %output%.ls

set file=p0ne.bpm.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.notif.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.ponify.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

:: set file=p0ne.autocomplete.ls
:: echo /*@source %file% */>> %output%.ls
:: type %file%             >> %output%.ls
:: echo.>> %output%.ls
:: echo.>> %output%.ls


echo.
echo == compiling plug_p0ne ==
del /Q %output%.js
CMD /C lsc -b -c %output%.ls
:: attach lambda.js
type jtb.lambda.js >> %output%.js
CMD /C uglifyjs -o %output%.js --source-map %output%.js.map %output%
del /Q %output%



:: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



echo.
set output=plug_p0ne.avatars
echo == compiling plug_p0ne.avatars.js ==
del /Q plug_p0ne.avatars.js
CMD /C lsc -b -c p0ne.avatars.ls
rename p0ne.avatars plug_p0ne.avatars
CMD /C uglifyjs -o %output%.js --source-map %output%.js.map %output%
del /Q %output%



:: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

echo.
echo == done ==
pause

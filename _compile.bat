@echo off
:start

set output= plug_p0ne.beta
echo == %output%.ls ==
echo /*=====================*\>    %output%.ls
echo ^|*      plug_p0ne      *^|>> %output%.ls
echo \*=====================*/>>   %output%.ls
echo.>> %output%.ls

set file=p0ne.head.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

:: BEGIN JavaScript imports
:: note - if there's an "SyntaxError: unterminated JS literal" check if JS files contain a backtilde
echo ``>> %output%.ls

set file=lambda.js
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=lz-string.js
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

echo ``>> %output%.ls
:: END JavaScript imports


set file=p0ne.auxiliaries.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.module.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.auxiliary-modules.ls
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

set file=p0ne.fixes.ls
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

set file=p0ne.chat.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.look-and-feel.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.room-theme.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.bpm.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.song-notif.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.song-info.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.avatars.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.settings.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.dev.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

set file=p0ne.userHistory.ls
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

set file=p0ne.fimplug.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls


echo ^>^>
del /Q %output%.js
CMD /C lsc -b -c %output%.ls
rename %output% %output%.js
:: CMD /C uglifyjs -o %output%.min.js --source-map %output%.js.map %output%.js
echo ^>^> %output%.ls



:: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


echo.
echo.
set output=plug_p0ne.migrate.1
echo == %output%.ls ==
echo /*=====================*\>    %output%.ls
echo ^|*  plug_p0ne.migrate.1  *^|>> %output%.ls
echo \*=====================*/>>   %output%.ls
echo.>> %output%.ls

set file=lz-string.js
echo - %file%
echo ``>> %output%.ls
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo ``>> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls


set file=p0ne.migrate.1.ls
echo - %file%
echo /*@source %file% */>> %output%.ls
type %file%             >> %output%.ls
echo.>> %output%.ls
echo.>> %output%.ls

echo ^>^>
del /Q %output%.js
CMD /C lsc -b -c %output%.ls
rename %output% %output%.js
:: CMD /C uglifyjs -o %output%.min.js --source-map %output%.js.map %output%.js
echo ^>^> %output%.ls



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo.
echo == done ==
date /T
time /T
pause

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo ================================================================
echo ================================================================
goto start
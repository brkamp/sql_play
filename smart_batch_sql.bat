@ECHO OFF

SET MinusDay=1

CALL :DynamicVBSScriptBuild

FOR /F "TOKENS=*" %%A IN ('cscript//nologo "%YYYYTmpVBS%"') DO SET YYYY=%%A
FOR /F "TOKENS=*" %%A IN ('cscript//nologo "%MMTmpVBS%"') DO SET MM=%%A
FOR /F "TOKENS=*" %%A IN ('cscript//nologo "%DDTmpVBS%"') DO SET DD=%%A

::// Set  YYYY MM DD variables.
SET YYYY=%YYYY%
SET MM=%MM%
SET DD=%DD%

SET fname=%YYYY%%MM%%DD%_HourCount.csv

if not exist "c:\Ricky\%fname%" goto :CONTINUE
del "c:\Ricky\%fname%"

:CONTINUE
echo Generating Report...
timeout 1 >NUL

sqlcmd -U <sqluser> -P <sqlpassword> -i "C:\path_to_script.sql" -o "c:\path_to_output\%fname%" -s"," -W

echo Task Completed.
timeout 5 >NUL
::PAUSE
exit

:DynamicVBSScriptBuild
SET YYYYTmpVBS=%temp%\~tmp_yyyy.vbs
SET MMTmpVBS=%temp%\~tmp_mm.vbs
SET DDTmpVBS=%temp%\~tmp_dd.vbs
IF EXIST "%YYYYTmpVBS%" DEL /Q /F "%YYYYTmpVBS%"
IF EXIST "%MMTmpVBS%" DEL /Q /F "%MMTmpVBS%"
IF EXIST "%DDTmpVBS%" DEL /Q /F "%DDTmpVBS%"
ECHO dt = DateAdd("d",-%MinusDay%,date) >> "%YYYYTmpVBS%"
ECHO yyyy = Year(dt)                    >> "%YYYYTmpVBS%"
ECHO WScript.Echo yyyy                  >> "%YYYYTmpVBS%"
ECHO dt = DateAdd("d",-%MinusDay%,date) >> "%MMTmpVBS%"
ECHO mm = Right("0" ^& Month(dt),2)     >> "%MMTmpVBS%"
ECHO WScript.Echo mm                    >> "%MMTmpVBS%"
ECHO dt = DateAdd("d",-%MinusDay%,date) >> "%DDTmpVBS%"
ECHO dd = Right("0" ^& Day(dt),2)       >> "%DDTmpVBS%"
ECHO WScript.Echo dd                    >> "%DDTmpVBS%"

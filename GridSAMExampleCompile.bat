@echo OFF

setlocal enabledelayedexpansion

set OMII_CLIENT_HOME=.
set MY_CLASSPATH=.;%OMII_CLIENT_HOME%\lib;%OMII_CLIENT_HOME%\conf;
for %%j in (%OMII_CLIENT_HOME%\lib\*.jar) do set MY_CLASSPATH=!MY_CLASSPATH!;%%j

echo Compiling the GridSAM client example...
javac -classpath %MY_CLASSPATH% GridSAMExample.java

endlocal enabledelayedexpansion


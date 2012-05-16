@echo OFF

setlocal enabledelayedexpansion

set OMII_CLIENT_HOME=.
set ENDORSED=-Djava.endorsed.dirs="%OMII_CLIENT_HOME%\endorsed"
set MY_CLASSPATH=.;%OMII_CLIENT_HOME%\lib;%OMII_CLIENT_HOME%\conf;
for %%j in (%OMII_CLIENT_HOME%\lib\*.jar) do set MY_CLASSPATH=!MY_CLASSPATH!;%%j

echo Run the GridSAM client example...

java %ENDORSED% -cp %MY_CLASSPATH% -Dftp.server="client.domain:port" -Dgridsam.server="https://server.domain:port/gridsam/services/gridsam?wsdl" GridSAMExample

endlocal enabledelayedexpansion

::Florida Memory Photo Search
:: See instructions pdf for information about usage
::This bat will search an invoice or list of file ids and generate a list of items that are not yet located on the cloud

:: Loop for Florida Maps directory
@echo off
setlocal enabledelayedexpansion

:: Set the server location
set "SERVER_LOCATION=\\NVDOS9FLMEM01\flmem01" 2>nul

:: Set the Photo Masters directory location
set "PHOTO_MASTERS_DIR=%SERVER_LOCATION%\Photo Masters"

:: Set the Photo Orders directory location
set "PHOTO_ORDERS_DIR=%SERVER_LOCATION%\Photo Orders"

:: Set the Florida Maps directory location
set "FLORIDA_MAPS_LOCATION=\\dosshares1\FlMemory03\Collections\State Library Collection - Florida Map Collection"

:: Set the input file path
set "input_file=%PHOTO_ORDERS_DIR%\files\invoice-data.txt"

::Intro text
echo.
echo *********************************************
echo ******** Florida Memory Photo Search ********
echo *********************************************

echo.
echo Current User: %USERNAME%
echo.
echo Current mode: Create a list of invoice items that are not yet on the cloud

echo.

:: Extract the invoice number from the input file
for /f "tokens=2" %%a in ('type "%input_file%" ^| find /i "Invoice #"') do (
    set "invoice_number=%%a"
)

if "%invoice_number%"=="" (
    for /f "tokens=2" %%a in ('type "%input_file%" ^| find /i "Order (#"') do (
    set "invoice_number=%%a"
    set "invoice_number=!invoice_number:(=!"
    set "invoice_number=!invoice_number:)=!"
)
)

if "%invoice_number%"=="" (
    for /f "tokens=2" %%a in ('type "%input_file%" ^| find /i "Order #"') do (
    set "invoice_number=%%a"
)
)

:: Check if the invoice # was found. If not set userName
if "%invoice_number%"=="" (
    set "invoice_number= %USERNAME%"
) else (
    echo Current invoice !invoice_number!
    echo.
)


:: Extract image IDs from the input file and store them in a variable
echo Locating item ids...
set "img_ids="
for /f "tokens=1,* delims=: " %%a in ('type "%input_file%" ^| find /i "Image Number:"') do (
    set "img_id=%%b"
    set "img_id=!img_id:Image Number: =!"
    set "img_ids=!img_ids! !img_id!"
    echo !img_id!
)

:: Extract map IDs from the input file and store them in a variable
set "map_ids="
for /f "tokens=4 delims=: " %%a in ('type "%input_file%" ^| find /i "Map Number:"') do (
    set "map_id=%%a"
    set "map_ids=!map_ids!!map_id! "
)

set "filtered_map_ids="
for %%b in (%map_ids%) do (
    set "map_id=%%b"
    setlocal enabledelayedexpansion
    if "!map_id!" neq "Scanned" (
        endlocal & set "filtered_map_ids=!filtered_map_ids!!map_id! "
    ) else (
        endlocal
    )
)

set "map_ids=%filtered_map_ids%"

if defined img_ids if defined map_ids (
    set "located_file_ids=%img_ids% %map_ids%"
)

if defined img_ids if not defined map_ids (
    set "located_file_ids=%img_ids%"
)

if defined map_ids if not defined img_ids (
    set "located_file_ids=%map_ids%"
)

if not defined map_ids if not defined img_ids (
    for /f "tokens=1,* delims=." %%a in ('type "%input_file%" ^| findstr /v /i "Invoice #"') do (
        set "located_file_id=%%a"
        set "located_file_ids=!located_file_ids! !located_file_id!"
        echo !located_file_id!
    )
)

IF /I NOT "%map_ids%"=="" (
    echo %map_ids%
)

echo.

:: Clear the content of the invoice-data.txt file
type nul > "%input_file%"

set num_files_found=0

for %%b in (%located_file_ids%) do (
set /A num_files_found+=1
)

:: check to see if any invoice #s found
if "%located_file_ids%"=="" (
    echo No file items found.
    echo Check to make sure Invoice Data has a valid invoice order form or a list of file items.
    echo Note: The Invoice Data file is automatically erased after every search.
    echo Check the Instructions PDF for more detailed information on adding search data.
    echo.
    echo Press any key to exit
    pause >nul
    exit /b
)

:: Check if the "Photo Masters" directory exists
if not exist "%PHOTO_MASTERS_DIR%" (
    echo Unable to locate the Photo Masters folder. Double check to make sure the folder exists and that the drive is not having issues with connectivity.
    echo.
    echo Press any key to exit
    pause >nul
    exit /b
)

:: Check if the "Photo Orders" directory exists
if not exist "%PHOTO_ORDERS_DIR%" (
    echo Unable to locate the Photo Orders folder. Double check to make sure the folder exists and that the drive is not having issues with connectivity.
    echo.
    echo Press any key to exit
    pause >nul
    exit /b
)

:: Check if the "Photo Orders" directory exists
if not exist "%FLORIDA_MAPS_LOCATION%" (
    echo Unable to locate the Florida Maps folder. Double check to make sure the folder exists and that the drive is not having issues with connectivity.
    echo.
    echo Press any key to exit
    pause >nul
    exit /b
)

:: Set the resulting directory name using the invoice number and timestamp
set TIMESTAMP=%DATE:/=-%_%TIME::=-%
set TIMESTAMP=%TIMESTAMP: =%
set RESULTING_DIR_NAME=%invoice_number%__%TIMESTAMP%

:: Set the path for the failed transfers file
set "TRANSFER_RESULTS_DIR=%PHOTO_ORDERS_DIR%\transfer_results"
set "RESULTING_DIR=%TRANSFER_RESULTS_DIR%\%RESULTING_DIR_NAME%"
set "NOT_ON_CLOUD_FILE=%RESULTING_DIR%\not-on-cloud.txt"

echo Created new folder: transfer-results\!RESULTING_DIR_NAME!
echo.
:: Generating directory for copied files
mkdir "%RESULTING_DIR%"
echo. > "%NOT_ON_CLOUD_FILE%"

echo Searching for files...

:: Store the remaining located_file_ids
set "remaining_ids=%located_file_ids%"


for %%i in (%located_file_ids%) do (
    for /r "%FLORIDA_MAPS_LOCATION%" %%f in (*%%i*) do (
        set "fileName=%%~nxf"
        echo !fileName! | findstr /r /i /c:"^%%i[^0-9]" > nul
        if !errorlevel! equ 0 (
            if not "%%~xf"==".md5" (
                set "remaining_ids=!remaining_ids:%%i=!"
                set "filePath=%%f"
                setlocal enabledelayedexpansion
                echo Florida Map Collection\!filePath:*Florida Map Collection\=!
                endlocal
            )
        ) else (
            echo !fileName! | findstr /r /i /c:"^.*[^a-zA-Z]%%i[^0-9]" > nul
            if !errorlevel! equ 0 (
                if not "%%~xf"==".md5" (
                    set "remaining_ids=!remaining_ids:%%i=!"
                    set "filePath=%%f"
                    setlocal enabledelayedexpansion
                    echo Florida Map Collection\!filePath:*Florida Map Collection\=!
                    endlocal
                )
            )
        )
    )
)


set "located_file_ids=%remaining_ids%"

for %%i in (%located_file_ids%) do (
    for /r "%PHOTO_MASTERS_DIR%" %%f in (*%%i*) do (
        set "fileName=%%~nxf"
        echo !fileName! | findstr /r /i /c:"^%%i[^0-9]" > nul
        if !errorlevel! equ 0 (
            if not "%%~xf"==".md5" (
                set "remaining_ids=!remaining_ids:%%i=!"
                set "filePath=%%f"
                setlocal enabledelayedexpansion
                echo Photo Masters\!filePath:*Photo Masters\=!
                endlocal
            )
        ) else (
            echo !fileName! | findstr /r /i /c:"^.*[^a-zA-Z]%%i[^0-9]" > nul
            if !errorlevel! equ 0 (
                if not "%%~xf"==".md5" (
                    set "remaining_ids=!remaining_ids:%%i=!"
                    set "filePath=%%f"
                    setlocal enabledelayedexpansion
                    echo Photo Masters\!filePath:*Photo Masters\=!
                    endlocal
                )
            )
        )
    )
)

:: crate var for number not on cloud
set num_not_on_cloud = 0

:: Add the remaining located_file_ids to the NOT_ON_CLOUD_FILE all at once
for %%i in (%remaining_ids%) do (
    echo %%i >> "%NOT_ON_CLOUD_FILE%"
    set /a num_not_on_cloud+=1
)

if "%remaining_ids%" neq "" (
    set "remaining_ids=%remaining_ids: =%"
    setlocal enabledelayedexpansion
    set "trimmed_ids="
    for %%a in (%remaining_ids%) do (
        set "trimmed_ids=!trimmed_ids! %%a"
    )
    if defined trimmed_ids (
        echo.
        echo Files not located on the cloud: !trimmed_ids:~1!
        echo.
    ) else (
        echo All files successfully located.
        rmdir /s /q "%RESULTING_DIR%"
    )
    endlocal
)


set "username=%USERNAME%"
set "csv_file=%PHOTO_ORDERS_DIR%\files\Order-data.csv"

@REM for /f "delims=" %%a in ('cscript //nologo //e:vbscript "%PHOTO_ORDERS_DIR%\files\VBscript.vbs" %num_files_found% %num_files_in_copied_dir%') do set time_saved=%%a

set /a "overall_minutes=(num_files_found * 2)"

set /a "hours=overall_minutes / 60"
set /a "minutes=overall_minutes %% 60"

set "time_saved=%hours%.%minutes%"

if "%minutes%" lss "10" (
    set "minutes=0%minutes%"
)



for /f "usebackq skip=1 tokens=1 delims=," %%a in (`powershell -Command "$csv = Import-Csv -Path '%csv_file%'; $nextRow = $csv.Count + 1; $nextRow"`) do set "next_row=%%a"

set year=%date:~10,4%
set month=%date:~4,2%
set day=%date:~7,2%
set current_date=%month%/%day%/%year%


:: Add the values to the CSV file
echo %current_date%, %username%, %invoice_number%,%num_files_found%,%num_files_in_copied_dir%,%num_not_on_cloud%, %overall_minutes% >> "%csv_file%"

popd

echo.

echo Clearing invoice-data.txt...
echo.
echo Search completed
echo.
echo Press any key to exit
pause >nul

endlocal
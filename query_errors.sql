USE DBA ;
/*
USE DBA
IF OBJECT_ID('dbo.TraceError', 'U') IS NOT NULL DROP TABLE dbo.TraceError;
SELECT * INTO TraceError FROM sys.fn_trace_gettable('D:\Traces\TraceDuration_209.trc', default)

SELECT * FROM sys.traces

*/
DECLARE  @load_data bit = 1

IF @load_data = 1
BEGIN;
	IF OBJECT_ID('dbo.TraceError', 'U') IS NOT NULL DROP TABLE dbo.TraceError;

	DECLARE @file varchar(2000) = (SELECT path FROM sys.traces WHERE path LIKE '%TraceError%');
	SELECT @file = CASE WHEN PATINDEX('%[_]%', @file) = 1 THEN -- When the file contains an underscore (_)
	REPLACE(@file
			,SUBSTRING(@file, PATINDEX('%[_]%', @file)+1, PATINDEX('%[.]%', @file) - PATINDEX('%[_]%', @file)-1) /*get the number part*/
			,CAST(CAST(SUBSTRING(@file, PATINDEX('%[_]%', @file)+1, PATINDEX('%[.]%', @file) - PATINDEX('%[_]%', @file)-1) AS int) -  1 AS sysname))/*substrac 1 from the number part*/
			ELSE @file -- When the file does not contains an underscore - the first file in the seriouse
			END;
	PRINT '-- Loading ' + CAST(1 AS sysname) + ' files(s) starting at file: ''' + @file + '''.';


	DECLARE @command varchar(MAX) = 
	'SELECT * INTO dbo.TraceError FROM ::fn_trace_gettable(''' + @file + ''', DEFAULT) WHERE TextData IS NOT NULL;';
	PRINT @command;
	EXEC (@command);
	--SELECT COUNT(*)Cnt, MIN(StartTime)StartTime, MAX(StartTime)EndTime, DATEDIFF(MINUTE, MIN(StartTime), MAX(StartTime) ) diff_mm  FROM dbo.TraceError
END;


SELECT 
 	 EventClass  
	,StartTime	
	,TextData	  
	,ApplicationName
	,DatabaseName
	,HostName
	--,LEFT( master.dbo.uf_trimextraspaces(TextData) , 50)    TextData
	,Reads                
	,Writes               
	,CPU      
	,Duration / 1000  AS Duration_ms     
	,Error
	,RowCounts
	,SPID  
	--,Object_Name(ObjectId) AS ObjectName
FROM dbo.TraceError t WHERE 1=1
--AND t.HostName LIKE '%'
--AND t.DatabaseName NOT LIKE ''
AND t.ApplicationName NOT LIKE 'SQLAgent%'
AND t.ApplicationName NOT LIKE 'Microsoft ® Windows Script Host%'
AND ApplicationName NOT LIKE 'Microsoft SQL Server Management%'
--AND EventClass NOT IN (10, 12)
--AND t.TextData LIKE '%%'
AND StartTime > '2020-08-31 13:00' 
--AND t.Error = 2
ORDER BY StartTime DESC
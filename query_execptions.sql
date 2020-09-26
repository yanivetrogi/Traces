USE DBA 

--SELECT COUNT(*)Cnt, MIN(StartTime)StartTime, MAX(StartTime)EndTime, DATEDIFF(MINUTE, MIN(StartTime), MAX(StartTime) ) diff_mm  FROM dbo.Exceptions

DECLARE  @load_data bit = 1


IF @load_data = 1
BEGIN;
	IF OBJECT_ID('dbo.Exceptions', 'U') IS NOT NULL DROP TABLE dbo.Exceptions;

	DECLARE @file varchar(2000) = (SELECT path FROM sys.traces WHERE path LIKE '%Exceptions%');
	SELECT @file = CASE WHEN PATINDEX('%[_]%', @file) = 1 THEN -- When the file contains an underscore (_)
	REPLACE(@file
			,SUBSTRING(@file, PATINDEX('%[_]%', @file)+1, PATINDEX('%[.]%', @file) - PATINDEX('%[_]%', @file)-1) /*get the number part*/
			,CAST(CAST(SUBSTRING(@file, PATINDEX('%[_]%', @file)+1, PATINDEX('%[.]%', @file) - PATINDEX('%[_]%', @file)-1) AS int) -  1 AS sysname))/*substrac 1 from the number part*/
			ELSE @file -- When the file does not contains an underscore - the first file in the seriouse
			END;
	PRINT '-- Loading ' + CAST(1 AS sysname) + ' files(s) starting at file: ''' + @file + '''.';

	DECLARE @command varchar(MAX) = 'SELECT * INTO Exceptions FROM ::fn_trace_gettable(''' + @file + ''', DEFAULT) WHERE TextData IS NOT NULL;';
	PRINT @command;
	EXEC (@command);
END;


SELECT 
 	 EventClass  
	,StartTime	
	,TextData	  
	,ApplicationName
	--,CASE WHEN ApplicationName NOT LIKE 'SQLAgent%' THEN ApplicationName ELSE (SELECT  N'JobName: ' + CHAR(39) + j.name + CHAR(39) + N';  StepID:' + CAST(js.step_id as VARCHAR(12)) + N';  StepName: ' + CHAR(39) + js.step_name + CHAR(39) FROM msdb..sysjobs j INNER JOIN msdb..sysjobsteps js ON j.job_id = js.job_id WHERE j.job_id = SUBSTRING(ApplicationName,38,2) + SUBSTRING(ApplicationName,36,2) + SUBSTRING(ApplicationName,34,2) + SUBSTRING(ApplicationName,32,2) + '-' + SUBSTRING(ApplicationName,42,2) + SUBSTRING(ApplicationName,40,2) + '-' + SUBSTRING(ApplicationName,46,2) + SUBSTRING(ApplicationName,44,2) + '-' + SUBSTRING(ApplicationName,48,4) + '-' + SUBSTRING(ApplicationName,52,12) AND js.step_id = CAST( SUBSTRING(ApplicationName, 72, LEN(ApplicationName) + 1 - CHARINDEX(')', ApplicationName) ) as INT )) END AS [program_name]
	,DatabaseName
	,HostName
	,Reads                
	,Writes               
	,CPU      
	,Duration / 1000  AS Duration_ms     
	,Error
	,RowCounts
	,SPID  
	,ObjectName
FROM dbo.Exceptions t WHERE 1=1
--AND t.HostName LIKE '%'
--AND t.DatabaseName NOT LIKE ''
--AND t.ApplicationName NOT LIKE '%'
--AND t.ApplicationName NOT LIKE 'Microsoft ® Windows Script Host%'
--AND ApplicationName NOT LIKE 'Microsoft SQL Server Management%'
--AND StartTime > '2020-08-31 13:00' 
ORDER BY StartTime DESC

--select DATEDIFF(MINUTE, MIN(StartTime), MAX(StartTime)) diff_mm, MIN(StartTime)StartTime, MAX(t.StartTime)EndtTime, COUNT(*)cnt FROM dbo.Exceptions t WHERE 1=1 AND t.Error = 2627




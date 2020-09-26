/*
	select BusinessEntityID from Person.Person where %%lockres%% = ‘(089241b7b846)’
*/

USE DBA; SET NOCOUNT ON; SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;
--SELECT * FROM sys.traces

DECLARE  @load_data bit, @num_files_to_load tinyint;
SELECT	 @num_files_to_load = 1
SELECT   @load_data = 1

IF @load_data = 1
BEGIN;
	IF OBJECT_ID('tempdb.dbo.#data', 'U') IS NOT NULL DROP TABLE dbo.#data;
	CREATE TABLE dbo.#data (TextData xml, EndTime datetime, DurationMS bigint, Mode int, rn int);

	DECLARE @file varchar(2000) = (SELECT path FROM sys.traces WHERE path LIKE '%TraceBlockedProcessReport%');
	SELECT @file = CASE WHEN PATINDEX('%[_]%', @file) = 1 THEN -- When the file contains an underscore (_)
	REPLACE(@file
			,SUBSTRING(@file, PATINDEX('%[_]%', @file)+1, PATINDEX('%[.]%', @file) - PATINDEX('%[_]%', @file)-1) /*get the number part*/
			,CAST(CAST(SUBSTRING(@file, PATINDEX('%[_]%', @file)+1, PATINDEX('%[.]%', @file) - PATINDEX('%[_]%', @file)-1) AS int) - @num_files_to_load + 1 AS sysname))/*substrac 1 from the number part*/
			ELSE @file -- When the file does not contains an underscore - the first file in the seriouse
			END;
	PRINT '-- Loading ' + CAST(@num_files_to_load AS sysname) + ' files(s) starting at file: ''' + @file + '''.';

	DECLARE @command varchar(MAX) = 
	'INSERT dbo.#data (TextData, EndTime, DurationMS, Mode, rn )
	 SELECT CONVERT(XML, TextData) AS TextData, EndTime AS EndTime, Duration/1000 AS DurationMS, Mode, ROW_NUMBER() OVER(ORDER BY EventSequence /*DESC*/) AS rn
	 FROM ::fn_trace_gettable(''' + @file + ''', DEFAULT) WHERE TextData IS NOT NULL;';

	 PRINT @command;
	 EXEC (@command);
END;


WITH CTE AS
(
	SELECT * FROM dbo.#data
	--SELECT CONVERT(XML, TextData) as TextData, EndTime AS EndTime, Duration/1000 AS DurationMS, Mode, ROW_NUMBER() OVER(ORDER BY EventSequence DESC) AS rn
	--FROM fn_trace_gettable('F:\DBArt\Dropbox\SQL Server Scripts\SystemOverview\BlockedProcessAnalysis\BlockedProcessesTrace.trc', 1) tr
	--WHERE TextData IS NOT NULL 
),
AllDataCTE AS
(
    SELECT 
		--TOP 200
	   lockData.blocking_spid, lockData.blocking_ecid, lockData.blocked_spid, blocked_ecid, lockData.waitresource, lockData.blocked_waitime, lockData.lockMode,
	   lockData.blocked_TrName, lockData.blocked_inputbuffer, lockData.blocking_inputbuffer,
	   blocked_frames.blocked_line, lockData.blocked_loginName, blocked_isolationlevel, DB_NAME(blocked_currentdb) AS blocked_currentdb, blocked_AppName, blocked_HostName,
	   blocking_frames.blocking_line, lockData.blocking_loginName, blocking_isolationlevel, DB_NAME(blocking_currentdb) AS blocking_currentdb, blocking_AppName, blocking_HostName,
	   SUBSTRING(
		  blocked_frame_Stmt.[text], 
		  (blocked_frames.blocked_StmtStart / 2) + 1, 
			(( CASE ISNULL(blocked_frames.blocked_StmtEnd, -1) 
				WHEN -1 THEN DATALENGTH(blocked_frame_Stmt.[text]) 
				ELSE blocked_frames.blocked_StmtEnd 
			END - blocked_frames.blocked_StmtStart )/ 2) + 1 
	   ) AS blocked_Statement,
	   SUBSTRING(
		  blocking_frame_Stmt.[text], 
		  (blocking_frames.blocking_StmtStart / 2) + 1, 
			(( CASE ISNULL(blocking_frames.blocking_StmtEnd, -1) 
				WHEN -1 THEN DATALENGTH(blocking_frame_Stmt.[text]) 
				ELSE blocking_frames.blocking_StmtEnd 
			END - blocking_frames.blocking_StmtStart )/ 2) + 1 
	   ) AS blocking_Statement,
	   ROW_NUMBER() OVER(PARTITION BY c.rn ORDER BY blocked_internalRowNum, blocking_internalRowNum) AS LockInternalRowNum, c.rn, c.EndTime,
	   c.TextData
    FROM 
	   CTE c
	   CROSS APPLY
	   (
		  SELECT
			 monitorloop = TextData.value('(//@monitorLoop)[1]', 'nvarchar(100)'),
			 blocked_spid = TextData.value('(/blocked-process-report/blocked-process/process/@spid)[1]', 'int'),
			 blocked_ecid = TextData.value('(/blocked-process-report/blocked-process/process/@ecid)[1]', 'int'),
			 waitresource = TextData.value('(/blocked-process-report/blocked-process/process/@waitresource)[1]', 'nvarchar(512)'),
			 lockMode  = TextData.value('(/blocked-process-report/blocked-process/process/@lockMode)[1]', 'varchar(32)'),

			 blocked_waitime = TextData.value('(/blocked-process-report/blocked-process/process/@waittime)[1]', 'bigint'),
			 blocked_TrName = TextData.value('(/blocked-process-report/blocked-process/process/@transactionname)[1]', 'nvarchar(512)'),
			 blocked_inputbuffer  = TextData.value('(/blocked-process-report/blocked-process/process/inputbuf/text())[1]', 'nvarchar(max)'),
			 blocked_stack = TextData.query('/blocked-process-report/blocked-process/process/executionStack'),
			 blocked_lastTranStartDate = TextData.value('(/blocked-process-report/blocked-process/process/@lasttranstarted)[1]', 'datetime'),
			 blocked_AppName = TextData.value('(/blocked-process-report/blocked-process/process/@clientapp)[1]', 'nvarchar(512)'),
			 blocked_HostName = TextData.value('(/blocked-process-report/blocked-process/process/@hostname)[1]', 'nvarchar(64)'),
			 blocked_kpid = TextData.value('(/blocked-process-report/blocked-process/process/@kpid)[1]', 'bigint'),
			 blocked_loginName = TextData.value('(/blocked-process-report/blocked-process/process/@loginname)[1]', 'nvarchar(128)'),
			 blocked_currentdb = TextData.value('(/blocked-process-report/blocked-process/process/@currentdb)[1]', 'int'),
			 blocked_isolationlevel = TextData.value('(/blocked-process-report/blocked-process/process/@isolationlevel)[1]', 'varchar(64)'),

			 blocking_inputbuffer = TextData.value('(/blocked-process-report/blocking-process/process/inputbuf/text())[1]', 'nvarchar(max)'),
			 blocking_spid = TextData.value('(/blocked-process-report/blocking-process/process/@spid)[1]', 'int'),
			 blocking_ecid = TextData.value('(/blocked-process-report/blocking-process/process/@ecid)[1]', 'int'),
			 blocking_waittime = TextData.value('(/blocked-process-report/blocking-process/process/@waittime)[1]', 'int'),
			 blocking_stack = TextData.query('/blocked-process-report/blocking-process/process/executionStack'),
			 blocking_lastBatchStartDate = TextData.value('(/blocked-process-report/blocking-process/process/@lastbatchstarted)[1]', 'datetime'),
			 blocking_lastBatchEndDate = TextData.value('(/blocked-process-report/blocking-process/process/@lastbatchcompleted)[1]', 'datetime'),
			 blocking_AppName = TextData.value('(/blocked-process-report/blocking-process/process/@clientapp)[1]', 'nvarchar(512)'),
			 blocking_HostName = TextData.value('(/blocked-process-report/blocking-process/process/@hostname)[1]', 'nvarchar(64)'),
			 blocking_kpid = TextData.value('(/blocked-process-report/blocking-process/process/@kpid)[1]', 'bigint'),
			 blocking_loginName = TextData.value('(/blocked-process-report/blocking-process/process/@loginname)[1]', 'nvarchar(128)'),
			 blocking_currentdb = TextData.value('(/blocked-process-report/blocking-process/process/@currentdb)[1]', 'int'),
			 blocking_isolationlevel = TextData.value('(/blocked-process-report/blocking-process/process/@isolationlevel)[1]', 'varchar(64)')

	   ) AS lockData
	   OUTER APPLY
	   (
		  SELECT 
			 ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS blocked_internalRowNum,
			 CONVERT(varbinary(64), t.c.value('@sqlhandle', 'varchar(128)'), 1) AS blocked_sqlhandle,
			 t.c.value('@line', 'int') AS blocked_line,
			 t.c.value('@stmtstart', 'int') AS blocked_StmtStart,
			 t.c.value('@stmtend', 'int') AS blocked_StmtEnd
		  FROM lockData.blocked_stack.nodes('/executionStack/frame') AS t(c)
	   ) AS blocked_frames
	   OUTER APPLY sys.dm_exec_sql_text(blocked_frames.blocked_sqlhandle) blocked_frame_Stmt
	   OUTER APPLY
	   (
		  SELECT 
			 ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS blocking_internalRowNum,
			 CONVERT(varbinary(64), t.c.value('@sqlhandle', 'varchar(128)'), 1) AS blocking_sqlhandle,
			 t.c.value('@line', 'int') AS blocking_line,
			 t.c.value('@stmtstart', 'int') AS blocking_StmtStart,
			 t.c.value('@stmtend', 'int') AS blocking_StmtEnd
		  FROM lockData.blocking_stack.nodes('/executionStack/frame') AS t(c)
	   ) AS blocking_frames
	   OUTER APPLY sys.dm_exec_sql_text(blocking_frames.blocking_sqlhandle) blocking_frame_Stmt
    WHERE 
	   (
		  blocked_frames.blocked_internalRowNum = blocking_frames.blocking_internalRowNum OR
		  blocked_frames.blocked_internalRowNum IS NULL OR
		  blocking_frames.blocking_internalRowNum IS NULL
	   ) 
)
SELECT 
    rn, 
	CASE LockInternalRowNum WHEN 1 THEN TextData ELSE NULL END AS TextData,
    CASE LockInternalRowNum WHEN 1 THEN EndTime ELSE NULL END AS EndTime,
    CASE LockInternalRowNum WHEN 1 THEN blocking_spid ELSE NULL END AS blocking_spid,
    --CASE LockInternalRowNum WHEN 1 THEN blocking_ecid ELSE NULL END AS blocking_ecid,
    CASE LockInternalRowNum WHEN 1 THEN blocked_spid ELSE NULL END AS blocked_spid,
    --CASE LockInternalRowNum WHEN 1 THEN blocked_ecid ELSE NULL END AS blocked_ecid,
    --CASE LockInternalRowNum WHEN 1 THEN waitresource ELSE NULL END AS waitresource,
    CASE LockInternalRowNum WHEN 1 THEN lockMode ELSE NULL END AS lockMode,
    CASE LockInternalRowNum WHEN 1 THEN blocked_waitime ELSE NULL END AS blocked_waitime,
    --CASE LockInternalRowNum WHEN 1 THEN blocked_TrName ELSE NULL END AS blocked_TrName,
    --CASE LockInternalRowNum WHEN 1 THEN blocked_loginName ELSE NULL END AS blocked_loginName,
    --CASE LockInternalRowNum WHEN 1 THEN blocking_loginName ELSE NULL END AS blocking_loginName,

    CASE LockInternalRowNum WHEN 1 THEN blocked_isolationlevel ELSE NULL END AS blocked_isolationlevel,
    --CASE LockInternalRowNum WHEN 1 THEN blocked_currentDB ELSE NULL END AS blocked_currentDB,
    CASE LockInternalRowNum WHEN 1 THEN blocking_isolationlevel ELSE NULL END AS blocking_isolationlevel,
    --CASE LockInternalRowNum WHEN 1 THEN blocking_currentDB ELSE NULL END AS blocking_currentDB,
    --CASE LockInternalRowNum WHEN 1 THEN blocked_AppName ELSE NULL END AS blocked_AppName,
    --CASE LockInternalRowNum WHEN 1 THEN blocking_AppName ELSE NULL END AS blocking_AppName,
    --CASE LockInternalRowNum WHEN 1 THEN blocked_HostName ELSE NULL END AS blocked_HostName,
    --CASE LockInternalRowNum WHEN 1 THEN blocking_HostName ELSE NULL END AS blocking_HostName,
    --blocked_line,
    blocked_Statement,
    --blocking_line,
    blocking_Statement,
    CASE LockInternalRowNum WHEN 1 THEN blocked_inputbuffer ELSE NULL END AS blocked_inputbuffer,
    CASE LockInternalRowNum WHEN 1 THEN blocking_inputbuffer ELSE NULL END AS blocking_inputbuffer
    
FROM AllDataCTE
WHERE 1=1 AND LockInternalRowNum = 1
AND AllDataCTE.EndTime > '2018-02-06 08:10'
ORDER BY rn, LockInternalRowNum;

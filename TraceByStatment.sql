
--CREATE DATABASE DBA; ALTER DATABASE DBA SET RECOVERY SIMPLE;

USE DBA;

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceByStatment]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].TraceByStatment;
GO

CREATE PROCEDURE TraceByStatment  
(  
  @Path sysname
 ,@MaxFileSize	bigint  = 50  
 ,@FileCount	int		= 50  
 ,@Statment sysname
 ,@DurationFilter_ms int = 0
)  
/*  
--Start a trace that captures RPC Completed and BATCH Comleted.
DECLARE @path sysname, @Statment sysname;
SELECT	@path = 'Z:\Traces\', @statment = 'RS_';
SELECT	@path = @path + @statment;
EXEC DBA.dbo.TraceByStatment @MaxFileSize = 50, @FileCount = 100, @Statment = @statment, @Path = @path, @DurationFilter_ms = 1;

SELECT * INTO TempStorage.dbo.BS_EVENT_SENDER_SQLCMD_INSERT_TO_QUEUE FROM ::fn_trace_gettable(N'D:\Traces\SP_PLN.trc', DEFAULT)

EXEC  sp_trace_setstatus 3, 1 --start
EXEC  sp_trace_setstatus 5, 0 --stop
EXEC  sp_trace_setstatus 5, 2 --remove

SELECT * FROM sys.traces 

xp_fixeddrives

-- stop all traces
USE master;SET NOCOUNT ON;

--SELECT * FROM sys.traces WHERE path IS NOT NULL AND id > 1;

DECLARE @t TABLE (id int);
INSERT @t (id) SELECT id FROM sys.traces WHERE path IS NOT NULL AND id > 1;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR 
	SELECT id FROM @t ORDER BY id;

DECLARE @id int;
OPEN cur;
	FETCH NEXT FROM cur INTO @id ;

	WHILE (@@FETCH_STATUS <> -1)
	BEGIN

		PRINT @id;
		EXEC  sp_trace_setstatus @id, 0; --stop
		EXEC  sp_trace_setstatus @id, 2; --remove

		FETCH NEXT FROM cur INTO @id ;
	END;
CLOSE cur; DEALLOCATE cur;
GO


*/  
AS      
SET NOCOUNT ON;    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   

SELECT @Statment = N'%' + @Statment + N'%';
  

DECLARE @RC int, @TraceId int, @EventClass int;  
  
EXEC @RC = sp_trace_create   
  @TraceId OUTPUT  
 ,@options			= 2								-- file rollover  
 ,@tracefile		= @Path 
 ,@maxfilesize  = @MaxFileSize		-- MB  
 ,@stoptime			= NULL						-- @stoptime   
 ,@filecount		= @FileCount ;		-- @filecount    
  
IF (@RC <> 0) OR (@@ERROR <> 0)   
BEGIN;  
 SELECT @RC AS ReturnCode, @@ERROR AS Error; RETURN(1);  
END;  
  
  
-- sp_trace_setevent @traceid, @eventid, @columnid, @on;  
  
DECLARE @on bit; SELECT @on = 1;  
  
  
-- RPC:Completed
-- Occurs when a remote procedure call (RPC) has completed.
SELECT @EventClass = 10 ;
exec sp_trace_setevent @TraceId, @EventClass,  1, @on	-- TextData
exec sp_trace_setevent @TraceId, @EventClass, 35, @on	-- DatabaseName
exec sp_trace_setevent @TraceId, @EventClass,  8, @on	-- HostName
exec sp_trace_setevent @TraceId, @EventClass, 10, @on	-- ApplicationName
exec sp_trace_setevent @TraceId, @EventClass, 11, @on	-- LoginName
exec sp_trace_setevent @TraceId, @EventClass, 12, @on	-- SPID
exec sp_trace_setevent @TraceId, @EventClass, 13, @on	-- Duration
exec sp_trace_setevent @TraceId, @EventClass, 14, @on	-- StartTime
exec sp_trace_setevent @TraceId, @EventClass, 15, @on	-- EndtTime
exec sp_trace_setevent @TraceId, @EventClass, 16, @on	-- Reads
exec sp_trace_setevent @TraceId, @EventClass, 17, @on	-- Writes
exec sp_trace_setevent @TraceId, @EventClass, 18, @on	-- CPU
exec sp_trace_setevent @TraceId, @EventClass, 22, @on	-- ObjectId
exec sp_trace_setevent @TraceId, @EventClass, 48, @on	-- RowCounts 
exec sp_trace_setevent @TraceId, @EventClass, 51, @on	-- EventSequence
EXEC sp_trace_setevent @TraceId, @EventClass, 34, @on; -- ObjectName 
EXEC sp_trace_setevent @TraceId, @EventClass, 21, @on; -- EventSubClass 
EXEC sp_trace_setevent @TraceId, @EventClass, 31, @on; -- Error


-- SQL:BatchCompleted
-- Occurs when a Transact-SQL batch has completed.
SELECT @EventClass = 12 ;
exec sp_trace_setevent @TraceId, @EventClass,  1, @on	-- TextData
exec sp_trace_setevent @TraceId, @EventClass, 35, @on	-- DatabaseName
exec sp_trace_setevent @TraceId, @EventClass,  8, @on	-- HostName
exec sp_trace_setevent @TraceId, @EventClass, 10, @on	-- ApplicationName
exec sp_trace_setevent @TraceId, @EventClass, 11, @on	-- LoginName
exec sp_trace_setevent @TraceId, @EventClass, 12, @on	-- SPID
exec sp_trace_setevent @TraceId, @EventClass, 13, @on	-- Duration
exec sp_trace_setevent @TraceId, @EventClass, 14, @on	-- StartTime
exec sp_trace_setevent @TraceId, @EventClass, 15, @on	-- EndtTime
exec sp_trace_setevent @TraceId, @EventClass, 16, @on	-- Reads
exec sp_trace_setevent @TraceId, @EventClass, 17, @on	-- Writes
exec sp_trace_setevent @TraceId, @EventClass, 18, @on	-- CPU
exec sp_trace_setevent @TraceId, @EventClass, 22, @on	-- ObjectId
exec sp_trace_setevent @TraceId, @EventClass, 48, @on	-- RowCounts 
exec sp_trace_setevent @TraceId, @EventClass, 51, @on	-- EventSequence
EXEC sp_trace_setevent @TraceId, @EventClass, 34, @on; -- ObjectName 
EXEC sp_trace_setevent @TraceId, @EventClass, 21, @on; -- EventSubClass
EXEC sp_trace_setevent @TraceId, @EventClass, 31, @on; -- Error


/*
-- Occurs when the Transact-SQL statement has completed.
-- SQL:StmtCompleted
SELECT @EventClass = 41 ;
exec sp_trace_setevent @TraceId, @EventClass,  1, @on	-- TextData
exec sp_trace_setevent @TraceId, @EventClass, 35, @on	-- DatabaseName
exec sp_trace_setevent @TraceId, @EventClass,  8, @on	-- HostName
exec sp_trace_setevent @TraceId, @EventClass, 10, @on	-- ApplicationName
exec sp_trace_setevent @TraceId, @EventClass, 11, @on	-- LoginName
exec sp_trace_setevent @TraceId, @EventClass, 12, @on	-- SPID
exec sp_trace_setevent @TraceId, @EventClass, 13, @on	-- Duration
exec sp_trace_setevent @TraceId, @EventClass, 14, @on	-- StartTime
exec sp_trace_setevent @TraceId, @EventClass, 15, @on	-- EndtTime
exec sp_trace_setevent @TraceId, @EventClass, 16, @on	-- Reads
exec sp_trace_setevent @TraceId, @EventClass, 17, @on	-- Writes
exec sp_trace_setevent @TraceId, @EventClass, 18, @on	-- CPU
exec sp_trace_setevent @TraceId, @EventClass, 22, @on	-- ObjectId
exec sp_trace_setevent @TraceId, @EventClass, 48, @on	-- RowCounts 
exec sp_trace_setevent @TraceId, @EventClass, 51, @on	-- EventSequence
EXEC sp_trace_setevent @TraceId, @EventClass, 34, @on; -- ObjectName 
EXEC sp_trace_setevent @TraceId, @EventClass, 21, @on; -- EventSubClass
EXEC sp_trace_setevent @TraceId, @EventClass, 31, @on; -- Error


-- Indicates that a Transact-SQL statement within a stored procedure has finished executing.
-- SP:StmtCompleted
SELECT @EventClass = 45 ;
exec sp_trace_setevent @TraceId, @EventClass,  1, @on	-- TextData
exec sp_trace_setevent @TraceId, @EventClass, 35, @on	-- DatabaseName
exec sp_trace_setevent @TraceId, @EventClass,  8, @on	-- HostName
exec sp_trace_setevent @TraceId, @EventClass, 10, @on	-- ApplicationName
exec sp_trace_setevent @TraceId, @EventClass, 11, @on	-- LoginName
exec sp_trace_setevent @TraceId, @EventClass, 12, @on	-- SPID
exec sp_trace_setevent @TraceId, @EventClass, 13, @on	-- Duration
exec sp_trace_setevent @TraceId, @EventClass, 14, @on	-- StartTime
exec sp_trace_setevent @TraceId, @EventClass, 15, @on	-- EndtTime
exec sp_trace_setevent @TraceId, @EventClass, 16, @on	-- Reads
exec sp_trace_setevent @TraceId, @EventClass, 17, @on	-- Writes
exec sp_trace_setevent @TraceId, @EventClass, 18, @on	-- CPU
exec sp_trace_setevent @TraceId, @EventClass, 22, @on	-- ObjectId
exec sp_trace_setevent @TraceId, @EventClass, 48, @on	-- RowCounts 
exec sp_trace_setevent @TraceId, @EventClass, 51, @on	-- EventSequence
EXEC sp_trace_setevent @TraceId, @EventClass, 34, @on; -- ObjectName 
EXEC sp_trace_setevent @TraceId, @EventClass, 21, @on; -- EventSubClass
EXEC sp_trace_setevent @TraceId, @EventClass, 31, @on; -- Error


--SP:Completed
-- Indicates when the stored procedure has completed.
SELECT @EventClass = 43 ;
exec sp_trace_setevent @TraceId, @EventClass,  1, @on	-- TextData
exec sp_trace_setevent @TraceId, @EventClass, 35, @on	-- DatabaseName
exec sp_trace_setevent @TraceId, @EventClass,  8, @on	-- HostName
exec sp_trace_setevent @TraceId, @EventClass, 10, @on	-- ApplicationName
exec sp_trace_setevent @TraceId, @EventClass, 11, @on	-- LoginName
exec sp_trace_setevent @TraceId, @EventClass, 12, @on	-- SPID
exec sp_trace_setevent @TraceId, @EventClass, 13, @on	-- Duration
exec sp_trace_setevent @TraceId, @EventClass, 14, @on	-- StartTime
exec sp_trace_setevent @TraceId, @EventClass, 15, @on	-- EndtTime
exec sp_trace_setevent @TraceId, @EventClass, 16, @on	-- Reads
exec sp_trace_setevent @TraceId, @EventClass, 17, @on	-- Writes
exec sp_trace_setevent @TraceId, @EventClass, 18, @on	-- CPU
exec sp_trace_setevent @TraceId, @EventClass, 22, @on	-- ObjectId
exec sp_trace_setevent @TraceId, @EventClass, 48, @on	-- RowCounts 
exec sp_trace_setevent @TraceId, @EventClass, 51, @on	-- EventSequence
EXEC sp_trace_setevent @TraceId, @EventClass, 34, @on; -- ObjectName 
EXEC sp_trace_setevent @TraceId, @EventClass, 21, @on; -- EventSubClass
EXEC sp_trace_setevent @TraceId, @EventClass, 31, @on; -- Error
 
*/

-- Blocked Process Report
-- Occurs when a process has been blocked for more than a specified amount of time. Does not include system processes or processes that are waiting on non deadlock-detectable resources
SELECT @EventClass = 137 ;
exec sp_trace_setevent @TraceId, @EventClass, 3, @on
exec sp_trace_setevent @TraceId, @EventClass, 15, @on
exec sp_trace_setevent @TraceId, @EventClass, 51, @on
exec sp_trace_setevent @TraceId, @EventClass, 4, @on
exec sp_trace_setevent @TraceId, @EventClass, 12, @on
exec sp_trace_setevent @TraceId, @EventClass, 24, @on
exec sp_trace_setevent @TraceId, @EventClass, 32, @on
exec sp_trace_setevent @TraceId, @EventClass, 60, @on
exec sp_trace_setevent @TraceId, @EventClass, 64, @on
exec sp_trace_setevent @TraceId, @EventClass, 1, @on
exec sp_trace_setevent @TraceId, @EventClass, 13, @on
exec sp_trace_setevent @TraceId, @EventClass, 41, @on
exec sp_trace_setevent @TraceId, @EventClass, 14, @on
exec sp_trace_setevent @TraceId, @EventClass, 22, @on
exec sp_trace_setevent @TraceId, @EventClass, 26, @on

  
  
/*  
List of Columns & EventClass: http://msdn.microsoft.com/en-us/library/ms186265.aspx  
       
sp_trace_setfilter @TraceId, @columnid, @logical_operator, @comparison_operator, @value ;  
  
@logical_operator: AND (0) or OR (1)   
  
@comparison_operator:  
0 = Equal, 1 = Not equal, 2 = Greater than, 3 = Less than, 4 = Greater than or equal,   
5 = Less than or equal, , 6 = Like, 7 = Not like   
*/  
  
  

-- Exclude ApplicationName  
EXEC sp_trace_setfilter @TraceId, 10, 0, 7, N'SQL Server Profiler';  
--EXEC sp_trace_setfilter @TraceId, 10, 0, 6, N'Replication Distribution Agent';  
  
-- Include TextData  
EXEC sp_trace_setfilter @TraceId, 1, 0, 6, @Statment;  
  
-- Exclude HostName  
--EXEC sp_trace_setfilter @TraceId, 8, 0, 7, @@servername;  


-- Duration (300000 micro seconds = 300ms)
-- 10,000,000 = 10 seconds
--DECLARE @bigintfilter bigint;
--SELECT @bigintfilter = 5000000

/* set the filter to micro seconds */
DECLARE @bigintfilter bigint
SELECT @bigintfilter = @DurationFilter_ms * 1000
EXEC sp_trace_setfilter @TraceId, 13, 0, 4, @bigintfilter;


-- Include DatabaseName  
--EXEC sp_trace_setfilter @TraceId, 35, 0, 6, N'BurstingDB';  
  
-- Start trace  
EXEC sp_trace_setstatus @TraceId, 1 ;  


SELECT TraceID = @TraceId;  
  
RETURN(0);  
GO
/*
EXEC  sp_trace_setstatus 3, 1 --start
EXEC  sp_trace_setstatus 2, 0 --stop
EXEC  sp_trace_setstatus 2, 2 --remove

SELECT * INTO TempStorage.dbo.[ACM_PLACEMENTS_LIST] FROM ::fn_trace_gettable(N'N:\Traces\ACM_PLACEMENTS_LIST.trc', DEFAULT)

SELECT [id], [status], [path], event_count, dropped_event_count, max_size, max_files, is_rollover, is_shutdown, buffer_count, buffer_size,
 file_position, start_time, stop_time, last_event_time FROM sys.traces --WHERE Id = 1

SELECT
	e.name AS Event_Name,
	c.name AS Column_Name
FROM fn_trace_geteventinfo(4) ei
JOIN sys.trace_events e ON ei.eventid = e.trace_event_id
JOIN sys.trace_columns c ON ei.columnid = c.trace_column_id;


SELECT
	 columnid
	,c.name AS Column_Name
	,logical_operator
	,comparison_operator
	,value
FROM fn_trace_getfilterinfo(10) ei
JOIN sys.trace_columns c ON ei.columnid = c.trace_column_id;

*/




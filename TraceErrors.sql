USE master;
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DBA' )
BEGIN;
	CREATE DATABASE DBA;
	ALTER DATABASE DBA SET RECOVERY SIMPLE;
END;

--xp_cmdshell 'md D:\Traces'

USE [DBA];
IF OBJECT_ID('TraceErrors', 'P') IS NOT NULL DROP PROCEDURE TraceErrors;
GO
/*
EXEC DBA.dbo.TraceErrors @MaxFileSize = 50, @FileCount = 30, @Path = 'D:\Traces\TraceErrors'

EXEC  sp_trace_setstatus 3, 1 --start
EXEC  sp_trace_setstatus 4, 0 --stop
EXEC  sp_trace_setstatus 4, 2 --remove

SELECT * FROM sys.traces 
*/
CREATE PROCEDURE [dbo].[TraceErrors]  
(  
  @Path sysname
 ,@MaxFileSize	bigint  = 50  
 ,@FileCount	int		= 50  
) 
AS      
SET NOCOUNT ON;    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
  

DECLARE @RC int, @TraceID int, @EventClass int;  
  
EXEC @RC = sp_trace_create   
  @TraceID OUTPUT  
 ,@options		= 2				-- file rollover  
 ,@tracefile	= @Path 
 ,@MaxFileSize  = @MaxFileSize	-- MB  
 ,@stoptime		= NULL			-- @stoptime   
 ,@FileCount	= @FileCount ;	-- @filecount    
  
  
IF (@RC <> 0) OR (@@ERROR <> 0)   
BEGIN;  
 SELECT @RC AS ReturnCode, @@ERROR AS Error; RETURN(1);  
END;  
  
  
-- sp_trace_setevent @traceid, @eventid, @columnid, @on;  
DECLARE @on bit; SELECT @on = 1;  
  
  
-- RPC:Completed
-- Occurs when a remote procedure call (RPC) has completed.
SELECT @EventClass = 10 ;
EXEC sp_trace_setevent @TraceID, @EventClass,  1, @on	-- TextData
EXEC sp_trace_setevent @TraceID, @EventClass, 35, @on	-- DatabaseName
EXEC sp_trace_setevent @TraceID, @EventClass,  8, @on	-- HostName
EXEC sp_trace_setevent @TraceID, @EventClass, 10, @on	-- ApplicationName
EXEC sp_trace_setevent @TraceID, @EventClass, 11, @on	-- LoginName
EXEC sp_trace_setevent @TraceID, @EventClass, 12, @on	-- SPID
EXEC sp_trace_setevent @TraceID, @EventClass, 13, @on	-- Duration
EXEC sp_trace_setevent @TraceID, @EventClass, 14, @on	-- StartTime
EXEC sp_trace_setevent @TraceID, @EventClass, 15, @on	-- EndtTime
EXEC sp_trace_setevent @TraceID, @EventClass, 16, @on	-- Reads
EXEC sp_trace_setevent @TraceID, @EventClass, 17, @on	-- Writes
EXEC sp_trace_setevent @TraceID, @EventClass, 18, @on	-- CPU
EXEC sp_trace_setevent @TraceID, @EventClass, 22, @on	-- ObjectId
EXEC sp_trace_setevent @TraceID, @EventClass, 48, @on	-- RowCounts 
EXEC sp_trace_setevent @TraceID, @EventClass, 51, @on	-- EventSequence
EXEC sp_trace_setevent @TraceID, @EventClass, 34, @on;  -- ObjectName 
EXEC sp_trace_setevent @TraceID, @EventClass, 21, @on;  -- EventSubClass 
EXEC sp_trace_setevent @TraceID, @EventClass, 31, @on;  -- Error


-- SQL:BatchCompleted
-- Occurs when a Transact-SQL batch has completed.
SELECT @EventClass = 12 ;
EXEC sp_trace_setevent @TraceID, @EventClass,  1, @on	-- TextData
EXEC sp_trace_setevent @TraceID, @EventClass, 35, @on	-- DatabaseName
EXEC sp_trace_setevent @TraceID, @EventClass,  8, @on	-- HostName
EXEC sp_trace_setevent @TraceID, @EventClass, 10, @on	-- ApplicationName
EXEC sp_trace_setevent @TraceID, @EventClass, 11, @on	-- LoginName
EXEC sp_trace_setevent @TraceID, @EventClass, 12, @on	-- SPID
EXEC sp_trace_setevent @TraceID, @EventClass, 13, @on	-- Duration
EXEC sp_trace_setevent @TraceID, @EventClass, 14, @on	-- StartTime
EXEC sp_trace_setevent @TraceID, @EventClass, 15, @on	-- EndtTime
EXEC sp_trace_setevent @TraceID, @EventClass, 16, @on	-- Reads
EXEC sp_trace_setevent @TraceID, @EventClass, 17, @on	-- Writes
EXEC sp_trace_setevent @TraceID, @EventClass, 18, @on	-- CPU
EXEC sp_trace_setevent @TraceID, @EventClass, 22, @on	-- ObjectId
EXEC sp_trace_setevent @TraceID, @EventClass, 48, @on	-- RowCounts 
EXEC sp_trace_setevent @TraceID, @EventClass, 51, @on	-- EventSequence
EXEC sp_trace_setevent @TraceID, @EventClass, 34, @on;  -- ObjectName 
EXEC sp_trace_setevent @TraceID, @EventClass, 21, @on;  -- EventSubClass
EXEC sp_trace_setevent @TraceID, @EventClass, 31, @on;  -- Error


/*  
List of Columns & EventClass httpmsdn.microsoft.comen-uslibraryms186265.aspx  
       
sp_trace_setfilter @TraceID, @columnid, @logical_operator, @comparison_operator, @value ;  
  
@logical_operator AND (0) or OR (1)   
  
@comparison_operator  
0 = Equal, 1 = Not equal, 2 = Greater than, 3 = Less than, 4 = Greater than or equal,   
5 = Less than or equal, , 6 = Like, 7 = Not like   
*/  

-- Exclude ApplicationName  
--EXEC sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Server Profiler';  
  
-- Exclude TextData  
--EXEC sp_trace_setfilter @TraceID, 1, 0, 7, N'exec sp_reset_connection%';  
  
-- Exclude HostName  
--EXEC sp_trace_setfilter @TraceID, 8, 0, 7, @@servername;  

-- Include DatabaseName  
--EXEC sp_trace_setfilter @TraceID, 35, 0, 6, N'BurstingDB';  


-- errors only
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, 0;
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, NULL;

-- Start trace  
EXEC sp_trace_setstatus @TraceID, 1 ;  


SELECT TraceID = @TraceID;  
RETURN(0);  
GO



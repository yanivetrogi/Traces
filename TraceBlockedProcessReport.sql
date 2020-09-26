USE [DBA];

/*
	CREATE DATABASE DBA; SET RECOVERY SIMPLE; 
	ALTER database DBA SET RECOVERY SIMPLE;
*/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceBlockedProcessReport]') AND type IN (N'P', N'PC'))
	DROP PROCEDURE [dbo].TraceBlockedProcessReport;
GO
/*  
EXEC sp_configure 'blocked process threshold (s)', 5 RECONFIGURE;

EXEC DBA.dbo.TraceBlockedProcessReport @MaxFileSize = 50, @FileCount = 10, @Path = N'D:\Traces\TraceBlockedProcessReport';
 
EXEC  sp_trace_setstatus 3, 1 --start
EXEC  sp_trace_setstatus 8, 0 --stop
EXEC  sp_trace_setstatus 8, 2 --remove

SELECT * FROM sys.traces 

-- Events
SELECT
	e.name AS Event_Name,
	c.name AS Column_Name
FROM fn_trace_geteventinfo(4) ei
JOIN sys.trace_events e ON ei.eventid = e.trace_event_id
JOIN sys.trace_columns c ON ei.columnid = c.trace_column_id;

-- Filters
SELECT
	 columnid
	,c.name AS Column_Name
	,logical_operator
	,comparison_operator
	,value
FROM fn_trace_getfilterinfo(4) ei
JOIN sys.trace_columns c ON ei.columnid = c.trace_column_id;
*/  
CREATE PROCEDURE TraceBlockedProcessReport  
(  
  @Path sysname
 ,@MaxFileSize	bigint  = 50  
 ,@FileCount	int		= 50  
)  
AS      
SET NOCOUNT ON;    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
  

DECLARE @RC int, @TraceId int, @EventClass int;  
  
EXEC @RC = sp_trace_create   
  @TraceId OUTPUT  
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

-- Blocked Process Report
-- Occurs when a process has been blocked for more than a specified amount of time. 
-- Does not include system processes or processes that are waiting on non deadlock-detectable resources
SELECT @EventClass = 137 ;
EXEC sp_trace_setevent @TraceId, @EventClass, 3,  @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 15, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 51, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 4,  @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 12, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 24, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 32, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 60, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 64, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 1,  @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 13, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 41, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 14, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 22, @on;
EXEC sp_trace_setevent @TraceId, @EventClass, 26, @on;

   
-- Start trace  
EXEC sp_trace_setstatus @TraceId, 1 ;  


SELECT TraceID = @TraceId;  
RETURN(0);  
GO

USE master;
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DBA' )
BEGIN;
	CREATE DATABASE DBA;
	ALTER DATABASE DBA SET RECOVERY SIMPLE;
END;
--xp_cmdshell 'md		D:\Traces'

USE [DBA];
IF OBJECT_ID('TraceExceptions', 'P') IS NOT NULL DROP PROCEDURE TraceExceptions;
GO
/*
EXEC DBA.dbo.TraceExceptions @MaxFileSize = 50, @FileCount = 30, @Path = 'C:\Traces\TraceExceptions'

EXEC  sp_trace_setstatus 3, 1 --start
EXEC  sp_trace_setstatus 4, 0 --stop
EXEC  sp_trace_setstatus 4, 2 --remove

SELECT * FROM sys.traces 
*/

CREATE PROCEDURE [dbo].[TraceExceptions]  
(  
  @Path sysname
 ,@MaxFileSize	bigint  = 50  
 ,@FileCount	int		= 10  
) 
AS      
SET NOCOUNT ON;    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
  

DECLARE @RC int, @TraceID int, @EventClass int;  
  
EXEC @RC = sp_trace_create   
  @TraceID OUTPUT  
 ,@options			= 2					-- file rollover  
 ,@tracefile		= @Path 
 ,@MaxFileSize		= @MaxFileSize		-- MB  
 ,@stoptime			= NULL				-- @stoptime   
 ,@FileCount		= @FileCount ;		-- @filecount    
  
  
IF (@RC <> 0) OR (@@ERROR <> 0)   
BEGIN;  
 SELECT @RC AS ReturnCode, @@ERROR AS Error; RETURN(1);  
END;  
  
-- sp_trace_setevent @traceid, @eventid, @columnid, @on;    
DECLARE @on bit; SELECT @on = 1;  
  
-- User Error Message
-- Displays error messages that users see in the case of an error or exception.
SELECT @EventClass = 162 ;
EXEC sp_trace_setevent @TraceID, @EventClass, 1, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 9, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 3, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 11, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 4, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 6, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 7, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 8, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 10, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 12, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 14, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 20, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 26, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 30, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 31, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 35, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 41, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 49, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 50, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 51, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 60, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 64, @on
EXEC sp_trace_setevent @TraceID, @EventClass, 66, @on


/*  
List of Columns & EventClass httpmsdn.microsoft.comen-uslibraryms186265.aspx  
       
sp_trace_setfilter @TraceId, @columnid, @logical_operator, @comparison_operator, @value ;  
  
@logical_operator AND (0) or OR (1)   
  
@comparison_operator  
0 = Equal, 1 = Not equal, 2 = Greater than, 3 = Less than, 4 = Greater than or equal,   
5 = Less than or equal, , 6 = Like, 7 = Not like   
*/  

/*
-- Set the Filters
DECLARE @intfilter int
DECLARE @bigintfilter bigint

SET @intfilter = 5701
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, @intfilter

SET @intfilter = 5703
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, @intfilter

SET @intfilter = 8153
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, @intfilter

SET @intfilter = 4035
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, @intfilter

SET @intfilter = 3014
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, @intfilter

SET @intfilter = 3211
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, @intfilter

SET @intfilter = 14108
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, @intfilter

SET @intfilter = 14149
EXEC sp_trace_setfilter @TraceID, 31, 0, 1, @intfilter

*/

-- Start trace  
EXEC sp_trace_setstatus @TraceID, 1 ;  


SELECT TraceID = @TraceID;  
RETURN(0);  
GO
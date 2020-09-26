USE DBA; 
IF EXISTS (SELECT * FROM sys.configurations WHERE name = 'show advanced options' AND value_in_use = 0) EXEC sp_configure @configname = 'show advanced options', @configvalue = 1; RECONFIGURE ;
IF EXISTS (SELECT * FROM sys.configurations WHERE name = 'xp_cmdshell' AND value_in_use = 0) EXEC sp_configure @configname = 'xp_cmdshell', @configvalue = 1; RECONFIGURE ;
IF EXISTS (SELECT * FROM sys.configurations WHERE name = 'clr enabled' AND value_in_use = 0) EXEC sp_configure @configname = 'clr enabled', @configvalue = 1; RECONFIGURE ;

/*
EXEC dbo.TraceExecutionsDelete @command = 'del C:\Traces\Baseline\Baseline*.trc';
EXEC DBA.dbo.TraceExecutionsStart @Database = NULL, @MaxFileSize = 100, @FileCount = 50, @Minutes = 10, @Path = N'C:\Traces\BaseLine' ;
EXEC DBA.dbo.TraceExecutionsLoad @path = N'C:\GoogleDrive\Projects\CallFlow\Clalit\20190704\1518\', @file =  N'trace*.trc';
EXEC DBA.dbo.TraceExecutionsManipulateData @Rows = 400


SELECT * FROM SYS.traces AS t

*/

USE DBA; 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceExecutionsDelete]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[TraceExecutionsDelete] ;
GO
CREATE PROCEDURE [dbo].[TraceExecutionsDelete] 
(
	@command varchar(1000)
)
AS
SET NOCOUNT ON; 

EXEC sys.xp_cmdshell @command /*, no_output */ ;
GO



USE DBA; 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceExecutionsLoad]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[TraceExecutionsLoad] ;
GO

CREATE PROCEDURE [dbo].[TraceExecutionsLoad] 
(	
	 @path sysname
	,@file sysname
)
/*
	Yaniv Etrogi
	Load the data from the trace files to a table.
*/
AS
SET NOCOUNT ON; 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


--EXEC DBA.dbo.TraceExecutionsLoad @Path = N'N:\Traces', @file =  N'BaseLine_*.trc';


/* Validate the given path */
IF (SELECT DBA.dbo.SQLIO_fnFolderExists(@path) ) = 0
BEGIN;
	RAISERROR ('The given path ''%s'' does not exist.', 16, 1, @path);
	RETURN;
END;


-- If the table does not exist ctreate it.
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BaseLineFull]') AND type in (N'U'))
BEGIN;
	SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
	CREATE TABLE [dbo].[BaseLineFull]
	(
		[StartTime] [datetime] NULL,
		[EventClass] [int] NULL,
		[Login] [nvarchar](256) NULL,
		[Object] [nvarchar](256) NULL,
		[Application] [nvarchar](256) NULL,
		[Database] [nvarchar](256) NULL,
		[Host] [nvarchar](256) NULL,
		[CPU] [int] NULL,
		[Reads] [bigint] NULL,
		[Writes] [bigint] NULL,
		[Duration] [bigint] NULL,
		[RowCounts] [bigint] NULL,
		[TextData] [ntext] NULL,
		[SPID] [int] NULL
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
END ELSE
BEGIN;
	TRUNCATE TABLE dbo.BaseLineFull;
END;


/* Get the trace file names into a table	*/
IF OBJECT_ID('tempdb.dbo.#trace_files') IS NOT NULL DROP TABLE tempdb.dbo.#trace_files;
CREATE TABLE #trace_files
(
	id [int] identity(1,1) CONSTRAINT PK_#trace_files PRIMARY KEY,
	[path] [nvarchar](max) NULL,
	[file_name] [nvarchar](max) NULL,
	[extension] [nvarchar](max) NULL,
	[directory_name] [nvarchar](max) NULL,
	[created_time] [datetime] NULL,
	[created_time_utc] [datetime] NULL,
	[modified_time] [datetime] NULL,
	[modified_time_utc] [datetime] NULL,
	[last_accessed_time] [datetime] NULL,
	[last_accessed_time_utc] [datetime] NULL,
	[file_length] [bigint] NULL,
	[is_read_only] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

 /* Get the trace files names from the file system into a table */
INSERT #trace_files
(
	 [path]
	,[file_name]
	,extension
	,directory_name
	,created_time
	,created_time_utc
	,modified_time
	,modified_time_utc
	,last_accessed_time
	,last_accessed_time_utc
	,file_length
	,is_read_only
)
SELECT 
	 [path]
	,[file_name]
	,extension
	,directory_name
	,created_time
	,created_time_utc
	,modified_time
	,modified_time_utc
	,last_accessed_time
	,last_accessed_time_utc
	,file_length
	,is_read_only
FROM DBA.dbo.SQLIO_fnGetFiles (@path, @file, 0);
--SELECT * FROM #trace_files;


DECLARE @id int, @max_id int, @file_name sysname, @full_path sysname;
SELECT @id = 1,  @max_id = MAX(id) FROM dbo.#trace_files;


/* Load the trace files to table */
WHILE (@id <= @max_id)
BEGIN;
	
	SELECT @file_name = file_name FROM dbo.#trace_files WHERE id = @id;
	SELECT @full_path = @path + N'\' + @file_name;

	INSERT [dbo].[BaseLineFull]	
	(
		 StartTime
		,EventClass
		,[Login]
		,[Object]
		,[Application]
		,[Database]
		,Host
		,CPU
		,Reads
		,Writes
		,Duration
		,RowCounts
		,TextData
		,SPID
	)
	SELECT 
		 [StartTime]
		,[EventClass] 
		,[LoginName]				AS [Login]
		,[ObjectName]				AS [Object]
		,[ApplicationName]	AS [Application]
		,[DatabaseName]			AS [Database]
		,[HostName]					AS [Host]
		,[CPU] 
		,[Reads] 
		,[Writes]	
		,[Duration] 
		,[RowCounts] 
		,[TextData] 
		,[SPID] 
	FROM ::fn_trace_gettable(@full_path, 1);

	SELECT @id = @id + 1;
	PRINT 'id: ' + CAST(@id AS sysname) + '  |  full_path: ' + @full_path;
END;
GO


USE DBA; 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceExecutionsManipulateData]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[TraceExecutionsManipulateData] ;
GO
CREATE PROCEDURE [dbo].[TraceExecutionsManipulateData] 
(
	@Rows int = 400
)
AS
SET NOCOUNT ON; 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


--EXEC DBA.dbo.TraceExecutionsManipulateData @Rows = 100


-- If the table does not exist ctreate it.
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BaseLine]') AND type in (N'U'))
BEGIN;
	SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
	CREATE TABLE [dbo].[BaseLine]
	(
	[InsertTime] [smalldatetime] NULL CONSTRAINT [DF_BaseLine_InsertTime]  DEFAULT (GETDATE()),
	[BatchId] [int] NULL,
	[StartTime] datetime NULL,
	[EndTime] datetime NULL,
	[Database] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EventClass] [varchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Statment] [varchar](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Executions] [int] NULL,
	[Total_Duration_ms] [bigint] NULL,
	[AVG_Duration_ms] [decimal](10, 3) NULL,
	[Total_Reads] [bigint] NULL,
	[AVG_Reads] [int] NULL,
	[Total_Writes] [bigint] NULL,
	[AVG_Writes] [int] NULL,
	[Total_CPU_ms] [bigint] NULL,
	[AVG_CPU_ms] [decimal](10, 3) NULL,
	[Total_RowCount] [bigint] NULL,
	[AVG_RowCount] [int] NULL
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
	SET ANSI_PADDING OFF;
	CREATE CLUSTERED INDEX IXC_BaseLine__StartTime ON dbo.BaseLine(StartTime);
	CREATE NONCLUSTERED INDEX IX_BaseLine__BatchId ON dbo.BaseLine (BatchId);
END;


-- Get the time period of the trace data that was captured.
DECLARE @StartTime datetime, @EndTime datetime, @BatchId int;
SELECT @StartTime = MIN(StartTime), @EndTime = MAX(StartTime) FROM dbo.BaseLineFull;
SELECT @BatchId = ISNULL(MAX(BatchId), 0) + 1 FROM dbo.BaseLine;
--SELECT @BatchId


INSERT [dbo].[BaseLine]	
(
	 BatchId
	,StartTime
	,EndTime
	,[Database]
	,EventClass
	,Statment
	,Executions
	,Total_Duration_ms
	,AVG_Duration_ms
	,Total_Reads
	,AVG_Reads
	,Total_Writes
	,AVG_Writes
	,Total_CPU_ms
	,AVG_CPU_ms
	,Total_RowCount
	,AVG_RowCount			
)
SELECT 
	 @BatchId
	,@StartTime
	,@EndTime
	,[Database]
	,EventClass
	,Statment
	,Executions
	,Total_Duration_ms
	,AVG_Duration_ms
	,Total_Reads
	,AVG_Reads
	,Total_Writes
	,AVG_Writes
	,Total_CPU_ms
	,AVG_CPU_ms
	,Total_RowCount
	,AVG_RowCount			
 FROM 
(
	SELECT 
		 RANK() OVER (PARTITION BY Statment, Derived2.[Database] ORDER BY Total_Duration_ms DESC,EventClass) AS [Rank]
		,[Database]
		,EventClass
		,Statment
		,Executions
		,Total_Duration_ms
		,AVG_Duration_ms
		,Total_Reads
		,AVG_Reads
		,Total_Writes
		,AVG_Writes
		,Total_CPU_ms
		,AVG_CPU_ms
		,Total_RowCount
		,AVG_RowCount					
			FROM 
			(
				SELECT TOP (@Rows)
					 [Database]
					,CASE WHEN EventClass = 10 THEN 'RPC' WHEN EventClass = 12 THEN 'BATCH' WHEN EventClass = 43 THEN 'SP' END AS EventClass 
					,CASE WHEN BaseLineFull.TextData IS NULL THEN [Object] ELSE dbo.sqlsig(BaseLineFull.TextData) END AS Statment
					,COUNT(*)					AS Executions
					,SUM(Duration) /1000 AS Total_Duration_ms
					,CAST ((SUM(Duration) /1000) / CAST(COUNT(*) AS decimal) AS decimal(10,3)) AS AVG_Duration_ms						
					,SUM(ISNULL(Reads, 0))								AS Total_Reads
					,SUM(ISNULL(Reads, 0)) / COUNT(*)			AS AVG_Reads
					,SUM(ISNULL(Writes, 0))								AS Total_Writes
					,SUM(ISNULL(Writes, 0))	/ COUNT(*)		AS AVG_Writes
					,SUM(ISNULL(CPU, 0)) 						AS Total_CPU_ms								
					,CAST((SUM(ISNULL(CPU, 0)) ) / CAST(COUNT(*)	AS decimal)	AS decimal(10,3))		AS AVG_CPU_ms										
					,SUM(ISNULL(RowCounts, 0)) 						AS Total_RowCount
					,SUM(ISNULL(RowCounts, 0)) / COUNT(*)	AS AVG_RowCount
			FROM dbo.BaseLineFull 
			GROUP BY 
				 CASE WHEN EventClass = 10 THEN 'RPC' WHEN EventClass = 12 THEN 'BATCH' WHEN EventClass = 43 THEN 'SP' END
				,[Database]
				,CASE WHEN BaseLineFull.TextData IS NULL THEN [Object] ELSE dbo.sqlsig(BaseLineFull.TextData) END
			ORDER BY Total_Duration_ms DESC
		)Derived2
)Derived1
WHERE [Rank] = 1
ORDER BY Total_Duration_ms DESC ;
GO


USE DBA;
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceExecutionsStart]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[TraceExecutionsStart] ;
GO
/*
EXEC dbo.TraceExecutionsDelete @command = 'del C:\Traces\Baseline*.trc'
EXEC DBA.dbo.TraceExecutionsStart @Minutes = 30, @Path = N'C:\Traces\BaseLine' 
EXEC DBA.dbo.TraceExecutionsLoad @path = N'C:\Traces\', @file =  N'BaseLine*.trc';
EXEC DBA.dbo.TraceExecutionsManipulateData @Rows = 200
*/
CREATE PROCEDURE [dbo].[TraceExecutionsStart]
(
	 @Database sysname = NULL
	,@MaxFileSize bigint = 200
	,@FileCount	int		= 3000  
	,@Minutes int = 60
	,@Path sysname
)
AS
SET NOCOUNT ON; 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


-- EXEC DBA.dbo.TraceExecutionsStart @MaxFileSize = 100, @FileCount = 30, @Minutes = 60, @Path = N'N:\Traces\BaseLine', @Database = NULL; 


DECLARE @RC int, @TraceID int, @EventClass int, @On bit, @StopTime datetime;
SELECT @On = 1, @StopTime = DATEADD(minute, @Minutes, CURRENT_TIMESTAMP ); 


--DECLARE @MaxFileSize bigint, @Database sysname, @Minutes int, @Path sysname ;
--SELECT @Minutes = 5 ; --<--- Number of minutes to run the trace before it is stopped.
--SELECT @Path = N'B:\Traces\BaseLine'


EXEC @RC = sp_trace_create 
				 @TraceID OUTPUT
				,@options				= 2	-- file rollover
				,@tracefile			= @Path 
				,@maxfilesize		= @MaxFileSize  -- MB
				,@stoptime			= @StopTime
				,@filecount			= @FileCount;			
IF (@RC <> 0) OR (@@ERROR <> 0) BEGIN; SELECT @RC; RETURN; END ;


-- SP:Completed.  Indicates when the stored procedure has completed. 
SELECT @EventClass = 43 ;
EXEC sp_trace_setevent @TraceID, @EventClass, 34, @On	-- ObjectName 
EXEC sp_trace_setevent @TraceID, @EventClass, 10, @On	-- ApplicationName
EXEC sp_trace_setevent @TraceID, @EventClass, 35, @On	-- DatabaseName
EXEC sp_trace_setevent @TraceID, @EventClass,  8, @On	-- HostName
EXEC sp_trace_setevent @TraceID, @EventClass, 16, @On	-- Reads
EXEC sp_trace_setevent @TraceID, @EventClass, 17, @On	-- Writes
EXEC sp_trace_setevent @TraceID, @EventClass, 18, @On	-- CPU
EXEC sp_trace_setevent @TraceID, @EventClass, 13, @On	-- Duration
EXEC sp_trace_setevent @TraceID, @EventClass, 48, @On	-- RowCounts 
EXEC sp_trace_setevent @TraceID, @EventClass, 12, @On	-- SPID
EXEC sp_trace_setevent @TraceID, @EventClass, 14, @On	-- StartTime 
EXEC sp_trace_setevent @TraceID, @EventClass, 11, @On	-- LoginName 


-- RPC:Completed. Occurs when a remote procedure call (RPC) has completed.
SELECT @EventClass = 10 ;
EXEC sp_trace_setevent @TraceID, @EventClass, 34, @On	-- ObjectName 
EXEC sp_trace_setevent @TraceID, @EventClass, 10, @On	-- ApplicationName
EXEC sp_trace_setevent @TraceID, @EventClass, 35, @On	-- DatabaseName
EXEC sp_trace_setevent @TraceID, @EventClass,  8, @On	-- HostName
EXEC sp_trace_setevent @TraceID, @EventClass, 16, @On	-- Reads
EXEC sp_trace_setevent @TraceID, @EventClass, 17, @On	-- Writes
EXEC sp_trace_setevent @TraceID, @EventClass, 18, @On	-- CPU
EXEC sp_trace_setevent @TraceID, @EventClass, 13, @On	-- Duration
EXEC sp_trace_setevent @TraceID, @EventClass, 48, @On	-- RowCounts 
EXEC sp_trace_setevent @TraceID, @EventClass, 12, @On	-- SPID
EXEC sp_trace_setevent @TraceID, @EventClass, 14, @On	-- StartTime 
EXEC sp_trace_setevent @TraceID, @EventClass, 11, @On	-- LoginName 


-- SQL:BatchCompleted. Occurs when a Transact-SQL batch has completed.
SELECT @EventClass = 12 ;
EXEC sp_trace_setevent @TraceID, @EventClass,  1, @On	-- TextData
EXEC sp_trace_setevent @TraceID, @EventClass, 34, @On	-- ObjectName 
EXEC sp_trace_setevent @TraceID, @EventClass, 10, @On	-- ApplicationName
EXEC sp_trace_setevent @TraceID, @EventClass, 35, @On	-- DatabaseName
EXEC sp_trace_setevent @TraceID, @EventClass,  8, @On	-- HostName
EXEC sp_trace_setevent @TraceID, @EventClass, 16, @On	-- Reads
EXEC sp_trace_setevent @TraceID, @EventClass, 17, @On	-- Writes
EXEC sp_trace_setevent @TraceID, @EventClass, 18, @On	-- CPU
EXEC sp_trace_setevent @TraceID, @EventClass, 13, @On	-- Duration
EXEC sp_trace_setevent @TraceID, @EventClass, 48, @On	-- RowCounts 
EXEC sp_trace_setevent @TraceID, @EventClass, 12, @On	-- SPID
EXEC sp_trace_setevent @TraceID, @EventClass, 14, @On	-- StartTime 
EXEC sp_trace_setevent @TraceID, @EventClass, 11, @On	-- LoginName 



/*		
sp_trace_setfilter @TraceID, @columnid, @logical_operator, @comparison_operator, @value 

@logical_operator: AND (0) or OR (1) 

@comparison_operator:
0 = Equal, 1 = Not equal, 2 = Greater than, 3 = Less than, 4 = Greater than or equal, 
5 = Less than or equal, , 6 = Like, 7 = Not like 
*/


-- Exclude TextData
--EXEC sp_trace_setfilter @TraceID, 1, 0, 7, N'EXEC sp_reset_connection';


-- Include specific Database
IF @Database IS NOT NULL
BEGIN;
	EXEC sp_trace_setfilter @TraceID, 35, 0, 0, @Database;
END;


SELECT TraceID = @TraceID;

-- Start trace
EXEC sp_trace_setstatus @TraceID, 1;
GO

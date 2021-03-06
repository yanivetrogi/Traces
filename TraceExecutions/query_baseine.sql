USE DBA; SET NOCOUNT ON;
/*
EXEC dbo.TraceExecutionsDelete @command = 'del c:\Traces\Baseline*.trc'
EXEC DBA.dbo.TraceExecutionsStart @Database = NULL, @MaxFileSize = 100, @FileCount = 50, @Minutes = 10, @Path = N'c:\Traces\BaseLine' ;
EXEC DBA.dbo.TraceExecutionsLoad @path = N'c:\Traces\', @file =  N'BaseLine*.trc';
EXEC DBA.dbo.TraceExecutionsManipulateData @Rows = 500

EXEC  sp_trace_setstatus 3, 1 --start
EXEC  sp_trace_setstatus 2, 0 --stop
EXEC  sp_trace_setstatus 2, 2 --remove

SELECT * FROM sys.traces 

xp_fixeddrives

EXEC sys.xp_cmdshell 'md c:\Traces\Baseline'
*/

-- Get Totals
DECLARE @BatchId int = (SELECT MAX(BatchId) FROM dbo.BaseLine);
SELECT MIN(StartTime)StartTime, MAX(EndTime)EndTime, DATEDIFF(minute, MIN(StartTime), MAX(EndTime)) [Minutes], SUM(Total_Duration_ms) Duration_ms, SUM(Total_Reads) Reads, SUM(Total_Writes) Writes, SUM(Total_CPU_ms) CPU, SUM(Total_RowCount) [RowCount] 
FROM BaseLine WHERE BatchId = @BatchId;
--SELECT @BatchId;

--SELECT DISTINCT StartTime from BaseLine ORDER BY 1
--SELECT DISTINCT EventClass from BaseLine
--SELECT SUM(p.rows) FROM sys.partitions AS p WHERE p.object_id = OBJECT_ID('BaseLineFull') AND p.index_id IN (0,1);

SELECT 
-- InsertTime
--,BatchId
--,StartTime
--,EndTime
 [Database]
,EventClass
,dbo.uf_trimextraspaces(LEFT(Statment, 300) )Statment
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
FROM dbo.BaseLine WHERE BatchId = @BatchId
AND EventClass IN ('RPC', 'BATCH', 'SP')
--AND Statment LIKE '%%'
--AND [Database] LIKE '%%'
--AND ApplicationName NOT LIKE 'Microsoft SQL Server Management%'
--AND StartTime BETWEEN '20160430 23:30' AND '20160501 02:00'
ORDER BY Executions DESC ;

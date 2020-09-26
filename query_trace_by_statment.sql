USE DBA
SET NOCOUNT ON; SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

DECLARE @path sysname = (SELECT path FROM sys.traces WHERE path LIKE '%BOOTS_CompositeAppointmentTypeFindFirstVacancy%');
--SELECT * FROM sys.traces

SELECT 
	 COUNT(*)cnt
	,AVG(CPU) cpu_avg
	,MAX(CPU) cpu_max
	,SUM(CPU)/1000 cpu_total_ss
	,AVG(Reads)Reads_avg
	,MAX(Reads)Reads_max
	,AVG(Writes) Writes_avg
	,MAX(Writes) Writes_max
	,AVG(Duration)/1000 Duration_ms_avg
	,MAX(Duration)/1000 Duration_ms_max
	,AVG(RowCounts)RowCounts_avg
	,MAX(RowCounts)RowCounts_max
	,DATEADD(mi,DATEPART(mi,StartTime), DATEADD(dd,0,DATEDIFF(dd,0,StartTime))) [minutes]
	--,ObjectName
FROM ::fn_trace_gettable(@path, 1) WHERE EventClass = 10
AND StartTime > DATEADD(MINUTE, -10, CURRENT_TIMESTAMP) --<----- Last xx minutes
GROUP BY DATEADD(mi,DATEPART(mi,StartTime), DATEADD(dd,0,DATEDIFF(dd,0,StartTime)))--,ObjectName
ORDER BY DATEADD(mi,DATEPART(mi,StartTime), DATEADD(dd,0,DATEDIFF(dd,0,StartTime)));

RETURN

SELECT TOP 10
	EventClass
	,CPU
	,Reads
	,Writes
	,Duration/1000 Duration_ms
	,RowCounts
	,SPID
	,StartTime
	,ObjectName
	,TextData
FROM ::fn_trace_gettable(@path, 1) WHERE EventClass = 10
AND StartTime > DATEADD(MINUTE, -5, CURRENT_TIMESTAMP)
ORDER BY Duration DESC

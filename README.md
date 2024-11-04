The TraceExecutions process captures all (entire) activity on an instance of sql server as defined by the @Minutes paramter.
At the final result the process aggrgates the data and displays a single line per execution.
You can then sort the data by number of exeutions, reads, duration etc. to match your need.


Here is a sample bit of code showing how to use the process.

﻿USE DBA; SET NOCOUNT ON;
-- Delete old traces
EXEC dbo.TraceExecutionsDelete @command = 'del C:\Traces\Baseline*.trc';


-- Start the trace
-- Create files sizes 100mb, limmited to 50 files (in FIFO), for a 10 minutes duration, the destination folder for the traces is: C:\Traces.
EXEC DBA.dbo.TraceExecutionsStart @Database = NULL, @MaxFileSize = 100, @FileCount = 50, @Minutes = 10, @Path = N'C:\Traces\BaseLine';


-- Load the raw trace files into a table (BaseLineFull).
EXEC DBA.dbo.TraceExecutionsLoad @path = N'C:\Traces\', @file =  N'BaseLine*.trc';


-- Manipulate the data in the table 
-- Insert data to table BaseLine
EXEC DBA.dbo.TraceExecutionsManipulateData @Rows = 500;


/*
EXEC  sp_trace_setstatus 3, 1 --start
EXEC  sp_trace_setstatus 2, 0 --stop
EXEC  sp_trace_setstatus 2, 2 --remove

SELECT * FROM sys.traces 

xp_fixeddrives

EXEC sys.xp_cmdshell 'md c:\Traces\Baseline'
*/

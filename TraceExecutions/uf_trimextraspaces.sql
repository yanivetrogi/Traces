USE DBA;
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_trimextraspaces]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].uf_trimextraspaces;
GO
CREATE FUNCTION dbo.uf_trimextraspaces 
(
	@instr varchar(MAX) 
)
RETURNS varchar(MAX)
AS
BEGIN;

    DECLARE @workingstr varchar(MAX);
    SELECT  @workingstr = @instr;

    WHILE CHARINDEX('  ', @workingstr) > 0
        BEGIN;
            SELECT @workingstr = REPLACE(@workingstr, '  ', ' ');
        END;

    RETURN @workingstr;
END;
GO



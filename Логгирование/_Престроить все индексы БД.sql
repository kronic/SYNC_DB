USE [Copy_DV]
GO
DECLARE		reindex_cursor		cursor local fast_forward
FOR 
SELECT		TABLE_NAME
FROM		INFORMATION_SCHEMA.TABLES
WHERE		TABLE_TYPE		=	'BASE TABLE'
AND			TABLE_SCHEMA	=	N'dbo'

DECLARE		@tablename			sysname
OPEN		reindex_cursor

FETCH NEXT 
FROM		reindex_cursor 
INTO		@tablename 

WHILE		@@fetch_status	=	0 
BEGIN
	exec('dbcc dbreindex ([' + @tablename + '], '''') with no_infomsgs')
    FETCH NEXT 
	FROM	reindex_cursor 
	INTO	@tablename
END

CLOSE		reindex_cursor
DEALLOCATE	reindex_cursor
/****** Script for SelectTopNRows command from SSMS  ******/
-- Initial table created via SSMS Imort tool


CREATE TABLE #DEST_TABLE (ID_NUM INT, BAG_RULE_CD NVARCHAR(20), CONTAIN_TXT NVARCHAR(20), CONTAIN_QTY INT)
GO

SELECT * INTO #TEMP FROM ADVENT_DEC_07_RULES
GO


DECLARE @ID INT;
DECLARE @rule_txt varchar(255);
DECLARE @bag_rule varchar(20);
DECLARE @contains varchar(20);
DECLARE @remain_contains nvarchar(255)
DECLARE @next_break int;
DECLARE @rule_len int;
DECLARE @bag_qty int;
DECLARE @no_bag int;


SET @ID = 0;
SET @bag_qty = 0;

WHILE EXISTS (SELECT * FROM #TEMP)
	BEGIN
		SELECT TOP 1 @next_break = CHARINDEX(' bags c',RULE_TXT)
					, @bag_rule = LEFT(RULE_TXT,@next_break -1)
					, @rule_txt= RULE_TXT
					, @rule_len = len(RULE_TXT)
					, @remain_contains = SUBSTRING(RULE_TXT, @next_break + 14, 999)
					, @no_bag = CASE WHEN CHARINDEX('no other bags', RULE_TXT) <> 0 THEN 1 ELSE 0 END
		FROM #TEMP;

		SET @ID = @ID + 1
		
		IF @no_bag = 1
			begin
				INSERT INTO #DEST_TABLE (ID_NUM, BAG_RULE_CD, CONTAIN_TXT, CONTAIN_QTY)
				VALUES (@ID, @bag_rule, 'No Bag', 0)

			end
		ELSE IF @no_bag = 0
			BEGIN
				SET @next_break = CHARINDEX(' ', @remain_contains)
				SET @bag_qty = SUBSTRING(@remain_contains,1, @next_break - 1)
				SET @remain_contains = SUBSTRING(@remain_contains, @next_break + 1,999)
				SET @next_break = CHARINDEX(' bag', @remain_contains)
				SET @contains = SUBSTRING(@remain_contains, 0, @next_break)
				SET @remain_contains = SUBSTRING(@remain_contains, @next_break + 1,999)
				INSERT INTO #DEST_TABLE (ID_NUM, BAG_RULE_CD, CONTAIN_TXT, CONTAIN_QTY)
				VALUES (@ID, @bag_rule, @contains, @bag_qty)
				SET @no_bag = CASE WHEN CHARINDEX(',', @remain_contains) <> 0 THEN 1 ELSE 0 END
				
				WHILE @no_bag >0
					BEGIN
						SET @next_break = CHARINDEX(', ', @remain_contains)
						SET @remain_contains = SUBSTRING(@remain_contains, @next_break + 2,999)
						SET @next_break = CHARINDEX(' ', @remain_contains)
						SET @bag_qty = SUBSTRING(@remain_contains,1, @next_break - 1)
						SET @remain_contains = SUBSTRING(@remain_contains, @next_break + 1,999)
						SET @next_break = CHARINDEX(' bag', @remain_contains)
						SET @contains = SUBSTRING(@remain_contains, 1,  @next_break)
						INSERT INTO #DEST_TABLE (ID_NUM, BAG_RULE_CD, CONTAIN_TXT, CONTAIN_QTY)
						VALUES (@ID, @bag_rule, @contains, @bag_qty)
						SET @no_bag = CASE WHEN CHARINDEX(',', @remain_contains) <> 0 THEN 1 ELSE 0 END	
					END

		END
						DELETE FROM #TEMP WHERE RULE_TXT = @rule_txt
	END

/**Final Table **/

CREATE TABLE #FINAL_TABLE (ID INT, BAG_RULE_CD NVARCHAR(20), CONTAIN_TXT NVARCHAR(20), CONTAIN_QTY INT)
GO

DECLARE @count int;

SET @count = 1;

INSERT INTO #FINAL_TABLE  
		SELECT	@COUNT, BAG_RULE_CD, CONTAIN_TXT, CONTAIN_QTY
		FROM	#DEST_TABLE 
		WHERE	CONTAIN_TXT = 'shiny gold' 
		
SET @count = @count + 1

INSERT INTO #FINAL_TABLE 
		SELECT	@COUNT, DEST.BAG_RULE_CD, DEST.CONTAIN_TXT, DEST.CONTAIN_QTY
		FROM	#FINAL_TABLE FINAL
				JOIN #DEST_TABLE DEST ON DEST.CONTAIN_TXT = FINAL.BAG_RULE_CD
		WHERE FINAL.ID = @count - 1

		SET @count = @count + 1

WHILE EXISTS (	SELECT * 
				FROM	#FINAL_TABLE FINAL
				JOIN #DEST_TABLE DEST ON DEST.CONTAIN_TXT = FINAL.BAG_RULE_CD
				WHERE FINAL.ID = @count - 1)

				BEGIN

					INSERT INTO #FINAL_TABLE 
					SELECT	@COUNT, DEST. BAG_RULE_CD, DEST.CONTAIN_TXT, DEST.CONTAIN_QTY
					FROM	#FINAL_TABLE FINAL
							JOIN #DEST_TABLE DEST ON DEST.CONTAIN_TXT = FINAL.BAG_RULE_CD
					WHERE FINAL.ID = @count - 1
					
					SET @count = @count + 1
				END

SELECT COUNT(DISTINCT FINAL.BAG_RULE_CD) FROM #FINAL_TABLE FINAL

go

/** Part II **/

CREATE TABLE #FINAL_TABLE2 (ID INT, BAG_RULE_CD NVARCHAR(20), CONTAIN_TXT NVARCHAR(20), CONTAIN_QTY INT, BAG_QTY INT)
GO

DECLARE @count int;

SET @count = 1;

INSERT INTO #FINAL_TABLE2
SELECT @COUNT, DEST.BAG_RULE_CD, DEST.CONTAIN_TXT, DEST.CONTAIN_QTY, DEST.CONTAIN_QTY FROM #DEST_TABLE DEST
WHERE BAG_RULE_CD = 'shiny gold'


SET @count = @COUNT + 1;

WHILE EXISTS (SELECT @COUNT, DEST.BAG_RULE_CD, DEST.CONTAIN_TXT, DEST.CONTAIN_QTY, FINAL.BAG_QTY * DEST.CONTAIN_QTY AS BAG_QTY2 FROM #DEST_TABLE DEST
JOIN #FINAL_TABLE2 FINAL on DEST.BAG_RULE_CD = FINAL.CONTAIN_TXT
WHERE FINAL.ID = @count - 1 AND DEST.CONTAIN_QTY > 0)
	BEGIN
		INSERT INTO #FINAL_TABLE2
		SELECT @COUNT, DEST.BAG_RULE_CD, DEST.CONTAIN_TXT, DEST.CONTAIN_QTY, FINAL.BAG_QTY * DEST.CONTAIN_QTY AS BAG_QTY2 FROM #DEST_TABLE DEST
		JOIN #FINAL_TABLE2 FINAL on DEST.BAG_RULE_CD = FINAL.CONTAIN_TXT
		WHERE FINAL.ID = @count - 1 AND DEST.CONTAIN_QTY > 0
		
		SET @count = @COUNT + 1;
	END




SELECT SUM(BAG_QTY) FROM #FINAL_TABLE2

GO

--Clean-up
DROP TABLE #DEST_TABLE
DROP TABLE #TEMP
DROP TABLE #FINAL_TABLE
DROP TABLE #FINAL_TABLE2
	
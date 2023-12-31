USE [SSS]
GO
/****** Object:  StoredProcedure [dbo].[cari_sp_mengandung]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[cari_sp_mengandung] (@keyword varchar(30))    
as    
begin    
select distinct o.name     
from sysobjects o, syscomments c    
where o.id=c.id    
and c.text like '%'+@keyword+'%'    
order by o.name
end 

GO
/****** Object:  StoredProcedure [dbo].[DELETE_SCHEME_APPROVAL_REIMBURSE]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[DELETE_SCHEME_APPROVAL_REIMBURSE] 
	@ID		BIGINT
AS
BEGIN
	DELETE SCHEME_APPROVAL_REIMBURSE_TRX WHERE ID = @ID
END

GO
/****** Object:  StoredProcedure [dbo].[GETAPPROVAL_LIST_REIMBURSE]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GETAPPROVAL_LIST_REIMBURSE]
	@EMPLOYEE_CODE	VARCHAR(50) --='1812012'
AS
BEGIN
	select A.ID, A.REFF_NO, A.APPLY_DATE, A.TOTAL, A.EMPLOYEE_CODE, PAY_TO_DESC, C.PLATFON, A.POSITION, A.AREA, A.BRANCH from REIMBURSE_OPERATION_HD A LEFT JOIN (
		SELECT A.HD_REFFNO, A.SEQ, A.EMPLOYEE_CODE, A.EMPLOYEE_NAME FROM SCHEME_APPROVAL_REIMBURSE_TRX A WHERE A.IS_DECISION ='F' AND A.SEQ = (
			SELECT TOP 1 SEQ FROM SCHEME_APPROVAL_REIMBURSE_TRX WHERE IS_DECISION ='F' AND HD_REFFNO = A.HD_REFFNO ORDER BY SEQ ASC
		)
	)B ON A.REFF_NO = B.HD_REFFNO
	LEFT JOIN MASTER_PLATFON_REIMBURSE C ON A.PAY_TO = C.PLATFON_REIMBURSE_ID
	where A.STATUS='NEED APPROVAL' AND B.EMPLOYEE_CODE = @EMPLOYEE_CODE AND C.IS_ACTIVE = 1
END

GO
/****** Object:  StoredProcedure [dbo].[GETDATA_PLATFONLIST]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GETDATA_PLATFONLIST]  
AS  
BEGIN  
 select   
  a.ID,  
  a.PLATFON_REIMBURSE_ID,   
  b.DESCS as EMPLOYEE_NAME,   
  c.DESCRIPTION as POSITION,   
  d.DESCRIPTION AS AREA,   
  e.DESCRIPTION AS BRANCH,   
  a.PLATFON,  
  CASE a.IS_ACTIVE WHEN 1 THEN 'AKTIF' ELSE 'TIDAK AKTIF' END AS IS_ACTIVE,   
  a.CRE_BY,   
  a.CRE_DT,   
  a.MOD_BY,   
  a.MOD_DT   
 from MASTER_PLATFON_REIMBURSE a   
 left join [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.dbo.SYS_TBLEMPLOYEE b on a.EMPLOYEE_CODE COLLATE Latin1_General_CI_AS = b.CODE   
 left join MASTER_POSITION c on a.POSITION_ID = c.ROLE   
 left join MASTER_AREA d on a.AREA_CODE = d.AREA_CODE   
 left join MASTER_BRANCH e on a.BRANCH_CODE = e.id  
END  
GO
/****** Object:  StoredProcedure [dbo].[GETDATA_REIMBURSEMENT]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GETDATA_REIMBURSEMENT]
	@REFFNO VARCHAR(50)
AS

SELECT A.[ID] ,A.[REFF_NO] ,A.[APPLY_DATE] ,A.[TOTAL] ,A.[PAY_TO] ,A.[PAY_TO_DESC] ,A.[EMPLOYEE_CODE] ,A.[POSITION] ,A.[AREA] ,A.[BRANCH] ,
A.[ACCOUNT_NO] ,A.[ACCOUNT_NAME] ,A.[BANK] ,A.[STATUS] ,A.[CRE_BY] ,A.[CRE_DT] , B.BRANCH_CODE_SMILE
FROM [dbo].[REIMBURSE_OPERATION_HD] A left join MASTER_BRANCH B on A.BRANCH = B.DESCRIPTION where A.REFF_NO=@REFFNO

SELECT A.[ID] ,A.[HD_REFFNO] ,A.[NOTA_DATE] ,A.[DETAIL_TYPE] ,A.[AMOUNT] ,A.[NOTE] ,A.[CRE_BY] ,A.[CRE_DT] ,A.[MOD_BY] ,A.[MOD_DT] 
FROM [dbo].[REIMBURSE_OPERATION_DT] A where A.HD_REFFNO=@REFFNO ORDER BY A.ID ASC
GO
/****** Object:  StoredProcedure [dbo].[GETDATA_REPORT_REIMBURSE]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GETDATA_REPORT_REIMBURSE]
--DECLARE
	@STARTDT	DATETIME,
	@ENDDT		DATETIME,
	@EMPCD		VARCHAR(50),
	@STATUS		VARCHAR(50)
AS
DECLARE @SQL VARCHAR(MAX)

SET @SQL = 'SELECT A.REFF_NO, A.PAY_TO_DESC, CONVERT(VARCHAR, A.APPLY_DATE, 106) as APPLY_DATE, A.EMPLOYEE_CODE, A.POSITION, A.AREA, A.BRANCH,
	CASE B.DETAIL_TYPE
		WHEN 1 THEN ''BENSIN''
		WHEN 2 THEN ''TOL''
		WHEN 3 THEN ''PARKIR''
		WHEN 4 THEN ''LAINNYA'' END DETAIL_TYPE, CONVERT(VARCHAR, B.NOTA_DATE,111) AS NOTA_DATE, B.AMOUNT, A.STATUS
	from [dbo].[REIMBURSE_OPERATION_HD] A LEFT JOIN [REIMBURSE_OPERATION_DT] B ON A.REFF_NO = B.HD_REFFNO 
	'
IF(@EMPCD = 'ALL' AND @STATUS = 'ALL')
BEGIN
	SET @SQL = @SQL + ' WHERE CAST(a.APPLY_DATE AS DATE) BETWEEN ''' + CONVERT(VARCHAR, @STARTDT, 23) + ''' AND ''' + CONVERT(VARCHAR, @ENDDT, 23) + '''' 
END ELSE IF (@EMPCD = 'ALL' AND @STATUS <> 'ALL')
BEGIN 	
	SET @SQL = @SQL + ' WHERE CAST(a.APPLY_DATE AS DATE) BETWEEN ''' + CONVERT(VARCHAR, @STARTDT, 23) + ''' AND ''' + CONVERT(VARCHAR, @ENDDT, 23) + ''' AND A.STATUS = ''' + @STATUS + ''''
END ELSE IF (@EMPCD <> 'ALL' AND @STATUS = 'ALL')
BEGIN
	SET @SQL = @SQL + ' WHERE CAST(a.APPLY_DATE AS DATE) BETWEEN ''' + CONVERT(VARCHAR, @STARTDT, 23) + ''' AND ''' + CONVERT(VARCHAR, @ENDDT, 23) + ''' AND A.EMPLOYEE_CODE = ''' + @EMPCD + ''''
END ELSE BEGIN
	SET @SQL = @SQL + ' WHERE CAST(a.APPLY_DATE AS DATE) BETWEEN ''' + CONVERT(VARCHAR, @STARTDT, 23) + ''' AND ''' + CONVERT(VARCHAR, @ENDDT, 23) + ''' AND A.STATUS = ''' + @STATUS + ''' AND A.EMPLOYEE_CODE = ''' + @EMPCD + ''''
END

--PRINT(@SQL)
EXEC(@SQL)
GO
/****** Object:  StoredProcedure [dbo].[GETDATAAREA]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GETDATAAREA]
	@ID		BIGINT
AS
BEGIN
	select isnull(MAX(AREA_CODE), 1000) + 1 AS MAXID from MASTER_AREA
	
	SELECT AREA_CODE ,DESCRIPTION , IS_ACTIVE FROM MASTER_AREA WHERE AREA_CODE=@ID
END

GO
/****** Object:  StoredProcedure [dbo].[GETDATAPOSITION]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[GETDATAPOSITION]
	@ID		BIGINT
AS
BEGIN
	select isnull(MAX(ROLE), 1000) + 1 AS MAXID from MASTER_POSITION
	
	SELECT ROLE ,DESCRIPTION , IS_ACTIVE FROM MASTER_POSITION WHERE ROLE=@ID
END

GO
/****** Object:  StoredProcedure [dbo].[GetDocumentKontrakWithPurposeCode]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GetDocumentKontrakWithPurposeCode] --'IF', 'APP/1019/0005','Mandatory'
--declare 
	@purpose_kode		varchar(50),-- ='IF',
	@App_No				varchar(50),-- ='APP/1019/0006',
	@Document_Type		varchar(50)-- ='Mandatory' -- Mandatory -- Tambahan
as
declare		@Client_Id		varchar(50),
			@ClientType		varchar(50),
			@FacilityType	varchar(50)
			--@branch			varchar(100),
			--@BranchType		varchar(50)
			
	select @Client_Id = CIF/*, @branch=@branch */ , @FacilityType = REPLACE(Facility,'Kredit ','') from [Application] where DocNo = @App_No
	--select * from [Application] where DocNo = @App_No
	select @ClientType =  
	CASE 
		WHEN [STATUS] = '1' THEN 'Perorangan' 
		WHEN [STATUS] = '2' AND SALUTE1 = 'PT' THEN 'PT'
		WHEN [STATUS] = '2' AND SALUTE1 = 'CV' THEN 'CV'
	END
	from [172.31.215.2\MSSQLSRVGUI].[IFINANCING_GOLIVE].[dbo].SYS_CLIENT where CLIENT = @Client_Id
	--select @Client_Id, @ClientType, @Document_Type
	--SELECT * FROM [dbo].[DocumentMandatory]
	select Id, Nomor_urut as DocKey, Nama_Dokumen as [Description] from [dbo].[Master_Document_Kontrak]
	where Jenis_Dokumen = @Document_Type and Jenis_Client = @ClientType and Jenis_Pembiayaan= @FacilityType and Purpose_Kode = @purpose_kode order by Nomor_urut ASC 
	
	--select * from [dbo].[Master_Document_Kontrak]
	--where Jenis_Dokumen = @Document_Type and Jenis_Client = @ClientType and Jenis_Pembiayaan= @FacilityType and Purpose_Kode = @purpose_kode order by Nomor_urut ASC 
	--select * from [dbo].[Master_Document_Kontrak]
	--where Jenis_Dokumen = @Document_Type and Jenis_Client = @ClientType and Purpose_Kode = @purpose_kode order by Nomor_urut ASC
	--select * from [dbo].[Master_Document_Kontrak] --where Jenis_Dokumen = 'Tambahan'
	--truncate table Master_Document_Kontrak
	
GO
/****** Object:  StoredProcedure [dbo].[GetDocumentKontrakWithPurposeCode_List]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetDocumentKontrakWithPurposeCode_List] -- 'IF', 'APP/0920/0676'
--declare 
	@purpose_kode		varchar(50),-- ='IF',
	@App_No				varchar(50)-- ='APP/1019/0006'
as
declare		@Client_Id		varchar(50),
			@ClientType		varchar(50),
			@FacilityType	varchar(50),
			@Document		varchar(max)
			--@branch			varchar(100),
			--@BranchType		varchar(50)
			
	select @Client_Id = CIF/*, @branch=@branch */ , @FacilityType = REPLACE(Facility,'Kredit ','') from [Application] where DocNo = @App_No
	--select * from [Application] where DocNo = @App_No
	select @ClientType =  
	CASE 
		WHEN [STATUS] = '1' THEN 'Perorangan' 
		WHEN [STATUS] = '2' AND SALUTE1 = 'PT' THEN 'PT'
		WHEN [STATUS] = '2' AND SALUTE1 = 'CV' THEN 'CV'
	END
	from [172.31.215.2\MSSQLSRVGUI].[IFINANCING_GOLIVE].[dbo].SYS_CLIENT where CLIENT = @Client_Id
	--select @Client_Id, @ClientType, @Document_Type
	--SELECT * FROM [dbo].[DocumentMandatory]
	select Id, Nomor_urut as DocKey, Nama_Dokumen as [Description] into #DATA from [dbo].[Master_Document_Kontrak]
	where Jenis_Dokumen ='Mandatory' and Jenis_Client = @ClientType and Jenis_Pembiayaan= @FacilityType and Purpose_Kode = @purpose_kode order by Nomor_urut ASC 
	
	--select * from [dbo].[Master_Document_Kontrak]
	--where Jenis_Dokumen = @Document_Type and Jenis_Client = @ClientType and Jenis_Pembiayaan= @FacilityType and Purpose_Kode = @purpose_kode order by Nomor_urut ASC 
	--select * from [dbo].[Master_Document_Kontrak]
	--where Jenis_Dokumen = @Document_Type and Jenis_Client = @ClientType and Purpose_Kode = @purpose_kode order by Nomor_urut ASC
	--select * from [dbo].[Master_Document_Kontrak] --where Jenis_Dokumen = 'Tambahan'
	--truncate table Master_Document_Kontrak
	--select * from #DATA
	set @Document = (select ', ' + [Description] 
              FROM #DATA
              FOR XML PATH (''))

	select REPLACE(REPLACE(@Document,', ', Char(10)),'&amp;','&') as data
	drop table #DATA

GO
/****** Object:  StoredProcedure [dbo].[INSERT_HEADER_PERJALANAN_DINAS]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[INSERT_HEADER_PERJALANAN_DINAS] 
       @Name NVARCHAR (50) = NULL, 
       @NIK NVARCHAR (50) = NULL, 
       @Jabatan NVARCHAR (50) = NULL,
	   @Tujuan NVARCHAR (50) = NULL,
	   @PembebananBiaya NVARCHAR (50) = NULL,
	   @Dept NVARCHAR (50)=NULL,
	   @DocKey int,
	   @DocNo NVARCHAR (50) = NULL,
	   @CreBy NVARCHAR (50) = NULL,
	   @ModBy NVARCHAR (50) = NULL,
	   @FromTujuan NVARCHAR (50) = NULL
AS 
BEGIN 
     SET NOCOUNT ON 
	 SET IDENTITY_INSERT dbo.trxPerjalananDinas ON
     INSERT INTO dbo.trxPerjalananDinas
          ([Name],NIK,[Status],DocDate,CRE_DATE,Jabatan,Tujuan,PembebananBiaya,Dept,DocKey,DocNo,CRE_BY,MOD_BY,MOD_DATE,FromTujuan) 
     VALUES 
          (@Name,@NIK,'NEW',GETDATE(),GETDATE(),@Jabatan,@Tujuan,@PembebananBiaya,@Dept,@DocKey,@DocNo,@CreBy,@ModBy,GETDATE(),@FromTujuan)
	 SET IDENTITY_INSERT dbo.trxPerjalananDinas OFF
END 

GO
/****** Object:  StoredProcedure [dbo].[INSERT_UPDATE_APPROVE_REIMBURSE]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[INSERT_UPDATE_APPROVE_REIMBURSE]
@ROLE_CODE varchar(50),
@DESCRIPTION varchar(255),
@IS_ACTIVE int,
@USERID varchar(50),
@POSITION_ID BIGINT
as
BEGIN
	
	IF EXISTS (SELECT ROLE_CODE FROM APPROVE_REIMBURSE_HD WHERE ROLE_CODE = @ROLE_CODE)
	BEGIN 
		UPDATE [APPROVE_REIMBURSE_HD] 
			SET 
				[DESCRIPTION] = @DESCRIPTION,
				[IS_ACTIVE] = @IS_ACTIVE,
				[POSITION_ID] = @POSITION_ID,
				[MOD_BY] = @USERID,
				[MOD_DATE] = GETDATE()
		WHERE [ROLE_CODE] = @ROLE_CODE
	END ELSE BEGIN
		INSERT INTO [dbo].[APPROVE_REIMBURSE_HD]
           ([ROLE_CODE]
		   ,[DESCRIPTION]
		   ,[POSITION_ID]
           ,[IS_ACTIVE]
           ,[CRE_BY]
           ,[CRE_DT]
           )
		VALUES
           (@ROLE_CODE,
			@DESCRIPTION,
			@POSITION_ID,
            @IS_ACTIVE,
            @USERID,
            GETDATE()
           )
	END

END
GO
/****** Object:  StoredProcedure [dbo].[INSERT_UPDATE_APPROVE_REIMBURSE_DT]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[INSERT_UPDATE_APPROVE_REIMBURSE_DT]
@ROLE_DT_CODE varchar(50),
@ROLE_HD_CODE varchar(50),
@LEVEL int,
@POSITION_CODE bigint,
@IS_ACTIVE int,
@USERID varchar(50),
@ACT_DT datetime
as
BEGIN

	DECLARE @POSITION varchar(255)
	select @POSITION = DESCRIPTION from MASTER_POSITION where ROLE = @POSITION_CODE

	IF EXISTS (SELECT ROLE_DT_CODE FROM APPROVE_REIMBURSE_DT WHERE ROLE_DT_CODE = @ROLE_DT_CODE)
	BEGIN 
		UPDATE [APPROVE_REIMBURSE_DT] 
			SET [ROLE_HD_CODE] = @ROLE_HD_CODE,
				[LEVEL] = @LEVEL,
				[POSITION_CODE] = @POSITION_CODE,
				[POSITION] = @POSITION,
				[IS_ACTIVE] = @IS_ACTIVE,
				[MOD_BY] = @USERID,
				[MOD_DT] = @ACT_DT
		WHERE [ROLE_DT_CODE] = @ROLE_DT_CODE
	END ELSE BEGIN
		INSERT INTO [dbo].[APPROVE_REIMBURSE_DT]
           ([ROLE_DT_CODE]
           ,[ROLE_HD_CODE]
           ,[LEVEL]
           ,[POSITION_CODE]
           ,[POSITION]
           ,[IS_ACTIVE]
           ,[CRE_BY]
           ,[CRE_DT]
           )
		VALUES
           (@ROLE_DT_CODE,
            @ROLE_HD_CODE,
            @LEVEL,
            @POSITION_CODE,
            @POSITION,
            @IS_ACTIVE,
            @USERID,
            @ACT_DT
           )
	END

END

GO
/****** Object:  StoredProcedure [dbo].[INSERT_UPDATE_MASTER_BRANCH]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
        
CREATE PROC [dbo].[INSERT_UPDATE_MASTER_BRANCH]        
 @AREA_CODE  BIGINT        
 ,@ID  BIGINT    
 ,@BRANCH_CODE VARCHAR(12)        
 ,@DESCRIPTION VARCHAR(255)        
 ,@IS_ACTIVE  INT        
 ,@USERID  VARCHAR(50)        
 ,@ACTION_DATE DATETIME  
 ,@ACTION VARCHAR(10)  
AS        
BEGIN   
  
IF @ACTION = 'UPDATE'  
 BEGIN   
   
	 IF exists (SELECT BRANCH_CODE_SMILE FROM [dbo].[MASTER_BRANCH] WHERE AREA_CODE = @AREA_CODE AND BRANCH_CODE_SMILE = @BRANCH_CODE AND IS_ACTIVE = @IS_ACTIVE)    
	 BEGIN
		raiserror('Branch Code is Exists!', 16, -1) ;    
    
		return;
	 END

	INSERT INTO MASTER_BRANCH
	SELECT @AREA_CODE [AREA_CODE],@DESCRIPTION [DESCRIPTION],@IS_ACTIVE [IS_ACTIVE],[CRE_BY],[CRE_DT],@USERID [MOD_BY],@ACTION_DATE [MOD_DT],@BRANCH_CODE [BRANCH_CODE_SMILE] FROM MASTER_BRANCH WHERE [ID] = @ID

	DELETE MASTER_BRANCH WHERE [ID] = @ID

	 --UPDATE [MASTER_BRANCH] SET        
		--[AREA_CODE] = @AREA_CODE,        
		--[DESCRIPTION] = @DESCRIPTION,        
		--[IS_ACTIVE] = @IS_ACTIVE,        
		--[MOD_BY] = @USERID,        
		--[MOD_DT] = @ACTION_DATE,    
		--[BRANCH_CODE_SMILE] = @BRANCH_CODE
		--WHERE [ID] = @ID --AND BRANCH_CODE_SMILE = @BRANCH_CODE_SMILE AND AREA_CODE = @AREA_CODE 
      
 END   
 ELSE IF @ACTION = 'INSERT'  
 BEGIN     
     
 IF exists (SELECT BRANCH_CODE_SMILE FROM [dbo].[MASTER_BRANCH] WHERE  AREA_CODE = @AREA_CODE AND BRANCH_CODE_SMILE = @BRANCH_CODE)    
  BEGIN    
   raiserror('Branch Code is Exists!', 16, -1) ;    
    
   return ;    
  END    
      
  INSERT INTO [dbo].[MASTER_BRANCH]        
           ([AREA_CODE]        
           ,[DESCRIPTION]        
           ,[IS_ACTIVE]        
           ,[CRE_BY]        
           ,[CRE_DT]      
     ,[BRANCH_CODE_SMILE]      
           )        
   VALUES        
   (@AREA_CODE        
   ,@DESCRIPTION        
   ,@IS_ACTIVE        
   ,@USERID        
   ,@ACTION_DATE      
   ,@BRANCH_CODE
   )        
 END        
END 
GO
/****** Object:  StoredProcedure [dbo].[INSERT_UPDATE_MITRA_PENGURUS]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[INSERT_UPDATE_MITRA_PENGURUS]
--DECLARE
	@ID				BIGINT=NULL
	,@MKey			Bigint
	,@NAMA			VARCHAR(500)
	,@GENDER		CHAR(1)
	,@NIK			VARCHAR(20)
	,@NPWP			VARCHAR(20)
	,@BIRTH_DATE	DATETIME
	,@BIRTH_PLACE	VARCHAR(255)
	,@ADDRESS		VARCHAR(500)
	,@PROVINCE		VARCHAR(255)
	,@REGION		VARCHAR(255)
	,@DISTRICT		VARCHAR(255)
	,@VILLAGE		VARCHAR(255)
	,@JABATAN		VARCHAR(255)
	--,@PANGSA		NUMERIC(18,2)
	,@USERID		VARCHAR(255)
AS
BEGIN
	IF NOT EXISTS (SELECT ID FROM [dbo].[MITRA_PENGURUS] WHERE ID = @ID)
	BEGIN 
		INSERT INTO [dbo].[MITRA_PENGURUS]
			   (MKey ,NAMA ,GENDER ,NIK ,NPWP ,BIRTH_DATE ,BIRTH_PLACE ,ADDRESS ,PROVINCE ,REGION ,DISTRICT ,VILLAGE ,JABATAN ,/*PANGSA ,*/CRE_DT ,CRE_BY)
		 VALUES 
				(@MKey ,@NAMA ,@GENDER ,@NIK ,@NPWP ,@BIRTH_DATE ,@BIRTH_PLACE ,@ADDRESS ,@PROVINCE ,@REGION ,@DISTRICT ,@VILLAGE ,@JABATAN ,/*@PANGSA,*/ GETDATE() ,@USERID)
	END ELSE BEGIN
		UPDATE [dbo].[MITRA_PENGURUS]
		   SET [MKey] = @MKey
			  ,[NAMA] = @NAMA
			  ,[GENDER] = @GENDER
			  ,[NIK] = @NIK
			  ,[NPWP] = @NPWP
			  ,[BIRTH_DATE] = @BIRTH_DATE
			  ,[BIRTH_PLACE] = @BIRTH_PLACE
			  ,[ADDRESS] = @ADDRESS
			  ,[PROVINCE] = @PROVINCE
			  ,[REGION] = @REGION
			  ,[DISTRICT] = @DISTRICT
			  ,[VILLAGE] = @VILLAGE
			  ,[JABATAN] = @JABATAN
			  --,[PANGSA] = @PANGSA
			  ,[MOD_DATE] = GETDATE()
			  ,[MOD_BY] = @USERID
		 WHERE ID = @ID 
	END
END


GO
/****** Object:  StoredProcedure [dbo].[INSERT_UPDATE_REIMBURSE_OPERATION_HD]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[INSERT_UPDATE_REIMBURSE_OPERATION_HD]
@REFF_NO varchar(50)
,@APPLY_DATE datetime
,@TOTAL numeric(18,2)=null
,@PAY_TO varchar(50)
,@PAY_TO_DESC varchar(255)
,@EMPLOYEE_CODE varchar(50)
,@POSITION varchar(255)
,@AREA varchar(255)
,@BRANCH varchar(255)
,@ACCOUNT_NO varchar(50)
,@ACCOUNT_NAME varchar(255)
,@BANK varchar(100)
,@STATUS varchar(50)
,@USERID varchar(50)
,@ACT_DT datetime

as

BEGIN
	IF EXISTS (SELECT [REFF_NO] FROM [REIMBURSE_OPERATION_HD] WHERE [REFF_NO] = @REFF_NO)
	BEGIN
		UPDATE [REIMBURSE_OPERATION_HD]
		SET		[APPLY_DATE] = @APPLY_DATE
				,[TOTAL] = @TOTAL
				,[PAY_TO] = @PAY_TO
				,[PAY_TO_DESC] = @PAY_TO_DESC
				,[EMPLOYEE_CODE] = @EMPLOYEE_CODE
				,[POSITION] = @POSITION
				,[AREA] = @AREA
				,[BRANCH] = @BRANCH
				,[ACCOUNT_NO] = @ACCOUNT_NO
				,[ACCOUNT_NAME] = @ACCOUNT_NAME
				,[BANK] = @BANK
				,[STATUS] = @STATUS
				,[MOD_BY] = @USERID
				,[MOD_DT] = @ACT_DT
		WHERE [REFF_NO] = @REFF_NO
	END ELSE 
	BEGIN
		INSERT INTO [dbo].[REIMBURSE_OPERATION_HD]
           ([REFF_NO]
           ,[APPLY_DATE]
           ,[TOTAL]
           ,[PAY_TO]
           ,[PAY_TO_DESC]
           ,[EMPLOYEE_CODE]
           ,[POSITION]
           ,[AREA]
           ,[BRANCH]
           ,[ACCOUNT_NO]
           ,[ACCOUNT_NAME]
           ,[BANK]
           ,[STATUS]
           ,[CRE_BY]
           ,[CRE_DT]
		   )
		VALUES
           (@REFF_NO
			,@APPLY_DATE
			,@TOTAL
			,@PAY_TO
			,@PAY_TO_DESC
			,@EMPLOYEE_CODE
			,@POSITION
			,@AREA
			,@BRANCH
			,@ACCOUNT_NO
			,@ACCOUNT_NAME
			,@BANK
			,@STATUS
			,@USERID
			,@ACT_DT
           )

		   declare	@POSITION_ID bigint, 
					@AREA_CODE bigint, 
					@BRANCH_CODE bigint, 
					@APPROVE_ID varchar(50)

		   declare	@TBLSCHEME table (
				ID int not null,
				LVL INT not null,
				POSITION_ID bigint not null,
				POSITION_NAME VARCHAR(255) not null
		   )

		   select @POSITION_ID = POSITION_ID, @AREA_CODE = AREA_CODE, @BRANCH_CODE = BRANCH_CODE 
		   from MASTER_PLATFON_REIMBURSE where PLATFON_REIMBURSE_ID = @PAY_TO AND IS_ACTIVE = 1
		   select @APPROVE_ID = ROLE_CODE from APPROVE_REIMBURSE_HD where IS_ACTIVE = 1 and POSITION_ID = @POSITION_ID
		   
		   --select @POSITION_ID AS POSITION_ID, @AREA_CODE AS AREA_CODE, @BRANCH_CODE AS BRANCH_CODE 
		   
		   INSERT @TBLSCHEME (ID, LVL, POSITION_ID, POSITION_NAME)
		   select ROW_NUMBER() OVER(ORDER BY LEVEL ASC) AS Row, LEVEL, POSITION_CODE, POSITION from APPROVE_REIMBURSE_DT 
		   where IS_ACTIVE = 1 and ROLE_HD_CODE = @APPROVE_ID 

		   declare	@X				int = 1,
					@Y				int,
					@NIK			VARCHAR(50),
					@NAME			VARCHAR(255),
					@POSITION_CODE	BIGINT,
					@POSITION_NAME	VARCHAR(255)

		   set @Y = (select COUNT(*) from @TBLSCHEME)

		   WHILE (@X <= @Y)
		   BEGIN
			select @POSITION_CODE = POSITION_ID, @POSITION_NAME = POSITION_NAME from @TBLSCHEME where ID = @X
			
			IF(@POSITION_CODE IN (1002,1003) AND @APPROVE_ID = 'RHD00001')
			BEGIN
				SELECT @NIK = EMPLOYEE_CODE, @NAME = EMPLOYEE_NAME FROM MASTER_PLATFON_REIMBURSE 
				WHERE AREA_CODE = @AREA_CODE AND BRANCH_CODE = @BRANCH_CODE AND POSITION_ID = @POSITION_CODE AND IS_ACTIVE = 1
			END
			ELSE BEGIN
				IF (@POSITION_CODE >= 1003)
				BEGIN
					SELECT @NIK = EMPLOYEE_CODE, @NAME = EMPLOYEE_NAME FROM MASTER_PLATFON_REIMBURSE 
					WHERE AREA_CODE IS NULL AND (BRANCH_CODE is null /*OR BRANCH_CODE = 0*/) AND POSITION_ID = @POSITION_CODE AND IS_ACTIVE = 1
				END ELSE BEGIN
					SELECT @NIK = EMPLOYEE_CODE, @NAME = EMPLOYEE_NAME FROM MASTER_PLATFON_REIMBURSE 
					WHERE AREA_CODE = @AREA_CODE AND (BRANCH_CODE is null /*OR BRANCH_CODE = 0*/) AND POSITION_ID = @POSITION_CODE AND IS_ACTIVE = 1
				END
			END


			if(@REFF_NO is null OR @X is null OR @NIK is null OR @NAME IS NULL OR @POSITION_CODE IS NULL) 
			BEGIN
				RAISERROR('Please confirm to IT for setting approval scheme!!!!',16,1);
				return; 
			END ELSE BEGIN
				INSERT SCHEME_APPROVAL_REIMBURSE_TRX (HD_REFFNO, SEQ, EMPLOYEE_CODE, EMPLOYEE_NAME, POSITION_CODE, POSITION, IS_DECISION, CRE_BY, CRE_DT)
				VALUES(@REFF_NO, @X, @NIK, @NAME, @POSITION_CODE, @POSITION_NAME, 'F', @USERID, @ACT_DT)
			END
			set @X = @X + 1;
		   END

	END
	
	INSERT REIMBURSE_OPERATION_TRX (HD_REFFNO, STATUS, CRE_BY, CRE_DT)
	VALUES (@REFF_NO, @STATUS, @USERID, @ACT_DT)
END

--SELECT * FROM APPROVE_REIMBURSE_HD
--SELECT * FROM APPROVE_REIMBURSE_DT
--SELECT * FROM MASTER_PLATFON_REIMBURSE
--delete SCHEME_APPROVAL_REIMBURSE_TRX where HD_REFFNO='RBS/0922/0004'
--delete REIMBURSE_OPERATION_TRX where HD_REFFNO='RBS/0922/0004'
--DELETE from REIMBURSE_OPERATION_HD WHERE ID=4

--select * from MASTER_PLATFON_REIMBURSE
--select * from REIMBURSE_OPERATION_TRX where HD_REFFNO='RBS/0922/0004'
--select * from APPROVE_REIMBURSE_HD
--select * from APPROVE_REIMBURSE_DT
--SELECT * FROM APPROVE_REIMBURSE_HD
--SELECT * FROM APPROVE_REIMBURSE_DT
--select * from REIMBURSE_OPERATION_HD
--select * from REIMBURSE_OPERATION_DTa

--select * from SCHEME_APPROVAL_REIMBURSE_TRX ORDER BY SEQ ASC
--SELECT PLATFON_REIMBURSE_ID,EMPLOYEE_CODE, EMPLOYEE_NAME, POSITION, POSITION_ID, AREA, AREA_CODE, BRANCH, BRANCH_CODE FROM MASTER_PLATFON_REIMBURSE where POSITION_ID in (1001,1002) ORDER BY PLATFON_REIMBURSE_ID ASC
--SELECT PLATFON_REIMBURSE_ID, EMPLOYEE_CODE, EMPLOYEE_NAME, POSITION, POSITION_ID FROM MASTER_PLATFON_REIMBURSE ORDER BY PLATFON_REIMBURSE_ID ASC
--select ROLE, DESCRIPTION from MASTER_POSITION where IS_ACTIVE=1
--SELECT A.ID ,A.HD_REFFNO ,A.SEQ ,A.EMPLOYEE_CODE ,A.EMPLOYEE_NAME ,A.POSITION_CODE ,A.POSITION,A.IS_DECISION ,A.DECISION_STATE ,A.DECISION_DATE ,A.DECISION_NOTE FROM dbo.SCHEME_APPROVAL_REIMBURSE_TRX A left join MASTER_POSITION B on A.POSITION where A.HD_REFFNO='RBS/0922/0005' ORDER BY SEQ ASC









GO
/****** Object:  StoredProcedure [dbo].[INSERT_UPDATE_SCHEME_APPROVAL_REIMBURSE_TRX]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[INSERT_UPDATE_SCHEME_APPROVAL_REIMBURSE_TRX]
@ID	BIGINT=null,
@HD_REFFNO varchar(50),
@SEQ int,
@EMPLOYEE_CODE varchar(50),
@EMPLOYEE_NAME varchar(255),
@POSITION_CODE bigint,
@USERID varchar(50),
@ACT_DT datetime
AS
BEGIN
	DECLARE @POSITION varchar(255) = (SELECT DESCRIPTION FROM MASTER_POSITION WHERE IS_ACTIVE=1 AND ROLE = @POSITION_CODE)

	IF EXISTS(SELECT ID FROM SCHEME_APPROVAL_REIMBURSE_TRX WHERE ID = @ID)
	BEGIN
		UPDATE SCHEME_APPROVAL_REIMBURSE_TRX
		SET	HD_REFFNO = @HD_REFFNO,
			SEQ = @SEQ,
			EMPLOYEE_CODE = @EMPLOYEE_CODE,
			EMPLOYEE_NAME = @EMPLOYEE_NAME,
			POSITION_CODE = @POSITION_CODE,
			POSITION = @POSITION,
			MOD_BY = @USERID,
			MOD_DT = @ACT_DT
		WHERE ID=@ID
	END ELSE BEGIN
		INSERT SCHEME_APPROVAL_REIMBURSE_TRX(HD_REFFNO, SEQ, EMPLOYEE_CODE, EMPLOYEE_NAME, POSITION_CODE, POSITION, IS_DECISION, CRE_BY, CRE_DT)
		VALUES(@HD_REFFNO, @SEQ, @EMPLOYEE_CODE, @EMPLOYEE_NAME, @POSITION_CODE, @POSITION, 'F', @USERID, @ACT_DT)
	END
END


GO
/****** Object:  StoredProcedure [dbo].[sp_CreateLaci]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eka
-- Create date: 26-Jul-2022
-- Description:	<Description,,>
-- =============================================
-- exec sp_CreateLaci
CREATE PROCEDURE [dbo].[sp_CreateLaci] 
	@USERID varchar(20)
AS
BEGIN
	DECLARE 
	@CabinetNo VARCHAR(20),
	@CabinetNoDompet VARCHAR(20),
	@CabinetNoTray VARCHAR(20),
	@laci VARCHAR(20),
	@dompet INT,
	@tray INT,
	@x INT = 1,
	@y INT 

	SET @laci = (SELECT TOP 1 Laci from MasterCabinet where CreatedBy = 'NEW' order by id desc)
	SET @dompet = (SELECT TOP 1 MaxDompet from MasterCabinet where CreatedBy = 'NEW' order by id desc)
	SET @tray = (SELECT TOP 1 MaxTray from MasterCabinet where CreatedBy = 'NEW' order by id desc)

	WHILE @x <= @dompet
	BEGIN
		--SET @CabinetNo = '';
		--SET @CabinetNoDompet = '';
		--SET @CabinetNoTray = '';
		/*format number cabinet + DOMPET*/
		
		IF @X < 10
		BEGIN
			SET @CabinetNoDompet = '0' + CAST(@x AS VARCHAR(2))
		END
		ELSE BEGIN
			SET @CabinetNoDompet = CAST(@x AS VARCHAR(2))
		END
		
		/* FORMAT NUMBER cabinet + DOMPET + TRAY*/
		SET @y = 1
		WHILE @y <= @tray
		begin
			IF @y < 10
			BEGIN
				SET @CabinetNoTray = '0' + CAST(@y AS VARCHAR(2))
			END
			ELSE BEGIN
				SET @CabinetNoTray =  CAST(@y AS VARCHAR(2))
			END

			set @CabinetNo = @laci + @CabinetNoDompet + @CabinetNoTray
			INSERT INTO CabinetDetail VALUES (@CabinetNo,0,'SYSTEM',GETDATE(),0,'',null,'SYSTEM',GETDATE())
			
			set @y = @y + 1;
		end

		
		SET @x = @x + 1;
	END

	UPDATE MasterCabinet
	SET CreatedBy = @USERID
	FROM (SELECT TOP 1 id,CreatedBy from MasterCabinet where CreatedBy = 'NEW' order by id desc) as a
	WHERE MasterCabinet.id = a.id
END

GO
/****** Object:  StoredProcedure [dbo].[sp_insert_telesales]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROCEDURE [dbo].[sp_insert_telesales]
	  --@ID int																		= NULL,
       @PRODUCT NVARCHAR (100)									= NULL
      ,@CALLDATE Datetime												= NULL
      ,@AGENT_ID NVARCHAR (100)									= NULL
      ,@ID_NUMBER NVARCHAR (100)								= NULL
      ,@NO_CONTRACT NVARCHAR (100)							= NULL
      ,@CUSTOMER_NAME NVARCHAR (255)						= NULL
      ,@CUSTOMER_ADDRESS NVARCHAR (MAX)					= NULL
      ,@UPDATE_CUSTOMER_ADDRESS NVARCHAR (MAX)	= NULL
      ,@CONTACTED_PHONE NVARCHAR (50)						= NULL
      ,@RESULT NVARCHAR (200)										= NULL
      ,@REASON NVARCHAR (200)										= NULL
      ,@TANGGAL_FOLLOWUP Datetime								= NULL
      ,@TENOR NVARCHAR (10)											= NULL
      ,@JUMLAH_JAMAAH NVARCHAR (10)							= NULL
      ,@KEBUTUHAN_PEMBIAYAAN NVARCHAR (255)			= NULL
      ,@START_CALL NVARCHAR (100)								= NULL
      ,@END_CALL NVARCHAR (100)									= NULL
      ,@DURATION_CALL NVARCHAR (100)						= NULL
      ,@KETERANGAN NVARCHAR (200)								= NULL
      ,@CALL_COUNTER NVARCHAR (50)							= NULL
      ,@FLAG_SEND NVARCHAR (1)									= NULL
AS 
BEGIN 
     SET NOCOUNT ON 
	 --SET IDENTITY_INSERT dbo.TelesalesInsert ON
     INSERT INTO dbo.TelesalesInsert
          ([PRODUCT]
           ,[CALLDATE]
           ,[AGENT_ID]
           ,[ID_NUMBER]
           ,[NO_CONTRACT]
           ,[CUSTOMER_NAME]
           ,[CUSTOMER_ADDRESS]
           ,[UPDATE_CUSTOMER_ADDRESS]
           ,[CONTACTED_PHONE]
           ,[RESULT]
           ,[REASON]
           ,[TANGGAL_FOLLOWUP]
           ,[TENOR]
           ,[JUMLAH_JAMAAH]
           ,[KEBUTUHAN_PEMBIAYAAN]
           ,[START_CALL]
           ,[END_CALL]
           ,[DURATION_CALL]
           ,[KETERANGAN]
           ,[CALL_COUNTER]
           ,[FLAG_SEND]) 
     VALUES 
          (
						@PRODUCT,
						@CALLDATE,
						@AGENT_ID,
						@ID_NUMBER,
						@NO_CONTRACT,
						@CUSTOMER_NAME,
						@CUSTOMER_ADDRESS,
						@UPDATE_CUSTOMER_ADDRESS,
						@CONTACTED_PHONE,
						@RESULT,
						@REASON,
						@TANGGAL_FOLLOWUP,
						@TENOR,
						@JUMLAH_JAMAAH,
						@KEBUTUHAN_PEMBIAYAAN,
						@START_CALL,
						@END_CALL,
						@DURATION_CALL,
						@KETERANGAN,
						@CALL_COUNTER,
						@FLAG_SEND
					)
	-- SET IDENTITY_INSERT dbo.TelesalesInsert OFF
END 
GO
/****** Object:  StoredProcedure [dbo].[sp_MNCL_SendItracking_EmailNotif]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_MNCL_SendItracking_EmailNotif]
as

declare @message VARCHAR(MAX)
declare @recepient VARCHAR(MAX)
declare @recepient2 varchar(max)
declare @title varchar(255)
declare @ctr int
declare @max int 

CREATE TABLE #tmpTaskEmail
	(
	id bigint identity,
	dtlkey bigint,
	clientName varchar(200),
	supplName varchar(200),
	docno varchar(50),
	branch varchar(200),
	commentby varchar(100),
	commentdt datetime,
	comment varchar(max),
	status varchar (40),
	DistDate date
	)

CREATE TABLE #tmpEmailRecipient
	(
	branch varchar(200),
	status varchar(200),
	emailRecipient varchar(MAX)
	)

-- Generate Email Data

DECLARE @CURRDATE DATE
SET @CURRDATE = GETDATE()

INSERT INTO #tmpTaskEmail
/*
	(
	dtlkey,
	clientName,
	supplName,
	docno,
	branch,
	commentby,
	commentdt,
	comment,
	status
	)
*/
SELECT com.DtlKey,app.ClientName, app.SupplierName, app.DocNo, app.Branch, com.CommentBy, com.CommentDate, com.CommentNote, app.Status, com.DistDate
	FROM [dbo].[ApplicationCommentHistory] com
	JOIN Application app on com.DocNo = app.DocNo
	WHERE CommentDate >= @CURRDATE
	AND DtlKey NOT IN
		(SELECT KEY_ID FROM EMAIL_HIST WHERE EMAIL_TYPE = 'ITRACKING_COMMENT')

-- Generate Email Recipient

SELECT * INTO #tmpEmailGroupCabang
FROM
	(
	SELECT StateDescription, GroupAccessCode
		FROM
		ApplicationWorkflowAccess where StateDescription in
			(select status from #tmpTaskEmail)
	) as qry
JOIN 
	(SELECT COMP.C_NAME [BRANCH], GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
		WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code in ('BR-AO', 'BR-BM', 'BR-MKT-ADM')
		GROUP BY COMP.C_NAME, GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL
	) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

SELECT * INTO #tmpEmailGroupHO FROM
	(
	SELECT distinct StateDescription, GroupAccessCode
		FROM ApplicationWorkflowAccess where StateDescription in
			(select status from #tmpTaskEmail)
	) as qry
JOIN 
	(SELECT GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
		WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code not in ('BR-AO', 'BR-BM', 'BR-MKT-ADM', 'HO-IT-STF', 'HO-IT-SCH')
		GROUP BY GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL
	) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

Insert into #tmpEmailRecipient
	SELECT main.BRANCH, main.status, isnull(main.email1, '') + left(main.email2,len(main.email2)-1) As email FROM
	(select distinct e1.BRANCH, e1.status ,
		(select email + '; ' 
			from #tmpEmailGroupCabang e2 
			where e1.status = e2.stateDescription and e2.BRANCH=e1.BRANCH
			ORDER BY e2.stateDescription
			FOR XML PATH ('')
		) as email1,
		(select email + '; ' 
			from #tmpEmailGroupHO e3
			where e1.status = e3.stateDescription
			ORDER BY e3.stateDescription
			FOR XML PATH ('')
		) as email2
	from
	#tmpTaskEmail e1
	) main

set @ctr = 1
select @max =  MAX(ID) FROM #tmpTaskEmail

while(@ctr <= @max)
BEGIN

SELECT @message = 
	'<html>
		<head><style>body {font-family: arial; font-size: 14px;}</style></head>
		<body>
			<strong>'+isnull(commentby,'')+' </strong> melakukan input komentar pada aplikasi iTracking dengan detail sebagai berikut :
			<br/>
			<br/>
			<table width="80%">
				<tr>
				<td width="17%">No App</td>
				<td width="1%">:&nbsp;</td>
				<td width="82%"><strong>'+isnull(docno,'')+'</strong></td>
				</tr>
				<tr>
				<td>Client</td>
				<td>:&nbsp;</td>
				<td><strong>'+isnull(clientName,'')+'</strong></td>
				</tr>
				<tr>
				<td>Cabang</td>
				<td>:&nbsp;</td>
				<td><strong>'+isnull(em.branch,'')+'</strong></td>
				</tr>
				<tr>
				<td>Supplier</td>
				<td>:&nbsp;</td>
				<td><strong>'+isnull(supplName,'')+'</strong> <br/></td>
				</tr>
			</table>
			<br/>
			<table width="100%">
				<tr>
				<td width="24%">Dikomentari oleh</td>
				<td width="1%">:&nbsp;</td>
				<td width="75%"><strong>'+isnull(commentby,'')+'</strong> <br/> </td>
				</tr>
				<tr>
				<td>Tanggal Komentar</td>
				<td>:&nbsp;</td>
				<td><strong>'+isnull(cast(commentdt as varchar(30)),'')+'</strong> <br/></td>
				</tr>'
				+
					 case when DistDate is null then '' else 
					'<tr>
					<td>Tanggal Request Disburse</td>
					<td>:&nbsp;</td>
					<td><strong>'+isnull(cast(DistDate as varchar(11)),'')+'</strong> <br/></td>
					</tr>' end
				+
				'<tr>
				<td>Komentar</td>
				<td>:&nbsp;</td>
				<td></td>
				</tr>
				<tr>
				<td colspan="3" style="padding-left: 10px;"> <strong>'+isnull(comment,'')+'</strong> <br/></td>
				</tr>
			</table>
			<br/>
			<br/>
			<i><small>Anda menerima email ini dikarenakan anda terdaftar di group <strong>'+isnull(r.status,'')+'</strong></small></i>
			<br/>
			<br/>
			Regards,
			<br/>
			MNC Leasing SMILE Application – Auto Notification
		</body>
		</html>'
	,
	@recepient = r.emailRecipient
		FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
		on em.status = r.status and em.branch=r.branch
		WHERE em.id = @ctr

	--SET @recepient	= 'liung.hartono@mncgroup.com'
	select @title	= 'iTracking Comment Notification (' + isnull(clientName,'') + ')' from #tmpTaskEmail where id = @ctr

	exec [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
		@profile_name	= 'SQLMelisa',
		@recipients		= @recepient ,
		@subject		= @title, --'ITracking Comment Notification',
		@body			= @message,
		@body_format	= 'HTML'

	INSERT INTO EMAIL_HIST
	(
	KEY_ID,
	EMAIL_TYPE,
	EMAIL_TO,
	MESSAGE,
	EMAIL_DT
	)
	SELECT dtlkey,'ITRACKING_COMMENT', isnull(r.emailRecipient, ''), @message, GETDATE()  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
	on em.status = r.status 
	WHERE em.id = @ctr

	set @ctr =  @ctr +1

END

select * FROM #tmpTaskEmail em 
	JOIN #tmpEmailRecipient r on em.status = r.status 

DROP TABLE #tmpEmailGroupCabang
DROP TABLE #tmpEmailGroupHO
DROP TABLE #tmpEmailRecipient
DROP TABLE #tmpTaskEmail




GO
/****** Object:  StoredProcedure [dbo].[sp_MNCL_SendItracking_EmailNotif_20210330]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[sp_MNCL_SendItracking_EmailNotif_20210330]
as

declare @message VARCHAR(MAX)
declare @recepient VARCHAR(MAX)
declare @ctr int
declare @max int 

CREATE TABLE #tmpTaskEmail
(
id bigint identity,
dtlkey bigint,
clientName varchar(200),
supplName varchar(200),
docno varchar(50),
branch varchar(200),
commentby varchar(100),
commentdt datetime,
comment varchar(max),
status varchar (40)
)

CREATE TABLE #tmpEmailRecipient
(
	status varchar(200),
	emailRecipient varchar(MAX)
)


-- Generate Email Data

DECLARE @CURRDATE DATE
SET @CURRDATE = GETDATE()

INSERT INTO #tmpTaskEmail
(
dtlkey,
clientName,
supplName,
docno,
branch,
commentby,
commentdt,
comment,
status
)
SELECT com.DtlKey,app.ClientName, app.SupplierName, app.DocNo, app.Branch, com.CommentBy, com.CommentDate, com.CommentNote,app.Status
FROM [dbo].[ApplicationCommentHistory]com
JOIN Application app on com.DocNo = app.DocNo
WHERE CommentDate >=  @CURRDATE
AND DtlKey NOT IN
(SELECT KEY_ID FROM EMAIL_HIST WHERE EMAIL_TYPE = 'ITRACKING_COMMENT')



-- Generate Email Recipient


SELECT * INTO #tmpEmailGroup 
FROM
(
SELECT StateDescription, GroupAccessCode
FROM
ApplicationWorkflowAccess where StateDescription in
(
select status from #tmpTaskEmail
)
) as qry

JOIN 
(SELECT GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID

 WHERE  IS_ACTIVE_FLAG = '1'
GROUP BY GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode


Insert into #tmpEmailRecipient
SELECT main.stateDescription, LEFT(Main.email,Len(Main.email)-1) As email  FROM
(
select distinct stateDescription ,
 (
select email + ';' 
from #tmpEmailGroup e2 
 where e1.stateDescription = e2.stateDescription 
 ORDER BY e2.stateDescription
 FOR XML PATH ('')
 ) as email
 from
 #tmpEmailGroup e1
 ) main
 

 set @ctr = 1
 select @max =  MAX(ID) FROM #tmpTaskEmail
 while(@ctr <= @max)
 BEGIN
 SELECT @message = 
 '<html>
<strong>'+isnull(commentby,'')+' </strong> melakukan input komentar pada aplikasi ITracking dengan detail sebagai berikut :
<br/>
<br/>
<table width="50%">
<tr>
<td width="20%">No App &nbsp&nbsp&nbsp&nbsp: </td>
<td width="80%"><strong>'+isnull(docno,'')+'</strong></td>
</tr>
<tr>
<td  width="20%">Client&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp: </td>
<td><strong>'+isnull(clientName,'')+'</strong></td>
</tr>
<tr>
<td  width="20%">Cabang&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp:</td>
<td width="80%"><strong>'+isnull(branch,'')+'</strong></td>
</tr>
<tr>
<td  width="20%">Supplier&nbsp&nbsp&nbsp&nbsp&nbsp:</td>
<td width="80%"><strong>'+isnull(supplName,'')+'</strong> <br/></td>
</tr>
</table>
<br/>
<br/>
<table>
<tr>
<td>Di komentari oleh : </td>
<td><strong>&nbsp&nbsp'+isnull(commentby,'')+'</strong> <br/> </td>
</tr>
<tr>
<td>Tanggal Komentar  :</td>
<td>&nbsp&nbsp<strong>'+isnull(cast(commentdt as varchar(50)),'')+'</strong> <br/></td>
</tr>
<tr>
<td>Komentar          :</td>
<td> <strong>&nbsp&nbsp'+isnull(comment,'')+'</strong> <br/></td>
</tr>

</table>
<br/>
<br/>
<i><small>Anda menerima email ini dikarenakan anda terdaftar di group  '+isnull(r.status,'')+'</small></i>
</html>'
 ,
@recepient = r.emailRecipient
  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.status = r.status 
 WHERE em.id = @ctr


 SET @recepient =  @recepient

 exec [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
		@profile_name	= 'SQLMelisa',
		@recipients		=    @recepient ,
		@subject		= 'ITracking Comment Notification',
		@body			= @message,
		@body_format	= 'HTML'

 INSERT INTO EMAIL_HIST
 (
 KEY_ID,
EMAIL_TYPE,
EMAIL_TO,
MESSAGE,
EMAIL_DT
 )
 SELECT dtlkey,'ITRACKING_COMMENT', r.emailRecipient, @message, GETDATE()  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.status = r.status 
 WHERE em.id = @ctr
  set @ctr =  @ctr +1
 END

 select * FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.status = r.status 

DROP TABLE #tmpEmailGroup
DROP TABLE #tmpEmailRecipient
DROP TABLE #tmpTaskEmail









---------------------------------------------




GO
/****** Object:  StoredProcedure [dbo].[sp_MNCL_SendItracking_EmailNotif_20210401]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROC [dbo].[sp_MNCL_SendItracking_EmailNotif_20210401]
as

declare @message VARCHAR(MAX)
declare @recepient VARCHAR(MAX)
declare @recepient2 varchar(max)
declare @title varchar(255)
declare @ctr int
declare @max int 

CREATE TABLE #tmpTaskEmail
	(
	id bigint identity,
	dtlkey bigint,
	clientName varchar(200),
	supplName varchar(200),
	docno varchar(50),
	branch varchar(200),
	commentby varchar(100),
	commentdt datetime,
	comment varchar(max),
	status varchar (40)
	)

CREATE TABLE #tmpEmailRecipient
(
	branch varchar(200),
	status varchar(200),
	emailRecipient varchar(MAX)
)

-- Generate Email Data

DECLARE @CURRDATE DATE
SET @CURRDATE = GETDATE()-1

INSERT INTO #tmpTaskEmail
	(
	dtlkey,
	clientName,
	supplName,
	docno,
	branch,
	commentby,
	commentdt,
	comment,
	status
	)
SELECT com.DtlKey,app.ClientName, app.SupplierName, app.DocNo, app.Branch, com.CommentBy, com.CommentDate, com.CommentNote,app.Status
	FROM [dbo].[ApplicationCommentHistory]com
	JOIN Application app on com.DocNo = app.DocNo
	WHERE CommentDate >=  @CURRDATE
	AND DtlKey NOT IN
		(SELECT KEY_ID FROM EMAIL_HIST WHERE EMAIL_TYPE = 'ITRACKING_COMMENT')

-- Generate Email Recipient

SELECT * INTO #tmpEmailGroupCabang
FROM
	(
		SELECT StateDescription, GroupAccessCode
		FROM
		ApplicationWorkflowAccess where StateDescription in
			(select status from #tmpTaskEmail)
	) as qry

JOIN 
	(SELECT COMP.C_NAME [BRANCH], GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
	WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code in ('BR-AO', 'BR-BM', 'BR-MKT-ADM')
	GROUP BY COMP.C_NAME, GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

SELECT * INTO #tmpEmailGroupHO FROM
	(
	SELECT distinct StateDescription, GroupAccessCode
		FROM ApplicationWorkflowAccess where StateDescription in
			(select status from #tmpTaskEmail)
	) as qry
JOIN 
(SELECT GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code not in ('BR-AO', 'BR-BM', 'BR-MKT-ADM')
GROUP BY GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

Insert into #tmpEmailRecipient
	SELECT main.BRANCH, main.stateDescription, main.email1 + left(main.email2,len(main.email2)-1) As email  FROM
	(select distinct e1.BRANCH, stateDescription , isnull(
		(select email + '; ' 
			from #tmpEmailGroupCabang e2 
			where e1.stateDescription = e2.stateDescription and e2.BRANCH=e1.BRANCH
			ORDER BY e2.stateDescription
			FOR XML PATH ('')
		), '') as email1,
		(select email + '; ' 
			from #tmpEmailGroupHO e3
			where e1.stateDescription = e3.stateDescription
			ORDER BY e3.stateDescription
			FOR XML PATH ('')
		) as email2
	from
	#tmpEmailGroupCabang e1
	) main

select * from #tmpEmailRecipient

set @ctr = 1
select @max =  MAX(ID) FROM #tmpTaskEmail

while(@ctr <= @max)
BEGIN
SELECT @message = 
	'<html>
		<body><style>body {font-family: arial; font-size: 16px;}</style></body>
		<strong>'+isnull(commentby,'')+' </strong> melakukan input komentar pada aplikasi ITracking dengan detail sebagai berikut :
		<br/>'+ @recepient +
		'<br/>
		<table width="80%">
			<tr>
			<td width="19%">No App</td>
			<td width="1%">:&nbsp;</td>
			<td width="80%"><strong>'+isnull(docno,'')+'</strong></td>
			</tr>
			<tr>
			<td>Client</td>
			<td>:&nbsp;</td>
			<td><strong>'+isnull(clientName,'')+'</strong></td>
			</tr>
			<tr>
			<td>Cabang</td>
			<td>:&nbsp;</td>
			<td><strong>'+isnull(em.branch,'')+'</strong></td>
			</tr>
			<tr>
			<td>Supplier</td>
			<td>:&nbsp;</td>
			<td><strong>'+isnull(supplName,'')+'</strong> <br/></td>
			</tr>
		</table>
		<br/>
		<br/>
		<table width="100%">
			<tr>
			<td width="29%">Dikomentari oleh</td>
			<td width="1%">:&nbsp;</td>
			<td width="70%"><strong>'+isnull(commentby,'')+'</strong> <br/> </td>
			</tr>
			<tr>
			<td>Tanggal Komentar</td>
			<td>:&nbsp;</td>
			<td><strong>'+isnull(cast(commentdt as varchar(50)),'')+'</strong> <br/></td>
			</tr>
			<tr>
			<td>Komentar</td>
			<td>:&nbsp;</td>
			<td> <strong>'+isnull(comment,'')+'</strong> <br/></td>
			</tr>
		</table>
		<br/>
		<br/>
		<i><small>Anda menerima email ini dikarenakan anda terdaftar di group '+isnull(r.status,'')+'</small></i>
		</html>'
	,
	@recepient = r.emailRecipient
		FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
		on em.status = r.status and em.branch=r.branch
		WHERE em.id = @ctr

	SET @recepient	= @recepient + '; liung.hartono@mncgroup.com'
	SET @recepient2	= 'liung.hartono@mncgroup.com'
	select @title	= 'ITracking Comment Notification (' + isnull(clientName,'') + ')' from #tmpTaskEmail where id = @ctr

	exec [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
		@profile_name	= 'SQLMelisa',
		@recipients		= @recepient2 ,
		@subject		= @title, --'ITracking Comment Notification',
		@body			= @message,
		@body_format	= 'HTML'
/*
	INSERT INTO EMAIL_HIST
	(
	KEY_ID,
	EMAIL_TYPE,
	EMAIL_TO,
	MESSAGE,
	EMAIL_DT
	)
	SELECT dtlkey,'ITRACKING_COMMENT', r.emailRecipient, @message, GETDATE()  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
	on em.status = r.status 
	WHERE em.id = @ctr
*/
	set @ctr =  @ctr +1

END

select * FROM #tmpTaskEmail em 
	JOIN #tmpEmailRecipient r on em.status = r.status 

DROP TABLE #tmpEmailGroupCabang
DROP TABLE #tmpEmailGroupHO
DROP TABLE #tmpEmailRecipient
DROP TABLE #tmpTaskEmail



GO
/****** Object:  StoredProcedure [dbo].[sp_MNCL_SendItracking_EmailNotif_20211224]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create PROC [dbo].[sp_MNCL_SendItracking_EmailNotif_20211224]
as

declare @message VARCHAR(MAX)
declare @recepient VARCHAR(MAX)
declare @recepient2 varchar(max)
declare @title varchar(255)
declare @ctr int
declare @max int 

CREATE TABLE #tmpTaskEmail
	(
	id bigint identity,
	dtlkey bigint,
	clientName varchar(200),
	supplName varchar(200),
	docno varchar(50),
	branch varchar(200),
	commentby varchar(100),
	commentdt datetime,
	comment varchar(max),
	status varchar (40)
	)

CREATE TABLE #tmpEmailRecipient
	(
	branch varchar(200),
	status varchar(200),
	emailRecipient varchar(MAX)
	)

-- Generate Email Data

DECLARE @CURRDATE DATE
SET @CURRDATE = GETDATE()

INSERT INTO #tmpTaskEmail
/*
	(
	dtlkey,
	clientName,
	supplName,
	docno,
	branch,
	commentby,
	commentdt,
	comment,
	status
	)
*/
SELECT com.DtlKey,app.ClientName, app.SupplierName, app.DocNo, app.Branch, com.CommentBy, com.CommentDate, com.CommentNote,app.Status
	FROM [dbo].[ApplicationCommentHistory]com
	JOIN Application app on com.DocNo = app.DocNo
	WHERE CommentDate >= @CURRDATE
	AND DtlKey NOT IN
		(SELECT KEY_ID FROM EMAIL_HIST WHERE EMAIL_TYPE = 'ITRACKING_COMMENT')

-- Generate Email Recipient

SELECT * INTO #tmpEmailGroupCabang
FROM
	(
	SELECT StateDescription, GroupAccessCode
		FROM
		ApplicationWorkflowAccess where StateDescription in
			(select status from #tmpTaskEmail)
	) as qry
JOIN 
	(SELECT COMP.C_NAME [BRANCH], GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
		WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code in ('BR-AO', 'BR-BM', 'BR-MKT-ADM')
		GROUP BY COMP.C_NAME, GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL
	) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

SELECT * INTO #tmpEmailGroupHO FROM
	(
	SELECT distinct StateDescription, GroupAccessCode
		FROM ApplicationWorkflowAccess where StateDescription in
			(select status from #tmpTaskEmail)
	) as qry
JOIN 
	(SELECT GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
		JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
		WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code not in ('BR-AO', 'BR-BM', 'BR-MKT-ADM')
		GROUP BY GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL
	) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

Insert into #tmpEmailRecipient
	SELECT main.BRANCH, main.status, isnull(main.email1, '') + left(main.email2,len(main.email2)-1) As email FROM
	(select distinct e1.BRANCH, e1.status ,
		(select email + '; ' 
			from #tmpEmailGroupCabang e2 
			where e1.status = e2.stateDescription and e2.BRANCH=e1.BRANCH
			ORDER BY e2.stateDescription
			FOR XML PATH ('')
		) as email1,
		(select email + '; ' 
			from #tmpEmailGroupHO e3
			where e1.status = e3.stateDescription
			ORDER BY e3.stateDescription
			FOR XML PATH ('')
		) as email2
	from
	#tmpTaskEmail e1
	) main

set @ctr = 1
select @max =  MAX(ID) FROM #tmpTaskEmail

while(@ctr <= @max)
BEGIN
SELECT @message = 
	'<html>
		<head><style>body {font-family: arial; font-size: 14px;}</style></head>
		<body>
			<strong>'+isnull(commentby,'')+' </strong> melakukan input komentar pada aplikasi iTracking dengan detail sebagai berikut :
			<br/>
			<br/>
			<table width="80%">
				<tr>
				<td width="17%">No App</td>
				<td width="1%">:&nbsp;</td>
				<td width="82%"><strong>'+isnull(docno,'')+'</strong></td>
				</tr>
				<tr>
				<td>Client</td>
				<td>:&nbsp;</td>
				<td><strong>'+isnull(clientName,'')+'</strong></td>
				</tr>
				<tr>
				<td>Cabang</td>
				<td>:&nbsp;</td>
				<td><strong>'+isnull(em.branch,'')+'</strong></td>
				</tr>
				<tr>
				<td>Supplier</td>
				<td>:&nbsp;</td>
				<td><strong>'+isnull(supplName,'')+'</strong> <br/></td>
				</tr>
			</table>
			<br/>
			<table width="100%">
				<tr>
				<td width="24%">Dikomentari oleh</td>
				<td width="1%">:&nbsp;</td>
				<td width="75%"><strong>'+isnull(commentby,'')+'</strong> <br/> </td>
				</tr>
				<tr>
				<td>Tanggal Komentar</td>
				<td>:&nbsp;</td>
				<td><strong>'+isnull(cast(commentdt as varchar(50)),'')+'</strong> <br/></td>
				</tr>
				<tr>
				<td>Komentar</td>
				<td>:&nbsp;</td>
				<td></td>
				</tr>
				<tr>
				<td colspan="3" style="padding-left: 10px;"> <strong>'+isnull(comment,'')+'</strong> <br/></td>
				</tr>
			</table>
			<br/>
			<br/>
			<i><small>Anda menerima email ini dikarenakan anda terdaftar di group <strong>'+isnull(r.status,'')+'</strong></small></i>
			<br/>
			<br/>
			Regards,
			<br/>
			MNC Leasing SMILE Application – Auto Notification
		</body>
		</html>'
	,
	@recepient = r.emailRecipient
		FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
		on em.status = r.status and em.branch=r.branch
		WHERE em.id = @ctr

	--SET @recepient	= @recepient + '; liung.hartono@mncgroup.com'
	--SET @recepient2	= 'liung.hartono@mncgroup.com'
	select @title	= 'iTracking Comment Notification (' + isnull(clientName,'') + ')' from #tmpTaskEmail where id = @ctr

	exec [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
		@profile_name	= 'SQLMelisa',
		@recipients		= @recepient ,
		@subject		= @title, --'ITracking Comment Notification',
		@body			= @message,
		@body_format	= 'HTML'

	INSERT INTO EMAIL_HIST
	(
	KEY_ID,
	EMAIL_TYPE,
	EMAIL_TO,
	MESSAGE,
	EMAIL_DT
	)
	SELECT dtlkey,'ITRACKING_COMMENT', isnull(r.emailRecipient, ''), @message, GETDATE()  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
	on em.status = r.status 
	WHERE em.id = @ctr

	set @ctr =  @ctr +1

END

select * FROM #tmpTaskEmail em 
	JOIN #tmpEmailRecipient r on em.status = r.status 

DROP TABLE #tmpEmailGroupCabang
DROP TABLE #tmpEmailGroupHO
DROP TABLE #tmpEmailRecipient
DROP TABLE #tmpTaskEmail




GO
/****** Object:  StoredProcedure [dbo].[sp_MNCL_SendItrackingHist_EmailNotif]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[sp_MNCL_SendItrackingHist_EmailNotif]
as

declare @message VARCHAR(MAX)
declare @recepient VARCHAR(MAX)
declare @title varchar(255)
declare @ctr int
declare @max int 

CREATE TABLE #tmpTaskEmail
	(
	id bigint identity,
	dtlkey bigint,
	clientName varchar(200),
	supplName varchar(200),
	docno varchar(50),
	itemDesc varchar(max),
	branch varchar(200),
	currstat varchar(100),
	TransDt datetime,
	fromstat varchar(2000),
	transby varchar (2000)
	)

CREATE TABLE #tmpEmailRecipient
(
	branch varchar(200),
	status varchar(200),
	emailRecipient varchar(MAX)
)

-- Generate Email Data

DECLARE @CURRDATE DATE
SET @CURRDATE = GETDATE()

INSERT INTO #tmpTaskEmail
	(
	dtlkey,
	clientName,
	supplName,
	docno,
	itemDesc,
	branch,
	currstat,
	TransDt,
	fromstat,
	transby
	)
SELECT com.DtlKey,app.ClientName, app.SupplierName, app.DocNo, det.ItemDescription, app.Branch, com.Status, com.TransDate, com.FromStatus, com.TransBy
	FROM [dbo].[ApplicationHistory]com
	JOIN Application app on com.DocKey = app.DocKey
	join ApplicationDetail det on det.DocKey=app.DocKey
	WHERE com.TransDate >=  @CURRDATE
	AND com.Status <> 'PROSPECT'
	AND com.DtlKey NOT IN
		(SELECT KEY_ID FROM EMAIL_HIST WHERE EMAIL_TYPE = 'ITRACKING_HIST') and com.Status = app.Status

-- Generate Email Recipient

SELECT * INTO #tmpEmailGroupCabang 
FROM
	(
	SELECT distinct StateDescription, GroupAccessCode
	FROM
	ApplicationWorkflowAccess where StateDescription in
		(select currstat from #tmpTaskEmail)
	) as qry
JOIN 
	(SELECT COMP.C_NAME [BRANCH], GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
	WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code in ('BR-AO', 'BR-BM', 'BR-MKT-ADM')
	GROUP BY COMP.C_NAME, GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

SELECT * INTO #tmpEmailGroupHO
	FROM
	(
	SELECT distinct StateDescription, GroupAccessCode
		FROM ApplicationWorkflowAccess where StateDescription in
			(select currstat from #tmpTaskEmail)
	) as qry
JOIN 
(SELECT GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code not in ('BR-AO', 'BR-BM', 'BR-MKT-ADM', 'HO-IT-STF', 'HO-IT-SCH')
GROUP BY GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

Insert into #tmpEmailRecipient
	SELECT main.BRANCH, main.currstat, isnull(main.email1, '') + left(main.email2,len(main.email2)-1) As email FROM
	(select distinct e1.BRANCH, e1.currstat ,
		(select email + '; ' 
			from #tmpEmailGroupCabang e2 
			where e1.currstat = e2.stateDescription and e2.BRANCH=e1.BRANCH
			ORDER BY e2.stateDescription
			FOR XML PATH ('')
		) as email1,
		(select email + '; ' 
			from #tmpEmailGroupHO e3
			where e1.currstat = e3.stateDescription
			ORDER BY e3.stateDescription
			FOR XML PATH ('')
		) as email2
	from
	#tmpTaskEmail e1
	) main
 
set @ctr = 1
select @max =  MAX(ID) FROM #tmpTaskEmail

 while(@ctr <= @max)
 BEGIN
 SELECT @message = 
	'<html>
		<head><style>body {font-family: arial; font-size: 14px;}</style></head>
 		<body>
			Ini adalah auto-generated email pemberitahuan untuk perubahan status aplikasi iTracking :
			<br/>
			<br/>
			<table>
			<tr>
				<td width="19%">Doc No.</td>
				<td width="1%">:&nbsp;</td>
				<td width="80%"><strong>'+em.docno+'</strong></td>
			</tr>
			<tr>
				<td width="19%">Description</td>
				<td width="1%">:&nbsp;</td>
				<td width="80%"><strong>'+em.itemDesc+'</strong></td>
			</tr>
			<tr>
				<td>Cabang</td>
				<td>:&nbsp;</td>
				<td><strong>'+em.branch+'</strong></td>
			</tr>
			<tr>
				<td width="19%">Client</td>
				<td width="1%">:&nbsp;</td>
				<td width="80%"><strong>'+clientName+'</strong></td>
			</tr>
			<tr>
				<td>Supplier</td>
				<td>:&nbsp;</td>
				<td><strong>'+supplName+'</strong></td>
			</tr>
			<tr>
				<td>Tanggal Proses</td>
				<td>:&nbsp;</td>
				<td><strong>'+CAST(TransDt as VARCHAR(50))+'</strong></td>
			</tr>
			<tr>
				<td>Di proses oleh</td>
				<td>:&nbsp;</td>
				<td><strong>'+transby+'</strong></td>
			</tr>
			<tr>
				<td>Status</td>
				<td>:&nbsp;</td>
				<td><strong>'+currstat+'</strong></td>
			</tr>
			</table>
			<br/>
			<br/>
			Regards,
			<br/>
			MNC Leasing SMILE Application – Auto Notification		
		</body>	  
		</html>'
	,
	@recepient = r.emailRecipient
		FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
		on em.currstat = r.status and em.branch=r.branch
		WHERE em.id = @ctr

	--SET @recepient = @recepient + '; eko.cietra@mncgroup.com; liung.hartono@mncgroup.com'
	--SET @recepient = 'liung.hartono@mncgroup.com'
	select @title	= 'iTracking Status Change (' + isnull(clientName,'') + ' - ' + currstat +')' from #tmpTaskEmail where id = @ctr

if(LEN(@message) > 0 OR @message IS NOT NULL)
BEGIN
	 exec [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
			@profile_name	= 'SQLMelisa',
			@recipients		= @recepient,
			@subject		= @title, --'ITracking Status Change Notification',
			@body			= @message,
			@body_format	= 'HTML'

INSERT INTO EMAIL_HIST
 (
KEY_ID,
EMAIL_TYPE,
EMAIL_TO,
MESSAGE,
EMAIL_DT
 )
 SELECT dtlkey,'ITRACKING_HIST', isnull(r.emailRecipient, ''), @message, GETDATE()  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status 
 WHERE em.id = @ctr
 END
  set @ctr =  @ctr +1
 END

 select * FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status 

DROP TABLE #tmpEmailGroupCabang
DROP TABLE #tmpEmailGroupHO
DROP TABLE #tmpEmailRecipient
DROP TABLE #tmpTaskEmail

---------------------------------------------



GO
/****** Object:  StoredProcedure [dbo].[sp_MNCL_SendItrackingHist_EmailNotif_20210326]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROC [dbo].[sp_MNCL_SendItrackingHist_EmailNotif_20210326]
as

declare @message VARCHAR(MAX)
declare @recepient VARCHAR(MAX)
declare @ctr int
declare @max int 

CREATE TABLE #tmpTaskEmail
(
id bigint identity,
dtlkey bigint,
clientName varchar(200),
supplName varchar(200),
docno varchar(50),
branch varchar(200),
currstat varchar(100),
TransDt datetime,
fromstat varchar(2000),
transby varchar (2000)
)

CREATE TABLE #tmpEmailRecipient
(
	status varchar(200),
	emailRecipient varchar(MAX)
)


-- Generate Email Data

DECLARE @CURRDATE DATE
SET @CURRDATE = GETDATE()

INSERT INTO #tmpTaskEmail
(
dtlkey,
clientName,
supplName,
docno,
branch,
currstat,
TransDt,
fromstat,
transby
)
SELECT com.DtlKey,app.ClientName, app.SupplierName, app.DocNo, app.Branch, com.Status, com.TransDate, com.FromStatus, com.TransBy
FROM [dbo].[ApplicationHistory]com
JOIN Application app on com.DocKey = app.DocKey
WHERE com.TransDate >=  @CURRDATE
AND com.Status <> 'PROSPECT'
AND DtlKey NOT IN
(SELECT KEY_ID FROM EMAIL_HIST WHERE EMAIL_TYPE = 'ITRACKING_HIST') and com.Status =  app.Status



-- Generate Email Recipient


SELECT * INTO #tmpEmailGroup 
FROM
(
SELECT StateDescription, GroupAccessCode
FROM
ApplicationWorkflowAccess where StateDescription in
(
select currstat from #tmpTaskEmail
)
) as qry

JOIN 
(SELECT GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID

 WHERE  IS_ACTIVE_FLAG = '1'
GROUP BY GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode


Insert into #tmpEmailRecipient
SELECT main.stateDescription, LEFT(Main.email,Len(Main.email)-1) As email  FROM
(
select distinct stateDescription ,
 (
select email + ';' 
from #tmpEmailGroup e2 
 where e1.stateDescription = e2.stateDescription 
 ORDER BY e2.stateDescription
 FOR XML PATH ('')
 ) as email
 from
 #tmpEmailGroup e1
 ) main
 
 --added by Liung's 26 mar 2021 untuk tracing email dobel
 update #tmpEmailRecipient set emailRecipient=emailRecipient+';liung.hartono@mncgroup.com'
 
 set @ctr = 1
 select @max =  MAX(ID) FROM #tmpTaskEmail
 while(@ctr <= @max)
 BEGIN
 SELECT @message = '<html>
Status doc no <strong>'+docno+'</strong> berubah menjadi <strong>'+currstat+'</strong> dengan detail sebagai berikut :
<br/>
<br/>
<table>
<tr>
<td>
Client&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp:
</td>
<td>
 <strong>'+clientName+'</strong>
</td>
</tr>
<tr>
<td>
Cabang&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp:	
</td>
<td>
<strong>'+branch+'</strong>
</td>
</tr>
<tr>
<td>
Supplier&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp:	
</td>
<td>
<strong>'+supplName+'</strong>
</td>
</tr>
<tr>
<td>
Tanggal Proses&nbsp&nbsp&nbsp:	
</td>
<td>
<strong>'+CAST(TransDt as VARCHAR(50))+'</strong>
</td>
</tr>
<tr>
<td>
Di proses oleh&nbsp&nbsp&nbsp&nbsp: 
</td>
<td>
<strong>'+transby+'</strong>
</td>
</tr>
<tr>
<td>
Status&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp: 
</td>
<td>
<strong>'+currstat+'</strong>
</td>
</tr>
</table>	  
</html>
'
 ,
@recepient = r.emailRecipient
  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status 
 WHERE em.id = @ctr

 SET @recepient = @recepient + '; eko.cietra@mncgroup.com'

if(LEN(@message) > 0 OR @message IS NOT NULL)
BEGIN
	 exec [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
			@profile_name	= 'SQLMelisa',
			@recipients		= @recepient,
			@subject		= 'ITracking Status Change Notification',
			@body			= @message,
			@body_format	= 'HTML'

	 INSERT INTO EMAIL_HIST
 (
 KEY_ID,
EMAIL_TYPE,
EMAIL_TO,
MESSAGE,
EMAIL_DT
 )
 SELECT dtlkey,'ITRACKING_HIST', r.emailRecipient, @message, GETDATE()  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status 
 WHERE em.id = @ctr
 END
  set @ctr =  @ctr +1
 END

 select * FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status 

DROP TABLE #tmpEmailGroup
DROP TABLE #tmpEmailRecipient
DROP TABLE #tmpTaskEmail









---------------------------------------------





GO
/****** Object:  StoredProcedure [dbo].[sp_MNCL_SendItrackingHist_EmailNotif_20210330]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROC [dbo].[sp_MNCL_SendItrackingHist_EmailNotif_20210330]
as

declare @message VARCHAR(MAX)
declare @recepient VARCHAR(MAX)
declare @ctr int
declare @max int 

CREATE TABLE #tmpTaskEmail
(
id bigint identity,
dtlkey bigint,
clientName varchar(200),
supplName varchar(200),
docno varchar(50),
branch varchar(200),
currstat varchar(100),
TransDt datetime,
fromstat varchar(2000),
transby varchar (2000)
)

CREATE TABLE #tmpEmailRecipient
(
	branch varchar(200),
	status varchar(200),
	emailRecipient varchar(MAX)
)

-- Generate Email Data

DECLARE @CURRDATE DATE
SET @CURRDATE = GETDATE()

INSERT INTO #tmpTaskEmail
(
dtlkey,
clientName,
supplName,
docno,
branch,
currstat,
TransDt,
fromstat,
transby
)
SELECT com.DtlKey,app.ClientName, app.SupplierName, app.DocNo, app.Branch, com.Status, com.TransDate, com.FromStatus, com.TransBy
FROM [dbo].[ApplicationHistory]com
JOIN Application app on com.DocKey = app.DocKey
WHERE com.TransDate >=  @CURRDATE
AND com.Status <> 'PROSPECT'
AND DtlKey NOT IN
(SELECT KEY_ID FROM EMAIL_HIST WHERE EMAIL_TYPE = 'ITRACKING_HIST') and com.Status =  app.Status

-- Generate Email Recipient

SELECT * INTO #tmpEmailGroup 
FROM
(
SELECT distinct StateDescription, GroupAccessCode
FROM
ApplicationWorkflowAccess where StateDescription in
(
select currstat from #tmpTaskEmail
)
) as qry

JOIN 
(SELECT COMP.C_NAME [BRANCH], GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
WHERE  IS_ACTIVE_FLAG = '1'
GROUP BY COMP.C_NAME, GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

Insert into #tmpEmailRecipient
SELECT main.BRANCH, main.stateDescription, LEFT(Main.email,Len(Main.email)-1) As email  FROM
(
select distinct e1.BRANCH, stateDescription ,
 (
select email + ';' 
from #tmpEmailGroup e2 
 where e1.stateDescription = e2.stateDescription and e2.BRANCH=e1.BRANCH
 ORDER BY e2.stateDescription
 FOR XML PATH ('')
 ) as email
 from
 #tmpEmailGroup e1
 ) main
 
 set @ctr = 1
 select @max =  MAX(ID) FROM #tmpTaskEmail
 while(@ctr <= @max)
 BEGIN
 SELECT @message = '<html>
Status doc no <strong>'+docno+'</strong> berubah menjadi <strong>'+currstat+'</strong> dengan detail sebagai berikut :
<br/>
<br/>
<table>
<tr>
<td>
Client&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp:
</td>
<td>
 <strong>'+clientName+'</strong>
</td>
</tr>
<tr>
<td>
Cabang&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp:	
</td>
<td>
<strong>'+em.branch+'</strong>
</td>
</tr>
<tr>
<td>
Supplier&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp:	
</td>
<td>
<strong>'+supplName+'</strong>
</td>
</tr>
<tr>
<td>
Tanggal Proses&nbsp&nbsp&nbsp:	
</td>
<td>
<strong>'+CAST(TransDt as VARCHAR(50))+'</strong>
</td>
</tr>
<tr>
<td>
Di proses oleh&nbsp&nbsp&nbsp&nbsp: 
</td>
<td>
<strong>'+transby+'</strong>
</td>
</tr>
<tr>
<td>
Status&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp: 
</td>
<td>
<strong>'+currstat+'</strong>
</td>
</tr>
</table>	  
</html>
'
 ,
@recepient = r.emailRecipient
  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status and em.branch=r.branch
 WHERE em.id = @ctr

 SET @recepient = @recepient + '; eko.cietra@mncgroup.com; liung.hartono@mncgroup.com'

if(LEN(@message) > 0 OR @message IS NOT NULL)
BEGIN
	 exec [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
			@profile_name	= 'SQLMelisa',
			@recipients		= @recepient,
			@subject		= 'ITracking Status Change Notification',
			@body			= @message,
			@body_format	= 'HTML'

INSERT INTO EMAIL_HIST
 (
KEY_ID,
EMAIL_TYPE,
EMAIL_TO,
MESSAGE,
EMAIL_DT
 )
 SELECT dtlkey,'ITRACKING_HIST', r.emailRecipient, @message, GETDATE()  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status 
 WHERE em.id = @ctr
 END
  set @ctr =  @ctr +1
 END

 select * FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status 

DROP TABLE #tmpEmailGroup
DROP TABLE #tmpEmailRecipient
DROP TABLE #tmpTaskEmail

---------------------------------------------



GO
/****** Object:  StoredProcedure [dbo].[sp_MNCL_SendItrackingHist_EmailNotif_20210401]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[sp_MNCL_SendItrackingHist_EmailNotif_20210401]
as

declare @message VARCHAR(MAX)
declare @recepient VARCHAR(MAX)
declare @title varchar(255)
declare @ctr int
declare @max int 

CREATE TABLE #tmpTaskEmail
	(
	id bigint identity,
	dtlkey bigint,
	clientName varchar(200),
	supplName varchar(200),
	docno varchar(50),
	branch varchar(200),
	currstat varchar(100),
	TransDt datetime,
	fromstat varchar(2000),
	transby varchar (2000)
	)

CREATE TABLE #tmpEmailRecipient
(
	branch varchar(200),
	status varchar(200),
	emailRecipient varchar(MAX)
)

-- Generate Email Data

DECLARE @CURRDATE DATE
SET @CURRDATE = GETDATE()

INSERT INTO #tmpTaskEmail
	(
	dtlkey,
	clientName,
	supplName,
	docno,
	branch,
	currstat,
	TransDt,
	fromstat,
	transby
	)
SELECT com.DtlKey,app.ClientName, app.SupplierName, app.DocNo, app.Branch, com.Status, com.TransDate, com.FromStatus, com.TransBy
	FROM [dbo].[ApplicationHistory]com
	JOIN Application app on com.DocKey = app.DocKey
	WHERE com.TransDate >=  '3/31/2021'--@CURRDATE
	AND com.Status <> 'PROSPECT'
	AND DtlKey NOT IN
		(SELECT KEY_ID FROM EMAIL_HIST WHERE EMAIL_TYPE = 'ITRACKING_HIST') and com.Status =  app.Status

-- Generate Email Recipient

SELECT * INTO #tmpEmailGroupCabang 
FROM
	(
	SELECT distinct StateDescription, GroupAccessCode
	FROM
	ApplicationWorkflowAccess where StateDescription in
		(select currstat from #tmpTaskEmail)
	) as qry
JOIN 
	(SELECT COMP.C_NAME [BRANCH], GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
	WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code in ('BR-AO', 'BR-BM', 'BR-MKT-ADM')
	GROUP BY COMP.C_NAME, GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

SELECT * INTO #tmpEmailGroupHO
	FROM
	(
	SELECT distinct StateDescription, GroupAccessCode
		FROM ApplicationWorkflowAccess where StateDescription in
			(select currstat from #tmpTaskEmail)
	) as qry
JOIN 
(SELECT GROUP_CODE, MU.USER_ID, USER_NAME, EMP.EMAIL FROM [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER_COMPANY_GROUP MG
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].MASTER_USER MU ON MU.USER_ID =  MG.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_TBLEMPLOYEE EMP ON EMP.CODE = MU.USER_ID
JOIN [172.31.215.2\MSSQLSRVGUI].IFINANCING_GOLIVE.[dbo].SYS_COMPANY COMP ON COMP.C_CODE = MG.C_CODE
WHERE  IS_ACTIVE_FLAG = '1' and mg.group_code not in ('BR-AO', 'BR-BM', 'BR-MKT-ADM')
GROUP BY GROUP_CODE, MU.USER_ID, USER_NAME ,EMP.EMAIL) qry2 on qry2.GROUP_CODE =  qry.GroupAccessCode

Insert into #tmpEmailRecipient
	SELECT main.BRANCH, main.currstat, isnull(main.email1, '') + left(main.email2,len(main.email2)-1) As email FROM
	(select distinct e1.BRANCH, e1.currstat ,
		(select email + '; ' 
			from #tmpEmailGroupCabang e2 
			where e1.currstat = e2.stateDescription and e2.BRANCH=e1.BRANCH
			ORDER BY e2.stateDescription
			FOR XML PATH ('')
		) as email1,
		(select email + '; ' 
			from #tmpEmailGroupHO e3
			where e1.currstat = e3.stateDescription
			ORDER BY e3.stateDescription
			FOR XML PATH ('')
		) as email2
	from
	#tmpTaskEmail e1
	) main
 
set @ctr = 1
select @max =  MAX(ID) FROM #tmpTaskEmail

 while(@ctr <= @max)
 BEGIN
 SELECT @message = 
	'<html>
		<head><style>body {font-family: arial; font-size: 14px;}</style></head>
 		<body>
			<p>Status doc no <strong>'+docno+'</strong> berubah menjadi <strong>'+currstat+'</strong> dengan detail sebagai berikut :
			<br/>
			<br/>
			<table>
			<tr>
				<td width="19%">Client</td>
				<td width="1%">:&nbsp;</td>
				<td width="80%"><strong>'+clientName+'</strong></td>
			</tr>
			<tr>
				<td>Cabang</td>
				<td>:&nbsp;</td>
				<td><strong>'+em.branch+'</strong></td>
			</tr>
			<tr>
				<td>Supplier</td>
				<td>:&nbsp;</td>
				<td><strong>'+supplName+'</strong></td>
			</tr>
			<tr>
				<td>Tanggal Proses</td>
				<td>:&nbsp;</td>
				<td><strong>'+CAST(TransDt as VARCHAR(50))+'</strong></td>
			</tr>
			<tr>
				<td>Di proses oleh</td>
				<td>:&nbsp;</td>
				<td><strong>'+transby+'</strong></td>
			</tr>
			<tr>
				<td>Status</td>
				<td>:&nbsp;</td>
				<td><strong>'+currstat+'</strong></td>
			</tr>
			</table>
		</body>	  
		</html>'
	,
	@recepient = r.emailRecipient
		FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
		on em.currstat = r.status and em.branch=r.branch
		WHERE em.id = @ctr

	SET @recepient = @recepient + '; eko.cietra@mncgroup.com; liung.hartono@mncgroup.com'
	--SET @recepient = 'liung.hartono@mncgroup.com'
	select @title	= 'iTracking Status Change (' + isnull(clientName,'') + ')' from #tmpTaskEmail where id = @ctr

if(LEN(@message) > 0 OR @message IS NOT NULL)
BEGIN
	 exec [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
			@profile_name	= 'SQLMelisa',
			@recipients		= @recepient,
			@subject		= @title, --'ITracking Status Change Notification',
			@body			= @message,
			@body_format	= 'HTML'

INSERT INTO EMAIL_HIST
 (
KEY_ID,
EMAIL_TYPE,
EMAIL_TO,
MESSAGE,
EMAIL_DT
 )
 SELECT dtlkey,'ITRACKING_HIST', isnull(r.emailRecipient, ''), @message, GETDATE()  FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status 
 WHERE em.id = @ctr
 END
  set @ctr =  @ctr +1
 END

 select * FROM #tmpTaskEmail em JOIN #tmpEmailRecipient r
 on em.currstat = r.status 

DROP TABLE #tmpEmailGroupCabang
DROP TABLE #tmpEmailGroupHO
DROP TABLE #tmpEmailRecipient
DROP TABLE #tmpTaskEmail

---------------------------------------------


GO
/****** Object:  StoredProcedure [dbo].[sp_SSS_SendMail]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_SSS_SendMail]
    @profile_name VARCHAR(100),
    @recipients VARCHAR(1000),
    @copy_recipients VARCHAR(1000),
    @body NVARCHAR(MAX),
    @subject NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    EXEC [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
        @profile_name = @profile_name,
        @recipients = @recipients,
        @copy_recipients = @copy_recipients,
        @body = @body,
        @subject = @subject
END


GO
/****** Object:  StoredProcedure [dbo].[spChangeMitraPass]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[spChangeMitraPass]
@username varchar(50),
@oldpassword varchar(2000),
@newpassword varchar(2000),
@result char(1) OUT,
@message varchar(200) OUT
as

BEGIN
if exists(SELECT '' FROM Mitra where MCode =  @username AND Password = @oldpassword)
BEGIN
	UPDATE Mitra set Password =  @newpassword, LastModifiedBy = @username, LastModifiedTime =  GETDATE() where MCode =  @username
	SET @result = '1'
	SET @message = 'Password berhasil di ubah'
END
ELSE
BEGIN
	SET @result = '0'
	SET @message = 'Password lama anda salah'
END
END
GO
/****** Object:  StoredProcedure [dbo].[spDeleteDocManagementFile]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spDeleteDocManagementFile] 
	@DocKey INT,
	@DeletedBy VARCHAR(20)

AS
BEGIN
	Insert into LogDeleteDocument 
		(Name, Type, Ext, Remarks, FileDoc, AppNo, CreatedBy, CreatedDateTime, DebiturName, AgreeNo, Module, 
		SubType, Branch, FileSize, DeletedBy, [DeletedDate])
	select 
		Name, Type, Ext, Remarks, FileDoc, AppNo, CreatedBy, CreatedDateTime, DebiturName, AgreeNo, Module, 
		SubType, Branch, FileSize, @DeletedBy [DeletedBy], GETDATE() [DeletedDate]  
	from DocumentFile where id = @DocKey

	Delete DocumentFile where id = @DocKey
END

GO
/****** Object:  StoredProcedure [dbo].[spDetailApplicationByProduct]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- exec [dbo].[spDetailApplicationByProduct] 'WEEK',3,2022,'FACTORING','week 2'

CREATE PROCEDURE [dbo].[spDetailApplicationByProduct]
	(
		@ParamType varchar(20),
		@ParamMonth INT,
		@ParamYear INT,
		@ParamProduct varchar(50),
		@ParamValue varchar(50)
	)
AS
BEGIN
	IF @ParamType = 'WEEK'
	BEGIN
		select 
			a.*
		from Application a
		inner join ApplicationDisbursementPlan b on a.docno = b.docno
		inner join GroupingProduct c on a.ObjectPembiayaan = c.leaseObject
		where 1=1
			and b.planyear = @ParamYear
			and b.planmonth = @ParamMonth
			and c.GroupDesc = @ParamProduct
			and b.planweek = @ParamValue
	END
	
END

GO
/****** Object:  StoredProcedure [dbo].[SPGetListDoc]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPGetListDoc]
(
@AgreementNo VARCHAR(50)
)
as
BEGIN

declare @prodfacility varchar(20)
SELECT @prodfacility = PRODUCT_FACILITY_CODE FROM [172.31.215.2\MSSQLSRVGUI].[IFINANCING_GOLIVE].[dbo].[LS_AGREEMENT]  WHERE LsAgree = '@AgreementNo'


IF(@prodfacility = '112')
BEGIN
SELECT distinct SubType as DocType FROM DocumentFile WHERE AgreeNo =  @AgreementNo  AND [TYPE] = 'DOKUMEN UNTUK DEBITUR'
END
ELSE
BEGIN
SELECT distinct SubType as DocType FROM DocumentFile WHERE AgreeNo =  '001221270200011'  AND [TYPE] = 'DOKUMEN UNTUK DEBITUR'
UNION
SELECT 'STARTERPACK'

END


END


GO
/****** Object:  StoredProcedure [dbo].[SpGetPolisInsurance]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SpGetPolisInsurance]
(
@AgreementNo VARCHAR(50),
@DocType VARCHAR(50)
)
as
BEGIN

SELECT AgreeNo, SubType, FileDoc, Ext FROM DocumentFile WHERE AgreeNo =  @AgreementNo AND SubType = @DocType AND [TYPE] = 'DOKUMEN UNTUK DEBITUR'


END


GO
/****** Object:  StoredProcedure [dbo].[spLoginMitra]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[spLoginMitra]
@username varchar(50),
@password varchar(2000)
as

SELECT 
mkey,
mcode,
nama,
tempatlahir,
CONVERT(VARCHAR(10), tanggallahir, 103) as tanggallahir,
[address],
email,
notlp,
hp,
nowhatsapp,
jenismitra,
issubmitra,
isactive,
createdby,
createdDatetime,
lastmodifiedby,
lastmodifiedtime,
contactperson,
npwp,
AktePendirian,
submitra,
branch,
tipemitra,
Provinsi,
KotaKabupaten
FROM Mitra where MCode =  @username and Password =  @password 
GO
/****** Object:  StoredProcedure [dbo].[spSummaryApplicationByProduct]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--exec [dbo].[spSummaryApplicationByProduct] 3, 2022

CREATE PROCEDURE [dbo].[spSummaryApplicationByProduct]
	(
		@ParamMonth INT,
		@ParamYear INT
	)
AS
BEGIN
	select 
		gp.GroupDesc, 
		ISNULL(SUM(sumdt.[Week 1]),0) [Week 1], 
		ISNULL(SUM(sumdt.[Week 2]),0)  [Week 2],
		ISNULL(SUM(sumdt.[Week 3]),0)  [Week 3],
		ISNULL(SUM(sumdt.[Week 4]),0)  [Week 4],
		ISNULL(SUM(sumdt.[Week 5]),0)  [Week 5],
		ISNULL(SUM(sumdt.GrandTotal),0)  [GrandTotal]
	from GroupingProduct gp
	left join(
		select 
			c.GroupDesc,
			SUM(Case when b.PlanWeek = 'week 1' then a.NTF else 0 end) [Week 1],
			SUM(Case when b.PlanWeek = 'week 2' then a.NTF else 0 end) [Week 2],
			SUM(Case when b.PlanWeek = 'week 3' then a.NTF else 0 end) [Week 3],
			SUM(Case when b.PlanWeek = 'week 4' then a.NTF else 0 end) [Week 4],
			SUM(Case when b.PlanWeek = 'week 5' then a.NTF else 0 end) [Week 5],
			SUM(Case when b.PlanWeek IN('week 1','week 2','week 3','week 4','week 5') then a.NTF else 0 end) [GrandTotal]
		from Application a
		inner join ApplicationDisbursementPlan b on a.docno = b.docno
		inner join GroupingProduct c on a.ObjectPembiayaan = c.leaseObject
		where 1=1
			and b.planyear = @ParamYear
			and b.planmonth = @ParamMonth
		group by c.GroupDesc
	) sumdt on gp.GroupDesc = sumdt.GroupDesc
	group by gp.GroupDesc
END

GO
/****** Object:  StoredProcedure [dbo].[spUpdataePlanDisburse]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- exec spUpdataePlanDisburse 'APP/1121/1873',0,0,'week 4'
CREATE PROCEDURE [dbo].[spUpdataePlanDisburse] 
	@ApplicNo VARCHAR(20),
	@ParamMonth INT,
	@ParamYear INT,
	@ParamWeeks VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT * FROM [dbo].[ApplicationDisbursementPlan] WHERE DocNo = @ApplicNo)
	BEGIN
		UPDATE [dbo].[ApplicationDisbursementPlan] SET 
			PlanMonth = @ParamMonth,
			PlanYear = @ParamYear,
			PlanWeek = @ParamWeeks
		WHERE DocNo = @ApplicNo
	END
	ELSE
	BEGIN
		INSERT INTO [dbo].[ApplicationDisbursementPlan] (DocNo, PlanMonth, PlanYear, PlanWeek)
		SELECT @ApplicNo, @ParamMonth, @ParamYear, @ParamWeeks

	END
	

END



GO
/****** Object:  StoredProcedure [dbo].[spUpdatePlanDisbDate]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- exec spUpdatePlanDisbDate 'APP/1121/1875', '2022-04-04'
CREATE PROCEDURE [dbo].[spUpdatePlanDisbDate] 
	@ApplicNo VARCHAR(20),
	@DateDisburse DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @WeekNum VARCHAR(10)
	
	SELECT @WeekNum = 'Week ' + CAST([dbo].[fn_get_week](@DateDisburse) AS varchar(1))

	IF EXISTS(SELECT * FROM [dbo].[ApplicationDisbursementPlan] WHERE DocNo = @ApplicNo)
	BEGIN
		UPDATE [dbo].[ApplicationDisbursementPlan] SET 
			PlanMonth = MONTH(@DateDisburse),
			PlanYear = YEAR(@DateDisburse),
			PlanWeek = @WeekNum
		WHERE DocNo = @ApplicNo
	END
	ELSE
	BEGIN
		INSERT INTO [dbo].[ApplicationDisbursementPlan] (DocNo, PlanMonth, PlanYear, PlanWeek)
		SELECT @ApplicNo, MONTH(@DateDisburse), YEAR(@DateDisburse), @WeekNum

	END
	

END

GO
/****** Object:  StoredProcedure [dbo].[UPDATE_INSERT_MASTER_PLATFON_REIMBUSE]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UPDATE_INSERT_MASTER_PLATFON_REIMBUSE]
(
	@ID BIGINT = NULL,
	@PLATFON_REIMBURSE_ID varchar(50),
	@EMPLOYEE_CODE varchar(10),
	@EMPLOYEE_NAME varchar(255),
	@POSITION_ID bigint,
	@POSITION varchar(255),
	@AREA_CODE bigint=null,
	@AREA varchar(255)=null,
	@BRANCH_CODE bigint=null,
	@BRANCH varchar(255)=null,
	@PLATFON numeric(18,2),
	@IS_ACTIVE INT,
	@USER_ID varchar(50),
	@ACT_DT datetime
)
AS
BEGIN

	IF EXISTS (SELECT PLATFON_REIMBURSE_ID FROM MASTER_PLATFON_REIMBURSE WHERE ID = @ID)
	BEGIN
		UPDATE [dbo].[MASTER_PLATFON_REIMBURSE]
		   SET [PLATFON_REIMBURSE_ID] = @PLATFON_REIMBURSE_ID  
		      ,[EMPLOYEE_CODE] = @EMPLOYEE_CODE
			  ,[EMPLOYEE_NAME] = @EMPLOYEE_NAME
			  ,[POSITION_ID] = @POSITION_ID
			  ,[POSITION] = @POSITION
			  ,[AREA_CODE] = @AREA_CODE
			  ,[AREA] = @AREA
			  ,[BRANCH_CODE] = @BRANCH_CODE
			  ,[BRANCH] = @BRANCH
			  ,[PLATFON] = @PLATFON
			  ,[IS_ACTIVE] = @IS_ACTIVE
			  ,[MOD_BY] = @USER_ID
			  ,[MOD_DT] = @ACT_DT
		 WHERE ID = @ID
	END ELSE BEGIN
		INSERT INTO [dbo].[MASTER_PLATFON_REIMBURSE]
           ([PLATFON_REIMBURSE_ID]
           ,[EMPLOYEE_CODE]
           ,[EMPLOYEE_NAME]
           ,[POSITION_ID]
           ,[POSITION]
           ,[AREA_CODE]
           ,[AREA]
           ,[BRANCH_CODE]
           ,[BRANCH]
           ,[PLATFON]
		   ,[IS_ACTIVE]
           ,[CRE_BY]
           ,[CRE_DT]
           )
		 VALUES
			(@PLATFON_REIMBURSE_ID
			,@EMPLOYEE_CODE
			,@EMPLOYEE_NAME
			,@POSITION_ID
			,@POSITION
			,@AREA_CODE
			,@AREA
			,@BRANCH_CODE
			,@BRANCH
			,@PLATFON
			,@IS_ACTIVE
			,@USER_ID 
			,@ACT_DT
			)
	END
END


GO
/****** Object:  StoredProcedure [dbo].[UPDATE_INSERT_REIMBURSE_OPERATION_DT]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UPDATE_INSERT_REIMBURSE_OPERATION_DT]
@ID	bigint,
@HD_REFFNO varchar(50),
@NOTA_DATE datetime,
@DETAIL_TYPE int,
@AMOUNT numeric(18,2),
@NOTE varchar(255)=null,
@USERID varchar(50),
@ACT_DT datetime
as
begin
	if exists (select ID from [REIMBURSE_OPERATION_DT] where ID=@ID AND HD_REFFNO=@HD_REFFNO)
	begin
		update [dbo].[REIMBURSE_OPERATION_DT] 
			set HD_REFFNO=@HD_REFFNO
			   ,[NOTA_DATE] = @NOTA_DATE
			   ,[DETAIL_TYPE] = @DETAIL_TYPE
			   ,[AMOUNT] = @AMOUNT
			   ,[NOTE] = @NOTE
			   ,[MOD_BY] = @USERID
			   ,[MOD_DT] = @ACT_DT
		where ID=@ID
	end else begin
		INSERT INTO [dbo].[REIMBURSE_OPERATION_DT]
           ([HD_REFFNO]
           ,[NOTA_DATE]
           ,[DETAIL_TYPE]
           ,[AMOUNT]
           ,[NOTE]
           ,[CRE_BY]
           ,[CRE_DT]
           )
		VALUES
           (@HD_REFFNO
			,@NOTA_DATE
			,@DETAIL_TYPE
			,@AMOUNT
			,@NOTE
			,@USERID
			,@ACT_DT
			)
	end

	update [REIMBURSE_OPERATION_HD] 
		set TOTAL = (select SUM(AMOUNT) from [REIMBURSE_OPERATION_DT] where HD_REFFNO = @HD_REFFNO)  
	where REFF_NO = @HD_REFFNO
	
end


GO
/****** Object:  StoredProcedure [dbo].[UPDATE_MASTER_AREA]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[UPDATE_MASTER_AREA]
	@AREA_CODE		BIGINT,
	@DESCRIPTION	VARCHAR(255),
	@IS_ACTIVE		INT,
	@USERID			VARCHAR(50),
	@ACTION_DATE	DATETIME
AS
BEGIN
	IF EXISTS (SELECT AREA_CODE FROM MASTER_AREA WHERE AREA_CODE = @AREA_CODE)
	BEGIN
		UPDATE MASTER_AREA 
			SET		DESCRIPTION = @DESCRIPTION,
					IS_ACTIVE = @IS_ACTIVE,
					MOD_BY = @USERID,
					MOD_DT = @ACTION_DATE
		WHERE AREA_CODE = @AREA_CODE
	END ELSE BEGIN
		INSERT MASTER_AREA ([DESCRIPTION] ,[IS_ACTIVE] ,[CRE_DT] ,[CRE_BY])
		VALUES (@DESCRIPTION, @IS_ACTIVE, @ACTION_DATE, @USERID)
	END
	
END


GO
/****** Object:  StoredProcedure [dbo].[UPDATE_MASTER_POSITION]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[UPDATE_MASTER_POSITION]
	@ROLE			BIGINT,
	@DESCRIPTION	VARCHAR(255),
	@IS_ACTIVE		INT,
	@USERID			VARCHAR(50)
AS
BEGIN
	IF EXISTS (SELECT ROLE FROM MASTER_POSITION WHERE ROLE = @ROLE)
	BEGIN
		UPDATE MASTER_POSITION 
			SET		DESCRIPTION = @DESCRIPTION,
					IS_ACTIVE = @IS_ACTIVE,
					MOD_BY = @USERID,
					MOD_DT = GETDATE()
		WHERE ROLE = @ROLE
	END ELSE BEGIN
		INSERT MASTER_POSITION ([DESCRIPTION] ,[IS_ACTIVE] ,[CRE_DT] ,[CRE_BY])
		VALUES (@DESCRIPTION, @IS_ACTIVE, GETDATE(), @USERID)
	END
	
END

GO
/****** Object:  StoredProcedure [dbo].[UPDATE_REIMBURSE_OPERATION]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UPDATE_REIMBURSE_OPERATION]
	@REFF_NO	VARCHAR(50),
	@STATUS		VARCHAR(50),
	@USERID		VARCHAR(50),
	@ACT_DT		DATETIME
AS
BEGIN
	DECLARE	@REMAIND		NUMERIC(18,2),
			@AMOUNT_REIMB	NUMERIC(18,2),
			@REQUESTER		VARCHAR(50)
	
	SELECT @AMOUNT_REIMB = TOTAL, @REQUESTER = PAY_TO FROM REIMBURSE_OPERATION_HD WHERE REFF_NO = @REFF_NO
	SELECT @REMAIND=REMAIND_PLATFON FROM MASTER_PLATFON_REIMBURSE WHERE PLATFON_REIMBURSE_ID = @REQUESTER AND IS_ACTIVE = 1

	IF((ISNULL(@REMAIND,0) - ISNULL(@AMOUNT_REIMB,0)) < 0) 
	BEGIN
		raiserror('Nominal melebihi platfon!!!', 16, 1)
        return
	END ELSE
	BEGIN
		UPDATE REIMBURSE_OPERATION_HD SET STATUS=@STATUS, MOD_BY = @USERID, MOD_DT=@ACT_DT WHERE REFF_NO = @REFF_NO
		UPDATE MASTER_PLATFON_REIMBURSE SET REMAIND_PLATFON = (@REMAIND - @AMOUNT_REIMB) WHERE PLATFON_REIMBURSE_ID = @REQUESTER AND IS_ACTIVE = 1
		
		INSERT INTO [dbo].[REIMBURSE_OPERATION_TRX] ([HD_REFFNO] ,[STATUS] ,[CRE_BY] ,[CRE_DT])
		VALUES (@REFF_NO,@STATUS, @USERID, @ACT_DT)
	END
END





GO
/****** Object:  StoredProcedure [dbo].[UPDATE_REIMBURSE_OPERATION_SCHEME]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UPDATE_REIMBURSE_OPERATION_SCHEME]
	@REFF_NO	VARCHAR(50),
	@NOTE		VARCHAR(max),
	@STATUS		VARCHAR(50),
	@USERID		VARCHAR(50),
	@ACT_DT		DATETIME
AS
BEGIN
	DECLARE
		@MAX_SEQ			INT,
		@DECISITION_STATE	VARCHAR(50),
		@IS_DECISION		VARCHAR(1),
		@LAST_EMP			VARCHAR(50)
	
	SELECT @MAX_SEQ = MAX(SEQ) from SCHEME_APPROVAL_REIMBURSE_TRX WHERE HD_REFFNO = @REFF_NO
	SELECT @DECISITION_STATE = DECISION_STATE, @IS_DECISION = IS_DECISION FROM SCHEME_APPROVAL_REIMBURSE_TRX WHERE HD_REFFNO = @REFF_NO AND SEQ = @MAX_SEQ - 1
	SELECT @LAST_EMP = EMPLOYEE_CODE FROM SCHEME_APPROVAL_REIMBURSE_TRX WHERE HD_REFFNO = @REFF_NO AND SEQ = @MAX_SEQ
	
	IF (@STATUS = 'APPROVED')
	BEGIN
		SET @IS_DECISION = 'T'

		IF (@STATUS = 'APPROVED' AND @DECISITION_STATE = 'APPROVED' AND @IS_DECISION = 'T' AND @LAST_EMP = @USERID)
		BEGIN
			UPDATE REIMBURSE_OPERATION_HD SET STATUS='DONE', MOD_BY = @USERID, MOD_DT=@ACT_DT where REFF_NO = @REFF_NO
			SET @IS_DECISION = 'T'

		END 		
	END ELSE IF (@STATUS = 'REJECTED' AND (SELECT COUNT(EMPLOYEE_CODE) FROM [SCHEME_APPROVAL_REIMBURSE_TRX] WHERE [HD_REFFNO] = @REFF_NO AND EMPLOYEE_CODE = @USERID) > 0) 
	BEGIN
		--select 'cek 1'
		UPDATE REIMBURSE_OPERATION_HD SET STATUS=@STATUS, MOD_BY = @USERID, MOD_DT=@ACT_DT where REFF_NO = @REFF_NO
		SET @IS_DECISION = 'T'

		DECLARE		@TOTAL			NUMERIC(18,2),
					@REQUESTER_ID	VARCHAR(50),
					@AREA			BIGINT,
					@BRANCH			BIGINT,
					@REMAIND		NUMERIC(18,2),
					@PLATFON		NUMERIC(18,2)
							
		SELECT @TOTAL = TOTAL, @REQUESTER_ID = PAY_TO  FROM REIMBURSE_OPERATION_HD WHERE REFF_NO = @REFF_NO
		SELECT @REMAIND = REMAIND_PLATFON, @PLATFON = PLATFON FROM MASTER_PLATFON_REIMBURSE where PLATFON_REIMBURSE_ID = @REQUESTER_ID AND IS_ACTIVE = 1

		IF((@TOTAL+@REMAIND) <= @PLATFON)
		BEGIN
			--select 'cek 2'
			UPDATE MASTER_PLATFON_REIMBURSE SET REMAIND_PLATFON = @TOTAL+@REMAIND, MOD_DT=@ACT_DT, MOD_BY=@USERID WHERE PLATFON_REIMBURSE_ID=@REQUESTER_ID AND IS_ACTIVE = 1
		END
	END
	
	
	UPDATE [dbo].[SCHEME_APPROVAL_REIMBURSE_TRX]
	   SET [IS_DECISION] = @IS_DECISION
		  ,[DECISION_STATE] = @STATUS
		  ,[DECISION_DATE] = @ACT_DT --@REFF_NO
		  ,[DECISION_NOTE] = @NOTE
		  ,[MOD_BY] = @USERID
		  ,[MOD_DT] = @ACT_DT
	 WHERE [HD_REFFNO] = @REFF_NO AND EMPLOYEE_CODE = @USERID
	
	INSERT INTO [dbo].[REIMBURSE_OPERATION_TRX] ([HD_REFFNO],[STATUS],[CRE_BY],[CRE_DT])
    VALUES (@REFF_NO,@STATUS, @USERID, @ACT_DT)
END


GO
/****** Object:  StoredProcedure [dbo].[UploadDocument_GetJtrust]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--exec UploadDocument_GetJtrust
CREATE PROCEDURE [dbo].[UploadDocument_GetJtrust]
AS
BEGIN
	SELECT [ID],[Name],[Type],[Ext],[Remarks],[AppNo],[CreatedBy],[CreatedDateTime],[DebiturName],[AgreeNo],[Module],[SubType],[Branch] FROM [dbo].[DocumentFile] 
                                                                    where AppNo IN ('0010APP201000037',
                                                                    '0004APP201000025',
                                                                    '0009APP201100040',
                                                                    '0014APP210200006',
                                                                    '0008APP210100001',
                                                                    '0015APP201100011',
                                                                    '0015APP210100001',
                                                                    '0015APP210100004',
                                                                    '0011APP210200012',
                                                                    '0009APP201100041',
                                                                    '0009APP201100042',
                                                                    '0007APP210200015',
                                                                    '0007APP210100003',
                                                                    '0008APP201000025',
                                                                    '0005APP210300015',
                                                                    '0007APP210200021',
                                                                    '0007APP210200013',
                                                                    '0007APP210300027',
                                                                    '0008APP210300015',
                                                                    '0008APP210300012',
                                                                    '0008APP210300013',
                                                                    '0014APP210300011',
                                                                    '0014APP210300012',
                                                                    '0007APP210100001',
                                                                    '0008APP210300016',
                                                                    '0014APP210400018',
                                                                    '0010APP210400029',
                                                                    '0009APP210400018',
                                                                    '0009APP210300017',
                                                                    '0005APP210200012',
                                                                    '0016APP210300047',
                                                                    '0003APP210400027',
                                                                    '0003APP210300006',
                                                                    '0008APP210400017',
                                                                    '0008APP210400021',
                                                                    '0009APP210300016',
                                                                    '0010APP210400033',
                                                                    '0011APP210400038',
                                                                    '0010APP210400031',
                                                                    '0011APP210300031',
                                                                    '0007APP210300033',
                                                                    '0009APP210400022',
                                                                    '0010APP210400034',
                                                                    '0010APP210400037',
                                                                    '0007APP210500043',
                                                                    '0005APP210400023',
                                                                    '0007APP210400038',
                                                                    '0005APP210500031',
                                                                    '0008APP210500026',
                                                                    '0008APP210500024',
                                                                    '0010APP210400039',
                                                                    '0014APP210500023',
                                                                    '0004APP210500034',
                                                                    '0010APP210400025',
                                                                    '0007APP210400039',
                                                                    '0009APP210500030',
                                                                    '0003APP210400025',
                                                                    '0011APP210400039',
                                                                    '0010APP210500041',
                                                                    '0015APP210500035',
                                                                    '0020APP210600015',
                                                                    '0012APP210600027',
                                                                    '0016APP210500054',
                                                                    '0007APP210500044',
                                                                    '0011APP210600053',
                                                                    '0014APP210600029',
                                                                    '0014APP210300014',
                                                                    '0016APP210200033',
                                                                    '0003APP210700045',
                                                                    '0005APP210400022',
                                                                    '0015APP210700041',
                                                                    '0016APP210500053',
                                                                    '0020APP210500010',
                                                                    '0007APP211000088',
                                                                    '0011APP210900075',
                                                                    '0007APP210900084',
                                                                    '0020APP211000037',
                                                                    '0010APP211000103',
                                                                    '0014APP211000050',
                                                                    '0010APP210900084',
                                                                    '0011APP211200090',
                                                                    '0003APP210700047',
                                                                    '0016APP211100085',
                                                                    '0016APP211200087',
                                                                    '0020APP211100043',
                                                                    '0020APP211200044',
                                                                    '0010APP210900090',
                                                                    '0010APP211200124',
                                                                    '0012APP211200067',
                                                                    '0010APP211200121',
                                                                    '0020APP211100042',
                                                                    '0006APP210700032',
                                                                    '0007APP211200114',
                                                                    '0008APP211200050',
                                                                    '0008APP210700040',
                                                                    '0011APP220100003',
                                                                    '0012APP211100064',
                                                                    '0010APP220200013',
                                                                    '0009APP220100010',
                                                                    '0013APP220100003',
                                                                    '0013APP220100004',
                                                                    '0014APP220200011',
                                                                    '0004APP220200016',
                                                                    '0010APP211000104',
                                                                    '0012APP220200008',
                                                                    '0014APP220200008',
                                                                    '0015APP220100002') 
                                                                    and type IN ('DOKUMEN LEGALITAS - BADAN USAHA','DOKUMEN LEGALITAS - PERORANGAN', 'DOKUMEN KREDIT - PERSETUJUAN PEMBIAYAAN','DOKUMEN KREDIT - LAINNYA', 'DOKUMEN KONTRAK')
                                                                    ORDER BY CreatedDateTime DESC
END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_get_week]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_get_week]
(
	@ParamDate datetime
)
returns int
begin
	declare @output int
	SET @output = (DATEPART(week, @ParamDate) - DATEPART(week, DATEADD(day, 1, EOMONTH(@ParamDate, -1)))) + 1;
	return @output
end




GO
/****** Object:  UserDefinedFunction [dbo].[fn_replace_string_newline]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_replace_string_newline](@str VARCHAR(max))
RETURNS VARCHAR(max)
AS
BEGIN
	SET @str = REPLACE(REPLACE(REPLACE(dbo.udf_StripHTML(CAST(@str AS VARCHAR(max))), char(9), ''), CHAR(13), ''), CHAR(10), '')
	RETURN @str
END

GO
/****** Object:  UserDefinedFunction [dbo].[udf_StripHTML]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_StripHTML]
(@HTMLText VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
DECLARE @Start INT
DECLARE @End INT
DECLARE @Length INT
SET @Start = CHARINDEX('<',@HTMLText)
SET @End = CHARINDEX('>',@HTMLText,CHARINDEX('<',@HTMLText))
SET @Length = (@End - @Start) + 1
WHILE @Start > 0
AND @End > 0
AND @Length > 0
BEGIN
SET @HTMLText = STUFF(@HTMLText,@Start,@Length,'')
SET @Start = CHARINDEX('<',@HTMLText)
SET @End = CHARINDEX('>',@HTMLText,CHARINDEX('<',@HTMLText))
SET @Length = (@End - @Start) + 1
END
RETURN LTRIM(RTRIM(@HTMLText))
END

GO
/****** Object:  Table [dbo].[AccessRight]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessRight](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[NIK] [nvarchar](20) NOT NULL,
	[CMDid] [nvarchar](20) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Application]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Application](
	[DocKey] [int] NOT NULL,
	[DocNo] [nvarchar](20) NOT NULL,
	[DocDate] [datetime] NOT NULL,
	[DocumentType] [nvarchar](50) NOT NULL,
	[Note] [nvarchar](max) NULL,
	[Remark1] [nvarchar](max) NULL,
	[Remark2] [nvarchar](max) NULL,
	[Remark3] [nvarchar](max) NULL,
	[Remark4] [nvarchar](max) NULL,
	[Branch] [nvarchar](50) NULL,
	[ObjectPembiayaan] [nvarchar](50) NULL,
	[Facility] [nvarchar](50) NULL,
	[JenisPengikatan] [nvarchar](50) NULL,
	[Package] [nvarchar](50) NULL,
	[CIF] [nvarchar](10) NULL,
	[ClientName] [nvarchar](100) NULL,
	[SupplierName] [nvarchar](100) NULL,
	[SupplierBranch] [nvarchar](100) NULL,
	[MarketingSupplier] [nvarchar](100) NULL,
	[OTR] [numeric](18, 2) NOT NULL,
	[NTF] [numeric](18, 2) NOT NULL,
	[DP] [numeric](18, 2) NOT NULL,
	[Tenor] [numeric](18, 0) NOT NULL,
	[EffRate] [numeric](18, 2) NOT NULL,
	[Status] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](20) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](20) NULL,
	[LastModifiedTime] [datetime] NULL,
	[Submit] [nvarchar](1) NULL,
	[SubmitBy] [nvarchar](20) NULL,
	[SubmitDateTime] [datetime] NULL,
	[Cancelled] [nvarchar](1) NULL,
	[CancelledDateTime] [datetime] NULL,
	[CancelledType] [nvarchar](100) NULL,
	[CancelledNote] [nvarchar](100) NULL,
	[OnHold] [nvarchar](1) NULL,
	[AgreementNo] [nvarchar](20) NULL,
	[PlanDisburseDate] [datetime] NULL,
 CONSTRAINT [PK_Application] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Application_20211210]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Application_20211210](
	[DocKey] [int] NOT NULL,
	[DocNo] [nvarchar](20) NOT NULL,
	[DocDate] [datetime] NOT NULL,
	[DocumentType] [nvarchar](50) NOT NULL,
	[Note] [nvarchar](max) NULL,
	[Remark1] [nvarchar](max) NULL,
	[Remark2] [nvarchar](max) NULL,
	[Remark3] [nvarchar](max) NULL,
	[Remark4] [nvarchar](max) NULL,
	[Branch] [nvarchar](50) NULL,
	[ObjectPembiayaan] [nvarchar](50) NULL,
	[Facility] [nvarchar](50) NULL,
	[JenisPengikatan] [nvarchar](50) NULL,
	[Package] [nvarchar](50) NULL,
	[CIF] [nvarchar](10) NULL,
	[ClientName] [nvarchar](100) NULL,
	[SupplierName] [nvarchar](100) NULL,
	[SupplierBranch] [nvarchar](100) NULL,
	[MarketingSupplier] [nvarchar](100) NULL,
	[OTR] [numeric](18, 2) NOT NULL,
	[NTF] [numeric](18, 2) NOT NULL,
	[DP] [numeric](18, 2) NOT NULL,
	[Tenor] [numeric](18, 0) NOT NULL,
	[EffRate] [numeric](18, 2) NOT NULL,
	[Status] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](20) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](20) NULL,
	[LastModifiedTime] [datetime] NULL,
	[Submit] [nvarchar](1) NULL,
	[SubmitBy] [nvarchar](20) NULL,
	[SubmitDateTime] [datetime] NULL,
	[Cancelled] [nvarchar](1) NULL,
	[CancelledDateTime] [datetime] NULL,
	[CancelledType] [nvarchar](100) NULL,
	[CancelledNote] [nvarchar](100) NULL,
	[OnHold] [nvarchar](1) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationCommentHistory]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationCommentHistory](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[SourceDocKey] [int] NULL,
	[DocNo] [nvarchar](20) NULL,
	[CommentBy] [nvarchar](20) NULL,
	[CommentNote] [nvarchar](max) NULL,
	[CommentDate] [datetime] NULL,
	[DistDate] [datetime] NULL,
 CONSTRAINT [PK_ApplicationCommentHistory] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationDetail]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationDetail](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NOT NULL,
	[Seq] [int] NOT NULL,
	[Condition] [nvarchar](50) NULL,
	[ItemDescription] [nvarchar](max) NULL,
	[Year] [numeric](18, 0) NULL,
	[UnitPrice] [numeric](18, 2) NULL,
	[Qty] [numeric](18, 2) NULL,
	[SubTotal] [numeric](18, 2) NULL,
	[AssetTypeDetail] [nvarchar](50) NULL,
 CONSTRAINT [PK_ApplicationDetail] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationDetail_temp]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationDetail_temp](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NOT NULL,
	[Seq] [int] NOT NULL,
	[Condition] [nvarchar](50) NULL,
	[ItemDescription] [nvarchar](max) NULL,
	[Year] [numeric](18, 0) NULL,
	[UnitPrice] [numeric](18, 2) NULL,
	[Qty] [numeric](18, 2) NULL,
	[SubTotal] [numeric](18, 2) NULL,
	[AssetTypeDetail] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationDisbursementPlan]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ApplicationDisbursementPlan](
	[DocNo] [varchar](20) NULL,
	[PlanMonth] [int] NULL,
	[PlanYear] [int] NULL,
	[PlanWeek] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ApplicationHistory]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationHistory](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[Status] [nvarchar](50) NULL,
	[TransByID] [nvarchar](20) NULL,
	[TransBy] [nvarchar](20) NULL,
	[TransDate] [datetime] NULL,
	[DiffTime] [int] NULL,
	[FromStatus] [nvarchar](50) NULL,
 CONSTRAINT [PK_ApplicationHistory2] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationOPLCommentHistory]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationOPLCommentHistory](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocNo] [nvarchar](20) NULL,
	[CommentBy] [nvarchar](100) NULL,
	[CommentNote] [nvarchar](max) NULL,
	[CommentDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationSyariahCommentHistory]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationSyariahCommentHistory](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocNo] [nvarchar](20) NULL,
	[CommentBy] [nvarchar](20) NULL,
	[CommentNote] [nvarchar](max) NULL,
	[CommentDate] [datetime] NULL,
 CONSTRAINT [PK_ApplicationSyariahCommentHistory] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationWorkflowAccess]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationWorkflowAccess](
	[StateDescription] [nvarchar](50) NULL,
	[GroupAccessCode] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationWorkflowAccess_20230314]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationWorkflowAccess_20230314](
	[StateDescription] [nvarchar](50) NULL,
	[GroupAccessCode] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationWorkflowScheme]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationWorkflowScheme](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Seq] [int] NOT NULL,
	[StateCode] [nvarchar](10) NOT NULL,
	[StateDescription] [nvarchar](50) NOT NULL,
	[CanCam] [nvarchar](1) NULL,
	[CanReturn] [nvarchar](1) NULL,
	[ReleaseAccess] [nvarchar](50) NULL,
 CONSTRAINT [PK_ApplicationWorkflowSchemeNEW] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationWorkflowScheme_20230314]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationWorkflowScheme_20230314](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Seq] [int] NOT NULL,
	[StateCode] [nvarchar](10) NOT NULL,
	[StateDescription] [nvarchar](50) NOT NULL,
	[CanCam] [nvarchar](1) NULL,
	[CanReturn] [nvarchar](1) NULL,
	[ReleaseAccess] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationWorkflowSchemeBackup]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationWorkflowSchemeBackup](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Seq] [int] NOT NULL,
	[StateCode] [nvarchar](10) NOT NULL,
	[StateDescription] [nvarchar](50) NOT NULL,
	[CanCam] [nvarchar](1) NULL,
	[CanReturn] [nvarchar](1) NULL,
	[ReleaseAccess] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[APPROVE_REIMBURSE_DT]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[APPROVE_REIMBURSE_DT](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ROLE_DT_CODE] [varchar](50) NOT NULL,
	[ROLE_HD_CODE] [varchar](50) NOT NULL,
	[LEVEL] [int] NOT NULL,
	[POSITION_CODE] [bigint] NOT NULL,
	[POSITION] [varchar](255) NOT NULL,
	[IS_ACTIVE] [int] NOT NULL,
	[CRE_BY] [varchar](50) NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[MOD_BY] [varchar](50) NULL,
	[MOD_DT] [datetime] NULL,
 CONSTRAINT [PK_APPROVE_REIMBURSE_DT] PRIMARY KEY CLUSTERED 
(
	[ROLE_DT_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[APPROVE_REIMBURSE_HD]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[APPROVE_REIMBURSE_HD](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ROLE_CODE] [varchar](50) NOT NULL,
	[DESCRIPTION] [varchar](255) NOT NULL,
	[IS_ACTIVE] [int] NOT NULL,
	[CRE_BY] [varchar](50) NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[MOD_BY] [varchar](50) NULL,
	[MOD_DATE] [datetime] NULL,
	[POSITION_ID] [bigint] NOT NULL,
 CONSTRAINT [PK_APPROVE_REIMBURSE_HD] PRIMARY KEY CLUSTERED 
(
	[ROLE_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CabinetDetail]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CabinetDetail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[CabinetNo] [varchar](20) NULL,
	[IsActive] [int] NULL,
	[ModActiveBy] [varchar](20) NULL,
	[ModActiveDate] [datetime] NULL,
	[CreatedBy] [varchar](20) NULL,
	[CreatedDate] [datetime] NULL,
	[TanggalJalan] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[districts]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[districts](
	[id] [char](7) NOT NULL,
	[regency_id] [char](4) NOT NULL,
	[name] [varchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DocFilebackup]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DocFilebackup](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](150) NULL,
	[Type] [nvarchar](50) NULL,
	[Ext] [nvarchar](5) NULL,
	[Remarks] [nvarchar](max) NULL,
	[FileDoc] [varbinary](max) NULL,
	[AppNo] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[DebiturName] [nvarchar](100) NULL,
	[AgreeNo] [nvarchar](50) NULL,
	[Module] [nvarchar](20) NULL,
	[MemoNo] [nvarchar](50) NULL,
	[SubType] [nvarchar](250) NULL,
	[Branch] [nvarchar](250) NULL,
	[FileSize] [nvarchar](20) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DocNoFormat]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocNoFormat](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Format] [nvarchar](20) NOT NULL,
	[NextNo] [int] NOT NULL,
	[DocType] [nvarchar](20) NOT NULL,
	[OneMonthOneSet] [nvarchar](1) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DOCUMENT_UPLOAD_RBS]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DOCUMENT_UPLOAD_RBS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[HD_REFFNO] [varchar](50) NOT NULL,
	[TYPE] [varchar](50) NULL,
	[FILENAME] [varchar](255) NOT NULL,
	[EXT] [varchar](5) NOT NULL,
	[NOTES] [varchar](max) NULL,
	[FILESIZE] [varchar](50) NOT NULL,
	[FILEDOC] [varbinary](max) NOT NULL,
	[CRE_BY] [varchar](50) NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[MOD_BY] [varchar](50) NULL,
	[MOD_DT] [datetime] NULL,
 CONSTRAINT [PK_DOCUMENT_UPLOAD_RBS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DocumentAdditional]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentAdditional](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](250) NULL,
 CONSTRAINT [PK_DocumentAdditional] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DocumentFile]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DocumentFile](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](150) NULL,
	[Type] [nvarchar](50) NULL,
	[Ext] [nvarchar](5) NULL,
	[Remarks] [nvarchar](max) NULL,
	[FileDoc] [varbinary](max) NULL,
	[AppNo] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[DebiturName] [nvarchar](100) NULL,
	[AgreeNo] [nvarchar](50) NULL,
	[Module] [nvarchar](20) NULL,
	[MemoNo] [nvarchar](50) NULL,
	[SubType] [nvarchar](250) NULL,
	[Branch] [nvarchar](250) NULL,
	[FileSize] [nvarchar](20) NULL,
 CONSTRAINT [PK_DocumentFile] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DocumentFile_backup]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DocumentFile_backup](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](150) NULL,
	[Type] [nvarchar](50) NULL,
	[Ext] [nvarchar](5) NULL,
	[Remarks] [nvarchar](max) NULL,
	[FileDoc] [varbinary](max) NULL,
	[AppNo] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[DebiturName] [nvarchar](100) NULL,
	[AgreeNo] [nvarchar](50) NULL,
	[Module] [nvarchar](20) NULL,
	[MemoNo] [nvarchar](50) NULL,
	[SubType] [nvarchar](250) NULL,
	[Branch] [nvarchar](250) NULL,
	[FileSize] [nvarchar](20) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DocumentFile20220125]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DocumentFile20220125](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](150) NULL,
	[Type] [nvarchar](50) NULL,
	[Ext] [nvarchar](5) NULL,
	[Remarks] [nvarchar](max) NULL,
	[FileDoc] [varbinary](max) NULL,
	[AppNo] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[DebiturName] [nvarchar](100) NULL,
	[AgreeNo] [nvarchar](50) NULL,
	[Module] [nvarchar](20) NULL,
	[MemoNo] [nvarchar](50) NULL,
	[SubType] [nvarchar](250) NULL,
	[Branch] [nvarchar](250) NULL,
	[FileSize] [nvarchar](20) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DocumentMandatory]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentMandatory](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](250) NULL,
 CONSTRAINT [PK_DocumentMandatory] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DocumentUploadSPD]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DocumentUploadSPD](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[Type] [nvarchar](50) NULL,
	[Ext] [nvarchar](5) NULL,
	[Notes] [nvarchar](max) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[FileSize] [nvarchar](50) NULL,
	[FileDoc] [varbinary](max) NULL,
	[SPDNo] [nvarchar](50) NULL,
 CONSTRAINT [PK_DocumentUploadSPD] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[EMAIL_HIST]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[EMAIL_HIST](
	[EMAIL_HIST_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[KEY_ID] [bigint] NOT NULL,
	[EMAIL_TYPE] [varchar](50) NOT NULL,
	[EMAIL_TO] [varchar](2000) NOT NULL,
	[MESSAGE] [varchar](max) NOT NULL,
	[EMAIL_DT] [datetime] NOT NULL,
 CONSTRAINT [PK_EMAIL_HIST] PRIMARY KEY CLUSTERED 
(
	[EMAIL_HIST_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[EmergencyContactInfo]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[EmergencyContactInfo](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[applicno] [varchar](20) NULL,
	[nama_sumber_informasi] [varchar](100) NULL,
	[jenis_kelamin] [varchar](2) NULL,
	[keterangan_nama_lengkap] [varchar](20) NULL,
	[no_telp] [varchar](20) NULL,
	[relasi] [varchar](30) NULL,
	[keterangan_alamat_SI] [varchar](20) NULL,
	[keterangan_alamat_debitur] [varchar](20) NULL,
	[cr_user] [varchar](50) NULL,
	[cr_date] [datetime] NULL,
	[md_user] [varchar](50) NULL,
	[md_date] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[GlobalParam]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GlobalParam](
	[isParam] [char](1) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[GroupingProduct]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GroupingProduct](
	[GroupID] [int] IDENTITY(1,1) NOT NULL,
	[GroupDesc] [varchar](100) NULL,
	[LeaseObject] [varchar](100) NULL,
 CONSTRAINT [PK_GroupingProduct] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InsuranceCoverage]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InsuranceCoverage](
	[Code] [int] IDENTITY(1,1) NOT NULL,
	[CoverageDesc] [nvarchar](250) NULL,
	[IsActive] [nvarchar](1) NULL,
 CONSTRAINT [PK_InsuranceCoverage] PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[InsuranceMaskapai]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InsuranceMaskapai](
	[Code] [int] IDENTITY(1,1) NOT NULL,
	[NamaMaskapai] [nvarchar](150) NULL,
	[IsActive] [nvarchar](1) NULL,
 CONSTRAINT [PK_InsuranceMaskapai] PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LateChargesWaive]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LateChargesWaive](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[DocNo] [nvarchar](20) NOT NULL,
	[DocDate] [datetime] NOT NULL,
	[RefNo] [nvarchar](20) NOT NULL,
	[LateChargesAmount] [money] NOT NULL,
	[WaiveAmount] [money] NOT NULL,
	[Client] [nvarchar](200) NOT NULL,
	[Remark1] [nvarchar](max) NULL,
	[Remark2] [nvarchar](max) NULL,
	[Remark3] [nvarchar](max) NULL,
	[Remark4] [nvarchar](max) NULL,
	[Cancelled] [nvarchar](1) NOT NULL,
	[Status] [nvarchar](20) NOT NULL,
	[CreatedBy] [nvarchar](20) NOT NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[SubmitBy] [nvarchar](20) NULL,
	[SubmitDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](20) NULL,
	[LastModifiedDateTime] [datetime] NULL,
 CONSTRAINT [PK_LateChargesWaive] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LateChargesWaiveDetail]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LateChargesWaiveDetail](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[AgreementNo] [nvarchar](40) NULL,
	[DR_CR] [decimal](18, 2) NULL,
	[Periode] [decimal](18, 0) NULL,
	[WaiveAmt] [decimal](18, 2) NULL,
 CONSTRAINT [PK_LateChargesWaiveDetail] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LIST_MITRA_REFID]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LIST_MITRA_REFID](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MCODE] [varchar](50) NULL,
	[REFID] [varchar](255) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LIST_REFID]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LIST_REFID](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[APPLICNO] [varchar](255) NULL,
	[REFID] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LogDeleteDocument]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LogDeleteDocument](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](150) NULL,
	[Type] [nvarchar](50) NULL,
	[Ext] [nvarchar](5) NULL,
	[Remarks] [nvarchar](max) NULL,
	[FileDoc] [varbinary](max) NULL,
	[AppNo] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[DebiturName] [nvarchar](100) NULL,
	[AgreeNo] [nvarchar](50) NULL,
	[Module] [nvarchar](20) NULL,
	[MemoNo] [nvarchar](50) NULL,
	[SubType] [nchar](250) NULL,
	[Branch] [varchar](100) NULL,
	[FileSize] [nvarchar](50) NULL,
	[DeletedBy] [varchar](20) NULL,
	[DeletedDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MASTER_AREA]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MASTER_AREA](
	[AREA_CODE] [bigint] IDENTITY(1000,1) NOT NULL,
	[DESCRIPTION] [varchar](255) NOT NULL,
	[IS_ACTIVE] [int] NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[CRE_BY] [varchar](100) NOT NULL,
	[MOD_DT] [datetime] NULL,
	[MOD_BY] [varchar](100) NULL,
 CONSTRAINT [PK_MASTER_AREA] PRIMARY KEY CLUSTERED 
(
	[AREA_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MASTER_BRANCH]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MASTER_BRANCH](
	[id] [bigint] IDENTITY(1000,1) NOT NULL,
	[AREA_CODE] [bigint] NOT NULL,
	[DESCRIPTION] [varchar](255) NOT NULL,
	[IS_ACTIVE] [int] NOT NULL,
	[CRE_BY] [varchar](100) NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[MOD_BY] [varchar](100) NULL,
	[MOD_DT] [datetime] NULL,
	[BRANCH_CODE_SMILE] [nvarchar](6) NULL,
 CONSTRAINT [PK_MASTER_BRANCH] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Master_Document_Kontrak]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Master_Document_Kontrak](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Jenis_Client] [varchar](255) NOT NULL,
	[Jenis_Pembiayaan] [varchar](255) NOT NULL,
	[Tujuan_Pembiayaan] [varchar](255) NOT NULL,
	[Purpose_Kode] [varchar](10) NOT NULL,
	[Jenis_Dokumen] [varchar](255) NOT NULL,
	[Nomor_Urut] [int] NOT NULL,
	[Nama_Dokumen] [varchar](255) NOT NULL,
	[Keterangan] [varchar](500) NULL,
 CONSTRAINT [PK_Master_Document_Kontrak] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MASTER_PLATFON_REIMBURSE]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[MASTER_PLATFON_REIMBURSE](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[PLATFON_REIMBURSE_ID] [varchar](50) NOT NULL,
	[EMPLOYEE_CODE] [varchar](10) NOT NULL,
	[EMPLOYEE_NAME] [varchar](255) NOT NULL,
	[POSITION_ID] [bigint] NOT NULL,
	[POSITION] [varchar](255) NOT NULL,
	[AREA_CODE] [bigint] NULL,
	[AREA] [varchar](255) NULL,
	[BRANCH_CODE] [bigint] NULL,
	[BRANCH] [varchar](255) NULL,
	[PLATFON] [numeric](18, 2) NULL,
	[CRE_BY] [varchar](50) NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[MOD_BY] [varchar](50) NULL,
	[MOD_DT] [datetime] NULL,
	[REMAIND_PLATFON] [numeric](18, 2) NULL,
	[IS_ACTIVE] [int] NULL,
 CONSTRAINT [PK_MASTER_PLATFON_REIMBURSE] PRIMARY KEY CLUSTERED 
(
	[PLATFON_REIMBURSE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MASTER_POSITION]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MASTER_POSITION](
	[ROLE] [bigint] IDENTITY(1000,1) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[IS_ACTIVE] [int] NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[CRE_BY] [varchar](100) NOT NULL,
	[MOD_DT] [datetime] NULL,
	[MOD_BY] [varchar](100) NULL,
 CONSTRAINT [PK_MASTER_POSITION] PRIMARY KEY CLUSTERED 
(
	[ROLE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MASTER_USER]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MASTER_USER](
	[USER_ID] [nvarchar](20) NOT NULL,
	[USER_NAME] [nvarchar](50) NOT NULL,
	[USER_PASSWORD] [nvarchar](32) NULL,
	[LAST_LOGIN_DATE] [datetime] NULL,
	[IS_ACTIVE_FLAG] [nvarchar](1) NOT NULL,
	[PASSWORD_APPROVAL] [nvarchar](32) NULL,
	[PASSWORD_EXP_DATE] [datetime] NULL,
	[CRE_DATE] [datetime] NOT NULL,
	[CRE_BY] [nvarchar](15) NOT NULL,
	[CRE_IP_ADDRESS] [nvarchar](15) NOT NULL,
	[MOD_DATE] [datetime] NOT NULL,
	[MOD_BY] [nvarchar](15) NOT NULL,
	[MOD_IP_ADDRESS] [nvarchar](15) NOT NULL,
 CONSTRAINT [PK_MASTER_USER_1] PRIMARY KEY CLUSTERED 
(
	[USER_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MasterBebanCabang]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MasterBebanCabang](
	[MasterBebanCabangId] [bigint] IDENTITY(1,1) NOT NULL,
	[OfficeCode] [varchar](20) NOT NULL,
	[OfficeName] [varchar](50) NOT NULL,
	[BebanAmt] [numeric](17, 2) NOT NULL,
	[UsrCrt] [varchar](20) NOT NULL,
	[DtmCrt] [datetime] NOT NULL,
	[UsrUpd] [varchar](20) NOT NULL,
	[DtmUpd] [datetime] NOT NULL,
 CONSTRAINT [PK_MasterBebanCabang] PRIMARY KEY CLUSTERED 
(
	[MasterBebanCabangId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MasterBiayaTunjangan]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MasterBiayaTunjangan](
	[id_tunjangan] [bigint] IDENTITY(1,1) NOT NULL,
	[id_jabatan] [bigint] NULL,
	[tunjangan_detail] [varchar](100) NULL,
	[nominal] [decimal](18, 2) NULL,
	[keterangan] [varchar](50) NULL,
 CONSTRAINT [PK_MasterBiayaTunjangan] PRIMARY KEY CLUSTERED 
(
	[id_tunjangan] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MasterBiayaTunjangan_20230302]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MasterBiayaTunjangan_20230302](
	[id_tunjangan] [bigint] IDENTITY(1,1) NOT NULL,
	[id_jabatan] [bigint] NULL,
	[tunjangan_detail] [varchar](100) NULL,
	[nominal] [decimal](18, 2) NULL,
	[keterangan] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MasterBiayaTunjangan_BACKUP]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MasterBiayaTunjangan_BACKUP](
	[id_tunjangan] [bigint] IDENTITY(1,1) NOT NULL,
	[id_jabatan] [bigint] NULL,
	[tunjangan_detail] [varchar](100) NULL,
	[nominal] [decimal](18, 2) NULL,
	[keterangan] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MasterBudgetPipeline]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MasterBudgetPipeline](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Product] [varchar](50) NULL,
	[Budget] [decimal](18, 2) NULL,
	[Month] [int] NULL,
	[Year] [int] NULL,
 CONSTRAINT [PK_MasterBudgetPipeline] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MasterCabinet]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MasterCabinet](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Laci] [varchar](5) NULL,
	[MaxDompet] [int] NULL,
	[MaxTray] [int] NULL,
	[MaxGiro] [int] NULL,
	[CreatedBy] [varchar](10) NULL,
	[CreatedDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MasterDocumentDesc]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MasterDocumentDesc](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[DocumentCode] [nvarchar](50) NULL,
	[DocumentDesc] [nvarchar](250) NULL,
 CONSTRAINT [PK_Document] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MasterDocumentSubDesc]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MasterDocumentSubDesc](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocumentCode] [nvarchar](50) NULL,
	[SubDocumentCode] [nvarchar](50) NULL,
	[SubDocumentDesc] [nvarchar](250) NULL,
 CONSTRAINT [PK_DocumentSub] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MasterJabatan]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MasterJabatan](
	[id_jabatan] [bigint] IDENTITY(1,1) NOT NULL,
	[jabatan_detail] [varchar](50) NULL,
	[description] [varchar](100) NULL,
 CONSTRAINT [PK_MasterJabatan] PRIMARY KEY CLUSTERED 
(
	[id_jabatan] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Mitra]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[Mitra](
	[MKey] [int] NOT NULL,
	[MCode] [nvarchar](15) NOT NULL,
	[Nama] [nvarchar](100) NULL,
	[TempatLahir] [nvarchar](50) NULL,
	[TanggalLahir] [date] NULL,
	[Address] [nvarchar](250) NULL,
	[Email] [nvarchar](50) NULL,
	[NoTlp] [nvarchar](20) NULL,
	[Hp] [nvarchar](20) NULL,
	[NoWhatsApp] [nvarchar](20) NULL,
	[JenisMitra] [nvarchar](50) NULL,
	[IsSubMitra] [nvarchar](5) NULL,
	[IsActive] [nvarchar](1) NULL,
	[CreatedBy] [nvarchar](20) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](20) NULL,
	[LastModifiedTime] [datetime] NULL,
	[ContactPerson] [nvarchar](100) NULL,
	[NPWP] [nvarchar](100) NULL,
	[AktePendirian] [nvarchar](100) NULL,
	[SubMitra] [nvarchar](100) NULL,
	[Branch] [nvarchar](100) NULL,
	[TipeMitra] [nvarchar](15) NULL,
	[Provinsi] [nvarchar](50) NULL,
	[KotaKabupaten] [nvarchar](50) NULL,
	[PIC] [nvarchar](150) NULL,
	[Password] [nvarchar](50) NULL,
	[Profile] [nvarchar](max) NULL,
	[IsTravel] [char](1) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
SET ANSI_PADDING ON
ALTER TABLE [dbo].[Mitra] ADD [Siskopatuh] [varchar](10) NULL
 CONSTRAINT [PK_Mitra] PRIMARY KEY CLUSTERED 
(
	[MKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MITRA_PENGURUS]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MITRA_PENGURUS](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MKey] [bigint] NOT NULL,
	[NAMA] [varchar](500) NULL,
	[GENDER] [char](1) NULL,
	[NIK] [varchar](50) NULL,
	[NPWP] [varchar](50) NULL,
	[BIRTH_DATE] [datetime] NULL,
	[BIRTH_PLACE] [varchar](100) NULL,
	[ADDRESS] [varchar](500) NULL,
	[PROVINCE] [varchar](255) NULL,
	[REGION] [varchar](255) NULL,
	[DISTRICT] [varchar](255) NULL,
	[VILLAGE] [varchar](255) NULL,
	[JABATAN] [varchar](50) NULL,
	[PANGSA] [numeric](18, 2) NULL,
	[CRE_DT] [datetime] NULL,
	[CRE_BY] [varchar](100) NULL,
	[MOD_DATE] [datetime] NULL,
	[MOD_BY] [varchar](100) NULL,
 CONSTRAINT [PK_MITRA_PENGURUS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MitraBankDetail]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MitraBankDetail](
	[MBankKey] [int] NOT NULL,
	[MKey] [int] NULL,
	[Seq] [int] NULL,
	[BankName] [nvarchar](50) NULL,
	[BankBranch] [nvarchar](50) NULL,
	[BankAccNo] [nvarchar](50) NULL,
	[BankAccName] [nvarchar](100) NULL,
 CONSTRAINT [PK_MitraBankDetail] PRIMARY KEY CLUSTERED 
(
	[MBankKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MitraComment]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MitraComment](
	[DtlKey] [bigint] IDENTITY(1,1) NOT NULL,
	[MKey] [bigint] NULL,
	[Comment] [varchar](max) NULL,
	[CreBy] [varchar](100) NULL,
	[CreDt] [datetime] NULL,
 CONSTRAINT [PK_MitraComment] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MitraDocumentDetail]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MitraDocumentDetail](
	[DtlUploadKey] [int] IDENTITY(1,1) NOT NULL,
	[MKey] [int] NULL,
	[Remark] [nvarchar](250) NULL,
	[DocPath] [nvarchar](max) NULL,
	[DocumentDesc] [varchar](250) NULL,
	[SubDocumentDesc] [varchar](250) NULL,
	[CreBy] [varchar](100) NULL,
	[CreDt] [datetime] NULL,
	[UpdBy] [varchar](100) NULL,
	[UpdDt] [datetime] NULL,
 CONSTRAINT [PK_MitraDocumentDetail] PRIMARY KEY CLUSTERED 
(
	[DtlUploadKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MNCL_PRODUCT_TARGET]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MNCL_PRODUCT_TARGET](
	[PRODUCT] [varchar](25) NULL,
	[TARGET_YEAR] [char](4) NULL,
	[TARGET_SALES] [numeric](18, 0) NULL,
	[CRE_BY] [varchar](15) NULL,
	[CRE_DATE] [smalldatetime] NULL,
	[MOD_BY] [varchar](15) NULL,
	[MOD_DATE] [smalldatetime] NULL,
	[NO_URUT] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MsNpl]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MsNpl](
	[MasterNplId] [bigint] IDENTITY(1,1) NOT NULL,
	[OfficeCode] [varchar](20) NOT NULL,
	[OfficeName] [varchar](50) NOT NULL,
	[NplPercentage] [numeric](9, 6) NOT NULL,
	[Bulan] [smallint] NOT NULL,
	[Tahun] [smallint] NOT NULL,
	[IsActive] [char](1) NOT NULL,
	[UsrCrt] [varchar](20) NOT NULL,
	[DtmCrt] [datetime] NOT NULL,
	[UsrUpd] [varchar](20) NOT NULL,
	[DtmUpd] [datetime] NOT NULL,
 CONSTRAINT [PK_MsNpl] PRIMARY KEY CLUSTERED 
(
	[MasterNplId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mstApplicationBudget]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mstApplicationBudget](
	[DocKey] [int] NOT NULL,
	[ObjectPembiayaan] [varchar](100) NULL,
	[Description] [varchar](200) NULL,
	[Amount] [numeric](18, 0) NULL,
 CONSTRAINT [PK_mstApplicationBudget] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mstCalculateProductList]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mstCalculateProductList](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[product_name] [varchar](100) NULL,
	[product_desc] [varchar](100) NULL,
	[adminfee] [decimal](18, 0) NULL,
	[provision] [decimal](18, 0) NULL,
	[audit_user] [varchar](100) NULL,
	[audit_date] [datetime] NULL,
 CONSTRAINT [PK_mstCalculateProductList] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mstDocLocation]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mstDocLocation](
	[DocKey] [int] IDENTITY(100,1) NOT NULL,
	[DocID] [varchar](20) NULL,
	[DocCategory] [varchar](100) NULL,
	[LocID] [int] NULL,
	[ReffNum] [varchar](20) NULL,
	[CRE_BY] [varchar](20) NULL,
	[CRE_DATE] [datetime] NULL,
	[MOD_BY] [varchar](20) NULL,
	[MOD_DATE] [datetime] NULL,
	[Description] [varchar](255) NULL,
	[Location] [varchar](255) NULL,
	[Status] [varchar](20) NULL,
 CONSTRAINT [PK_mstDocLocation] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mstDocLocation_log]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mstDocLocation_log](
	[LogKey] [int] IDENTITY(100,1) NOT NULL,
	[DocID] [varchar](20) NULL,
	[DocCategory] [varchar](100) NULL,
	[Location] [varchar](255) NULL,
	[ReffNum] [varchar](20) NULL,
	[Description] [varchar](255) NULL,
	[CRE_BY] [varchar](20) NULL,
	[CRE_DATE] [datetime] NULL,
	[MOD_BY] [varchar](20) NULL,
	[MOD_DATE] [datetime] NULL,
	[Status] [varchar](20) NULL,
 CONSTRAINT [PK_mstDocLocation_log] PRIMARY KEY CLUSTERED 
(
	[LogKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mstGeneralSetup]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mstGeneralSetup](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](50) NULL,
	[Value] [varchar](50) NULL,
	[Descs] [varchar](50) NULL,
 CONSTRAINT [PK_mstGeneralSetup] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mstSurveyItem]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mstSurveyItem](
	[id] [int] NOT NULL,
	[survey_object] [varchar](50) NULL,
	[survey_item] [varchar](max) NULL,
	[cr_user] [varchar](50) NULL,
	[cr_date] [datetime] NULL,
	[md_user] [varchar](50) NULL,
	[md_date] [datetime] NULL,
 CONSTRAINT [PK_mstSurveyItem] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PartialPaymentApprovalList]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PartialPaymentApprovalList](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[Dockey] [varchar](10) NULL,
	[Code] [varchar](40) NULL,
	[TypeApproval] [varchar](50) NULL,
	[Seq] [int] NULL,
	[NIK] [varchar](50) NULL,
	[Nama] [varchar](50) NULL,
	[Jabatan] [varchar](50) NULL,
	[IsDecision] [varchar](50) NULL,
	[DecisionState] [varchar](50) NULL,
	[DecisionCode] [int] NULL,
	[DecisionDate] [datetime] NULL,
	[DecisionNote] [varchar](50) NULL,
	[Email] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PolisAsuransiFA]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PolisAsuransiFA](
	[DocKey] [int] NOT NULL,
	[DocNo] [nvarchar](50) NULL,
	[DocDate] [datetime] NULL,
	[AssetDesc] [nvarchar](250) NULL,
	[NoPolisi] [nvarchar](100) NULL,
	[NoRangka] [nvarchar](50) NULL,
	[NoMesin] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](50) NULL,
	[LastModifiedDateTime] [datetime] NULL,
 CONSTRAINT [PK_PolisAsuransiFA] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PolisAsuransiFADetail]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PolisAsuransiFADetail](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[Maskapai] [nvarchar](150) NULL,
	[NoPolis] [nvarchar](100) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Coverage] [nvarchar](100) NULL,
 CONSTRAINT [PK_PolisAsuransiFADetail] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ProfitLossCalculate]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProfitLossCalculate](
	[ProfitLossCalculateId] [bigint] IDENTITY(1,1) NOT NULL,
	[Pembiayaan] [numeric](17, 2) NOT NULL,
	[Tenor] [int] NOT NULL,
	[ccode] [varchar](20) NOT NULL,
	[LsAgree] [varchar](50) NOT NULL,
	[ProvisiIncome] [numeric](17, 2) NOT NULL,
	[FlatRateFullTerm] [numeric](17, 6) NOT NULL,
	[FlatRateAnnualy] [numeric](17, 6) NOT NULL,
	[IncomeInterestTotal] [numeric](17, 2) NOT NULL,
	[IncomeProvisi] [numeric](17, 2) NOT NULL,
	[IncomeInsurance] [numeric](17, 2) NOT NULL,
	[IncomeAdmin] [numeric](17, 2) NOT NULL,
	[TotalIncome] [numeric](17, 2) NOT NULL,
	[BebanBungaBank] [numeric](17, 2) NOT NULL,
	[BebanProvisiBank] [numeric](17, 2) NOT NULL,
	[BebanAdminBank] [numeric](17, 2) NOT NULL,
	[BebanCadanganKerugian] [numeric](17, 2) NOT NULL,
	[BebanGeneralAdminCabang] [numeric](17, 2) NOT NULL,
	[TotalBeban] [numeric](17, 2) NOT NULL,
	[ProfitAndLoss] [numeric](17, 2) NOT NULL,
	[CreatedDate] [datetime] NULL,
 CONSTRAINT [PK_ProfitLossCalculate] PRIMARY KEY CLUSTERED 
(
	[ProfitLossCalculateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[provinces]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[provinces](
	[id] [char](2) NOT NULL,
	[name] [varchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[regencies]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[regencies](
	[id] [char](4) NOT NULL,
	[province_id] [char](2) NOT NULL,
	[name] [varchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Registry]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Registry](
	[RegID] [nvarchar](50) NOT NULL,
	[RegType] [nvarchar](50) NULL,
	[RegValue] [nvarchar](50) NULL,
 CONSTRAINT [PK_RegID] PRIMARY KEY CLUSTERED 
(
	[RegID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[REIMBURSE_OPERATION_DT]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[REIMBURSE_OPERATION_DT](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[HD_REFFNO] [varchar](50) NOT NULL,
	[NOTA_DATE] [datetime] NOT NULL,
	[DETAIL_TYPE] [int] NOT NULL,
	[AMOUNT] [numeric](18, 2) NOT NULL,
	[NOTE] [varchar](255) NULL,
	[CRE_BY] [varchar](50) NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[MOD_BY] [varchar](50) NULL,
	[MOD_DT] [datetime] NULL,
 CONSTRAINT [PK_REIMBURSE_OPERATION_DT] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[REIMBURSE_OPERATION_HD]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[REIMBURSE_OPERATION_HD](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[REFF_NO] [varchar](50) NOT NULL,
	[APPLY_DATE] [datetime] NOT NULL,
	[TOTAL] [numeric](18, 2) NULL,
	[PAY_TO] [varchar](50) NOT NULL,
	[PAY_TO_DESC] [varchar](255) NULL,
	[EMPLOYEE_CODE] [varchar](50) NOT NULL,
	[POSITION] [varchar](255) NOT NULL,
	[AREA] [varchar](255) NOT NULL,
	[BRANCH] [varchar](255) NULL,
	[ACCOUNT_NO] [varchar](50) NOT NULL,
	[ACCOUNT_NAME] [varchar](255) NOT NULL,
	[BANK] [varchar](100) NOT NULL,
	[STATUS] [varchar](50) NOT NULL,
	[CRE_BY] [varchar](50) NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[MOD_BY] [varchar](50) NULL,
	[MOD_DT] [datetime] NULL,
 CONSTRAINT [PK_REIMBURSE_OPERATION_HD] PRIMARY KEY CLUSTERED 
(
	[REFF_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[REIMBURSE_OPERATION_TRX]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[REIMBURSE_OPERATION_TRX](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[HD_REFFNO] [varchar](50) NOT NULL,
	[STATUS] [varchar](50) NOT NULL,
	[CRE_BY] [varchar](50) NULL,
	[CRE_DT] [datetime] NULL,
 CONSTRAINT [PK_REIMBURSE_OPERATION_TRX] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCHEME_APPROVAL_REIMBURSE_TRX]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCHEME_APPROVAL_REIMBURSE_TRX](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[HD_REFFNO] [varchar](50) NOT NULL,
	[SEQ] [int] NOT NULL,
	[EMPLOYEE_CODE] [varchar](50) NOT NULL,
	[EMPLOYEE_NAME] [varchar](255) NOT NULL,
	[POSITION_CODE] [bigint] NOT NULL,
	[POSITION] [varchar](255) NOT NULL,
	[IS_DECISION] [varchar](1) NULL,
	[DECISION_STATE] [varchar](50) NULL,
	[DECISION_DATE] [datetime] NULL,
	[DECISION_NOTE] [varchar](max) NULL,
	[CRE_BY] [varchar](50) NOT NULL,
	[CRE_DT] [datetime] NOT NULL,
	[MOD_BY] [varchar](50) NULL,
	[MOD_DT] [datetime] NULL,
 CONSTRAINT [PK_SCHEME_APPROVAL_REIMBURSE_TRX] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Session]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Session](
	[SessionKey] [int] IDENTITY(1,1) NOT NULL,
	[NIK] [nvarchar](20) NULL,
	[ComputerName] [nvarchar](500) NULL,
	[UserName] [nvarchar](500) NULL,
	[PrivateKey] [nvarchar](500) NULL,
	[TimeStart] [datetime] NULL,
	[TimeEnd] [datetime] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SheetControl]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SheetControl](
	[DocNo] [nvarchar](30) NOT NULL,
	[DocDate] [datetime] NULL,
	[AppNo] [nvarchar](30) NULL,
	[Client] [nvarchar](50) NULL,
	[RO] [nvarchar](100) NULL,
	[Tipe] [nvarchar](50) NULL,
	[Name] [nvarchar](100) NULL,
	[IdentityName] [nvarchar](100) NULL,
	[IbuKandung] [nvarchar](100) NULL,
	[TempatLahir] [nvarchar](100) NULL,
	[TanggalLahir] [date] NULL,
	[NPWP] [nvarchar](50) NULL,
	[KTP] [nvarchar](50) NULL,
	[Email] [nvarchar](50) NULL,
	[Agama] [nvarchar](50) NULL,
	[StatusNikah] [nvarchar](50) NULL,
	[Gender] [nvarchar](50) NULL,
	[Pendidikan] [nvarchar](100) NULL,
	[AlamatKtp] [nvarchar](250) NULL,
	[AlamatTagih] [nvarchar](250) NULL,
	[CoyName] [nvarchar](100) NULL,
	[Job] [nvarchar](100) NULL,
	[ClientGroup] [nvarchar](100) NULL,
	[SpouseName] [nvarchar](100) NULL,
	[SpouseKtp] [nvarchar](50) NULL,
	[SpouseTanggalLahir] [date] NULL,
	[SpouseTempatLahir] [nvarchar](100) NULL,
	[Insalary] [decimal](18, 2) NULL,
	[AlamatKantor] [nvarchar](250) NULL,
	[Telepon] [nvarchar](25) NULL,
	[MobilePhone] [nvarchar](25) NULL,
	[JenisPengikatan] [nvarchar](50) NULL,
	[CRNo] [nvarchar](200) NULL,
	[CRDate] [datetime] NULL,
	[CAMNo] [nvarchar](200) NULL,
	[CAMDate] [datetime] NULL,
	[DocMand] [nvarchar](max) NULL,
	[DocAddi] [nvarchar](max) NULL,
	[LegalConclution] [nvarchar](max) NULL,
	[UncompletedDoc] [nvarchar](max) NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](100) NULL,
	[LastModifiedDateTime] [datetime] NULL,
	[SLIKGolongan] [nvarchar](100) NULL,
	[SLIKSektorEkonomi] [nvarchar](100) NULL,
	[SIPPGolongan] [nvarchar](100) NULL,
	[SIPPSektorEkonomi] [nvarchar](100) NULL,
	[FooterMadeBy] [nvarchar](100) NULL,
	[FooterMadeByPos] [nvarchar](50) NULL,
	[FooterApprovedBy] [nvarchar](100) NULL,
	[FooterApprovedByPos] [nvarchar](50) NULL,
	[FooterMarketing] [nvarchar](100) NULL,
	[FooterMarketingPos] [nvarchar](50) NULL,
	[FooterBusinessManager] [nvarchar](100) NULL,
	[FooterBusinessManagerPos] [nvarchar](50) NULL,
 CONSTRAINT [PK_SheetControl] PRIMARY KEY CLUSTERED 
(
	[DocNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SheetControlAkteNotaris]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SheetControlAkteNotaris](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[AppNo] [nvarchar](30) NULL,
	[NoAktaPerubahan] [nvarchar](100) NULL,
	[TglAktaPerubahan] [datetime] NULL,
	[SK] [nvarchar](100) NULL,
	[TglSK] [datetime] NULL,
 CONSTRAINT [PK_SheetControlAkteNotaris] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SheetControlBadanUsaha]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SheetControlBadanUsaha](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[AppNo] [nvarchar](30) NULL,
	[Name] [nvarchar](250) NULL,
	[NPWP] [nvarchar](50) NULL,
	[JenisBadanUsaha] [nvarchar](50) NULL,
	[StatusBadanUsaha] [nvarchar](50) NULL,
	[AddressSKD] [nvarchar](250) NULL,
	[KodePOSSKD] [nvarchar](10) NULL,
	[AddressNPWP] [nvarchar](250) NULL,
	[KodePOSNPWP] [nvarchar](10) NULL,
	[AddresssBILL] [nvarchar](250) NULL,
	[KodePOSBILL] [nvarchar](10) NULL,
	[CorporateGroup] [nvarchar](100) NULL,
	[CorporateEmail] [nvarchar](100) NULL,
	[CorporateContactPerson] [nvarchar](100) NULL,
	[CorporateContactPersonHp] [nvarchar](20) NULL,
	[CorporateContactPersonTelp] [nvarchar](20) NULL,
	[SIUP] [nvarchar](100) NULL,
	[SIUPExpTo] [datetime] NULL,
	[TDP] [nvarchar](100) NULL,
	[TDPExpTo] [datetime] NULL,
	[TempatPendirian] [nvarchar](100) NULL,
	[NoAkta] [nvarchar](100) NULL,
	[TglAkta] [datetime] NULL,
	[Notaris] [nvarchar](100) NULL,
	[SKMenhukam] [nvarchar](100) NULL,
	[TglSK] [datetime] NULL,
	[SLIKGolongan] [nvarchar](100) NULL,
	[SLIKSektorEkonomi] [nvarchar](100) NULL,
	[SIPPGolongan] [nvarchar](100) NULL,
	[SIPPSektorEkonomi] [nvarchar](100) NULL,
 CONSTRAINT [PK_SheetControlBadanUsaha] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SheetControlDetailAsset]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SheetControlDetailAsset](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[AppNo] [nvarchar](30) NULL,
	[ItemDesc] [nvarchar](250) NULL,
	[Year] [nvarchar](5) NULL,
	[Condition] [nvarchar](20) NULL,
	[AssetTypeDetail] [nvarchar](50) NULL,
 CONSTRAINT [PK_SheetControlDetailAsset] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SheetControlPemegangSaham]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SheetControlPemegangSaham](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[AppNo] [nvarchar](30) NULL,
	[NamaPemegangSaham] [nvarchar](100) NULL,
	[PorsiKepemilikan] [nvarchar](100) NULL,
	[ModalDasar] [numeric](18, 2) NULL,
	[ModalDisetor] [numeric](18, 2) NULL,
	[Jabatan] [nvarchar](100) NULL,
 CONSTRAINT [PK_SheetControlPemegangSaham] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SheetControlPengurus]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SheetControlPengurus](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[AppNo] [nvarchar](30) NULL,
	[NamaPengurus] [nvarchar](100) NULL,
	[AlamatPengurus] [nvarchar](250) NULL,
	[NIK] [nvarchar](100) NULL,
	[NPWP] [nvarchar](100) NULL,
	[Jabatan] [nvarchar](100) NULL,
 CONSTRAINT [PK_SheetControlPengurus] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TelesalesInsert]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TelesalesInsert](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PRODUCT] [varchar](100) NULL,
	[CALLDATE] [datetime] NOT NULL,
	[AGENT_ID] [varchar](100) NOT NULL,
	[ID_NUMBER] [varchar](100) NOT NULL,
	[NO_CONTRACT] [varchar](100) NULL,
	[CUSTOMER_NAME] [varchar](255) NULL,
	[CUSTOMER_ADDRESS] [varchar](max) NULL,
	[UPDATE_CUSTOMER_ADDRESS] [varchar](max) NULL,
	[CONTACTED_PHONE] [varchar](50) NULL,
	[RESULT] [varchar](200) NULL,
	[REASON] [varchar](200) NULL,
	[TANGGAL_FOLLOWUP] [datetime] NULL,
	[TENOR] [varchar](10) NULL,
	[JUMLAH_JAMAAH] [varchar](10) NULL,
	[KEBUTUHAN_PEMBIAYAAN] [varchar](255) NULL,
	[START_CALL] [varchar](100) NOT NULL,
	[END_CALL] [varchar](100) NOT NULL,
	[DURATION_CALL] [varchar](100) NOT NULL,
	[KETERANGAN] [varchar](255) NULL,
	[CALL_COUNTER] [varchar](50) NOT NULL,
	[FLAG_SEND] [varchar](1) NOT NULL,
 CONSTRAINT [PK_TeleSales_Insert] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransactionGiroApprovalList]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TransactionGiroApprovalList](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[TypeApproval] [varchar](50) NULL,
	[Seq] [int] NULL,
	[NIK] [varchar](50) NULL,
	[Nama] [varchar](50) NULL,
	[Jabatan] [varchar](50) NULL,
	[IsDecision] [varchar](50) NULL,
	[DecisionState] [varchar](50) NULL,
	[DecisionDate] [datetime] NULL,
	[DecisionNote] [varchar](50) NULL,
	[Email] [varchar](50) NULL,
 CONSTRAINT [PK_TransactionGiroApprovalList] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransaksiGiro_D]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TransaksiGiro_D](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[Dockey] [int] NULL,
	[TrxGiroStatus] [varchar](50) NULL,
	[GiroNo] [varchar](50) NULL,
	[Amount] [decimal](18, 0) NULL,
	[ClientName] [varchar](200) NULL,
	[TglJalanGiro] [varchar](20) NULL,
	[CreatedBy] [varchar](20) NULL,
	[CreatedDate] [datetime] NULL,
	[GiroStatusApproval] [varchar](50) NULL,
	[ContractNo] [varchar](50) NULL,
	[Remarks] [varchar](250) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransaksiGiro_D_HISTORY]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TransaksiGiro_D_HISTORY](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[Dockey] [int] NULL,
	[TrxGiroStatus] [varchar](50) NULL,
	[GiroNo] [varchar](50) NULL,
	[Amount] [decimal](18, 0) NULL,
	[ClientName] [varchar](200) NULL,
	[TglJalanGiro] [varchar](10) NULL,
	[CreatedBy] [varchar](20) NULL,
	[CreatedDate] [datetime] NULL,
	[GiroStatusApproval] [varchar](50) NULL,
	[ContractNo] [varchar](50) NULL,
	[Remarks] [varchar](250) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransaksiGiro_H]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TransaksiGiro_H](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[TrxGiroNo] [varchar](100) NULL,
	[CabinetNo] [varchar](100) NULL,
	[StatusTransaksi] [varchar](100) NULL,
	[TglJalanGiro] [varchar](5) NULL,
	[ContractNo] [varchar](100) NULL,
	[ClientName] [varchar](200) NULL,
	[StatusApproval] [varchar](100) NULL,
	[JumlahGiro] [int] NULL,
	[CreatedBy] [varchar](10) NULL,
	[CreatedDate] [datetime] NULL,
	[IsAllOut] [varchar](2) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransaksiGiro_H_HISTORY]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TransaksiGiro_H_HISTORY](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[TrxGiroNo] [varchar](100) NULL,
	[CabinetNo] [varchar](100) NULL,
	[StatusTransaksi] [varchar](100) NULL,
	[TglJalanGiro] [varchar](5) NULL,
	[ContractNo] [varchar](100) NULL,
	[ClientName] [varchar](200) NULL,
	[StatusApproval] [varchar](100) NULL,
	[JumlahGiro] [int] NULL,
	[CreatedBy] [varchar](10) NULL,
	[CreatedDate] [datetime] NULL,
	[IsAllOut] [varchar](2) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[trxPerjalananDinas]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[trxPerjalananDinas](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[DocNo] [varchar](50) NULL,
	[DocDate] [datetime] NULL,
	[Status] [varchar](50) NULL,
	[NIK] [varchar](50) NULL,
	[Name] [varchar](50) NULL,
	[Dept] [varchar](50) NULL,
	[Jabatan] [varchar](50) NULL,
	[TipeTunjangan] [varchar](50) NULL,
	[Tujuan] [varchar](150) NULL,
	[PembebananBiaya] [varchar](50) NULL,
	[CRE_BY] [varchar](50) NULL,
	[CRE_DATE] [datetime] NULL,
	[MOD_BY] [varchar](50) NULL,
	[MOD_DATE] [datetime] NULL,
	[FromTujuan] [varchar](50) NULL,
	[TotalPengajuan] [decimal](18, 0) NULL,
	[TotalRealisasi] [decimal](18, 0) NULL,
 CONSTRAINT [PK_trxPerjalananDinas] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[trxPerjalananDinasApprovalList]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[trxPerjalananDinasApprovalList](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[TypeApproval] [varchar](50) NULL,
	[Seq] [int] NULL,
	[NIK] [varchar](50) NULL,
	[Nama] [varchar](50) NULL,
	[Jabatan] [varchar](50) NULL,
	[IsDecision] [varchar](50) NULL,
	[DecisionState] [varchar](50) NULL,
	[DecisionDate] [datetime] NULL,
	[DecisionNote] [varchar](max) NULL,
	[Email] [varchar](50) NULL,
 CONSTRAINT [PK_trxPerjalananDinasApprovalList] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[trxPerjalananDinasDetail]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[trxPerjalananDinasDetail](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[TypeSPD] [varchar](50) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[JumlahHari] [int] NULL,
	[Kendaraan] [varchar](50) NULL,
	[Remarks] [varchar](50) NULL,
	[Tujuan] [varchar](100) NULL,
	[FromTujuan] [varchar](100) NULL,
	[CIF] [varchar](max) NULL,
	[DebiturName] [varchar](300) NULL,
	[ActionPlan] [varchar](max) NULL,
	[Type_Kunjungan] [varchar](30) NULL,
	[SuppName] [varchar](500) NULL,
	[DestName] [varchar](500) NULL,
 CONSTRAINT [PK_trxPerjalananDinasDetail] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[trxPerjalananDinasDetailBudget]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[trxPerjalananDinasDetailBudget](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[TypeSPD] [varchar](50) NULL,
	[TypeBudget] [varchar](50) NULL,
	[BudgetDesc] [varchar](max) NULL,
	[BudgetAmount] [decimal](18, 0) NULL,
	[BudgetFile] [varbinary](max) NULL,
 CONSTRAINT [PK_trxPerjalananDinasDetailBudget] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[trxReleaseDoc]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[trxReleaseDoc](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[AgreementNo] [varchar](20) NULL,
	[ClientName] [varchar](100) NULL,
	[ReleaseDate] [datetime] NULL,
	[LastInsPaidDate] [datetime] NULL,
	[DaysDiff] [int] NULL,
	[FeePenitipanDoc] [decimal](18, 2) NULL,
	[WaiveReason] [varchar](20) NULL,
	[WaiveFeePenitipanDoc] [decimal](18, 2) NULL,
	[ReleaseStat] [varchar](20) NULL,
	[ReqNote] [varchar](max) NULL,
	[ApproveDecision] [varchar](20) NULL,
	[ApproveBy] [varchar](20) NULL,
	[ApproveDate] [datetime] NULL,
	[ApproveNote] [varchar](max) NULL,
	[WaiveApproveDecision] [varchar](20) NULL,
	[WaiveApproveBy] [varchar](20) NULL,
	[WaiveApproveDate] [datetime] NULL,
	[WaiveApproveNote] [varchar](max) NULL,
	[WaiveApproveFeeAmt] [decimal](18, 2) NULL,
	[CashierNo] [varchar](50) NULL,
	[ReleaseNote] [varchar](max) NULL,
	[ReleaseDocBy] [varchar](20) NULL,
	[ReleaseDocDate] [datetime] NULL,
	[WaiveDocFile] [varbinary](max) NULL,
	[WaiveDocExt] [varchar](5) NULL,
	[CreatedBy] [varchar](20) NULL,
	[CreatedDate] [datetime] NULL,
	[ModdifiedBy] [varchar](20) NULL,
	[ModdifiedDate] [datetime] NULL,
	[DueDateReleaseDoc] [datetime] NULL,
	[CrossCollApproveDate] [datetime] NULL,
 CONSTRAINT [PK_trxReleaseDoc] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[trxSurveyDBR]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[trxSurveyDBR](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[applicno] [varchar](20) NULL,
	[income] [decimal](18, 0) NULL,
	[ins_slik] [decimal](18, 0) NULL,
	[ins_deb] [decimal](18, 0) NULL,
	[ins_spouse] [decimal](18, 0) NULL,
	[ins_child] [decimal](18, 0) NULL,
	[ins_other] [decimal](18, 0) NULL,
	[dbr] [decimal](18, 2) NULL,
	[cr_user] [varchar](50) NULL,
	[cr_date] [datetime] NULL,
	[biayahidup] [decimal](18, 0) NULL,
	[freecashflow] [decimal](18, 2) NULL,
	[income_other] [decimal](18, 0) NULL,
	[income_penjamin] [decimal](18, 0) NULL,
	[income_penjamin_spouse] [decimal](18, 0) NULL,
	[remarks] [varchar](4000) NULL
) ON [PRIMARY]
SET ANSI_PADDING OFF
ALTER TABLE [dbo].[trxSurveyDBR] ADD [StatusApproval] [varchar](100) NULL
ALTER TABLE [dbo].[trxSurveyDBR] ADD [StatusCode] [int] NULL
ALTER TABLE [dbo].[trxSurveyDBR] ADD [ins_guarantee] [decimal](18, 0) NULL
SET ANSI_PADDING ON
ALTER TABLE [dbo].[trxSurveyDBR] ADD [kolekDebt] [varchar](5) NULL
 CONSTRAINT [PK_trxSurveyDBR] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TrxSurveyMitraTravel]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TrxSurveyMitraTravel](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[APPNO] [varchar](50) NOT NULL,
	[MCODE_TRAVEL] [varchar](50) NOT NULL,
	[KOLEKTIBILITAS_SLIK] [int] NULL,
	[SISKOPATUH] [varchar](50) NULL,
	[CRE_BY] [varchar](50) NULL,
	[CRE_DT] [datetime] NULL,
	[MOD_BY] [varchar](50) NULL,
	[MOD_DT] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[trxSurveyTask]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[trxSurveyTask](
	[trxid] [int] IDENTITY(1,1) NOT NULL,
	[applicno] [varchar](20) NULL,
	[survey_object] [varchar](100) NULL,
	[survey_item] [varchar](100) NULL,
	[agreement] [varchar](20) NULL,
	[cr_user] [varchar](50) NULL,
	[cr_date] [datetime] NULL,
	[md_user] [varchar](50) NULL,
	[md_date] [datetime] NULL,
 CONSTRAINT [PK_trxSurveyTask] PRIMARY KEY CLUSTERED 
(
	[trxid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UpdateSLIK]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UpdateSLIK](
	[DocKey] [int] NOT NULL,
	[DocNo] [nvarchar](30) NULL,
	[DocDate] [datetime] NULL,
	[RefNo] [nvarchar](30) NULL,
	[Remark] [nvarchar](max) NULL,
	[CreatedBy] [nvarchar](30) NULL,
	[CreatedDateTime] [datetime] NULL,
	[Cancel] [nvarchar](1) NULL,
	[CancelBy] [nvarchar](30) NULL,
	[CancelDateTime] [datetime] NULL,
	[SLIKAvailable] [nvarchar](20) NULL,
	[CAChecking] [nvarchar](1) NULL,
	[Debitur] [nvarchar](100) NULL,
 CONSTRAINT [PK_UpdateSLIK] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UpdateSLIKDetail]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UpdateSLIKDetail](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[JenisPembiayaan] [nvarchar](100) NULL,
	[PerusahaanPembiayaan] [nvarchar](100) NULL,
	[AtasNama] [nvarchar](100) NULL,
	[Plafon] [decimal](18, 2) NULL,
	[BakiDebet] [decimal](18, 2) NULL,
	[Bunga] [decimal](18, 2) NULL,
	[TglAkadAwal] [datetime] NULL,
	[TglAwalSisaTenor] [datetime] NULL,
	[TglJatuhTempo] [datetime] NULL,
	[Angsuran] [decimal](18, 2) NULL,
	[Kolektibilitas] [nvarchar](50) NULL,
	[HistoryKolek] [nvarchar](50) NULL,
	[AktualOverDue] [nvarchar](15) NULL,
 CONSTRAINT [PK_UpdateSLIKDetail] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UpdateSLIKDetail_20220210]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UpdateSLIKDetail_20220210](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[JenisPembiayaan] [nvarchar](100) NULL,
	[PerusahaanPembiayaan] [nvarchar](100) NULL,
	[AtasNama] [nvarchar](100) NULL,
	[Plafon] [decimal](18, 2) NULL,
	[BakiDebet] [decimal](18, 2) NULL,
	[Bunga] [decimal](18, 2) NULL,
	[TglAkadAwal] [datetime] NULL,
	[TglAwalSisaTenor] [datetime] NULL,
	[TglJatuhTempo] [datetime] NULL,
	[Angsuran] [decimal](18, 2) NULL,
	[Kolektibilitas] [nvarchar](50) NULL,
	[HistoryKolek] [nvarchar](50) NULL,
	[AktualOverDue] [nvarchar](15) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UpdateSLIKDetail_ARGA]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UpdateSLIKDetail_ARGA](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[JenisPembiayaan] [nvarchar](100) NULL,
	[PerusahaanPembiayaan] [nvarchar](100) NULL,
	[AtasNama] [nvarchar](100) NULL,
	[Plafon] [decimal](18, 2) NULL,
	[BakiDebet] [decimal](18, 2) NULL,
	[Bunga] [decimal](18, 2) NULL,
	[TglAkadAwal] [datetime] NULL,
	[TglAwalSisaTenor] [datetime] NULL,
	[TglJatuhTempo] [datetime] NULL,
	[Angsuran] [decimal](18, 2) NULL,
	[Kolektibilitas] [nvarchar](50) NULL,
	[HistoryKolek] [nvarchar](50) NULL,
	[AktualOverDue] [nvarchar](15) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UpdateSPPHNo]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UpdateSPPHNo](
	[DocKey] [int] NOT NULL,
	[AgreementNo] [nvarchar](20) NULL,
	[NoSPPH] [nvarchar](20) NULL,
	[JenisPengurus] [nvarchar](20) NULL,
	[IDPengurus] [nvarchar](20) NULL,
	[NamaPengurus] [nvarchar](100) NULL,
	[Status] [nvarchar](20) NULL,
	[CreatedBy] [nvarchar](20) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](20) NULL,
	[LastModifiedDateTime] [datetime] NULL,
	[ApproveBy] [nvarchar](150) NULL,
	[ApproveDateTime] [datetime] NULL,
	[DebiturName] [nvarchar](100) NULL,
	[Tenor] [int] NULL,
	[Installment] [decimal](18, 2) NULL,
	[Branch] [nvarchar](100) NULL,
	[IDSalesAdmin] [nvarchar](20) NULL,
	[NamaSalesAdmin] [nvarchar](max) NULL,
	[IDMktHead] [nvarchar](20) NULL,
	[NamaMktHead] [nvarchar](max) NULL,
	[DisburseDate] [datetime] NULL,
 CONSTRAINT [PK_UpdateSPPHNo] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UploadPaymentTextFile]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UploadPaymentTextFile](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Seq] [int] NULL,
	[OrderNumber] [nvarchar](30) NULL,
	[Tanggal] [date] NULL,
	[NomorKontrak] [nvarchar](30) NULL,
	[AyoconnectPrice] [decimal](18, 2) NULL,
	[PotonganAyoconnect] [decimal](18, 2) NULL,
	[Disburse] [decimal](18, 2) NULL,
	[Status] [nvarchar](20) NULL,
	[PaidOn] [date] NULL,
	[PaymentMode] [nvarchar](50) NULL,
	[UploadBy] [nvarchar](250) NULL,
	[UploadDateTime] [datetime] NULL,
	[UploadStatus] [nvarchar](20) NULL,
	[JasaPembayaran] [nvarchar](30) NULL,
 CONSTRAINT [PK_UploadPaymentTextFile] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[VerificationTaskApprovalList]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VerificationTaskApprovalList](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[TypeApproval] [varchar](50) NULL,
	[Seq] [int] NULL,
	[NIK] [varchar](50) NULL,
	[Nama] [varchar](200) NULL,
	[Jabatan] [varchar](max) NULL,
	[IsDecision] [varchar](5) NULL,
	[DecisionState] [varchar](20) NULL,
	[DecisionDate] [datetime] NULL,
	[DecisionNote] [varchar](max) NULL,
	[Email] [varchar](50) NULL,
	[DecisionCode] [int] NULL,
 CONSTRAINT [PK_VerificationTaskApprovalList] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VerifikasiDebiturInfo]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VerifikasiDebiturInfo](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[applicno] [varchar](20) NULL,
	[pengajuan_dana_haji] [varchar](10) NULL,
	[keterangan_ttd_formulir] [varchar](30) NULL,
	[keterangan_nama_lengkap] [varchar](20) NULL,
	[keterangan_nama_ibu_kandung] [varchar](20) NULL,
	[keterangan_tempat_tgllahir] [varchar](20) NULL,
	[keterangan_tempat_tinggal] [varchar](20) NULL,
	[status_tempat_tinggal] [varchar](50) NULL,
	[jumlah_penghuni_rumah] [varchar](30) NULL,
	[keterangan_tempat_bekerja] [varchar](20) NULL,
	[masa_kerja] [varchar](30) NULL,
	[status_karyawan] [varchar](30) NULL,
	[sumber_penghasilan] [varchar](30) NULL,
	[besar_gaji] [varchar](30) NULL,
	[pekerjaan_pasangan] [varchar](50) NULL,
	[jumlah_tanggungan] [varchar](30) NULL,
	[cr_user] [varchar](50) NULL,
	[cr_date] [datetime] NULL,
	[md_user] [varchar](50) NULL,
	[md_date] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VerifikasiTempatBekerjaInfo]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[VerifikasiTempatBekerjaInfo](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[applicno] [varchar](20) NULL,
	[karyawan] [varchar](10) NULL,
	[nama_sumber_informasi] [varchar](100) NULL,
	[jenis_kelamin] [varchar](2) NULL,
	[no_telp] [varchar](20) NULL,
	[relasi] [varchar](30) NULL,
	[keterangan_usaha_debitur] [varchar](50) NULL,
	[jabatan] [varchar](50) NULL,
	[masa_kerja] [varchar](20) NULL,
	[jumlah_penghuni_rumah] [varchar](20) NULL,
	[status_karyawan] [varchar](20) NULL,
	[bidang_usaha] [varchar](30) NULL,
	[cr_user] [varchar](50) NULL,
	[cr_date] [datetime] NULL,
	[md_user] [varchar](50) NULL,
	[md_date] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[villages]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[villages](
	[id] [char](10) NOT NULL,
	[district_id] [char](7) NOT NULL,
	[name] [varchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[WilayahKotaKabupaten]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WilayahKotaKabupaten](
	[id] [varchar](4) NOT NULL,
	[provinsi_id] [varchar](2) NOT NULL,
	[nama] [varchar](30) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[WilayahProvinsi]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WilayahProvinsi](
	[id] [varchar](2) NOT NULL,
	[nama] [varchar](30) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[WorkFlowAccessOPL]    Script Date: 8/2/2023 10:43:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WorkFlowAccessOPL](
	[StateDescription] [varchar](200) NULL,
	[GroupAccessCode] [varchar](200) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[APPROVE_REIMBURSE_DT] ADD  CONSTRAINT [DF_APPROVE_REIMBURSE_DT_LEVEL]  DEFAULT ((1)) FOR [LEVEL]
GO
ALTER TABLE [dbo].[APPROVE_REIMBURSE_DT] ADD  CONSTRAINT [DF_APPROVE_REIMBURSE_DT_IS_ACTIVE]  DEFAULT ((1)) FOR [IS_ACTIVE]
GO
ALTER TABLE [dbo].[APPROVE_REIMBURSE_HD] ADD  CONSTRAINT [DF_APPROVE_REIMBURSE_HD_IS_ACTIVE]  DEFAULT ((1)) FOR [IS_ACTIVE]
GO
ALTER TABLE [dbo].[MASTER_AREA] ADD  CONSTRAINT [DF_MASTER_AREA_IS_ACTIVE]  DEFAULT ((1)) FOR [IS_ACTIVE]
GO
ALTER TABLE [dbo].[MASTER_BRANCH] ADD  CONSTRAINT [DF_MASTER_BRANCH_IS_ACTIVE]  DEFAULT ((1)) FOR [IS_ACTIVE]
GO
ALTER TABLE [dbo].[MASTER_PLATFON_REIMBURSE] ADD  DEFAULT ((1)) FOR [IS_ACTIVE]
GO
ALTER TABLE [dbo].[MASTER_POSITION] ADD  CONSTRAINT [DF_MASTER_POSITION_IS_ACTIVE]  DEFAULT ((1)) FOR [IS_ACTIVE]
GO
ALTER TABLE [dbo].[MASTER_USER] ADD  CONSTRAINT [DF_MASTER_USER_PASSWORD_APPROVAL]  DEFAULT ((1)) FOR [PASSWORD_APPROVAL]
GO
ALTER TABLE [dbo].[Mitra] ADD  CONSTRAINT [D_Mitra_IsTravel]  DEFAULT ('F') FOR [IsTravel]
GO
ALTER TABLE [dbo].[WilayahKotaKabupaten] ADD  DEFAULT ('') FOR [provinsi_id]
GO
ALTER TABLE [dbo].[APPROVE_REIMBURSE_DT]  WITH CHECK ADD  CONSTRAINT [FK_APPROVE_REIMBURSE_DT_APPROVE_REIMBURSE_HD] FOREIGN KEY([ROLE_HD_CODE])
REFERENCES [dbo].[APPROVE_REIMBURSE_HD] ([ROLE_CODE])
GO
ALTER TABLE [dbo].[APPROVE_REIMBURSE_DT] CHECK CONSTRAINT [FK_APPROVE_REIMBURSE_DT_APPROVE_REIMBURSE_HD]
GO
ALTER TABLE [dbo].[districts]  WITH CHECK ADD  CONSTRAINT [districts_regency_id_foreign] FOREIGN KEY([regency_id])
REFERENCES [dbo].[regencies] ([id])
GO
ALTER TABLE [dbo].[districts] CHECK CONSTRAINT [districts_regency_id_foreign]
GO
ALTER TABLE [dbo].[MASTER_BRANCH]  WITH CHECK ADD  CONSTRAINT [FK_MASTER_BRANCH_MASTER_AREA] FOREIGN KEY([AREA_CODE])
REFERENCES [dbo].[MASTER_AREA] ([AREA_CODE])
GO
ALTER TABLE [dbo].[MASTER_BRANCH] CHECK CONSTRAINT [FK_MASTER_BRANCH_MASTER_AREA]
GO
ALTER TABLE [dbo].[MasterBiayaTunjangan]  WITH CHECK ADD  CONSTRAINT [FK_MasterBiayaTunjangan_MasterJabatan] FOREIGN KEY([id_jabatan])
REFERENCES [dbo].[MasterJabatan] ([id_jabatan])
GO
ALTER TABLE [dbo].[MasterBiayaTunjangan] CHECK CONSTRAINT [FK_MasterBiayaTunjangan_MasterJabatan]
GO
ALTER TABLE [dbo].[regencies]  WITH CHECK ADD  CONSTRAINT [regencies_province_id_foreign] FOREIGN KEY([province_id])
REFERENCES [dbo].[provinces] ([id])
GO
ALTER TABLE [dbo].[regencies] CHECK CONSTRAINT [regencies_province_id_foreign]
GO
ALTER TABLE [dbo].[villages]  WITH CHECK ADD  CONSTRAINT [villages_district_id_foreign] FOREIGN KEY([district_id])
REFERENCES [dbo].[districts] ([id])
GO
ALTER TABLE [dbo].[villages] CHECK CONSTRAINT [villages_district_id_foreign]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'1=BENSIN; 2=TOL; 3=PARKIR; 4=LAINNYA' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'REIMBURSE_OPERATION_DT', @level2type=N'COLUMN',@level2name=N'DETAIL_TYPE'
GO

USE [CARPOOL]
GO
/****** Object:  StoredProcedure [dbo].[GetApprovalBooking]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetApprovalBooking]       
 @USERID VARCHAR(10),
 @Approver VARCHAR(15)           
AS      
BEGIN      
      
 SET NOCOUNT ON;           

	IF @Approver = 'IS_GA'
	BEGIN   

		SELECT A.APPROVER,A.* FROM Booking A
		INNER JOIN AccessRight B ON A.Approver = B.CMDid or A.Approver = B.NIK
		INNER JOIN IFINANCING_GOLIVE..SYS_TBLEMPLOYEE C ON B.NIK=C.CODE
		INNER JOIN (SELECT DISTINCT USER_ID FROM IFINANCING_GOLIVE..MASTER_USER_COMPANY_GROUP WHERE
		GROUP_CODE IN ('HO-GA-MGR','HO-GA-SCH','HO-GA-STF')  
		) D on B.NIK = D.USER_ID
		WHERE A.Status='NEED APPROVAL' AND B.NIK=@USERID --AND A.APPROVER=@Approver 
		
	END     
	ELSE
	BEGIN

		select  A.*   
		from Booking a        
		left join (        
		 select * from BookingApprovalList a        
		 where IsDecision = 'F'        
		 and Seq = (select top 1 seq from BookingApprovalList where dockey = a.DocKey and IsDecision = 'F')     
		) b on a.DocKey = b.DocKey        
		left join IFINANCING_GOLIVE..SYS_TBLEMPLOYEE c on b.NIK COLLATE SQL_Latin1_General_CP1_CI_AS = c.CODE   
		where b.TypeApproval = 'Pengajuan Approval'         
		and a.Approver = @USERID         
		and a.Status = 'NEED APPROVAL' 
	END
END


GO
/****** Object:  StoredProcedure [dbo].[GetApprovalSettlement]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetApprovalSettlement]       
 @USERID VARCHAR(10)         
AS      
BEGIN      
      
 SET NOCOUNT ON;           

		select  A.*   
		from Settlement a        
		left join (        
		 select * from SettlementApprovalList a        
		 where IsDecision = 'F'        
		 and Seq = (select top 1 seq from SettlementApprovalList where dockey = a.DocKey and IsDecision = 'F')     
		) b on a.DocKey = b.DocKey        
		left join IFINANCING_GOLIVE..SYS_TBLEMPLOYEE c on b.NIK COLLATE SQL_Latin1_General_CP1_CI_AS = c.CODE   
		where b.TypeApproval = 'Pengajuan Approval'         
		and a.Approver = @USERID         
		and a.Status = 'NEED APPROVAL' 
	
END


GO
/****** Object:  StoredProcedure [dbo].[GetDataChangeCar]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDataChangeCar]       
 --@UserID VARCHAR(10)       
AS      
BEGIN      
      
 SET NOCOUNT ON;           

		SELECT A.* FROM Booking A		
		INNER JOIN IFINANCING_GOLIVE..SYS_TBLEMPLOYEE B ON A.EmployeeName=B.DESCS
		WHERE A.Status='ON SCHEDULE' --AND B.CODE=@UserID
END
GO
/****** Object:  StoredProcedure [dbo].[GetOnScheduleBook]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetOnScheduleBook]       
 @UserID VARCHAR(10)       
AS      
BEGIN      
      
 SET NOCOUNT ON;           

		SELECT A.* FROM Booking A
		INNER JOIN AccessRight B ON A.Approver = B.CMDid
		INNER JOIN IFINANCING_GOLIVE..SYS_TBLEMPLOYEE C ON B.NIK=C.CODE
		INNER JOIN (SELECT DISTINCT USER_ID FROM IFINANCING_GOLIVE..MASTER_USER_COMPANY_GROUP WHERE
		GROUP_CODE IN ('HO-GA-MGR','HO-GA-SCH','HO-GA-STF')  
		) D on B.NIK = D.USER_ID
		WHERE A.Status='ON SCHEDULE' AND B.NIK=@UserID
END



GO
/****** Object:  StoredProcedure [dbo].[SP_Email_Notification_Approval_CarPool]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Email_Notification_Approval_CarPool] 
(
@UserName varchar(100)
) 
AS  
BEGIN  
   
 declare
  
  @EmployeeName varchar(100),  
  @JenisMobil varchar(100),  
  @NoPlat varchar(max),
  @Remarks varchar(50),  
  @subject_cabang varchar(100),
  @profiler nvarchar(50) = 'SQLMelisa',  
  @recipient varchar(max)='arief.syamsudin@mncgroup.com',   
  @subject nvarchar(500) = '',    
  @bodyFormat nvarchar(100) = 'HTML',  
  @bodyHead nvarchar(MAX),  
  @bodyFill nvarchar(MAX) = '',  
  @bodyFoot nvarchar(MAX) = '',
  @recipient2 XML='',
  @Type varchar(5) = ''

	
	SELECT A.EMPLOYEENAME,C.AST_NAME [CARNAME],B.CARLICENSEPLATE,B.REMARK
	into #DATA
	FROM Booking A
	INNER JOIN BookingAdmin B ON A.DocKey=B.SourceKey
	INNER JOIN IFINANCING_GOLIVE..fa_assetregister C ON B.CarLicensePlate=C.PLAT_NO
	WHERE A.STATUS='ON SCHEDULE' AND A.EmployeeName = @UserName
	--AND CAST(A.LastModifiedDateTime AS DATE) = cast(GETDATE() as date) --'2023-01-25'--dateadd(day,-1,cast(GETDATE() as date))
	ORDER BY A.LastModifiedDateTime DESC


   declare subject_EmployeeName cursor read_only for 

    select EmployeeName from #DATA group by EmployeeName
	  
   open subject_EmployeeName  
   fetch subject_EmployeeName into 
   @EmployeeName     
   

   while @@fetch_status = 0  
   begin 
   
   SET @recipient2 = ';garry.florence@mncgroup.com'
		--SET @recipient2 = (
		--					select distinct ';' + c.EMAIL 
		--					from IFINANCING_GOLIVE..master_user_company_group a
		--					INNER JOIN IFINANCING_GOLIVE..SYS_COMPANY b ON a.C_CODE = b.C_CODE
		--					INNER JOIN IFINANCING_GOLIVE..SYS_TBLEMPLOYEE c on a.USER_ID = c.CODE
		--					where c.descs = @EmployeeName AND c.ISACTIVE = 1 
		--					FOR XML PATH('')
		--				  )

		if convert(varchar(max),@recipient2) <> ''
		begin
			SET @recipient = @recipient + convert(varchar(max),@recipient2)
		end

		SET @subject = 'CARPOOL - Approve '
		
		set @bodyHead='<head><style>body {font-family: arial; font-size: 12px;}</style></head>' +  
			 '<body>' +   
			 'Dear '+@EmployeeName+', <br><br>' +   
			 'Peminjaman Kendaraan Mobil sudah di approve oleh tim GA.<br>' +
			 'Kendaraan Mobil dapat segera diambil dengan detail berikut:<br><br>';

			 set  @bodyHead = @bodyHead + 
			 '<table border="1" width="1500"><tr style="font-weight: bold; text-align:center;">' +  
			 '<td width="100">Jenis Mobil</td>' +   
			 '<td width="120">No. Plat</td>' +
			 '<td width="120">Remarks</td></tr>'; 	 	
		
		set @bodyFill = '';	 		
		begin -- loop 2 
			declare table_content cursor read_only for  
				
				select CarName,CarLicensePlate,Remark
				from #DATA 
				where EmployeeName = @EmployeeName

			open table_content  
			fetch table_content into 
			  @JenisMobil,  
			  @NoPlat,  
			  @Remarks  
			 
			   
			 while @@fetch_status = 0  
			 begin 			  
				  set @bodyFill = @bodyFill + '<tr><td style="text-align:center;">' +  isnull(@JenisMobil,'') + '</td>' + 
				   '<td style="text-align:center;">' + isnull(@NoPlat, '') + '</td>' +  
				   '<td style="text-align:left;">' + isnull(@Remarks, '') + '</td></tr>' 
 
				 
				  fetch next from table_content into  
				   @JenisMobil,  
				   @NoPlat,  
				   @Remarks	    
			 end			 
				 		 
			 close table_content  
			 deallocate table_content 

		end --loop 2
		
			
				set @bodyFoot = '</table><br><br>' +
					'Regards,<br>MNC Leasing SMILE Application – Auto Notification</body>'

			 if @bodyFill <> ''  
			 BEGIN  
			 set @bodyFill = @bodyHead + @bodyFill + @bodyFoot 
			 END
			 
			 --print	 '@profile_name '+	@profiler+ 
				--	 '@recipients	'+	@recipient+ 
				--	 '@subject  	'+	@subject+ 
				--	 '@body   		'+	@bodyFill+ 
				--	 '@body_format	'+	@bodyFormat	 		  		   
			 exec [DBCORE].msdb.dbo.sp_send_dbmail  
			 @profile_name = @profiler,  
			 @recipients  = 'garry.florence@mncgroup.com',--@recipient,  
			 @subject  = @subject,  
			 @body   = @bodyFill,  
			 @body_format = @bodyFormat,
			 @importance = 'HIGH' 

			 insert MNCL_Email_Notification values('Approval GA', @bodyFill, @recipient, GETDATE())
			 			
		fetch next from subject_EmployeeName into  
		@EmployeeName			
		
	end  
		 
	close subject_EmployeeName  
	deallocate subject_EmployeeName 			
	
	drop table #DATA 
 end 




GO
/****** Object:  StoredProcedure [dbo].[sp_getApproverName]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_getApproverName]
@NIK varchar(20)
as
begin

	select b.DESCS
	FROM dbo.Booking a
	left join IFINANCING_GOLIVE..SYS_TBLEMPLOYEE B ON A.APPROVER = b.CODE                                                                
	WHERE b.code=@NIK

end
GO
/****** Object:  StoredProcedure [dbo].[sp_GetRecepient]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_GetRecepient]
@employeename nvarchar(50)
as
begin

	select DISTINCT c.EMAIL 
	from IFINANCING_GOLIVE..master_user_company_group a
	INNER JOIN IFINANCING_GOLIVE..SYS_COMPANY b ON a.C_CODE = b.C_CODE
	INNER JOIN IFINANCING_GOLIVE..SYS_TBLEMPLOYEE c on a.USER_ID = c.CODE
	where c.descs = @employeename AND c.ISACTIVE = 1 
end

GO
/****** Object:  StoredProcedure [dbo].[sp_master_user_login]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_master_user_login] 
(
	@p_email		nvarchar(50)
	,@p_user_password	nvarchar(32)
) as
begin

	select	--mu.user_id
			mu.user_password
			,mu.EMAIL
			,mu.is_active_flag
			,mu.USER_NAME 'staff_name'
			,(SELECT top 1 CONVERT(DATETIME,cast(cast(sys_date as date) as nvarchar(20)) + ' ' + LEFT(cast(cast(getdate() as time) as nvarchar(19)),12),120) FROM dbo.SYSTEM_DATE) 'SYSTEM_DATE_TIME'
			,(SELECT top 1 CONVERT(VARCHAR(10),sys_date,103) FROM dbo.SYSTEM_DATE) 'SYSTEM_DATE'
			,getdate()
	from	MasterUser mu
	where	mu.EMAIL			= @p_email and mu.IS_ACTIVE_FLAG='1'
	--and		mu.USER_PASSWORD	=   CONVERT(VARCHAR(32), HashBytes('MD5', @p_user_password), 2)
end




GO
/****** Object:  StoredProcedure [dbo].[spGetListReport]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spGetListReport]   
   
AS  
BEGIN  
   
 SET NOCOUNT ON;  
  
 select  
  book.DocKey,  
  book.DocNo,  
  book.DocDate,  
  book.EmployeeName,  
  '' [EmployeeCompanyName],
  '' [Menit],
  '' [AmountParkir],
  '' [AmountTOL],
  '' [DriverName],
  book.Department,  
  LTRIM(RTRIM(STUFF((  
   SELECT ', ' + X.Name FROM BookingDetail X   
   WHERE X.DocKey = book.DocKey FOR XML PATH ('')), 1, 1, ''))) [Penumpang],  
  bDriver.ActualPickDateTime,  
  bDriver.ActualArriveDateTime,  
  bAdmin.LastKilometer,
  bAdmin.CurrentKilometer,
  SUM(ISNULL(iBBM.SubTotal,0)) [AmountBBM]  
  ,bAdmin.CarLicensePlate  
  ,book.RequestPickLoc  
  ,book.RequestDestLoc
  ,book.TripDetails
 from Booking book  
 --left join BookingDetail b on book.DocKey = b.DocKey  
 left join BookingDriver bDriver on book.DocKey = bDriver.SourceKey  
 left join BookingAdmin bAdmin on book.DocKey = bAdmin.SourceKey  
 left join Settlement sett on book.DocNo = sett.BookNo  
 left join SettlementDetail iParkir on sett.DocKey = iParkir.DocKey and iParkir.ItemCode = 'ST0001'  
 left join SettlementDetail iTOL on sett.DocKey = iTOL.DocKey and iTOL.ItemCode = 'ST0002'  
 left join SettlementDetail iBBM on sett.DocKey = iBBM.DocKey and iBBM.ItemCode = 'ST0004'  
 --where bAdmin.SourceKey = '18997'  
 group by   
  book.DocKey,  
  book.DocNo,  
  book.DocDate,  
  book.EmployeeName,  
  book.Department,  
  bDriver.ActualPickDateTime,  
  bDriver.ActualArriveDateTime,  
  bAdmin.LastKilometer,  
  bAdmin.CurrentKilometer,bAdmin.CarLicensePlate,book.RequestPickLoc,book.RequestDestLoc,book.TripDetails  
 order by book.DocDate Desc  
  
END  

GO
/****** Object:  UserDefinedFunction [dbo].[GetNumberKilometer]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
--SELECT dbo.GetNumberKilometer('404.2 km')
CREATE FUNCTION [dbo].[GetNumberKilometer] 
(
	@value varchar(20)
)
RETURNS float
AS
BEGIN
	
	DECLARE @NumKM	VARCHAR(20)
	DECLARE @IntKM float
	
	SET @NumKM = @value
	SELECT @NumKM = REPLACE(@NumKM,'km','')
	SELECT @NumKM = REPLACE(@NumKM,'.km','')
	
	SET @IntKM = CAST(@NumKM AS float)

	RETURN @IntKM
END

GO
/****** Object:  UserDefinedFunction [dbo].[GetReplaceNonNumeric]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GetReplaceNonNumeric] 
(
	@value VARCHAR(20)
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @NumKM	VARCHAR(20)
	DECLARE @IntKM float
	
	SET @NumKM = @value
	--SELECT @NumKM = REPLACE(@NumKM,'km','')
	--SELECT @NumKM = REPLACE(@NumKM,'.km','')
	
	SELECT @NumKM = LEFT(SUBSTRING(@value, PATINDEX('%[0-9.-]%', @value), 8000),
	PATINDEX('%[^0-9.-]%', SUBSTRING(@value, PATINDEX('%[0-9.-]%', @value), 8000) + 'X') -1)

	SET @IntKM = CAST(@NumKM AS float)

	RETURN @IntKM
		

END

GO
/****** Object:  Table [dbo].[AccessRight]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessRight](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Email] [nvarchar](100) NOT NULL,
	[CMDid] [nvarchar](20) NOT NULL,
	[NIK] [nvarchar](40) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Booking]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Booking](
	[DocKey] [int] NOT NULL,
	[DocNo] [nvarchar](20) NOT NULL,
	[DocDate] [datetime] NOT NULL,
	[Note] [nvarchar](max) NULL,
	[Remark1] [nvarchar](max) NULL,
	[Remark2] [nvarchar](max) NULL,
	[Remark3] [nvarchar](max) NULL,
	[Remark4] [nvarchar](max) NULL,
	[EmployeeName] [nvarchar](50) NULL,
	[EmployeeCompanyName] [nvarchar](100) NULL,
	[Status] [nvarchar](30) NULL,
	[NumberOfSeat] [int] NULL,
	[RequestStartTime] [datetime] NULL,
	[RequestFinishTime] [datetime] NULL,
	[RequestPickLoc] [nvarchar](max) NULL,
	[RequestDestLoc] [nvarchar](max) NULL,
	[RequestPickAddress] [nvarchar](max) NULL,
	[RequestDestAddress] [nvarchar](max) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](50) NULL,
	[LastModifiedDateTime] [datetime] NULL,
	[Cancelled] [nvarchar](1) NULL,
	[CancelledBy] [nvarchar](50) NULL,
	[CancelledDateTime] [datetime] NULL,
	[CancelledReason] [nvarchar](max) NULL,
	[Department] [nvarchar](50) NULL,
	[TripDetails] [nvarchar](max) NULL,
	[IsSettlement] [nvarchar](1) NULL,
	[Hp] [nvarchar](20) NULL,
	[NeedApproval] [nvarchar](1) NULL,
	[Approver] [nvarchar](50) NULL,
 CONSTRAINT [PK_Booking] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BookingAdmin]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BookingAdmin](
	[DocKey] [int] NOT NULL,
	[SourceKey] [int] NULL,
	[DriverCode] [nvarchar](20) NULL,
	[DriverName] [nvarchar](50) NULL,
	[CarCode] [nvarchar](20) NULL,
	[CarType] [nvarchar](50) NULL,
	[CarLicensePlate] [varchar](15) NULL,
	[Remark] [nvarchar](max) NULL,
	[EstPickDateTime] [datetime] NULL,
	[EstArriveDateTime] [datetime] NULL,
	[AdminCode] [nvarchar](20) NULL,
	[AdminName] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](50) NULL,
	[LastModifiedDateTime] [datetime] NULL,
	[LastKilometer] [nvarchar](10) NULL,
	[CurrentKilometer] [nvarchar](20) NULL,
 CONSTRAINT [PK_BookingAdmin] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BookingApprovalList]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BookingApprovalList](
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
	[DecisionCode] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BookingDetail]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BookingDetail](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NOT NULL,
	[Seq] [int] NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Gender] [nvarchar](10) NULL,
	[Status] [nvarchar](50) NULL,
	[Remark1] [nvarchar](max) NULL,
	[Remark2] [nvarchar](max) NULL,
	[Remark3] [nvarchar](max) NULL,
	[Remark4] [nvarchar](max) NULL,
	[NIK] [nvarchar](40) NULL,
	[Jabatan] [nvarchar](80) NULL,
	[Email] [nvarchar](100) NULL,
 CONSTRAINT [PK_BookongDetail] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BookingDriver]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BookingDriver](
	[DocKey] [int] NOT NULL,
	[SourceKey] [int] NULL,
	[DriverName] [nvarchar](50) NULL,
	[ActualPickDateTime] [datetime] NULL,
	[ActualArriveDateTime] [datetime] NULL,
	[DriverRemark] [nvarchar](max) NULL,
	[LastModifiedBy] [nvarchar](50) NULL,
	[LastModifiedDateTime] [datetime] NULL,
	[LastKilometer] [nvarchar](10) NULL,
	[CurrentKilometer] [nvarchar](10) NULL,
 CONSTRAINT [PK_BookingDriver] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BookingType]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BookingType](
	[BookTypeCode] [nvarchar](10) NOT NULL,
	[BookTypeDesc] [nvarchar](50) NULL,
 CONSTRAINT [PK_BookingType] PRIMARY KEY CLUSTERED 
(
	[BookTypeCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DocNoFormat]    Script Date: 8/2/2023 10:49:14 AM ******/
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
/****** Object:  Table [dbo].[GeoLoc]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GeoLoc](
	[DriverName] [nvarchar](50) NOT NULL,
	[Phone] [nvarchar](20) NULL,
	[GeoLat] [float] NULL,
	[GeoLong] [float] NULL,
 CONSTRAINT [PK_GeoLoc] PRIMARY KEY CLUSTERED 
(
	[DriverName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Item]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Item](
	[ItemCode] [nvarchar](20) NOT NULL,
	[ItemGroup] [nvarchar](30) NULL,
	[ItemDescription] [nvarchar](max) NULL,
	[IsActive] [nvarchar](1) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](50) NULL,
	[LastModifiedDateTime] [datetime] NULL,
 CONSTRAINT [PK_Item] PRIMARY KEY CLUSTERED 
(
	[ItemCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MasterCar]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MasterCar](
	[CarCode] [nvarchar](30) NOT NULL,
	[CarName] [nvarchar](50) NULL,
	[CarLicense] [varchar](15) NULL,
	[Kilometer] [nvarchar](10) NULL,
	[IsActive] [nvarchar](1) NULL,
	[Remark] [nvarchar](max) NULL,
 CONSTRAINT [PK_MasterCar] PRIMARY KEY CLUSTERED 
(
	[CarCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MasterClient]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MasterClient](
	[ClientID] [nvarchar](25) NOT NULL,
	[SmileID] [nvarchar](25) NULL,
	[Name] [nvarchar](max) NULL,
	[Address1] [nvarchar](max) NULL,
	[Address2] [nvarchar](max) NULL,
	[RT] [nvarchar](5) NULL,
	[RW] [nvarchar](5) NULL,
	[Kelurahan] [nvarchar](100) NULL,
	[Kecamatan] [nvarchar](100) NULL,
	[Kota] [nvarchar](100) NULL,
	[KodePos] [nvarchar](100) NULL,
	[ContactPerson] [nvarchar](100) NULL,
	[MobilePhone] [nvarchar](100) NULL,
	[Email] [nvarchar](100) NULL,
	[IsActive] [nvarchar](1) NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](100) NULL,
	[LastModifiedTime] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ClientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MasterUser]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MasterUser](
	[USER_NAME] [nvarchar](50) NOT NULL,
	[EMAIL] [nvarchar](50) NOT NULL,
	[USER_PASSWORD] [nvarchar](32) NULL,
	[LAST_LOGIN_DATE] [datetime] NULL,
	[IS_ACTIVE_FLAG] [nvarchar](1) NOT NULL,
	[PASSWORD_APPROVAL] [nvarchar](32) NULL,
	[PASSWORD_EXP_DATE] [datetime] NULL,
	[CRE_DATE] [datetime] NOT NULL,
	[CRE_BY] [nvarchar](100) NULL,
	[CRE_IP_ADDRESS] [nvarchar](15) NOT NULL,
	[MOD_DATE] [datetime] NOT NULL,
	[MOD_BY] [nvarchar](100) NULL,
	[MOD_IP_ADDRESS] [nvarchar](15) NOT NULL,
	[CompanyName] [nvarchar](150) NULL,
	[IsAdmin] [nvarchar](1) NULL,
	[IsCoordinator] [nvarchar](1) NULL,
	[IsCustomer] [nvarchar](1) NULL,
	[IsDriver] [nvarchar](1) NULL,
	[Department] [nvarchar](150) NULL,
	[Hp] [nvarchar](20) NULL,
	[NeedApproval] [nvarchar](1) NULL,
	[Approver] [nvarchar](50) NULL,
 CONSTRAINT [PK_MasterUser] PRIMARY KEY CLUSTERED 
(
	[EMAIL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_MasterUser_EMAIL2] UNIQUE NONCLUSTERED 
(
	[EMAIL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MNCL_Email_Notification]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MNCL_Email_Notification](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[notif_type] [varchar](20) NOT NULL,
	[notif_message] [varchar](max) NULL,
	[notif_recipient] [varchar](700) NULL,
	[process_date] [smalldatetime] NULL,
 CONSTRAINT [PK_MNCL_Email_Notification] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[NumberOfSeat]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NumberOfSeat](
	[NumberOfSeat] [int] NOT NULL,
 CONSTRAINT [PK_NumberOfSeat] PRIMARY KEY CLUSTERED 
(
	[NumberOfSeat] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PersonStatus]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PersonStatus](
	[StatusDesc] [nvarchar](30) NOT NULL,
 CONSTRAINT [PK_PersonStatus] PRIMARY KEY CLUSTERED 
(
	[StatusDesc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Registry]    Script Date: 8/2/2023 10:49:14 AM ******/
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
/****** Object:  Table [dbo].[Session]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Session](
	[SessionKey] [int] IDENTITY(1,1) NOT NULL,
	[Email] [nvarchar](50) NULL,
	[ComputerName] [nvarchar](500) NULL,
	[UserName] [nvarchar](500) NULL,
	[PrivateKey] [nvarchar](500) NULL,
	[TimeStart] [datetime] NULL,
	[TimeEnd] [datetime] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Settlement]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Settlement](
	[DocKey] [int] NOT NULL,
	[SourceKey] [int] NULL,
	[DocNo] [nvarchar](20) NULL,
	[DocDate] [datetime] NULL,
	[BookNo] [nvarchar](20) NULL,
	[BookDate] [datetime] NULL,
	[BookCompany] [nvarchar](100) NULL,
	[BookBy] [nvarchar](50) NULL,
	[BookDept] [nvarchar](50) NULL,
	[BookType] [nvarchar](20) NULL,
	[BookSeatNumber] [int] NULL,
	[BookPickupLoc] [nvarchar](max) NULL,
	[BookDestinationLoc] [nvarchar](max) NULL,
	[BookPickupAddress] [nvarchar](max) NULL,
	[BookDestinantionAddress] [nvarchar](max) NULL,
	[BookTripDetail] [nvarchar](max) NULL,
	[BookActPickupDateTime] [datetime] NULL,
	[BookActArrivalDateTime] [datetime] NULL,
	[BookDriver] [nvarchar](50) NULL,
	[BookCarType] [nvarchar](50) NULL,
	[BookCarLicense] [nvarchar](10) NULL,
	[Total] [numeric](18, 2) NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](50) NULL,
	[LastModifiedDateTime] [datetime] NULL,
	[Cancelled] [nvarchar](1) NULL,
	[CancelledBy] [nvarchar](50) NULL,
	[CancelledDateTime] [datetime] NULL,
	[CancelledReason] [nvarchar](max) NULL,
	[NeedApproval] [nvarchar](1) NULL,
	[Approver] [nvarchar](50) NULL,
	[Status] [nvarchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SettlementApprovalList]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SettlementApprovalList](
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
	[DecisionCode] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SettlementDetail]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SettlementDetail](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[ItemCode] [nvarchar](20) NULL,
	[ItemDesc] [nvarchar](100) NULL,
	[Note] [nvarchar](max) NULL,
	[Remark1] [nvarchar](max) NULL,
	[Remark2] [nvarchar](max) NULL,
	[Remark3] [nvarchar](max) NULL,
	[Remark4] [nvarchar](max) NULL,
	[Image] [image] NULL,
	[Qty] [numeric](18, 2) NULL,
	[UnitPrice] [numeric](18, 2) NULL,
	[SubTotal] [numeric](18, 2) NULL,
 CONSTRAINT [PK_SettlementDetail] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SMSHist]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SMSHist](
	[SmsKey] [int] IDENTITY(1,1) NOT NULL,
	[DocNo] [nvarchar](50) NULL,
	[SendDate] [datetime] NULL,
	[ReceiverNo] [nvarchar](50) NULL,
	[Konten] [nvarchar](250) NULL,
 CONSTRAINT [PK_SMSHist] PRIMARY KEY CLUSTERED 
(
	[SmsKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SYS_CLIENT]    Script Date: 8/2/2023 10:49:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SYS_CLIENT](
	[SYS_CLIENTID] [int] IDENTITY(1,1) NOT NULL,
	[CLIENT] [nvarchar](10) NOT NULL,
	[DIN] [nvarchar](20) NULL,
	[NAME] [nvarchar](60) NULL,
	[SHORTNAME] [nvarchar](60) NULL,
	[REAL_NAME] [nvarchar](100) NULL,
	[SALUTE1] [nvarchar](10) NULL,
	[SALUTE2] [nvarchar](10) NULL,
	[IBUKANDUNG] [nvarchar](40) NULL,
	[IBULAHIR] [datetime] NULL,
	[IBUJABAT] [nvarchar](30) NULL,
	[STATUS] [numeric](1, 0) NULL,
	[ADDRESS1] [nvarchar](500) NULL,
	[ADDRESS2] [nvarchar](40) NULL,
	[ADDRESS3] [nvarchar](40) NULL,
	[KECAMATAN] [nvarchar](40) NULL,
	[KELURAHAN] [nvarchar](40) NULL,
	[AREA_CODE] [nvarchar](6) NULL,
	[PHONE] [nvarchar](20) NULL,
	[FAX] [nvarchar](20) NULL,
	[CONTACT] [nvarchar](40) NULL,
	[POSITION] [nvarchar](30) NULL,
	[CONTLAHIR] [datetime] NULL,
	[GROUP_] [nvarchar](6) NULL,
	[IND_CODE] [nvarchar](10) NULL,
	[LOC_CODE] [nvarchar](4) NULL,
	[INDUSTRY] [nvarchar](3) NULL,
	[REGDATE] [datetime] NULL,
	[WLIST] [nvarchar](1) NOT NULL,
	[COLLATERAL] [nvarchar](1) NOT NULL,
	[REMARK] [text] NULL,
	[INJUMTG] [numeric](2, 0) NULL,
	[RELIGION] [nvarchar](20) NULL,
	[INMAILADD1] [nvarchar](100) NULL,
	[INMAILADD2] [nvarchar](40) NULL,
	[INMAILADD3] [nvarchar](40) NULL,
	[INMAILTELP] [nvarchar](14) NULL,
	[INGENDER] [numeric](1, 0) NULL,
	[INBORNPLC] [varchar](100) NULL,
	[INBORNDT] [datetime] NULL,
	[INKTP] [nvarchar](30) NULL,
	[INHOUSE] [numeric](1, 0) NULL,
	[INMARITAL] [numeric](1, 0) NULL,
	[INSTAY] [numeric](3, 0) NULL,
	[INSTAYEAR] [numeric](3, 0) NULL,
	[INSTAMTH] [numeric](3, 0) NULL,
	[INLUASHOUSE] [numeric](4, 0) NULL,
	[INLUASLAND] [numeric](4, 0) NULL,
	[INHOUSERP] [numeric](17, 2) NULL,
	[INCAR] [nvarchar](30) NULL,
	[INCARYEAR] [nvarchar](4) NULL,
	[INCARNO] [nvarchar](11) NULL,
	[INDEPEN] [numeric](3, 0) NULL,
	[INEDUCAT] [nvarchar](30) NULL,
	[INMEMPART] [text] NULL,
	[INJOB] [numeric](1, 0) NULL,
	[INCOMPANY] [nvarchar](35) NULL,
	[INCOMPIND] [nvarchar](40) NULL,
	[INADDR1] [nvarchar](100) NULL,
	[INADDR2] [nvarchar](35) NULL,
	[INADDR3] [nvarchar](35) NULL,
	[INPOSITION] [nvarchar](30) NULL,
	[INSALARY] [numeric](17, 2) NULL,
	[INOTHER] [numeric](17, 2) NULL,
	[INPHONE] [nvarchar](20) NULL,
	[INFAX] [nvarchar](20) NULL,
	[INPERIOD] [numeric](3, 0) NULL,
	[INPERYEAR] [numeric](3, 0) NULL,
	[INPERMTH] [numeric](3, 0) NULL,
	[INSPOUNAME] [nvarchar](35) NULL,
	[INSPOUBRDT] [datetime] NULL,
	[INSPOUPLC] [nvarchar](20) NULL,
	[INSPOUEDU] [nvarchar](25) NULL,
	[INSPOUKT] [nvarchar](30) NULL,
	[INSPOUJOB] [numeric](1, 0) NULL,
	[INSPOUCOMP] [nvarchar](40) NULL,
	[INSPOUIND] [nvarchar](35) NULL,
	[INSPOUADD1] [nvarchar](50) NULL,
	[INSPOUADD2] [nvarchar](40) NULL,
	[INSPOUADD3] [nvarchar](40) NULL,
	[INSPOUTELP] [nvarchar](14) NULL,
	[INSPOUFAX] [nvarchar](14) NULL,
	[INSPOUJAB] [nvarchar](30) NULL,
	[INSPOUYEAR] [numeric](2, 0) NULL,
	[INSPOUBLN] [numeric](2, 0) NULL,
	[INSPOUSLR] [numeric](17, 2) NULL,
	[INSPOUOTH] [numeric](17, 2) NULL,
	[INBANK] [nvarchar](35) NULL,
	[INTYPELOAN] [nvarchar](20) NULL,
	[INTOTLOAN] [numeric](17, 2) NULL,
	[INRENTAL] [numeric](17, 2) NULL,
	[INLOANPERIOD] [numeric](3, 0) NULL,
	[INFROMDT] [datetime] NULL,
	[INTODT] [datetime] NULL,
	[INJAMIN] [nvarchar](35) NULL,
	[INJAMADD1] [nvarchar](100) NULL,
	[INJAMADD2] [nvarchar](40) NULL,
	[INJAMADD3] [nvarchar](40) NULL,
	[INJAMKTP] [nvarchar](30) NULL,
	[INJAMTELP] [nvarchar](14) NULL,
	[INJAMSTAT] [numeric](1, 0) NULL,
	[IS_SUBSCRIBE] [nvarchar](1) NOT NULL,
	[COBISTYPE] [numeric](1, 0) NULL,
	[COBISSTAT] [numeric](1, 0) NULL,
	[COBISNAT] [nvarchar](35) NULL,
	[NPWP] [nvarchar](35) NULL,
	[SIUP] [nvarchar](35) NULL,
	[COBOC] [text] NULL,
	[COBOD] [text] NULL,
	[COBANKER] [text] NULL,
	[MOFCODE] [nvarchar](10) NULL,
	[CR_LIMIT] [numeric](17, 2) NULL,
	[MEMO] [text] NULL,
	[AKTEUBAH] [nvarchar](20) NULL,
	[TGLUBAH] [datetime] NULL,
	[NOTARIS1] [nvarchar](40) NULL,
	[NOTARIS2] [nvarchar](40) NULL,
	[AO] [nvarchar](20) NULL,
	[SINCE] [nvarchar](4) NULL,
	[PLAFOND] [numeric](12, 0) NULL,
	[SIDSTATUS] [nvarchar](4) NULL,
	[SIDGOLONGAN] [nvarchar](4) NULL,
	[SIDDATI2] [nvarchar](4) NULL,
	[SIDNEGARA] [nvarchar](3) NULL,
	[SIDPEKERJAAN] [nvarchar](3) NULL,
	[SIDBIDUSAHA] [nvarchar](6) NULL,
	[CLIENT_TYPE] [nvarchar](10) NULL,
	[KTP_CORP] [nvarchar](30) NULL,
	[EXP_KTP] [datetime] NULL,
	[INSPOUNAME2] [nvarchar](100) NULL,
	[INSPOUNAME3] [nvarchar](40) NULL,
	[INSPOUNAME4] [nvarchar](40) NULL,
	[INSPOUJAB2] [nvarchar](40) NULL,
	[INSPOUJAB3] [nvarchar](40) NULL,
	[INSPOUJAB4] [nvarchar](40) NULL,
	[INSPOUBRDT2] [datetime] NULL,
	[INSPOUBRDT3] [datetime] NULL,
	[INSPOUBRDT4] [datetime] NULL,
	[IBU_NPWP] [nvarchar](20) NULL,
	[IBU_TEMPAT_LAHIR] [nvarchar](40) NULL,
	[IBUADD1] [nvarchar](100) NULL,
	[IBUADD2] [nvarchar](40) NULL,
	[IBUADD3] [nvarchar](40) NULL,
	[INSPOU_NPWP] [nvarchar](20) NULL,
	[INSPOU_KTP] [nvarchar](30) NULL,
	[INSPOU_EXP_KTP] [datetime] NULL,
	[INSPOU_LAHIR] [nvarchar](40) NULL,
	[INSPOU_NPWP2] [nvarchar](20) NULL,
	[INSPOU_KTP2] [nvarchar](30) NULL,
	[INSPOU_EXP_KTP2] [datetime] NULL,
	[INSPOU_LAHIR2] [nvarchar](40) NULL,
	[INSPOU_NPWP3] [nvarchar](20) NULL,
	[INSPOU_KTP3] [nvarchar](30) NULL,
	[INSPOU_EXP_KTP3] [datetime] NULL,
	[INSPOU_LAHIR3] [nvarchar](40) NULL,
	[INSPOU_NPWP4] [nvarchar](20) NULL,
	[INSPOU_KTP4] [nvarchar](30) NULL,
	[INSPOU_EXP_KTP4] [datetime] NULL,
	[INSPOU_LAHIR4] [nvarchar](40) NULL,
	[INEXPKTP] [datetime] NULL,
	[NO_SK] [nvarchar](50) NULL,
	[NO_SK_RUBAH] [nvarchar](50) NULL,
	[CONTACTHP] [nvarchar](20) NULL,
	[CONTACTTLP] [nvarchar](20) NULL,
	[TDP] [nvarchar](50) NULL,
	[SRTPENJAMIN1] [nvarchar](50) NULL,
	[SRTPENJAMINEXP1] [datetime] NULL,
	[SRTPENJAMIN2] [nvarchar](50) NULL,
	[SRTPENJAMINEXP2] [datetime] NULL,
	[SRTPENJAMIN3] [nvarchar](50) NULL,
	[SRTPENJAMINEXP3] [datetime] NULL,
	[SKTDOMISILI] [nvarchar](50) NULL,
	[DOMISILI] [nvarchar](50) NULL,
	[KOTA] [nvarchar](100) NULL,
	[MAPPING] [nvarchar](50) NULL,
	[INJAMHUB] [nvarchar](50) NULL,
	[TDP_FROM_DT] [datetime] NULL,
	[TDP_TO_DT] [datetime] NULL,
	[SIUP_FROM_DT] [datetime] NULL,
	[SIUP_TO_DT] [datetime] NULL,
	[DOMS_BY] [nvarchar](100) NULL,
	[DOMS_FROM_DT] [datetime] NULL,
	[DOMS_TO_DT] [datetime] NULL,
	[DI_OLEH] [nvarchar](100) NULL,
	[KOTA_PERUBAHAN] [nvarchar](100) NULL,
	[SUBIND_CODE] [nvarchar](6) NULL,
	[INEFFKTP] [datetime] NULL,
	[INSPOUBANK_ACCNO] [nvarchar](20) NULL,
	[INSPOUBANK_ACCNAME] [nvarchar](50) NULL,
	[INSPOUBANK_NAME] [nvarchar](50) NULL,
	[INSPOUBANK_BRANCH] [nvarchar](50) NULL,
	[BANK_ACCNO] [nvarchar](20) NULL,
	[BANK_ACCNAME] [nvarchar](50) NULL,
	[BANK_NAME] [nvarchar](50) NULL,
	[BANK_BRANCH] [nvarchar](50) NULL,
	[AREA_CODES] [nvarchar](5) NULL,
	[INEMERNAME] [nvarchar](50) NULL,
	[INEMERPLACE] [nvarchar](50) NULL,
	[INEMERBRTDT] [datetime] NULL,
	[INEMEREDU] [nvarchar](30) NULL,
	[INEMERKTP] [nvarchar](30) NULL,
	[INEMERJOB] [nvarchar](30) NULL,
	[INEMERCOMP] [nvarchar](50) NULL,
	[INEMERIND] [nvarchar](50) NULL,
	[INEMERADD1] [nvarchar](200) NULL,
	[INEMERADD2] [nchar](40) NULL,
	[INEMERADD3] [nchar](40) NULL,
	[INEMERTELP] [nvarchar](20) NULL,
	[INEMERFAX] [nvarchar](20) NULL,
	[INEMERJAB] [nvarchar](50) NULL,
	[INEMERYEAR] [numeric](2, 0) NULL,
	[INEMERBLN] [numeric](2, 0) NULL,
	[INSPOUAREA_CODE] [nvarchar](6) NULL,
	[INSPOU_KELURAHAN] [nvarchar](40) NULL,
	[INSPOU_KECAMATAN] [nvarchar](40) NULL,
	[INSPOU_KOTA] [nvarchar](100) NULL,
	[INSEMERAREA_CODE] [nvarchar](6) NULL,
	[INSEMER_KELURAHAN] [nvarchar](40) NULL,
	[INSEMER_KECAMATAN] [nvarchar](40) NULL,
	[INSEMER_KOTA] [nvarchar](100) NULL,
	[INSJOBAREA_CODE] [nvarchar](6) NULL,
	[INSJOB_KELURAHAN] [nvarchar](40) NULL,
	[INSJOB_KECAMATAN] [nvarchar](40) NULL,
	[INSJOB_KOTA] [nvarchar](100) NULL,
	[INHOUSEPRICE] [numeric](18, 2) NULL,
	[VILLA_DESC] [nvarchar](100) NULL,
	[VILLA_PRICE] [numeric](18, 2) NULL,
	[VILLA_LUASHOUSE] [numeric](4, 0) NULL,
	[VILLA_LUASLAND] [numeric](4, 0) NULL,
	[INCARPRICE] [numeric](18, 2) NULL,
	[DEPOSITO_DESC] [nvarchar](100) NULL,
	[DEPOSITO_AMT] [numeric](18, 2) NULL,
	[OTHER_WEALTH_DESC] [nvarchar](100) NULL,
	[OTHER_WEALTH_AMT] [numeric](18, 2) NULL,
	[INHOUSE_DESC] [nvarchar](100) NULL,
	[NPWP_ONPROSSES] [nvarchar](1) NULL,
	[INAREA] [nvarchar](6) NULL,
	[INKECAMATAN] [nvarchar](40) NULL,
	[INKELURAHAN] [nvarchar](40) NULL,
	[INKOTA] [nvarchar](100) NULL,
	[LATITUDE] [nvarchar](50) NULL,
	[LONGITUDE] [nvarchar](50) NULL,
	[LATITUDE_TRX] [nvarchar](50) NULL,
	[LONGITUDE_TRX] [nvarchar](50) NULL,
	[CRE_DATE] [datetime] NOT NULL,
	[CRE_BY] [nvarchar](15) NOT NULL,
	[CRE_IP_ADDRESS] [nvarchar](15) NOT NULL,
	[MOD_DATE] [datetime] NOT NULL,
	[MOD_BY] [nvarchar](15) NOT NULL,
	[MOD_IP_ADDRESS] [nvarchar](15) NOT NULL,
	[RT] [nvarchar](5) NULL,
	[RW] [nvarchar](5) NULL,
	[KOTA_TERBIT_KTP] [nvarchar](100) NULL,
	[OJK_CODE] [nvarchar](20) NULL,
	[OJK_REFERENCE] [nvarchar](20) NULL,
	[SID_SYNC_DATE] [datetime] NULL,
	[IND_CODE_BI] [nvarchar](10) NULL,
	[STATUS_OJK] [nvarchar](4) NULL,
	[GOLONGAN_OJK] [nvarchar](5) NULL,
	[DATI2_OJK] [nvarchar](4) NULL,
	[NEGARA_OJK] [nvarchar](3) NULL,
	[PEKERJAAN_OJK] [nvarchar](3) NULL,
	[BIDUSAHA_OJK] [nvarchar](6) NULL,
	[CATEGORY] [nvarchar](10) NULL,
	[OJK_STATUS_KETERKAITAN] [nvarchar](20) NULL,
	[STATUS_APPROVED] [nvarchar](15) NULL,
	[CURRENT_APPROVAL_LEVEL] [int] NULL,
	[BILL_ADDRESS1] [nvarchar](500) NULL,
	[BILL_ADDRESS2] [nvarchar](100) NULL,
	[BILL_ADDRESS3] [nvarchar](100) NULL,
	[BILL_RT] [nvarchar](100) NULL,
	[BILL_RW] [nvarchar](100) NULL,
	[INMAILADD4] [nvarchar](250) NULL,
 CONSTRAINT [PK_SYS_CLIENT_1] PRIMARY KEY CLUSTERED 
(
	[CLIENT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SYSTEM_DATE]    Script Date: 8/2/2023 10:49:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SYSTEM_DATE](
	[sys_date] [datetime] NULL
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_STATUS]  DEFAULT ((0)) FOR [STATUS]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INJUMTG]  DEFAULT ((0)) FOR [INJUMTG]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INGENDER]  DEFAULT ((0)) FOR [INGENDER]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INHOUSE]  DEFAULT ((0)) FOR [INHOUSE]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INMARITAL]  DEFAULT ((0)) FOR [INMARITAL]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INSTAY]  DEFAULT ((0)) FOR [INSTAY]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INSTAYEAR]  DEFAULT ((0)) FOR [INSTAYEAR]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INSTAMTH]  DEFAULT ((0)) FOR [INSTAMTH]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INLUASHOUSE]  DEFAULT ((0)) FOR [INLUASHOUSE]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INLUASLAND]  DEFAULT ((0)) FOR [INLUASLAND]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INHOUSERP]  DEFAULT ((0)) FOR [INHOUSERP]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INDEPEN]  DEFAULT ((0)) FOR [INDEPEN]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INJOB]  DEFAULT ((0)) FOR [INJOB]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INSALARY]  DEFAULT ((0)) FOR [INSALARY]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INOTHER]  DEFAULT ((0)) FOR [INOTHER]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INPERIOD]  DEFAULT ((0)) FOR [INPERIOD]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INPERYEAR]  DEFAULT ((0)) FOR [INPERYEAR]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INPERMTH]  DEFAULT ((0)) FOR [INPERMTH]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INSPOUJOB]  DEFAULT ((0)) FOR [INSPOUJOB]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INSPOUYEAR]  DEFAULT ((0)) FOR [INSPOUYEAR]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INSPOUBLN]  DEFAULT ((0)) FOR [INSPOUBLN]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INSPOUSLR]  DEFAULT ((0)) FOR [INSPOUSLR]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INSPOUOTH]  DEFAULT ((0)) FOR [INSPOUOTH]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INTOTLOAN]  DEFAULT ((0)) FOR [INTOTLOAN]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INRENTAL]  DEFAULT ((0)) FOR [INRENTAL]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INLOANPERIOD]  DEFAULT ((0)) FOR [INLOANPERIOD]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_INJAMSTAT]  DEFAULT ((0)) FOR [INJAMSTAT]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_IS_SUBSCRIBE]  DEFAULT (N'0') FOR [IS_SUBSCRIBE]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_COBISTYPE]  DEFAULT ((0)) FOR [COBISTYPE]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_COBISSTAT]  DEFAULT ((0)) FOR [COBISSTAT]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_CR_LIMIT]  DEFAULT ((0)) FOR [CR_LIMIT]
GO
ALTER TABLE [dbo].[SYS_CLIENT] ADD  CONSTRAINT [DF_SYS_CLIENT_PLAFOND]  DEFAULT ((0)) FOR [PLAFOND]
GO

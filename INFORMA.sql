USE [INFORMA]
GO
/****** Object:  StoredProcedure [dbo].[cari_sp_mengandung]    Script Date: 8/2/2023 10:44:09 AM ******/
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
/****** Object:  StoredProcedure [dbo].[sp_INFORMA_GetDetailPelepasanCrossColl]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

-- exec dbo.sp_INFORMA_GetDetailPelepasanCrossColl 4102
CREATE PROCEDURE [dbo].[sp_INFORMA_GetDetailPelepasanCrossColl]
	@DocKey int
AS
BEGIN
	select
		a.*, 
		b.VHCYEAR,
		ISNULL(b.NTF,0) [PLAFOND]
	from [INFORMA].[dbo].[InternalMemoDetailPelepasanCrossColl] a
	left join LS_ASSETVEHICLE b on a.AgreementNo = b.LSAGREE and a.AssetDesc = b.DESCRIPTION
	where a.DocKey = @DocKey 
	group by a.DtlKey,a.DocKey, a.Seq,a.AgreementNo, a.AssetDesc, a.ValueAsset, a.OSPH, a.CicilanTenor, a.DendaBerjalan, 
		b.VHCYEAR,
		b.NTF,
		b.DESCRIPTION
	ORDER BY a.Seq
END

GO
/****** Object:  StoredProcedure [dbo].[sp_INFORMA_SendMail]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_INFORMA_SendMail]
    @profile_name VARCHAR(100),
    @recipients VARCHAR(1000),
    @copy_recipients VARCHAR(1000),
    @body NVARCHAR(MAX),
    @subject NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    --EXEC [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
    --    @profile_name = @profile_name,
    --    @recipients = @recipients,
    --    @copy_recipients = @copy_recipients,
    --    @body = @body,
    --    @subject = @subject
END

GO
/****** Object:  StoredProcedure [dbo].[sp_SSS_SendMail]    Script Date: 8/2/2023 10:44:09 AM ******/
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

    --EXEC [172.31.215.2\MSSQLSRVGUI].msdb.dbo.sp_send_dbmail
    --    @profile_name = @profile_name,
    --    @recipients = @recipients,
    --    @copy_recipients = @copy_recipients,
    --    @body = @body,
    --    @subject = @subject
END


GO
/****** Object:  UserDefinedFunction [dbo].[SLIK_fn_remove_special_char]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[SLIK_fn_remove_special_char]
(
	@p_string			nvarchar(max)
)
returns nvarchar(max)
as
begin
	declare @result nvarchar(max)
	
	if @p_string is null
		return ''
	
	set @result = @p_string
	set @result = replace(@result, '  ', ' ') 
	set @result = ltrim(rtrim(@result))
	set @result = replace(@result, '-', '')
	set @result = replace(@result, '–', '') -- object ghaib berupa '–'
	set @result = replace(@result, ';', '')
	set @result = replace(@result, '.', '')
	set @result = replace(@result, ',', '')
	set @result = replace(@result, '/', '')
	set @result = replace(@result, '\', '')
	set @result = replace(@result, '|', '')
	set @result = replace(@result, '(', '')
	set @result = replace(@result, ')', '')
	set @result = replace(@result, '_', '')
	set @result = replace(@result, '>', '')
	set @result = replace(@result, ':', '')
	set @result = replace(@result, '"', '')
	set @result = replace(@result, '+', '')
	set @result = replace(@result, '#', '')
	set @result = replace(@result, '`', '')
	set @result = replace(@result, 'À', '')  -- object ghaib berupa 'Â'
	set @result = replace(@result, '[', '')
	set @result = replace(@result, ']', '')
	set @result = case when right(@result,1) = ' ' then SUBSTRING(@result, 1 ,
	case when  CHARINDEX(' ', @result ) = 0 then LEN(@result) 
	else CHARINDEX(' ', @result) -1 end) else @result end
	set @result = REPLACE(REPLACE(@result, CHAR(13), ''), CHAR(10), '')
	return @result
end 


GO
/****** Object:  Table [dbo].[AccessRight]    Script Date: 8/2/2023 10:44:09 AM ******/
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
/****** Object:  Table [dbo].[DeviasiExtendHistory]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DeviasiExtendHistory](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DocNo] [varchar](50) NULL,
	[RefNo] [varchar](50) NULL,
	[PerpanjanganKe] [int] NULL,
 CONSTRAINT [PK_DeviasiExtendHistory] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DocNoFormat]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocNoFormat](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Format] [nvarchar](50) NULL,
	[NextNo] [int] NOT NULL,
	[DocType] [nvarchar](20) NOT NULL,
	[OneMonthOneSet] [nvarchar](1) NOT NULL,
	[DeptCode] [nvarchar](25) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Employee]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Employee](
	[NIK] [nvarchar](20) NOT NULL,
	[Nama] [nvarchar](100) NULL,
	[DeptCode] [nvarchar](10) NULL,
	[DeptDesc] [nchar](100) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FreeTextTemplate]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FreeTextTemplate](
	[id] [int] NOT NULL,
	[docFile] [varbinary](max) NULL,
	[docDesc] [varchar](max) NULL,
 CONSTRAINT [PK_FreeTextTemplate] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InternalMemo]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[InternalMemo](
	[DocKey] [int] NOT NULL,
	[DocNo] [nvarchar](50) NULL,
	[DocDate] [datetime] NULL,
	[DocType] [nvarchar](100) NULL,
	[DocValue] [nvarchar](3) NULL,
	[Status] [nvarchar](20) NULL,
	[IsApprove] [nvarchar](1) NULL,
	[MemoBranch] [nvarchar](50) NULL,
	[MemoFrom] [nvarchar](255) NULL,
	[MemoTo] [nvarchar](255) NULL,
	[MemoCC] [nvarchar](255) NULL,
	[MemoPerihal] [nvarchar](max) NULL,
	[MemoLampiran] [nvarchar](150) NULL,
	[MemoRefNo] [nvarchar](100) NULL,
	[DebiturName] [nvarchar](150) NULL,
	[DebiturCIF] [nvarchar](30) NULL,
	[DebiturAddress] [nvarchar](250) NULL,
	[DebiturAngsuran] [decimal](18, 2) NULL,
	[BackgroundText] [nvarchar](max) NULL,
	[CostBenefitAnalysisText] [nvarchar](max) NULL,
	[GiroReason] [nvarchar](max) NULL,
	[GiroTolakanKe] [nvarchar](2) NULL,
	[GiroPreviousApplyDate] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreatedDateTime] [datetime] NULL,
	[SubmitBy] [nvarchar](100) NULL,
	[SubmitDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](100) NULL,
	[LastModifiedDateTime] [datetime] NULL,
	[HeaderText] [nvarchar](max) NULL,
	[FooterText] [nvarchar](max) NULL,
	[Note] [nvarchar](max) NULL,
	[Remark1] [nvarchar](100) NULL,
	[Remark2] [nvarchar](100) NULL,
	[Remark3] [nvarchar](100) NULL,
	[Remark4] [nvarchar](100) NULL,
	[NextApprover] [nvarchar](100) NULL,
	[NoteReturn] [varchar](max) NULL,
	[DeviasiNoPFK] [varchar](max) NULL,
	[DeviasiUnit] [varchar](max) NULL,
	[DeviasiJenisPembiayaan] [varchar](200) NULL,
	[DeviasiNamaDebitur] [varchar](max) NULL,
	[DeviasiNamaAO] [varchar](max) NULL,
	[DeviasiTBO] [varchar](20) NULL,
	[KategoriDeviasi] [varchar](100) NULL,
	[DeviasiCIFDebitur] [varchar](30) NULL,
	[ActionPlan] [varchar](max) NULL,
 CONSTRAINT [PK_InternalMemo] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InternalMemoApprovalList]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[InternalMemoApprovalList](
	[DtlAppKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[NIK] [nvarchar](20) NULL,
	[Nama] [nvarchar](100) NULL,
	[Jabatan] [nvarchar](100) NULL,
	[IsDecision] [nvarchar](1) NULL,
	[DecisionState] [nvarchar](25) NULL,
	[DecisionDate] [datetime] NULL,
	[DecisionNote] [varchar](max) NULL,
	[Email] [nvarchar](100) NULL,
 CONSTRAINT [PK_InternalMemoApprovalList] PRIMARY KEY CLUSTERED 
(
	[DtlAppKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InternalMemoApprovalList_20220624]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[InternalMemoApprovalList_20220624](
	[DtlAppKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[NIK] [nvarchar](20) NULL,
	[Nama] [nvarchar](100) NULL,
	[Jabatan] [nvarchar](100) NULL,
	[IsDecision] [nvarchar](1) NULL,
	[DecisionState] [nvarchar](25) NULL,
	[DecisionDate] [datetime] NULL,
	[DecisionNote] [varchar](max) NULL,
	[Email] [nvarchar](100) NULL,
 CONSTRAINT [PK_InternalMemoApprovalList_20220624] PRIMARY KEY CLUSTERED 
(
	[DtlAppKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InternalMemoApprovalTemplate]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[InternalMemoApprovalTemplate](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[DocType] [int] NULL,
	[Seq] [int] NULL,
	[NIK] [varchar](20) NULL,
	[Nama] [varchar](200) NULL,
	[Jabatan] [varchar](50) NULL,
	[Email] [varchar](200) NULL,
	[Area] [varchar](100) NULL,
	[CreatedBy] [varchar](20) NULL,
	[CreatedDate] [datetime] NULL,
	[ModdifiedBy] [varchar](20) NULL,
	[ModdifiedDate] [datetime] NULL,
 CONSTRAINT [PK_InternalMemoApprovalTemplate] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InternalMemoDetailBiayaBulanan]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InternalMemoDetailBiayaBulanan](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[Keterangan] [nvarchar](max) NULL,
	[Periode] [nvarchar](50) NULL,
	[Remark1] [nvarchar](max) NULL,
	[Remark2] [nvarchar](max) NULL,
	[Total] [decimal](18, 2) NULL,
 CONSTRAINT [PK_InternalMemoDetailBiayaBulanan] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[InternalMemoDetailDeviasi]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[InternalMemoDetailDeviasi](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[Perihal] [varchar](max) NULL,
	[Alasan] [varchar](max) NULL,
	[Action] [varchar](max) NULL,
	[Deadline] [datetime] NULL,
	[Status] [varchar](20) NULL,
	[UpdateBy] [varchar](20) NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_InternalMemoDetailDeviasi] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InternalMemoDetailException]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[InternalMemoDetailException](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[Perihal] [varchar](max) NULL,
	[Alasan] [varchar](max) NULL,
	[MitigasiResiko] [varchar](max) NULL,
 CONSTRAINT [PK_InternalMemoDetailException] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InternalMemoDetailFreeText]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[InternalMemoDetailFreeText](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[FreeTextFile] [varbinary](max) NULL,
 CONSTRAINT [PK_InternalMemoDetailFreeText] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InternalMemoDetailPelepasanCrossColl]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InternalMemoDetailPelepasanCrossColl](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[AgreementNo] [nvarchar](30) NULL,
	[AssetDesc] [nvarchar](250) NULL,
	[ValueAsset] [decimal](18, 2) NULL,
	[OSPH] [decimal](18, 2) NULL,
	[CicilanTenor] [nvarchar](10) NULL,
	[DendaBerjalan] [decimal](18, 2) NULL,
	[AssetYear] [int] NULL,
	[AssetNTF] [decimal](18, 0) NULL,
 CONSTRAINT [PK_InternalMemoDetailPelepasanCrossColl] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[InternalMemoDetailPemakaianCashColl]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InternalMemoDetailPemakaianCashColl](
	[DtlKey] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[AssetDesc] [nvarchar](250) NULL,
	[NoRangka] [nvarchar](100) NULL,
	[NoMesin] [nvarchar](100) NULL,
	[Tahun] [nvarchar](5) NULL,
 CONSTRAINT [PK_InternalMemoDetailPemakaianCashColl] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[InternalMemoDetailPendingGiro]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InternalMemoDetailPendingGiro](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[NamaDebitur] [nvarchar](250) NULL,
	[AgreementNo] [nvarchar](30) NULL,
	[NamaBank] [nvarchar](100) NULL,
	[NoGiro] [nvarchar](100) NULL,
	[NominalGiro] [decimal](18, 2) NULL,
	[AngsuranDariKe] [nvarchar](20) NULL,
	[TglJatuhTempo] [datetime] NULL,
	[LamaPenundaan] [decimal](18, 2) NULL,
	[TglDiJalankanKembali] [datetime] NULL,
	[GiroOverdue] [int] NULL,
	[TglJalanGiro] [datetime] NULL,
 CONSTRAINT [PK_InternalMemoDetailPendingGiro] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[InternalMemoDetailPurchaseRequest]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InternalMemoDetailPurchaseRequest](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[NamaBarang] [nvarchar](250) NULL,
	[Kategori] [nvarchar](25) NULL,
	[Qty] [decimal](18, 2) NULL,
	[Spesifikasi] [nvarchar](max) NULL,
	[Keterangan] [nvarchar](max) NULL,
	[IsBudget] [nvarchar](1) NULL,
 CONSTRAINT [PK_InternalMemoDetailPurchaseRequest] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[InternalMemoStateHistory]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[InternalMemoStateHistory](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[NIK] [varchar](20) NULL,
	[Nama] [varchar](100) NULL,
	[State] [varchar](50) NULL,
	[Note] [varchar](max) NULL,
	[DateState] [datetime] NULL,
	[DiffTime] [int] NULL,
 CONSTRAINT [PK_InternalMemoStateHistory] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[InternalMemoType]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InternalMemoType](
	[DocValue] [int] NOT NULL,
	[DocDesc] [nvarchar](150) NULL,
 CONSTRAINT [PK_InternalMemoType] PRIMARY KEY CLUSTERED 
(
	[DocValue] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MASTER_USER]    Script Date: 8/2/2023 10:44:09 AM ******/
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
/****** Object:  Table [dbo].[PeminjamanDokumen]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PeminjamanDokumen](
	[DocKey] [int] NOT NULL,
	[DocNo] [nvarchar](50) NULL,
	[DocDate] [datetime] NULL,
	[DocCategory] [varchar](50) NULL,
	[Department] [nvarchar](50) NULL,
	[Status] [nvarchar](20) NULL,
	[Keperluan] [nvarchar](100) NULL,
	[Remark] [nvarchar](250) NULL,
	[TglPeminjaman] [datetime] NULL,
	[TglPengembalian] [datetime] NULL,
	[CreatedBy] [varchar](10) NULL,
	[CreatedDateTime] [datetime] NULL,
	[LastModifiedBy] [nvarchar](50) NULL,
	[LastModifiedDateTime] [datetime] NULL,
	[IsApprove] [varchar](1) NULL,
	[NextApprover] [varchar](100) NULL,
	[CustodianApprover] [varchar](10) NULL,
	[CustodianDecision] [varchar](20) NULL,
	[DecicionNote] [varchar](100) NULL,
	[DecicionDate] [datetime] NULL,
 CONSTRAINT [PK_PeminjamanDokumen] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PeminjamanDokumenApprovalList]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PeminjamanDokumenApprovalList](
	[DtlAppKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[NIK] [nvarchar](20) NULL,
	[Nama] [nvarchar](100) NULL,
	[Jabatan] [nvarchar](100) NULL,
	[IsDecision] [nvarchar](1) NULL,
	[DecisionState] [nvarchar](25) NULL,
	[DecisionDate] [datetime] NULL,
	[DecisionNote] [nvarchar](250) NULL,
	[Email] [nvarchar](100) NULL,
 CONSTRAINT [PK_PeminjamanDokumenApprovalList] PRIMARY KEY CLUSTERED 
(
	[DtlAppKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PeminjamanDokumenCategory]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PeminjamanDokumenCategory](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Category] [nvarchar](50) NULL,
	[UserApproval] [varchar](20) NULL,
 CONSTRAINT [PK_DokumenPeminjamanCategory] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PeminjamanDokumenDetail]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PeminjamanDokumenDetail](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[DocID] [varchar](20) NULL,
	[Description] [nvarchar](50) NULL,
	[Status] [nvarchar](50) NULL,
 CONSTRAINT [PK_PeminjamanDokumenDetail] PRIMARY KEY CLUSTERED 
(
	[DtlKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PeminjamanDokumenHistory]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PeminjamanDokumenHistory](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DocKey] [int] NULL,
	[DocNo] [varchar](50) NULL,
	[DocDate] [datetime] NULL,
	[DocCategory] [varchar](50) NULL,
	[Department] [varchar](50) NULL,
	[PengajuanStatus] [varchar](50) NULL,
	[Keperluan] [varchar](255) NULL,
	[Remarks] [varchar](255) NULL,
	[TglPeminjaman] [datetime] NULL,
	[TglPengembalian] [datetime] NULL,
	[DocID] [varchar](20) NULL,
	[DocDesc] [varchar](255) NULL,
	[DocStatus] [varchar](20) NULL,
	[CreatedBy] [varchar](10) NULL,
	[CreatedDate] [datetime] NULL,
 CONSTRAINT [PK_PeminjamanDokumenHistory] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Registry]    Script Date: 8/2/2023 10:44:09 AM ******/
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
/****** Object:  Table [dbo].[Session]    Script Date: 8/2/2023 10:44:09 AM ******/
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
/****** Object:  Table [dbo].[tempFreeText23dec]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tempFreeText23dec](
	[DtlKey] [int] NOT NULL,
	[DocKey] [int] NULL,
	[Seq] [int] NULL,
	[FreeTextFile] [varbinary](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UserDokumenCategory]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserDokumenCategory](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[Category] [varchar](50) NULL,
	[UserID] [varchar](20) NULL,
	[IsApprover] [varchar](1) NULL,
 CONSTRAINT [PK_UserDokumenCategory] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Users]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[NIK] [nvarchar](20) NOT NULL,
	[FULLNAME] [nvarchar](500) NOT NULL,
	[HEAD] [nvarchar](500) NULL,
	[HEADNAME] [nvarchar](500) NULL,
	[CCODE] [nvarchar](500) NOT NULL,
	[PASSWORD] [nvarchar](500) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[WorkList]    Script Date: 8/2/2023 10:44:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkList](
	[DocKey] [int] IDENTITY(1,1) NOT NULL,
	[SourceKey] [int] NULL,
	[DocNo] [nvarchar](50) NULL,
	[DocType] [nvarchar](100) NULL,
	[UserKey] [nvarchar](20) NULL,
	[UserName] [nvarchar](100) NULL,
	[CreatedMemoBy] [nvarchar](100) NULL,
 CONSTRAINT [PK_WorkList] PRIMARY KEY CLUSTERED 
(
	[DocKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[MASTER_USER] ADD  CONSTRAINT [DF_MASTER_USER_PASSWORD_APPROVAL]  DEFAULT ((1)) FOR [PASSWORD_APPROVAL]
GO

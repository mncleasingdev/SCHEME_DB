USE [SMS]
GO
/****** Object:  StoredProcedure [dbo].[sp_MNCL_GetListSMS]    Script Date: 8/2/2023 10:50:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_MNCL_GetListSMS]
AS
 SELECT * FROM T_SMS WHERE SEND_STATUS = '0' 
 
 --AND LEFT(MSISDN,5) NOT IN
 -- ('62811',
	--'62812',
	--'62813',
	--'62821',
	--'62822',
	--'62823',
	--'62852',
	--'62853',
	--'62851')
GO
/****** Object:  Table [dbo].[T_SMS]    Script Date: 8/2/2023 10:50:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[T_SMS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SMS_DEPT] [varchar](4) NULL,
	[SMS_SUBJECT] [varchar](200) NULL,
	[MSISDN] [varchar](25) NULL,
	[SMS_MESSAGE] [varchar](350) NULL,
	[SEND_STATUS] [char](1) NULL,
	[SEND_DATE] [datetime] NULL,
	[CREATE_DATE] [datetime] NULL,
	[CREATOR] [varchar](25) NULL,
	[SENDER_NAME] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[T_SMS_20190722]    Script Date: 8/2/2023 10:50:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[T_SMS_20190722](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SMS_DEPT] [varchar](4) NULL,
	[SMS_SUBJECT] [varchar](200) NULL,
	[MSISDN] [varchar](25) NULL,
	[SMS_MESSAGE] [varchar](350) NULL,
	[SEND_STATUS] [char](1) NULL,
	[SEND_DATE] [datetime] NULL,
	[CREATE_DATE] [datetime] NULL,
	[CREATOR] [varchar](25) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[T_SMS_20220406]    Script Date: 8/2/2023 10:50:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[T_SMS_20220406](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SMS_DEPT] [varchar](4) NULL,
	[SMS_SUBJECT] [varchar](200) NULL,
	[MSISDN] [varchar](25) NULL,
	[SMS_MESSAGE] [varchar](350) NULL,
	[SEND_STATUS] [char](1) NULL,
	[SEND_DATE] [datetime] NULL,
	[CREATE_DATE] [datetime] NULL,
	[CREATOR] [varchar](25) NULL,
	[SENDER_NAME] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

USE [BI]
GO
/****** Object:  StoredProcedure [dbo].[Proc_SA_StockReport_Detail]    Script Date: 2020/7/2 16:42:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================

-- Author:		DAVIS

-- Structure Tree:

-->LAYOUT A
---->COMPANY TYPE
------>CALCULATE ITEM (REMAINING)
-->LAYOUT B
---->CALCULATE ITEM (TO BE RECEIVE)
-->LAYOUT C
---->CALCULATE ITEM (WHS RETURN)
-->LAYOUT D
---->COMPANY TYPE
------>CALCUALATE ITEM (CMP)

-- =============================================
ALTER PROCEDURE  [dbo].[Proc_SA_StockReport_Detail]
@ISLATE INT, @CALCULATE_ITEM NVARCHAR(20),@SHOPID NVARCHAR(100),@COMPANY NVARCHAR(100),@COMPANY_TYPE NVARCHAR(100),@REGION NVARCHAR(100),@LAYOUT NVARCHAR(10)
AS 

BEGIN
--set @ISLATE = 1
--set @COMPANY_TYPE = 'Web'
--
--set @Company = 'WebShop'
--set @CALCULATE_ITEM = 'return'
--set @REGION = 'Web'
--set @LAYOUT = 'C'

IF(@LAYOUT = 'A')
BEGIN
    IF EXISTS(SELECT * FROM SYSOBJECTS WHERE ID = OBJECT_ID(N'#SA_StockReport_Detail_A'))
    DROP TABLE #SA_StockReport_Detail_A
    CREATE TABLE #SA_StockReport_Detail_A
    (   
    [ShopID] NVARCHAR(100)
	, [Name] NVARCHAR(100)
    ,[ItemNo] NVARCHAR(100)
    ,ItemImage NVARCHAR(100)
    ,Size NVARCHAR(20)
    ,Quantity INT
    ,Line NVARCHAR(100)
    ,Collection NVARCHAR(100)
    ,NavisionOrderID NVARCHAR(100)
    ,CustomerOrderID NVARCHAR(100)
    ,[Order Date] datetime
    ,[Shipment Date] datetime
    ,[Estimated Delivery Date] datetime
    ,Company NVARCHAR(100)
    ,Country NVARCHAR(100)
    ,Region NVARCHAR(20)
    ,CompanyType NVARCHAR(20)
    ,[Rating] INT
    ,[Status] NVARCHAR(20)
    )
  
    --remaining low
    IF(@COMPANY_TYPE IN ('Boutique' , 'Franchise', 'Web'))
    BEGIN
        IF(@CALCULATE_ITEM = 'low')
        BEGIN
    
        INSERT INTO #SA_StockReport_Detail_A
      
        Select a.[Sell-to Customer No_] as ShopID
        ,b.Name,a.No_ as ItemNo
        ,'http://10.0.20.15/photo/'+a.No_+'.jpg' AS ItemImage
        ,a.[Variant Code] AS Size,[Outstanding Quantity] as Quantity
        ,(CASE WHEN m.Collectionline_Code IS NULL THEN 'NA' Else m.Collectionline_Code End) as Line
        ,m.Collection_Name as Collection,[Document No_] as NavisionOrderID
        ,[Customer Order No_] AS CustomerOrderID,[Order Date],[Shipment Date]
        ,(case when m.Is_Custom_Made=1 then dateadd(day,15,[Shipment Date]) else [Estimated Delivery Date] end) as [Estimated Delivery Date]
        ,b.Company,cr.Country_Name as Country,(Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end) as Region
		,@COMPANY_TYPE as  Company_type
        ,CASE WHEN m.[Rating] = 'Other' THEN '0' else m.[Rating] end as [Rating]
        ,aa.[Status]
        FROM [New_SR_SalesLine_BlanketOrder] a
        Inner Join F_PRD_PRODUCT m on a.No_=m.Prod_Id
         and m.Rating = '1' and m.Prod_Class=1
        Inner Join (
		select Company_Id [Company],Cust_Id [ShopCode],Type ClientType,Country_Id [Country_Region Code],Cust_Name Name
		from F_PTY_CLIENT_CUST with (nolock)
		where Blocked<>3
			AND Type IN (1,2)
			and ((Company_Id='E02N' and Cust_Id not in ('TH01','VN01')) or (Company_Id ='APM Monaco China'))
			) B 
			ON a.[Sell-to Customer No_] = b.ShopCode
        Inner Join [New_SR_Shop_Franchise] d on d.ShopID=a.[Sell-to Customer No_]
        Left Join F_CM_DIM_REGION CR with (nolock) on B.[Country_Region Code]=CR.Country_Id
        Left Join 
        (SELECT Prod_Id,size
            ,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
            FROM [F_PRD_PROD_STATUS_DAILY]
            where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
			) aa
            on a.No_ = aa.Prod_Id and a.[Variant Code] = aa.Size
            where
            a.[No_] NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826') 
         --and (@ISLATE = 0) or (@ISLATE = 1 and [Estimated Delivery Date] <dateadd(day,-1,Convert(date,getdate())))
			and case when @ISLATE = 0 THEN -1 ELSE [Estimated Delivery Date] END <dateadd(day,-1,Convert(date,getdate()))
            and case when @ShopID='-1' then '-1' else [Sell-to Customer No_] end =@ShopID and -- USING "-1 = -1" method to drill up
            case when @Company='-1' then '-1' else d.Company end =@Company and 
            case when @Region='-1' then '-1' else (Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end) end =@Region
        END
    
        ELSE IF(@CALCULATE_ITEM = 'access')
        BEGIN
     
			INSERT INTO #SA_StockReport_Detail_A
    
     --remaining access
			Select a.[Sell-to Customer No_] as ShopID
			,b.Name,a.No_ as ItemNo
			,'http://10.0.20.15/photo/'+a.No_+'.jpg' AS ItemImage
			,a.[Variant Code] AS Size,[Outstanding Quantity] as Quantity
			,(CASE WHEN m.Collectionline_Code IS NULL THEN 'NA' Else m.Collectionline_Code End) as Line
			,m.Collection_Name as Collection,[Document No_] as NavisionOrderID
			,[Customer Order No_] AS CustomerOrderID,[Order Date],[Shipment Date]
			,(case when m.Is_Custom_Made=1 then dateadd(day,15,[Shipment Date]) else [Estimated Delivery Date] end) as [Estimated Delivery Date]
			,b.Company,cr.Country_Name as Country,(Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end) as Region
			,@COMPANY_TYPE as  Company_type
			,CASE WHEN m.[Rating] = 'Other' THEN '0' else m.[Rating] end as [Rating]
			,aa.[Status]
			FROM [New_SR_SalesLine_BlanketOrder] a
			Inner Join F_PRD_PRODUCT m on a.No_=m.Prod_Id
			and m.Prod_Class=3
			Inner Join (
				select Company_Id [Company],Cust_Id [ShopCode],Type ClientType,Country_Id [Country_Region Code],Cust_Name Name
				from F_PTY_CLIENT_CUST with (nolock)
				where Blocked<>3
				AND Type IN (1,2)
				and ((Company_Id='E02N' and Cust_Id not in ('TH01','VN01')) or (Company_Id ='APM Monaco China'))
				) B 
				ON a.[Sell-to Customer No_] = b.ShopCode
			Inner Join [New_SR_Shop_Franchise] d on d.ShopID=a.[Sell-to Customer No_]
			Left Join F_CM_DIM_REGION CR with (nolock) on B.[Country_Region Code]=CR.Country_Id
			Left Join 
				(SELECT Prod_Id,size
				,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
				FROM [F_PRD_PROD_STATUS_DAILY]
				where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
				) aa
			on a.No_ = aa.Prod_Id and a.[Variant Code] = aa.Size
            where a.[No_] NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826') and a.OrderStatus=1
			and case when @ISLATE = 0 THEN -1 ELSE [Estimated Delivery Date] END <dateadd(day,-1,Convert(date,getdate()))
            --and [Estimated Delivery Date] <dateadd(day,-1,Convert(date,getdate()))
            and case when @ShopID='-1' then '-1' else [Sell-to Customer No_] end =@ShopID and 
            case when @Company='-1' then '-1' else d.Company end =@Company and 
            case when @Region='-1' then '-1' else Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end end =@Region
        END
    
        ELSE IF(@CALCULATE_ITEM = 'cust_order')
      
		BEGIN
			INSERT INTO #SA_StockReport_Detail_A
  
			Select a.[Sell-to Customer No_] as ShopID
			,b.Name,a.No_ as ItemNo
			,'http://10.0.20.15/photo/'+a.No_+'.jpg' AS ItemImage
			,a.[Variant Code] AS Size,[Outstanding Quantity] as Quantity
			,(CASE WHEN m.Collectionline_Code IS NULL THEN 'NA' Else m.Collectionline_Code End) as Line
			,m.Collection_Name as Collection,[Document No_] as NavisionOrderID
			,[Customer Order No_] AS CustomerOrderID,[Order Date],[Shipment Date]
			,(case when m.Is_Custom_Made=1 then dateadd(day,15,[Shipment Date]) else [Estimated Delivery Date] end) as [Estimated Delivery Date]
			,b.Company,cr.Country_Name as Country,(Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end) as Region
			,@COMPANY_TYPE as  Company_type
			,CASE WHEN m.[Rating] = 'Other' THEN '0' else m.[Rating] end as [Rating]
			,aa.[Status]
			FROM [New_SR_SalesLine_BlanketOrder] a
			Inner Join F_PRD_PRODUCT m on a.No_=m.Prod_Id
			and m.Prod_Class<>3
			Inner Join (
				select Company_Id [Company],Cust_Id [ShopCode],Type ClientType,Country_Id [Country_Region Code],Cust_Name Name
				from F_PTY_CLIENT_CUST with (nolock)
				where Blocked<>3
				AND Type IN (1,2,3)
				and ((Company_Id='E02N' and Cust_Id not in ('TH01','VN01')) or (Company_Id ='APM Monaco China'))
				) B 
			ON a.[Sell-to Customer No_] = b.ShopCode
			Left Join F_CM_DIM_REGION CR with (nolock) on B.[Country_Region Code]=CR.Country_Id
			Left Join [New_SR_Shop_Franchise] d on d.ShopID=a.[Sell-to Customer No_]
			Left Join 
				(SELECT Prod_Id,size
				,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
				FROM [F_PRD_PROD_STATUS_DAILY]
				where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
				) aa
            on a.No_ = aa.Prod_Id and a.[Variant Code] = aa.Size
			where a.[Sales Class] in (1,5) and a.[No_] NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826')
		    and  ([Sell-to Customer No_] in (SELECT distinct [ShopID] FROM [Analytics].[dbo].[New_SR_Shop_Franchise]) or b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') ) 
			and case when @ISLATE = 0 THEN -1 ELSE [Estimated Delivery Date] END <dateadd(day,-1,Convert(date,getdate()))
			and case when @ShopID='-1' then '-1' else [Sell-to Customer No_] end =@ShopID 
			and case when @Company='-1' then '-1' else case when isnull(d.Company,'')='' then 'WebShop' else d.Company end end =@Company
			and case when @Region='-1' then '-1' else (Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end)  end =@Region

		END

		--Ignore this.
		ELSE IF(@CALCULATE_ITEM = 'CMP')
		
		BEGIN

			INSERT INTO #SA_StockReport_Detail_A

			Select a.[Sell-to Customer No_] as ShopID
			,b.Name,a.No_ as ItemNo
			,'http://10.0.20.15/photo/'+a.No_+'.jpg' AS ItemImage
			,a.[Variant Code] AS Size,[Outstanding Quantity] as Quantity
			,(CASE WHEN m.Collectionline_Code IS NULL THEN 'NA' Else m.Collectionline_Code End) as Line
			,m.Collection_Name as Collection,[Document No_] as NavisionOrderID
			,[Customer Order No_] AS CustomerOrderID,[Order Date],[Shipment Date]
			--,(case when m.Is_Custom_Made=1 then dateadd(day,15,[Shipment Date]) else [Estimated Delivery Date] end) as [Estimated Delivery Date]
			,[Estimated Delivery Date]
			,b.Company,cr.Country_Name as Country,(Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end) as Region
			,@COMPANY_TYPE as  Company_type
			,CASE WHEN m.[Rating] = 'Other' THEN '0' else m.[Rating] end as [Rating]
			,aa.[Status]  
			FROM [New_SR_SalesLine_BlanketOrder] a
			Inner Join F_PRD_PRODUCT m on a.No_=m.Prod_Id
			and m.Prod_Class<>3
			Inner Join (
				select Company_Id [Company],Cust_Id [ShopCode],Type ClientType,Country_Id [Country_Region Code],Cust_Name Name
				from F_PTY_CLIENT_CUST with (nolock)
				where Blocked<>3
				AND Type IN (1,2,3)
				and ((Company_Id='E02N' and Cust_Id not in ('TH01','VN01')) or (Company_Id ='APM Monaco China'))
				) B 
			ON a.[Sell-to Customer No_] = b.ShopCode
			Left Join F_CM_DIM_REGION CR with (nolock) on B.[Country_Region Code]=CR.Country_Id
			Left Join [New_SR_Shop_Franchise] d on d.ShopID=a.[Sell-to Customer No_]
			Left Join 
			(SELECT Prod_Id,size
				,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
				FROM [F_PRD_PROD_STATUS_DAILY]
				where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
				) aa
            on a.No_ = aa.Prod_Id and a.[Variant Code] = aa.Size
            where  a.[Sales Class] in (1,5) AND M.Is_Custom_Made = 1
			and a.No_ NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826') 
			and case when @ISLATE = 0 THEN -1 ELSE [Estimated Delivery Date] END <dateadd(day,-1,Convert(date,getdate()))
			and case when @ShopID='-1' then '-1' else [Sell-to Customer No_] end =@ShopID 
			and case when @Company='-1' then '-1' else case when isnull(d.Company,'')='' then 'WebShop' else d.Company end end =@Company
			and case when @Region='-1' then '-1' else (Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end)  end =@Region

		END




	  
		ELSE IF(@CALCULATE_ITEM = 'total')
     
		BEGIN
  
			INSERT INTO #SA_StockReport_Detail_A
  
			Select a.[Sell-to Customer No_] as ShopID
			,b.Name,a.No_ as ItemNo
			,'http://10.0.20.15/photo/'+a.No_+'.jpg' AS ItemImage
			,a.[Variant Code] AS Size,[Outstanding Quantity] as Quantity
			,(CASE WHEN m.Collectionline_Code IS NULL THEN 'NA' Else m.Collectionline_Code End) as Line
			,m.Collection_Name as Collection,[Document No_] as NavisionOrderID
			,[Customer Order No_] AS CustomerOrderID,[Order Date],[Shipment Date]
			,(case when m.Is_Custom_Made=1 then dateadd(day,15,[Shipment Date]) else [Estimated Delivery Date] end) as [Estimated Delivery Date]
			,b.Company,cr.Country_Name as Country,(Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end) as Region
			,@COMPANY_TYPE as  Company_type
			,CASE WHEN m.[Rating] = 'Other' THEN '0' else m.[Rating] end as [Rating]
			,aa.[Status]
			FROM [New_SR_SalesLine_BlanketOrder] a
			Inner Join F_PRD_PRODUCT m on a.No_=m.Prod_Id
			and m.Prod_Class<>3
			Inner Join (
				select Company_Id [Company],Cust_Id [ShopCode],Type ClientType,Country_Id [Country_Region Code],Cust_Name Name
				from F_PTY_CLIENT_CUST with (nolock)
				where Blocked<>3
				AND Type IN (1,2)
				and ((Company_Id='E02N' and Cust_Id not in ('TH01','VN01')) or (Company_Id ='APM Monaco China'))
				) B 
			ON a.[Sell-to Customer No_] = b.ShopCode
			Inner Join [New_SR_Shop_Franchise] d on d.ShopID=a.[Sell-to Customer No_]
			Left Join F_CM_DIM_REGION CR with (nolock) on B.[Country_Region Code]=CR.Country_Id
			Left Join 
			(SELECT Prod_Id,size
				,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
				FROM [F_PRD_PROD_STATUS_DAILY]
				where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
				) aa
            on a.No_ = aa.Prod_Id and a.[Variant Code] = aa.Size
			where a.[No_] NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826')
			and case when @ISLATE = 0 THEN -1 ELSE [Estimated Delivery Date] END <dateadd(day,-1,Convert(date,getdate()))
			AND case when @ShopID='-1' then '-1' else [Sell-to Customer No_] end =@ShopID and 
			case when @Company='-1' then '-1' else d.Company end =@Company and
			case when @Region='-1' then '-1' else Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end end =@Region
  	
		END
  	
    END
  -----------------------
  
    ELSE IF(@COMPANY_TYPE='Wholesale') 
    BEGIN
		IF(@CALCULATE_ITEM = 'total')
		BEGIN
  
		INSERT INTO #SA_StockReport_Detail_A
  
        Select a.[Sell-to Customer No_] as ShopID
        ,b.Name,a.No_ as ItemNo
        ,'http://10.0.20.15/photo/'+a.No_+'.jpg' AS ItemImage
        ,a.[Variant Code] AS Size
		,[Outstanding Quantity] as Quantity
        ,(CASE WHEN m.Collectionline_Code IS NULL THEN 'NA' Else m.Collectionline_Code End) as Line
        ,m.Collection_Name as Collection,[Document No_] as NavisionOrderID
        ,[Customer Order No_] AS CustomerOrderID
		,[Order Date]
		,[Shipment Date]
        ,(CASE WHEN [Estimated Delivery Date] <'2000-01-01 00:00:00.000' THEN NULL ELSE [Estimated Delivery Date] END) as [Estimated Delivery Date]
        ,'Wholesale' as Company
		,cr.Country_Name as Country
		,'Wholesale' as Region
		,'Wholesale' as CompanyType
        ,CASE WHEN m.[Rating] = 'Other' THEN '0' else m.[Rating] end as [Rating]
        ,aa.[Status]
        FROM [New_SR_SalesLine_BlanketOrder] a
        Inner Join F_PRD_PRODUCT m on a.No_=m.Prod_Id
        Inner Join (
		select Company_Id [Company],Cust_Id [ShopCode],Type ClientType,Country_Id [Country_Region Code],Cust_Name Name
		from F_PTY_CLIENT_CUST with (nolock)
		where  Blocked<>3
		and ((Company_Id='E02N' and Cust_Id not in ('TH01','VN01')) or (Company_Id ='APM Monaco China'))
		and Type<>1
		and Cust_Id not in ('TMALL','APMSTAFF','WECHAT')
		and Cust_Name not like 'Web%'
		and Cust_Name not like 'Wei%' 
		and Cust_Id not in (select distinct shopid from New_SR_Shop_Franchise) 
			) B 
			ON a.[Sell-to Customer No_] = b.ShopCode
        Left Join F_CM_DIM_REGION CR with (nolock) on B.[Country_Region Code]=CR.Country_Id
        Left Join 
        (SELECT Prod_Id,size
            ,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
            FROM [F_PRD_PROD_STATUS_DAILY]
            where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
			) aa
            on a.No_ = aa.Prod_Id and a.[Variant Code] = aa.Size
			where b.ClientType!=1 and [Sell-to Customer No_] not in ('TMALL','APMSTAFF','WECHAT') and b.Name not like 'Web%' and b.Name not like 'Wei%' and [Sell-to Customer No_] not in (select distinct shopid from New_SR_Shop_Franchise) 
			and a.[No_] NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826') and a.OrderStatus=1
			and case when @ISLATE = 0 THEN '-1' ELSE [Estimated Delivery Date] END <dateadd(day,-1,Convert(date,getdate()))
			and case when @ShopID='-1' then '-1' else [Sell-to Customer No_] end =@ShopID 
			and case when @Company='-1' then '-1' else 'Wholesale' end =@Company
			and case when @Region='-1' then '-1' else '_Wholesale' end  =@Region
  	
		END



    END

  	    IF EXISTS(SELECT * FROM #SA_StockReport_Detail_A)
	BEGIN
	SELECT * FROM #SA_StockReport_Detail_A
	END


--##########################
END

ELSE IF(@LAYOUT = 'B')

BEGIN

    IF EXISTS(SELECT * FROM SYSOBJECTS WHERE ID = OBJECT_ID(N'#SA_StockReport_Detail_B'))
    DROP TABLE #SA_StockReport_Detail_B
    CREATE TABLE #SA_StockReport_Detail_B
    (
    [ShopID] NVARCHAR(100)
    ,[Name] NVARCHAR(100)
    ,[TransferNo] NVARCHAR(100)
    ,[PostingDate] DATE
    ,[Actural Shipping Date] DATE
    ,[Express No_] NVARCHAR(100)
    ,[Express Recv_Date] DATE
    ,ItemImage NVARCHAR(100)
    ,[ItemNo] NVARCHAR(100)
    ,Size NVARCHAR(20)
    ,TobeReceived INT
    ,Collection NVARCHAR(100)
    ,CollectionLineName NVARCHAR(100)
    ,Country NVARCHAR(100)
    ,Region NVARCHAR(20)
    ,[LateDay] INT
    ,[Rating] INT
    ,[Status] NVARCHAR(20)
    )
  
    IF(@CALCULATE_ITEM='receive')
   
    BEGIN

   
		INSERT INTO #SA_StockReport_Detail_B


		Select 
		a.[Location_Code] as ShopID,b.Name
		,a.Order_No [TransferNo]
		,a.[Posting_Date]
		,e.[Actural_Shipping_Date]
		,e.[Express_No] as [Express No_]
		,e.[Express_Receive_Date] as [Express Recv_ Date]
		,'http://10.0.20.15/photo/'+a.Item_Id+'.jpg' AS ItemImage,
		a.Item_Id as [ItemNo],a.[Size],a.[Qty] AS [TobeReceived]
		,m.Collection_Name,m.Collectionline_Code
		,cr.Country_Name as Country,cr.Region,-s.ExpectedShippingDays as LateDay
		,case when m.[Rating] = 'other' then 0 else [Rating] end [Rating],aa.[Status]
		FROM 
		F_PHA_Purch_Order a
		Inner Join F_PRD_PRODUCT m on a.Item_Id=m.Prod_Id  AND m.Prod_Class<>3
		Inner Join [New_SR_Shop_Franchise] b on a.[Location_Code] =b.ShopID and b.[Client Type] IN (1,2)
		Left Join F_CM_DIM_REGION cr with (nolock) on b.[Country_Region Code]=CR.Country_Id
		Left Join 
		(SELECT [Company_Id]
			,[Document_No]
			,[Order_Date]
			,[Shipment_Date]
			,(CASE WHEN CAST([Actural_Shipping_Date] as date)<'2000-01-01' THEN NULL ELSE CAST([Actural_Shipping_Date] as date) END) [Actural_Shipping_Date]
			,[Sell_To_Customer_Id]
			,[Document_Type]
			,[Order_No]
			,[External_Document_No]
			,(CASE WHEN CAST([Express_Receive_Date] AS DATE)<'2000-01-01' THEN NULL ELSE [Express_Receive_Date] END) [Express_Receive_Date]
			,[Customer_Order_No]
			,Express_No
		FROM [BI].[dbo].[F_SAL_Company_Prod_Sales]
		where [External_Document_No] <> ''
		and [Company_Id] in ('APM Monaco China','E02N')
		AND [Document_Type] = 2
		group by [Company_Id]
			,[Document_No]
			,[Order_Date]
			,[Shipment_Date]
			,[Actural_Shipping_Date]
			,[Sell_To_Customer_Id]
			,[Document_Type]
			,[Order_No]
			,[External_Document_No]
			,[Express_Receive_Date]
			,[Customer_Order_No]
			,Express_No) e 
		on a.Order_No=e.External_Document_No and a.[Posting_Date]=e.Shipment_Date AND a.[Location_Code]=e.Sell_To_Customer_Id
		left join [New_SR_DIM_ExpectedShippingDays] s on cr.Region=s.Region
		Left Join 
		(SELECT Prod_Id
			,[Size]
			,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
		FROM [F_PRD_PROD_STATUS_DAILY]
		where [Etl_Date] = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])) aa
		on m.Prod_Id = aa.Prod_Id and a.Size = aa.Size
		Where a.Outstanding_Qty<>0 and a.Type = 2 AND Order_Type = 1
		--and a.Order_Type IN (1,5)
		and a.Item_Id NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826')
		and case when @ISLATE = 0 THEN -1 ELSE CAST(A.Posting_Date AS DATETIME) END <dateadd(day,-1,Convert(date,getdate()))
		and case when @ShopID='-1' then '-1' else [Location_Code] end =@ShopID and 
		case when @Company='-1' then '-1' else b.Company end =@Company and 
		case when @Region='-1' then '-1' else cr.Region end =@Region
 
		UNION ALL

		Select [Transfer_To_Code] as ShopID,d.Name
		,a.[Transfer_No]
		,a.[Etl_Date] AS [PostingDate]
		,[Shipment_Date] AS [Actural Shipping Date]
		,'' AS [Express No_]
		,[Receipt_Date] AS [Express Recv_ Date]
		,'http://10.0.20.15/photo/'+a.Item_No+'.jpg' AS ItemImage
		,a.[Item_No],a.Size,[Qty_To_Receive] as [TobeReceived],m.Collection_Name as Collection
		,m.Collectionline_Code as CollectionLineName,cR.Country_Name AS Country
		,cR.Region,-s.ExpectedShippingDays as [LateDay]
		,case when m.[Rating] = 'other' then 0 else [Rating] end [Rating],aa.[Status]
        FROM [F_TRF_Transfer_Order] a with (nolock)
 		Inner Join F_PRD_PRODUCT m on a.Item_No=m.Prod_Id
		and m.Prod_Class<>3
		Inner Join [New_SR_Shop_Franchise] d on d.ShopID=a.[Transfer_To_Code] and d.[Client Type] IN (1,2)
		Left Join F_CM_DIM_REGION CR with (nolock) on d.[Country_Region Code]=CR.Country_Id
		left join [New_SR_DIM_ExpectedShippingDays] s on cr.Region=s.Region
		Left Join 
		(SELECT Prod_Id,size
			,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
			FROM [F_PRD_PROD_STATUS_DAILY]
			where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
			) aa
        on a.Item_No = aa.Prod_Id and a.Size = aa.Size
        where m.Prod_Id NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826')
		--and (@ISLATE = 0) or (@ISLATE = 1 and a.Etl_Date< DATEADD(DAY,-s.ExpectedShippingDays,CONVERT(DATE,GETDATE())))
		AND case when @ISLATE = 0 THEN -1 ELSE CAST(A.ETL_DATE AS DATETIME)  END < DATEADD(DAY,-s.ExpectedShippingDays,CONVERT(DATE,GETDATE()))
		and case when @ShopID='-1' then '-1' else [Transfer_to_Code] end =@ShopID and 
		case when @Company='-1' then '-1' else d.Company end =@Company and 
		case when @Region='-1' then '-1' else cr.Region end =@Region

	END

	IF EXISTS(SELECT * FROM #SA_StockReport_Detail_B)
	BEGIN
	SELECT * FROM #SA_StockReport_Detail_B
	END

END

ELSE IF(@LAYOUT = 'C')

BEGIN

IF EXISTS(SELECT * FROM SYSOBJECTS WHERE ID = OBJECT_ID(N'#SA_StockReport_Detail_C'))
    DROP TABLE #SA_StockReport_Detail_C
    CREATE TABLE #SA_StockReport_Detail_C
    (
    [ShopID] NVARCHAR(100)
    ,[Name] NVARCHAR(100)
	,Order_No NVARCHAR(100)
	,[Posting_Date] datetime
    ,ItemImage NVARCHAR(100)
	,[ItemNo] NVARCHAR(100)
    ,Size NVARCHAR(20)
    ,TobeReceive INT
    ,Line NVARCHAR(100)
    ,Collection NVARCHAR(100)
    ,Country NVARCHAR(100)
    ,Region NVARCHAR(20)
	,LateDay int
    ,[Rating] INT
    ,[Status] NVARCHAR(20)
    )


	IF(@CALCULATE_ITEM = 'return')
		
	BEGIN
		
	INSERT INTO #SA_StockReport_Detail_C

	Select a.Location_Code as ShopID
	,b.Name
	,a.Order_No
	,Posting_Date
	,'http://10.0.20.15/photo/'+a.Item_Id+'.jpg' AS ItemImage
	,a.Item_Id as ItemNo
	,a.Size AS Size
	,a.Outstanding_Qty as TobeReceived
	,(CASE WHEN m.Collectionline_Code IS NULL THEN 'NA' Else m.Collectionline_Code End) as Line
	,m.Collection_Name as Collection
	--,(case when m.Is_Custom_Made=1 then dateadd(day,15,[Shipment_Date]) else Estimated_Delivery_Date end) as [Estimated Delivery Date]
	,cr.Country_Name as Country
	,(Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end) as Region
	,-s.ExpectedShippingDays as Lateday
	,CASE WHEN m.[Rating] = 'Other' THEN '0' else m.[Rating] end as [Rating]
	,aa.[Status]
	FROM F_PHA_Purch_Order  a
	Inner Join F_PRD_PRODUCT m on a.Item_Id=m.Prod_Id
	and m.Prod_Class<>3
	Inner Join (
	select Company_Id [Company],Cust_Id [ShopCode],Type ClientType,Country_Id [Country_Region Code],Cust_Name Name
		from F_PTY_CLIENT_CUST with (nolock)
		where Blocked<>3
			AND Type IN (1,2)
			and ((Company_Id='E02N' and Cust_Id not in ('TH01','VN01')) or (Company_Id ='APM Monaco China'))
		) B 
		ON a.Location_Code = b.ShopCode
		Inner Join [New_SR_Shop_Franchise] d on d.ShopID=a.Location_Code and d.[Client Type] IN (1,2)
		Left Join F_CM_DIM_REGION CR with (nolock) on B.[Country_Region Code]=CR.Country_Id
		left join [New_SR_DIM_ExpectedShippingDays] s on cr.Region=s.Region
		Left Join 
		(SELECT Prod_Id,size
			,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
			FROM [F_PRD_PROD_STATUS_DAILY]
			where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
			) aa
           on a.Item_Id = aa.Prod_Id and a.Size = aa.Size
           where  a.Order_Type=5 and  m.Prod_Id NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826')		   
		and a.Location_Code<>'' and a.Outstanding_Qty<>0
		AND case when @ISLATE = 0 THEN -1 ELSE CAST(a.[Posting_Date] AS DATETIME) END < DATEADD(DAY,-s.ExpectedShippingDays,CONVERT(DATE,GETDATE()))
		and case when @ShopID='-1' then '-1' else A.Location_Code end =@ShopID and 
		case when @Company='-1' then '-1' else d.Company end =@Company and 
		case when @Region='-1' then '-1' else cr.Region end =@Region

	UNION ALL

	Select a.Location_Code as ShopID
	,b.Name
	,a.Order_No
	,Posting_Date
	,'http://10.0.20.15/photo/'+a.Prod_Id+'.jpg' AS ItemImage
	,a.Prod_Id as ItemNo
	,a.Size AS Size
	,a.Outstanding_Qty as TobeReceived
	,(CASE WHEN m.Collectionline_Code IS NULL THEN 'NA' Else m.Collectionline_Code End) as Line
	,m.Collection_Name as Collection
	--,(case when m.Is_Custom_Made=1 then dateadd(day,15,[Shipment_Date]) else Estimated_Delivery_Date end) as [Estimated Delivery Date]
	,cr.Country_Name as Country
	,(Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end) as Region
	,-s.ExpectedShippingDays as Lateday
	,CASE WHEN m.[Rating] = 'Other' THEN '0' else m.[Rating] end as [Rating]
	,aa.[Status]
	FROM F_SAL_Sales_Order  a
	Inner Join F_PRD_PRODUCT m on a.Prod_Id=m.Prod_Id
	and m.Prod_Class<>3
	Inner Join (
	select Company_Id [Company],Cust_Id [ShopCode],Type ClientType,Country_Id [Country_Region Code],Cust_Name Name
		from F_PTY_CLIENT_CUST with (nolock)
		where Blocked<>3
			AND Type IN (1,2)
			and ((Company_Id='E02N' and Cust_Id not in ('TH01','VN01')) or (Company_Id ='APM Monaco China'))
		) B 
		ON a.Location_Code = b.ShopCode
		Inner Join [New_SR_Shop_Franchise] d on d.ShopID=a.Location_Code and d.[Client Type] IN (1,2)
		Left Join F_CM_DIM_REGION CR with (nolock) on B.[Country_Region Code]=CR.Country_Id
		left join [New_SR_DIM_ExpectedShippingDays] s on cr.Region=s.Region
		Left Join 
		(SELECT Prod_Id,size
			,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
			FROM [F_PRD_PROD_STATUS_DAILY]
			where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
			) aa
           on a.Prod_Id = aa.Prod_Id and a.Size = aa.Size
           where  a.Order_Type=5 and  m.Prod_Id NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826')		   
		and a.Location_Code<>'' and a.Outstanding_Qty<>0 and a.Sell_To_Customer_No <> ''
		AND case when @ISLATE = 0 THEN -1 ELSE CAST(a.[Posting_Date] AS DATETIME) END < DATEADD(DAY,-s.ExpectedShippingDays,CONVERT(DATE,GETDATE()))
		and case when @ShopID='-1' then '-1' else A.Location_Code end =@ShopID and 
		case when @Company='-1' then '-1' else d.Company end =@Company and 
		case when @Region='-1' then '-1' else cr.Region end =@Region

	END
	IF EXISTS(SELECT * FROM #SA_StockReport_Detail_C)
	BEGIN
	SELECT * FROM #SA_StockReport_Detail_C
	END
END

ELSE IF(@LAYOUT = 'D')
BEGIN
    IF EXISTS(SELECT * FROM SYSOBJECTS WHERE ID = OBJECT_ID(N'#SA_StockReport_Detail_D'))
    DROP TABLE #SA_StockReport_Detail_D
    CREATE TABLE #SA_StockReport_Detail_D
    (   
    [ShopID] NVARCHAR(100)
	, [Name] NVARCHAR(100)
    ,[ItemNo] NVARCHAR(100)
    ,ItemImage NVARCHAR(100)
	,[Product Type] NVARCHAR(100)
    ,Size NVARCHAR(20)
    ,Quantity INT
    ,Line NVARCHAR(100)
    ,Collection NVARCHAR(100)
    ,NavisionOrderID NVARCHAR(100)
    ,CustomerOrderID NVARCHAR(100)
	,[Filename of Image] NVARCHAR(50)
	,[Design Image] NVARCHAR(100)
	,[Document Date] date
    ,[Order Date] datetime
    ,[Shipment Date] datetime
    ,[Estimated Delivery Date] datetime
	,[To_No] NVARCHAR(100)
	,[To_Release_Date] datetime
	,[MO_No] nvarchar(100)
	,[MO_Release_Date] datetime
	,[MO_Due_Date] datetime
	,[MO_Operation_Status] NVARCHAR(20)
	,TransferShipmentDate datetime
	,[Operation Worker] NVARCHAR(100)
	,[CheckinTime] datetime
    ,Company NVARCHAR(100)
    ,Country NVARCHAR(100)
    ,Region NVARCHAR(20)
    ,CompanyType NVARCHAR(20)
    ,[Rating] INT
    ,[Status] NVARCHAR(20)
    )

		IF(@CALCULATE_ITEM = 'CMP')
		
		BEGIN

			INSERT INTO #SA_StockReport_Detail_D

			Select DISTINCT a.[Sell-to Customer No_] as ShopID
			,b.Name,a.No_ as ItemNo
			,'http://10.0.20.15/photo/'+a.No_+'.jpg' AS ItemImage
			,CASE WHEN TY.[Type] IS NULL THEN 'CMP' ELSE TY.[Type] END as [Product Type]
			,a.[Variant Code] AS Size,[Outstanding Quantity] as Quantity
			--,(CASE WHEN a.[Line No_] IS NULL THEN 'NA' Else a.[Line No_] End) as Line
			,a.[Line No_] as Line
			,m.Collection_Name as Collection,[Document No_] as NavisionOrderID
			,[Customer Order No_] AS CustomerOrderID
			,[File_Name_Image] as [Filename of Image]
			,'http://10.0.20.15/photoengraving/' + [File_Name_Image] as [Design Image]
			,a.[Document_Date] as [Document Date] 
			,[Order Date],[Shipment Date]
			--,(case when m.Is_Custom_Made=1 then dateadd(day,15,[Shipment Date]) else [Estimated Delivery Date] end) as [Estimated Delivery Date]
			,[Estimated Delivery Date]
			,[ExternalDocuNo] as [To_No]
			,T.[Document_Date] AS [To_Release_Date]
			,MO.[OrderNO] as [MO_No], MO.ReleasedDate as [MO_Release_Date],[Due_Date] as [MO_Due_Date]
			,CASE WHEN [CurrentOperation] IS NULL THEN 'NA' ELSE [CurrentOperation] END as [MO_Operation_Status]
			,S.Actual_Factory_Delivery_Date as TransferShipmentDate
			,E.Employee_Name [Operation Worker]
			,CASE WHEN CAST(RO.[CheckinTime] AS DATE) = '1753-01-01' THEN NULL ELSE RO.[CheckinTime] END AS [CheckinTime]
			,b.Company,cr.Country_Name as Country,(Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end) as Region
			,@COMPANY_TYPE as  Company_type
			,CASE WHEN m.[Rating] = 'Other' THEN '0' else m.[Rating] end as [Rating]
			,aa.[Status]  
			FROM [New_SR_SalesLine_BlanketOrder] a
			Inner Join F_PRD_PRODUCT m on a.No_=m.Prod_Id and m.Prod_Class<>3
			LEFT JOIN New_SR_DIM_CMP_Type TY on m.[Prod_Id] = TY.Item
			Inner Join (
				select Company_Id [Company],Cust_Id [ShopCode],Type ClientType,Country_Id [Country_Region Code],Cust_Name Name
				from F_PTY_CLIENT_CUST with (nolock)
				where Blocked<>3
				AND Type IN (1,2,3)
				and ((Company_Id='E02N' and Cust_Id not in ('TH01','VN01')) or (Company_Id ='APM Monaco China'))
				) B 
			ON a.[Sell-to Customer No_] = b.ShopCode
			Left Join F_CM_DIM_REGION CR with (nolock) on B.[Country_Region Code]=CR.Country_Id
			Left Join [New_SR_Shop_Franchise] d on d.ShopID=a.[Sell-to Customer No_]
			Left Join 
			(SELECT Prod_Id,size
				,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
				FROM [F_PRD_PROD_STATUS_DAILY]
				where Etl_Date = (select max(Etl_Date) from [F_PRD_PROD_STATUS_DAILY])
				) aa
            on a.No_ = aa.Prod_Id and a.[Variant Code] = aa.Size
			LEFT JOIN [BI].[dbo].[F_TRF_Transfer_Order] T
			ON A.[Document No_] = T.Request_Order_No and A.[Line No_] = T.Line_No AND A.No_ = T.Item_No AND A.[Variant Code] = T.Size
			LEFT JOIN [F_TRF_Transfer_Shipment] S 
			ON T.Transfer_No = S.Transfer_Order_No AND T.Company_Id = S.Company_Id AND T.Item_No = S.Item_No AND T.Size = S.Size
			LEFT JOIN [BI].[dbo].[F_MFG_Production_Order] MO 
			ON MO.[ExternalDocuNo] = T.Transfer_No AND MO.[OrderNO]=T.[Prod_Order_No] AND MO.Item = T.Item_No AND MO.Size = T.Size
			LEFT JOIN [F_MFG_Production_Routing] RO
			ON MO.Company_Id = RO.Company_Id AND MO.OrderNO = RO.OrderNo AND MO.Location_Code = RO.LocationCode AND MO.CurrentOperation = RO.OperationName
			LEFT JOIN F_PTY_Employee E ON RO.CheckinEmployee = E.Employee_Id AND RO.Company_Id = E.Company_Id
            where  a.[Sales Class] in (1,5) AND M.Is_Custom_Made = 1
			and a.No_ NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826')  
			and case when @ISLATE = 0 THEN -1 ELSE [Estimated Delivery Date] END <dateadd(day,-1,Convert(date,getdate()))
			and case when @ShopID='-1' then '-1' else [Sell-to Customer No_] end =@ShopID 
			and case when @Company='-1' then '-1' else case when isnull(d.Company,'')='' then 'WebShop' else d.Company end end =@Company
			and case when @Region='-1' then '-1' else (Case when b.[Name] like 'Web%' or b.[Name] in ('Tmall', 'weChat') then 'Web' Else cr.Region end)  end =@Region

		END

  -----------------------
  


  	IF EXISTS(SELECT * FROM #SA_StockReport_Detail_D)
	BEGIN
	SELECT * FROM #SA_StockReport_Detail_D
	END


--##########################
END



END

/*
 Select [Location Code] as ShopID
 ,b.Name
 ,a.[Document No_]
 ,[Posting Date],
'http://10.0.20.15/photo/'+a.Item+'.jpg' AS ItemImage
,a.[Item],a.[Size],[TobeReceived]
,m.[Collection],n.CollectionLineName
,c.Country,c.Region
,-s.ExpectedShippingDays as '-Day' ,m.[Rating],aa.[Status]
FROM [Analytics].[dbo].[New_SR_PurchaseLine] a
Inner Join [Analytics].[dbo].[DEF_Item] m on a.[Item]=m.Item AND a.[Size]=m.Size AND m.[ItemClass]<>3
Left Join [Analytics].[dbo].[DEF_CollectionLine] n on m.[Line]=n.CollectionLineCode
Inner Join [Analytics].[dbo].[New_SR_Shop_Franchise] b on a.[Location Code] =b.ShopID and b.[Client Type] IN (1,2)
Left Join [Analytics].[dbo].[DEF_country_region] c on b.[Country_Region Code]=c.ISO3
left join [Analytics].[dbo].[New_SR_ExpectedShippingDays] s on c.Region=s.Region
Left Join 
(SELECT [Item]
      ,[Size]
      ,(case when [Status] = 1 then 'non-active' else 'active' end) [Status]
  FROM [Analytics].[dbo].[DEF_ItemStatusDetail]
  where [Date] = (select max(Date) from [Analytics].[dbo].[DEF_ItemStatusDetail])) aa
  on m.Item = aa.Item and m.Size = aa.Size
Where a.[Document Type]=5 and a.Item NOT IN ('AV828Y','RV828','RV826','AV826Y','AV828BR','AV828','AV826BR','AV826')
*/ 
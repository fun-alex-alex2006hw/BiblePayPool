USE [biblepaypool]
GO
/****** Object:  StoredProcedure [dbo].[AdjustUserBalance]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

       
	  CREATE procedure [dbo].[AdjustUserBalance]
	  (@network varchar(20), @amt float, @userguid uniqueidentifier)

	  As 

	  IF (@network='main')
		  BEGIN
	 		Update Users set BalanceMain = isnull(BalanceMain,0) + @amt Where id = @userguid 
		  END
	  ELSE
	  	  BEGIN
			Update Users set BalanceTest = isnull(BalanceTest,0) + @amt Where id = @userguid 
		  END

	       

GO
/****** Object:  StoredProcedure [dbo].[Credit]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

       
	   CREATE procedure [dbo].[Credit]

	  (@userguid uniqueidentifier, @amount money)

	  As 

	  
	  declare @txid as varchar(100)
	  set @txid = cast(newid() as varchar(50))
	  declare @oldbalance float
	   select @oldbalance=balancemain from users where id= @userguid

	  Update Users set balancemain=balancemain+@amount where id=@userguid

	  -- add a credit memo to the txlog

	  Insert into TransactionLog (id,height,transactionid,username,userid,transactiontype,destination,amount,oldbalance,newbalance,added,updated,networkid,notes) 
		 VALUES
		 (newid(), 99999, @txid, '', @userguid, 'CREDIT_MEMO',
		 '', @amount, @oldbalance, @oldBalance+@amount, getdate(),getdate(),'main','CREDIT_MEMO')


		 update requestlog set txid='CreditMemo' where userguid=@userguid and txid like '%err%' and amount=@amount
GO
/****** Object:  StoredProcedure [dbo].[InsPayment]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
       
	   
	   
	  CREATE procedure [dbo].[InsPayment]
	  (@NetworkID varchar(100), 
	  @BlockDistGuid uniqueidentifier, 
	  @nHeight int,
	  @sUserName varchar(100),
	  @userGuid uniqueidentifier,
	  @CreditDesc varchar(100),
	  @subsidy float,
	  @stats varchar(4000)
	  ) 

				AS 
	
	 BEGIN

			declare @oldBalance float
			declare @newBalance float
			declare @PayCount as float
		 	Select @PayCount = isnull(count(*),0) From TransactionLog where transactionid = cast(@BlockDistGuid as varchar(120))
			
			if @PayCount = 0 
			BEGIN
				select @oldBalance = case when @networkid='main' then isnull(balanceMain,0) else isnull(balanceTest,0) end From Users where id=@userGuid
				select @newBalance = @oldBalance + @subsidy
			
  				Insert into transactionlog (id,height,transactionid,username,userid,transactiontype,destination,amount,oldbalance,newbalance,added,updated,rake,networkid,notes)
					values (newid(),
					@nHeight,@BlockDistGuid,
					@sUserName, @userGuid,
					@CreditDesc,
					@userGuid,@subsidy,@oldBalance,@newbalance,getdate(),getdate(),0,@NetworkID,
					@stats)

				Update Users set balanceMain=isnull(balanceMain,0)+@subsidy where id = @userGuid and @networkID='main'
				Update Users set balanceTest=isnull(balanceTest,0)+@subsidy where id = @userGuid and @networkID='test'
			END

		    Update Block_Distribution set Paid = getdate() where id = @BlockDistGuid
			
               
	 END
	 


                   
GO
/****** Object:  StoredProcedure [dbo].[InsTradeHistory]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
       
	   
	   
	  CREATE procedure [dbo].[InsTradeHistory]
	  (	  @TXID varchar(100) 	  ) 

				AS 
	
	 BEGIN

	   BEGIN
            Insert into TradeComplete
			Select * from trade where ExecutionTxid=@TXID
       END
	   Delete From Trade where ExecutionTxId = @TXID and ExecutionTxId in (Select ExecutionTxId from TradeComplete where Executiontxid= @TXID)
	 END
	 


                   
GO
/****** Object:  StoredProcedure [dbo].[InsTxLog]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

       
	  create procedure [dbo].[InsTxLog]
	  (@iHeight float, @TXID varchar(100),@username varchar(100),
	  @userguid varchar(100), @TxType varchar(100), @Destination varchar(100),
	  @amt float, @oldbalance float, @newbalance float, @networkid varchar(30),
	  @notes varchar(999))
	  
	  As 
	     Insert into TransactionLog (id,height,transactionid,username,userid,transactiontype,destination,amount,oldbalance,newbalance,added,updated,networkid,notes) 
		 VALUES
		 (newid(), @iHeight, @TXID, @username, @userguid, @TxType, @Destination, @Amt, @OldBalance, @newBalance, getdate(), getdate(), @networkid, @notes);
		 
GO
/****** Object:  StoredProcedure [dbo].[InsWork]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
       
	   
	   
	  CREATE procedure [dbo].[InsWork](@NetworkID varchar(100), @minerid uniqueidentifier, @ThreadID float, @MinerName varchar(200), @HashTarget varchar(200), @WorkId uniqueidentifier, @IP varchar(100)) 

				AS 
	
	 BEGIN
		Insert into Work (id,solution,networkid,minerid,minername,updated,added,hashtarget,starttime,endtime,hps,threadid,ip) 
		values (@workid,newid(),@networkid,@minerid,@minerName,getdate(),getdate(),@HashTarget,getdate(),null,0,@ThreadID,@IP)
	 END
	 


                   
GO
/****** Object:  StoredProcedure [dbo].[Maintenance]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

       
	   
	  CREATE procedure [dbo].[Maintenance]
	  
	  as
	
-- Defrag the most active tables

dbcc indexdefrag ( biblepaypool,'work','ClusteredIndex-20170918-211644')

dbcc indexdefrag (biblepaypool,'miners','UQ__Miners__F3DBC572AA8A8A98')

dbcc indexdefrag (biblepaypool,'block_distribution','UQ__block_di__7F957A3945A68BA1')

-- Archive the old info:

insert into block_distribution_history
Select * from block_distribution  where updated < getdate()-50
delete from block_distribution where updated < getdate()-50

-- Run a report on Fragmentation

SELECT dbschemas.[name] as 'Schema',
dbtables.[name] as 'Table',
dbindexes.[name] as 'Index',
indexstats.avg_fragmentation_in_percent,
indexstats.page_count
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
ORDER BY indexstats.avg_fragmentation_in_percent desc




                   

GO
/****** Object:  StoredProcedure [dbo].[OrderMatch]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
       
	   
	   
  	 CREATE procedure [dbo].[OrderMatch](@NetworkID varchar(100)) 

				AS 
	
	 BEGIN
	
	-- Note: This stored proc is not in production, it is in alpha testing
		
	--Delete old stuff
	Delete from Trade where Match is null and Added  < dateadd(minute,-(60*24),getdate()) and trade.EscrowTxId is null
	
	--update buy side
	Update buy set buy.match = sell.id
	From trade as buy 
	Inner join Trade as Sell on Buy.Quantity = Sell.Quantity  and sell.Act = 'Sell' 
	where 
	buy.match is null and sell.match is null 
	and buy.act = 'Buy' 
	and buy.price = sell.price 
	and buy.networkid=@NetworkID and sell.networkid=@NetworkID
	--update the sell side
	Update Sell set Sell.MatchSell = buy.id
	From trade as buy 
	inner join Trade as Sell on Buy.Quantity = Sell.Quantity  and sell.Act = 'Sell' 
	where buy.matchSell is null and sell.matchSell is null
	and buy.act = 'Buy' 
	and buy.price = sell.price and 
	buy.networkid=@NetworkID and sell.networkid=@NetworkID
	-- Mark escrow to go out that needs to go out
	Update Sell set Sell.EscrowApproved = getdate()
	from trade as buy 
	inner join Trade as Sell on sell.Act = 'Sell' and sell.MatchSell = buy.id
	where 
	buy.act = 'Buy' and buy.networkid=@NetworkID and sell.networkid=@NetworkID
	and buy.EscrowTxid is not null and sell.escrowTxId is not null 
		and sell.EscrowApproved is null
	Update Buy set Buy.EscrowApproved = getdate()
	From trade as buy 
	inner join Trade as Sell on sell.Act = 'Sell' and sell.MatchSell = buy.id
	Where 
	buy.act = 'Buy' and buy.networkid=@NetworkID and sell.networkid=@NetworkID
	and buy.EscrowTxid is not null and sell.escrowTxId is not null 
		and buy.EscrowApproved is null

	END
	 


                   
GO
/****** Object:  StoredProcedure [dbo].[PayBlockParticipants]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PayBlockParticipants]
	@NetworkID varchar(100)
AS


declare @id uniqueidentifier
declare @height int
declare @userid uniqueidentifier
declare @username varchar(100)
declare @subsidy float
declare @stats varchar(4000)

declare cur CURSOR LOCAL for
  Select id,height,userid,username,subsidy,stats From Block_Distribution (nolock) where paid is null and networkid = @NetworkID
            
open cur

	fetch next from cur into @id,@height,@userid,@username,@subsidy,@stats

	While @@FETCH_STATUS = 0 BEGIN
		--execute the InsPayment Proc for each row
		exec InsPayment @NetworkID, @id, @height,@username, @userid, 'MINING_CREDIT', @subsidy, @stats
		fetch next from cur into @id,@height,@userid,@username,@subsidy,@stats
	END

close cur
deallocate cur


	

GO
/****** Object:  StoredProcedure [dbo].[TxLogMaintenance]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

       
	   
	   
	  CREATE procedure [dbo].[TxLogMaintenance]
	 
	  (@enddate datetime)

	  as 

	  Delete from TransactionLog where networkid='testnet' and added < @enddate



Insert Into TransactionLog
select  newid()  id,
newid() transactionid,max(username) username,
max(userid) userid,
max(transactionType) transactionType,
max(destination) destination,sum(amount) amount,
avg(oldbalance) oldBalance,
avg(newbalance) newBalance,
max(added) Added,
max(updated) Updated,avg(rake) Rake,
max(networkid) NetworkID,
 max(notes) NOTES,
 max(height) Height,
 max(amount2) Amount2, 1 as LogType
 from TransactionLog 
 where
 transactionType='MINING_CREDIT'
 and added < @enddate and isnull(logtype,0)=0
 group by userid

 delete from TransactionLog where isnull(logType,0) =0 and Added < @enddate and transactionType='MINING_CREDIT'

 
  
  

Update TransactionLog set Amount2 = 1*Amount where TransactionType='MINING_CREDIT'


Update TransactionLog set amount2=-1*Amount where transactionType='Withdrawal'





GO
/****** Object:  StoredProcedure [dbo].[UpdatePool]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
      
	CREATE procedure [dbo].[UpdatePool](@sNetwork varchar(100)) 

				AS 
	

IF  (Select 	datediff(second, system.updated,getdate()) from system where systemkey='leaderboard_updated') > 60
BEGIN
BEGIN TRANSACTION;   
	update system set updated=getdate() where systemkey='leaderboard_updated'

	
	-- Delete work solved with modified clients reporting 0 total threads with work across threads
	Delete from work where minername in (select minername from (select max(threadid) t, count(*) c,minername from work group by minername) a where t = 0  and c > 100) and endtime is not null and starttime < dateadd(second,-500,getdate())
	Delete from work where ip in  (	select ip from (	select max(shares) t, count(*) c,ip from work group by ip 	) a where t > 125  and c > 100 ) 
	and endtime is not null and starttime < dateadd(second,-500,getdate())

	--Delete old work from all chains:  
	Delete from Work where starttime < dateadd(second,-1600,getdate())

	--Set the decay work on completed work
	Update work set Age = (100 - (((datediff(second, endtime,getdate())/50.01)*1.1)))/100  where 1=1 
	--Set the weight of each hashtarget
	Update work set chainwork = dbo.getweight(hashtarget) where chainwork is null
	
	--Set the shares done by worker
    UPDATE Work SET work.shares = (Select count(*) From Work  w with (nolock)  where w.minerid=work.minerid and endtime is not null and networkid='test') where networkid='test'
	UPDATE Work SET work.shares = (Select count(*) From Work  w with (nolock)  where w.minerid=work.minerid and endtime is not null and networkid='main') where networkid='main'

	--Set the totalshares of all workers
	Update work set work.totalshares = (Select count(*) from work with (nolock)  where endtime is not null and networkid='test') where networkid='test'
	Update work set work.totalshares = (Select count(*) from work with (nolock)  where endtime is not null and networkid='main') where networkid='main'

	--Set the elapsed time in seconds for work sent by pool that is completed
	Update work set work.HpsSecs = (Datediff(s, starttime, endtime+.0001)+0.0001) where endtime is not null

	--Set the simulated HPS for individual shares
	Update work set work.hpsRoot = 100000/work.HpsSecs where work.hpssecs is not null

	--Set the synthetic HPS (Age decayed) per completed record
	update work Set HpsEngineered =  shares * 1500
	update work set HPS = HpsEngineered * Age * 1.30 where 1=1

	-- Copy the sum of the HPS for the work records per miner back to the user record (this is used for block payments)
    Update Users Set Users.HpsTest=(
					 select sum(h) from (	Select avg(work.hps) h,miners.id From Work with (nolock) 
					 inner Join miners On Work.minerid=miners.id And miners.UserId=users.id Where EndTime Is Not null 
	  	  			 And hps > 0 And Work.networkid='test' group by miners.id) a ) 
	-- Copy for Main Chain
	Update Users Set Users.HpsMain=(
					 select sum(h) from (	Select avg(work.hps) h,miners.id From Work with (nolock) 
					 inner Join miners On Work.minerid=miners.id And miners.UserId=users.id Where EndTime Is Not null 
	  	  			 And hps > 0 And Work.networkid='main' group by miners.id) a ) 


	-- Copy the sum of the server HPS records back to user record (used for parentheses in Stats in block_distribution)
    Update Users set Users.BoxHpstest = (
			 select sum(h) from (	Select avg(work.boxhps) h,miners.id From Work with (nolock) 
					 inner Join miners On Work.minerid=miners.id And miners.UserId=users.id Where EndTime Is Not null 
	  	  			 And hps > 0 And Work.networkid='test' group by miners.id) a ) 

	Update Users set Users.BoxHpsMain = (
			 select sum(h) from (	Select avg(work.boxhps) h,miners.id From Work with (nolock) 
					 inner Join miners On Work.minerid=miners.id And miners.UserId=users.id Where EndTime Is Not null 
	  	  			 And hps > 0 And Work.networkid='main' group by miners.id) a ) 
 
 	-- Maintain a record of HPS per mining thread (used for police subsystem)
	Update Users set Users.ThreadHpsTest  = (Select avg(work.ThreadHPS) from Work  with (nolock) 
         	 inner join miners on work.minerid=miners.id  And Miners.UserId=Users.Id where endtime Is Not null and work.networkid='test')

	Update Users set Users.ThreadHpsMain  = (Select avg(work.ThreadHPS) from Work  with (nolock) 
         	 inner join miners on work.minerid=miners.id  And Miners.UserId=Users.Id where endtime Is Not null and work.networkid='main')

	-- Maintain a sum of thread counts per miner
	Update Miners set Miners.BoxHPStest = round((Select isnull(avg(work.boxhps),0) from Work with (nolock)  where Work.MinerId = Miners.Id and work.networkid = 'test'),2)
	Update Miners set Miners.BoxHPSmain = round((Select isnull(avg(work.boxhps),0) from Work with (nolock)  where Work.MinerId = Miners.Id and work.networkid = 'main'),2)
	
	Update Users Set Users.ThreadCountTest = (Select sum(miners.Threadstest)+1 from Miners where Miners.UserId=Users.Id)
	Update Users Set Users.ThreadBoxHPStest=Users.ThreadCounttest*Users.ThreadHPStest


	
	--Leaderboard


drop table leaderboardmain
Select 
newid() as id,
Users.username,
MinerName,
Round(Avg(work.BoxHPS),2) HPS,
round(avg(work.hps),2) as HPS2,
count(*) as shares,
max(endtime) as Reported,
max(endtime) as Added,
max(endtime) as Updated,
Users.Cloak 
into Leaderboardmain
from Work with (nolock) 
 inner join Miners with (nolock) on Miners.id = work.minerid  
 inner join Users with (nolock) on Miners.Userid = Users.Id  
 where Work.BoxHps > 0 and  work.hps > 0 and work.networkid='main'
   Group by Users.cloak,users.username,minername order by avg(work.boxhps) desc,MinerName



drop table leaderboardtest
Select 
newid() as id,
Users.username,MinerName,
Round(Avg(work.BoxHPS),2) HPS,
round(avg(work.hps),2) as HPS2,
count(*) as shares,
max(endtime) as Reported,
max(endtime) as Added,
max(endtime) as Updated,
Users.Cloak 
into Leaderboardtest
from Work with (nolock) 
 inner join Miners with (nolock) on Miners.id = work.minerid  
 inner join Users with (nolock) on Miners.Userid = Users.Id  
 where Work.BoxHps > 0 and  work.hps > 0 and work.networkid='test'
   Group by Users.cloak,users.username,minername order by avg(work.boxhps) desc,MinerName

   -- Main

drop table blockdistributionmain
Select top 512 block_distribution.id,users.username, block_distribution.height, block_distribution.block_subsidy, 
 block_distribution.subsidy, block_distribution.paid, block_distribution.hps, block_distribution.PPH, 
 block_distribution.updated,  users.cloak  
 into blockdistributionmain
 from block_distribution 
  inner join Users on users.id = block_distribution.userid WHERE Block_Distribution.NetworkID='main' order by height desc,subsidy desc

drop table blockdistributiontest
Select top 512 block_distribution.id,users.username, block_distribution.height, block_distribution.block_subsidy, 
 block_distribution.subsidy, block_distribution.paid, block_distribution.hps, block_distribution.PPH, 
 block_distribution.updated,  users.cloak  
 into blockdistributiontest
 from block_distribution 
  inner join Users on users.id = block_distribution.userid WHERE Block_Distribution.NetworkID='test' order by height desc,subsidy desc



COMMIT TRANSACTION;


END

GO
/****** Object:  UserDefinedFunction [dbo].[GetWeight]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetWeight](@shashtarget varchar(100)) 
       RETURNS int 
AS 
BEGIN; 
  DECLARE @Result float; 

  declare @sChunk varchar(10);
  set @sChunk = substring(@shashtarget,2,4);
  declare @component1 float;
  declare @in1 float;
  declare @in2 float;
  declare @in3 float;
  declare @in4 float;
  set @in1 = 10-cast(substring(@sChunk,1,1) as float);
  set @in2 = 10-cast(substring(@sChunk,2,1) as float);
  set @in3 = 10-cast(substring(@sChunk,3,1) as float);
  set @in4 = 10-cast(substring(@sChunk,4,1) as float);

  
  IF @in1 = 10  
  BEGIN
       SET @in1 = 325
  END

  IF @in1 = 9
  BEGIN
	SET @in1 = 256
  END

  if @in1 = 8
  BEGIN 
	set @in1 = 100
  END

  if @in1 = 7
  BEGIN
	set @in1 = 80
  END

  if @in1 = 6
  BEGIN 
  set @in1=60
  END

  if @in1=5
  BEGIN
	set @in1=50
  END

  set @component1 = (@in1 * 512) + (@in2 * 256) + (@in3 * 128) + (@in1 * 64);
  set @component1 = @component1 * 7.5;
  SET @Result = @component1;
  RETURN @Result; 
END;



GO
/****** Object:  Table [dbo].[Audit]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Audit](
	[id] [uniqueidentifier] NULL,
	[updated] [datetime] NULL,
	[ChainWork] [decimal](20, 0) NULL,
	[Elapsed] [float] NULL,
	[ElapsedClient] [float] NULL,
	[HPSClient] [float] NULL,
	[CalcHPS] [float] NULL,
	[networkid] [varchar](20) NULL,
	[IP] [varchar](100) NULL,
	[minername] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[block_distribution]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[block_distribution](
	[id] [uniqueidentifier] NULL,
	[height] [float] NULL,
	[updated] [datetime] NULL,
	[block_subsidy] [money] NULL,
	[subsidy] [money] NULL,
	[Paid] [datetime] NULL,
	[NetworkID] [varchar](30) NULL,
	[hps] [float] NULL,
	[userid] [uniqueidentifier] NULL,
	[stats] [varchar](3501) NULL,
	[UserName] [varchar](200) NULL,
	[PPH] [float] NULL,
UNIQUE NONCLUSTERED 
(
	[height] ASC,
	[userid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[block_distribution_history]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[block_distribution_history](
	[id] [uniqueidentifier] NULL,
	[height] [float] NULL,
	[updated] [datetime] NULL,
	[block_subsidy] [money] NULL,
	[subsidy] [money] NULL,
	[Paid] [datetime] NULL,
	[NetworkID] [varchar](30) NULL,
	[hps] [float] NULL,
	[userid] [uniqueidentifier] NULL,
	[stats] [varchar](3501) NULL,
	[UserName] [varchar](200) NULL,
	[PPH] [float] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[blockdistributionmain]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[blockdistributionmain](
	[id] [uniqueidentifier] NULL,
	[username] [varchar](100) NULL,
	[height] [float] NULL,
	[block_subsidy] [money] NULL,
	[subsidy] [money] NULL,
	[paid] [datetime] NULL,
	[hps] [float] NULL,
	[PPH] [float] NULL,
	[updated] [datetime] NULL,
	[cloak] [numeric](1, 0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[blockdistributiontest]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[blockdistributiontest](
	[id] [uniqueidentifier] NULL,
	[username] [varchar](100) NULL,
	[height] [float] NULL,
	[block_subsidy] [money] NULL,
	[subsidy] [money] NULL,
	[paid] [datetime] NULL,
	[hps] [float] NULL,
	[PPH] [float] NULL,
	[updated] [datetime] NULL,
	[cloak] [numeric](1, 0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[blocks]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[blocks](
	[id] [uniqueidentifier] NULL,
	[height] [float] NULL,
	[updated] [datetime] NULL,
	[subsidy] [money] NULL,
	[minerid] [uniqueidentifier] NULL,
	[NetworkID] [varchar](50) NULL,
	[MinerNameByHashPs] [varchar](100) NULL,
	[MinerNameWhoFoundBlock] [varchar](125) NULL,
	[BlockVersion] [varchar](30) NULL,
UNIQUE NONCLUSTERED 
(
	[height] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CryptoPrice]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CryptoPrice](
	[id] [uniqueidentifier] NULL,
	[Symbol] [varchar](10) NULL,
	[BTCPrice] [money] NULL,
	[BBPPrice] [money] NULL,
	[Added] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[dictionary]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dictionary](
	[Id] [uniqueidentifier] NULL,
	[TableName] [varchar](100) NULL,
	[FieldName] [varchar](100) NULL,
	[DataType] [varchar](50) NULL,
	[ParentTable] [varchar](100) NULL,
	[ParentFieldName] [varchar](100) NULL,
	[ParentGuiField1] [varchar](100) NULL,
	[ParentGuiField2] [varchar](100) NULL,
	[Caption] [varchar](200) NULL,
	[FieldSize] [numeric](6, 0) NULL,
	[FieldRows] [numeric](6, 0) NULL,
	[FieldCols] [numeric](6, 0) NULL,
	[ErrorText] [varchar](200) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Expense]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Expense](
	[id] [uniqueidentifier] NULL,
	[BatchId] [uniqueidentifier] NULL,
	[Added] [date] NULL,
	[Amount] [money] NULL,
	[OrphanPremiumsPaid] [float] NULL,
	[NewSponsorships] [float] NULL,
	[URL] [varchar](400) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Faucet]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Faucet](
	[id] [uniqueidentifier] NULL,
	[TransactionID] [varchar](200) NULL,
	[Amount] [float] NULL,
	[Added] [datetime] NULL,
	[Network] [varchar](50) NULL,
	[Height] [float] NULL,
	[IP] [varchar](200) NULL,
	[Address] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Forensic]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Forensic](
	[id] [uniqueidentifier] NULL,
	[amt] [float] NULL,
	[bal] [money] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Forensic2]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Forensic2](
	[id] [uniqueidentifier] NULL,
	[amt] [float] NULL,
	[bal] [money] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[invalidsolution]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[invalidsolution](
	[id] [uniqueidentifier] NULL,
	[added] [datetime] NULL,
	[IP] [varchar](100) NULL,
	[solution] [varchar](700) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Leaderboardmain]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Leaderboardmain](
	[id] [uniqueidentifier] NULL,
	[username] [varchar](100) NULL,
	[MinerName] [varchar](200) NULL,
	[HPS] [float] NULL,
	[HPS2] [float] NULL,
	[shares] [int] NULL,
	[Reported] [datetime] NULL,
	[Added] [datetime] NULL,
	[Updated] [datetime] NULL,
	[Cloak] [numeric](1, 0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Leaderboardtest]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Leaderboardtest](
	[id] [uniqueidentifier] NULL,
	[username] [varchar](100) NULL,
	[MinerName] [varchar](200) NULL,
	[HPS] [float] NULL,
	[HPS2] [float] NULL,
	[shares] [int] NULL,
	[Reported] [datetime] NULL,
	[Added] [datetime] NULL,
	[Updated] [datetime] NULL,
	[Cloak] [numeric](1, 0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Letters]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Letters](
	[id] [uniqueidentifier] NULL,
	[Body] [varchar](8000) NULL,
	[added] [datetime] NULL,
	[orphanid] [varchar](40) NULL,
	[userid] [uniqueidentifier] NULL,
	[username] [varchar](100) NULL,
	[name] [varchar](400) NULL,
	[Upvote] [float] NOT NULL,
	[Downvote] [float] NOT NULL,
	[Approved] [numeric](1, 0) NULL,
	[Sent] [numeric](1, 0) NULL,
	[Paid] [numeric](1, 0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LettersInbound]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LettersInbound](
	[id] [uniqueidentifier] NULL,
	[OrphanID] [varchar](40) NULL,
	[URL] [varchar](255) NULL,
	[Name] [varchar](200) NULL,
	[added] [date] NULL,
	[Page] [float] NULL,
	[Updated] [date] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LetterWritingFees]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LetterWritingFees](
	[id] [uniqueidentifier] NULL,
	[height] [float] NULL,
	[added] [datetime] NULL,
	[amount] [money] NULL,
	[networkid] [varchar](70) NULL,
	[quantity] [float] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Links]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Links](
	[id] [uniqueidentifier] NULL,
	[URL] [varchar](500) NULL,
	[Added] [datetime] NULL,
	[Userid] [uniqueidentifier] NULL,
	[PaymentPerClick] [float] NULL,
	[Budget] [float] NULL,
	[Clicks] [float] NULL,
	[Rewards] [float] NULL,
	[Notes] [varchar](1000) NULL,
	[OriginalURL] [varchar](1000) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Lookup]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Lookup](
	[id] [uniqueidentifier] NULL,
	[TableName] [varchar](100) NULL,
	[Field] [varchar](100) NULL,
	[FieldList] [varchar](999) NULL,
	[Method] [varchar](200) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[menu]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[menu](
	[id] [uniqueidentifier] NULL,
	[Hierarchy] [varchar](200) NULL,
	[Classname] [varchar](200) NULL,
	[added] [datetime] NULL,
	[DefaultURL] [varchar](255) NULL,
	[Method] [varchar](200) NULL,
	[deleted] [numeric](1, 0) NULL,
	[ordinal] [float] NULL,
	[Accountability] [numeric](1, 0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Metrics]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Metrics](
	[id] [uniqueidentifier] NULL,
	[Credits] [float] NULL,
	[Debits] [float] NULL,
	[WalletDebits] [float] NULL,
	[Added] [datetime] NULL,
	[network] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Miners]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Miners](
	[id] [uniqueidentifier] NULL,
	[Userid] [uniqueidentifier] NULL,
	[username] [varchar](100) NULL,
	[updated] [datetime] NULL,
	[added] [datetime] NULL,
	[LastLogin] [datetime] NULL,
	[workeraddress] [varchar](100) NULL,
	[Notes] [varchar](255) NULL,
	[ThreadsMain] [float] NULL,
	[ThreadsTest] [float] NULL,
	[BoxHPSMain] [float] NULL,
	[BoxHPSTest] [float] NULL,
	[getworks] [float] NULL,
	[Disabled] [numeric](1, 0) NULL,
	[HighHash] [float] NULL,
UNIQUE NONCLUSTERED 
(
	[username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Orders]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Orders](
	[id] [uniqueidentifier] NULL,
	[UserId] [uniqueidentifier] NULL,
	[ProductId] [varchar](100) NULL,
	[Added] [datetime] NULL,
	[Amount] [money] NULL,
	[Status1] [varchar](100) NULL,
	[Status2] [varchar](100) NULL,
	[Status3] [varchar](100) NULL,
	[MouseID] [varchar](100) NULL,
	[Updated] [datetime] NULL,
	[Title] [varchar](100) NULL,
	[TXID] [varchar](100) NULL,
	[WalletOrder] [numeric](1, 0) NULL,
	[WalletOrderProcessed] [numeric](1, 0) NULL,
	[Address] [varchar](100) NULL,
	[NetworkID] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[organization]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[organization](
	[id] [uniqueidentifier] NULL,
	[Name] [varchar](200) NULL,
	[Theme] [varchar](100) NULL,
	[Added] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[OrphanAuction]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrphanAuction](
	[id] [uniqueidentifier] NULL,
	[updated] [datetime] NULL,
	[BBPAmount] [money] NULL,
	[BTCRaised] [money] NULL,
	[BTCPrice] [money] NULL,
	[EstimatedOrphanBenefit] [float] NULL,
	[Amount] [money] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Orphans]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Orphans](
	[id] [uniqueidentifier] NULL,
	[OrphanID] [varchar](100) NULL,
	[Commitment] [money] NULL,
	[Notes] [varchar](1000) NULL,
	[Name] [varchar](200) NULL,
	[URL] [varchar](255) NULL,
	[added] [datetime] NULL,
	[updated] [datetime] NULL,
	[Frequency] [varchar](50) NULL,
	[Charity] [varchar](100) NULL,
	[Organization] [varchar](125) NULL,
	[NeedWritten] [float] NULL,
UNIQUE NONCLUSTERED 
(
	[OrphanID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Page]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Page](
	[id] [uniqueidentifier] NULL,
	[Name] [varchar](200) NULL,
	[Sections] [varchar](1000) NULL,
	[deleted] [numeric](1, 0) NULL,
	[Organization] [uniqueidentifier] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Picture]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Picture](
	[id] [uniqueidentifier] NULL,
	[added] [datetime] NULL,
	[deleted] [numeric](1, 0) NULL,
	[addedby] [uniqueidentifier] NULL,
	[organization] [uniqueidentifier] NULL,
	[ParentId] [uniqueidentifier] NULL,
	[Updated] [datetime] NULL,
	[UpdatedBy] [uniqueidentifier] NULL,
	[Dummy] [varchar](20) NULL,
	[Name] [varchar](400) NULL,
	[Extension] [varchar](5) NULL,
	[SAN] [varchar](500) NULL,
	[FullFileName] [varchar](100) NULL,
	[Size] [float] NULL,
	[URL] [varchar](300) NULL,
	[ParentType] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Products]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Products](
	[id] [uniqueidentifier] NULL,
	[productid] [varchar](125) NULL,
	[ShortDescription] [varchar](512) NULL,
	[Description] [varchar](4000) NULL,
	[Added] [datetime] NULL,
	[Pics] [varchar](2000) NULL,
	[Price] [money] NULL,
	[Shipping] [money] NULL,
	[Retailer] [varchar](100) NULL,
	[product_details] [varchar](4000) NULL,
	[title] [varchar](512) NULL,
	[NetworkID] [varchar](100) NULL,
	[InWallet] [numeric](1, 0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Proposal]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Proposal](
	[id] [uniqueidentifier] NULL,
	[Name] [varchar](750) NULL,
	[ReceiveAddress] [varchar](100) NULL,
	[Amount] [money] NULL,
	[URL] [varchar](2000) NULL,
	[UnixStartTime] [float] NULL,
	[UnixEndTime] [float] NULL,
	[PrepareTXID] [varchar](100) NULL,
	[Added] [datetime] NULL,
	[Updated] [datetime] NULL,
	[Hex] [varchar](4000) NULL,
	[SubmitTxId] [varchar](100) NULL,
	[Network] [varchar](100) NULL,
	[Prepared] [numeric](1, 0) NULL,
	[Submitted] [numeric](1, 0) NULL,
	[UserId] [uniqueidentifier] NULL,
	[UserName] [varchar](300) NULL,
	[PrepareTime] [datetime] NULL,
	[SubmitTime] [datetime] NULL,
	[GobjectID] [varchar](100) NULL,
	[AbsoluteYesCount] [float] NULL,
	[YesCount] [float] NULL,
	[NoCt] [float] NULL,
	[AbstainCount] [float] NULL,
	[Height] [float] NULL,
	[FundedTime] [datetime] NULL,
	[TriggerTxId] [varchar](100) NULL,
	[TriggerTime] [datetime] NULL,
	[PaidTime] [datetime] NULL,
	[SuperBlockTxId] [varchar](100) NULL,
	[MasternodeCount] [float] NULL,
	[budgetable] [numeric](1, 0) NULL,
	[resubmit] [varchar](3000) NULL,
	[expensetype] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RequestLog]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RequestLog](
	[id] [uniqueidentifier] NULL,
	[txid] [varchar](200) NULL,
	[amount] [money] NULL,
	[added] [datetime] NULL,
	[network] [varchar](10) NULL,
	[IP] [varchar](50) NULL,
	[Address] [varchar](100) NULL,
	[username] [varchar](100) NULL,
	[userguid] [uniqueidentifier] NULL,
	[UserGuid2] [uniqueidentifier] NULL,
	[username2] [varchar](100) NULL,
	[IP2] [varchar](100) NULL,
	[Processed] [numeric](1, 0) NULL,
	[Audited] [numeric](1, 0) NULL,
	[Questionable] [numeric](1, 0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Section]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Section](
	[id] [uniqueidentifier] NULL,
	[Name] [varchar](200) NULL,
	[Fields] [varchar](750) NULL,
	[deleted] [numeric](1, 0) NULL,
	[TableName] [varchar](200) NULL,
	[Organization] [uniqueidentifier] NULL,
	[DependentSection] [varchar](100) NULL,
	[DependentFields] [varchar](500) NULL,
	[Class] [varchar](200) NULL,
	[Method] [varchar](200) NULL,
	[FieldBackup] [varchar](3000) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SectionRules]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SectionRules](
	[id] [uniqueidentifier] NULL,
	[SectionID] [uniqueidentifier] NULL,
	[RuleText] [varchar](4000) NULL,
	[deleted] [numeric](1, 0) NULL,
	[Organization] [uniqueidentifier] NULL,
	[Added] [datetime] NULL,
	[addedby] [uniqueidentifier] NULL,
	[Updated] [datetime] NULL,
	[updatedby] [uniqueidentifier] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SentMoney]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SentMoney](
	[id] [uniqueidentifier] NULL,
	[TXID] [varchar](100) NULL,
	[Amount] [money] NULL,
	[Added] [datetime] NULL,
	[Network] [varchar](20) NULL,
	[IP] [varchar](50) NULL,
	[Address] [varchar](100) NULL,
	[username] [varchar](100) NULL,
	[userguid] [varchar](100) NULL,
	[RequestLogId] [uniqueidentifier] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[System]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[System](
	[id] [uniqueidentifier] NULL,
	[SystemKey] [varchar](100) NULL,
	[Value] [varchar](255) NULL,
	[Updated] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Ticket]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Ticket](
	[id] [uniqueidentifier] NULL,
	[Name] [varchar](250) NULL,
	[Description] [varchar](250) NULL,
	[SubmittedBy] [uniqueidentifier] NULL,
	[AssignedTo] [uniqueidentifier] NULL,
	[Disposition] [varchar](200) NULL,
	[Added] [datetime] NULL,
	[Updated] [datetime] NULL,
	[Deleted] [numeric](1, 0) NULL,
	[TicketNumber] [varchar](100) NULL,
	[Body] [varchar](4000) NULL,
	[UserText1] [varchar](200) NULL,
	[UpdatedBy] [uniqueidentifier] NULL,
	[ParentID] [uniqueidentifier] NULL,
	[Organization] [uniqueidentifier] NULL,
	[AddedBy] [uniqueidentifier] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TicketHistory]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TicketHistory](
	[id] [uniqueidentifier] NULL,
	[Body] [varchar](4000) NULL,
	[added] [datetime] NULL,
	[updated] [datetime] NULL,
	[Deleted] [numeric](1, 0) NULL,
	[AssignedTo] [uniqueidentifier] NULL,
	[Disposition] [varchar](200) NULL,
	[ParentId] [uniqueidentifier] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Trade]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Trade](
	[id] [uniqueidentifier] NULL,
	[Added] [datetime] NULL,
	[IP] [varchar](20) NULL,
	[Act] [varchar](20) NULL,
	[Symbol] [varchar](20) NULL,
	[Quantity] [float] NULL,
	[Price] [float] NULL,
	[Total] [float] NULL,
	[Address] [varchar](100) NULL,
	[Hash] [varchar](100) NULL,
	[Time] [float] NULL,
	[networkid] [varchar](50) NULL,
	[Match] [uniqueidentifier] NULL,
	[EscrowTXID] [varchar](100) NULL,
	[MatchSell] [uniqueidentifier] NULL,
	[ExecutionTxId] [varchar](100) NULL,
	[TotalEscrow] [float] NULL,
	[EscrowApproved] [datetime] NULL,
	[CreateRawHex] [varchar](50) NULL,
	[BroadcastHex] [varchar](50) NULL,
	[Executed] [datetime] NULL,
	[vout] [numeric](3, 0) NULL,
	[Err] [varchar](3000) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TradeComplete]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TradeComplete](
	[id] [uniqueidentifier] NULL,
	[Added] [datetime] NULL,
	[IP] [varchar](20) NULL,
	[Act] [varchar](20) NULL,
	[Symbol] [varchar](20) NULL,
	[Quantity] [float] NULL,
	[Price] [float] NULL,
	[Total] [float] NULL,
	[Address] [varchar](100) NULL,
	[Hash] [varchar](100) NULL,
	[Time] [float] NULL,
	[networkid] [varchar](50) NULL,
	[Match] [uniqueidentifier] NULL,
	[EscrowTXID] [varchar](100) NULL,
	[MatchSell] [uniqueidentifier] NULL,
	[ExecutionTxId] [varchar](100) NULL,
	[TotalEscrow] [float] NULL,
	[EscrowApproved] [datetime] NULL,
	[CreateRawHex] [varchar](50) NULL,
	[BroadcastHex] [varchar](50) NULL,
	[Executed] [datetime] NULL,
	[vout] [numeric](3, 0) NULL,
	[Err] [varchar](3000) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransactionLog]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TransactionLog](
	[id] [uniqueidentifier] NULL,
	[transactionid] [varchar](200) NULL,
	[username] [varchar](100) NULL,
	[userid] [uniqueidentifier] NULL,
	[transactiontype] [varchar](100) NULL,
	[destination] [varchar](100) NULL,
	[amount] [money] NULL,
	[oldbalance] [money] NULL,
	[newbalance] [money] NULL,
	[added] [datetime] NULL,
	[updated] [datetime] NULL,
	[rake] [money] NULL,
	[NetworkID] [varchar](30) NULL,
	[Notes] [varchar](4000) NULL,
	[Height] [float] NULL,
	[Amount2] [float] NULL,
	[LogType] [numeric](1, 0) NULL,
UNIQUE NONCLUSTERED 
(
	[transactionid] ASC,
	[NetworkID] ASC,
	[transactiontype] ASC,
	[amount] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Users]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Users](
	[id] [uniqueidentifier] NULL,
	[username] [varchar](100) NULL,
	[password] [varchar](350) NULL,
	[Email] [varchar](100) NULL,
	[updated] [datetime] NULL,
	[added] [datetime] NULL,
	[deleted] [numeric](1, 0) NULL,
	[FailedLoginAttempts] [numeric](4, 0) NULL,
	[LastLogin] [datetime] NULL,
	[WithdrawalAddress] [varchar](100) NULL,
	[LastFailedLoginDate] [datetime] NULL,
	[UserText1] [varchar](255) NULL,
	[ThreadBoxHPS] [float] NULL,
	[BoxHPSMain] [float] NULL,
	[BoxHPSTest] [float] NULL,
	[HPSMain] [float] NULL,
	[HPSTest] [float] NULL,
	[ThreadHPSMain] [float] NULL,
	[ThreadHPSTest] [float] NULL,
	[ThreadCountMain] [float] NULL,
	[ThreadCountTest] [float] NULL,
	[BalanceMain] [money] NULL,
	[Balancetest] [money] NULL,
	[ThreadBoxHPStest] [float] NULL,
	[HomogenizedHPSMain] [float] NULL,
	[HomogenizedHPSTest] [float] NULL,
	[ThreadBoxHPSMain] [float] NULL,
	[Cloak] [numeric](1, 0) NULL,
	[Organization] [uniqueidentifier] NULL,
	[Bug] [money] NULL,
	[DelName] [varchar](120) NULL,
	[Address1] [varchar](200) NULL,
	[Address2] [varchar](200) NULL,
	[City] [varchar](100) NULL,
	[State] [varchar](10) NULL,
	[Zip] [varchar](20) NULL,
	[Country] [varchar](120) NULL,
	[AddressVerified] [numeric](1, 0) NULL,
	[Phone] [varchar](20) NULL,
	[EmailVerified] [numeric](1, 0) NULL,
	[Withdraws] [float] NULL,
	[SendVerified] [numeric](1, 0) NULL,
UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Votes]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Votes](
	[id] [uniqueidentifier] NULL,
	[added] [datetime] NULL,
	[userid] [uniqueidentifier] NULL,
	[letterid] [uniqueidentifier] NULL,
	[upvote] [float] NOT NULL,
	[downvote] [float] NOT NULL,
	[IP] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Work]    Script Date: 12/24/2017 4:59:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Work](
	[id] [uniqueidentifier] NULL,
	[minerid] [uniqueidentifier] NULL,
	[minername] [varchar](200) NULL,
	[updated] [datetime] NULL,
	[added] [datetime] NULL,
	[hashtarget] [varchar](200) NULL,
	[starttime] [datetime] NULL,
	[endtime] [datetime] NULL,
	[hps] [float] NULL,
	[networkid] [varchar](20) NULL,
	[ThreadID] [float] NULL,
	[ThreadStart] [float] NULL,
	[HashCounter] [float] NULL,
	[TimerStart] [float] NULL,
	[TimerEnd] [float] NULL,
	[ThreadHPS] [float] NULL,
	[BoxHPS] [float] NULL,
	[ThreadWork] [float] NULL,
	[Age] [float] NULL,
	[Shares] [float] NULL,
	[HpsRoot] [float] NULL,
	[hpssecs] [float] NULL,
	[chainwork] [float] NULL,
	[totalshares] [float] NULL,
	[HPSEngineered] [float] NULL,
	[IP] [varchar](40) NULL,
	[Audited] [numeric](1, 0) NULL,
	[SharePercent] [float] NULL,
	[AvgShares] [float] NULL,
	[AvgHPS] [float] NULL,
	[Solution] [varchar](500) NULL,
	[solution2] [varchar](500) NULL,
	[OS] [varchar](50) NULL,
	[Validated] [numeric](1, 0) NULL,
	[Error] [varchar](300) NULL,
	[Nonce] [float] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[Letters] ADD  DEFAULT ((0)) FOR [Upvote]
GO
ALTER TABLE [dbo].[Letters] ADD  DEFAULT ((0)) FOR [Downvote]
GO
ALTER TABLE [dbo].[Letters] ADD  DEFAULT ((0)) FOR [Approved]
GO
ALTER TABLE [dbo].[Letters] ADD  DEFAULT ((0)) FOR [Sent]
GO
ALTER TABLE [dbo].[Letters] ADD  DEFAULT ((0)) FOR [Paid]
GO
ALTER TABLE [dbo].[menu] ADD  DEFAULT ((0)) FOR [ordinal]
GO

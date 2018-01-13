use master
create database BankSystem

use BankSystem
create table UserInfo
(
	U_ID char(18) primary key,
	U_NAME char(20) not null,
	U_Add varchar(100) not null,
	U_Tel char(20) not null,
	U_Sex char(2) not null
)

create table AdminInfo--银行员工
(
	A_ID char(18) primary key,
	A_NAME char(20) not null,
	A_Pro char(20) not null,
	A_Passwd char(6) not null
)
create table CardInfo
(
	U_ID char(18) foreign key references UserInfo(U_ID),
	A_ID char(18) foreign key references AdminInfo(A_ID),
	C_ID char(19) not null,
	Balance float,
	Passwd char(6) not null,      
	DateTime_C datetime not null,
	Card_State bit not null
	Constraint ck_banlance check(Balance>=0),
	Constraint pk_c primary key(U_ID,A_ID,DateTime_C),
	constraint uk_C unique(C_ID)
)
create table Rate--利率
(
	yearlength smallint not null,
	rate float not null

)
alter table Rate
add constraint pk_R primary key(yearlength)
create table Store
(
	U_ID char(18) foreign key references UserInfo(U_ID),
	A_ID char(18) foreign key references AdminInfo(A_ID),
	C_ID char(19) foreign key references CardInfo(C_ID),
	DateTime_S datetime not null,
	Much float not null,
	Kind smallint not null foreign key references Rate(yearlength),
	rate float not null,
	constraint pk_S primary key(C_ID,DateTime_S)
)
create table GetMoney
(
	U_ID char(18) foreign key references UserInfo(U_ID),
	A_ID char(18) foreign key references AdminInfo(A_ID),
	DateTime_G datetime not null,
	Much float not null,
	constraint pk_G primary key(U_ID,A_ID,DateTime_G)
)
create table SuperInfo--超级管理员
(
	ID char(18) primary key not null,
	passwd char(6) not null
)
create table Account
(
	ID int not null primary key,
	account char(19) not null unique,
	Ac_state bit not null
) 
go
create proc Pro_UserInfo @U_ID char(18),@U_NAME char(20),@U_Add varchar(100),@U_Tel char(20),@U_Sex char(2)
As 
	set nocount on
	if not exists(select* from UserInfo where @U_ID=U_ID)
		begin
			insert into UserInfo
			values(@U_ID,@U_NAME,@U_Add,@U_Tel,@U_Sex)
		end
go
--drop proc Pro_UserInfo
create proc Pro_CardInfo @U_ID char(18),@A_ID char(18),@C_ID char(19),@Passwd char(6),@Balance float,@msg char(20) output
AS
	
	if not exists(select * from CardInfo where C_ID=@C_ID)
		begin
			insert into CardInfo
			values(@U_ID,@A_ID,@C_ID,0,@Passwd,getdate(),1)
			select @msg = '开户成功!'
		end
	else
		select @msg = '开户失败，账户已存在!'
go
--drop proc Pro_CardInfo
create trigger add_Balance on Store for insert
AS
	update CardInfo
	set Balance += Much
	from inserted,CardInfo
	where inserted.C_ID=CardInfo.C_ID

go
create trigger del_CID on CardInfo for insert
AS
	update Account
	set Ac_state = 0
	from Account,inserted
	where inserted.C_ID=Account.account

	--drop trigger del_CID
--存储过程测试
Declare @msg char(20)
execute Pro_CardInfo '321321199511087238','202150401','6212263602015645319','123456',110,@msg output
print @msg
go
create proc Pro_Store @U_ID char(18),@A_ID char(18),@C_ID char(19),@Much float,@Kind smallint,@msg char(20) output
AS
	if exists(select* from Store where C_ID=@C_ID and Kind!=0)
		select @msg = '该账户为定期账户，不可再次存入！'
	else
	begin
		declare @rate float
		select @rate = rate
		from Rate
		where yearlength = @Kind
		insert into Store
		values(@U_ID,@A_ID,@C_ID,getdate(),@Much,@Kind,@rate)
		select @msg = '存款成功！'
	end
--drop proc Pro_Store
alter table Store
alter column rate float not null
declare @msg char(50)
execute  Pro_Zh '202150401','321321199511087238','6212263602015645305','6212263602015645303',21,@msg output
print @msg


go
create view view_zh(U_ID,A_NAME,C_ID1,C_ID2,much,ztime)
as
select U_ID,A_NAME,C_ID1,C_ID2,much,ztime
from zhuanzhang a,AdminInfo b
where a.A_ID=b.A_ID
select * from view_zh
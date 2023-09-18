use zhs;

set global local_infile = 1;   
 -- Loading csv file into table
LOAD DATA LOCAL INFILE 'C:/Users/mthokozisi/Desktop/ZHS Analytics/Projects/Laptops/archive 2/laptopData.csv'
INTO TABLE laptops
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 1. Checking the number of rows.
select count(*) from laptops;

-- 2. dropping unnecesary columns
alter table laptops 
drop column Unnamed_0;
 
-- 3. fixing empty cells to null values
set sql_safe_updates = 0;

update laptops
	set Company =  nullif(Company,'')
	   ,TypeName = nullif(TypeName,'')
       ,Inches = nullif(Inches,'')
	   ,ScreenResolution = nullif(ScreenResolution,'')
       ,Cpu_obs = nullif(Cpu_obs,'')
       ,Ram = nullif(Ram,'')
       ,Memory_obs = nullif(Memory_obs,'')
       ,Gpu = nullif(Gpu,'')
       ,OpSys = nullif(OpSys,'')
       ,Weight = nullif(Weight,'')
       ,Price = nullif(Price,'');

-- 4. droppimg null values
with index_values as (select index_id
from laptops
where Company is null
  and TypeName is null
  and Inches is null
  and ScreenResolution is null
  and Cpu_obs is null
  and Ram is null
  and Memory_obs is null
  and Gpu is null
  and OpSys is null
  and Weight is null
  and Price is null
)
 
delete laptops
from laptops
join index_values on laptops.index_id = index_values.index_id
where laptops.index_id = index_values.index_id;

-- 5. checking data types and fixing data types
select COLUMN_NAME, DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'laptops';

-- 5.1 inches modified to decimal
alter table laptops modify column Inches decimal(10,1);  

-- 5.2 modifying the price column
update laptops
set Price = round(Price);

alter table laptops modify column price integer;

-- 5.3 modifying the weight column
update laptops
set 
	Weight = replace(Weight,'kg','');

update laptops
set 
	Weight = 1.26
where
	Weight = '?';

alter table laptops modify column Weight decimal(10,2);  


-- 5.4 modifying the Ram column
update laptops
set 
	Ram = replace(Ram,'GB','');

alter table laptops modify column Ram integer;

-- 6. Creating new features
alter table laptops
add column resolution_width integer after ScreenResolution,
add column resolution_height integer after resolution_width;


-- 5.1 Extracting resolution width
update laptops 
set resolution_width = substring_index(substring_index(ScreenResolution,' ',-1),'x',-1) ;

-- 5.2 Extracting resolution height
update laptops 
set resolution_height = substring_index(substring_index(ScreenResolution,' ',-1),'x',1) ;

-- 5.3 Adding and updating new column
alter table laptops
add column is_touchscreen integer after ScreenResolution;

update laptops
set is_touchscreen = case when ScreenResolution like '%touchscreen%' then 1 else 0 end;

-- 5.4 Creating and updating new features
alter table laptops
add column cpu_brand varchar(255) after Cpu_obs,
add column cpu_name varchar(255) after cpu_brand,
add column cpu_speed decimal(10,1) after cpu_name;

update laptops 
	set cpu_brand = substring_index(Cpu_obs, ' ',1);
    
    update laptops 
    set cpu_speed = replace(substring_index(Cpu_obs,' ',-1),'GHz','');
    
    update laptops 
    set  cpu_name = replace(replace(Cpu_obs,cpu_brand,'' ),substring_index(Cpu_obs,' ',-1),'');

-- 5.5 Creating and updating new features
alter table laptops
add column memory_type varchar(255) after Memory_obs,
add column primary_storage int after memory_type,
add column secondary_storage int after primary_storage;

update laptops
set memory_type = case
when Memory_obs like '%ssd%' and Memory_obs like '%hhd%' then 'Hybrid'
when Memory_obs like '%flash storage%' and Memory_obs like '%hhd%' then 'Hybrid'
when Memory_obs like '%ssd%' then 'SSD'
when Memory_obs like '%hdd%' then 'HHD'
when Memory_obs like '%flash storage%' then 'Flash Storage'
else null
 end;

update laptops
set primary_storage = regexp_substr(substring_index(Memory_obs,'+',1),'[0-9]+'),
	secondary_storage = case when Memory_obs like '%+%' then regexp_substr(substring_index(Memory_obs,'+',-1),'[0-9]+') else 0 end;
    
update laptops
set primary_storage = case when primary_storage <=2 then primary_storage*1024 else primary_storage end,
	secondary_storage = case when secondary_storage <=2 then secondary_storage*1024 else secondary_storage end;
    
-- 5.6 Creating and updating new features    
alter table laptops
add column gpu_brand varchar(255) after Gpu,
add column gpu_name varchar(255) after gpu_brand;

update laptops
set gpu_brand = substring_index(Gpu, ' ',1);

update laptops
set gpu_name = replace(Gpu,gpu_brand,'');

-- 5.7 Updating OS feature

update laptops
set OpSys = case
			when OpSys like '%mac%' then 'macos'
            when OpSys like '%windows%' then 'windows'
            when OpSys like '%linux%' then 'linux'
            when OpSys like 'No OS' then 'N/A'
            else 'other'
            end;

    
select * from laptops









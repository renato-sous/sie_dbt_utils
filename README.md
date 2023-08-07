This sie-dbt-utils package contains macros that can be (re)used across dbt projects within Siemens.

----
# Contents

**[Installation](#installation)**

**[Versions](#versions)**

**[Macros](#macros)**

- [Siemens Utilities](#siemens-utilities):
    - [alphanum](#alphanum-source)
    - [array_to_in](#array_to_in-source)
    - [cast_masked_columns](#cast_masked_columns-source)
    - [current_environment](#current_environment-source)
    - [date_to_fiscal_period / to_fiscper](#date_to_fiscal_period-source)
    - [dynamic_limit](#dynamic_limit-source)
    - [dynamic_tablesample](#dynamic_tablesample-source)
    - [full_refresh_protection](#full_refresh_protection-source)
    - [get_fiscal_period / get_current_fiscal_period](#get_fiscal_period-source)
    - [get_fiscal_quarter / get_current_fiscal_quarter](#get_fiscal_quarter-source)
    - [neat_log](#neat_log-source)
    - [sap_to_date](#sap_to_date-source)
    - [sap_to_timestamp](#sap_to_timestamp-source)
    - [simple_cte](#simple_cte-source)
- [ERP Domain Functions](#erp_domain-functions):
    - [build_key_columns](#build_key_columns-source)
    - [stg_erpall](#stg_erpall-source)
- [SAP HANA Functions](#sap-hana-functions):
    - [add_workdays](#add_workdays-source)
    - [workdays_between](#workdays_between-source)

   <!-- - [create_model_HK](#create_model_hk-source)
    - [rename_column_dictionary](#rename_column_dictionary-source) -->
    
- [overriding](#macro-overriding):
    - Fully Qualified Names in Models ([generate_alias_name](#generate_alias_name-source))
    - [generate_schema_name](#generate_schema_name-source)
    - [create_schema](#create_schema-source)
    - [drop_schema](#drop_schema-source)
    - [dbt_utils.hash](#dbt_utilshash-source)
- [Operations](#macros-for-Operations):
    - [drop_old_relations](#drop_old_relations-source)
- [internal](#internal-macros)
    - [check_db_connection](#check_db_connection-source)



---
# Installation
In order to use this package in your dbt Cloud project, you need to add it to the `packages.yml` file.  
**Ensure that you are using the correction revision**

`packages.yml`
```yaml
packages:
  - git: "git@code.siemens.com:dbt-cloud-at-siemens/sie_dbt_utils.git" # git URL
    revision: "v0.2.4" # get the revision from the Release Notes
    #revision: "v0.2-latest" # this can be used to fetch always the patch corrections on the current minor release
```


To ensure the right dispatch sequence for the macro overriding, add the following lines to the `dbt_project.yml`.  
Ensure that you replace `<PROJNAME>`  with the correct `name:` that you have configured in the same file.

`dbt_project.yml`
```yaml
dispatch:
  - macro_namespace: dbt
    search_order: ['<PROJNAME>', 'sie_dbt_utils', 'dbt']

```

# Versions
The `sie_dbt_utils` package is now using the [SemVer versioning system](https://semver.org/). Each new release will have the format `vMAJOR.MINOR.PATCH`, (example `v.0.2.4`).  
For each `MAJOR.MINOR` version will exist also the `MAJOR.MINOR-latest` that will point to the most recent `PATCH` within. The  projects can use this version and ensure that the latests patches will always be obtained without having to manually change the `packages.yml`. examples are: `v0.1-latest` and `v0.2-latest`.  

Everytime that a new `MINOR` is released, it will have some impacting changes that might require your attention and prior tests before using it on the Productive environments.

Ensure to always check the latest releases on [sie_dbt_utils's Releases page](https://code.siemens.com/dbt-cloud-at-siemens/sie_dbt_utils/-/releases)

# Macros

## Siemens Utilities


### alphanum ([source](macros/utilities/alphanum.sql))
- Macro `alphanum` will fill numeric content with leading zeros up to target_length.
- In case the value has leading spaces, it is still considered numeric

#### Arguments
- `value_field` (required) : content for the alpha conversion
- `target_length` (required) : final lenght of the field. 

#### Usage
```sql
  -- Example
  select belnr,
       {{ sie_dbt_utils.alphanum('BELNR',10) }} as belnr_alphanum

  ---- gets converted into:
  -- select belnr,
  --      (case when REGEXP_LIKE (BELNR,$$^\s*\d+$$) then lpad(ltrim(BELNR),10,'0') 
  --           else BELNR 
  --       end) as belnr_alphanum
```

### array_to_in ([source](macros/utilities/array_to_in.sql))
- Macro `array_to_in` generates a string with the list of values in a SQL IN format.
- Sometimes in Jinja we have a list of values that we would like to apply directly to the SQL Queries, and this macro converts it easily.

#### Parameters.
 * `array` array(string): Message to present (up to 80 characters)

#### Syntax.
```sql
{{ sie_dbt_utils.array_to_in(<array_varible>) }}


```

#### Usage.
- The macro will return the SQL List with all the values on the Jinja Array
```sql
Examples :
  -- using a Jinja variable <my_arr>
    {%set my_arr = ['ABCD', 'EFGH'] }}
    WHERE BUKRS in {{ sie_dbt_utils.array_to_in(my_arr)}}
    --> WHERE BUKRS in ('ABCD', 'EFGH')

  -- directly writing the Jinja Array/List
  select * from mytable
    WHERE GJAHR in {{ sie_dbt_utils.array_to_in(['2021','2022', '2023'])}}
    --> select * from mytable
    --    WHERE GJAHR in ('2021','2022', '2023')

```



### cast_masked_columns ([source](#))
- Macro `cast_masked_columns` intents to solve an issue that happens in dbt when materializing columns that have Masking Policies, while in Development Environment. 
- The error happens when the column is a varchar( less than 32 ), and the masking policy will deliver an hashed value with 32 characters. It will not be able to insert the record in the new dbt Table and fails.
- The macro will do the cast to a desired length ONLY when the role being used is `*_RESTRICTED`.

#### Parameters.
 * `column_name` (string): column_name that will be cast as VARCHAR(<length>)
 * `length` (integer): new length to apply to this column


#### Syntax.
```sql
{{ sie_dbt_utils.cast_masked_columns(<column_name>, [length]) }}

```

#### Usage.
- The macro will return a cast for the `column_name` with the desired `length` while in the `DEV` environment:  
```sql
-- Examples (in DEV environment using *_DEVELOPER role):
    {{ sie_dbt_utils.cast_masked_columns('usnam')}}
    --> cast( usnam as varchar(32) ) as usnam
    {{ sie_dbt_utils.cast_masked_columns('usnam', 64)}}
    --> cast( usnam as varchar(64) ) as usnam
    {{ sie_dbt_utils.cast_masked_columns('usnam', 2)}}
    --> cast( usnam as varchar(2) ) as usnam

--Examples ( in QUA or PRD environments ):
    {{ sie_dbt_utils.cast_masked_columns('usnam')}}
    --> usnam
    {{ sie_dbt_utils.cast_masked_columns('usnam', 64)}}
    --> usnam
    {{ sie_dbt_utils.cast_masked_columns('usnam', 2)}}
    --> usnam

```



### current_environment ([source](#))
- Macro `current_environment` will return the environment according to the `target.database`. The result can be one of the following values: `[DEV, QUA, PRD]`
- ...  

#### Usage.
- Regular call for the macro within models. For instance, if you want to limit the data while working on the DEV environment.
- The macro cannot be used within yaml files.
```sql
 {{ sie_dbt_utils.current_environment() }}

 -- Example to limit the data while in DEV enviroment
 select *
from {{ source('snowflake_info', 'VIEWS')}}

 {% if sie_dbt_utils.current_environment() == 'DEV' -%}
-- in Development mode, so let's limit the result to 345 lines
   limit 345
 {%- endif -%}
```

#### Features

* The result can be one of the following values: `[DEV, QUA, PRD]`  



### date_to_fiscal_period ([source](macros/utilities/date_to_fiscal_period.sql))
- Macro `date_to_fiscal_period` converts any date value (either from a column, fixed value or a function) into the corresponding fiscal period in the format `yyyy0mm`
#### short form
Macro `to_fiscper` can also be used as short form.



#### Syntax.
```sql
{{ sie_dbt_utils.date_to_fiscal_period(<date_value>, [out_format]) }}

-- date_value: value in Date format
-- out_format (optional): string format to retrieve the fiscal date.
--              Examples for input '2022-08-16' -> Fiscal Period 2022011:
--                        'yyyy0mm' (default) --> '2022011'
--                        '0mm' --> '011'    (same as Fiscal Period only)
--                        'mm' --> '11'      (numeric Fiscal Period)
--                        'yyyy' --> '2022'  (Fiscal Year)
```

#### Usage.
- The macro is available and can be used in any model as the following examples:
```sql
-- Example with fixed value (double and single quotes needed):
{{ sie_dbt_utils.date_to_fiscal_period("'2022-03-23'") }}
-- converts into: to_char(add_months('2022-03-23',3),'yyyy0mm')

-- Example with function current_date:
{{ sie_dbt_utils.date_to_fiscal_period('current_date()') }}
-- converts into: to_char(add_months(current_date(),3),'yyyy0mm')

-- Example using a column
{{ sie_dbt_utils.date_to_fiscal_period('budat') }}
-- converts into: to_char(add_months(budat,3),'yyyy0mm')

-- Get the current Fiscal Period
{ { sie_dbt_utils.date_to_fiscal_period('current_date()', '0mm') } }
-- converts into: to_char(add_months(current_date(),3),'0mm')

-- Get the current Fiscal Year
{ { sie_dbt_utils.date_to_fiscal_period('current_date()', 'yyyy') } }
-- converts into: to_char(add_months(current_date(),3),'yyyy')

```

### dynamic_limit ([source](macros/utilities/dynamic_limit.sql))
- Macro `dynamic_limit` can be used to limit the models up to a certain number of Records, to make the dbt runs faster, in the cases where the data is not relevant.
- This macro should will be applied when `target.name` is `CI` or `default`(during the development mode)



#### Syntax.
```sql
select 
    *
    from {{ source('some_source','some_table') }} 

{{ sie_dbt_utils.dynamic_limit() }}
/*
-- results in:
select 
    *
    from dev_database.some_source.table_name

LIMIT 100
*/
```

#### Usage.
- The limit could be set by the variable `sdu_data_limit`. And the variable could be defined in differnt places, according to the project's decision:  

1. **Limit the data only in certain `dbt runs`**. Then define it on the command line:
> `dbt run -s trf_fi_doc_header --vars 'sdu_data_limit: 100'`

2. **Limit the data by default for all the `dbt runs` in development mode**. Then define it on the `dbt_project.yml`:
> ```yml
> vars:
>   sdu_data_limit: "100"
> ```
and then to run some models with unlimited data, set the limit to `-1`:  
> `dbt run -s trf_fi_doc_header --vars 'sdu_data_limit: -1'`

3. **Limit the data by default, but according to some other criteria**: Then define it on the `dbt_project.yml`:
> ```yml
> vars:
>   sdu_data_limit: "{%- if target.name == 'default' -%} 500 {%- elif target.name == 'CI' -%} 100 {%- endif -%}"
> ```



### dynamic_tablesample ([source](macros/utilities/dynamic_tablesample.sql))
- Macro `dynamic_tablesample` can be used to sample the source tables up to a certain % of Records, to make the dbt runs faster, in the cases where the data is not relevant.
- This macro should will be applied when `target.name` is `CI` or `default`(during the development mode)



#### Syntax.
```sql
select 
    *
    from {{ source('some_source','some_table') }}  {{ sie_dbt_utils.dynamic_tablesample() }}

/*
-- results in:
select 
    *
    from dev_database.some_source.table_name  tablesample(2) 
*/
```

#### Usage.
- The limit could be set by the variable `sdu_data_sample` (percentage value from 0-100). And the variable could be defined in different places, according to the project's decision:  

1. **Limit the data only in certain `dbt runs`**. Then define it on the command line:
> `dbt run -s trf_fi_doc_header --vars 'sdu_data_sample: 2'`

2. **Limit the data by default for all the `dbt runs` in development mode**. Then define it on the `dbt_project.yml`:
> ```yml
> vars:
>   sdu_data_sample: "2"   #2% sample
> ```
and then to run some models with unlimited data, set the limit to `-1`:  
> `dbt run -s trf_fi_doc_header --vars 'sdu_data_sample: -1'`

3. **Limit the data by default, but according to some other criteria**: Then define it on the `dbt_project.yml`:
> ```yml
> vars:
>   sdu_data_limit: "{%- if target.name == 'default' -%} 500 {%- elif target.name == 'CI' -%} 100 {%- endif -%}"
> ```


### full_refresh_protection ([source](macros/utilities/full_refresh_protection.sql))
- Macro `full_refresh_protection` will prevent a model to be loaded with the `full-refresh` flag.  
Typically this is used with models with `materialized = 'incremental'`, in order to prevent that the data is lost.  
The specific model will fail, and an error message is thrown.


#### Syntax.
```sql
-- call this procedure in the first line of your model.
{{ sie_dbt_utils.full_refresh_protection() }}
```
The expected behaviour is that an error is thrown everytime this model will run with `full-refresh` flag on.

#### Usage.
- The macro should be used in the first line of the incremental models.

```sql
-- call this procedure in the first line of your model.
{{ sie_dbt_utils.full_refresh_protection() }}

-- same code as before for incremental models
{{
    config(
         materialized='incremental',
         unique_key='HK_VBAK'
    )
}}
```

The log will show the error:
```console
20:45:37  Completed with 1 error and 0 warnings:
20:45:37  Compilation Error in model staging_erp_ap0_kna1 (models/staging/erp/ap0/staging_erp_ap0_kna1.sql)
20:45:37    Full refresh is not allowed for this model. Exclude it from the run via the argument "--exclude staging_erp_ap0_kna1".
```


### neat_log ([source](macros/utilities/neat_log.sql))
- Macro `neat_log` logs a message in the same format as the dbt Cloud run messages

#### Parameters.
 * `message` (string): Message to present (up to 80 characters)
 * `result` (string):  status message to show at the end (for example: the run time)
 * `info` (boolean): if True, the message will show on the main log

#### Syntax.
```sql
{{ sie_dbt_utils.neat_log('some message') }}
{{ sie_dbt_utils.neat_log('running some part of the code', 'START') }}
{{ sie_dbt_utils.neat_log('running some part of the code', 'runtime 10s') }}

```

#### Usage.
- The macro will log a message in the same format as the dbt Cloud model run messages.
```sql
-- Example messages
{{neat_log('First Message')}}
{{neat_log('First Message', 'Success!')}}
{{neat_log('First Message with a longer text', 'Success!')}}
..
/*
First Message ..................................................................
First Message .................................................................. [Success!]
First Message with a longer text ............................................... [Success!]
*/

```




### get_fiscal_period ([source](macros/utilities/get_current_fiscal_period.sql))
- Macro `get_fiscal_period` returns the fiscal YearPeriod in the format `'YYYY0MM'`.  
The Fiscal Period is derived on the current calendar month + 3 Months.  
If the previous fiscal period needs to be obtained, the parameter `_offset=-1` can be provided, or any other integer.

#### 
Macro `get_current_fiscal_period()` maintained for retro-compability and it redirects to `get_fiscal_period(0)`.

#### Parameters.
 * `_offset` (integer): This is the offset to the current fiscal period. Default value = 0
 

#### Syntax.
```sql
{{ sie_dbt_utils.get_fiscal_period([offset]) }}
```

#### Usage.
- The macro will derive the Fiscal Period based on the current system date. The offset can be applied to get previous or next fiscals periods:
```sql
-- Example filtering a table
where yearperiod = '{{ sie_dbt_utils.get_fiscal_period() }}'
-- (sql) -> yeaperiod = '2023004'

-- Example showing to filter the values based on the current fiscal period and the 2 previous fiscal periods
    where
        fiscal_period between '{{ sie_dbt_utils.get_fiscal_period(-2) }}' and '{{ sie_dbt_utils.get_fiscal_period() }}'

--    (sql) -> where fiscal_period between '2023002' and '2023004'

```

### get_fiscal_quarter ([source](macros/utilities/get_current_fiscal_quarter.sql))
- Macro `get_fiscal_quarter` returns the fiscal Quarter as an integer value from [1-4].  
The Fiscal Quarter is derived using the `get_fiscal_period` macro logic.  
If the quarter from the previous fiscal period needs to be obtained, the parameter `_offset=-1` can be provided, or any other integer.

#### 
Macro `get_current_fiscal_quarter()` maintained for retro-compability and it redirects to `get_fiscal_quarter(0)`.

#### Parameters.
 * `_offset` (integer): This is the offset in months to the current fiscal quarter. Default value = 0
 

#### Syntax.
```sql
{{ sie_dbt_utils.get_fiscal_quarter([offset]) }}
```

#### Usage.
- The macro will derive the Fiscal Quarter based on the current system date. The period offset can be applied to get previous or next fiscals periods:
```sql
-- Example filtering a table
where quarter = '{{ sie_dbt_utils.get_fiscal_quarter() }}'
-- (sql) -> quarter = '1'

-- Example showing to filter the values based on the current fiscal period and the 2 previous fiscal periods
    where
        quarter between '{{ sie_dbt_utils.get_fiscal_quarter(-2) }}' and '{{ sie_dbt_utils.get_fiscal_quarter() }}'

--    (sql) -> where fiscal_period between '1' and '2' -- assuming this was built on 2023.01.10

```


### sap_to_date ([source](macros/utilities/sap_to_date.sql))
- Macro `sap_to_date` converts the SAP Date values (format `'YYYYMMDD'`) into a correct SQL Date datatype.



#### Syntax.
```sql
{{ sie_dbt_utils.sap_to_date(<sap_date_value>) }}

-- sap_date_value: value in SAP Date format: YYYYMMDD
```

#### Usage.
- The macro is available and can be used in any model as the following examples:
```sql
-- Example with a date columns `budat`:
{{ sie_dbt_utils.sap_to_date('budat') }}
-- converts into: to_date(budat, 'YYYYMMDD')

-- Example with fixed value (double and single quotes needed):
{{ sie_dbt_utils.sap_to_date("'20221231'") }}
-- converts into: to_date('20221231', 'YYYYMMDD')
```

### sap_to_timestamp ([source](macros/utilities/sap_to_timestamp.sql))
- Macro `sap_to_timestamp` converts the SAP Date values (format `'YYYYMMDD'`) into a correct SQL Date datatype.

#### Parameters.
  * `sap_date_value` (string) : column name with SAP Date format `YYYYMMDD`
  * `sap_time_value` (string) : column name with SAP Tme format `HHMMSS`


#### Syntax.
```sql
{{ sie_dbt_utils.sap_to_timestamp(<sap_date_value>, <sap_time_value>) }}

-- sap_date_value: value in SAP Date format: YYYYMMDD
```

#### Usage.
- The macro is available and can be used in any model as the following examples:
```sql
-- Example with a columns `budat` and 'aetim' :
{{ sie_dbt_utils.sap_to_timestamp('budat', 'aetim') }}
-- converts into: try_to_timestamp(budat||aetim,'yyyymmddhh24miss')

-- Example with fixed value (double and single quotes needed):
{{ sie_dbt_utils.sap_to_timestamp('budat') }}
-- converts into: try_to_timestamp('budat','yyyymmdd')

-- Example with fixed value (double and single quotes needed):
{{ sie_dbt_utils.sap_to_timestamp("'20221231'") }}
-- converts into: try_to_timestamp('20221231','yyyymmdd')
```


### simple_cte ([source](macros/utilities/simple_cte.sql))
- Macro `simple_cte` will generate a sequence of CTEs based on a list of model names and it's expected CTE alias.

#### Parameters.
  * `tuple_list` (list of pairs): list of pairs consisting of `cte_alias` and `model_reference`

#### Syntax.
```sql
{{ sie_dbt_utils.simple_cte( 
        [
            ("<cte_alias_1>", "<model_reference_1>"),
            ("<cte_alias_2>", "<model_reference_2>"),
            ...
            ("<cte_alias_n>", "<model_reference_n>"),
        ])
}}
```

#### Usage.
- The macro is available and can be used in any model as the following examples:
```sql
{{ sie_dbt_utils.simple_cte(
        [
            ("ekko", "stg_ekko"),
            ("ekpo", "stg_ekpo"),
            ("bseg", "stg_bseg")
        ])
}}

-- generated the followin SQL code:
WITH ekko AS (

    SELECT * 
    FROM DEV_DCC_P.dbt_Z003HMBT_STAGING.stg_ekko

), ekpo AS (

    SELECT * 
    FROM DEV_DCC_P.dbt_Z003HMBT_STAGING.stg_ekpo

), bseg AS (

    SELECT * 
    FROM DEV_DCC_P.dbt_Z003HMBT_STAGING.stg_bseg

)```



## ERP Domain Functions

### build_key_columns ([source](macros/utilities/erp_domain/build_key_columns.sql))
 - Macro `build_key_columns` will generate the PK and HK columns for the required ERP Table. This information will be read from the *_DISTRIBUTE.DOM_ERP.CUST_ALL_DOM_TABLE_KEYS table.
 - The main purpose is to have the same definition of Hash Keys between all the projects

#### Parameters.
  * `in_table_name` (String): Name of the source table to be used. Ex: KNA1
  * `key_columns` (array[String]): list of columns to be retrieved. [] to retrieve all the columns
  * `column_type` (String): type of column to take from the seed table. typically 'PK' or 'HK' or '%' for both
  * `available_columns` (array[String]): in case your model only has certain columns lists. include here to filter the HK/PK that match


#### Syntax.
```sql
{{ sie_dbt_utils.build_key_columns( <in_table_name> ,
                                    [key_columns=[]],
                                    [column_type='%'],
                                    [available_columns=none]) }}

```

#### Usage.
- The macro will return the Hash Key definition for all the columns that are requested.

```sql
Examples:
-- all PK and HK
{{ sie_dbt_utils.build_key_columns( 'vbak') }}

-- PK only:
{{ sie_dbt_utils.build_key_columns( 'vbak', column_type = 'PK') }}

-- specific HK only:
{{ sie_dbt_utils.build_key_columns( 'vbak', key_columns=['hk_aufnr','hk_kokrs'], column_type='HK') }}

-- All the HKs that can be created using the statement available columns: mandt and vbeln
{{ sie_dbt_utils.build_key_columns( 'vbak', column_type='HK', available_columns=['MANDT','VBELN']) }}

```


### stg_erpall ([source](macros/utilities/erp_domain/stg_erpall.sql))
You can find more documentation for this macro on the dedicated [README.md](macros/utilities/erp_domain/README.md)

- Macro `stg_erpall` will generate a select Statement that unions the table <table_name> from all the ERP Systems to which the project has access to.
- Similar functionallity as the one found on the `DOM_ERP.STG_ERPALL_*` views, but this version will have less view dependencies and using only the required ERP Systems
  - The compilation time should have a major improvement
  - The execution time should also have a good improvement, and this version will not require any RLS joins to restrict the data.
- The Statement will generate the `hash_keys` and `primary_keys` as defined in `DOM_ERP`, but only if it's composing columns are available in the query.

#### Parameters.
* `table_name` (String): Name of the ERP table to generate the statement
* `erp_systems` (array[String]) - optional: list of System names to include, if empty, then all the ERP systems will be used
* `include_columns` (String) - optional: List of columns to include in your model. If empty then all the columns will be included
* `column_override` (dict) - optional: A dictionary of explicit column type overrides, e.g. {"some_field": "varchar(100)"}.``
* `where` (String) - optional: where clause to be included in each SELECT statement
* `create_keys` (Boolean) - optional: if set to `False` then the Primary Keys and Hash Keys are not generated
* `column_prefix` (String) - optional: if set, adds a prefix to the column name (separated by "_")
* `column_suffix` (String) - optional: if set, adds a suffix to the column name (separated by "_")

#### Syntax.
```sql
{{ sie_dbt_utils.stg_erpall(<table_name>, 
                           [erp_systems=[]],
                           [include_columns=[]],
                           [column_override=[]], 
                           [where=''],
                           [create_keys=True],
                           [column_prefix=''],
                           [column_suffix=''] )
}}

```

#### Usage.
- The macro will generate a SELECT statement with a union between all the ERP systems to which the project has access to. The columns can also be restricted
- Typically this will be used within a CTE, to
```sql
-- selecting some columns of bseg table from all the ERP systems.
with erpall as (
    {{ sie_dbt_utils.stg_erpall('ekkn',
                  erp_systems=[],
                  include_columns=['AUFNR', 'ebeln', 'ebelp', 'kostl', 'loekz', 'mandt', 'menge', 'netwr', 'nplnr', 'prctr', 'ps_psp_pnr', 'sakto', 'vbeln', 'vproz', 'ZEKKN'],
                  column_override={'MANDT': 'varchar(10)'},
                  where="mandt='100'") }}
)
select *
    from erpall

/*
 Will generate a select statement with the following columns:
PK_BSEG | HK_BELNR | HK_BUKRS | HK_BUZEI | SYSTEM | MANDT | BUKRS | BELNR | GJAHR | BUZEI | BUZID | AUGDT | AUGCP | AUGBL | BSCHL | KOART | LAST_UPDATED | AUDGT_DATE
Where the columns PK_BSEG, HK_BELNR, HK_BUKRS, HK_BUZEI  are the hash keys defined in DOM_ERP
SYSTEM is the ERP system for the corresponding record
*/

```



## SAP HANA Functions
### add_workdays ([source](macros/utilities/add_workdays.sql))
- Macro `add_workdays` should calculate the resulting working day when adding a number of working days to an initial date.  

In order to use this macro, you need to consume the table `trf_utils_tfacs_unique` from the DOM_COMMON schema, via the `*_DISTRIBUTE` databases.   
**note:** it is recommended that you create a staging for `trf_utils_tfacs_unique` and materialize it as a table. See the Example: [workdays_between Requirements](#workdays_between-requirements)

#### Parameters.
 * `alias`(string) - this refers to the alias of the tfacs table that is joined in the query
 * `first_date` (date) - initial date
 * `number_workdays`(integer) - number of working days to add

#### Syntax.
```sql
{{ sie_dbt_utils.add_workdays('wkd', "to_date(adrc.ZZDADATE, 'YYYYMMDD')", 10) }} as result_working_day
        -- 'wkd' refers to the alias of the `trf_utils_tfacs_unique`
        -- dates should be in the SQL date format, in this case we are casting the SAP dates.
``` 

#### Usage.
- The macro can be used in any model, and requires a inner/left join with the `common_tfacs` table from DOM_COMMON (see the [Requirements](#workdays_between-requirements)):
```sql
with my_table as (
  select budat as date_initial,
         aedat as date_final
    from    {{ ref('<some_model>') }} t
)
select
        date_initial,
        10 as number_of_days_to_add,
        {{ sie_dbt_utils.add_workdays('wkd', "to_date(date_initial, 'YYYYMMDD')", 10) }} as result_working_day
        -- 'wkd' refers to the alias of the `trf_utils_tfacs_unique`
        -- dates should be in the SQL date format, in this case we are casting the SAP dates.

from    my_table
        left outer join {{ ref('common_tfacs') }} wkd
          on wkd.system = t.system and wkd.ident = '01_AP001' -- '01_AP001' is the Calendar ID used
        -- the Calendar ID can also exist as a column on the `t` table
limit 10;
```

### workdays_between ([source](macros/utilities/sap_hana_functions/workdays_between.sql))
- Macro `workdays_between` should calculate the working days between two dates considering a SAP Factory calendar from a specific ERP System and Calendar ID.  
In order to use this macro, you need to consume the table `trf_utils_tfacs_unique` from the DOM_COMMON schema, via the `*_DISTRIBUTE` databases.  
 
**note:** it is recommended that you create a staging for `trf_utils_tfacs_unique` and materialize it as a table. See the Example: [workdays_between Requirements](#workdays_between-requirements)

#### Parameters.
 * `alias`(string) - this refers to the alias of the tfacs table that is joined in the query
 * `first_date`(date) - initial date
 * `second_date`(date) - final date

#### Syntax.
```sql
{{ sie_dbt_utils.workdays_between('wkd', "to_date(t.date_initial, 'yyyymmdd')", "to_date(t.date_final, 'yyyymmdd')") }} as wkdays_result,
        -- 'wkd' refers to the alias of the `trf_utils_tfacs_unique`
        -- both dates should be in the date format, in this case we are casting the SAP dates.
;
```

#### Usage.
- The macro can be used in any model, and requires a inner/left join with the `common_tfacs` table from DOM_COMMON (see the [Requirements](#workdays_between-requirements)):
```sql
with my_table as (
  select 'AP001' as system,
         t.budat as date_initial,
         t.aedat as date_final
    from    {{ ref('<some_model>') }} t
)
select
        date_initial,
        date_final,
      {{ sie_dbt_utils.workdays_between('wkd', "to_date(t.date_initial, 'yyyymmdd')", "to_date(t.date_final, 'yyyymmdd')") }} as wkdays_result
        -- 'wkd' refers to the alias of the `trf_utils_tfacs_unique`
        -- both dates should be in the date format, in this case we are casting the SAP dates.

from    my_table t
        left outer join {{ ref('common_tfacs') }} wkd
          on wkd.system = t.system and wkd.ident = '01_AP001' -- '01_AP001' is the Calendar ID used
        -- the Calendar ID can also exist as a column on the `t` table
limit 10;
```

#### workdays_between requirements
Create a staging model for the unique_TFACS table from DOM_COMMON, and materialize it as a table:  
`models/staging/dom_common/common_tfacs.sql`
```sql
{{
    config( materialized='table', )
}}
with tfacs as (
        select * from {{ source('dom_common', 'dist_common_tfacs') }} 
        ) 

, transform as (
    select
        system, 
        ident,
        min_date,
        workday_flags
        from
            tfacs
)

select
    *
    from transform

```  

Create the Source File:  
`models/staging/dom_common/_sources.yml`
```yml
version: 2

sources:
  - name: dom_common
    database: "{{ env_var('DBT_CURRENT_ENVIRONMENT') }}_DISTRIBUTE"
    schema: dom_common
    description: Sources from the dom_common 
    tables:
      - name: 'dist_common_tfacs'

```



<!---
#### create_model_HK ([source](macros/utilities/)])
'<to be created>'
#### Usage.
#### Features

### rename_column_dictionary ([source](macros/utilities/)])
'<to be created>'
##### Usage.
##### Features
--->

## Macro overriding
These macros override the default dbt macros, in order to provide aditional functions, check each one to see how to activate or configure.


### generate_alias_name ([source](macros/overrides/generate_alias_name.sql))
- Macro `generate_alias_name` overrided to allow the usage of Fully Qualified Names (Like in SAP HANA repository objects).  
Example: `marts/facts/m_f_my_final_model.sql`  is created as `marts_facts$m_f_my_final_model`
- The Fully Qualified Names' separators ('_' and '$' ) are customizable.

#### Usage.
- The macro is deactivated by default. In order to activate it for your entire project, you need to set the Variable 'siemens_long_names_in_models'in the `dbt_project.yml` file:
```yaml
vars:
  siemens_long_names_in_models: true
```

#### Features

* The Fully Qualified Names separators ('_' and '$') are customizable. These can be defined using the two variables:
```yaml
vars:
  siemens_long_names_in_models: true 
  siemens_long_names_in_models_object_delimiter: '/'  # delimiter for the model name (default="$")
  siemens_long_names_in_models_folder_delimiter: '.' # delimiter for the Folders (Default="_")
```
* The macro can be deactivated in certain models, using the config below:
```sql
{{
    config(
        siemens_use_long_name=false
    )
}}
```
* Custom_alias_name can still be used and will be used instead of the Fully Qualified Name.
```sql
{{
    config(
        alias='my_custom_model_name'
    )
}}
```

### generate_schema_name ([source](macros/overrides/generate_schema_name.sql))
- Macro `generate_schema_name` overrided to provide the schemas only with the `Custom Schema Name` (when it is defined), rather than then concatenation between the `<target_schema> + '_' + <custom_schema_name>`. This will happen only for the Technical Users that run in the DEV, QUA and PRD Environments  
Example: schema `STAGING`  is created instead of `dbt_STAGING`


#### Usage.
- The macro is activated by default. No further changes are needed. In case you prefer to keep the default behaviour, you have to override this macro in your own project.

#### Features.
The standard generation of dbt's Schemas consists of two parts: `<target_schema> [+ '_' + <custom_schema_name>]`  
Where:
* `<target_schema>`: refers to the schema defined on the User Profile ("dbt_<GID>") / Environment ("dbt")
* `<custom_schema_name>`: (Optional if defined): the schema that is defined in the `dbt_project.yml` or in the models directly. Example: "STAGING"

This macro implementation will generate a different name when the technical user `*_TU_ETL_DBT` is running the jobs. Here is the behaviour:  
| who runs? | username | target_schema | custom_schema | Result |
| ------ | ------ | ------ | ------ | ------ |
| developer | Z003HMBT | dbt_Z003HMBT | | dbt_Z003HMBT |
| developer | Z003HMBT | dbt_Z003HMBT | STAGING |  dbt_Z003HMBT_STAGING |
| Technical User| DEV_SAMPLE_PROJECT_TU_ETL_DBT| dbt |  |  dbt |
| Technical User| DEV_SAMPLE_PROJECT_TU_ETL_DBT| dbt | STAGING |  STAGING |

#### ChangeLog
 - 2022.06.03: This macro was updated to consider the CI pipelines for the CI automation

### create_schema ([source](macros/utilities/create_schema.sql))
- Macro `create_schema` overrides to call the required procedure in Snowflake, in order to Create a new Schema

#### Usage.
No changes needed. This macros is activated by default and will run automatically.

#### Features.
* Macro `create_schema` overrides to call the required procedure in Snowflake, in order to Create a new Schema
```sql
call common.rbac.prc_schema_in_<DEV|QUA|PRD>('create schema if not exists <SCHEMA_NAME> with managed access')
```


### drop_schema ([source](macros/utilities/drop_schema.sql))
- Macro `drop_schema` overrides to call the required procedure in Snowflake, in order to Drop an existent Schema

#### Usage.
No changes needed. This macros is activated by default and will run automatically.

#### Features.
* Macro `drop_schema` overrides to call the required procedure in Snowflake, in order to Drop an existent Schema
```
call common.rbac.prc_schema_in_<DEV|QUA|PRD>('drop schema if exists <SCHEMA_NAME> cascade')
```


### dbt_utils.hash ([source](macros/overrides/dbt_utils/hash.sql))
- Macro `dbt_utils.hash` overrides the `dbt_utils` macro to use the `md5_binary` function instead of the default `md5`.

#### Usage.
- The macro is used internally on the `dbt_utils.surrogate_key`.
- In order to use this version, you need to add the following dispatch sequence on the `dbt_project.yml`, right after the current dispatch for `dbt`.
replace `<DBT_PROJECT_NAME>` by the name of your project as seen on line 5 of the same file.
`dbt_project.yml`
```yaml
dispatch:
  - macro_namespace: dbt
    search_order: ['<DBT_PROJECT_NAME>', 'sie_dbt_utils', 'dbt']
#>>>>>>> add the following lines in the dispatch definition
  - macro_namespace: dbt_utils
    search_order: ['<DBT_PROJECT_NAME>', 'sie_dbt_utils', 'dbt_utils']
```



## macros for Operations
### drop_old_relations ([source](macros/utilities/drop_old_relations.sql))
- Macro `drop_old_relations` will identify the objects in the database that are not related to the dbt Project anymore.  
- It can be executed in dry_run mode, just to list the drop statements, for validation. Or executed in real mode, and the database objects will be dropped.
- **Pay extra attention if your database contains objects that are not maitained by dbt Cloud**  
- **it is recommended that the macro runs for one schema at a time.**  
- This macro should be executed in the command line or as a dbt Cloud job itself.

- pay atention to the Snowflake Roles and the object ownership.
    - objects created by the dbt Cloud Jobs are using the `*_ETL` role, and can only be deleted using this role. Either as a dbt Cloud job or copying and pasting the statements into a Snowflake worksheet.
    - objects created by the user while in development mode (using the command line), are created by the `*_DEVELOPER_RESTRICTED` role, and can only be dropped in a Snowflake Worksheet with the same role. Copy the statements and run in Snowflake directly.


#### Parameters.
* `schema`(string OR array) - Optional parameter to define a list of schemas in uppercase. If parameter is not provided, then the personal schema will be used (example: `dbt_<GID>`)
    * Examples:
        * as a string: `'STAGING'`
        * as an array: `['STAGING','TRANSFORM']`
* `dry_run` (string default=`'true'`) `['true','false']` -
    * if set to `'true'`, then the drop statements are listed
    * if set to `'false'`, then macro runs in real mode and the drop statements are executed. **note** this mode cannot be activated while using the command line in development mode.


#### Syntax.
in the command line or the job definition:
```bash
# provide the parameters using one of the options below
dbt run-operation sie_dbt_utils.drop_old_relations 
dbt run-operation sie_dbt_utils.drop_old_relations --args "{dry_run: 'true'}"
dbt run-operation sie_dbt_utils.drop_old_relations --args "{schema: ['STAGING','TRANSFORM']}"
dbt run-operation sie_dbt_utils.drop_old_relations --args "{dry_run: 'true', schema: ['STAGING','TRANSFORM']}"
```

#### Usage.
- The macro can be executed in development mode or as a job
```bash
# running macro in dry_run mode for the personal schemas dbt_<GID>_*
dbt run-operation sie_dbt_utils.drop_old_relations

# running macro in dry_run mode for a single schema
dbt run-operation sie_dbt_utils.drop_old_relations --args "{dry_run: 'true', schema: 'STAGING'}"

# running macro in dry_run mode  for a single schema as an Array
dbt run-operation sie_dbt_utils.drop_old_relations --args "{dry_run: 'true', schema: ['STAGING']}"

# running macro in dry_run mode  for two schemas
dbt run-operation sie_dbt_utils.drop_old_relations --args "{dry_run: 'true', schema: ['STAGING','TRANSFORM']}"

# running macro in real mode  for two schemas
dbt run-operation sie_dbt_utils.drop_old_relations --args "{dry_run: 'false', schema: ['STAGING','TRANSFORM']}"
```


## Internal Macros

### check_db_connection ([source](macros/utilities/check_db_connection.sql))
- Macro `check_db_connection` will simply run a select statment on the Database and either fails or shows a message  this:  
`:: check_db_connection: USERNAME(34.xxx.xxxx.108): Query reached db successfully [2022-03-31 10:10:00.688000+02:00] `
- One of the use cases is to have a dedicated job with it, and check if the Credentials are correctly setup, or there is something wrong with it.

#### Usage.
- The macro should be used by the `dbt run-operation check_db_connection` command, either in the console or as a dedicated job




<!-- TEMPLATE!

### NAME ([source](macros/utilities/))
- Macro `NAME` ...
- ...  

#### Arguments
- `arg1` (required/optional) : 
- `arg2` (required/optional) : 

#### Usage
```sql
  -- Example
```

--->

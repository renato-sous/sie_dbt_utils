# v0.2.4

## Corrections
- :thumbsup: macro `stg_erpall` identifies the ERP systems in a better way ( #33 )
- :thumbsup: macro `add_workdays` fixed to accept days between 0 and -0.49 without error  ( #34 )
- :thumbsup: macro `build_key_columns` reads the Key definitions from PRD_DISTRIBUTE.DOM_ERP ( #39 )
- :thumbsup: macro `cast_masked_columns` fixed to allow columns with table alias  ( #40 )
- :thumbsup: macro `add_workdays` fixed for edge cases (below minimum date and adding/subtracting 0 days)  ( #42 )
- :thumbsup: macro `sap_to_timestamp` fixed issue with SAP empty values ('0000000'), now returns null  ( #49 )


## Breaking changes
- :rotating_light: 

## Improvements
 - :new: `plain` materialization included ( #29 )
 - :new: macro `get_fiscal_quarter` created ( #35 )
 - :new: macro `stg_erpall` has two new parameters `column_prefix` and `column_prefix` ( #36 )
 - :new: macro `simple_cte` was created ( #44 )
 - :new: This is now the first oficial release using the Semantic Versioning

## Migration instructions
- :rotating_light: **Always test the entire project in a separate branch before merging into dev!**
- To use this version, include the package with revision `v0.2.4` in the `packages.yml` file:
```yaml
packages:
  - git: "git@code.siemens.com:dbt-cloud-at-siemens/sie_dbt_utils.git" # git URL
    revision: "v0.2.4"
```


# sie-dbt-utils 230301 (1st March 2023) - v0.2.3

## Corrections
- :thumbsup: macro `add_workdays` fixed to allow subtraction of working days ( #28 )
- :thumbsup: macro `stg_erpall` fixed issues with the `/SIE/*` tables ( #30 )
- :thumbsup: macro `stg_erpall` parameters `include_columns` and `erp_systems` accepts lowercase ( #32 )


## Breaking changes
- :rotating_light: 

## Improvements
 - :new: macro `stg_erpall` has dispatch ( #32 )
 - :new: macro `stg_erpall` has new parameters: `column_override`, `where`, `create_keys` ( #32 )

## Migration instructions
- :rotating_light: **Always test the entire project in a separate branch before merging into dev!**
- To use this version, include the package with revision `sie_dbt_utils_230301` in the `packages.yml` file:
```yaml
packages:
  - git: "git@code.siemens.com:dbt-cloud-at-siemens/sie_dbt_utils.git" # git URL
    revision: "sie_dbt_utils_230301"
```


# sie-dbt-utils 230210 (10th February 2023) v0.2.2

## Corrections
- :thumbsup: macro `workdays_between` fixed the alias used, to allow multiple joins in same query ( #19 )
- :thumbsup: macro `workdays_between` had a deviation of +1 days. It has been fixed ( #21 )
- :thumbsup: macro `workdays_between` returns NULL in case of the largest dates from SAP (9999.12.31) ( #21 )
- :thumbsup: macro `sap_to_timestamp` had a wrong dispatch namespace. (#24)

## Breaking changes
- :rotating_light: No breaking changes, but it is recommended that your project starts using at least `dbt Core 1.3`

## Improvements
 - :new: `array_to_in` macro created (#22)
 - :new: `get_fiscal_period` macro created (#18)
 - :new: `get_current_fiscal_period` macro created (alias for `get_fiscal_period`) (#18)
 - :new: `neat_log` macro created (#20)
 - :new: `cast_masked_columns` macro created (#25)
 - :new: `stg_erpall` macro created (#27)
 - :new: `build_key_columns` macro created (#27)

## Migration instructions
- :rotating_light: **Always test the entire project in a separate branch before merging into dev!**
- To use this version, include the package with revision `sie_dbt_utils_230210` in the `packages.yml` file:
```yaml
packages:
  - git: "git@code.siemens.com:dbt-cloud-at-siemens/sie_dbt_utils.git" # git URL
    revision: "sie_dbt_utils_230210"
```

# sie-dbt-utils 220812 (12th August 2022)

## Corrections
- no corrections from previous releases have been made

## Breaking changes
- :rotating_light: macro `dbt_utils.hash` overriden. The macro is now using `md5_binary` instead of `md5` function. **See the Migration Instructions below**
- :rotating_light: macro `generate_schema_name` overriden. To have special logic for the CI jobs.

## Improvements
 - :new: `alphanum` macro created
 - :new: `dynamic_tablesample`  macro created. To be used in development and CI Jobs
 - :new: `dynamic_limit` macro created. To be used in development and CI Jobs
 - :new: `drop_old_relations` macro created. To be used as a run-operation
 - :new: `sap_to_timestamp` macro created.
 - :new: `add_workdays` macro created. equivalent to SAP HANA's function
 - :new: `workdays_between` macro created. equivalent to SAP HANA's function

## Migration instructions
- :rotating_light: **Always test the entire project in a separate branch before merging into dev!**
- To use this version, include the package with revision `sie_dbt_utils_220812` in the `packages.yml` file:
```yaml
packages:
  - git: "git@code.siemens.com:dbt-cloud-at-siemens/sie_dbt_utils.git" # git URL
    revision: "sie_dbt_utils_220812"
```
### :raised_back_of_hand: Manual Step: `dbt_utils.hash` overriding
- the macro `dbt_utils.hash` has been overriden to use the `md5_binary` function instead of `md5`.
- If you are using the `dbt_utils.hash` or (`dbt_utils.surrogate_key`) in your project, and wish to use this new version, then please update the dispatch definition in the `dbt_project.yml` as seen in the [README](https://code.siemens.com/dbt-cloud-at-siemens/sie_dbt_utils/-/blob/main/README.md#dbt_utilshash-source).
- **Attention**: the tables/views will now have a BINARY data type, instead of the VARCHAR, this might break your models and joins. please it throughly. Specially if you are using incremental models, as a full refresh might be required.



## Features

The new macros can be used in any model. To enhance the functionalities of dbt Cloud.  
Please refer to the [README.MD](https://code.siemens.com/dbt-cloud-at-siemens/sie_dbt_utils/-/blob/main/README.md), in order to see their usage and examples.



# sie-dbt-utils 220405 (5th April 2022)

## Correction
- :warning:  there was an error on revision `sie_dbt_utils_220404`, which was deleted and you can use this one instead.

## Breaking changes
- :new: macro `current_environment` created. It will return the Environment Name as one of DEV, QUA or PR.
- :new: macr `date_to_fiscal_period` created. To convert date fields into Fiscal Period in the desired format.
- :new: macro `full_refresh_protection` created. To prevent some incremental models to be dropped using the `--full-refresh` flag.
- :new: macro `sap_to_date` created. To convert a sap date field `('YYYYMMDD' as VARCHAR(8))` into a SQL Date format.
- :new: internal macro `check_db_connection` created. To be used mostly in a dedicated job, to ensure the connection between dbt Cloud and the Snowflake is working properly.
- :white_check_mark: log messages from macro `generate_schema_name` have been cleared

## Migration instructions
- To use this version, include the package with revision `sie_dbt_utils_220405` in the `packages.yml` file:
```yaml
packages:
  - git: "git@code.siemens.com:dbt-cloud-at-siemens/sie_dbt_utils.git" # git URL
    revision: "sie_dbt_utils_220405"
```

## Features

The new macros can be used in any model. To enhance the functionalities of dbt Cloud.  
Please refer to the [README.MD](https://code.siemens.com/dbt-cloud-at-siemens/sie_dbt_utils/-/blob/main/README.md), in order to see their usage and examples.



# sie-dbt-utils 220308 (8th March 2022)

## Breaking changes
- :rotating_light: default `generate_schema_name` macro overrided. To use the `custom schema name` in the DEV, QUA and PRD Environments.

## Migration instructions
- To use this version, include the package with revision `sie_dbt_utils_220308` in the `packages.yml` file:
```yaml
packages:
  - git: "git@code.siemens.com:dbt-cloud-at-siemens/sie_dbt_utils.git" # git URL
    revision: "sie_dbt_utils_220308"
```
- The **macro is activated by default**.
<details><summary>Click here to learn how to deactivate it.</summary>
Override the macro `default__generate_schema_name` in your own project. and use the [original source code](https://github.com/dbt-labs/dbt-core/blob/main/core/dbt/include/global_project/macros/get_custom_name/get_custom_schema.sql).  

Copy the code and paste in your new macro `generate_schema_name.sql`:  

```sql
{% macro default__generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
```
</details>

## Features

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


# sie-dbt-utils v0.0.3

## Breaking changes
- :rotating_light: default `generate_alias_name` macro overrided. To allow full path names to be created.

## Migration instructions
- To use this version, include the package with revision `sie_dbt_utils_v0.0.3` in the `packages.yml` file:
```yaml
packages:
  - git: "git@code.siemens.com:dbt-cloud-at-siemens/sie_dbt_utils.git" # git URL
    revision: "sie_dbt_utils_v0.0.3"
```
- The **macro is deactivated by default**, in order to activate it: add the following Variable needs to be set on the `dbt_project.yml` file:
```yaml
vars:
  siemens_long_names_in_models: true
```

## Features

* Macro `generate_alias_name` was overrided to allow the usage of full path names (Like in SAP HANA repository objects).
Example: `marts/facts/m_f_my_final_model.sql`  is created as `marts_facts$m_f_my_final_model`
* The full path names' separators are customizable: '_' and '$' can be replaced using the two variables:
```yaml
vars:
  siemens_long_names_in_models: true 
  siemens_long_names_in_models_object_delimiter: '/'  # delimiter for the model name (default="$")
  siemens_long_names_in_models_folder_delimiter: '.' # delimiter for the Folders (Default="_")
```
* The macro can be deactivated in certain models, using the config below:
```jinja
  {{
    config(
        siemens_use_long_name=false
    )
}}
```
* Custom_alias_name can still be used
```jinja
{{
    config(
        alias='my_custom_model_name'
    )
}}
```

# sie-dbt-utils v0.0.2

## Breaking changes
- :rotating_light: `create_schema` and `drop_schema` macros created. To adopt the measures from our Snowflake account

## Migration instructions
- No changes needed. These macros are activated by default.

## Features

* Macro `create_schema` was overrided to call the required procedure in Snowflake, in order to Create a new Schema
```
call common.rbac.prc_schema_in_<DEV|QUA|PRD>('create schema if not exists <SCHEMA_NAME> with managed access')
```
* Macro `drop_schema` was overrided to call the required procedure in Snowflake, in order to Drop an existent Schema
```
call common.rbac.prc_schema_in_<DEV|QUA|PRD>('drop schema if exists <SCHEMA_NAME> cascade')
```

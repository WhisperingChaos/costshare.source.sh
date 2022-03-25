# [costshare](./component/costshare.source.sh)
A [component](https://github.com/WhisperingChaos/SOLID_Bash#component-composition) that consumes: 
- a required CSV formated stream of purchases/refunds and
- a required vendor table in CSV format which defines one or more rows defining a vendor name and the percentage to be paid by one of the parties and
- an optional purchase exclusionary table which discards one or more specific pruchase that would otherwize be included by the vendor table.

Given these inputs, the component will apportion the cost/reimbursement between two parties.
## ToC
[API Index](#api-index)  
[API](#api)  
[Install](#install)  
[Test](#test)  
[License MIT](LICENSE)  


### API Index

[costshare_charge_share_run](#costshare_charge_share_run)

[costshare_purchase_exclude_filter_tbl](#costshare_purchase_exclude_filter_tbl)

[costshare_vendor_pct_tbl](#costshare_vendor_pct_tbl)

### API
#### costshare_charge_share_run
https://github.com/WhisperingChaos/costshare.source.sh/blob/a50c24a0f5171d2cae5c8c78deb2b5482573e9f8/component/costshare.source.sh#L135-L185

Before calling this function to calculate the shared charge amounts 

#### costshare_purchase_exclude_filter_tbl
https://github.com/WhisperingChaos/costshare.source.sh/blob/a50c24a0f5171d2cae5c8c78deb2b5482573e9f8/component/costshare.source.sh#L83-L109

[How to override a callback function](https://github.com/WhisperingChaos/SOLID_Bash#function-overriding)

##### Example
https://github.com/WhisperingChaos/costshare.source.sh/blob/a50c24a0f5171d2cae5c8c78deb2b5482573e9f8/component/costshare.source.sh#L110-L126

#### costshare_vendor_pct_tbl
https://github.com/WhisperingChaos/costshare.source.sh/blob/a50c24a0f5171d2cae5c8c78deb2b5482573e9f8/component/costshare.source.sh#L28-L72

[How to override a callback function](https://github.com/WhisperingChaos/SOLID_Bash#function-overriding)

##### Example
https://github.com/WhisperingChaos/costshare.source.sh/blob/a50c24a0f5171d2cae5c8c78deb2b5482573e9f8/component/costshare.source.sh#L73-L82

### Install
#### Simple
Copy **costshare.source.sh** into a directory then use the Bash [source](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#Bash-Builtins) command to include this package in a Bash testing script before executing fuctions which rely on its [API](#api-index).  Copying using:

  * [```git clone```](https://help.github.com/articles/cloning-a-repository/) to copy entire project contents including its git repository.  Obtains current master which may include untested features.  To synchronize the working directory to reflect the desired release, use ```git checkout tags/<tag_name>```.
  *  [```wget https://github.com/whisperingchaos/costshare.source.sh/tarball/master```](https://github.com/whisperingchaos/costshare.source.sh/tarball/master) creates a tarball that includes only the project files without the git repository.  Obtains current master branch which may include untested features.
#### SOLID Composition
TODO
#### Developed Using 
GNU bash, version 4.3.48(1)-release

This component relies on [nameref/name reference feature](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameters.html) introduced in version 4.3.
### Test
After [installing](#install), change directory to **costshare.source.sh**'s ```test```. Then run:
  * ```./config.sh``` followed by
  * [**./csv_source_test.sh**](test/csv_source_test.sh).  It should complete successfully and not produce any messages.
```
host:~/Desktop/projects/costshare.source.sh/test$ ./costshare.source_test.sh
host:~/Desktop/projects/costshare.source.sh/test$ 
```

# [costshare](./component/costshare.source.sh)
A [component](https://github.com/WhisperingChaos/SOLID_Bash#component-composition) that consumes: 
- a required CSV formated stream of purchases/refunds and
- a required vendor table in CSV format which defines one or more rows defining a vendor name and the percentage to be paid by one of the parties and
- an optional purchase exclusionary table which discards one or more specific pruchase that would otherwize be included by the vendor table.

Given these inputs, the component will apportion the cost/reimbursement between two parties.

### How to Install
#### Source Statement
Simply copy the [raw version](./component/costshare.source.sh?raw=1) of ```costshare``` or extract it from a [zip](https://github.com/whisperingchaos/costshare/zipball/master) of this repository.  
component/costshare.source.sh

Use the bash [```'.' (AKA source)```](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html) statement to include component into your own source module.
### SOLID
Another method exists that implements a [SOLID](https://github.com/WhisperingChaos/SOLID_Bash) approach to managing bash source.  This approach is demonstrated by the ```test``` component, that configures (constructs) an executable from a set components to test this one.


### Dependencies
#### bash version ```GNU bash, version 4.3.48(1)-release```
This component uses bash [nameref/name reference](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameters.html) feature introduced in version 4.3.

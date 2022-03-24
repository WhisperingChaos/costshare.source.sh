#!/bin/bash
###############################################################################
##
##  costshare
##
##  Purpose
##    Divide the purchase cost of an item/service between two parties: Party 'X'
##    and Party 'Y'.  Requires a table whose rows relate a vendor to the 
##    precentage charged to Party 'X' and a stream of purchase transactions
##    whose data includes a vendor name.  The vendor name in the purchase
##    stream is correlated with the ones found in the vendor table in order
##    determine the percentage of the purchase cost to apportioned to Party 'X'.
##  Note
##    Adheres to "SOLID bash" principles:
##    https://github.com/WhisperingChaos/SOLID_Bash#solid_bash
##
###############################################################################

############################## Hook/Callback Functions ########################
##
##  The function(s)s below define the callback "interface" for this component.
##  Override them to provide the input needed to drive this component's output.
##  If unfamiliar with bash function override mechanism see:
##  https://github.com/WhisperingChaos/SOLID_Bash#function-overriding
##
###############################################################################

###############################################################################
##
##  Purpose
##    Defines the vendor percentage table used to filter and calculate the
##    share of a charge owed between two parties.  Only purchases with these
##    vendors are considered.  Vendors that aren't defined in this table
##    are excluded/ignored.
##  Why
##    Automates the process of filtering the purchases that two parties agree
##    on paying and associating the percentage to be paid by Party 'X' to
##    the selected ones.
##  Format
##    The first field in the table is a vendor's name or a regex of it.  
##    This field is delimited by the second one using a comma(,)
##    The second filed is the percentage paid by Party 'X'
##  Constraints
##    Vendor Name
##    - Must be capitalized in the same manner as specified on the statement.
##    - It can contain a whitespace between words.
##    - A vendor name can be truncated to the first whole word (root word)
##      as long as the same percentage is applied to all purchases common
##      to the root.
##    - A root must be at least 3 characters long.
##    - A vendor name must be long enough to uniquely associate the proper
##      percentage that should be paid by Party 'X'.
##    - A vendor name must not contain double, single, or backtick quotes, nor
##      commas. Limiting a vendor name's characters to alphabetic and numeric
##      characters should work.  Also, the process should accomidate characters
##      like #$@.
##    - Its length will be truncated to 'costshare_VENDOR_NAME_LENGTH_MAX' to
##      prevent exploitation/bugs.
##    Party 'X' Percentage
##    - The percentage of the total charge to be paid by Party 'X'.
##    - The share paid by Party 'Y' is the amount that remains after deducting
##      the amount owed by Party 'X'.
##    - Must be a whole number between 0-100.
##
###############################################################################
costshare_vendor_pct_tbl(){
  abort "Override the costshare_vendor_pct_tbl to provide the table of vendors and Party 'X' percentage."
# Vendor Name, Party 'X' Percentage
# Heredoc example:
cat <<costshare_vendor_pct_tbl
WHOLE Foods,50 
costshare_vendor_pct_tbl
}
###############################################################################
##
##  Purpose
##    Excludes purchases normally included by "costshare_vendor_pct_tbl".
##    Each CSV formatted row can define a regex pattern for each input field.
##    Each 
##  Why
##    There may be purchases involving a vendor that are typically shared_
##    but in certain cases aren't.
##  Format
##    Field
##    - Vendor Name or extended regex.
##    - Date MM/DD(/(YY|YYYY))? or extended regex.
##    - Amount or extended regex.
##    The Vendor Name and Date fields must each be terminated by a comma (,).
##    Omit a field from matching by either leaving it entirely empty or by 
##    specifing an empty value using a pair of double quotes ("").  If an
##    empty value is specified, a comma must terminate the field if a value
##    is specified for a subsequent field.
##    Example
##      Use regex to exclude all purchases from BJS that occurred on 10/10/2022.
##      BJS.*,10/10/2022                     
##      Exclude all 110 Grill purchases whose amount is 125.64  Used
##      '\' to escape decimal point (period) to avert being interperted as 
##      a regex "match any single character" operator and specified no Date value.
##      110 Grill,,125\.64
##      Same as above but used two double quotes("") to omit Date from
##      match criteria.
##      110 Grill,"",125\.64
##
###############################################################################
costshare_chase_purchase_exclude_filter_tbl(){
#vendorNameRegex,dateRegex,amtRegex
  msg_fatal "override this function to exclude certain purchase transactions."
}
################################ Public API ###################################
##
##  Define the public functions that can be called to either perform the 
##  the work offered by this component or a worthwhile helper function.
##  The code below shouldn't change unless there's a bug.
##
###############################################################################

###############################################################################
##
##  Purpose
##    Extracts the transactions from the input purchase stream whose vendor name
##    was defined by the "costshare_vendor_pct_tbl", calculates the amount
##    owed by both Party 'X' and Party 'Y', and streams results. 
##  In
##    STDIN  - newline delimited text/CSV records with format:
##             "date,vendorName,charge"[forwardedFields].
##             Where:
##               date       - (required) MM/DD, MM/DD/YY, or MM/DD/YYY
##               vendorName - (required) see constraints defined by 'costshare_vendor_pct_tbl'.
##               cost       - (required) must conform to decimal number with 2
##                            places of accuracy to right of decimal point. 
##                            A negative sign can preceed the number and
##                            produce negative shared cost amount. 
##               [forwardedFields] - (optional) any data following the two digit
##                            cost will be forwarded through this component by
##                            appending this data to its generated output.
##    STDOUT - newline delimited text/CSV records with format:
##             "date,vendorName,charge,partyXpct,sharePartyXRound,sharePartyY"[forwardedFields]
##             Where:
##               partyXpct        - Party 'X' percentage applied to the charge
##               sharePartyXRound - Calculated Party 'X' portion of the charge
##                                  rounded using "unbaised/bankers" rounding method.
##               sharePartyY      - Calculated Party 'Y' portion of the charge.
##               [forwardedFields]- (optional) see STDIN above
###############################################################################
costshare_charge_share_run(){
  costshare__purchase_stream_normalize             \
  | costshare__purchase_exclude_filter_regex_apply \
  | costshare__grep_fixed_filter                   \
  | costshare__charge_share_compute
}
###############################################################################
##
##  Purpose
##    Verifies and transforms the contents of costshare_vendor_pct_tbl to
##    a uniform format.
##  Why
##    Reports on rows whose format and data values violate what's expected
##    by the functions in this component.
##    Applies some basic transforms so the data presented in the table
##    reflects the semantics of the corresponding data in the purchase input
##    stream.  For example, eliminating redundant whitespace from the vendor
##    name field.  This transform allows the comparison between vendor names
##    in the costshare_vendor_pct_tbl with ones appearing in the purchase
##    input stream.
##  Note
##    This function should be called by any function that must operate on the
##    clean/normalized content of the costshare_vendor_pct_tbl
##  In
##    STDIN  - rows of the costshare_vendor_pct_tbl provided by the
##             STDOUT of costshare_vendor_pct_tbl function.
##    STDOUT - verified and normalized rows of the costshare_vendor_pct_tbl
###############################################################################
costshare_vendor_pct_tbl_normalize(){
  costshare_vendor_pct_tbl \
  | costshare__vendor_pct_tbl_normalize
}
###############################################################################
##
##  Purpose
##    Creates a grep fixed filter to consume only the normalized vendor
##    names specified by the costshare_vendor_pct_tbl.
##  Why
##    Facilitate filtering using grep fixed filter tooling.
##    Improves reliability by replacing a statically coded instance
##    with a dynamically produced one. 
##  In
##    STDIN  - provided by STDOUT of costshare_vendor_pct_tbl_normalize
##    STDOUT - one or more newline delimited entries of normalize vendor names.
##             last normalized name is always 'DoesNotMatchAnyVendor' as it
##             should not match any vendor names and if the vendor table is 
##             empty, nothing in the input purchase stream will be processed.
##             Otherwise, if this filter was truely empty, all purchases would
##             be processed.  The above is encapsulated in single quotes.
###############################################################################
costshare_vendor_fixed_filter(){
  echo -n "'"
  costshare_vendor_pct_tbl_normalize \
  | costshare__vendor_fixed_filter
  # simplifies terminating filter.  also, if only entry due to empty costshare
  # table, creates a filter that doesn't match any input vendors. 
  echo DoesNotMatchAnyVendor"'"
}
##############################################################################
##    These constants are part of the public interface and can be changed.
###############################################################################
#
# defines the maximum number of errors, while scanning either the
# costshare_vendor_pct_tbl or purchase stream, that once exceeded will cause
# the execution to halt.
declare -g -i -r costshare_ERROR_THRESHOLD_STOP=10
#
# defines the vendor name's maximum length considered by this module for names
# that appear in the costshare_vendor_pct_tbl and those appearing in the
# billing/purchase input stream.
declare -g -i -r costshare_VENDOR_NAME_LENGTH_MAX=256

############################ private implementation ###########################
#
#   The code below shouldn't change unless there's a bug.
#
###############################################################################

#  vendor name has to start with at least 3 non whitespace characters.
#  trim spaces before and after a vendor's name but preserve consecutive
#  whitespace between words of a vendor name.
declare -g -r costshare__VENDOR_NAME_TRIM_REGEX='^[[:space:]]*([^[:space:]][^[:space:]][^[:space:]]+([[:space:]]+[^[:space:]]+)*)[[:space:]]*$'
#  allow whitespace either before or after vendor name and whole number
#  percentage.  allows leading and trailing spaces to align values
#  in a visual column pattern.
declare -g -r costshare__PCT_TABLE_REGEX='^[[:space:]]*([1-9][0-9]?[0-9]?)[[:space:]]*$'

costshare__vendor_pct_tbl_normalize(){

  local row
  local vendorName
  local -i pct=0
  local -i rowCnt=0
  local -i errorCnt=0
  local normRow
  while read -r row; do
    (( rowCnt++ ))

    if ! csv_field_get "$row" fieldUnset vendorName pct; then
      costshare__error_msg errorCnt "row" "$rowCnt" "$row" "fails to conform to basic CSV format"
      continue
    fi

    if [[ "${fieldUnset}" -ne 0 ]]; then
      costshare__error_msg errorCnt "row" "$rowCnt" "$row" "both vendor name and share percentage are required"
      continue
    fi
    
    if ! [[ $pct =~ $costshare__PCT_TABLE_REGEX ]]; then
      costshare__error_msg errorCnt "row" "$rowCnt" "$row" "invalid percentage format  costshare__PCT_TABLE_REGEX='$costshare__PCT_TABLE_REGEX'"
      continue
    fi

    pct=${BASH_REMATCH[1]} 
    if [[ $pct -gt 100 ]]; then
      costshare__error_msg errorCnt "row" "$rowCnt" "$row" "pct=$pct must be =< 100'"
      continue
    fi

    if ! [[ $vendorName =~ $costshare__VENDOR_NAME_TRIM_REGEX ]]; then
      costshare__error_msg errorCnt "row" "$rowCnt" "$row"  "vendor name fails costshare__VENDOR_NAME_TRIM_REGEX='$costshare__VENDOR_NAME_TRIM_REGEX'"
      continue
    fi

    vendorName=${BASH_REMATCH[1]}
    if [[ ${#vendorName} -gt $costshare_VENDOR_NAME_LENGTH_MAX ]]; then
      costshare__error_msg errorCnt "row" "$rowCnt" "$row"  "vendor name exceeds costshare_VENDOR_NAME_LENGTH_MAX=$costshare_VENDOR_NAME_LENGTH_MAX. Either override length or truncate vendor name"
      continue
    fi

    costshare__embedded_whitespace_replace "$vendorName" vendorName
    normRow=''
    csv_field_append normRow "$vendorName" "$pct"
    echo "$normRow"
  done
  if [[ $errorCnt -gt 0 ]]; then
    abort "Rows of costshare_vendor_pct_tbl don't comply with expected format. errorCnt=$errorCnt"
  fi
}
###############################################################################
##
##  Purpose
##    Helps create a 'grep' compliant fixed filter to select the purchases
##    broker by specific vendors.
##  Why
##    CSV format encapsulates vendor names that may contain a comma.  Without 
##    encapsulation, the comma becomes a delimiter dividing the name into two
##    distinct fields.  Therefore CSV parsing is required to preserve the
##    entire name.
##  In
##    STDIN - CSV formatted row with following fields in the order presented:
##              Vendor Name - (required) An exact or partial name.
##            Subsequent fields will be ignored. 
##  Out
##    STDOUT - Streams a vendor name absent its encapsulating quotes.
##
###############################################################################
costshare__vendor_fixed_filter(){

  local vendor
  local -i unsetFieldCnt
  local vendorName  
  while read -r vendor; do

    if ! csv_field_get "$vendor" unsetFieldCnt vendorName; then 
      abort 'invalid CSV format vendor='"$vendor"
    fi
  
    if [[ $unsetFieldCnt -gt 0 ]] \
    || [[ -z "$vendorName" ]]; then
      continue
    fi

    echo "$vendorName"

  done
}
###############################################################################
##
##  Purpose
##    Create a an extended regex filter to exclude purchases normally
##    included by "costshare_vendor_pct_tbl".  
##  Why
##    Sometimes parties agree not to share the cost of a specific purchase
##    from a vendor that they usually cost share.
##  In
##    STDIN - CSV formatted row with following fields:
##              Vendor Name Regex - (optional) An exact name or regex.
##              Date Regex        - (optional) An exact date in MM/DD(/YY|YYYY)? or regex.
##              Amount Regex      - (optional) An exact amount or regex.
##            At least one of the above fields must be specified.
##            When combined, the regex of these fields identify the purchase(s)
##            to specifically exclude.
##  Out
##    STDOUT - Each input row is combined into a single, extended regular
##             expression using the "or" operator.
###############################################################################
costshare__purchase_exclude_filter_regex_create(){

  local vendorNameRegex
  local dateRegex
  local amtRegex
  local exclude
  local regex
  local -i fieldUnset=0
  local -i excludeCnt=0
  while read -r exclude; do

    (( excludeCnt++ ))

    vendorNameRegex=''
    dateRegex=''
    amtRegex=''
    if ! csv_field_get "$exclude" fieldUnset  vendorNameRegex dateRegex amtRegex; then
      msg_fatal "problem reading exclude filter exclude='$exclude' excludeCnt=$excludeCnt"
    fi 

    if [[ "$fieldUnset" -gt 2   ]]; then
      msg_fatal "Exclude request must include at least one regex expression. exclude='$exclude' excludeCnt=$excludeCnt "
    fi

    if [[ -z "$vendorNameRegex" ]]; then
      # create filter to skip over this field
      vendorNameRegex='[^,]*'
    fi

    if [[ -z "$dateRegex" ]]; then
      # create filter to skip over this field
      dateRegex='[^,]*'
    fi

    if [[ -z "$amtRegex" ]]; then
      # create filter to skip over this field
      amtRegex='[^,]*'
    fi

    regex+="^${dateRegex},${vendorNameRegex},${amtRegex}|"

  done
  if [[ -n "$regex" ]]; then
    # eliminate dangling "or" operator at end of the regex
    echo "${regex:0:${#regex}-1}"
  fi
}
###############################################################################
##
##  Purpose
##    Excludes purchases normally cost shared by applying a filter, generated
##    from costshare_chase_purchase_exclude_filter_tbl.   
##  Why
##    Sometimes parties agree not to share the cost of a specific purchase
##    from a vendor that they usually cost share.
##  In
##    STDIN - Conforms to CSV purchase format (interface) accepted by
##            costshare_charge_share_run.
##    costshare_chase_purchase_exclude_filter_tbl
##            A function that provides regular expressions via STDIN from
##            a table.  
##  Out
##    STDOUT - bash associative array syntax where the "key" is the vendor name
##             while its value is Party 'X''s percentage.
###############################################################################
costshare__purchase_exclude_filter_regex_apply(){

  local -r regexfilter="$( costshare_chase_purchase_exclude_filter_tbl | costshare__purchase_exclude_filter_regex_create )"
  if [[ $? -ne 0 ]]; then
    exit 1
  fi

  if [[ -z "$regexFilter" ]]; then
    tee
    return
  fi 

  grep -E -v "$regexfilter"
}
###############################################################################
##
##  Purpose
##    Creates serialized form of the costshare_vendor_pct_tbl_normalize that
##    conforms to the bash syntax needed to assign an associative array's
##    key/value pairs to a bash asssociative array.
##  Why
##    Facilitates searching by using the vendor name, or a portion of it, to
##    both identify transactions of interest and compute the appropriate share
##    amounts for Party 'Y' and Party 'X'.
##  In
##    STDIN - generated by the STDOUT of costshare_vendor_pct_tbl_normalize.
##  Out
##    STDOUT - bash associative array syntax where the "key" is the vendor name
##             while its value is Party 'X''s percentage.
###############################################################################
costshare__vendor_pct_map_create(){
  costshare_vendor_pct_tbl_normalize \
  | costshare__vendor_pct_map_syntax_gen
}
costshare__vendor_pct_map_syntax_gen(){
  local vendorPct
  local vendorName
  local pct
  local -A vendorMap
  local -i unsetFieldCnt
  while read -r vendorPct; do

    if ! csv_field_get "$vendorPct" unsetFieldCnt vendorName pct; then
      exit 1
    fi
 
    if [[ $unsetFieldCnt -gt 0 ]]; then
      continue
    fi 

    vendorMap["$vendorName"]="$pct"

  done
  local -r vendorMapSerialized=$(typeset -p vendorMap)
  echo ${vendorMapSerialized#declare -A vendorMap=}
}
###############################################################################
##
##  Purpose
##    Create an associative array (map) whose key represents the first space
##    deliminited word (root) of a vendor's name.  While its value contains a
##    space separated "array" of vendor name lengths whose vendor names begin
##    with the same root.  The array of lengths is ordered from longest vendor
##    name to the shortest one (that share the same root). 
##  Why
##    Certain vendors denote certain purchases as "subtypes".  The cost of 
##    these subtypes might be calculated via a different percentage then other
##    subtypes or root type.  In order to associate the approprate percentage
##    to the correct vendor's subtype, the most specific subtype should be
##    matched against the vendor's name before matching against a more generic
##    type.  For example, "BJS WHOLESALE CLUB" vs "BJS FUEL".  The root of both
##    vendors is "BJS".  The subtype "WHOLESALE CLUB" refers to home commmodity
##    items such as fruits, vegitables, paper towels, TVs, ... while
##    the "FUEL" subtype restricts itself to purchases of gasoline.  The
##    "WHOLESALE CLUB" purchases percentage is typically 29% while "FUEL" costs
##    are shared at 50%.
##  In
##    STDIN - streamed costshare_vendor_pct_tbl_normalize
##
##  Out
##    STDOUT - bash serialized associated map without "declare -A ...".
##             Stream begins with "(" and ends with ")"   
###############################################################################
costshare__vendor_name_length_map_create(){
  costshare_vendor_pct_tbl_normalize \
  | costshare__vendor_name_length_map
}

costshare__vendor_name_length_map(){
  
  local -i nameLen
  local -A nameLenMap
  local lenEncoding
  local vendorName
  while read -r line; do
    vendorName=${line%%,*}
    nameLen=${#vendorName}
    if [[ $nameLen -lt 3 ]]; then
      abort "vendor name must be at least 3 characters long. vendorName='$vendorName' nameLen=$nameLen"
    fi
    vendorStartWord=${vendorName%% *}
    lenEncoding=${nameLenMap[$vendorStartWord]}
    set -- $lenEncoding
    costshare__vendor_pct_name_encoding_ordering lenEncodingNew nameLen "$@"
    nameLenMap[$vendorStartWord]=$lenEncodingNew
  done
  local -r nameLenSerialized=$(typeset -p nameLenMap)
  echo ${nameLenSerialized#declare -A nameLenMap=}
}

costshare__vendor_pct_name_encoding_ordering(){
  local -n lenEncodingNewRtn=$1
  local -i -r newLen=$2

  shift 2
  lenEncodingNewRtn=""
  local -i dupLenSkip=0
  while [[ $# -gt 0 ]]; do
    if [[ $newLen -eq $1 ]]; then
      # length already included
      dupLenSkip=1
      break
    fi
    if [[ $newLen -gt $1 ]]; then
      break
    fi
    lenEncodingNewRtn+=" $1"
    shift
  done
  if [[ $dupLenSkip == 0 ]]; then 
    lenEncodingNewRtn+=" $newLen"
  fi
  if [[ $# -gt 0 ]]; then
    lenEncodingNewRtn+=" ""$@"
  fi
}

# purchase date enables filtering by this component, require at least MM/DD
# but allow for MM/DD/YY or YYYY.
declare -g -r costshare__PURCHASE_DATE_REGEX='(^[0-1][0-9]/[0-3][0-9](/[0-9][0-9]([0-9][0-9])?)?)'
# requires at least 1 digit to left of decimal. If decimal point specified, 2
# decimal places must be specified.  A charge is positive while a 
# refund/reimbursement is represented as a negative charge amount.
declare -g -r costshare__PURCHASE_CHARGE_REGEX='(^[-]?[0-9]+(\.[0-9][0-9])?)'

costshare__purchase_stream_normalize(){

  local purchase
  local purchaseDate
  local vendorName
  local charge
  local $csv_field_REMAINDER
  local forwardFields
  local normRow
  local -i unsetFieldCnt
  local -i chargeNumStart
  local -i purchaseCnt=0
  local -i errorCnt=0
  while read -r purchase; do
 
    # any fields after the required ones are optional.  since they might not exist
    # (re)set the remainder field to empty string.
    eval $csv_field_REMAINDER=\'\'
    if ! csv_field_get "$purchase" unsetFieldCnt purchaseDate vendorName charge $csv_field_REMAINDER 2>/dev/null; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase" "does not comply with basic CSV format."
      continue
    fi

    if [[ $unsetFieldCnt -gt 1 ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase" "required field: purchaseDate, vendor name, and/or charge notspecified."
      continue
    fi
      
    if ! [[ $purchaseDate =~ $costshare__PURCHASE_DATE_REGEX ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase" "date does not match expected format.  costshare__PURCHASE_DATE_REGEX='$costshare__PURCHASE_DATE_REGEX'"
      continue
    fi

    if ! [[ $vendorName =~ $costshare__VENDOR_NAME_TRIM_REGEX ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase"  "vendor name fails costshare__VENDOR_NAME_TRIM_REGEX='$costshare__VENDOR_NAME_TRIM_REGEX'"
      continue
    fi
    vendorName=${BASH_REMATCH[1]}

    if [[ ${#vendorName} -gt $costshare_VENDOR_NAME_LENGTH_MAX ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase"  "vendor name exceeds costshare_VENDOR_NAME_LENGTH_MAX=$costshare_VENDOR_NAME_LENGTH_MAX. Either override length or truncate vendor name"
      continue
    fi
    # applying this function unifies the vendor name semantics
    # between the costshare__vendor_pct_tbl and purchase stream.
    # permits their comparision or use as hash values.
    costshare__embedded_whitespace_replace "$vendorName" vendorName

    if ! [[ "$charge" =~ $costshare__PURCHASE_CHARGE_REGEX ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase" "charge amount does not match expected format.  costshare__PURCHASE_CHARGE_REGEX='$costshare__PURCHASE_CHARGE_REGEX'"
      continue
    fi

    chargeNumStart=0
    if [[ "${charge:0:1}" == '-' ]]; then chargeNumStart=1; fi
    if [[ "${charge:$chargeNumStart:1}" == '0' ]] \
    && [[ "${charge:$chargeNumStart:2}" != '0.' ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase"  "Charges cannot start with '0' when charge/refund greater than 0.99."
      continue
    fi

    eval forwardFields\=\"\$$csv_field_REMAINDER\"
    if [[ -n "$forwardFields" ]]; then
      # forwarded fields must be prefixed by
      # comma to maintain CSV spec for charge field.
      forwardFields=",$forwardFields"
    fi

    normRow=''
    csv_field_append normRow "$purchaseDate" "$vendorName" "$charge"
    echo "$normRow"$forwardFields

  done
  if [[ $errorCnt -gt 0 ]]; then
    abort "Purchase entry(s) from purchase stream do not comply with expected format. errorCnt=$errorCnt"
  fi
}

costshare__embedded_whitespace_replace(){
  local stringIn=$1
  local -n stringRtn=$2

  # convert a tab to space so a tab before or after a space
  # or consecutive tabs looks like consecutive spaces.
  local -r tab='	'
  local -r space=' '
  stringIn="${stringIn//$tab/$space}"

  local stringPrev
  while [[ "$stringIn" != "$stringPrev" ]]; do
    stringPrev="$stringIn"
    stringIn="${stringIn//$space$space/$space}"
  done

  stringRtn=$stringIn
} 


costshare__charge_share_compute(){

  eval local \-\A \-\r vendorPCT=$(costshare__vendor_pct_map_create)
  eval local \-\A \-\r vendorNameLen=$(costshare__vendor_name_length_map_create)

  local purchase
  local purchaseDate
  local vendorName
  local charge
  local forwardFields
  local vendorRoot
  local vendorSubtypeLens
  local $csv_field_REMAINDER
  while read -r purchase; do

    # any fields after the required ones are optional.  since they might not exist
    # (re)set the remainder field to empty string.
    eval $csv_field_REMAINDER=\'\'
    if ! csv_field_get "$purchase" unsetFieldCnt purchaseDate vendorName charge $csv_field_REMAINDER 2>/dev/null; then
      abort 'Purchase data fails basic CSV spec. purchase='"'""$purchase""'"
    fi
    
    vendorRoot=${vendorName%% *}
    vendorSubtypeLens=${vendorNameLen[$vendorRoot]}
    if [[ -z "$vendorSubtypeLens" ]]; then
      abort "Could not determine vendorSubtypeLens for vendorRoot='$vendorRoot' "
    fi

    local partyXpct=0
    costshare__charge_share_pct_get vendorPCT "$vendorSubtypeLens" "$vendorName" partyXpct

    # use awk for unbiased rounding to a penny, as bash performs only integer math
    local sharePartyX=0
    local sharePartyXRound=$(echo $charge $partyXpct        | awk '{ printf("%.2f",($1*$2/100))}' )
    local sharePartyY=$(     echo $charge $sharePartyXRound | awk '{ printf("%.2f",($1-$2))}')
    # convert decimal totals to intergers so bash can perform arithmetic instead of awk.
    # done this way because it should be faster as, a call to awk 
    # represents a child fork of this process and awk also introduces rounding
    # error when substracting what it considers floating point numbers.
    # the rounding error can be "fixed" by multiplying the numbers by 100 so
    # awk sees them as integers but chose the bash method below.  
    local -i checkCharge="${charge//./} - ${sharePartyXRound//./} - ${sharePartyY//./}"
    if [[ $checkCharge -ne 0 ]]; then
      abort "Failed to compute proper share amounts for purchase='$purchase' "
    fi

    eval forwardFields\=\"\$$csv_field_REMAINDER\"
    if [[ -n "$forwardFields" ]]; then
      # forwarded fields must be prefixed by
      # comma to maintain CSV spec for charge field.
      forwardFields=",$forwardFields"
    fi

    local purchaseShare=''
    csv_field_append purchaseShare "$purchaseDate" "$vendorName" "$charge" "$partyXpct" "$sharePartyXRound" "$sharePartyY"
    echo "$purchaseShare$forwardFields"

  done
}

costshare__charge_share_pct_get(){
  local -r vendorPCTmap=$1
  local -r vendorSubtypeLens="$2"
  local -r vendorName="$3"
  local -n partyXpctRTN=$4

  local -a pct=0
  set -- $vendorSubtypeLens
  while [[ $# -gt 0 ]]; do
    local subtypeName=${vendorName:0:$1}
    eval pct\=\$\{$vendorPCTmap\[\$subtypeName\]\}
    if [[ -n $pct ]]; then
      partyXpctRTN=$pct
      return
    fi
    shift
  done
  abort "Failed to find vendorName='$vendorName' in vendor_pct_table."
}

costshare__grep_fixed_filter(){
  local -r filter="$(costshare_vendor_fixed_filter)"
  # this function was created to encapsulate processing grep
  # and the eval required to properly include fixed strings
  # to simplify the code that uses it.
  eval grep \-\-fixed\-strings "$filter"
}

costshare__error_msg(){
  local -n errorCntRTN=$1
  local -r entryType="$2"
  local -r entryCnt=$3
  local -r entryContent="$4"
  local -r msg="$5"

  (( errorCntRTN++ ))
  echo "Error: ${msg}. ${entryType}Cnt=$entryCnt ${entryType}='$entryContent'">&2
  if [[ $errorCntRTN -lt $costshare_ERROR_THRESHOLD_STOP ]]; then
    return
  fi
 abort "Number of errors detected exceeeds
 + costshare_ERROR_THRESHOLD_STOP=$costshare_ERROR_THRESHOLD_STOP.
 + Repair these errors to continue." 
}   

abort(){
  echo Abort: "$@" >&2
  exit 1
}

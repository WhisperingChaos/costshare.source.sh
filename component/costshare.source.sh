#!/bin/bash
###############################################################################
##
##  costshare
##
##  Purpose
##    Divide the purchase cost of an item/service between two parties: Party 'X'
##    and Party 'Y'.  Requires a table whose rows relate a vendor to the 
##    precentage charged to Party 'X' and a stream of purchase transactions
##    whose data includes a vendor name that's used to correlate the a 
##    row in the table. 
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
##    share of a charge owed between two parties.  
##  Why
##    Automates the process of filtering the purchases that two parties agree
##    on paying and associating the percentage to be paid by Party 'X' to
##    the selected ones.
##  Format
##    The first field in the table is the vendor's name.  
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
##      prevent exploitation/bugs if the vendor name wasn't limited.
##    Party 'X' Percentage
##    - The percentage of the total charge to be paid by Party 'X'.
##    - The share paid by Party 'Y' is the amount that remains after deducting
##      the amount owed by Party 'X'.
##    - Must be a whole number between 0-100.
##
###############################################################################
costshare_vendor_pct_tbl(){
  abort "Override this table to provide the streaming data in the required form."
# Vendor Name, Party 'X' Percentage
# Heredoc example:
cat <<costshare_vendor_pct_tbl
WHOLE Foods,50 
costshare_vendor_pct_tbl
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
##             "mmdd,vendorName,charge".
##             Where:
##               mmdd       - nn/nn
##               vendorName - see constraints defined by 'costshare_vendor_pct_tbl'.
##               charge     - must conform to decimal number with 2 places of 
##                            accuracy to right of decimal point.  
##    STDOUT - newline delimited text/CSV records with format:
##             "mmdd,vendorName,charge,
##             Where:
##               pctPartyX  - Party 'X' percentage applied to the charge
##               sharePartyXRound - Calculated Party 'X' portion of the charge
##                 rounded using "unbaised/bankers" rounding method.
##               sharePartyY - Calculated Party 'X' portion of the charge.
###############################################################################
costshare_charge_share_run(){
  local -r VENDOR_FILTER=$(costshare_vendor_filter_regex)
  grep -E "$VENDOR_FILTER"			\
  | costshare__purchase_stream_normalize	\
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
  costshare_vendor_pct_tbl | costshare__vendor_pct_tbl_normalize
}
###############################################################################
##
##  Purpose
##    Creates a regex pattern of all vendor names by inserting an "or" operator
##    at the end of a name. An embedded space within an name becomes part of
##    the regex match.  As such, it's expected that the regex implementation
##    will interperate the space as a match character instead of a whitespace
##    that's ignored. 
##  Why
##    Facilitate filtering using regex compliant tools, like "grep -E".
##    Increase component reliability by eliminating static coding via the 
##    generation of the regex filter from provided table. 
##  In
##    STDIN  - provided by STDOUT of costshare_vendor_pct_tbl_normalize
##    STDOUT - a single line of Vendor root names separated by regex "or"
##             operator where the last vendor name is 'DoesNotMatchAnyVendor'.
###############################################################################
costshare_vendor_filter_regex(){

  costshare_vendor_pct_tbl_normalize | awk 'BEGIN { FS = "," } ; { printf("%s%s",$1,"|")}'
  # eliminaes the code needed to remove last 'or'. 
  echo DoesNotMatchAnyVendor
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
#  percentage.  allows leading leading/trailing spaces to align values
#  in a visual column pattern.
declare -g -r costshare__VENDOR_PCT_TABLE_REGEX='^([^,]+),[[:space:]]*([1-9][0-9]?[0-9]?)[[:space:]]*$'

costshare__vendor_pct_tbl_normalize(){

  local row
  local vendorName
  local -i pct=0
  local -i rowCnt=0
  local -i errorCnt=0
  while read -r row; do
    (( rowCnt++ ))
    if ! [[ $row =~ $costshare__VENDOR_PCT_TABLE_REGEX ]]; then
      costshare__error_msg errorCnt "row" "$rowCnt" "$row" "fails format check regexVerify='$regexVerify'"
      continue
    fi

    vendorName=${BASH_REMATCH[1]} 
    pct=${BASH_REMATCH[2]}

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
      costshare__error_msg errorCnt "row" "$rowCnt" "$row"  "vendor name exceeds costshare_VENDOR_NAME_LENGTH_MAX=$costshare_VENDOR_NAME_LENGTH_MAX . Either override length or truncate vendor name."
      continue
    fi

    costshare__embedded_whitespace_replace "$vendorName" vendorName
    echo "$vendorName","$pct"
  done
  if [[ $errorCnt -gt 0 ]]; then
    abort "Rows of costshare_vendor_pct_tbl don't comply with expected format. errorCnt=$errorCnt"
  fi
}
###############################################################################
##
##  Purpose
##    Creates serialized form of the costshare_vendor_pct_tbl_normalize that conforms to the bash
##    syntax needed to assign an associative array's key/value pairs to a
##    bash asssociative array.
##  Why
##    Facilitates searching by using the vendor name, or a portion of it, to
##    both identify transactions of interest and compute the appropriate share
##    amounts for Party 'Y' and Party 'X'.
##  In
##    STDIN - generated by costshare_vendor_pct_tbl_normalize STDOUT.
##  Out
##    STDOUT - bash associative array syntax where the "key" is the vendor name
##             while its value is Party 'X''s percentage.
###############################################################################
costshare__vendor_pct_map_create(){
  costshare_vendor_pct_tbl_normalize | awk 'BEGIN { FS = ","; print "(" } ; { print "[\""$1"\"]" "=" "\""$2"\""}; END { print ")" }'
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
  costshare_vendor_pct_tbl_normalize | costshare__vendor_name_length_map
}

costshare__vendor_name_length_map(){
  
  local -i nameLen
  local -A nameLenMap
  local lenEncoding
  local vendorName
  while read line; do
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
  local -r lenEncodingNewRtn=$1
  local -i -r newLen=$2

  shift 2
  local _lenEncodingNew
  while [[ $# -gt 0 ]]; do
    if [[ $newLen -gt $1 ]]; then
      break
    fi
    _lenEncodingNew+=" $1"
    shift
  done
  _lenEncodingNew+=" $newLen"
  if [[ $# -gt 0 ]]; then
    _lenEncodingNew+=" ""$@"
  fi
  eval $lenEncodingNewRtn\=\$\_lenEncodingNew
}

# require at least MM/DD but allow for MM/DD/YY or YYYY. date is not processed by
# this component therefore accept a couple variations 
declare -g -r costshare__PURCHASE_DATE_REGEX='([0-1][0-9]/[0-3][0-9](/[0-9][0-9]([0-9][0-9])?)?)'
# accept any characters except a comma inside a vendor name.
declare -g -r costshare__PURCHASE_VENDOR_NAME_REGEX='([^,]+)'
# requires a number of at least 1 digit to left of decimal. If decimal point specified, 2
# decimal places must be specified.  Allows for reimbursement as a negative charge amount.
declare -g -r costshare__PURCHASE_CHARGE_REGEX='([-]?[0-9]+(\.[0-9][0-9])?)'
# allow other data, not used by this component, to pass through as part of its stream.
# provides means to easily add processes that execute before or after this one   
declare -g -r costshare__PURCHASE_FORWARD_REGEX='(.*)$'
# purposely anchored only the fields required by this module so they must appear at the
# start of the purchase data.
declare -g -r costshare__PURCHASE_DATA_FORMAT_REGEX='^'\
"$costshare__PURCHASE_DATE_REGEX"','\
"$costshare__PURCHASE_VENDOR_NAME_REGEX"','\
"$costshare__PURCHASE_CHARGE_REGEX"\
"$costshare__PURCHASE_FORWARD_REGEX" 
declare -g -i -r costshare__PURCHASE_DATE_IDX=1
declare -g -i -r costshare__PURCHASE_VENDOR_NAME_IDX=4
declare -g -i -r costshare__PURCHASE_CHARGE_IDX=5
declare -g -i -r costshare__PURCHASE_FORWARD_IDX=7

costshare__purchase_stream_normalize(){

  local purchase
  local purchaseDate
  local vendorName
  local charge
  local forwardFields
  local chargeNumStart
  local -i purchaseCnt=0
  local -i errorCnt=0
  while read -r purchase; do

    if ! [[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase" "failed to match expected format.  costshare__PURCHASE_DATA_FORMAT_REGEX='$costshare__PURCHASE_DATA_FORMAT_REGEX'"
      continue
    fi

    purchaseDate="${BASE_REMATCH[$costshare__PURCHASE_DATE_IDX]}"
    vendorName="${BASE_REMATCH[$costshare__PURCHASE_VENDOR_NAME_IDX]}"
    charge="$chargeRTN=${BASE_REMATCH[$costshare__PURCHASE_CHARGE_IDX]}"
    forwardFields="${BASE_REMATCH[$costshare__PURCHASE_FORWARD_IDX]}"

    if ! [[ $vendorName =~ $costshare__VENDOR_NAME_TRIM_REGEX ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase"  "vendor name fails costshare__VENDOR_NAME_TRIM_REGEX='$costshare__VENDOR_NAME_TRIM_REGEX'"
      continue
    fi

    vendorName=${BASH_REMATCH[1]}

    if [[ ${#vendorName} -gt $costshare_VENDOR_NAME_LENGTH_MAX ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase"  "vendor name exceeds costshare_VENDOR_NAME_LENGTH_MAX=$costshare_VENDOR_NAME_LENGTH_MAX . Either override length or truncate vendor name."
      continue
    fi

    chargeNumStart=0
    if [[ "${charge:0:1}" == '-' ]]; then chargeNumS
tart=1; fi
    if [[ "${charge:$chargeNumStart:1}"   == "0" ]] \
    && [[ "${charge:$chargeNumStart+1:1}" != "." ]]; then
      costshare__error_msg errorCnt "purchase" "$purchaseCnt" "$purchase"  "Charges cannot start with '0' when charge/refund greater than 0.99."
      continue
    fi

    # applying this function unifies the vendor name semantics
    # between the costshare__vendor_pct_tbl and purchase stream
    costshare__embedded_whitespace_replace "$vendorName" vendorName

    echo "$pruchaseDateMMDD","$vendorName","$charge","$forwardFields"

  done
}


costshare__embedded_whitespace_replace(){
  local stringIn=$1
  local -n stringRtn=$2

  # convert a tab to space so a tab before or after a space
  # or consecutive tabs looks like consecutive spaces.
  stringIn="${stringIn//\	/\ }"

  local stringPrev
  while [[ "$stringIn" != "$stringPrev" ]]; do
    stringPrev="$stringIn"
    stringIn="${stringIn//\ \ /\ }"
  done

  stringRtn=$stringIn
} 


costshare__charge_share_compute(){

  eval local \-\A \-\r vendorPCT=$(costshare__vendor_pct_map_create)
  eval local \-\A \-\r vendorNameLen=$(costshare__vendor_name_length_map_create)

  local -r vendorRegex=$costshare__expected_format_regex
  local purchase
  while read -r purchase; do

    if ! [[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]; then
      abort 'Charge format invalid=' "$purchase"
    fi
    local vendorName="${BASH_REMATCH[$costshare__PURCHASE_VENDOR_NAME_IDX]}"
    local charge=${BASH_REMATCH[$costshare__PURCHASE_CHARGE_IDX]}
    local vendorRoot=${vendorName%% *}
    local vendorSubtypeLens=${vendorNameLen[$vendorRoot]}
    if [[ -z "$vendorSubtypeLens" ]]; then
      abort "Could not determine vendorSubtypeLens for vendorRoot=$vendorRoot"
    fi

    local pctPartyX=0
    costshare__charge_share_pct_get vendorPCT "$vendorSubtypeLens"  pctPartyX "$vendorName"

    # use awk for unbiased rounding to a penny, as bash performs only integer math
    local sharePartyX=0
    local sharePartyXRound=$(echo $charge $pctPartyX                      | awk '{ printf("%.2f",($1*$2/100))}' )
    local sharePartyY=$(     echo $charge $sharePartyXRound               | awk '{ printf("%.2f",($1-$2))}')
    # convert decimal totals to intergers so bash can perform arithmetic instead of awk.
    # done this way because it should be faster as, a call to awk 
    # represents a child fork of this process and awk also introduces rounding
    # error when substracting what it considers floating point numbers.
    # the rounding error can be "fixed" by multiplying the numbers by 100 so
    # awk sees them as integers but chose the bash method below.  
    local -i checkCharge="${charge//./} - ${sharePartyXRound//./} - ${sharePartyY//./}"
    if [[ $checkCharge -ne 0 ]]; then
      abort "Failed to compute proper share amounts for transaction=$purchase"
    fi

    echo "$purchase",$pctPartyX,$sharePartyXRound,$sharePartyY

  done
}

costshare__charge_share_pct_get(){
  local -r vendorPCTmap=$1
  local -r vendorSubtypeLens="$2"
  local -r vendorPCTrtn=$3
  local -r vendorName="$4"

  local -a pct=0
  set -- $vendorSubtypeLens
  while [[ $# -gt 0 ]]; do
    local subtypeName=${vendorName:0:$1}
    eval pct\=\$\{$vendorPCTmap\[\$subtypeName\]\}
    if [[ -n "$pct" ]]; then
      eval $vendorPCTrtn\=\$pct
      return
    fi
    shift
  done
  abort "Failed to find vendorName='$vendorName' in vendor_pct_table."
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

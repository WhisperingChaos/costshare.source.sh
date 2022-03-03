#!/bin/bash
compose_executable(){
  local -r callFromDir="$( dirname "$1" )"

  local -r callSourcer="$callFromDir"'/config_sh/vendor/sourcer/sourcer.sh'
  local -r myRoot="$callFromDir"'/costshare_test_sh'
  local mod
  for mod in $( "$callSourcer" "$myRoot"); do
    source "$mod"
  done
}


test_costshare__error_msg(){

  local -i errorCnt=0
  assert_output_true \
    echo "Error: message to print. rowCnt=1 row='entry content'" \
    --- \
    costshare__error_msg errorCnt 'row' 1 'entry content' 'message to print'

  errorCnt=0
  costshare__error_msg errorCnt 'row' 1 'entry content' 'message to print' 2>/dev/null
  assert_true '[[ $errorCnt -eq 1 ]]'

  assert_output_true \
    test_costshare__error_msg_threshold_expected \
    --- \
    test_costshare__error_msg_threshold_exit
}
test_costshare__error_msg_threshold_exit()(

   errorCnt=$costshare_ERROR_THRESHOLD_STOP
   costshare__error_msg errorCnt 'row' 1 'entry content' 'message to print'
 
  # exceeding the threshold should exit this child
  # process before executing this assert.  if it does
  # the assert should fail generating unexpected
  # output that should be detected by the 
  # calling assert_output_true function.
  assert_true false
  assert_return_code_set
)
test_costshare__error_msg_threshold_expected(){
  cat <<'test_costshare__error_msg_threshold_expected_output'
Error: message to print. rowCnt=1 row='entry content'
Abort: Number of errors detected exceeeds
 + costshare_ERROR_THRESHOLD_STOP=10.
 + Repair these errors to continue.
test_costshare__error_msg_threshold_expected_output
}


test_costshare_vendor_pct_tbl_normalize(){

  test_costshare_vendor_pct_tbl_names_with_whitespace_special_characters
  assert_output_true \
    test_costshare_vendor_pct_tbl_expected \
    --- \
    costshare_vendor_pct_tbl_normalize

}
test_costshare_vendor_pct_tbl_names_with_whitespace_special_characters(){
costshare_vendor_pct_tbl(){
cat <<'costshare_vendor_pct_tbl'
   Root1 Vendor,  20
Root2 Vendor,30
Root3   Vendor,40
Root4		Vendor,40
Root5		Vendor    part1 part2  part3 4,50
Root6 ~ ! # $ % ^ & ( ) _ - + = ] [ | \ " ' | ? . / < > $s * : end,60
costshare_vendor_pct_tbl
}
test_costshare_vendor_pct_tbl_expected(){
cat <<'costshare_vendor_pct_tbl_result'
Root1 Vendor,20
Root2 Vendor,30
Root3 Vendor,40
Root4 Vendor,40
Root5 Vendor part1 part2 part3 4,50
Root6 ~ ! # $ % ^ & ( ) _ - + = ] [ | \ " ' | ? . / < > $s * : end,60
costshare_vendor_pct_tbl_result
}
}

test_costshare__purchase_REGEX(){

# MM/DD
  local purchase='01/10,vendor name,100.50,forwarded,fields'
  assert_true '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'

  local purchaseDate="${BASH_REMATCH[$costshare__PURCHASE_DATE_IDX]}"
  assert_true '[[ $purchaseDate == "01/10" ]]'

  local vendorName="${BASH_REMATCH[$costshare__PURCHASE_VENDOR_NAME_IDX]}"
  assert_true '[[ $vendorName == "vendor name" ]]'

  local charge=${BASH_REMATCH[$costshare__PURCHASE_CHARGE_IDX]}
  assert_true '[[ $charge == "100.50" ]]'

  local forwardFields=${BASH_REMATCH[$costshare__PURCHASE_FORWARD_IDX]}
  assert_true '[[ $forwardFields == ",forwarded,fields" ]]'

# MM/DD/YYYY
  local purchase='01/10/2022,vendor name,100.50,forwarded,fields'
  assert_true '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'

  local purchaseDate="${BASH_REMATCH[$costshare__PURCHASE_DATE_IDX]}"
  assert_true '[[ $purchaseDate == "01/10/2022" ]]'

  local vendorName="${BASH_REMATCH[$costshare__PURCHASE_VENDOR_NAME_IDX]}"
  assert_true '[[ $vendorName == "vendor name" ]]'

  local charge=${BASH_REMATCH[$costshare__PURCHASE_CHARGE_IDX]}
  assert_true '[[ $charge == "100.50" ]]'

  local forwardFields=${BASH_REMATCH[$costshare__PURCHASE_FORWARD_IDX]}
  assert_true '[[ $forwardFields == ",forwarded,fields" ]]'

# whole number charge
  local purchase='01/10/20,vendor name,100,forwarded,fields'
  assert_true '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'

  local purchaseDate="${BASH_REMATCH[$costshare__PURCHASE_DATE_IDX]}"
  assert_true '[[ $purchaseDate == "01/10/20" ]]'

  local vendorName="${BASH_REMATCH[$costshare__PURCHASE_VENDOR_NAME_IDX]}"
  assert_true '[[ $vendorName == "vendor name" ]]'

  local charge=${BASH_REMATCH[$costshare__PURCHASE_CHARGE_IDX]}
  assert_true '[[ $charge == "100" ]]'

  local forwardFields=${BASH_REMATCH[$costshare__PURCHASE_FORWARD_IDX]}
  assert_true '[[ $forwardFields == ",forwarded,fields" ]]'

# negative whole number charge(refund)
  local purchase='01/10/20,vendor name,-100,forwarded,fields'
  assert_true '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'

  local purchaseDate="${BASH_REMATCH[$costshare__PURCHASE_DATE_IDX]}"
  assert_true '[[ $purchaseDate == "01/10/20" ]]'

  local vendorName="${BASH_REMATCH[$costshare__PURCHASE_VENDOR_NAME_IDX]}"
  assert_true '[[ $vendorName == "vendor name" ]]'

  local charge=${BASH_REMATCH[$costshare__PURCHASE_CHARGE_IDX]}
  assert_true '[[ $charge == "-100" ]]'

  local forwardFields=${BASH_REMATCH[$costshare__PURCHASE_FORWARD_IDX]}
  assert_true '[[ $forwardFields == ",forwarded,fields" ]]'

# vendor name with spaces
  local purchase='01/10/20,  vendor    name  ,-100,forwarded,fields'
  assert_true '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'

  local purchaseDate="${BASH_REMATCH[$costshare__PURCHASE_DATE_IDX]}"
  assert_true '[[ $purchaseDate == "01/10/20" ]]'

  local vendorName="${BASH_REMATCH[$costshare__PURCHASE_VENDOR_NAME_IDX]}"
  local -r vdn="  vendor    name  " 
  assert_true '[[ "$vendorName" == "$vdn" ]]'

  local charge=${BASH_REMATCH[$costshare__PURCHASE_CHARGE_IDX]}
  assert_true '[[ $charge == "-100" ]]'

  local forwardFields=${BASH_REMATCH[$costshare__PURCHASE_FORWARD_IDX]}
  assert_true '[[ $forwardFields == ",forwarded,fields" ]]'

# remove optional forwarded fields
  local purchase='01/10/20,vendor name,-100'
  assert_true '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'

  local purchaseDate="${BASH_REMATCH[$costshare__PURCHASE_DATE_IDX]}"
  assert_true '[[ $purchaseDate == "01/10/20" ]]'

  local vendorName="${BASH_REMATCH[$costshare__PURCHASE_VENDOR_NAME_IDX]}"
  assert_true '[[ $vendorName == "vendor name" ]]'

  local charge=${BASH_REMATCH[$costshare__PURCHASE_CHARGE_IDX]}
  assert_true '[[ $charge == "-100" ]]'

  local forwardFields=${BASH_REMATCH[$costshare__PURCHASE_FORWARD_IDX]}
  assert_true '[[ "$forwardFields" == "" ]]'

# bad date
  local purchase='011,vendor name,-100'
  assert_false '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'

# bad vendor name
  local purchase='01/11,vendor,name,-100'
  assert_false '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'

# bad vendor name
  local purchase='01/11,vendor, 100 name,-100'
  assert_false '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'

# bad vendor name but undetectable
  local purchase='01/11,vendor,100 name,-100'
  assert_true '[[ $purchase =~ $costshare__PURCHASE_DATA_FORMAT_REGEX ]]'
}

test_costshare__embedded_whitespace_replace(){

  costshare__embedded_whitespace_replace '		a  b' result
  assert_true '[[ "$result" == " a b" ]]'

  costshare__embedded_whitespace_replace 'a  b' result
  assert_true '[[ "$result" == "a b" ]]'

  costshare__embedded_whitespace_replace '  a  b  c  d' result
  assert_true '[[ "$result" == " a b c d" ]]'

  costshare__embedded_whitespace_replace 'abcd' result
  assert_true '[[ "$result" == "abcd" ]]'
}

test_costshare__vendor_pct_map_create(){
  costshare_vendor_pct_tbl(){
    echo 1Root Vendor,20
    echo 2Root Vendor,30
  }
  assert_output_true \
    test_costshare__vendor_pct_map_create_output_1 \
    --- \
   costshare__vendor_pct_map_create
}
test_costshare__vendor_pct_map_create_output_1(){
cat <<test_costshare__vendor_pct_map_create_output_1
(
["1Root Vendor"]="20"
["2Root Vendor"]="30"
)
test_costshare__vendor_pct_map_create_output_1
}


test_costshare__vendor_pct_name_encoding_ordering(){

  local lenEncodingNew

  costshare__vendor_pct_name_encoding_ordering lenEncodingNew 1
  assert_true '[[ "$lenEncodingNew" == " 1" ]]'

  costshare__vendor_pct_name_encoding_ordering lenEncodingNew 5 $lenEncodingNew
  assert_true '[[ "$lenEncodingNew" == " 5 1" ]]'

  costshare__vendor_pct_name_encoding_ordering lenEncodingNew 4 $lenEncodingNew
  assert_true '[[ "$lenEncodingNew" == " 5 4 1" ]]'

  costshare__vendor_pct_name_encoding_ordering lenEncodingNew 4 $lenEncodingNew
  assert_true '[[ "$lenEncodingNew" == " 5 4 1" ]]'

  costshare__vendor_pct_name_encoding_ordering lenEncodingNew 6 $lenEncodingNew
  assert_true '[[ "$lenEncodingNew" == " 6 5 4 1" ]]'

  costshare__vendor_pct_name_encoding_ordering lenEncodingNew 3 $lenEncodingNew
  assert_true '[[ "$lenEncodingNew" == " 6 5 4 3 1" ]]'
}


test_costshare__vendor_name_length_map(){

  assert_output_true \
    echo "'"'([Root1]=" 13" [Root2]=" 14" [Root3]=" 15" [Root4]=" 14" [Root5]=" 32" [Root6]=" 66" )'"'" \
    --- \
    test_costshare_pipe
}
test_costshare_vendor_pct_tbl_vendor_name_length_map(){
cat <<'test_costshare_vendor_pct_tbl_vendor_name_length_map'
Root1 !Vendor,20
Root2 Ve**ndor,30
Root2 Ve++ndor,30
Root3 Ven$$$dor,40
Root4 Ven[dor],40
Root5 Vendor part1 part2 part3 4,50
Root6 ~ ! # $ % ^ & ( ) _ - + = ] [ | \ " ' | ? . / < > $s * : end,60
test_costshare_vendor_pct_tbl_vendor_name_length_map
}
test_costshare_pipe(){
  test_costshare_vendor_pct_tbl_vendor_name_length_map | costshare__vendor_name_length_map
}

test_costshare__vendor_pct_tbl_normalize(){

  assert_true 'echo "field1,field2,field3"
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true test_costshare__vendor_pct_tbl_normalize_fail_regex'

  assert_true 'echo "vendor,101"
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true test_costshare__vendor_pct_tbl_normalize_fail_pct_le_100'

  assert_true 'echo "ve ndor,1"
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true test_costshare__vendor_pct_tbl_normalize_fail_trim_regex'

  assert_true 'test_costshare__vendor_pct_tbl_normalize_fail_vendor_max_len_input
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true test_costshare__vendor_pct_tbl_normalize_fail_vendor_max_len'

}
test_costshare__vendor_pct_tbl_normalize_fail_regex(){
cat<<'error'
Error: fails format check costshare__VENDOR_PCT_TABLE_REGEX='^([^,]+),[[:space:]]*([1-9][0-9]?[0-9]?)[[:space:]]*$'. rowCnt=1 row='field1,field2,field3'
Abort: Rows of costshare_vendor_pct_tbl don't comply with expected format. errorCnt=1
error
}
test_costshare__vendor_pct_tbl_normalize_fail_pct_le_100(){
cat<<'error'
Error: pct=101 must be =< 100'. rowCnt=1 row='vendor,101'
Abort: Rows of costshare_vendor_pct_tbl don't comply with expected format. errorCnt=1
error
}
test_costshare__vendor_pct_tbl_normalize_fail_trim_regex(){
cat<<'error'
Error: vendor name fails costshare__VENDOR_NAME_TRIM_REGEX='^[[:space:]]*([^[:space:]][^[:space:]][^[:space:]]+([[:space:]]+[^[:space:]]+)*)[[:space:]]*$'. rowCnt=1 row='ve ndor,1'
Abort: Rows of costshare_vendor_pct_tbl don't comply with expected format. errorCnt=1
error
}
test_costshare__vendor_pct_tbl_normalize_fail_vendor_max_len_input(){
cat<<'input'
012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567,1
input
}
test_costshare__vendor_pct_tbl_normalize_fail_vendor_max_len(){
cat<<'error'
Error: vendor name exceeds costshare_VENDOR_NAME_LENGTH_MAX=256. Either override length or truncate vendor name. rowCnt=1 row='012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567,1'
Abort: Rows of costshare_vendor_pct_tbl don't comply with expected format. errorCnt=1
error
}

test_costshare__purchase_stream_normalize(){
  assert_true '
    echo "fails, regex"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true test_costshare__purchase_stream_normalize_fail_REGEX'
  assert_true '
    test_costshare__purchase_stream_normalize_fail_vendor_max_len_input 
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true test_costshare__purchase_stream_normalize_fail_vendor_max_len'
  assert_true '
    echo "10/10,Vendor Name,01.99"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true test_costshare__purchase_stream_normalize_fail_leading_zero'
  assert_true '
    echo "10/10,Vendor Name,0.99"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true echo "10/10,Vendor Name,0.99"'
  assert_true '
    echo "10/10,Vendor Name,-0.99"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true echo "10/10,Vendor Name,-0.99"'
  assert_true '
    echo "10/10,Vendor Name,-.99"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true test_costshare__purchase_stream_normalize_fail_no_leading_zero'
  assert_true '
    echo "10/10,   Vendor   Name   ,100"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true echo "10/10,Vendor Name,100"'
  assert_true '
    echo "10/10/20,   Vendor   Name   ,100.00"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true echo "10/10/20,Vendor Name,100.00"'
  assert_true '
    echo "10/10/20,   Vendor   Name   ,100.00,forwarded fields"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true echo "10/10/20,Vendor Name,100.00,forwarded fields"'
  assert_true '
    echo "10/10/2022,Vendor   123  Name,100.00forwarded fields,f2"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true echo "10/10/2022,Vendor 123 Name,100.00forwarded fields,f2"'
}
test_costshare__purchase_stream_normalize_fail_REGEX(){
cat<<'error'
Error: failed to match expected format.  costshare__PURCHASE_DATA_FORMAT_REGEX='^([0-1][0-9]/[0-3][0-9](/[0-9][0-9]([0-9][0-9])?)?),([^,]+),([-]?[0-9]+(\.[0-9][0-9])?)(.*)$'. purchaseCnt=0 purchase='fails, regex'
Abort: Purchase entry(s) from purchase stream do not comply with expected format. errorCnt=1
error
}
test_costshare__purchase_stream_normalize_fail_vendor_max_len_input(){
cat<<'input'
10/10,012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567,100.00
input
}
test_costshare__purchase_stream_normalize_fail_vendor_max_len(){
cat<<'error'
Error: vendor name exceeds costshare_VENDOR_NAME_LENGTH_MAX=256. Either override length or truncate vendor name. purchaseCnt=0 purchase='10/10,012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567,100.00'
Abort: Purchase entry(s) from purchase stream do not comply with expected format. errorCnt=1
error
}
test_costshare__purchase_stream_normalize_fail_leading_zero(){
cat<<'error'
Error: Charges cannot start with '0' when charge/refund greater than 0.99.. purchaseCnt=0 purchase='10/10,Vendor Name,01.99'
Abort: Purchase entry(s) from purchase stream do not comply with expected format. errorCnt=1
error
}
test_costshare__purchase_stream_normalize_fail_no_leading_zero(){
cat<<'error'
Error: failed to match expected format.  costshare__PURCHASE_DATA_FORMAT_REGEX='^([0-1][0-9]/[0-3][0-9](/[0-9][0-9]([0-9][0-9])?)?),([^,]+),([-]?[0-9]+(\.[0-9][0-9])?)(.*)$'. purchaseCnt=0 purchase='10/10,Vendor Name,-.99'
Abort: Purchase entry(s) from purchase stream do not comply with expected format. errorCnt=1
error
}


test_costshare__charge_share_pct_get(){

  test_costshare__charge_share_pct_vendor_tbl
  eval local \-\A \-\r vendorPCT=$(costshare__vendor_pct_map_create)
  eval local \-\A \-\r vendorNameLen=$(costshare__vendor_name_length_map_create)
  local -i partyXpct=0
  costshare__charge_share_pct_get vendorPCT "${vendorNameLen[BJS]}" 'BJS Warehouse' partyXpct
  assert_true '[[ $partyXpct -eq 20 ]]'
  partyXpct=0
  costshare__charge_share_pct_get vendorPCT "${vendorNameLen[BJS]}" 'BJS Gas' partyXpct
  assert_true '[[ $partyXpct -eq 50 ]]'
  partyXpct=0
  costshare__charge_share_pct_get vendorPCT "${vendorNameLen[BJS]}" 'BJS GasWarehouse' partyXpct
  assert_true '[[ $partyXpct -eq 50 ]]'
  partyXpct=0
  costshare__charge_share_pct_get vendorPCT "${vendorNameLen[BJS]}" '110 Grill' partyXpct
  assert_true '[[ $partyXpct -eq 29 ]]'
  partyXpct=0
  assert_output_true \
    echo 'Abort: Failed to find vendorName='"'110 Grill DC'"' in vendor_pct_table.' \
    --- \
    costshare__charge_share_pct_get vendorPCT "${vendorNameLen[BJS]}" '110 Grill DC' partyXpct
}
test_costshare__charge_share_pct_vendor_tbl(){
costshare_vendor_pct_tbl(){
cat <<'costshare_vendor_pct_tbl'
BJS Warehouse, 20
BJS Gas      , 50
110 Grill    , 29
costshare_vendor_pct_tbl
}
}


test_costshare__charge_share_compute(){
  test_costshare__charge_share_compute_vendor_pct_tbl
  assert_true '
    echo "fail,regex,"
    | costshare__charge_share_compute 2>&1
    | assert_output_true test_costshare__charge_share_compute_fail_Regex'
  assert_true '
    echo "10/10,fail vendor name,50.95"
    | costshare__charge_share_compute 2>&1
    | assert_output_true test_costshare__charge_share_compute_fail_vendor_name'
  assert_true '
    echo "10/10,BJS PARTYX,35.35"
    | costshare__charge_share_compute 2>&1
    | assert_output_true echo "10/10,BJS PARTYX,35.35,100,35.35,0.00"'
  assert_true '
    echo "10/10,BJS Warehouse,33.34"
    | costshare__charge_share_compute 2>&1
    | assert_output_true echo "10/10,BJS Warehouse,33.34,20,6.67,26.67"'
  assert_true '
    echo "10/10,BJS fail,33.34"
    | costshare__charge_share_compute 2>&1
    | assert_output_true echo "Abort: Failed to find vendorName="'"\'BJS fail\'"'" in vendor_pct_table."'
  assert_true '
    echo "10/10,BJS Warehouse,33.34ForwardedFields"
    | costshare__charge_share_compute 2>&1
    | assert_output_true echo "10/10,BJS Warehouse,33.34,20,6.67,26.67ForwardedFields"'
  assert_true '
    echo "10/10,BJS Warehouse,33.34,ForwardedFields"
    | costshare__charge_share_compute 2>&1
    | assert_output_true echo "10/10,BJS Warehouse,33.34,20,6.67,26.67,ForwardedFields"'
  assert_true '
    echo "10/10,BJS Warehouse,-33.34,ForwardedFields"
    | costshare__charge_share_compute 2>&1
    | assert_output_true echo "10/10,BJS Warehouse,-33.34,20,-6.67,-26.67,ForwardedFields"'
}
test_costshare__charge_share_compute_vendor_pct_tbl(){
costshare_vendor_pct_tbl(){
cat <<'costshare_vendor_pct_tbl'
BJS Warehouse, 20
BJS Gas      , 50
110 Grill    , 29
BJS PARTYX   , 100
costshare_vendor_pct_tbl
}
}
test_costshare__charge_share_compute_fail_Regex(){
cat <<'error'
Abort: Purchase data fails costshare__PURCHASE_DATA_FORMAT_REGEX='^([0-1][0-9]/[0-3][0-9](/[0-9][0-9]([0-9][0-9])?)?),([^,]+),([-]?[0-9]+(\.[0-9][0-9])?)(.*)$'purchase='fail,regex,'
error
}
test_costshare__charge_share_compute_fail_vendor_name(){
cat <<'error'
Abort: Could not determine vendorSubtypeLens for vendorRoot='fail'
error
}

main(){
  compose_executable "$0"

  test_costshare__error_msg
  test_costshare__embedded_whitespace_replace
  test_costshare_vendor_pct_tbl_normalize
  test_costshare__purchase_REGEX
  test_costshare__vendor_pct_map_create
  test_costshare__vendor_pct_name_encoding_ordering
  test_costshare__vendor_name_length_map
  test_costshare__vendor_pct_tbl_normalize
  test_costshare__purchase_stream_normalize
  test_costshare__charge_share_pct_get
  test_costshare__charge_share_compute

  assert_return_code_set
}

main

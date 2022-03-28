#!/bin/bash
compose_executable(){
  local -r callFromDir="$( dirname "$1" )"

  local -r callSourcer="$callFromDir"'/config_sh/vendor/sourcer/sourcer.sh'
  local -r myRoot="$callFromDir"'/costshare_source_test_sh'
  local mod
  for mod in $( "$callSourcer" "$myRoot"); do
    source "$mod"
  done
}


test_costshare_vendor_pct_tbl(){

  assert_output_true \
    echo "Abort: Override the costshare_vendor_pct_tbl to provide the table of vendors and Party 'X' percentage." \
    --- \
    costshare_vendor_pct_tbl
}


test_costshare_purchase_exclude_filter_tbl(){

  assert_output_true \
    test_costshare_purchase_exclude_filter_tbl_fatal_ovrride \
    --- \
    costshare_purchase_exclude_filter_tbl
}
test_costshare_purchase_exclude_filter_tbl_fatal_ovrride(){
cat <<'fatal_ovrride'
Abort: override this function to exclude certain purchase transactions.
fatal_ovrride
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


test_costshare__vendor_pct_tbl_norm_stream(){

  test_costshare_vendor_pct_tbl_names_with_whitespace_special_characters
  assert_output_true \
    test_costshare_vendor_pct_tbl_expected \
    --- \
    costshare__vendor_pct_tbl_norm_stream

}
test_costshare_vendor_pct_tbl_names_with_whitespace_special_characters(){
costshare_vendor_pct_tbl(){
cat <<'costshare_vendor_pct_tbl'
   Root1 Vendor,  20
Root2 Vendor,30
Root3   Vendor {},40
Root4		Vendor,40
Root5		Vendor    part1 part2  part3 4,50
"Root6 ~ ! # $ % ^ & ( ) _ - + = ] [ | \ "" ' | ? . / < > $s * : end",60
costshare_vendor_pct_tbl
}
test_costshare_vendor_pct_tbl_expected(){
cat <<'costshare_vendor_pct_tbl_result'
Root1 Vendor,20
Root2 Vendor,30
Root3 Vendor {},40
Root4 Vendor,40
Root5 Vendor part1 part2 part3 4,50
"Root6 ~ ! # $ % ^ & ( ) _ - + = ] [ | \ "" ' | ? . / < > $s * : end",60
costshare_vendor_pct_tbl_result
}
}

test_costshare__purchase_REGEX(){

# MM/DD
  assert_true '[[ 10/10 =~ $costshare__PURCHASE_DATE_REGEX ]]'

# MM/DD/YY
  assert_true '[[ 01/10/22 =~ $costshare__PURCHASE_DATE_REGEX ]]'

# MM/DD/YYYY
  assert_true '[[ 01/10/2022 =~ $costshare__PURCHASE_DATE_REGEX ]]'

# bad date
  assert_false '[[ 01-10 =~ $costshare__PURCHASE_DATE_REGEX ]]'

# whole number charge
  assert_true '[[ 100 =~ $costshare__PURCHASE_CHARGE_REGEX ]]'

# negative whole number charge(refund)
  assert_true '[[ -100 =~ $costshare__PURCHASE_CHARGE_REGEX ]]'

# decimal number charge < $1
  assert_true '[[ 0.95 =~ $costshare__PURCHASE_CHARGE_REGEX ]]'

# decimal number charge > $1
  assert_true '[[ 100.65 =~ $costshare__PURCHASE_CHARGE_REGEX ]]'

# negative decimal number charge
  assert_true '[[ -0.95 =~ $costshare__PURCHASE_CHARGE_REGEX ]]'
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

  costshare__embedded_whitespace_replace '		,a  b' result
  assert_true '[[ "$result" == " ,a b" ]]'

  costshare__embedded_whitespace_replace 'a,  b' result
  assert_true '[[ "$result" == "a, b" ]]'

}

test_costshare__vendor_pct_map_create(){
  costshare_vendor_pct_tbl(){
    echo 1Root Vendor,20
    echo 2Root Vendor,30
  }
  eval local \-A vendorMap\=$( costshare__vendor_pct_map_create )
  assert_true '[[ "${vendorMap["1Root Vendor"]}" == "20" ]]'
  assert_true '[[ "${vendorMap["2Root Vendor"]}" == "30" ]]'
  assert_true '[[ ${#vendorMap[@]} -eq 2 ]]'
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

  eval local \-A nameLenMap\=$( test_costshare_vendor_pct_tbl_vendor_name_length_map | costshare__vendor_name_length_map )
  assert_true '[[ "${nameLenMap[Root1]}" == " 13" ]]'
  assert_true '[[ "${nameLenMap[Root2]}" == " 14" ]]'
  assert_true '[[ "${nameLenMap[Root3]}" == " 15" ]]'
  assert_true '[[ "${nameLenMap[Root4]}" == " 14" ]]'
  assert_true '[[ "${nameLenMap[Root5]}" == " 32" ]]'
  assert_true '[[ "${nameLenMap[Root6]}" == " 66" ]]'

  assert_true '[[ ${#nameLenMap[@]} -eq 6 ]]' 

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


test_costshare__vendor_pct_tbl_normalize(){

  assert_true 'echo "field1,field2,field3"
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true test_costshare__vendor_pct_tbl_normalize_invalid_pct_regex'

  assert_true 'echo "vendor,101"
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true test_costshare__vendor_pct_tbl_normalize_fail_pct_le_100'

  assert_true 'echo "v,1"
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true echo "v,1"'

  assert_true 'echo "v      endor,1"
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true echo "v endor,1"'

  assert_true 'echo "ve ndor,1"
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true echo "ve ndor,1"'

  assert_true 'echo "   ve n'\''     dor  ,1"
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true echo "ve n'\'' dor,1"'

  assert_true 'test_costshare__vendor_pct_tbl_normalize_fail_vendor_max_len_input
   | costshare__vendor_pct_tbl_normalize 2>&1
   | assert_output_true test_costshare__vendor_pct_tbl_normalize_fail_vendor_max_len'

}
test_costshare__vendor_pct_tbl_normalize_invalid_pct_regex(){
cat<<'error'
Error: invalid percentage format  costshare__PCT_TABLE_REGEX='^[[:space:]]*([1-9][0-9]?[0-9]?)[[:space:]]*$'. rowCnt=1 row='field1,field2,field3'
Abort: Rows of costshare_vendor_pct_tbl don't comply with expected format. errorCnt=1
error
}
test_costshare__vendor_pct_tbl_normalize_fail_pct_le_100(){
cat<<'error'
Error: pct=101 must be =< 100'. rowCnt=1 row='vendor,101'
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


test_costshare__purchase_exclude_filter_regex_create(){

  assert_output_true \
    test_costshare__purchase_exclude_filter_regex_create_override_error  \
    --- \
    costshare_purchase_exclude_filter_tbl
 
  assert_true '
    echo ",Date,Amt"
    | costshare__purchase_exclude_filter_regex_create 2>&1
    | assert_output_true test_costshare__purchase_exclude_filter_regex_create_vendor_name_excluded'

  assert_true '
    echo '"'"'BJS $$.*'"'"'
    | costshare__purchase_exclude_filter_regex_create 2>&1
    | assert_output_true test_costshare__purchase_exclude_filter_regex_create_vendor_name_regex'

  assert_true '
    echo '"'"'BJS .*,10/[[:digit:]]?,'"'"'
    | costshare__purchase_exclude_filter_regex_create 2>&1
    | assert_output_true test_costshare__purchase_exclude_filter_regex_create_vendor_name_date_regex'

  assert_true '
    echo '"'"'BJS .*,10/[[:digit:]]?,100\.00'"'"'
    | costshare__purchase_exclude_filter_regex_create 2>&1
    | assert_output_true test_costshare__purchase_exclude_filter_regex_create_vendor_name_date_amt_regex'

  assert_true '
    test_costshare__purchase_exclude_filter_regex_create_multi_rows
    | costshare__purchase_exclude_filter_regex_create 2>&1
    | assert_output_true test_costshare__purchase_exclude_filter_regex_create_multi_rows_expected'
}
test_costshare__purchase_exclude_filter_regex_create_override_error(){
  cat <<'override_error'
Abort: override this function to exclude certain purchase transactions.
override_error
}
test_costshare__purchase_exclude_filter_regex_create_vendor_name_excluded(){
cat <<'vendor_name_excluded'
^Date,(([^,"]+)|(["](([^"]|(""))*)["])),Amt
vendor_name_excluded
}
test_costshare__purchase_exclude_filter_regex_create_vendor_name_regex(){
cat <<'vendor_name_regex'
^(([^,"]+)|(["](([^"]|(""))*)["])),BJS $$.*,(([^,"]+)|(["](([^"]|(""))*)["]))
vendor_name_regex
}
test_costshare__purchase_exclude_filter_regex_create_vendor_name_date_regex(){
cat <<'vendor_name_date_regex'
^10/[[:digit:]]?,BJS .*,(([^,"]+)|(["](([^"]|(""))*)["]))
vendor_name_date_regex
}
test_costshare__purchase_exclude_filter_regex_create_vendor_name_date_amt_regex(){
cat <<'vendor_name_date_amt_regex'
^10/[[:digit:]]?,BJS .*,100\.00
vendor_name_date_amt_regex
}
test_costshare__purchase_exclude_filter_regex_create_multi_rows(){
cat <<'multi_rows'
,Date,Amt
BJS $$.*
BJS .*,10/[[:digit:]]?,
BJS .*,10/[[:digit:]]?,100\.00
multi_rows
}
test_costshare__purchase_exclude_filter_regex_create_multi_rows_expected(){
cat <<'multi_rows'
^Date,(([^,"]+)|(["](([^"]|(""))*)["])),Amt|^(([^,"]+)|(["](([^"]|(""))*)["])),BJS $$.*,(([^,"]+)|(["](([^"]|(""))*)["]))|^10/[[:digit:]]?,BJS .*,(([^,"]+)|(["](([^"]|(""))*)["]))|^10/[[:digit:]]?,BJS .*,100\.00
multi_rows
}


test_costshare__purchase_exclude_filter_regex_apply(){

  local filter="$( echo "BJS.*","","" | costshare__purchase_exclude_filter_regex_create )"
  local filterExpect='^(([^,"]+)|(["](([^"]|(""))*)["])),BJS.*,(([^,"]+)|(["](([^"]|(""))*)["]))'
  assert_true '[[ "$filter" == "$filterExpect" ]]'
  assert_true '
    test_costshare__purchase_exclude_filter_regex_apply_exclude_all_BJS
    | grep -E -v "$filter" 2>&1
    | assert_output_true echo "10/10,110 Grill,100.00"'

  local filter="$( echo "","10/10","" | costshare__purchase_exclude_filter_regex_create )"
  local filterExpect='^10/10,(([^,"]+)|(["](([^"]|(""))*)["])),(([^,"]+)|(["](([^"]|(""))*)["]))'
  assert_true '[[ "$filter" == "$filterExpect" ]]'
  assert_true '
    test_costshare__purchase_exclude_filter_regex_apply_exclude_by_date
    | grep -E -v "$filter" 2>&1
    | assert_output_true echo "10/11,BJS Wholesale,50.00"'

  local filter="$( echo '"BJS.*","10/10","100\.00"' | costshare__purchase_exclude_filter_regex_create )"
  assert_true '[[ "$filter" == '\''^10/10,BJS.*,100\.00'\'' ]]'
  assert_true '
    test_costshare__purchase_exclude_filter_regex_apply_exclude_BJS_10_10_100Dollars
    | grep -E -v "$filter" 2>&1
    | assert_output_true test_costshare__purchase_exclude_filter_regex_apply_exclude_BJS_10_10_100Dollars_expected'

}
test_costshare__purchase_exclude_filter_regex_apply_exclude_all_BJS(){
cat<<'exclude_all_BJS'
10/10,BJS Gas,100.00
10/10,110 Grill,100.00
10/11,BJS Wholesale,50.00
10/12,BJS Wholesale,51.00
exclude_all_BJS
}
test_costshare__purchase_exclude_filter_regex_apply_exclude_by_date(){
cat<<'exclude_by_date'
10/10,BJS Gas,100.00
10/10,110 Grill,100.00
10/11,BJS Wholesale,50.00
10/10,BJS Wholesale,51.00
exclude_by_date
}
test_costshare__purchase_exclude_filter_regex_apply_exclude_by_amt(){
cat<<'exclude_by_amt'
10/10,BJS Gas,100.00
10/10,110 Grill,100.00
10/11,BJS Wholesale,50.00
10/10,BJS Wholesale,51.00
exclude_by_amt
}
test_costshare__purchase_exclude_filter_regex_apply_exclude_BJS_10_10_100Dollars(){
cat<<'exclude_by_amt'
10/10,BJS Gas,100.00
10/10,110 Grill,100.00
10/11,BJS Wholesale,50.00
10/10,BJS Wholesale,51.00
exclude_by_amt
}
test_costshare__purchase_exclude_filter_regex_apply_exclude_BJS_10_10_100Dollars_expected(){
cat<<'exclude_BJS_10_10_100Dollars_expected'
10/10,110 Grill,100.00
10/11,BJS Wholesale,50.00
10/10,BJS Wholesale,51.00
exclude_BJS_10_10_100Dollars_expected
}


test_costshare__purchase_stream_normalize(){
  assert_true '
    echo "date, missing"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true test_costshare__purchase_stream_normalize_date_missing_regex'
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
    echo "10/10/2022,Vendor   123  Name,100.00,forwarded fields"",f2"
    | costshare__purchase_stream_normalize 2>&1
    | assert_output_true echo "10/10/2022,Vendor 123 Name,100.00,forwarded fields"",f2"'
}
test_costshare__purchase_stream_normalize_date_missing_regex(){
cat<<'error'
Error: required field: purchaseDate, vendor name, and/or charge notspecified.. purchaseCnt=0 purchase='date, missing'
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
Error: charge amount does not match expected format.  costshare__PURCHASE_CHARGE_REGEX='(^[-]?[0-9]+(\.[0-9][0-9])?)'. purchaseCnt=0 purchase='10/10,Vendor Name,-.99'
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
    echo "10/10,BJS Warehouse,33.34,ForwardedFields"
    | costshare__charge_share_compute 2>&1
    | assert_output_true echo "10/10,BJS Warehouse,33.34,20,6.67,26.67,ForwardedFields"'
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


test_costshare_charge_share_run(){


  costshare_purchase_exclude_filter_tbl(){
    #vendorNameRegex,dateRegex,amtRegex
    #define empty filter for test
    return
  }

  test_costshare_charge_share_run_vendor_pct_tbl
  assert_true '
    echo "10/10,BJS Warehouse,-33.34,ForwardedFields"
    | costshare_charge_share_run 2>&1
    | assert_output_true echo "10/10,BJS Warehouse,-33.34,20,-6.67,-26.67,ForwardedFields"'

  assert_true '
    echo "10/10,BJS Ware[house,-33.34,ForwardedFields"
    | costshare_charge_share_run 2>&1
    | assert_output_false echo'

  assert_true '
    echo "10/10,\"BJS Warehouse\",-80.00"
    | costshare_charge_share_run 2>&1
    | assert_output_true echo "10/10,BJS Warehouse,-80.00,20,-16.00,-64.00"'

  assert_true '
    echo "10/10,\"BJS Warehouse\"\"\",-80.00"
    | costshare_charge_share_run 2>&1
    | assert_output_true echo "10/10,\"BJS Warehouse\"\"\",-80.00,20,-16.00,-64.00"'
}
test_costshare_charge_share_run_vendor_pct_tbl(){
costshare_vendor_pct_tbl(){
cat <<'costshare_vendor_pct_tbl'
BJS Warehouse, 20
BJS Gas      , 50
110 Grill    , 29
BJS PARTYX   , 100
costshare_vendor_pct_tbl
}
}


test_costshare__vendor_fixed_filter(){
  test_costshare__vendor_fixed_filter_vendor_pct_tbl
  assert_output_true \
    test_costshare__vendor_fixed_filter_good \
    --- \
    costshare__vendor_fixed_filter
}
test_costshare__vendor_fixed_filter_vendor_pct_tbl(){
costshare_vendor_pct_tbl(){
cat <<'costshare_vendor_pct_tbl'
BJS x        , 10
BJS Warehouse, 20
BJS G.a?+s   , 50
110 Grill    , 29
BJS PARTYX   , 100
costshare_vendor_pct_tbl
}
}
test_costshare__vendor_fixed_filter_good(){
cat<<'fixedfilter'
BJS x
BJS Warehouse
BJS G.a?+s
110 Grill
BJS PARTYX
DoesNotMatchAnyVendor
fixedfilter
}


main(){
  compose_executable "$0"

  # test_costshare_vendor_pct_tbl should always be after
  # compose because it tests default behavior.  the
  # default is overriden by the other tests.
  test_costshare_vendor_pct_tbl
  # test_costshare_purchase_exclude_filter_tbl should always
  # run before any other test that overrides its 
  # default behavior.
  test_costshare_purchase_exclude_filter_tbl

  test_costshare__error_msg
  test_costshare__embedded_whitespace_replace
  test_costshare__vendor_pct_tbl_norm_stream
  test_costshare__purchase_REGEX
  test_costshare__vendor_pct_map_create
  test_costshare__vendor_pct_name_encoding_ordering
  test_costshare__vendor_name_length_map
  test_costshare__vendor_pct_tbl_normalize
  test_costshare__purchase_exclude_filter_regex_create
  test_costshare__purchase_exclude_filter_regex_apply
  test_costshare__purchase_stream_normalize
  test_costshare__charge_share_pct_get
  test_costshare__charge_share_compute
  test_costshare_charge_share_run
  test_costshare__vendor_fixed_filter
 
  assert_return_code_set
}

main

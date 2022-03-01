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
  assert_output_true
    costshare_vendor_pct_tbl_expected \
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
# * $ not valid
}
costshare_vendor_pct_tbl_expected(){
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
  assert_output_true test_costshare__vendor_pct_map_create_output_1 --- costshare__vendor_pct_map_create
}
test_costshare__vendor_pct_map_create_output_1(){
cat <<test_costshare__vendor_pct_map_create_output_1
(
["1Root Vendor"]="20"
["2Root Vendor"]="30"
)
test_costshare__vendor_pct_map_create_output_1
}

main(){
  compose_executable "$0"
  test_costshare__error_msg
  test_costshare__embedded_whitespace_replace
  test_costshare__purchase_REGEX
  test_costshare_vendor_pct_tbl_normalize

  assert_return_code_set
return
  test_costshare__vendor_pct_map_create
}

main

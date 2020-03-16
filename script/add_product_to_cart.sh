#!/usr/bin/env bash

########################################################################################################################
###################################### Magento Automation script #######################################################
# Usage: magRester -u <Magento User> -p <Magento password> -f <SKU List input File>  -o <Outfile> -l <Magento host> ####
# V 0.0.1 ##############################################################################################################
# Author: Deep Kamal Singh #############################################################################################
########################################################################################################################

M_API="http://dks.magento/m2nodat/rest/V1/carts/mine/items";
M_API_TOKEN="g4ioh3ukh3igt0fenxfelpvxdyxpw863";
M_CART_ID=33;

which curl > /dev/null;
curlExist=`echo $?`;
if [ "$curlExist" = 0 ];then
    echo "curl available on system, attempting reading infile";
else
    echo "curl does not exists, cant curl,exiting"; exit 1;
fi;

while getopts "u:p:f:o:l:" opt; do
  case ${opt} in
    u ) user=$OPTARG;;
    p ) pass=$OPTARG;;
    f ) infile=$OPTARG;;
    o ) outfile=$OPTARG;;
    l ) url=$OPTARG;;
    \? )
      echo "Usage: \n\tmagRester -u <Magento User> -p <Magento password> -f <SKU List input File>  -o <Outfile> -l <Magento host>"; break;
      ;;
    : )
      echo "Invalid option: ${opt} requires an argument" 1>&2; break;
      ;;
  esac
done

obtainMagentoToken(){

    api_endpoint=${1}"integration/customer/token";
    echo "Obtaining token from ${api_endpoint} with username ${2} and password ${3}";
    M_API_TOKEN=(`curl -k --location --request POST ${api_endpoint} --header "Content-Type: application/json" --data-raw "{\"username\": \"${2}\",\"password\": \"${3}\"}"`);

    M_API_TOKEN=${M_API_TOKEN#\"};
    M_API_TOKEN=${M_API_TOKEN%\"};

    echo "Token Obtained::"$M_API_TOKEN;

}

obtainMagentoCart(){
    api_endpoint=${1}"carts/mine";
#    echo "Token here is "${M_API_TOKEN};
#    echo "curl -k -s --location --request POST '${api_endpoint}' --header 'Content-Type: application/json' --header 'Authorization: Bearer ${M_API_TOKEN}'";
    M_CART_ID=(`curl -s -k --location --request POST ${api_endpoint} --header "Content-Type: application/json" --header "Authorization: Bearer ${M_API_TOKEN}"`);
#    echo "Cart ID here is "${M_CART_ID};

}
addItemToCart() {

    api_endpoint=${4}"carts/mine/items";

    dt=`date +"%Y%m%d%H%M%s"`;
    op=`curl -k -s --output /dev/null \
    -w "${dt},${3},%{http_code}, %{time_redirect}, %{time_namelookup}, %{time_connect}, %{time_appconnect}, %{time_pretransfer},%{time_starttransfer}, %{time_total}, %{size_request}, %{size_upload},%{size_download},%{size_header}" \
    --location --request POST ${api_endpoint}  \
    --header "Content-Type: application/json"  \
    --header "Authorization: Bearer ${M_API_TOKEN}"  \
    --data-raw "${1}"`
    echo "${op}" >> $2;
#    echo "" >> ${2};


}

prepareDataAndAddToCart(){
#'{"cartItem":{"sku": "f-shb-01","qty": 1,"quote_id": 17}}'
    echo "Working for "${1};
    addItemToCart "{\"cartItem\":{\"sku\": \"${1}\",\"qty\": 1,\"quote_id\": ${2} }}" ${3} ${1} ${4};
}

if [ -z "$user" ]; then
    echo "User identity not provided, will use admin:admin for auth";
    pass="admin";
    user="admin";
fi;
if [ -z "$url" ]; then
    echo "AEM upload URL not provided in argument, exiting";
    echo "Usage: \n\tmagRester -u <Magento User> -p <Magento password> -f <SKU List input File>  -o <Outfile> -l <Magento host>"; break;
    exit 1;
fi;
#check if file opts is provided, if not check if dir opts is provided, else exit
if [ -z "$infile" ]; then
    echo "In File not provided in argument, nothing to do, exiting...";exit 0;
elif [ -r "$infile" ]; then
    echo "In File '${infile}' exists and is readable, processing further";
    echo "Found total  "`wc -l ${infile}|awk '{print $1}'`" lines in file, assuming all SKUs";
    obtainMagentoToken $url $user $pass;
    obtainMagentoCart $url;
    echo "Obtained cart ID ::"${M_CART_ID};

    for i in `cat ${infile}|awk '{print $1}'|sed 's/ //g'`; do prepareDataAndAddToCart $i ${M_CART_ID} ${outfile} ${url}; done;

else
    echo "In File '${infile}' does not exists or its not readable";exit 1;
fi;

exit 0;

#echo "Obtained User::"$user;
#echo "Obtained Pass::"$pass;
#echo "Obtained URL::"$url;
#obtainMagentoToken $url $user $pass
#curl -s --output /dev/null     -w '%{time_redirect}, %{time_namelookup}, %{time_connect}, %{time_appconnect}, %{time_pretransfer},%{time_starttransfer}, %{time_total}, %{size_request}, %{size_upload},%{size_download},%{size_header}'     --location --request POST http://dks.magento/m2nodat/rest/V1/carts/mine/items      --header 'Content-Type: application/json'      --header 'Authorization: Bearer g4ioh3ukh3igt0fenxfelpvxdyxpw863'      --data-raw '{"cartItem":{"sku": "WT06-XL-Blue","qty": 1,"quote_id": 22 }}' >> results.txt

#! /bin/bash

print_help() {
    echo Usage:
    echo -e "  get-s3-bucket-objects bucket|help [aws-profile]"
    exit $1
}

if [ "$#" -eq 0 ] || [ "$1" == "help" ]; then
    print_help 0
elif [[ ! -z "$2" ]]; then
    _profile="--profile $2"
fi

_bucket="$1"
_objects_file="/tmp/s3_bucket_objects.txt"
_sorted_objects_file="/tmp/sorted_s3_bucket_objects.txt"

echo -n > $_objects_file
echo -n > $_sorted_objects_file

# get all objects within the s3 bucket. saved to 
echo "Gathering Objects"
aws s3api list-objects --bucket $_bucket --query 'Contents[].{Key: Key, Size: Size,Class:StorageClass,LastModified:LastModified}' --no-cli-pager --output text  > $_objects_file
sort -k1 -k3 $_objects_file > $_sorted_objects_file

#remove files
rm -rf $_objects_file

echo "results located in $_sorted_objects_file"
cat $_sorted_objects_file

exit 0
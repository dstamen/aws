#! /bin/bash
_regional_instances_file="/tmp/instances.txt"
_sorted_regional_instances_file="/tmp/sorted-instances.txt"
_regional_vpcs_subnets_file="/tmp/instances-vpc-subnet.txt"
_regional_ebs_volumes_file="/tmp/ebs-volume-details.txt"
echo -n > $_regional_instances_file
echo -n > $_sorted_regional_instances_file
echo -n > $_regional_vpcs_subnets_file
echo -n > $_regional_ebs_volumes_file

# get all instance ids, their AZ, volumes and volume sizes saved to /tmp/instances-$_region.txt
echo "Gathering Volumes"
for REGION in $(aws ec2 describe-regions --output text --query 'Regions[].[RegionName]') ; do aws ec2 describe-volumes --filter Name=attachment.status,Values=attached --query 'Volumes[*].{VolumeID:VolumeId,Size:Size,Type:VolumeType,Iops:Iops,AvailabilityZone:AvailabilityZone,State:State,Device:Attachments[0].Device,InstanceId:Attachments[0].InstanceId}' $_profile --region $REGION --output text --no-cli-pager >> $_regional_instances_file;done
sort --reverse $_regional_instances_file > $_sorted_regional_instances_file

# put all the instance ids into a string variable
aws_instances="$(cat $_sorted_regional_instances_file | grep -Ev "None" | cut -f 3)"
aws_instances_region="$(cat $_sorted_regional_instances_file | grep -Ev "None" | cut -f 1 | sed 's/.$//')"

# convert the string variable to an array
aws_instances_array=($aws_instances)
aws_instances_region_array=($aws_instances_region)

echo "Gathering Instances"
if [ ${#aws_instances_array[@]}  -ne 0 ]; then
    for (( i=0; i<${#aws_instances_array[@]}; i++ ));do aws ec2 describe-instances --instance-ids "${aws_instances_array[$i]}" --output text --query 'Reservations[*].Instances[*].{Type:InstanceType,RootDevice:RootDeviceName}' $_profile --region "${aws_instances_region_array[$i]}" >> $_regional_vpcs_subnets_file; done
fi

# combine the columns from /tmp/instances-$_region.txt and /tmp/instances_vpc_subnet-$_region.txt into /tmp/ebs-volume-details-$_region.txt
paste $_sorted_regional_instances_file $_regional_vpcs_subnets_file > $_regional_ebs_volumes_file

rm -rf $_regional_vpcs_subnets_file $_sorted_regional_instances_file $_regional_instances_file

echo "results located in $_regional_ebs_volumes_file"

exit 0
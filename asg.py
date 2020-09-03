import boto3, json
from datetime import datetime, date
import pytz

launchTemplateID = "lt-054cca151bb72789b"

ec2 = boto3.client("ec2")
autoscaling = boto3.client('autoscaling')

def get_most_recent_ami(tag):
    tag_filter=[
        {
            'Name': 'tag:Name',
            'Values': [
                tag,
            ]
        },
    ]

    response = ec2.describe_images(Filters=tag_filter)
    mostResentDate = datetime.min
    amiID = ""
    for image in response["Images"]:
        creationDate = datetime.strptime(image["CreationDate"], "%Y-%m-%dT%H:%M:%S.%fZ")
        if creationDate > mostResentDate:
            mostResentDate = creationDate
            amiID = image["ImageId"]
    return amiID

def set_desired_capacity(capacity, name, client):
    response = client.set_desired_capacity(
        AutoScalingGroupName=name,
        DesiredCapacity=capacity,
        HonorCooldown=False
    )

    print(json.dumps(response))

def set_scaling_limits(min, max, desired, name, client):
    response = client.update_auto_scaling_group(
        AutoScalingGroupName=name,
        MinSize=min,
        MaxSize=max,
        DesiredCapacity=desired
    )
    print(json.dumps(response))

def set_default_launch_template_version(ltid):
    response = ec2.modify_launch_template(
            LaunchTemplateId=ltid,
            DefaultVersion="$Latest"
        )
    print(response)

def create_launch_template_version(launchTemplateID, imageID):
    response = ec2.create_launch_template_version(
        LaunchTemplateId=launchTemplateID,
        SourceVersion="$Latest",
        VersionDescription="Latest-AMI",
        LaunchTemplateData={
            "ImageId": imageID
        }
    )
    print(response)

amid = get_most_recent_ami("BooksApp")
create_launch_template_version(launchTemplateID, amid)
set_default_launch_template_version(launchTemplateID)







# pipelines
# environments
# security groups
# VPC flow logs
# cloudwatch
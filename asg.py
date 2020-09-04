import boto3, json, time
from datetime import datetime, date
import pytz

# Get refresh ID
# Search by refresh ID

launchTemplateID = "lt-067b01b2082ab60c5"

ec2 = boto3.client("ec2")
autoscaling = boto3.client('autoscaling')

def start_instance_refresh(asgname):
    response = autoscaling.start_instance_refresh(
    AutoScalingGroupName=asgname,
    Strategy='Rolling',
    Preferences={
        'MinHealthyPercentage': 90,
        'InstanceWarmup': 30
    }
)

def get_refresh_data():
    still_running = True
    while still_running:
        still_running = False
        response = autoscaling.describe_instance_refreshes(
            AutoScalingGroupName='bakeDemo',
            MaxRecords=100
        )
        for r in response["InstanceRefreshes"]:
            if r["Status"] != "Successful":
                still_running = True
            print(r["Status"])
        time.sleep(30)


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
set_desired_capacity(10, "bakeDemo", autoscaling)
time.sleep(120)
start_instance_refresh("bakeDemo")
# get_refresh_data()
time.sleep(120)
set_desired_capacity(1, "bakeDemo", autoscaling)







# pipelines
# environments
# security groups
# VPC flow logs
# cloudwatch
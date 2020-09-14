# Image_Bakery
terraform apply devops/infra/  
terraform validate devops/infra/  


packer validate ./devops/packer/packer.json
packer build ./devops/packer/packer.json

python asg.py
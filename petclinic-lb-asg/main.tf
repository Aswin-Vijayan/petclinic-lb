provider "aws" {
  region = "us-west-2"
}

module "lb-asg" {
  source        = "../modules"
  subnets       = ["subnet-058a7514ba8adbb07", "subnet-0dbcd1ac168414927", "subnet-032f5077729435858"]
  ami_id        = "ami-0cb02b6a95a84b6e0"
  instance_type = "t2.medium"
  key_name      = "aswin-key"
  environment   = "dev"
  vpc_id        = "vpc-0a5ca4a92c2e10163"
}
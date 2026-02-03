resource "aws_key_pair" "openvpn" {
  key_name   = "openvpn"
  public_key = file("C:\\Users\\Admin\\Desktop\\REPOS\\keys-aws\\openvpn.pub") #for mac or linux use /
}

resource "aws_instance" "vpn" {
  ami           = local.ami_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.vpn_sg_id]
  subnet_id = local.public_subnet_ids
  key_name =  aws_key_pair.openvpn.key_name # expoting the key local to aws 
  #key_name = "devops" #make sur this key exists in aws
  user_data = file("openvpn.sh")
  tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-openvpn"
    }
  )
}
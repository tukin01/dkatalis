# # Create EC2 Key Pair
# resource "aws_key_pair" "my-key" {
#   key_name   = "es-key"
#   public_key = tls_private_key.my_key.public_key_openssh
# }

# # Generate Private Key
# resource "tls_private_key" "my_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }
# #Create 3 EC2 Instances for ElasticSearch cluster nodes
# # Output Private Key to File
# output "private_key_pem" {
#   value     = tls_private_key.my_key.private_key_pem
#   sensitive = true
# }

resource "aws_instance" "es-node-1" {
  ami             = "ami-007020fd9c84e18c7"
  key_name        = "es-key"
  security_groups = ["default"]
  instance_type   = "t2.medium"
  tags = {
    Name        = "master-1"
    Owner       = "dkatalis"
    Environment = "Prod"
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'Executing commands on master-1'",
      "sudo apt update",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("es-key.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "es-node-2" {
  ami             = "ami-007020fd9c84e18c7"
  key_name        = "es-key"
  security_groups = ["default"]
  instance_type   = "t2.medium"
  tags = {
    Name        = "datanode-1"
    Owner       = "dkatalis"
    Environment = "Prod"
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'Executing commands on es-node-1'",
      "sudo apt update",
      #   "sudo apt install -y nginx",
      #   "sudo systemctl start nginx"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("es-key.pem")
      host        = self.public_ip
    }
  }
}


resource "aws_instance" "es-node-3" {
  ami             = "ami-007020fd9c84e18c7"
  key_name        = "es-key"
  security_groups = ["default"]
  instance_type   = "t2.medium"
  tags = {
    Name        = "datanode-2"
    Owner       = "dkatalis"
    Environment = "Prod"
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'Executing commands on master-1'",
      "sudo apt update",
      #   "sudo apt install -y nginx",
      #   "sudo systemctl start nginx"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("es-key.pem")
      host        = self.public_ip
    }
  }
}

# # Create new load balancer for EC2 ElasticSearch Cluster

resource "aws_elb" "elasticsearch-loadbalancer" {
  name = "lb-es"
  security_groups = ["sg-0abd7b773d2c1a33b"]
  availability_zones = [
    "ap-south-1a",
    "ap-south-1b",
    "ap-south-1c"
  ]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/isALive.json"
    interval            = 30
  }

  instances = [
    "${aws_instance.es-node-1.id}",
    "${aws_instance.es-node-2.id}",
    "${aws_instance.es-node-3.id}"
  ]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}




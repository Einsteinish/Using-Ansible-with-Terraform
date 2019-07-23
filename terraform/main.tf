provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_instance" "myInstanceAWS" {
  count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ami = "${var.ami_id}"
  key_name = "${var.ssh_key_name}"
  subnet_id = "${var.subnet_id}"
  tags {
    Name = "${var.instance_name}"
  }
}

data "template_file" "ansible_vars" {
  template = "${file("${path.root}/ansible_vars.yml.tpl")}"

  vars {
    consul_datacenter         = "${lower(var.datacenter)}"
  }
}

output "consul_datacenter" {
  value = "$${consul_datacenter}"
}

output "datacenter" {
  value = "${lower(var.datacenter)}"
}


resource "null_resource" "ConfigureAnsibleLabelVariable" {
  provisioner "local-exec" {
    command = "echo [${var.dev_host_label}:vars] > hosts"
  }
  provisioner "local-exec" {
    command = "echo ansible_ssh_user=${var.ssh_user_name} >> hosts"
  }
  provisioner "local-exec" {
    command = "echo ansible_ssh_private_key_file=${var.ssh_key_path} >> hosts"
  }
  provisioner "local-exec" {
    command = "echo [${var.dev_host_label}] >> hosts"
  }
}

resource "null_resource" "ProvisionRemoteHostsIpToAnsibleHosts" {
  count = "${var.instance_count}"
  connection {
    type = "ssh"
    user = "${var.ssh_user_name}"
    host = "${element(aws_instance.myInstanceAWS.*.public_ip, count.index)}"
    private_key = "${file("${var.ssh_key_path}")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install python-setuptools python-pip -y",
      "sudo pip install httplib2"
    ]
  }
  provisioner "local-exec" {
    command = "echo ${element(aws_instance.myInstanceAWS.*.public_ip, count.index)} >> hosts"
  }
}

# render temp file containing our ansible variables
resource "local_file" "ansible_vars" {
  content  = "${data.template_file.ansible_vars.rendered}"
  filename = "${path.root}/ansible_vars.yml"
}

resource "null_resource" "ModifyApplyAnsiblePlayBook" {
  provisioner "local-exec" {
    command = "sed -i -e '/hosts:/ s/: .*/: ${var.dev_host_label}/' ../ansible/play.yml"   #change host label in playbook dynamically
  }

  provisioner "local-exec" {
    command = <<EOT
    sleep 10; ansible-playbook -i hosts ../ansible/play.yml \
    --extra-vars @"${local_file.ansible_vars.filename}" 
  EOT
  }
  depends_on = ["null_resource.ProvisionRemoteHostsIpToAnsibleHosts"]
}
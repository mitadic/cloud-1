INVENTORY=inventory.yaml
VENV=.venv
PYTHON=$(VENV)/bin/python
PIP=$(VENV)/bin/pip
ANSIBLE_PLAYBOOK=$(VENV)/bin/ansible-playbook
ANSIBLE=$(VENV)/bin/ansible
PLAYBOOK=$(ANSIBLE_PLAYBOOK) main.yaml -i $(INVENTORY)

all: init aws_sg aws_new_ec2 aws_mount_ebs setup deploy certbot

init:
	test -d $(VENV) || python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install boto3 botocore ansible
	$(VENV)/bin/ansible-galaxy collection install community.docker
	$(VENV)/bin/ansible-galaxy collection install amazon.aws
	echo "Add paired key *.pem"
	-chmod 400 key.pem

aws_sg:
	$(PLAYBOOK) --tags aws_sg

aws_new_ec2:
	$(PLAYBOOK) --tags aws_new_ec2

aws_mount_ebs:
	$(PLAYBOOK) --tags aws_mount_ebs

setup:
	$(PLAYBOOK) --tags setup

deploy:
	$(PLAYBOOK) --tags deploy

clean:
	$(PLAYBOOK) --tags clean

certbot:
	@read -p "Have you updated Route 53 to point to instance1 before continuing? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		$(PLAYBOOK) --tags certbot; \
	else \
		echo "❌ Please update Route 53 DNS first, then run again."; \
	fi

ping:
	$(ANSIBLE) my_ec2_hosts -m ping -i $(INVENTORY)

fclean: clean

re: fclean deploy

.PHONY: all clean fclean re

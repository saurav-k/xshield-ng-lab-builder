# A sample enterprise lab for Xshield

![alt](images/lab-env.png)

This lab consists of EC2 instances deployed using Terraform in any AWS region of your choosing.  It represents two environments with a mix of Ubuntu Linux and Microsoft Windows servers, and also includes three "legacy" systems served by a ColorTokens Gatekeeper appliance.  Built-in traffic generators send HTTP requests to the CRM, HRMS and Wordpress front-ends.  Infrastructure services include a SIEM, a vulnerability scanner, and an Inventory Management system.

Xshield agents are deployed during Terraform-ation, and optional Ansible scripts are also included. The Ansible scripts are useful if you decommision the agents from the Xshield console, and would like to re-install them withot destroying and rebuilding the environment.

You may use your own macOS or Windows system to execute Terraform (and Ansible), or deploy a small Ubuntu server VM.

## Setup the necessary tools

<details>
<summary>Deploy a Boostrap VM</summary>
<p>

The instructions below assume the use of an Ubuntu 22.04 VM (1 vCPU, 4GB RAM should be adequate.)

Before proceeding, let's update the apt repositories.

```
sudo apt update
```
</details>

<details>
<summary>Install saml2aws if required</summary>
<p>

We use multifactor authentication with JumpCloud for AWS CLI access at our organization. The open source **saml2aws** tool makes this easy.  Install this tool using the following steps:

```
mkdir -p ~/.local/bin
CURRENT_VERSION=$(curl -Ls https://api.github.com/repos/Versent/saml2aws/releases/latest | grep 'tag_name' | cut -d'v' -f2 | cut -d'"' -f1)
wget -c https://github.com/Versent/saml2aws/releases/download/v${CURRENT_VERSION}/saml2aws_${CURRENT_VERSION}_linux_amd64.tar.gz -O - | tar -xzv -C ~/.local/bin
chmod u+x ~/.local/bin/saml2aws
sudo install .local/bin/saml2aws /usr/local/bin
```

Next, configure **saml2aws**
```
saml2aws configure --idp-provider <IDP name> --username <Your Username> --url <Your SSO URL> -p default --mfa Auto --skip-prompt
```

To test the installation, authenticate as follows:

```
saml2aws login --idp-account=default --role arn:aws:iam::<Your URN>
```
</details>

<details>
<summary>Install the AWS CLI</summary>
<p>

``` 
apt get install unzip
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
 
To test the installation, run a CLI command, for example:

```
aws ec2 describe-instances
```

</details>

<details>
<summary>Install Terraform</summary>
<p>

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform
 
To test if installation is successful, simply run:
```
terraform
```

You should see terraform output its usage information.
 
</details>

<details>
<summary>(Optional) Install Ansible</summary>
<p>

sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
</details>
 
## Configure your environment

<details>
<summary>Download the scripts</summary>
<p>

Clone this repo:

```
git clone https://github.com/ColorTokens-Labs/xshield-ng-lab-builder.git
```
</details>
<details>
<summary>Configure</summary>
<p>

Edit the configuration file [a relative link](config.txt.sample) and fill in the
fields.
<p>

**_NOTE:_** Save the file as **config.txt**
<p>
Now run the configure.sh script:

```
./configure.sh
```

Your output should look like this:
```
bash $ ./configure.sh
Writing xshield/config.json...
Writing terraform/terraform.tfvars...
Writing terraform/provider.tf
```

If you run into errors, please verify the parameters you entered in the config.txt file.

</details>

## Deploy!

You are now ready to deploy:

```
cd terraform
terraform init
terraform plan
terraform apply
```

If you encounter issues during terraform plan, please re-check the parameters in the configuration file.  Insufficient IAM permissions may also cause some errors, especially when running terraform apply.

If all goes well, terraform apply will output the Bastion server IP, it's PEM filename, and the Wordpress URLs for Prod and Test.








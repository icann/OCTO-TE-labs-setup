# Lab setup guide

Welcome to the lab setup guide!

The following instructions should help you to setup and take down a lab.

> [!NOTE]
> Don't hesitate to ask for help. Nico and Ulrich are always happy to help a colleague. Usually use Slack but in urgent cases a phone call is a faster way to get help.

# Lab Features

- All group name servers are reachable from the internet (through dnsdist in container ns1)
- dnsviz.net and zonemaster.net can be used to test group zonemaster
- DS records can be submitted manually on the group web page
- CDS records are scanned and will be submitted automatically

# Step-by-step guide

- Log into AWS
- Goto CloudFormation
- Click on "Create stack"
- Choose "with new resources (standard)"
- In the field "Amazon S3 URL" put    
  `https://te-lab-setup.s3.us-east-2.amazonaws.com/lab-ec2.yaml`
- Click on "Next"
- Enter Stack name - Please follow the convention    
  LAB-\<DATE\>-\<LOCATION\>, e.g. LAB-20250101-STOCKHOLM
- Enter DnsName - needs to be a valid domain name, usually we use location (city or country) name for that
- Value for DnsParent should not be changed unless you really need to use another domain for the lab.
  Please be aware that the zone must already exist in your AWS account and must be dnssec signed.
- Choose LabType - 1 = resolver, 2 = DNS, 3 = Router
- Do **NOT** change the value of LatestUbuntu, it is a magic AWS value
- Write in your own name as Owner
- Write in the number of groups you want to set up, between 3 and 64
- Click on "Next"
- Scroll to the bottom of the page
- Check the the box "I acknowledge that AWS CloudFormation might create IAM resources with customised names."    
This is needed for the ec2 instance to access s3 and route53
- Click on "Next"
- Scroll to the bottom of the page
- Click on "Next"
- After around 5 minutes the stack creation should show "CREATE_COMPLETE"
- Wait approx. 30 minutes for all lab setup scripts to finish too.
- **DONE**

# Lab access

## SSH access

Follow the ***Prepare your laptop for lab access*** below.<br>
Then just type
```
ssh <DnsName>.te-labs.training
```

> [!TIP]
> Prepare your laptop for lab access
> 
> Put the following in your `~/.ssh/config` file
> 
> ```
> Host *.te-labs.training
>	User ubuntu
>	IdentityFile ~/.ssh/id_te-lab.pem
> IdentitiesOnly yes
>	Port 8484
> ```
>
> Ask one of your colleagues for the `~/.ssh/id_te-lab.pem` file.

## Access to lab web

The web page of the lab can be reached at    
`https://<DnsName>.te-labs.training`

For the group passwords, log into the web by ssh and type
```
cat grouppasswords.txt
```
# Lab life-cycle management

Please setup a new lab at least a week before your engagement.
Test the new lab for full functionality.

Then go to **AWS EC2** and stop the instance (it should have the same name as your lab). On the day of your engagement go back to **AWS EC2** and start the instance again.

> [!NOTE]
> This will save several hundred dollars in AWS fees.

# Lab Take-down

Once you are done with your lab it is important to decomission it.
Please follow these "easy" steps:

- Log into AWS
- Goto Route53 
- Delete all RRs from the lab zone (except apex RRs)
- Goto CloudFormation
- Click on "Stacks" on the left hand menu
- Mark the button in front of your lab
- On the upper left hand choose "Delete"
- After approx. 5 minutes the stack should be deleted
- if the delete failed
  - Click on your lab
  - Click on "Retry delete" and choose the "Force delete" option
- **DONE**

# Feature Requests

Please submit as github issue.

# Network address plan

The lab uses the 100.64.0.0/10 address space from RFC 6598 "IANA-Reserved IPv4 Prefix for Shared Address Space".

There is a backbone to which all groups network interconnects: 100.64.0.0/22

Each goup has a router (rtrXXX) that interconects all it's sub-nets and to the backbone.
The default gateway that provides Internet conection is 100.64.0.1

Each group has a network prefix: 100.100.X.0/24
Then, within each group, prefix is splitted into 3 sub-networks:

- Clients network (**lan**): 100.100.X.0/26
- Internal servers network (**int**): 100.100.X.64/26
- Auth servers stuff network (**dmz**): 100.100.X.128/26

# Network setup for different lab types

## Lab type 1 (Resolver)

## Lab type 2 (DNS)
<img src="configs/www/var/www/html/_img/grp_network_map.png">

## Lab type 3 (Routing)
<img src="configs/www/var/www/html/_img/group_routing_network_globalRPKI_map.png">
<img src="configs/www/var/www/html/_img/grp_routing_network_map.png">

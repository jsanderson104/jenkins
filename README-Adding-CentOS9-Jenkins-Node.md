```
==== building centos 9 vm for jenkins agent to run podman builds with =====

*use nmtui to set a static ip on the interface

# Essential Security crap to turn off for now

echo "automation  ALL=(ALL)   NOPASSWD:ALL" > /etc/sudoers.d/automation
echo "podman-builder  ALL=(ALL)   NOPASSWD:ALL" > /etc/sudoers.d/automation

hostnamectl set-hostname ocibuilder.lab.sanderson.com
export IP=$(ip -br a |grep -vE '^lo.*' |awk -F' ' '{print $3}' | sed 's/\/24//' | tr -d '\n')
export INTERFACE=$(ip -br a |grep -vE '^lo.*' |awk -F' ' '{print $1}'|tr -d '\n')
echo $IP $INTERFACE


systemctl disable --now fapolicyd
setenforce 0
sed -i.bak 's/^SELINUX.*/SELINUX=permissive/' /etc/selinux/config
rm -f /etc/profile.d/tmux.sh
rm -f /etc/profile.d/tmout.sh

# Set DNS to point at my IDM DNS servers then to google dns
cat << EOF > /etc/resolv.conf
search lab.sanderson.com
nameserver 192.168.1.201
nameserver 192.168.1.145
nameserver 8.8.8.8
EOF

# Set firewall ports and services and make them persist reboot
firewall-cmd --add-port=50000/tcp
firewall-cmd --add-service={cockpit,dhcpv6-client,freeipa-4,freeipa-ldap,freeipa-ldaps,freeipa-replication,freeipa-trust,ssh}
firewall-cmd --runtime-to-permanent

# Setup hosts file for my lab to make basic services well-known
cat << EOF >> /etc/hosts
192.168.1.44    ansi.lab.sanderson.com          ansi

192.168.1.76    control.lab.sanderson.com       control
192.168.1.169   worker1.lab.sanderson.com       worker1
192.168.1.170   worker2.lab.sanderson.com       worker2
192.168.1.171   worker3.lab.sanderson.com       worker3
192.168.1.140   worker4.lab.sanderson.com       worker4

192.168.1.201   ipa1.lab.sanderson.com          ipa1
192.168.1.145   ipa2.lab.sanderson.com          ipa2
EOF

# Set MY hostname in hosts file for posterity, but when we join IPA it should register in that DNS as well since our search domain in resolv matches the domain we're joining.
# IMPORTANT THAT YOU DOUBLE-CHECK YOUR HOSTS FILE ENTRY FOR THIS NODE 
echo "$IP       $(hostname -f)                  $(hostname -s)" >> /etc/hosts

# Join IPA domain for podman-builder account ability.
yum install -y ipa-client git

# Only necessary if your IDM server isn't in FIPS mode... -or- your vm here is in FIPS mode and the server isn't. vica-versa.
update-crypto-policies --set FIPS:AD-SUPPORT:SHA1

ipa-client-install --mkhomedir --no-ntp --realm=LAB.SANDERSON.COM --principal=svc_joinhost -w svc_joinhost -U

# Should've registered in IDM DNS at this point... 
dig @192.168.1.145 ocibuilder.lab.sanderson.com +short


# Need more recent Java to run the Jenkins Agent than what Centos repos have...
wget https://download.oracle.com/java/27/latest/jdk-27_linux-x64_bin.tar.gz

# Extract and make it the acive java on the OS
tar -C /opt/ -xzvf jdk-27_linux-x64_bin.tar.gz
chown -R podman-builder:podman-builder /opt/jdk-27
chmod a+X -R /opt/jdk-27
unlink /etc/alternatives/java
ln -s /opt/jdk-27/bin/java /etc/alternatives/java

# Fix /home mount options to allow executing and set the options back to default
sed -i.bak '/^\/dev\/mapper\/vg_os-home.*/d' /etc/fstab && mount |grep home | awk -F' ' '{print $1 " " $3 " " $5 " defaults 0 0"}' >> /etc/fstab && systemctl daemon-reload && mount -o remount /home

dnf install -y podman ansible-core

# Download and the Jenkins agent from the Jenkins server
wget http://jenkins.lab.sanderson.com:8080/jnlpJars/agent.jar


# Next step is to Create the Node in Jenkins Settings page as admin user. Goto the Nodes settings section and Create a new node (nothing special here). I did, however, set the Jenkins "root" directory to the LDAP
# accounts home directory so everything would be contained into one place.
# Also change the usage to "Use this node as much as possible" - we havent ventured into segregating builds via labels yet.
# Save and Apply the new node settings. Now in the jenkins nodes list you will see your newly created node. Click on it to go to its settings page to retrieve the "secret" need for the command below

# Run the Jenkins Agent so that it doesn't exit but runs in the background until i kill it. This command has to be retrieved from the JenkinsUI NODE settings/creation page so it'll have an updated secret
nohup java -jar agent.jar -url http://jenkins.lab.sanderson.com:8080/ -secret [put secret from jenkins node in the UI here] -name "ocibuilder.lab.sanderson.com" -webSocket -workDir "/home/podman-builder" 2>&1 > ./agent.log &

```




1. Pull the Jenkins container image 
# podman pull docker.io/jenkins/jenkins

2. Run the container with persistent storage
# podman run -dt --name jenkins --hostname jenkins.lab.sanderson.com -v /mnt/jenkins:/jenkins_home -p 9090:8080 -p 9443:8443 -e JENKINS_HOME=/jenkins_home  docker.io/jenkins/jenkins

3. Get Jenkins Initial setup admin password
# podman logs jenkins |grep -A5 "Please use the following password to proceed to installation"

4. Open the Firewall ports on the container host 
# firewall-cmd --add-port={9090/tcp,9443/tcp} && firewall-cmd --runtime-to-permanent

5. Open a browser and navigate to the Jenkins non-ssl port that we provided above (9090-->8080) and use the token provided from step 3 to login as admin for setup.
  In my home lab, i use my ansible vm to run this container so http://ansi.lab.sanderson.com:9090/

6. After password entry, select "Install suggested plugins"

7. Create first admin user

*More complex setup would be to use nginx and the proxy and have it answer on a unique IP via SSL then proxy to the localhost backend port 9090

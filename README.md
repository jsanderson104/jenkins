<h1> How to run Jenkins in Podman</h1>

Pull the Jenkins container image
```
podman pull docker.io/jenkins/jenkins
```

Make the Jenkins_home path writeable from within the contanier.. this is the lazy insecure way. Don't judge me - it's a home lab. 
This location can be used later to make backups of the app and have it stored on the host/vm.
```
mkdir -p /mnt/jenkins && chmod 777 /mnt/jenkins
```

Run the container with persistent storage
```
podman run -dt --name jenkins --hostname jenkins.lab.sanderson.com -v /mnt/jenkins:/jenkins_home -p 9090:8080 -p 9443:8443 -e JENKINS_HOME=/jenkins_home  docker.io/jenkins/jenkins
```

Get Jenkins Initial setup admin password
```
podman logs jenkins |grep -A5 "Please use the following password to proceed to installation"
```

Open the Firewall ports on the container host 
```
firewall-cmd --add-port={9090/tcp,9443/tcp} && firewall-cmd --runtime-to-permanent
```

Open a browser and navigate to the Jenkins non-ssl port that we provided above (9090-->8080) and use the token provided from step 3 to login as admin for setup.
In my home lab, i use my ansible vm to run this container so http://ansi.lab.sanderson.com:9090/ will be the default "base url" for jenkins when it starts. I cahnged it to reflect the jenkins.lab.sanderson.com name since i have it in DNS.

6. After password entry, select "Install suggested plugins"

7. Create first admin user

*More complex setup would be to use nginx and the proxy and have it answer on a unique IP via SSL then proxy to the localhost backend port 9090


<h2>How to have an external Jenkins instance use K8S as a "cloud" platform for building.</h2><br>
-  It should dynamically spin-up pods/images when GitHub committs occur.
First and foremost, you'll need to install the Kubernetes plugin for Jenkins.<br>
There is a file in this repo that will need to be applied to the K8S cluster to create the namespace, serviceAccount, and RoleBinding.<br>
Then we will need to get the K8S token for logging in as the newly created service account.<br>

```
kubectl create token -n jenkins-builders jenkins-svc-account
```

Save that token output for use in Jenkins. <br>
You will need to create a Jenkins Credential to make-use-of the new K8S token.<br>

Important that while setting up the credential, you'll need to use the "secret text" option and paste the token in that box.<br>
Now that you've got the Kubernetes "slice of the pie" allocated for Jenkins, we next need to configure Jenkins.<br>

<b>Inside Jenkins admin user, click on the Gear in the top-right and then choose "Clouds", then Create or Add.</b> <br>
<b>Settings: </b>
```
Kubernetes URL = https://control.lab.sanderson.com:6443
```

```
Kubernetes Namespace = jenkins-builders
```
- Disable https certificate check
- Set the Credentials we created using the Token.
- Add the Jenkins URL value to the baseurl of your Jenkins instance.
- Enable garbage collection


<b> To set the Jenkins container to start on reboot as a systemd service </b>
```
podman generate systemd jenkins
```
Copy the file to /etc/systemd/system/jenkins.service and reload systemd
```
systemctl daemon-reload
```




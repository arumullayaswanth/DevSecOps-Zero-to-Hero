# DevSecOps for This Weather App

## 1. What is this project?

This project is a weather website made using React.

GitHub repository:

`https://github.com/arumullayaswanth/weather-app-devsecops.git`

It works like this:

- user types a city name
- app asks OpenWeather for weather data
- app shows the result on the screen

Later, we can:

- build the app
- scan it for security problems
- put it inside Docker
- deploy it to Kubernetes on EC2

So the short story is:

`Code -> Check -> Build -> Push -> Deploy`

## 2. What is DevSecOps?

DevSecOps is a simple idea:

- `Dev` means writing code
- `Sec` means security
- `Ops` means deployment and running the app

Meaning:

We do security checks in every step, not only at the end.

## 3. Pipeline flow

Your pipeline for this project is:

`Developer -> GitHub -> Jenkins -> Security Scans -> Docker Build -> Amazon ECR -> Update Kubernetes File -> Deploy to Kubernetes on EC2 -> OWASP ZAP Scan -> Falco Monitoring`

Very simple explanation:

1. You write code.
2. You push code to GitHub.
3. Jenkins starts automatically.
4. Jenkins checks code and security.
5. Jenkins builds Docker image.
6. Jenkins pushes image to Amazon ECR.
7. Jenkins updates Kubernetes deployment file with the new image version.
8. Kubernetes runs the new app.
9. OWASP ZAP checks the live website.
10. Falco watches runtime activity.

## 4. Tools and jobs

| Tool | Job | Easy meaning |
| --- | --- | --- |
| GitHub | source code | stores your project |
| Jenkins | CI/CD | runs pipeline automatically |
| SonarQube | SAST | checks code quality and risky code |
| Snyk | dependency scan | checks npm packages for vulnerabilities |
| Gitleaks | secrets scan | finds keys, passwords, tokens in code |
| Trivy | container scan | checks Docker image for vulnerabilities |
| Checkov | IaC scan | checks Kubernetes YAML for mistakes |
| Docker | build image | packs app into a container |
| Amazon ECR | image registry | stores Docker images |
| Kubernetes / k3s | deployment | runs the app |
| OWASP ZAP | DAST | tests the running app from outside |
| Falco | runtime security | watches the cluster after deployment |

## 5. Why each security check is used

### SonarQube

Checks the code itself.

Finds things like:

- bad code quality
- code smells
- risky coding patterns

### Snyk

Checks packages from `package.json`.

Finds things like:

- old vulnerable libraries

### Gitleaks

Checks if secrets are written in code.

Finds things like:

- API keys
- passwords
- tokens

### Trivy

Checks the Docker image.

Finds things like:

- vulnerable OS packages
- risky software in the image

### Checkov

Checks Kubernetes YAML files.

Finds things like:

- bad security settings
- weak deployment config

### OWASP ZAP

Checks the live website after deployment.

Finds things like:

- common web security issues
- missing security headers

### Falco

Watches the app after it is running.

Finds things like:

- suspicious processes
- strange runtime behavior

## 6. Important truth about this app

This app is a frontend app.

So even if we remove the API key from GitHub, the browser can still see the key when the frontend uses it.

That means:

- removing the key from code is good
- using Jenkins secret is better than hardcoding
- but it is still not a fully hidden backend secret

Real best solution later:

`React frontend -> backend API -> OpenWeather API`

That way the key stays on the server, not in the browser.

## 7. Files added for the pipeline

These files were added:

- [jenkins/Jenkinsfile](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/jenkins/Jenkinsfile#L1) = Jenkins pipeline
- [Dockerfile](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/Dockerfile#L1) = Docker build file
- [nginx.conf](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/nginx.conf#L1) = Nginx config
- [k8s/namespace.yaml](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/k8s/namespace.yaml#L1) = namespace
- [k8s/deployment.yaml](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/k8s/deployment.yaml#L1) = deployment
- [k8s/service.yaml](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/k8s/service.yaml#L1) = service
- [sonar-project.properties](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/sonar-project.properties#L1) = SonarQube config
- [.gitleaks.toml](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/.gitleaks.toml#L1) = Gitleaks config
- [.env.example](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/.env.example#L1) = sample env file

## 8. Jenkins pipeline stages

Jenkins runs these stages:

1. `Checkout`
   Downloads code from GitHub.
2. `Secrets Scan`
   Gitleaks checks if secrets are in the code.
3. `Install Dependencies`
   npm installs the packages.
4. `Test`
   Project tests run.
5. `Build Frontend`
   React production build is created.
6. `SAST`
   SonarQube scans the code.
7. `Dependency Scan`
   Snyk scans the packages.
8. `Container Build`
   Docker builds image.
9. `Container Scan`
   Trivy scans image.
10. `ECR Image Pushing`
   Docker image is pushed to Amazon ECR.
11. `IaC Security Scan`
   Checkov scans Kubernetes files.
12. `Update Deployment file`
   Jenkins updates image tag in deployment YAML and pushes it to GitHub.
13. `Deploy to Kubernetes`
   Kubernetes applies the YAML files.
14. `DAST`
   OWASP ZAP scans the running app.

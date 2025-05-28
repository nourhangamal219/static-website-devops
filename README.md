# static-website-devops
🚀 Project 1: CI/CD Pipeline for a Static Website on AWS (with Terraform for provisioning Infrastructure + GitHub Actions for automating CI/CD Pipeline)

A real-world, cloud-native DevOps project that checks all the boxes: IaC, CI/CD, cloud, security, monitoring, and automation.

## 🚀 Features

✅ Fully automated infrastructure provisioning using Terraform 
✅ Terraform S3 backend with state locking via DynamoDB  
✅ ACM certificate issuance and DNS validation  
✅ Secure CloudFront CDN with Route 53 integration  
✅ GitHub Actions workflow for plan/apply on PR approval  
✅ Health check and monitoring integration

## 📦 Tech Stack

- **Infrastructure as Code**: Terraform (v1.6+)
- **CI/CD**: GitHub Actions
- **Cloud Provider**: AWS
- **DNS & SSL**: Route 53 + ACM
- **CDN**: AWS CloudFront
- **Static Hosting**: S3 (public access blocked + OAI via CloudFront)
- **Monitoring**: CloudWatch Health Checks
- 

---

## 📁 Project Structure

```bash
.
├── .github/workflows/
│   └── deploy.yml         # GitHub Actions for CI/CD
│   └── UpdateSite.yml         # GitHub Actions for CI/CD
├── terraform/
│   ├── main.tf            # Core infrastructure
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   └── backend.tf         # S3 backend & DynamoDB locking
├── site/
│   └── index.html         # Your static website content
└── README.md              # You're here

⚙️ Prerequisites

AWS Account with IAM access
Registered Domain Name
Terraform v1.6+
GitHub repository with secrets:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
DOMAIN_NAME

🌍 Deployment Architecture

[ GitHub Actions ]
        ↓
[ Terraform ]
        ↓
+----------------------------+
| AWS Infrastructure         |
|----------------------------|
| S3 Bucket (static site)    |
| CloudFront (CDN)           |
| Route53 (DNS)              |
| ACM Certificate (SSL)      |
| DynamoDB (state locking)   |
+----------------------------+

🤖 GitHub Actions Automation
On every pull request for terraform files:

terraform plan runs
A comment is posted with the plan output
On merge to main:

terraform apply is triggered

On every pull request for site files:
Sync with S3

Feel free to fork this repo and use it in your own DevOps portfolio.
PRs welcome if you spot any bugs or have cool ideas to extend it (e.g., GitOps, modules, logging, etc).

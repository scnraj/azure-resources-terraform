# Quick Start Guide

## Fast Track Deployment (5 minutes)

### Option 1: Terraform (Recommended)

```bash
# 1. Login to Azure
az login

# 2. Initialize Terraform
terraform init

# 3. Deploy App Service first (without custom domain)
# Comment out lines 36-54 in main.tf (custom domain resources)
terraform apply

# 4. Get verification ID
az webapp show --resource-group rg-mygame-prod --name app-mygame-prod --query customDomainVerificationId --output tsv

# 5. Configure DNS records:
#    - CNAME: mygame -> app-mygame-prod.azurewebsites.net
#    - TXT: asuid.mygame -> [verification ID from step 4]

# 6. Wait 5-10 minutes for DNS propagation, then:
# Uncomment lines 36-54 in main.tf
terraform apply

# 7. Done! Visit https://mygame.mahima.info
```

### Option 2: Azure CLI Script

```bash
# 1. Run the deployment script
./deploy.sh

# 2. Follow the prompts to configure DNS
# 3. Script will complete the deployment
```

## Important Notes

1. **DNS is CRITICAL**: You must configure DNS records before adding the custom domain
2. **App Service Name**: Must be globally unique (change in variables.tf if needed)
3. **Cost**: ~$13-15/month for B1 tier
4. **SSL Certificate**: Automatically managed and renewed by Microsoft (free)

## Verification Commands

```bash
# Check deployment status
terraform output

# Test HTTPS
curl -I https://mygame.mahima.info

# Check certificate
openssl s_client -connect mygame.mahima.info:443 -servername mygame.mahima.info
```

## Troubleshooting

**DNS not resolving?**
```bash
nslookup mygame.mahima.info
dig mygame.mahima.info
```

**Domain verification failing?**
- Double-check TXT record: `dig TXT asuid.mygame.mahima.info`
- Wait longer (DNS can take up to 48 hours)

## Need Different Runtime?

Edit `main.tf` line 28-30:
```hcl
# For Python
application_stack {
  python_version = "3.11"
}

# For .NET
application_stack {
  dotnet_version = "7.0"
}

# For PHP
application_stack {
  php_version = "8.2"
}
```

See full documentation in [README.md](README.md)

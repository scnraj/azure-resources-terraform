# Complete Deployment Guide for Azure App Service

## Prerequisites Installation

### Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Azure CLI
```bash
brew install azure-cli
```

Or download directly from: https://aka.ms/installazureclimacos

Verify installation:
```bash
az version
```

### Install Terraform
```bash
brew install terraform
```

Or download from: https://www.terraform.io/downloads

Verify installation:
```bash
terraform version
```

---

## 🚀 Deployment Steps

### Step 1: Login to Azure
```bash
cd /Users/rajsinthalapadi/ADO-Repo/Local-repo
az login
```

This will open a browser window. Login with your Azure credentials.

### Step 2: Select Your Subscription
```bash
# List available subscriptions
az account list --output table

# Set the subscription you want to use
az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"

# Verify
az account show
```

### Step 3: Initialize Terraform
```bash
terraform init
```

Expected output: "Terraform has been successfully initialized!"

### Step 4: Review the Deployment Plan
```bash
terraform plan
```

This shows what will be created. Review carefully.

### Step 5: Two-Phase Deployment

#### Phase 1: Deploy App Service (Without Custom Domain)

**First, temporarily comment out the custom domain sections in main.tf:**

Edit `main.tf` and comment out lines 36-54 (add `#` at the start of each line):
```hcl
# # Custom Domain
# resource "azurerm_app_service_custom_hostname_binding" "main" {
#   hostname            = var.custom_domain
#   app_service_name    = azurerm_linux_web_app.main.name
#   resource_group_name = azurerm_resource_group.main.name
# 
#   lifecycle {
#     ignore_changes = [ssl_state, thumbprint]
#   }
# 
#   depends_on = [azurerm_linux_web_app.main]
# }
# 
# # Microsoft Managed Certificate
# resource "azurerm_app_service_managed_certificate" "main" {
#   custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.main.id
# }
# 
# # Certificate Binding
# resource "azurerm_app_service_certificate_binding" "main" {
#   hostname_binding_id = azurerm_app_service_custom_hostname_binding.main.id
#   certificate_id      = azurerm_app_service_managed_certificate.main.id
#   ssl_state           = "SniEnabled"
# }
```

**Deploy:**
```bash
terraform apply
```

Type `yes` when prompted.

**Get important information:**
```bash
# Get the App Service hostname
terraform output app_service_default_hostname

# Get domain verification ID
az webapp show \
  --resource-group rg-mygame-prod \
  --name app-mygame-prod \
  --query customDomainVerificationId \
  --output tsv
```

#### Phase 2: Configure DNS and Add Custom Domain

**Configure DNS Records** in your domain provider (where mahima.info is registered):

1. **CNAME Record:**
   - Type: CNAME
   - Name: `mygame`
   - Value: `app-mygame-prod.azurewebsites.net` (from terraform output)
   - TTL: 3600

2. **TXT Record (for verification):**
   - Type: TXT
   - Name: `asuid.mygame`
   - Value: [Verification ID from above command]
   - TTL: 3600

**Wait for DNS Propagation (5-10 minutes):**
```bash
# Check if DNS is working
nslookup mygame.mahima.info

# Or use dig
dig mygame.mahima.info
```

**Uncomment the custom domain sections in main.tf** (remove the `#` symbols)

**Deploy again:**
```bash
terraform apply
```

Type `yes` when prompted.

---

## ✅ Verification

### Check App Service
```bash
az webapp show \
  --resource-group rg-mygame-prod \
  --name app-mygame-prod \
  --output table
```

### Check Custom Domain
```bash
az webapp config hostname list \
  --resource-group rg-mygame-prod \
  --webapp-name app-mygame-prod \
  --output table
```

### Check SSL Certificate
```bash
az webapp config ssl list \
  --resource-group rg-mygame-prod \
  --output table
```

### Test Your Website
```bash
# Test HTTP redirect
curl -I http://mygame.mahima.info

# Test HTTPS
curl -I https://mygame.mahima.info

# Check certificate details
openssl s_client -connect mygame.mahima.info:443 -servername mygame.mahima.info < /dev/null
```

Visit in browser: **https://mygame.mahima.info**

---

## 📊 View in Azure Portal

Your resources will be at:
```
https://portal.azure.com/#@/resource/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-mygame-prod/overview
```

---

## 🔧 Troubleshooting

### Issue: "app-mygame-prod" name already taken
The App Service name must be globally unique. Update in `variables.tf`:
```hcl
variable "app_service_name" {
  default     = "app-mygame-prod-YOUR_INITIALS"  # Make it unique
}
```

### Issue: Domain verification fails
```bash
# Check DNS records
dig TXT asuid.mygame.mahima.info
dig CNAME mygame.mahima.info

# Wait longer - DNS can take up to 48 hours (usually 5-10 minutes)
```

### Issue: Certificate creation fails
- Make sure the App Service Plan is at least B1 (Basic) tier
- Ensure the custom domain is successfully bound first
- Wait a few minutes after domain binding before creating certificate

### Issue: Terraform state issues
```bash
# Refresh state
terraform refresh

# If needed, import existing resources
terraform import azurerm_resource_group.main /subscriptions/YOUR_SUB_ID/resourceGroups/rg-mygame-prod
```

---

## 🧹 Cleanup (Delete Everything)

When you're done and want to delete all resources:
```bash
terraform destroy
```

Type `yes` to confirm.

This will delete:
- App Service
- App Service Plan
- SSL Certificate
- Resource Group
- All associated resources

**Cost**: This will stop all billing immediately.

---

## 💰 Cost Estimate

- **B1 App Service Plan**: ~$13-15 USD/month (~$20 AUD/month)
- **Microsoft Managed Certificate**: FREE
- **Bandwidth**: Pay as you go (usually minimal)

Australia East region may have slightly different pricing.

---

## 🎯 Next Steps After Deployment

### 1. Deploy Your Application Code

**Using Git:**
```bash
# Get Git credentials
az webapp deployment list-publishing-credentials \
  --name app-mygame-prod \
  --resource-group rg-mygame-prod

# Configure Git deployment
cd /path/to/your/app
git remote add azure https://app-mygame-prod.scm.azurewebsites.net:443/app-mygame-prod.git
git push azure main:master
```

**Using Azure DevOps or GitHub Actions:**
- Set up CI/CD pipeline
- Configure deployment credentials
- Push code automatically on commit

**Using FTP:**
```bash
# Get FTP credentials
az webapp deployment list-publishing-credentials \
  --name app-mygame-prod \
  --resource-group rg-mygame-prod \
  --query "{ftpUrl:publishingPassword, username:publishingUserName}" \
  --output table
```

### 2. Configure Application Settings
```bash
# Set environment variables
az webapp config appsettings set \
  --resource-group rg-mygame-prod \
  --name app-mygame-prod \
  --settings KEY1=value1 KEY2=value2
```

### 3. Enable Application Insights (Recommended)
```bash
az monitor app-insights component create \
  --app app-mygame-insights \
  --location australiaeast \
  --resource-group rg-mygame-prod \
  --application-type web

# Get instrumentation key and add to app settings
```

### 4. Configure Deployment Slots (Optional - for zero-downtime deployments)
```bash
az webapp deployment slot create \
  --name app-mygame-prod \
  --resource-group rg-mygame-prod \
  --slot staging
```

### 5. Set up Continuous Deployment
Enable from Azure Portal or configure in your CI/CD pipeline.

---

## 📞 Support Resources

- **Azure Documentation**: https://docs.microsoft.com/en-us/azure/app-service/
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Azure CLI Reference**: https://docs.microsoft.com/en-us/cli/azure/
- **Azure Status**: https://status.azure.com/

---

## Quick Command Reference

```bash
# Login
az login

# List subscriptions
az account list --output table

# Set subscription
az account set --subscription "SUBSCRIPTION_NAME"

# Deploy
terraform init
terraform plan
terraform apply

# Check status
terraform output
az webapp show --resource-group rg-mygame-prod --name app-mygame-prod --output table

# View logs
az webapp log tail --resource-group rg-mygame-prod --name app-mygame-prod

# Restart app
az webapp restart --resource-group rg-mygame-prod --name app-mygame-prod

# Destroy
terraform destroy
```

---

## Security Best Practices

1. **Enable Managed Identity** for secure access to Azure resources
2. **Configure IP Restrictions** if needed
3. **Enable Application Insights** for monitoring
4. **Set up Alerts** for downtime/errors
5. **Use Deployment Slots** for safe deployments
6. **Enable Diagnostic Logging**
7. **Regular Security Updates** for your application stack

Good luck with your deployment! 🚀

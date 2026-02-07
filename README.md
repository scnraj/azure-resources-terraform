# Azure App Service with Custom Domain Deployment

This project deploys an Azure App Service Plan with a Web App, custom domain (mygame.mahima.info), and Microsoft managed certificate.

## Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Terraform** - [Install Terraform](https://www.terraform.io/downloads)
3. **Azure Subscription** - Active Azure subscription
4. **Domain Access** - Ability to update DNS records for mahima.info

## Architecture

- **Resource Group**: Container for all Azure resources
- **App Service Plan**: B1 Basic tier (Linux)
- **App Service**: Linux Web App with Node.js 18 LTS
- **Custom Domain**: mygame.mahima.info
- **SSL Certificate**: Microsoft managed certificate (free)

## DNS Prerequisites

**CRITICAL**: Before deploying, you MUST configure DNS records for your custom domain:

### Step 1: Get verification codes
After creating the App Service but before adding the custom domain, you'll need:
1. The default App Service hostname (e.g., `app-mygame-prod.azurewebsites.net`)

### Step 2: Add DNS records
In your DNS provider (where mahima.info is registered), add these records:

1. **CNAME Record** (for the subdomain):
   - **Type**: CNAME
   - **Name**: mygame
   - **Value**: `app-mygame-prod.azurewebsites.net` (your App Service hostname)
   - **TTL**: 3600

2. **TXT Record** (for domain verification):
   - **Type**: TXT
   - **Name**: asuid.mygame
   - **Value**: Custom verification ID from Azure (see below)
   - **TTL**: 3600

### Getting the Custom Verification ID

Run this after creating the App Service:
```bash
az webapp show \
  --resource-group rg-mygame-prod \
  --name app-mygame-prod \
  --query customDomainVerificationId \
  --output tsv
```

## Deployment Steps

### 1. Login to Azure
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review the Plan
```bash
terraform plan
```

### 4. Two-Stage Deployment (Recommended)

#### Stage 1: Deploy App Service without Custom Domain

Edit `main.tf` and comment out the custom domain and certificate sections:
```hcl
# # Custom Domain
# resource "azurerm_app_service_custom_hostname_binding" "main" { ... }
# 
# # Microsoft Managed Certificate
# resource "azurerm_app_service_managed_certificate" "main" { ... }
# 
# # Certificate Binding
# resource "azurerm_app_service_certificate_binding" "main" { ... }
```

Deploy:
```bash
terraform apply
```

Get the App Service hostname and verification ID:
```bash
terraform output app_service_default_hostname
az webapp show --resource-group rg-mygame-prod --name app-mygame-prod --query customDomainVerificationId --output tsv
```

#### Stage 2: Configure DNS, then Deploy Custom Domain

1. Add the DNS records as described above
2. Wait 5-10 minutes for DNS propagation
3. Verify DNS is working:
   ```bash
   nslookup mygame.mahima.info
   dig mygame.mahima.info
   ```

4. Uncomment the custom domain sections in `main.tf`
5. Deploy again:
   ```bash
   terraform apply
   ```

### Alternative: Single Deployment (if DNS is already configured)

If you've already configured DNS records:
```bash
terraform apply -auto-approve
```

## Customization

### Change App Service Plan SKU

Edit `variables.tf`:
```hcl
variable "sku_name" {
  default = "S1"  # Standard tier
}
```

Available SKUs:
- **B1, B2, B3**: Basic tier
- **S1, S2, S3**: Standard tier
- **P1V2, P2V2, P3V2**: Premium V2 tier

### Change Runtime Stack

Edit `main.tf` in the `application_stack` block:
```hcl
application_stack {
  # For Python
  python_version = "3.11"
  
  # For .NET
  # dotnet_version = "7.0"
  
  # For Java
  # java_version = "17"
}
```

### Change Region

Edit `variables.tf`:
```hcl
variable "location" {
  default = "West Europe"
}
```

## Verification

### 1. Check App Service Status
```bash
az webapp show --resource-group rg-mygame-prod --name app-mygame-prod --output table
```

### 2. Check Custom Domain Binding
```bash
az webapp config hostname list --resource-group rg-mygame-prod --webapp-name app-mygame-prod --output table
```

### 3. Check SSL Certificate
```bash
az webapp config ssl list --resource-group rg-mygame-prod --output table
```

### 4. Test HTTPS
```bash
curl -I https://mygame.mahima.info
```

## Troubleshooting

### Error: "Unable to verify domain ownership"
- Ensure DNS records are properly configured
- Wait longer for DNS propagation (can take up to 48 hours, usually 5-10 minutes)
- Verify using: `nslookup mygame.mahima.info`

### Error: "Hostname is already in use"
- The custom domain might be bound to another Azure resource
- Check DNS configuration points to the correct App Service

### Error: "Cannot create managed certificate"
- Ensure the domain is successfully bound first
- Microsoft managed certificates require the domain to be validated
- Check that the App Service Plan is at least Basic tier (B1)

### Certificate Not Auto-Renewing
Microsoft managed certificates auto-renew, but ensure:
- The App Service and domain binding remain active
- DNS records remain valid

## Deployment with Azure CLI (Alternative)

See `deploy.sh` for a shell script alternative.

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will delete all resources including the App Service and certificate.

## Cost Estimate

- **B1 App Service Plan**: ~$13-15/month
- **Microsoft Managed Certificate**: Free
- **Bandwidth**: Pay-as-you-go

## Security Recommendations

1. Enable App Service Authentication if needed
2. Configure Application Insights for monitoring
3. Set up deployment slots for zero-downtime deployments
4. Enable diagnostic logging
5. Configure IP restrictions if applicable

## Next Steps

1. Deploy your application code using:
   - Azure DevOps Pipeline
   - GitHub Actions
   - FTP/FTPS
   - Git deployment
   - VS Code Azure extension

2. Configure Application Settings/Environment Variables
3. Set up Application Insights for monitoring
4. Configure scaling rules if needed

## Support

For issues with:
- **Terraform**: Check [Terraform Azure Provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- **Azure App Service**: Check [Azure documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- **Custom domains**: Check [Azure custom domain docs](https://docs.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-custom-domain)

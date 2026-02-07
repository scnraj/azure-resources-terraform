#!/bin/bash

# Azure App Service Deployment Script
# Deploys App Service Plan with Custom Domain and Managed Certificate

set -e  # Exit on error

# Configuration Variables
RESOURCE_GROUP="rg-mygame-prod"
LOCATION="australiaeast"
APP_SERVICE_PLAN="asp-mygame-prod"
APP_SERVICE_NAME="app-mygame-prod"
SKU="B2"
CUSTOM_DOMAIN="mygame.mahima.info"

echo "================================================"
echo "Azure App Service Deployment Script"
echo "================================================"
echo ""
echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  App Service Plan: $APP_SERVICE_PLAN"
echo "  App Service: $APP_SERVICE_NAME"
echo "  SKU: $SKU"
echo "  Custom Domain: $CUSTOM_DOMAIN"
echo ""
echo "================================================"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
echo "Checking Azure login status..."
az account show &> /dev/null || {
    echo "Not logged in to Azure. Please login..."
    az login
}

# Get subscription info
SUBSCRIPTION=$(az account show --query name -o tsv)
echo "Using subscription: $SUBSCRIPTION"
echo ""

# Create Resource Group
echo "Step 1: Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output table

echo ""

# Create App Service Plan
echo "Step 2: Creating App Service Plan..."
az appservice plan create \
    --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku $SKU \
    --output table

echo ""

# Create Web App
echo "Step 3: Creating Web App..."
az webapp create \
    --name $APP_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN \
    --runtime "NODE:18-lts" \
    --output table

echo ""

# Enable HTTPS Only
echo "Step 4: Enabling HTTPS Only..."
az webapp update \
    --name $APP_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP \
    --https-only true \
    --output table

echo ""

# Get App Service Default Hostname
DEFAULT_HOSTNAME=$(az webapp show \
    --name $APP_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP \
    --query defaultHostName \
    --output tsv)

echo "================================================"
echo "App Service Created Successfully!"
echo "================================================"
echo "Default Hostname: $DEFAULT_HOSTNAME"
echo ""

# Get Custom Domain Verification ID
VERIFICATION_ID=$(az webapp show \
    --name $APP_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP \
    --query customDomainVerificationId \
    --output tsv)

echo "Custom Domain Verification ID: $VERIFICATION_ID"
echo ""

echo "================================================"
echo "DNS CONFIGURATION REQUIRED"
echo "================================================"
echo ""
echo "Before proceeding, configure these DNS records in your DNS provider:"
echo ""
echo "1. CNAME Record:"
echo "   Type: CNAME"
echo "   Name: mygame"
echo "   Value: $DEFAULT_HOSTNAME"
echo "   TTL: 3600"
echo ""
echo "2. TXT Record (for verification):"
echo "   Type: TXT"
echo "   Name: asuid.mygame"
echo "   Value: $VERIFICATION_ID"
echo "   TTL: 3600"
echo ""
echo "================================================"
echo ""

# Ask user to confirm DNS is configured
read -p "Have you configured the DNS records and waited for propagation? (yes/no): " DNS_READY

if [ "$DNS_READY" != "yes" ]; then
    echo ""
    echo "Please configure DNS records and run the script again, or continue manually with:"
    echo ""
    echo "# Add custom domain:"
    echo "az webapp config hostname add \\"
    echo "    --webapp-name $APP_SERVICE_NAME \\"
    echo "    --resource-group $RESOURCE_GROUP \\"
    echo "    --hostname $CUSTOM_DOMAIN"
    echo ""
    echo "# Create managed certificate:"
    echo "az webapp config ssl create \\"
    echo "    --resource-group $RESOURCE_GROUP \\"
    echo "    --name $APP_SERVICE_NAME \\"
    echo "    --hostname $CUSTOM_DOMAIN"
    echo ""
    echo "# Bind certificate:"
    echo "az webapp config ssl bind \\"
    echo "    --resource-group $RESOURCE_GROUP \\"
    echo "    --name $APP_SERVICE_NAME \\"
    echo "    --certificate-thumbprint <THUMBPRINT> \\"
    echo "    --ssl-type SNI"
    echo ""
    exit 0
fi

# Verify DNS
echo ""
echo "Step 5: Verifying DNS configuration..."
if nslookup $CUSTOM_DOMAIN > /dev/null 2>&1; then
    echo "✓ DNS lookup successful for $CUSTOM_DOMAIN"
else
    echo "⚠ Warning: DNS lookup failed. Proceeding anyway, but may fail..."
fi

echo ""

# Add Custom Domain
echo "Step 6: Adding Custom Domain..."
az webapp config hostname add \
    --webapp-name $APP_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP \
    --hostname $CUSTOM_DOMAIN \
    --output table

echo ""

# Create Managed Certificate
echo "Step 7: Creating Microsoft Managed Certificate..."
echo "Note: This may take a few minutes..."

az webapp config ssl create \
    --resource-group $RESOURCE_GROUP \
    --name $APP_SERVICE_NAME \
    --hostname $CUSTOM_DOMAIN \
    --output table

echo ""

# Get Certificate Thumbprint
CERT_THUMBPRINT=$(az webapp config ssl list \
    --resource-group $RESOURCE_GROUP \
    --query "[?hostNames[0]=='$CUSTOM_DOMAIN'].thumbprint" \
    --output tsv)

echo "Certificate Thumbprint: $CERT_THUMBPRINT"
echo ""

# Bind Certificate
echo "Step 8: Binding Certificate..."
az webapp config ssl bind \
    --resource-group $RESOURCE_GROUP \
    --name $APP_SERVICE_NAME \
    --certificate-thumbprint $CERT_THUMBPRINT \
    --ssl-type SNI \
    --output table

echo ""
echo "================================================"
echo "DEPLOYMENT COMPLETE!"
echo "================================================"
echo ""
echo "App Service URL: https://$CUSTOM_DOMAIN"
echo "Default URL: https://$DEFAULT_HOSTNAME"
echo ""
echo "Verify deployment:"
echo "  curl -I https://$CUSTOM_DOMAIN"
echo ""
echo "View in Azure Portal:"
echo "  https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$APP_SERVICE_NAME"
echo ""
echo "================================================"
echo "Next Steps:"
echo "================================================"
echo "1. Deploy your application code"
echo "2. Configure app settings/environment variables"
echo "3. Set up monitoring and alerts"
echo "4. Configure deployment slots (optional)"
echo ""

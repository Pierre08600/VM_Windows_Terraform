# ============================================================================
# Script de déploiement automatique VM Windows Server 2022 sur Azure
# Auteur: Pierre Baroni
# Description: Automatise le déploiement Terraform d'une VM Windows sur Azure
#
# ⚠️ IMPORTANT: Ce script doit être placé à la RACINE du projet
#               (au même niveau que le dossier terraform/, PAS dedans)
#
# Structure attendue:
#   Projet/
#   ├── Deploy-AzureVM.ps1  ← Ce script ICI
#   └── terraform/          ← Dossier Terraform
#       ├── provider.tf
#       ├── variables.tf
#       ├── main.tf
#       └── outputs.tf
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Deploy', 'Destroy', 'GetInfo', 'Connect')]
    [string]$Action = 'Deploy',
    
    [Parameter(Mandatory=$false)]
    [string]$TerraformPath = ".\terraform",
    
    [Parameter(Mandatory=$false)]
    [string]$TenantId = ""
)

# Couleurs pour l'affichage
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Success" { Write-Host $Message -ForegroundColor Green }
        "Error"   { Write-Host $Message -ForegroundColor Red }
        "Warning" { Write-Host $Message -ForegroundColor Yellow }
        "Info"    { Write-Host $Message -ForegroundColor Cyan }
        default   { Write-Host $Message }
    }
}

# Fonction pour vérifier les prérequis
function Test-Prerequisites {
    Write-ColorOutput "`n=== Vérification des prérequis ===" "Info"
    
    $allOk = $true
    
    # Vérifier Terraform
    Write-Host "Vérification de Terraform... " -NoNewline
    if (Get-Command terraform -ErrorAction SilentlyContinue) {
        $tfVersion = terraform version -json | ConvertFrom-Json
        Write-ColorOutput "OK (Version: $($tfVersion.terraform_version))" "Success"
    } else {
        Write-ColorOutput "NON INSTALLÉ" "Error"
        Write-ColorOutput "Installez Terraform depuis: https://www.terraform.io/downloads" "Warning"
        $allOk = $false
    }
    
    # Vérifier Azure CLI
    Write-Host "Vérification d'Azure CLI... " -NoNewline
    if (Get-Command az -ErrorAction SilentlyContinue) {
        $azVersion = (az version | ConvertFrom-Json).'azure-cli'
        Write-ColorOutput "OK (Version: $azVersion)" "Success"
    } else {
        Write-ColorOutput "NON INSTALLÉ" "Error"
        Write-ColorOutput "Installez Azure CLI depuis: https://learn.microsoft.com/cli/azure/install-azure-cli" "Warning"
        $allOk = $false
    }
    
    # Vérifier le dossier Terraform
    Write-Host "Vérification du dossier Terraform... " -NoNewline
    $tfPath = Join-Path -Path $PSScriptRoot -ChildPath "terraform"
    if (Test-Path $tfPath) {
        Write-ColorOutput "OK" "Success"
    } else {
        Write-ColorOutput "INTROUVABLE" "Error"
        Write-ColorOutput "Le dossier '$tfPath' n'existe pas" "Warning"
        $allOk = $false
    }
    
    return $allOk
}

# Fonction de connexion Azure
function Connect-AzureAccount {
    Write-ColorOutput "`n=== Connexion à Azure ===" "Info"
    
    # Vérifier si déjà connecté
    $account = az account show 2>$null
    if ($LASTEXITCODE -eq 0) {
        $accountInfo = $account | ConvertFrom-Json
        Write-ColorOutput "Déjà connecté avec le compte: $($accountInfo.user.name)" "Success"
        Write-ColorOutput "Subscription: $($accountInfo.name)" "Info"
        Write-ColorOutput "Tenant ID: $($accountInfo.tenantId)" "Info"
        
        $continue = Read-Host "Voulez-vous continuer avec ce compte? (O/N)"
        if ($continue -ne 'O' -and $continue -ne 'o') {
            az logout
            Start-AzureLogin
        }
    } else {
        Start-AzureLogin
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Erreur de connexion à Azure" "Error"
        return $false
    }
    
    return $true
}

# Fonction pour gérer la connexion Azure
function Start-AzureLogin {
    Write-ColorOutput "`nChoisissez votre mode de connexion:" "Info"
    Write-Host "1. Connexion normale (défaut)"
    Write-Host "2. Connexion avec un Tenant ID spécifique"
    Write-Host ""
    
    $choice = Read-Host "Votre choix (1 ou 2)"
    
    switch ($choice) {
        "2" {
            if ([string]::IsNullOrEmpty($script:TenantId)) {
                $script:TenantId = Read-Host "Entrez votre Tenant ID"
            }
            
            if ([string]::IsNullOrEmpty($script:TenantId)) {
                Write-ColorOutput "Tenant ID vide, connexion normale..." "Warning"
                az login
            } else {
                Write-ColorOutput "Connexion à Azure avec le Tenant: $script:TenantId" "Info"
                az login --tenant $script:TenantId
            }
        }
        default {
            Write-ColorOutput "Connexion à Azure..." "Info"
            az login
        }
    }
}

# Fonction de déploiement
function Start-TerraformDeploy {
    Write-ColorOutput "`n=== Déploiement de l'infrastructure ===" "Info"
    
    $tfPath = Join-Path -Path $PSScriptRoot -ChildPath "terraform"
    Push-Location $tfPath
    
    try {
        # Initialisation
        Write-ColorOutput "`nInitialisation de Terraform..." "Info"
        terraform init
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de l'initialisation Terraform"
        }
        
        # Plan
        Write-ColorOutput "`nCréation du plan de déploiement..." "Info"
        terraform plan -out=tfplan
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la création du plan"
        }
        
        # Confirmation
        Write-ColorOutput "`n⚠️  ATTENTION: Ce déploiement va créer des ressources sur Azure (coût ~43€/mois)" "Warning"
        $confirm = Read-Host "Voulez-vous continuer avec le déploiement? (O/N)"
        
        if ($confirm -eq 'O' -or $confirm -eq 'o') {
            Write-ColorOutput "`nDéploiement en cours... (cela peut prendre 5-10 minutes)" "Info"
            terraform apply tfplan
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "`n✓ Déploiement réussi!" "Success"
                Get-TerraformOutputs
            } else {
                throw "Erreur lors du déploiement"
            }
        } else {
            Write-ColorOutput "Déploiement annulé par l'utilisateur" "Warning"
        }
        
    } catch {
        Write-ColorOutput "Erreur: $($_.Exception.Message)" "Error"
    } finally {
        Pop-Location
    }
}

# Fonction pour récupérer les outputs
function Get-TerraformOutputs {
    Write-ColorOutput "`n=== Informations de connexion ===" "Info"
    
    $tfPath = Join-Path -Path $PSScriptRoot -ChildPath "terraform"
    
    if (-not (Test-Path $tfPath)) {
        Write-ColorOutput "Erreur: Le dossier terraform n'existe pas à $tfPath" "Error"
        return
    }
    
    Push-Location $tfPath
    
    try {
        $ipAddress = terraform output -raw public_ip_address 2>$null
        $password = terraform output -raw admin_password 2>$null
        $resourceGroup = terraform output -raw resource_group_name 2>$null
        $vmName = terraform output -raw vm_name 2>$null
        
        if ($ipAddress) {
            Write-ColorOutput "`nVM déployée avec succès:" "Success"
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            Write-Host "Resource Group : " -NoNewline; Write-ColorOutput $resourceGroup "Info"
            Write-Host "Nom de la VM   : " -NoNewline; Write-ColorOutput $vmName "Info"
            Write-Host "IP Publique    : " -NoNewline; Write-ColorOutput $ipAddress "Success"
            Write-Host "Utilisateur    : " -NoNewline; Write-ColorOutput "azureadmin" "Info"
            Write-Host "Mot de passe   : " -NoNewline; Write-ColorOutput $password "Warning"
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            # Sauvegarder dans un fichier
            $outputFile = "connexion_vm.txt"
            @"
=== Informations de connexion VM Windows ===
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Resource Group : $resourceGroup
Nom de la VM   : $vmName
IP Publique    : $ipAddress
Utilisateur    : azureadmin
Mot de passe   : $password

Commande RDP:
mstsc /v:$ipAddress

⚠️  IMPORTANT: Pensez à supprimer cette VM après utilisation pour éviter les frais!
Commande: .\Deploy-AzureVM.ps1 -Action Destroy
"@ | Out-File -FilePath $outputFile -Encoding UTF8
            
            Write-ColorOutput "`nℹ️  Informations sauvegardées dans: $outputFile" "Info"
            
            $rdpConnect = Read-Host "`nVoulez-vous vous connecter maintenant en RDP? (O/N)"
            if ($rdpConnect -eq 'O' -or $rdpConnect -eq 'o') {
                Start-RDPConnection -IPAddress $ipAddress
            }
        } else {
            Write-ColorOutput "Aucune infrastructure déployée trouvée" "Warning"
        }
        
    } catch {
        Write-ColorOutput "Erreur lors de la récupération des outputs: $($_.Exception.Message)" "Error"
    } finally {
        Pop-Location
    }
}

# Fonction de connexion RDP
function Start-RDPConnection {
    param([string]$IPAddress)
    
    Write-ColorOutput "`nLancement de la connexion RDP vers $IPAddress..." "Info"
    Start-Process mstsc -ArgumentList "/v:$IPAddress"
}

# Fonction de destruction
function Remove-TerraformInfrastructure {
    Write-ColorOutput "`n=== Suppression de l'infrastructure ===" "Warning"
    
    $tfPath = Join-Path -Path $PSScriptRoot -ChildPath "terraform"
    Push-Location $tfPath
    
    try {
        # Afficher ce qui sera détruit
        Write-ColorOutput "`nRessources qui seront supprimées:" "Info"
        terraform plan -destroy
        
        Write-ColorOutput "`n⚠️  ATTENTION: Cette action va SUPPRIMER toutes les ressources Azure créées" "Warning"
        $confirm = Read-Host "Êtes-vous sûr de vouloir continuer? Tapez 'SUPPRIMER' pour confirmer"
        
        if ($confirm -eq 'SUPPRIMER') {
            Write-ColorOutput "`nSuppression en cours..." "Info"
            terraform destroy -auto-approve
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "`n✓ Infrastructure supprimée avec succès!" "Success"
                
                # Nettoyer le fichier de connexion
                if (Test-Path "connexion_vm.txt") {
                    Remove-Item "connexion_vm.txt"
                    Write-ColorOutput "Fichier de connexion supprimé" "Info"
                }
            } else {
                throw "Erreur lors de la suppression"
            }
        } else {
            Write-ColorOutput "Suppression annulée" "Info"
        }
        
    } catch {
        Write-ColorOutput "Erreur: $($_.Exception.Message)" "Error"
    } finally {
        Pop-Location
    }
}

# ============================================================================
# PROGRAMME PRINCIPAL
# ============================================================================

Clear-Host
Write-ColorOutput @"
╔════════════════════════════════════════════════════════════╗
║  Script de déploiement VM Windows Server 2022 sur Azure   ║
║  Basé sur le projet Terraform de Pierre Baroni            ║
╚════════════════════════════════════════════════════════════╝
"@ "Info"

# Initialiser le Tenant ID comme variable de script
$script:TenantId = $TenantId

# Vérifier les prérequis
if (-not (Test-Prerequisites)) {
    Write-ColorOutput "`nImpossible de continuer sans les prérequis" "Error"
    exit 1
}

# Exécuter l'action demandée
switch ($Action) {
    'Deploy' {
        if (Connect-AzureAccount) {
            Start-TerraformDeploy
        }
    }
    
    'Destroy' {
        if (Connect-AzureAccount) {
            Remove-TerraformInfrastructure
        }
    }
    
    'GetInfo' {
        Get-TerraformOutputs
    }
    
    'Connect' {
        $tfPath = Join-Path -Path $PSScriptRoot -ChildPath "terraform"
        Push-Location $tfPath
        $ipAddress = terraform output -raw public_ip_address 2>$null
        Pop-Location
        
        if ($ipAddress) {
            Start-RDPConnection -IPAddress $ipAddress
        } else {
            Write-ColorOutput "Aucune VM déployée trouvée" "Error"
        }
    }
}

Write-ColorOutput "`n═══════════════════════════════════════════════════════════" "Info"
Write-ColorOutput "Script terminé" "Success"
Write-ColorOutput "═══════════════════════════════════════════════════════════`n" "Info"

# ============================================================================
# RAPPEL DE SUPPRESSION (uniquement après un déploiement réussi)
# ============================================================================

if ($Action -eq 'Deploy') {
    # Vérifier si des ressources ont été déployées
    $tfPath = Join-Path -Path $PSScriptRoot -ChildPath "terraform"
    Push-Location $tfPath
    $ipAddress = terraform output -raw public_ip_address 2>$null
    Pop-Location
    
    if ($ipAddress) {
        Write-ColorOutput "`n⚠️  RAPPEL IMPORTANT ⚠️" "Warning"
        Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Warning"
        Write-ColorOutput "Cette VM coûte environ 43€/mois sur Azure" "Warning"
        Write-ColorOutput "N'oubliez pas de la supprimer après vos tests!" "Warning"
        Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" "Warning"
        
        $destroyNow = Read-Host "Voulez-vous détruire l'infrastructure MAINTENANT? (O/N)"
        
        if ($destroyNow -eq 'O' -or $destroyNow -eq 'o') {
            Write-ColorOutput "`n🔄 Lancement de la suppression..." "Info"
            Start-Sleep -Seconds 2
            Remove-TerraformInfrastructure
        } else {
            Write-ColorOutput "`n💡 Pour supprimer plus tard, utilisez:" "Info"
            Write-ColorOutput "   .\Deploy-AzureVM.ps1 -Action Destroy`n" "Info"
        }
    }
}

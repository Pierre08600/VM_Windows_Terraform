\# Déploiement d'une VM Windows avec Terraform



\*\*Auteur :\*\* Pierre Baroni  

\*\*Date :\*\* Octobre 2025  

\*\*Contexte :\*\* Projet d'apprentissage DevOps



---



\## À propos



Ce projet fait partie de mon apprentissage des technologies DevOps. J'ai voulu comprendre comment déployer automatiquement une infrastructure sur Azure avec Terraform.



\*\*Ce que j'ai appris :\*\*

\- Les bases de Terraform (provider, resources, outputs)

\- La gestion d'infrastructure cloud avec Azure

\- Les concepts réseau (VNet, Subnet, NSG)

\- L'automatisation avec Infrastructure as Code



---



\##  Ce que fait ce projet



Déploiement automatisé d'une machine virtuelle Windows Server 2022 sur Azure avec :

\- Un réseau virtuel isolé

\- Une IP publique pour l'accès

\- Un pare-feu (NSG) configuré pour RDP

\- Un mot de passe généré automatiquement



---



\##  Technologies utilisées



\- \*\*Terraform\*\* - Pour l'automatisation

\- \*\*Azure\*\* - Cloud provider

\- \*\*PowerShell\*\* - Pour les commandes

\- \*\*Git\*\* - Versioning du code



---



\##  Structure du projet

```

## 📁 Structure du projet
```
VM_Windows_Terraform/
│
├── Deploy-AzureVM.ps1          # Script PowerShell d'automatisation (RACINE DU PROJET)
├── README.md                    # Documentation principale
├── .gitignore                   # Fichiers à exclure de Git
│
├── terraform/                   # Configuration Terraform
│   ├── provider.tf             # Configuration Azure Provider
│   ├── variables.tf            # Variables du projet
│   ├── main.tf                 # Ressources principales (VM, VNet, NSG, IP)
│   └── outputs.tf              # Informations de sortie
│
├── docs/                        # Documentation complémentaire
│
└── screenshots/                 # Captures d'écran du processus


**⚠️ Important :** Le script `Deploy-AzureVM.ps1` doit être placé à la racine du projet, 
au même niveau que le dossier `terraform/`, PAS à l'intérieur.
```

\##  Comment utiliser


\### Prérequis

\- Terraform installé

\- Azure CLI installé

\- Un compte Azure



\### Déploiement

```powershell

\# Se connecter à Azure

az login



\# Initialiser Terraform

cd terraform

terraform init



\# Voir ce qui sera créé

terraform plan



\# Déployer

terraform apply

```



\### Connexion à la VM



Après le déploiement :

```powershell

\# Récupérer l'IP

terraform output public\_ip\_address



\# Récupérer le mot de passe

terraform output -raw admin\_password



\# Se connecter en RDP

mstsc /v:\[IP\_PUBLIQUE]

```



\*\*Identifiants :\*\*

\- Utilisateur : `azureadmin`

\- Mot de passe : celui affiché par la commande ci-dessus



---



\##  Suppression



\*\*Important :\*\* Supprimer l'infrastructure après les tests pour éviter les frais !

```powershell

cd terraform

terraform destroy

```



---



\##  Coût estimé



\- VM Standard\_B2s : ~40€/mois

\- IP publique : ~3€/mois

\- \*\*Total : ~43€/mois\*\*



Attention: il faut penser à supprimer la VM après vos tests !



---



\##  Documentation



Le dossier `screenshots/` contient 20 captures documentant chaque étape du processus, de la création à la connexion RDP.



---



\##  Ce que j'ai compris



\*\*Infrastructure as Code :\*\*

\- Le code décrit l'infrastructure souhaitée

\- Terraform gère la création automatique

\- Tout est reproductible et versionnable



\*\*Azure :\*\*

\- Organisation en Resource Groups

\- Réseaux virtuels et sous-réseaux

\- Sécurité avec Network Security Groups



\*\*DevOps :\*\*

\- Automatisation des déploiements

\- Documentation du processus

\- Versioning avec Git



---



\##  Ressources utilisées



\- \[Documentation Terraform](https://www.terraform.io/docs)

\- \[Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

\- \[Documentation Azure](https://learn.microsoft.com/azure/)

## 🚀 Script d'automatisation PowerShell

Un script PowerShell complet a été ajouté pour automatiser toutes les opérations !

### ✨ Fonctionnalités

- ✅ Vérification automatique des prérequis
- ✅ Connexion Azure avec support Tenant ID
- ✅ Déploiement automatisé complet
- ✅ Connexion RDP en un clic
- ✅ Gestion du cycle de vie (Deploy/Destroy)
- ✅ Interface colorée et intuitive

### 📋 Utilisation

**Déploiement complet :**
```powershell
.\Deploy-AzureVM.ps1 -Action Deploy
```

**Avec un Tenant Azure spécifique :**
```powershell
.\Deploy-AzureVM.ps1 -Action Deploy -TenantId "votre-tenant-id"
```

**Récupérer les informations de connexion :**
```powershell
.\Deploy-AzureVM.ps1 -Action GetInfo
```

**Se connecter en RDP automatiquement :**
```powershell
.\Deploy-AzureVM.ps1 -Action Connect
```

**Supprimer l'infrastructure :**
```powershell
.\Deploy-AzureVM.ps1 -Action Destroy
```



---



\##  Contact



\*\*Pierre Baroni\*\*  

Email : pierre.baroni@free.fr



Ce projet fait partie de mon parcours d'apprentissage en DevOps.



---



\_Projet réalisé dans un cadre d'apprentissage - Octobre 2025\_


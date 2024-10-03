#!/bin/bash

set -e  # Arrêter le script en cas d'erreur

# Fonction pour afficher un message en couleur
show() {
    echo -e "\033[1;35m$1\033[0m"
}

# Fonction pour gérer une interruption (Ctrl+C)
trap 'show "Script interrupted. Exiting..."; exit 1;' INT

# Logo
show "Downloading and displaying logo..."
curl -s https://raw.githubusercontent.com/macfly-base/logo/main/logo.sh | bash
sleep 3

# Installation de NVM, Node et npm via un script externe
show "Installing NVM, Node, and npm..."
source <(wget -qO - https://raw.githubusercontent.com/macfly-base/installation/main/node.sh)

# Installation de yarn
show "Installing Yarn..."
npm install -g yarn

# Clonage et configuration de Hyperlane
show "Installing Hyperlane..."
rm -rf hyperlane-monorepo
git clone https://github.com/hyperlane-xyz/hyperlane-monorepo.git

# Vérification si le clonage a réussi
if [ ! -d "hyperlane-monorepo" ]; then
    show "Error: Failed to clone the Hyperlane repository."
    exit 1
fi

cd hyperlane-monorepo
yarn install

# Vérification si l'installation de yarn a réussi
if [ $? -ne 0 ]; then
    show "Error: Yarn installation failed."
    exit 1
fi

yarn build && cd typescript/cli

# Lecture des clés privées et des adresses de l'utilisateur
read -s -p "Enter your private key: " PVT_KEY
echo  # Nouvelle ligne après la saisie masquée
read -p "Enter your wallet address of the above private key: " WALLET

# Exporter la clé privée
export HYP_KEY="$PVT_KEY"

# Créer le répertoire de configuration si nécessaire
mkdir -p ./configs

# Création du fichier YAML pour la configuration de déploiement
cat <<EOF > ./configs/warp-route-deployment.yaml
base:
  interchainSecurityModule:
    modules:
      - relayer: "$WALLET"
        type: trustedRelayerIsm
      - domains: {}
        owner: "$WALLET"
        type: defaultFallbackRoutingIsm
    threshold: 1
    type: staticAggregationIsm
  isNft: false
  mailbox: "0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D"
  owner: "$WALLET"
  token: "0x532f27101965dd16442e59d40670faf5ebb142e4"
  type: collateral
zoramainnet:
  interchainSecurityModule:
    modules:
      - relayer: "$WALLET"
        type: trustedRelayerIsm
      - domains: {}
        owner: "$WALLET"
        type: defaultFallbackRoutingIsm
    threshold: 1
    type: staticAggregationIsm
  isNft: false
  mailbox: "0xF5da68b2577EF5C0A0D98aA2a58483a68C2f232a"
  owner: "$WALLET"
  type: synthetic
EOF

# Affichage et déploiement
show "Deploying using Hyperlane..."
yarn hyperlane warp deploy

# Vérification du succès du déploiement
if [ $? -eq 0 ]; then
    show "Deployment completed successfully!"
else
    show "Error: Deployment failed."
    exit 1
fi

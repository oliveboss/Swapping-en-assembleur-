# Swapping-en-assembleur-
Projet de swapping en masm(.asm) avec gestions des memoires 
# Swapping en Assembleur avec MASM - Gestion de la Mémoire 🖥️💾

## Description
Le projet **Swapping en Assembleur avec MASM** consiste en l'implémentation d'une méthode de **swapping** (échange de données entre la mémoire principale et le disque dur) en utilisant le langage **assembleur MASM**. Ce projet met en œuvre la gestion de la mémoire pour optimiser l'utilisation des ressources limitées de la machine. 

Le **swapping** est une technique essentielle dans les systèmes d'exploitation, permettant de déplacer des portions de données (ou pages) entre la mémoire principale (RAM) et un espace de stockage secondaire (tel qu'un disque dur) afin de maximiser la performance du système.

Ce projet permet de comprendre comment les systèmes d'exploitation gèrent la mémoire de manière basse-niveau et offre une opportunité d'apprendre la manipulation de la mémoire et les optimisations liées au swapping.

## Fonctionnalités
- **Gestion de la mémoire** : Implémentation d'une gestion dynamique de la mémoire avec MASM, simulant le swapping de pages mémoire.
- **Échange de données** : Gestion de l'échange entre la mémoire physique et le disque, permettant de libérer de l'espace en mémoire.
- **Optimisation** : Techniques d'optimisation pour éviter les problèmes de fragmentation mémoire.
- **Système d'adressage** : Simulation de l'adressage mémoire pour permettre la gestion efficace de la mémoire virtuelle.

## Technologies utilisées
- **MASM (Microsoft Macro Assembler)** : Langage utilisé pour l'implémentation du projet.
- **Système d'exploitation (Windows)** : Le projet a été conçu pour être exécuté sous un système Windows avec MASM.
- **Mémoire virtuelle** : Simulation de la mémoire virtuelle pour implémenter le mécanisme de swapping.

## Architecture du projet
Le projet est organisé en plusieurs modules, chacun responsable de certaines fonctionnalités clés :

1. **Module de gestion de la mémoire** : Gère la mémoire et permet de savoir quelles zones de mémoire sont allouées et lesquelles peuvent être échangées.
2. **Module de swapping** : Implémente les opérations de swap entre la mémoire physique et la mémoire virtuelle (disque).
3. **Module de gestion des pages** : Gère les pages mémoire, leur allocation, leur échange, etc.
4. **Module d'optimisation** : Effectue des optimisations pour minimiser les accès disque en maximisant l'utilisation de la mémoire physique.

## Installation

### Prérequis
- **MASM** : Assurez-vous que le **MASM** (Microsoft Macro Assembler) est installé sur votre machine. Vous pouvez le télécharger depuis le site officiel de Microsoft ou utiliser des outils tiers qui fournissent MASM.
- **Windows** : Ce projet est conçu pour être utilisé sous un système d'exploitation Windows.
- **Éditeur de texte** : Vous pouvez utiliser un éditeur comme **Visual Studio Code**, **Notepad++**, ou tout autre éditeur qui supporte la syntaxe MASM.

### Étapes d'installation
1. **Clonez le dépôt sur votre machine** :
   ```bash
   git clone https://github.com/oliveboss/Swapping-en-assembleur.git

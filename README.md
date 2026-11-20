# Scripts Roblox Lua

Collection de scripts Lua conçus pour différents jeux Roblox.

> [!WARNING]
> Utilisez ces scripts uniquement dans des environnements pour lesquels vous disposez d’une autorisation. Le respect des conditions d’utilisation de Roblox et des règles des expériences concernées est de votre responsabilité.

## Scripts disponibles

| Fichier | Jeu |
|---|---|
| `arsenal.lua` | Arsenal |
| `mm2.lua` | Murder Mystery 2 |
| `rivals.lua` | Rivals |
| `c6r6.lua` | Loader |
| `flick.lua` | Flick |
| `sniper-arena.lua` | Sniper Arena |
| `steal-a-egg.lua` | Steal an Egg |
| `universal.lua` | Script universel |

## Prérequis

- Un interpréteur Lua compatible avec Luau
- Un environnement Roblox autorisé
- Une connaissance des API Roblox auxquelles le script accède

Certains scripts sont obfusqués ou protégés. Leur fonctionnement exact doit être vérifié avant toute utilisation.

## Utilisation

1. Ouvrez le script correspondant au jeu souhaité.
2. Vérifiez son contenu et les autorisations nécessaires.
3. Chargez-le uniquement dans un environnement autorisé.

## Ajouter un script

1. Forkez le dépôt.
2. Créez une branche :

```bash
git checkout -b ajout-nom-du-script
```

3. Ajoutez le fichier Lua à la racine du dépôt.
4. Documentez :
   - le jeu concerné
   - les fonctionnalités
   - les dépendances
   - les API externes utilisées
   - les limites et incompatibilités connues

5. Donnez au fichier un nom clair :

```text
nom-du-jeu.lua
```

6. Exécutez une vérification Lua/Luau si possible.
7. Ouvrez une Pull Request avec une description précise.

## Convention de nommage

- Utilisez uniquement des minuscules.
- Séparez les mots par des tirets.
- Évitez les noms ambigus ou les espaces.
- Préfixez les variantes expérimentales par `experimental-`.

Exemple :

```text
arsenal.lua
murder-mystery-2.lua
experimental-universal.lua
```

## Contributions attendues

Les contributions suivantes sont les bienvenues :

- amélioration du README ;
- ajout de commentaires aux scripts ;
- suppression ou remplacement d’éléments obfusqués ;
- corrections de compatibilité ;
- documentation des fonctionnalités ;
- ajout de tests ou d’exemples ;
- rapport d’un script cassé ou obsolète.

## Sécurité

Ne publiez jamais :

- des mots de passe ;
- des jetons ;
- des cookies ;
- des identifiants Roblox ;
- des webhooks ;
- des données personnelles ;
- des clés ou secrets privés.

Signalez toute fonctionnalité qui collecte ou transmet des données personnelles.

## Licence

Aucune licence n’est actuellement définie. Avant toute réutilisation ou contribution significative, définissez une licence ou demandez l’autorisation au propriétaire du dépôt.

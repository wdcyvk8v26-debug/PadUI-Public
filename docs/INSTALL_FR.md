# Installer PadUI

1. Fermer tous les clients Ryzom.
2. Sauvegarder le dossier `user` existant et les paramètres d’interface des personnages.
3. Extraire le paquet. Copier tous les fichiers **contenus dans son dossier `user`** dans le dossier `user` de Ryzom et remplacer les fichiers correspondants. Ne pas créer de dossier imbriqué `user/user`.
4. Redémarrer le client. Répéter pour les installations séparées.

Exemple Windows : `C:\Spiele\steamapps\common\Ryzom\user`. Sous Linux et macOS, le chemin dépend de l’installation ; vérifier le dossier de données accessible en écriture utilisé par le client.

Ouvrir les réglages PadUI depuis la liste des fenêtres. Langue, accents, transparence et dispositions sont centralisés, ainsi que la taille de l’équipe et des minuteurs compacts. Les minuteurs proposent compte à rebours et chronomètre ; changer de mode remet le minuteur à zéro.

Installer `padui_mob_catalog.lua` et `padui_mobs.lua` directement dans `user`. Aucun JSON BM séparé n’est nécessaire. Les noms de boss appris et de nombreux réglages sont sauvegardés par personnage via Ryzom. Quitter normalement pour les enregistrer.

Pour une mise à jour, remplacer tous les fichiers fournis. Restaurer une ancienne version ne réinitialise pas automatiquement les couleurs et réglages enregistrés. Utiliser la sauvegarde pour une restauration complète.

Pour signaler un problème, indiquer version PadUI, système, version exacte du client et étapes de reproduction. Retirer les informations privées des journaux.

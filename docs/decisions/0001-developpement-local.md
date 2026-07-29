# ADR-0001 : Développement local

## Statut

Acceptée

## Date

2026-06-21

## Contexte

Le développement du Dashboard LJ était réalisé directement sur GitHub Pages.

Chaque modification nécessitait :

- Commit
- Push
- GitHub Actions
- Déploiement
- Tests

Les indisponibilités ponctuelles de GitHub Pages ralentissaient fortement les phases de développement.

## Décision

Le développement est désormais réalisé en local avec :

- Visual Studio Code
- Live Server

GitHub devient uniquement la plateforme de gestion de versions et de publication.

## Conséquences

Positives :

- Tests immédiats
- Débogage facilité
- Développement indépendant de GitHub

Négatives :

- Nécessite un environnement local configuré.
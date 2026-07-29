# ADR 0004 - Modularisation du moteur PDF

- **Statut :** Acceptée
- **Date :** 2026-07-20
- **Sprint :** Sprint 4
- **Auteur :** Loïc J.

---

# Contexte

Depuis les premiers sprints, l'export PDF a progressivement évolué.

Les fonctions principales (`buildCover`, `drawFooter`, `drawFiligrane`, `buildSummary`, etc.) ont été refactorisées afin de :

- supprimer les valeurs codées en dur ;
- centraliser les constantes dans `pdfTheme.js` ;
- améliorer la lisibilité du code ;
- faciliter les évolutions futures.

Le fichier `nouveau_doc.js` reste néanmoins volumineux et regroupe encore plusieurs responsabilités.

Il devient souhaitable de préparer une architecture plus modulaire.

---

# Décision

À partir du Sprint 4, le moteur PDF sera progressivement découpé en plusieurs modules spécialisés.

Chaque module aura une responsabilité unique.

Le découpage sera réalisé progressivement afin d'éviter toute régression.

Aucun changement fonctionnel ne sera introduit lors de cette phase.

---

# Architecture cible

```text
js/
│
├── pdf/
│   ├── pdfGenerator.js
│   ├── pdfTheme.js
│   ├── pdfLayout.js
│   ├── pdfText.js
│   ├── pdfResources.js
│   ├── pdfCover.js
│   ├── pdfSummary.js
│   ├── pdfCharts.js
│   ├── pdfDecoration.js
│   └── pdfFooter.js
```

Chaque fichier regroupera une responsabilité clairement identifiée.

---

# Responsabilités

## pdfGenerator.js

Chef d'orchestre de l'export PDF.

Responsabilités :

- création du document jsPDF ;
- chargement des ressources ;
- appel des différentes étapes ;
- sauvegarde du PDF.

Il ne contiendra aucun dessin.

---

## pdfTheme.js

Centralise toute l'identité graphique.

Exemples :

- couleurs ;
- tailles de police ;
- tailles des logos ;
- paramètres graphiques.

---

## pdfLayout.js

Centralise uniquement les positions.

Exemples :

- marges ;
- espacements ;
- coordonnées ;
- alignements.

---

## pdfText.js

Centralise tous les textes utilisés dans le PDF.

Exemples :

- titre ;
- sous-titre ;
- filigrane ;
- pied de page.

---

## pdfResources.js

Gestion des ressources graphiques.

Exemples :

- chargement des images ;
- mise en cache ;
- vérification des ressources.

---

## pdfCover.js

Construction de la page de couverture.

---

## pdfSummary.js

Construction du sommaire.

---

## pdfCharts.js

Construction des pages contenant les graphiques.

---

## pdfDecoration.js

Décoration des pages :

- filigrane ;
- numérotation ;
- footer.

---

# Objectifs

Cette architecture doit permettre :

- une meilleure lisibilité ;
- une maintenance simplifiée ;
- une meilleure réutilisabilité ;
- une évolution plus rapide du projet.

---

# Conséquences

Les évolutions futures seront réalisées module par module.

Le comportement du Dashboard ne devra jamais être modifié lors d'un simple découpage de code.

Chaque étape devra être validée par un test de non-régression.

---

# Principe retenu

Le Sprint 4 privilégie la stabilité.

Avant toute nouvelle fonctionnalité :

- améliorer l'architecture ;
- réduire le couplage ;
- renforcer la modularité.

Cette stratégie doit permettre au projet Dashboard LJ de continuer à évoluer tout en restant simple à maintenir.
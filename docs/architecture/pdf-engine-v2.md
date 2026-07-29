# Architecture du moteur PDF

**Projet :** Dashboard LJ

**Version :** 2.0

**Dernière mise à jour :** Juillet 2026

---

# 1. Objectif

Le moteur PDF est responsable de la génération complète du rapport produit par Dashboard LJ.

Son objectif est de produire un document homogène, facilement maintenable et indépendant de l'interface utilisateur.

L'architecture repose sur plusieurs modules spécialisés, chacun ayant une responsabilité unique.

---

# 2. Vue d'ensemble

```text
generatePDF()

│
├── loadResources()
│
├── buildCover()
│
├── buildCharts()
│
├── buildHtmlPages()
│
├── buildSummary()
│
├── decoratePages()
│      │
│      ├── drawFiligrane()
│      │
│      └── drawFooter()
│
└── pdf.save()
```

Le rôle de `generatePDF()` est uniquement d'orchestrer les différentes étapes.

Il ne contient pas la logique de dessin.

---

# 3. Flux d'exécution

```text
Utilisateur

      │

      ▼

generatePDF()

      │

      ▼

Chargement des ressources

      │

      ▼

Construction de la couverture

      │

      ▼

Création des pages graphiques

      │

      ▼

Construction des pages HTML

      │

      ▼

Construction du sommaire

      │

      ▼

Décoration de toutes les pages

      │

      ├── Filigrane

      └── Footer

      │

      ▼

Sauvegarde du document PDF
```

---

# 4. Responsabilités

## generatePDF()

Responsable de l'orchestration générale.

Il :

- crée le document jsPDF ;
- charge les ressources ;
- appelle les différents modules ;
- sauvegarde le document.

---

## loadResources()

Charge les ressources graphiques.

Actuellement :

- logo ;
- bandeau.

---

## buildCover()

Construit la page de couverture.

Responsabilités :

- bandeau ;
- logo ;
- titre ;
- sous-titre ;
- informations ;
- signature.

---

## buildCharts()

Construit les pages contenant les graphiques.

Responsabilités :

- ajout des graphiques ;
- pagination.

---

## buildHtmlPages()

Ajoute les contenus HTML convertis en PDF.

---

## buildSummary()

Construit automatiquement le sommaire.

---

## decoratePages()

Décore toutes les pages du document.

Responsabilités :

- appel de `drawFiligrane()`;
- appel de `drawFooter()`.

---

## drawFiligrane()

Dessine le filigrane graphique.

Selon la page :

- logo centré ;
- logo compact ;
- logo de couverture ;
- texte "DOCUMENT INTERNE".

---

## drawFooter()

Dessine le pied de page.

Responsabilités :

- ligne de séparation ;
- texte Dashboard LJ ;
- numérotation.

---

# 5. Ressources

Le moteur PDF utilise actuellement les ressources suivantes.

## Logo

Utilisé par :

- couverture ;
- filigrane.

---

## Bandeau

Utilisé par :

- couverture ;
- pages graphiques.

---

# 6. Configuration graphique

Toute l'identité graphique est centralisée dans `PDF_THEME`.

```text
PDF_THEME

├── colors
│
├── fonts
│
├── cover
│
├── summary
│
├── footer
│
└── watermark
```

Cette centralisation permet :

- d'éviter les valeurs codées en dur ;
- d'harmoniser le rendu graphique ;
- de faciliter les évolutions.

---

# 7. Principes d'architecture

Le moteur PDF respecte les principes suivants.

## Responsabilité unique

Chaque fonction possède une responsabilité clairement identifiée.

---

## Séparation des responsabilités

Le thème graphique est indépendant :

- de la logique ;
- des ressources ;
- du contenu.

---

## Modularité

Chaque évolution doit pouvoir être réalisée sans modifier les autres modules.

---

## Non-régression

Toute évolution est validée par un test complet de génération du PDF.

---

# 8. Évolutions prévues

Le Sprint 4 prévoit la création progressive des modules suivants.

```text
pdf/

├── pdfGenerator.js
├── pdfTheme.js
├── pdfLayout.js
├── pdfText.js
├── pdfResources.js
├── pdfCover.js
├── pdfSummary.js
├── pdfCharts.js
├── pdfDecoration.js
└── pdfFooter.js
```

Le découpage sera réalisé progressivement afin d'éviter toute régression.

---

# 9. Philosophie du projet

Le projet Dashboard LJ privilégie :

- une architecture claire ;
- des modules spécialisés ;
- une documentation à jour ;
- des évolutions progressives ;
- des tests systématiques.

L'objectif est de construire un moteur PDF robuste, maintenable et évolutif.

# 10. Architecture du moteur PDF
  ================================ 


Moteur PDF
###### Le moteur PDF est orchestré par generatePDF(). Cette fonction coordonne les différentes étapes de construction du document en s'appuyant sur des modules spécialisés. Le schéma ci-dessous représente l'état actuel de cette orchestration.

generatePDF()         → nouveau_doc.js
│
├── buildCover()      → pdfCover.js        ✅
├── buildSummary()    → pdfSummary.js      ✅
├── buildCharts()     → pdfCharts.js       ✅
├── buildHtmlPages()  → pdfHtmlPages.js    ✅
├── decoratePages()   → pdfDecoration.js   ✅
└── pdf.save()

### Légende
- ✅ : module externalisé
- 🚧 : encore dans nouveau_doc.js

# 11. Architecture modulaire du moteur pdf suite au sprint 5.4

nouveau_doc.js
│
├── Chargement des ressources
├── Orchestration de la génération
├── Gestion du clic utilisateur
└── Point d'entrée

pdfTheme.js
├── Thème PDF

pdfGenerator.js
├── Point d'entrée du moteur

pdfCover.js
├── Couverture

pdfCharts.js
├── Pages graphiques

pdfHtmlPages.js
├── Pages HTML

pdfSummary.js
├── Sommaire

pdfDecoration.js
├── Filigranes et décorations

pdfFooter.js
├── Pied de page
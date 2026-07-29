# Convention de codage Dashboard LJ

## Configuration

Lorsqu'une fonction utilise plusieurs propriétés d'un même objet de configuration
(PDF_THEME, PDF_LAYOUT, etc.), on crée un alias local.

Exemple :

const { footer, fonts } = PDF_THEME;

Cette convention améliore la lisibilité et évite la répétition de chemins longs
(PDF_THEME.footer.fontSize, PDF_THEME.footer.textColor...).
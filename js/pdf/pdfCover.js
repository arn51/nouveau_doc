/******************************************************************************
 * Dashboard LJ
 * pdfCover.js
 * Description :
 *      Fonctions de construction de la couverture du rapport PDF
 * 
 * Auteur :
 *      Loîc J.
 * 
 * Depuis :
 *      Sprint 4.4
 ******************************************************************************/

 /******************************************************************************
 * drawBandeau()
 *
 * Dessine le bandeau supérieur utilisé sur :
 *  - la couverture
 *  - les pages contenant des graphiques
 ******************************************************************************/
async function drawBandeau(pdf, bandeauImg, pageWidth) {
    const bandeauHeight = 20;
    pdf.addImage(bandeauImg, "PNG", 0, 0, pageWidth, bandeauHeight);
    return bandeauHeight;
}

/******************************************************************************
 * drawPageTitle()
 *
 * Dessine le titre des pages graphiques.
 ******************************************************************************/
function drawPageTitle(pdf, title, yPosition, pageWidth) {
    pdf.setFont(
        PDF_THEME.fonts.family.default, 
        PDF_THEME.fonts.style.bold
    );
    pdf.setFontSize(16);
    pdf.text(title, pageWidth / 2, yPosition + 14, { align: "center" });
    return yPosition + 22;
}

/******************************************************************************
 * buildcover()
 * 
 * Construit la page de couverture du rapport PDF
 ******************************************************************************/
async function buildCover(pdf, resources) {

    const pageWidth = pdf.internal.pageSize.getWidth();
    const pageHeight = pdf.internal.pageSize.getHeight();

    const bandeauHeight = await drawBandeau(
        pdf,
        resources.bandeau,
        pageWidth
    );

    const logoWidth = PDF_THEME.cover.logo.width;
	const logoHeight = PDF_THEME.cover.logo.height;

    pdf.addImage(
        resources.logo,
        "PNG",
        pageWidth - logoWidth - 10,
        1,
        logoWidth,
        logoHeight
    );

    // Fond
    pdf.setFillColor(
        ...PDF_THEME.colors.background
    );
    pdf.rect(
        0,
        bandeauHeight,
        pageWidth,
        pageHeight - bandeauHeight,
        "F"
    );

    // Titre
    pdf.setFont(
        PDF_THEME.fonts.family.default,
        PDF_THEME.fonts.style.bold
    );
    pdf.setFontSize(
        PDF_THEME.cover.title.size 
    );
    pdf.setTextColor(
        ...PDF_THEME.colors.textPrimary
    );

    pdf.text(
        "Rapport d'analyse",
        pageWidth/2,
        bandeauHeight + 40,
        {align:"center"}
    );

    // Sous-titre

    pdf.setFont(
        PDF_THEME.fonts.family.default,
        PDF_THEME.fonts.style.normal
    );
    pdf.setFontSize(
        PDF_THEME.cover.subtitle.size
    );
    pdf.setTextColor(
        ...PDF_THEME.colors.textSecondary
    );

    pdf.text(
        "Synthèse des indicateurs — Dashboard LJ",
        pageWidth/2,
        bandeauHeight + 60,
        {align:"center"}
    );

    // Ligne

    pdf.setDrawColor(
        ...PDF_THEME.colors.separator
    );
    pdf.setLineWidth(0.6);

    pdf.line(
        pageWidth/2 -30,
        bandeauHeight +70,
        pageWidth/2 +30,
        bandeauHeight +70
    );

    // Informations

    pdf.setFontSize(
        PDF_THEME.cover.info.size
    );

    pdf.setTextColor(
        ...PDF_THEME.colors.textMuted
    );

    let infoY = bandeauHeight +95;

    pdf.text("Document interne",20,infoY);

    infoY+=8;

    pdf.text("Auteur : Loïc J.",20,infoY);

    infoY+=8;

    pdf.text(
        "Date : " +
        new Date().toLocaleDateString("fr-FR"),
        20,
        infoY
    );

    // Signature

    pdf.setFont(
        PDF_THEME.fonts.family.default,
        PDF_THEME.fonts.style.italic
    );

    pdf.setFontSize(
        PDF_THEME.cover.signature.size
    );

    pdf.text(
        "Dashboard LJ",
        pageWidth-20,
        bandeauHeight+95,
        {
            align:"right"
        }
    );

}
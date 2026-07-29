/******************************************************************************
 * Dashboard LJ
 * PDF Footer
 * Description :
 *      Création du bas de page
 * 
 * Auteur :
 *      Loîc J.
 * 
 * Depuis :
 *      Sprint 4.3
 ******************************************************************************/
// Footer premium
function drawFooter(pdf, pageNumber, totalPages, pageWidth, pageHeight) {
    const {
        footer, 
        fonts 
    } = PDF_THEME;

    pdf.setDrawColor(
        ...footer.drawColor
    );
    pdf.setLineWidth(0.4);
    
    pdf.line(
        footer.marginLeft, 
        pageHeight - 30, 
        pageWidth - footer.marginRight, 
        pageHeight - 30
    );

    pdf.setFont(
        fonts.family.default, 
        fonts.style.normal 
    );

    pdf.setFontSize(
        footer.fontSize
    );

    pdf.setTextColor(
        ...footer.textColor
    );

    pdf.text(
        "Dashboard LJ — Rapport interne", 
        footer.marginLeft, 
        pageHeight - 15
    );

    pdf.text(
        `Page ${pageNumber} / ${totalPages}`, 
        pageWidth - footer.marginRight, 
        pageHeight - 15, 
        { align: "right" }
    );
}
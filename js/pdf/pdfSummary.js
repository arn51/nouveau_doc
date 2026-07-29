/******************************************************************************
 * Dépendances
 * 
 * Utilise :
 *     - PDF_THEME
 *     - jsPDF
 * 
 * Appelée par :
 *    - generatePDF()
 ******************************************************************************/
async function buildSummary(pdf, resources) {

    const pageWidth = pdf.internal.pageSize.getWidth();

    pdf.addPage();

    const bandeauHeight = await drawBandeau(
        pdf,
        resources.bandeau,
        pageWidth
    );

    pdf.setFont(
        PDF_THEME.fonts.family.default, 
        PDF_THEME.fonts.style.bold
    );
    pdf.setFontSize(
        PDF_THEME.summary.title.size
    );

    pdf.text(
        "Sommaire",
        pageWidth / 2,
        bandeauHeight + 30,
        { align: "center" }
    );

    pdf.setFont(
        PDF_THEME.fonts.family.default, 
        PDF_THEME.fonts.style.normal
    );
    pdf.setFontSize(
        PDF_THEME.summary.item.size
    );

    const sommaire = [
        "Page 1 — Page de couverture",
        "Page 2 — Graphique Barres",
        "Page 3 — Graphique Radar",
        "Page 4 — Graphique Donut",
        "Page 5 — Vue Cartes",
        "Page 6 — Tableau des Badges",
        "Page 7 — Sommaire"
    ];

    let y = bandeauHeight + 50;

    sommaire.forEach(line => {

        pdf.text(line, 60, y);

        y += 7;

    });

}
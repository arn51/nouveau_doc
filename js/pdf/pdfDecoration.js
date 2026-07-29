/******************************************************************************
 * drawfiligrane()
 * 
 * Construit et positionne le filigrane en fonction de la page
 ******************************************************************************/

function drawFiligrane(pdf, logoImg, pageNumber) {
    const {
    watermark,
    fonts
} = PDF_THEME;

    const pageWidth  = pdf.internal.pageSize.getWidth();
    const pageHeight = pdf.internal.pageSize.getHeight();

    let logoSize = watermark.logo.standardSize;
    let textSize = watermark.label.standardSize;
    
    if (pageNumber === 1) {
        logoSize = watermark.logo.coverSize;
    }

    if (pageNumber === 5 || pageNumber === 7) {
        logoSize = watermark.logo.compactSize;
        textSize = watermark.label.compactSize;
    }

    let x = (pageWidth - logoSize) / 2;
    let y = (pageHeight - logoSize) / 2;

    if (pageNumber === 1) {

        x = pageWidth - logoSize - 20;
        y = pageHeight - logoSize - 25;

    }

    if (pageNumber === 5 || pageNumber === 7) {

        x = pageWidth - logoSize - 20;
        y = pageHeight - logoSize - 20;

    }
	
    // Logo
    pdf.addImage(
        logoImg,
        "PNG",
        x,
        y,
        logoSize,
        logoSize
    );

    // Texte (sauf couverture)
    if (pageNumber !== 1) {

        pdf.setFont(
            fonts.family.default, 
            fonts.style.bold
        );
        
        console.log(
            "Page :", pageNumber,
            "textSize :", textSize
        );

        pdf.setFontSize(textSize);

        pdf.setTextColor(
            ...watermark.colors.text
        );

        pdf.text(
            "DOCUMENT INTERNE",
            pageWidth / 2,
            pageHeight / 2,
            {
                align: "center",
                angle: 45
            }
        );
    }
}

/******************************************************************************
 * decoratePages()
 * 
 * Ajoute les éléments de décoration sur toutes les pages.
 ******************************************************************************/
async function decoratePages(pdf, resources) {

    const pageWidth = pdf.internal.pageSize.getWidth();
    const pageHeight = pdf.internal.pageSize.getHeight();

    const totalPages = pdf.internal.getNumberOfPages();

    for (let i = 1; i <= totalPages; i++) {

        pdf.setPage(i);

        await drawFiligrane(
            pdf,
            resources.logo,
            i
        );

        drawFooter(
            pdf,
            i,
            totalPages,
            pageWidth,
            pageHeight
        );

    }

}
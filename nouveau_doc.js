document.addEventListener("DOMContentLoaded", () => {

    const exportBtn = document.getElementById("exportPDF");

    if (!exportBtn) {
        console.error("Le bouton exportPDF est introuvable !");
        return;
    }

    function waitForCharts() {
        return new Promise(resolve => {
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    setTimeout(resolve, 100);
                });
            });
        });
    }

    async function addSectionCapture(pdf, element, pageWidth, pageHeight, title) {

        if (!element) {
            console.warn(`Section manquante pour : ${title}`);
            return;
        }

        const previousDisplay = element.style.display;
        element.style.display = "block";

        const canvas = await html2canvas(element, {
            scale: 1.4,
            useCORS: true,
            windowWidth: document.documentElement.clientWidth,
            windowHeight: document.documentElement.clientHeight
        });

        element.style.display = previousDisplay;

        const imgData = canvas.toDataURL("image/png");

        const marginX = 30;
        const marginTop = 70;
        const maxWidth = pageWidth - marginX * 2;
        const imgHeight = canvas.height * (maxWidth / canvas.width);

        const availableHeight = pageHeight - marginTop - 40;

        const drawTitle = () => {
            pdf.setFontSize(18);
            pdf.setTextColor(20);
            pdf.text(title, marginX, 40);
        };

        // 🔥 Le tableau compact tient sur une seule page → UNE SEULE PAGE
        if (imgHeight <= availableHeight) {
            drawTitle();
            pdf.addImage(imgData, "PNG", marginX, marginTop, maxWidth, imgHeight, "", "FAST");
            return;
        }

        // Découpage si nécessaire (rare)
        let remainingHeight = imgHeight;
        let offsetY = 0;

        while (remainingHeight > 0) {

            drawTitle();

            const sliceHeight = Math.min(remainingHeight, availableHeight);

            pdf.addImage(
                imgData,
                "PNG",
                marginX,
                marginTop,
                maxWidth,
                imgHeight,
                "",
                "FAST",
                0,
                offsetY
            );

            remainingHeight -= sliceHeight;
            offsetY += sliceHeight;

            if (remainingHeight > 0) {
                pdf.addPage();
            }
        }
    }

    function addWatermarkAndFooter(pdf, pageWidth, pageHeight, pageNum, totalPages, logo) {

        if (logo) {
            try {
                pdf.setGState(new pdf.GState({ opacity: 0.12 }));
                const wmWidth = pageWidth * 0.35;
                const wmHeight = wmWidth;
                const wmX = (pageWidth - wmWidth) / 2;
                const wmY = (pageHeight - wmHeight) / 2;
                pdf.addImage(logo, "PNG", wmX, wmY, wmWidth, wmHeight, "", "FAST");
            } catch (e) {}
        }

        pdf.setFontSize(48);
        pdf.setTextColor(150);
        pdf.text(
            "LJ DASHBOARD",
            pageWidth / 2,
            pageHeight / 2 + 40,
            { angle: 45, align: "center" }
        );

        if (pdf.GState) pdf.setGState(new pdf.GState({ opacity: 1 }));

        pdf.setFontSize(11);
        pdf.setTextColor(120);
        pdf.text(
            `Page ${pageNum} / ${totalPages}`,
            pageWidth / 2,
            pageHeight - 20,
            { align: "center" }
        );

        pdf.setFontSize(10);
        pdf.text(
            "Document généré avec PDF PRO",
            pageWidth / 2,
            pageHeight - 8,
            { align: "center" }
        );
    }

    exportBtn.addEventListener("click", async () => {

        const { jsPDF } = window.jspdf;

        const pdf = new jsPDF({
            unit: "px",
            format: "a4",
            hotfixes: ["px_scaling"]
        });

        const pageWidth = pdf.internal.pageSize.getWidth();
        const pageHeight = pdf.internal.pageSize.getHeight();

        const logo = new Image();
        logo.src = "/nouveau_doc/assets/logo.png";

        await new Promise(resolve => {
            logo.onload = resolve;
            logo.onerror = resolve;
        });

        await waitForCharts();

        const summaryEl = document.getElementById("summary");
        const chartsEl = document.querySelector(".charts");
        const cardsEl = document.getElementById("cardsContainer");
        const tableEl = document.getElementById("badgeTable");

        // PAGE DE GARDE
        pdf.setFontSize(24);
        pdf.setTextColor(20);

        if (logo.complete) {
            pdf.addImage(logo, "PNG", 40, 40, 80, 80);
        }

        pdf.text("Analyse des Badges — Avril 2026", 140, 80);
        pdf.setFontSize(14);
        pdf.setTextColor(80);
        pdf.text("Généré automatiquement depuis le Dashboard LJ", 140, 105);

        pdf.setFontSize(12);
        pdf.text(
            `Date de génération : ${new Date().toLocaleString()}`,
            40,
            150
        );

        // SOMMAIRE
        pdf.addPage();
        const tocPageIndex = pdf.internal.getNumberOfPages();

        pdf.setFontSize(20);
        pdf.text("Sommaire", 40, 60);

        const tocLines = [
            { label: "1. Résumé global", key: "resume" },
            { label: "2. Graphiques", key: "charts" },
            { label: "3. Vue cartes", key: "cards" },
            { label: "4. Tableau des badges", key: "table" }
        ];

        let tocStartY = 100;
        const tocLineHeight = 24;

        tocLines.forEach((item, index) => {
            pdf.setFontSize(13);
            pdf.text(item.label, 60, tocStartY + index * tocLineHeight);
        });

        // RÉSUMÉ GLOBAL
        pdf.addPage();
        const resumePageIndex = pdf.internal.getNumberOfPages();

        pdf.setFontSize(18);
        pdf.text("Résumé global", 40, 60);

        const getText = (id) => {
            const el = document.getElementById(id);
            return el ? el.textContent.trim() : "";
        };

        const resumeLines = [
            getText("total"),
            getText("completed"),
            getText("incomplete"),
            getText("average"),
            getText("updated")
        ].filter(Boolean);

        let resumeY = 100;
        resumeLines.forEach(line => {
            pdf.setFontSize(13);
            pdf.text(line, 60, resumeY);
            resumeY += 22;
        });

        // GRAPHIQUES
        pdf.addPage();
        const chartsPageIndex = pdf.internal.getNumberOfPages();
        await addSectionCapture(pdf, chartsEl, pageWidth, pageHeight, "Graphiques");

        // VUE CARTES (mini-cards compactes)
        pdf.addPage();
        const cardsPageIndex = pdf.internal.getNumberOfPages();
        await addSectionCapture(pdf, cardsEl, pageWidth, pageHeight, "Vue cartes");

        // TABLEAU DES BADGES
        pdf.addPage();
        const tablePageIndex = pdf.internal.getNumberOfPages();
        await addSectionCapture(pdf, tableEl, pageWidth, pageHeight, "Tableau des badges");

        // SOMMAIRE FINAL
        const totalPages = pdf.internal.getNumberOfPages();

        pdf.setPage(tocPageIndex);

        const pageMap = {
            resume: resumePageIndex,
            charts: chartsPageIndex,
            cards: cardsPageIndex,
            table: tablePageIndex
        };

        tocLines.forEach((item, index) => {
            const y = tocStartY + index * tocLineHeight;
            const pageNum = pageMap[item.key];
            const label = item.label;
            const textWidth = pdf.getTextWidth(label);

            pdf.text(label, 60, y);
            pdf.text(`... ${pageNum}`, 60 + textWidth + 10, y);
        });

        // FILIGRANE + FOOTER
        for (let i = 1; i <= totalPages; i++) {
            pdf.setPage(i);
            addWatermarkAndFooter(pdf, pageWidth, pageHeight, i, totalPages, logo.complete ? logo : null);
        }

        pdf.save("export.pdf");
    });
});

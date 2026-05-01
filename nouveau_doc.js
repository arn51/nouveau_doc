    exportBtn.addEventListener("click", async () => {

        console.log("exportPDF cliqué");

        // Vérification jsPDF
        if (!window.jspdf) {
            console.error("jsPDF n'est pas chargé !");
            return;
        }

        const { jsPDF } = window.jspdf;

        const pdf = new jsPDF({
            unit: "px",
            format: "a4",
            hotfixes: ["px_scaling"]
        });

        const pageWidth = pdf.internal.pageSize.getWidth();
        const pageHeight = pdf.internal.pageSize.getHeight();

        // 1) Charger le logo externe (CHEMIN ABSOLU CORRIGÉ)
        const logo = new Image();
        logo.src = "/nouveau_doc/assets/logo.png";

        await new Promise(resolve => logo.onload = resolve);

        // 2) Attendre que Chart.js soit rendu
        await waitForCharts();

        // 3) Capturer le contenu HTML
        const content = document.getElementById("pdf-content");

        const canvas = await html2canvas(content, {
            scale: 2,
            useCORS: true,
            windowWidth: document.documentElement.clientWidth,
            windowHeight: document.documentElement.clientHeight
        });

        const imgData = canvas.toDataURL("image/png");

        const imgWidth = pageWidth - 40;
        const imgHeight = canvas.height * (imgWidth / canvas.width);

        let position = 100;
        let heightLeft = imgHeight;

        // 4) HEADER
        pdf.addImage(logo, "PNG", 20, 20, 60, 60);
        pdf.setFontSize(16);
        pdf.text("Rapport généré automatiquement", 100, 40);
        pdf.setFontSize(12);
        pdf.text(new Date().toLocaleDateString(), 100, 60);

        // 5) Première page
        pdf.addImage(imgData, "PNG", 20, position, imgWidth, imgHeight);
        heightLeft -= (pageHeight - position - 40);

        // 6) Pages suivantes
        while (heightLeft > 0) {
            pdf.addPage();

            pdf.addImage(logo, "PNG", 20, 20, 60, 60);
            pdf.setFontSize(16);
            pdf.text("Rapport généré automatiquement", 100, 40);

            const newPosition = 100;
            pdf.addImage(imgData, "PNG", 20, newPosition - (imgHeight - heightLeft), imgWidth, imgHeight);

            heightLeft -= (pageHeight - newPosition - 40);
        }

        // 7) Footer + pagination
        const totalPages = pdf.internal.getNumberOfPages();

        for (let i = 1; i <= totalPages; i++) {
            pdf.setPage(i);

        // === FILIGRANE IMAGE + TEXTE ===

        // Opacité réduite pour le filigrane
           pdf.setGState(new pdf.GState({ opacity: 0.12 }));

        // --- Filigrane image ---
            const wmWidth = pageWidth * 0.35;
            const wmHeight = wmWidth;
            const wmX = (pageWidth - wmWidth) / 2;
            const wmY = (pageHeight - wmHeight) / 2;

            pdf.addImage(logo, "PNG", wmX, wmY, wmWidth, wmHeight, "", "FAST");

        // --- Filigrane texte ---
            pdf.setFontSize(48);
            pdf.setTextColor(150);
            pdf.text("LJ DASHBOARD", pageWidth / 2, pageHeight / 2 + wmHeight * 0.6, {
                angle: 45,
                align: "center"
        });

        // Retour à l’opacité normale
            pdf.setGState(new pdf.GState({ opacity: 1 }));

        // === FOOTER ===
            pdf.setFontSize(11);
            pdf.setTextColor(120);
            pdf.text(`Page ${i} / ${totalPages}`, pageWidth / 2, pageHeight - 20, { align: "center" });

            pdf.setFontSize(10);
            pdf.text("Document généré avec PDF PRO", pageWidth / 2, pageHeight - 8, { align: "center" });
        }

        // 8) Sauvegarde
        pdf.save("export.pdf");
    });

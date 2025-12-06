
import { jsPDF } from "jspdf";
import { agendaData, homeworkData, policyTemplates, designChecklist } from "../data/content";

export const exportCurriculum = () => {
  const doc = new jsPDF();
  let yPos = 20;
  const lineHeight = 7;
  const pageHeight = doc.internal.pageSize.height;

  const checkPageBreak = (spaceNeeded: number = 20) => {
    if (yPos + spaceNeeded >= pageHeight) {
      doc.addPage();
      yPos = 20;
    }
  };

  // Helper to add text
  const addText = (text: string, fontSize: number = 10, isBold: boolean = false) => {
    doc.setFontSize(fontSize);
    doc.setFont("helvetica", isBold ? "bold" : "normal");
    
    // Turkish character handling workarounds for standard fonts
    // Note: Standard PDF fonts have limited UTF-8 support. 
    // In a production environment, we would load a custom font (e.g., Roboto).
    // Here we accept standard font limitations for simplicity.
    const splitText = doc.splitTextToSize(text, 180);
    
    if (yPos + (splitText.length * lineHeight) >= pageHeight) {
      doc.addPage();
      yPos = 20;
    }
    
    doc.text(splitText, 15, yPos);
    yPos += splitText.length * 6; // slightly tighter line spacing
  };

  // Title
  doc.setFontSize(16);
  doc.setFont("helvetica", "bold");
  doc.text("Fen & YZ Egitim Portali - Dijital Kilavuz", 15, yPos);
  yPos += 10;
  
  doc.setFontSize(10);
  doc.setFont("helvetica", "normal");
  doc.text(`Olusturulma Tarihi: ${new Date().toLocaleDateString('tr-TR')}`, 15, yPos);
  yPos += 15;

  // Section 1: 7-Dimension Framework
  addText("1. 7 Boyutlu Nitelikli Odev Tasarimi Cercevesi", 14, true);
  yPos += 5;
  addText("1. Bilisel Derinlik: Bloom'un ust basamaklarini hedefler.");
  addText("2. Ozgunluk: Ogrencinin yerel ve kisisel baglamini icerir.");
  addText("3. Surec Seffafligi: Surec belgeleme araclarini kullanir.");
  addText("4. YZ Etigi: Seffaflik ve durustluk ilkesini benimser.");
  addText("5. Coklu Kanit: Sozlu savunma ve performans gorevleri icerir.");
  addText("6. Isbirligi: Sosyal ogrenmeyi destekler.");
  addText("7. Yansitma: Metacognition (bilosotesi) sorulari icerir.");
  yPos += 10;

  // Section 2: Agenda
  checkPageBreak();
  addText("2. 4 Gunluk Hizmet Ici Egitim Programi", 14, true);
  yPos += 5;
  Object.values(agendaData).forEach(day => {
    checkPageBreak(30);
    addText(`${day.title}`, 12, true);
    addText(`Hedef: ${day.goal}`, 10, false);
    yPos += 2;
    day.sessions.forEach(session => {
      addText(`- ${session.time}: ${session.title}`);
    });
    yPos += 5;
  });
  
  // Section 3: Homework Examples
  checkPageBreak();
  addText("3. Ornek Ozgun Fen Odevleri", 14, true);
  yPos += 5;
  homeworkData.forEach((hw, index) => {
    checkPageBreak(50);
    addText(`${index + 1}. ${hw.title} (${hw.classLevel})`, 12, true);
    addText(`Amac: ${hw.aim}`);
    addText(`Yonerge: ${hw.instructions}`);
    addText(`Cikti: ${hw.deliverable}`);
    yPos += 5;
  });

  // Section 4: Policies
  checkPageBreak();
  addText("4. YZ Etik Beyan Sablonlari", 14, true);
  yPos += 5;
  policyTemplates.forEach(policy => {
    checkPageBreak(20);
    addText(policy.title, 11, true);
    addText(`"${policy.text}"`);
    yPos += 3;
  });

  // Save PDF
  doc.save("Nitelikli_Odev_Tasarim_Kilavuzu.pdf");
};

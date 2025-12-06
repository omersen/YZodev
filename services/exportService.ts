import { agendaData, homeworkData, policyTemplates, designChecklist } from "../data/content";

export const exportCurriculum = () => {
  const lines: string[] = [];

  // Title
  lines.push("# Fen & YZ Eğitim Portalı - Dijital Kılavuz");
  lines.push(`Oluşturulma Tarihi: ${new Date().toLocaleDateString('tr-TR')}`);
  lines.push("> Kaynak: Dijital Pedagoji ve Ölçmenin Yeni Vizyonu: Öğretmen Yetkinliklerinin Güçlendirilmesine Yönelik Yapay Zeka Dirençli Ödev Tasarımı Eğitimi");
  lines.push("\n---\n");

  // Section 1: 7-Dimension Framework
  lines.push("## 1. Dijital Pedagoji ve Ölçmenin Yeni Vizyonu: Öğretmen Yetkinliklerinin Güçlendirilmesine Yönelik Yapay Zeka Dirençli Ödev Tasarımı Eğitimi (7 Boyut)\n");
  lines.push("1. **Bilişsel Derinlik:** Bloom'un üst basamaklarını hedefler.");
  lines.push("2. **Özgünlük:** Öğrencinin yerel ve kişisel bağlamını içerir.");
  lines.push("3. **Süreç Şeffaflığı:** Süreç belgeleme araçlarını kullanır.");
  lines.push("4. **YZ Etiği:** Şeffaflık ve dürüstlük ilkesini benimser.");
  lines.push("5. **Çoklu Kanıt:** Sözlü savunma ve performans görevleri içerir.");
  lines.push("6. **İşbirliği:** Sosyal öğrenmeyi destekler.");
  lines.push("7. **Yansıtma:** Metacognition (bilişötesi) soruları içerir.");
  lines.push("\n---\n");

  // Section 2: Agenda
  lines.push("## 2. 4 Günlük Hizmet İçi Eğitim Programı\n");
  Object.values(agendaData).forEach(day => {
    lines.push(`### ${day.title}`);
    lines.push(`*Hedef: ${day.goal}*\n`);
    day.sessions.forEach(session => {
      lines.push(`- **${session.time}** - ${session.title}`);
      lines.push(`  ${session.desc}`);
    });
    lines.push("\n");
  });
  lines.push("---\n");

  // Section 3: Detailed Homework Examples
  lines.push("## 3. Örnek Özgün Fen Ödevleri\n");
  homeworkData.forEach((hw, index) => {
    lines.push(`### ${index + 1}. ${hw.title} (${hw.classLevel})`);
    lines.push(`*Amaç: ${hw.aim}*\n`);
    lines.push(`**Yönerge:** ${hw.instructions}\n`);
    lines.push("**Adımlar:**");
    hw.steps.forEach(step => lines.push(`- ${step}`));
    lines.push(`\n**YZ Politikası:** ${hw.policy}`);
    lines.push(`**Çıktı:** ${hw.deliverable}`);
    lines.push(`\n**Değerlendirme (Rubrik Özeti):**`);
    hw.rubric.forEach(r => {
        lines.push(`- *${r.criteria}:* ${r.levels[4]} (Mükemmel)`);
    });
    lines.push("\n---\n");
  });

  // Section 4: Policies
  lines.push("## 4. YZ Etik Beyan Şablonları\n");
  policyTemplates.forEach(policy => {
    lines.push(`### ${policy.title}`);
    lines.push(`> "${policy.text}"\n`);
  });

  // Section 5: Checklist
  lines.push("\n## 5. Tasarım Kontrol Listesi\n");
  designChecklist.forEach(item => {
      lines.push(`- [ ] **${item.dimension}:** ${item.question}`);
  });

  // Create File
  const blob = new Blob([lines.join("\n")], { type: "text/markdown;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  
  // Trigger Download
  const link = document.createElement("a");
  link.href = url;
  link.download = "Nitelikli_Odev_Tasarim_Kilavuzu.md";
  document.body.appendChild(link);
  link.click();
  
  // Cleanup
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
};
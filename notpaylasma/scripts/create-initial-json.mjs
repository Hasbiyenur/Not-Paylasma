// Önceki uygulamanın başlangıç kayıtlarının tek seferlik JSON karşılığı.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
const date = new Date('2026-11-11T12:00:00Z');
const users = [ ['demo-ayse','Ayşe','Yılmaz','ayse@example.com'], ['demo-mehmet','Mehmet','Demir','mehmet@example.com'] ]
  .map(([uid,firstName,lastName,email]) => ({uid,firstName,lastName,email,photoUrl:null,createdAt:date.toISOString(),updatedAt:date.toISOString()}));
const categories = [ ['yazilim','Yazılım','Programlama ve mobil geliştirme'], ['matematik','Matematik','Matematik ve istatistik'], ['fizik','Fizik','Mekanik ve elektrik'], ['dil','Dil','Dil öğrenimi'] ].map(([id,name,description]) => ({id,name,description}));
const subjects = [ ['Dart ve koleksiyonlar','Mobil Programlama','yazilim','dart'], ['Türev çalışma notları','Matematik I','matematik','türev'], ['Hareket ve kuvvet','Fizik I','fizik','mekanik'], ['İngilizce zamanlar','İngilizce','dil','gramer'] ];
const notes = Array.from({length:26}, (_,i) => {
  const subject = subjects[i%4], ext = i===1?'docx':i===2?'png':'pdf', user = users[i%2];
  const id = `demo-note-${String(i).padStart(3,'0')}`;
  return {id,title:`${subject[0]} • ${i+1}`,description:'Arama ve paylaşım akışlarını denemek için örnek kayıt. Ek dosya, NotPaylaş demo çalışma sayfasıdır; dersin tam içeriği değildir.',courseName:subject[1],categoryId:subject[2],university:'Örnek Eğitim Kurumu',tags:[subject[3],'örnek'],userId:user.uid,userName:`${user.firstName} ${user.lastName}`,fileName:`ornek.${ext}`,storagePath:`notes/${user.uid}/${id}/ornek.${ext}`,fileType:ext,fileSize:readFileSync(`assets/data/files/ornek.${ext}`).length,downloadCount:0,favoriteCount:0,createdAt:new Date(date.getTime()-i*3600000).toISOString(),updatedAt:date.toISOString()};
});
const credentials = Object.fromEntries(users.map(user => {
  const salt=`initial-json-${user.uid}`;
  return [user.uid,{salt,hash:createHash('sha256').update(`${salt}:NotPaylas123!`).digest('hex')}];
}));
mkdirSync('assets/data',{recursive:true});
writeFileSync('assets/data/initial_data.json',JSON.stringify({schemaVersion:1,users,credentials,categories,notes,favorites:{},currentUid:null,theme:'system'},null,2)+'\n');


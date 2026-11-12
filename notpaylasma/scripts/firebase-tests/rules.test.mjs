import { readFileSync } from 'node:fs';
import { before, beforeEach, after, test, describe } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';

let env;
const user = (uid='alice') => env.authenticatedContext(uid,{email: uid+'@example.com'});
const profile = (uid='alice') => ({
  uid,firstName:'Ayşe',lastName:'Yılmaz',email:uid+'@example.com',
  createdAt:serverTimestamp(),updatedAt:serverTimestamp()
});
describe('Firebase kullanıcı profili; dosyalar ve notlar yerel',()=>{
  before(async()=>{
    env=await initializeTestEnvironment({
      projectId:'demo-notpaylas',
      firestore:{host:'127.0.0.1',port:8080,rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')},
      storage:{host:'127.0.0.1',port:9199,rules:readFileSync(new URL('../../storage.rules',import.meta.url),'utf8')},
    });
  });
  beforeEach(async()=>{await env.clearFirestore();await env.clearStorage();});
  after(async()=>{await env?.cleanup();});
  test('Sahibi kendi profilini oluşturur, okur ve günceller',async()=>{
    const ref=doc(user().firestore(),'users/alice');
    await assertSucceeds(setDoc(ref,profile()));
    await assertSucceeds(getDoc(ref));
    await assertSucceeds(updateDoc(ref,{firstName:'A',updatedAt:serverTimestamp()}));
  });
  test('Oturumsuz erişim ve başkasının profili reddedilir',async()=>{
    await assertSucceeds(setDoc(doc(user().firestore(),'users/alice'),profile()));
    await assertFails(getDoc(doc(user('bob').firestore(),'users/alice')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'users/alice')));
    await assertFails(setDoc(doc(user('bob').firestore(),'users/alice'),profile()));
  });
  test('Parola, fotoğraf yolu ve fazladan alanlar Firestore’a yazılamaz',async()=>{
    const ref=doc(user().firestore(),'users/alice');
    for(const extra of [{password:'secret'},{photoUrl:'avatars/alice/photo'},{photoUrl:null},{isAdmin:true}])
      await assertFails(setDoc(ref,{...profile(),...extra}));
  });
  test('Kimlik, e-posta, oluşturma zamanı ve alan türleri korunur',async()=>{
    const ref=doc(user().firestore(),'users/alice');
    await assertSucceeds(setDoc(ref,profile()));
    for(const value of [{uid:'bob'},{email:'bob@example.com'},{createdAt:serverTimestamp()},{firstName:123},{lastName:''}])
      await assertFails(updateDoc(ref,{...value,updatedAt:serverTimestamp()}));
  });
  test('Eski photoUrl alanı silinerek kullanıcı profili onarılabilir',async()=>{
    await env.withSecurityRulesDisabled(async ctx=>{
      await setDoc(doc(ctx.firestore(),'users/alice'),{...profile(),photoUrl:'avatars/alice/old'});
    });
    const {deleteField}=await import('firebase/firestore');
    await assertSucceeds(updateDoc(doc(user().firestore(),'users/alice'),{photoUrl:deleteField(),updatedAt:serverTimestamp()}));
  });
  test('Not, kategori, favori ve temizlik kuyruğu Firestore’da kapalıdır',async()=>{
    const db=user().firestore();
    for(const path of ['notes/n1','categories/yazilim','users/alice/favorites/n1','users/alice/fileCleanup/job']){
      await assertFails(setDoc(doc(db,path),{value:1}));
      await assertFails(getDoc(doc(db,path)));
    }
  });
  test('Avatar ve not ekleri Firebase Storage’a yüklenemez',async()=>{
    const storage=user().storage();
    for(const path of ['avatars/alice/photo','notes/alice/n1/file']){
      await assertFails(storage.ref(path).put(new Uint8Array([1]),{contentType:'image/png'}));
      await assertFails(storage.ref(path).getMetadata());
    }
  });
});

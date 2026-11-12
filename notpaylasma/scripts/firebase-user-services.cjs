// Yalnızca belirtilen mevcut projedeki servisleri yönetir; login/proje oluşturma yoktur.
const path = require('node:path');
const fs = require('node:fs');
const project = 'not-paylasma-proje';
const action = process.argv[2] || 'check';
if (!['check','check-billing','enable-firestore','enable-email-password'].includes(action)) throw new Error('Geçersiz işlem.');
const toolsRoot = process.env.FIREBASE_TOOLS_DIR || path.join(process.env.APPDATA || '', 'npm/node_modules/firebase-tools');
if (!fs.existsSync(path.join(toolsRoot,'lib/auth.js'))) throw new Error('Firebase CLI yolu için FIREBASE_TOOLS_DIR belirtin.');
const load = name => require(path.join(toolsRoot,'lib',name));
async function run() {
  const account = load('auth.js').getProjectDefaultAccount(process.cwd());
  if (!account) throw new Error('Mevcut Firebase CLI oturumu bulunamadı. Oturum açma uygulama sahibine aittir.');
  await load('requireAuth.js').requireAuth({project,projectRoot:process.cwd(),nonInteractive:true,...account},true);
  if (action === 'check-billing') {
    const billing = new (load('apiv2.js').Client)({urlPrefix:'https://cloudbilling.googleapis.com',apiVersion:'v1'});
    const result = await billing.get('/projects/'+project+'/billingInfo',{skipLog:{resBody:true}});
    console.log(JSON.stringify({project,billingEnabled:result.body.billingEnabled===true}));
    if (result.body.billingEnabled===true) throw new Error('Faturalandırma açık; ücretsiz plan şartı nedeniyle ücretli kaynak işlemleri yapılmadı.');
    return;
  }
  if (action === 'enable-firestore') {
    await load('ensureApiEnabled.js').ensure(project,'firestore.googleapis.com','Firestore',true);
    console.log(JSON.stringify({project,firestoreApiEnabled:true}));
    return;
  }
  const client = new (load('apiv2.js').Client)({urlPrefix:'https://identitytoolkit.googleapis.com',apiVersion:'admin/v2'});
  let result = await client.get('/projects/'+project+'/config',{skipLog:{resBody:true}});
  if (action === 'enable-email-password' && !result.body.signIn?.email?.enabled) {
    result = await client.patch('/projects/'+project+'/config',
      {signIn:{email:{enabled:true,passwordRequired:true}}},
      {queryParams:{updateMask:'signIn.email.enabled,signIn.email.passwordRequired'},skipLog:{reqBody:true,resBody:true}});
  }
  console.log(JSON.stringify({project,emailPasswordEnabled:result.body.signIn?.email?.enabled===true,passwordRequired:result.body.signIn?.email?.passwordRequired===true,subtype:result.body.subtype}));
}
run().catch(error=>{console.error(error.message);process.exitCode=1;});

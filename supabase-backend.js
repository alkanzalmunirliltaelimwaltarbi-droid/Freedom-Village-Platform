(() => {
  'use strict';
  const { createClient } = window.supabase;
  const client = createClient(window.FV_SUPABASE_URL, window.FV_SUPABASE_PUBLISHABLE_KEY, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
  });
  const collections = ['news','services','emergency','events','directory'];
  async function profile(){
    const {data:{user}} = await client.auth.getUser();
    if(!user) return null;
    const {data,error}=await client.from('profiles').select('*').eq('id',user.id).maybeSingle();
    if(error) throw error;
    return data ? {...data,email:user.email} : {id:user.id,email:user.email,name:user.user_metadata?.name||user.email,is_admin:false,active:true};
  }
  async function loadData(base){
    const out=JSON.parse(JSON.stringify(base));
    for(const c of collections){ const {data,error}=await client.from('content_items').select('*').eq('category',c).order('created_at',{ascending:false}); if(error) throw error; out[c]=data||[]; }
    {const {data,error}=await client.from('requests').select('*').order('created_at',{ascending:false}); if(error) throw error; out.requests=(data||[]).map(x=>({...x,statusLabel:x.status_label||'قيد المراجعة',userId:x.user_id||null,createdAt:x.created_at}));}
    {const {data,error}=await client.from('profiles').select('*').order('created_at',{ascending:false}); if(error) throw error; out.users=(data||[]).map(x=>({id:x.id,name:x.name||'',email:x.email||'',active:x.active!==false,isAdmin:!!x.is_admin}));}
    {const {data,error}=await client.from('prayer_times').select('*').eq('id',1).maybeSingle(); if(error) throw error; if(data) out.prayer={...out.prayer,...data};}
    {const {data,error}=await client.from('app_settings').select('*').eq('id',1).maybeSingle(); if(error) throw error; if(data) out.settings={...out.settings,...data,hijriOffset:Number(data.hijri_offset||0),logoUrl:data.logo_url||''};}
    return out;
  }
  async function saveData(data){
    for(const c of collections){
      const {data:old,error:e}=await client.from('content_items').select('id').eq('category',c); if(e) throw e;
      const rows=(data[c]||[]).map(x=>({id:x.id,category:c,title:x.title||'',body:x.body||'',date:x.date||null,extra:x.extra||{}}));
      if(rows.length){const {error}=await client.from('content_items').upsert(rows); if(error) throw error;}
      const keep=new Set(rows.map(x=>x.id)); const ids=(old||[]).map(x=>x.id).filter(id=>!keep.has(id));
      if(ids.length){const {error}=await client.from('content_items').delete().eq('category',c).in('id',ids); if(error) throw error;}
    }
    {const rows=(data.requests||[]).map(x=>({id:x.id,tracking:x.tracking,type:x.type,name:x.name||'',phone:x.phone||'',body:x.body||'',status:x.status||'under_review',status_label:x.statusLabel||'قيد المراجعة',user_id:x.userId||null,created_at:x.createdAt||new Date().toISOString()})); if(rows.length){const {error}=await client.from('requests').upsert(rows); if(error) throw error;}}
    {const p={id:1,fajr:data.prayer.fajr||'',sunrise:data.prayer.sunrise||'',dhuhr:data.prayer.dhuhr||'',asr:data.prayer.asr||'',maghrib:data.prayer.maghrib||'',isha:data.prayer.isha||'',image_url:data.prayer.image_url||''}; const {error}=await client.from('prayer_times').upsert(p); if(error) throw error;}
    {const s={id:1,village:data.settings.village||'قرية الحرية',description:data.settings.description||'',hijri_offset:Number(data.settings.hijriOffset||0),logo_url:data.settings.logoUrl||null}; const {error}=await client.from('app_settings').upsert(s); if(error) throw error;}
    return true;
  }
  async function uploadImage(file,path){
    const ext=(file.name.split('.').pop()||'jpg').toLowerCase().replace(/[^a-z0-9]/g,'')||'jpg';
    const full=`${path}.${ext}`;
    const {error}=await client.storage.from('public-assets').upload(full,file,{upsert:true,contentType:file.type||'image/jpeg',cacheControl:'3600'});
    if(error) throw error;
    const {data}=client.storage.from('public-assets').getPublicUrl(full);
    return data.publicUrl;
  }
  window.FVCloud={client,auth:client.auth,profile,loadData,saveData,uploadImage,isReady:true};
})();

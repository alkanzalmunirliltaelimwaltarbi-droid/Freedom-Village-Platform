# منصة قرية الحرية — Supabase + GitHub + Netlify

هذه النسخة تحول التخزين من LocalStorage إلى Supabase:
- Supabase Auth لتسجيل الدخول.
- PostgreSQL للبيانات.
- Realtime للتزامن بين الأجهزة.
- Storage للصور والشعار.
- RLS لحماية الصلاحيات.
- GitHub لحفظ المشروع وإدارة الإصدارات.
- Netlify للنشر التلقائي.

## 1) إعداد Supabase مرة واحدة
1. افتح مشروع Supabase: https://supabase.com/dashboard/project/novkheywufddqqoigxqe
2. افتح SQL Editor.
3. الصق كامل ملف `schema.sql` ونفذه.
4. افتح Authentication > Providers وتأكد من تفعيل Email.
5. من Authentication > Users اختر Add user وأنشئ أول حساب للمشرف.
6. انسخ UID للحساب.
7. افتح Table Editor > profiles.
8. أضف صفاً:
   - id = UID نفسه
   - name = اسم المشرف
   - email = البريد الإلكتروني
   - is_admin = true
   - active = true

## 2) إنشاء المستخدمين
لأسباب أمنية لا ينشئ المتصفح حسابات Auth جديدة بصلاحية إدارية. أنشئ حساب المستخدم من Authentication > Users ثم أضف له profile بنفس UID، وبعدها يمكن للمشرف تفعيل/إيقاف الحساب أو منحه صلاحية مشرف.

## 3) GitHub
أنشئ مستودعاً جديداً وارفع محتويات هذا المجلد كما هي. لا تضع service_role key أو أي مفتاح سري في GitHub. مفتاح publishable الموجود في `supabase-config.js` مخصص للاستخدام في الواجهة مع RLS.

## 4) Netlify
في Netlify اختر Add new project > Import an existing project > GitHub، ثم اختر المستودع. لا يوجد build command مطلوب لهذا المشروع؛ مجلد المشروع نفسه هو مجلد النشر.

بعد ربط GitHub، كل Push إلى الفرع المرتبط يمكن أن يطلق نشر Netlify تلقائياً.

## 5) مهم
لا تحذف RLS. الأمان يعتمد على سياسات `schema.sql`.

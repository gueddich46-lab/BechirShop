package com.bechir.shop;
import android.app.Activity;
import android.content.*;
import android.widget.Toast;
import com.google.firebase.messaging.FirebaseMessaging;
final class NotificationToken { static void init(android.app.Activity a){ com.onesignal.OneSignal.initWithContext(a.getApplicationContext(), "3887e33b-9cee-44d9-ab8f-b6158a3f3a0e"); }

 static void copy(Activity a){
 try { com.onesignal.OneSignal.getUser().getPushSubscription().optIn(); } catch(Exception ignored){}
 new android.os.Handler(android.os.Looper.getMainLooper()).postDelayed(()->{
 try { var sub=com.onesignal.OneSignal.getUser().getPushSubscription(); new android.app.AlertDialog.Builder(a).setTitle("OneSignal - تشخيص").setMessage("SDK: 5.1.31\nSubscription ID: "+(sub.getId()!=null?"OK":"Missing")+"\nFCM token: "+(sub.getToken()!=null?"OK":"Missing")+"\nOpted in: "+sub.getOptedIn()).setPositiveButton("OK",null).show(); }catch(Exception e){new android.app.AlertDialog.Builder(a).setMessage(e.getClass().getSimpleName()).setPositiveButton("OK",null).show();}
 },3000);
 }
 static void copyLegacy(Activity a){
 try { FirebaseMessaging.getInstance().getToken().addOnCompleteListener(task->{
 if(!task.isSuccessful()){Toast.makeText(a,"تعذر الحصول على رمز الإشعارات",Toast.LENGTH_LONG).show();return;}
 ClipboardManager clipboard=(ClipboardManager)a.getSystemService(Context.CLIPBOARD_SERVICE);
 clipboard.setPrimaryClip(ClipData.newPlainText("FCM token",task.getResult()));
 Toast.makeText(a,"تم نسخ رمز الإشعارات",Toast.LENGTH_LONG).show();
 }); } catch(Exception e){Toast.makeText(a,"تعذر تهيئة Firebase",Toast.LENGTH_LONG).show();}
 }
}
package com.bechir.shop;
import android.app.Activity;
import android.content.*;
import android.widget.Toast;
import com.google.firebase.messaging.FirebaseMessaging;
final class NotificationToken {
 static void copy(Activity a){
 try { FirebaseMessaging.getInstance().getToken().addOnCompleteListener(task->{
 if(!task.isSuccessful()){Toast.makeText(a,"تعذر الحصول على رمز الإشعارات",Toast.LENGTH_LONG).show();return;}
 ClipboardManager clipboard=(ClipboardManager)a.getSystemService(Context.CLIPBOARD_SERVICE);
 clipboard.setPrimaryClip(ClipData.newPlainText("FCM token",task.getResult()));
 Toast.makeText(a,"تم نسخ رمز الإشعارات",Toast.LENGTH_LONG).show();
 }); } catch(Exception e){Toast.makeText(a,"تعذر تهيئة Firebase",Toast.LENGTH_LONG).show();}
 }
}
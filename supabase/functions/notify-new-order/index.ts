import { GoogleAuth } from "npm:google-auth-library@9";
Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", {status:405});
  const secret = Deno.env.get("ORDER_WEBHOOK_SECRET");
  if (!secret || req.headers.get("x-webhook-secret") !== secret) return new Response("Unauthorized", {status:401});
  try {
    const token = Deno.env.get("ADMIN_FCM_TOKEN");
    const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!token || !raw) return new Response("Missing configuration", {status:503});
    const auth = new GoogleAuth({credentials:JSON.parse(raw),scopes:["https://www.googleapis.com/auth/firebase.messaging"]});
    const access = await (await auth.getClient()).getAccessToken();
    if (!access.token) return new Response("Authentication failed",{status:502});
    const result = await fetch("https://fcm.googleapis.com/v1/projects/bechir-shop/messages:send",{
      method:"POST",headers:{Authorization:"Bearer "+access.token,"Content-Type":"application/json"},
      body:JSON.stringify({message:{token,notification:{title:"بشير شوب PRO",body:"لديك طلب جديد في المتجر"},android:{priority:"high",notification:{channel_id:"shop_orders"}}}})
    });
    return Response.json({success:result.ok},{status:result.ok?200:502});
} catch (error) {
  console.error("Notification error:", error instanceof Error ? error.name : "Unknown error");
  return new Response("Notification failed", { status: 500 });
}
                                
});

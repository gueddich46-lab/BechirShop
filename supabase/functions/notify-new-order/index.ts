Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", {status:405});
  const secret = Deno.env.get("ORDER_WEBHOOK_SECRET");
  if (!secret || req.headers.get("x-webhook-secret") !== secret) return new Response("Unauthorized", {status:401});
  const key = Deno.env.get("ONESIGNAL_API_KEY");
  const subscription = Deno.env.get("ONESIGNAL_SUBSCRIPTION_ID");
  if (!key || !subscription) return new Response("Missing configuration", {status:503});
  try {
    const result = await fetch("https://api.onesignal.com/notifications", {
      method:"POST",
      headers:{"Authorization":"Key "+key,"Content-Type":"application/json"},
      body:JSON.stringify({
        app_id:"3887e33b-9cee-44d9-ab8f-b6158a3f3a0e",
        include_subscription_ids:[subscription.trim()],
        target_channel:"push",
        headings:{en:"طلب جديد في بشير شوب"},
        contents:{en:"لديك طلب جديد! افتح التطبيق للاطلاع على التفاصيل."}
      })
    });
    const data = await result.json();
    const success = result.ok && typeof data.id === "string" && data.id.length > 0;
    return Response.json({success,provider_status:result.status},{status:success?200:502});
  } catch {
    return new Response("Notification failed",{status:500});
  }
});

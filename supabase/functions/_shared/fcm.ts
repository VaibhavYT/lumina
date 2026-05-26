export async function sendFCMNotification({
  deviceToken,
  title,
  body,
  data = {},
}: {
  deviceToken: string | null | undefined;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<void> {
  if (!deviceToken) {
    console.log("No FCM token for device; skipping push notification");
    return;
  }

  const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
  if (!fcmServerKey) {
    console.error("FCM_SERVER_KEY not set");
    return;
  }

  const response = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `key=${fcmServerKey}`,
    },
    body: JSON.stringify({
      to: deviceToken,
      notification: { title, body, sound: "default" },
      data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
      priority: "high",
    }),
  });

  if (!response.ok) {
    console.error("FCM send failed:", await response.text());
  }
}

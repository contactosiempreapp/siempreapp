// SIEMPRE — Service Worker (notificaciones push)

const ACCION_NOTIFICACION_URL = "https://bvxeiihvlczztuvjgzyz.supabase.co/functions/v1/accion-notificacion";

self.addEventListener("install", (event) => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("push", (event) => {
  let data = { title: "SIEMPRE", body: "Tenés una novedad en la app." };
  try {
    if (event.data) data = event.data.json();
  } catch (e) {
    if (event.data) data.body = event.data.text();
  }

  const options = {
    body: data.body || "",
    icon: "icon-192.png",
    badge: "icon-192.png",
    vibrate: [200, 100, 200],
    data: { url: data.url || "./", actionToken: data.actionToken || null }
  };
  if (data.actions) options.actions = data.actions;

  event.waitUntil(self.registration.showNotification(data.title || "SIEMPRE", options));
});

self.addEventListener("notificationclick", (event) => {
  const url = (event.notification.data && event.notification.data.url) || "./";
  const actionToken = event.notification.data && event.notification.data.actionToken;

  // Tocó un botón de acción (Tomé / No tomé) en vez del cuerpo de la notificación
  if (event.action === "tome" || event.action === "no_tome") {
    event.notification.close();
    if (!actionToken) return;
    event.waitUntil(
      fetch(ACCION_NOTIFICACION_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token: actionToken, respuesta: event.action })
      }).then(() =>
        self.registration.showNotification("¡Listo! 💜", {
          body: event.action === "tome" ? "Quedó registrado que la tomaste hoy." : "Quedó registrado que no la tomaste hoy.",
          icon: "icon-192.png",
          badge: "icon-192.png"
        })
      ).catch(() => {})
    );
    return;
  }

  // Tocó el cuerpo de la notificación: abrir/enfocar la app
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(location.origin) && "focus" in client) return client.focus();
      }
      if (self.clients.openWindow) return self.clients.openWindow(url);
    })
  );
});

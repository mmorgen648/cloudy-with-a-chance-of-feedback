const clientId = "5gc47l6rh621jdl9ai7bfli2qv";
const domain = "eu-central-1eg8otyz7b.auth.eu-central-1.amazoncognito.com";
const redirectUri = window.location.origin + "/login.html";

const params = new URLSearchParams(window.location.search);
const code = params.get("code");

if (code) {
  const body =
    "grant_type=authorization_code" +
    "&client_id=" +
    encodeURIComponent(clientId) +
    "&code=" +
    encodeURIComponent(code) +
    "&redirect_uri=" +
    encodeURIComponent(redirectUri);

  fetch(`https://${domain}/oauth2/token`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body,
  })
    .then((response) => response.json())
    .then((data) => {
      console.log("Tokens:", data);

      // Tokens im Browser speichern
      sessionStorage.setItem("id_token", data.id_token);
      sessionStorage.setItem("access_token", data.access_token);
      sessionStorage.setItem("refresh_token", data.refresh_token);

      // Nach erfolgreichem Login zur Admin-Seite weiterleiten
      window.location.href = "admin.html";
    })
    .catch((error) => {
      console.error("Token exchange failed:", error);
    });
}

document.getElementById("loginButton").addEventListener("click", () => {
  const loginUrl =
    `https://${domain}/login` +
    `?client_id=${encodeURIComponent(clientId)}` +
    `&response_type=code` +
    `&scope=openid+email` +
    `&redirect_uri=${encodeURIComponent(redirectUri)}`;

  window.location.href = loginUrl;
});

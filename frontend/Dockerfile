# Frontend als statische Dateien über Nginx ausliefern (Production-Style)
FROM nginx:1.27-alpine

# Statische Dateien ins Nginx-HTML-Verzeichnis kopieren
COPY . /usr/share/nginx/html

# Optional: Default-Nginx-Config drin lassen (reicht für statische Seiten)
EXPOSE 80
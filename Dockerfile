FROM ghcr.io/nginxinc/nginx-unprivileged:alpine

WORKDIR /usr/share/nginx/html/

# Copy static files with correct owner only
COPY --chown=nginx:nginx public/ /usr/share/nginx/html/

USER nginx

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q -O /dev/null http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

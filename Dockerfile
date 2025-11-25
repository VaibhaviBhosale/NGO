# Use nginx unprivileged image
FROM ghcr.io/nginxinc/nginx-unprivileged:alpine

# Set working directory
WORKDIR /usr/share/nginx/html/

# Copy website files WITH correct ownership
COPY --chown=nginx:nginx public/ /usr/share/nginx/html/

# Switch to non-root user to avoid SonarQube S2 warning
USER nginx

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q -O /dev/null http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

# Use nginx without rate-limit issues
FROM ghcr.io/nginxinc/nginx-unprivileged:alpine

# Copy your site into nginx web root
COPY public/ /usr/share/nginx/html/

# Healthcheck (exec form - SonarQube compliant)
HEALTHCHECK --interval=30s --timeout=3s \
  CMD ["wget", "-q", "-O", "/dev/null", "http://localhost:8080/"]

# Expose port 80
EXPOSE 8080

# Run nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]

USER 101
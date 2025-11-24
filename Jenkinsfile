pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:

  - name: node
    image: node:18
    command: ['cat']
    tty: true

  - name: sonar-scanner
    image: sonarsource/sonar-scanner-cli
    command: ['cat']
    tty: true

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['cat']
    tty: true
    securityContext:
      runAsUser: 0
      readOnlyRootFilesystem: false
    env:
    - name: KUBECONFIG
      value: /kube/config
    volumeMounts:
    - name: kubeconfig-secret
      mountPath: /kube/config
      subPath: kubeconfig

  - name: dind
    image: docker:dind
    args: ["--storage-driver=overlay2", "--insecure-registry=nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085"]
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""

  volumes:
  - name: kubeconfig-secret
    secret:
      secretName: kubeconfig-secret
'''
        }
    }

    stages {
    stage('Checkout') {
            steps {
                git url:'https://github.com/VaibhaviBhosale/NGO.git',branch:'main'
            }
        }


        /* -------------------------
           STATIC WEBSITE STEP
           ------------------------- */
        stage('Prepare NGO Website') {
            steps {
                container('node') {
                    sh '''
                        echo "NGO website – static HTML/CSS site"
                        echo "Listing project files..."
                        ls -la
                    '''
                }
            }
        }

        /* -------------------------
           DOCKER BUILD
           ------------------------- */
        stage('Build Docker Image') {
            steps {
                container('dind') {
                    sh '''
                        sleep 10
                        echo "=== Building NGO Docker Image ==="
                        docker build -t ngo:latest .
                    '''
                }
            }
        }

        /* -------------------------
           SONARQUBE ANALYSIS
           ------------------------- */
        stage('SonarQube Analysis') {
            steps {
                container('sonar-scanner') {
                    sh '''
                        sonar-scanner \
                        -Dsonar.projectKey=2401018-Ecommerce \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=https://sonarqube.imcc.com \
                        -Dsonar.token=sqp_9bab4625da21d06e8ff026e7397361d9bfa50b7c

                        
                    '''
                }
            }
        }

        /* -------------------------
           DOCKER LOGIN TO NEXUS
           ------------------------- */
        stage('Login to Nexus Registry') {
            steps {
                container('dind') {
                    sh '''
                        echo "Logging in to Nexus Docker Registry..."
                        docker login nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085 \
                          -u admin -p Changeme@2025
                    '''
                }
            }
        }

        /* -------------------------
           PUSH IMAGE TO NEXUS
           ------------------------- */
        stage('Push NGO Image to Nexus') {
            steps {
                container('dind') {
                    sh '''
                        echo "Tagging NGO image..."
                        docker tag ngo:latest nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401018_NGO/ngo:v1

                        echo "Pushing NGO image to Nexus..."
                        docker push nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401018_NGO/ngo:v1
                    '''
                }
            }
        }

        /* -------------------------
           CREATE NAMESPACE
           ------------------------- */
        stage('Create Namespace') {
            steps {
                container('kubectl') {
                    sh '''
                        echo "Creating namespace 2401018 if not exists..."
                        kubectl create namespace 2401018 || echo "Namespace already exists"
                        kubectl get ns
                    '''
                }
            }
        }

        /* -------------------------
           DEPLOY TO KUBERNETES
           ------------------------- */
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                        echo "Applying NGO Kubernetes Deployment & Service..."

                        kubectl apply -f k8s/deployment.yaml -n 2401018
                        kubectl apply -f k8s/service.yaml -n 2401018

                        echo "Checking all resources..."
                        kubectl get all -n 2401018

                        echo "Waiting for rollout..."
                        kubectl rollout status deployment/engo-connect-deployment -n 2401018
                    '''
                }
            }
        }

        /* -------------------------
           DEBUG
           ------------------------- */
        stage('Debug Pods') {
            steps {
                container('kubectl') {
                    sh '''
                        echo "[DEBUG] Listing Pods..."
                        kubectl get pods -n 2401018

                        echo "[DEBUG] Describe Pods..."
                        kubectl describe pods -n 2401018 | head -n 200
                    '''
                }
            }
        }
    }
}
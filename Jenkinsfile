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

  environment {
    APP_NAME        = "engeo-frontend"          // your app name
    IMAGE_TAG       = "v1"                       // or latest
    REGISTRY_URL    = "nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085"
    REGISTRY_REPO   = "2401018_ngo"              // your namespace/project
    SONAR_PROJECT   = "2401018_Ecommerce"
    SONAR_HOST_URL  = "http://my-sonarqube-sonarqube.sonarqube.svc.cluster.local:9000"
}

    stages {

        /* -------------------------
           REMOVE OLD DOCKERFILE
           ------------------------- */
        stage('Clean Old Workspace Dockerfile') {
            steps {
                container('node') {
                    sh '''
                        echo "Deleting ALL existing Dockerfiles in Kubernetes workspace..."
                        find . -name "Dockerfile" -type f -print -delete || true
                        echo "Workspace cleaned."
                    '''
                }
            }
        }

        /* -------------------------
           CHECKOUT
           ------------------------- */
        stage('Checkout') {
            steps {
                git url:'https://github.com/VaibhaviBhosale/NGO.git', branch:'main'
            }
        }

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

        stage('SonarQube Analysis') {
    steps {
        container('sonar-scanner') {
            withCredentials([
                string(credentialsId: 'SONAR_TOKEN_ID', variable: 'SONAR_TOKEN')
            ]) {
                sh '''
                    echo "Checking SonarQube reachability..."
                    curl -I $SONAR_HOST_URL || echo "SonarQube not reachable, but running scanner anyway."

                    sonar-scanner \
                      -Dsonar.projectKey=2401018_Ecommerce \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=$SONAR_HOST_URL \
                      -Dsonar.login=$SONAR_TOKEN
                '''
            }
        }
    }
}


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

        stage('Push NGO Image to Nexus') {
            steps {
                container('dind') {
                    sh '''
                        echo "Tagging NGO image..."
                        docker tag ngo:latest nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401018_ngo/ngo:v1

                        echo "Pushing NGO image to Nexus..."
                        docker push nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401018_ngo/ngo:v1
                    '''
                }
            }
        }

        stage('Create Namespace') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl create namespace 2401018 || echo "Namespace already exists"
                        kubectl get ns
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                        echo "Applying NGO Kubernetes Deployment & Service..."
                        kubectl apply -f k8s/deployment.yaml -n 2401018
                        kubectl apply -f k8s/service.yaml -n 2401018

                        kubectl get all -n 2401018

                        kubectl rollout status deployment/engeo-frontend-deployment -n 2401018

                    '''
                }
            }
        }

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

pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: sonar-scanner
    image: sonarsource/sonar-scanner-cli
    command: ["cat"]
    tty: true

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
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
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
    volumeMounts:
    - name: docker-config
      mountPath: /etc/docker/daemon.json
      subPath: daemon.json

  volumes:
  - name: docker-config
    configMap:
      name: docker-daemon-config
  - name: kubeconfig-secret
    secret:
      secretName: kubeconfig-secret
'''
        }
    }

    environment {
        SONAR_HOST = 'http://my-sonarqube-sonarqube.sonarqube.svc.cluster.local:9000'
    }

    stages {

        stage('Build Docker Image') {
            steps {
                container('dind') {
                    sh '''
                        echo "Building NGO Docker image..."
                        sleep 15
                        docker build -t ngo:latest .
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('sonar-scanner') {
                    withCredentials([
                        string(credentialsId: 'sonartoken-2401018', variable: 'SONAR_TOKEN')
                    ]) {
                        sh '''
                            sonar-scanner \
                              -Dsonar.projectKey=2401018_Ecommerce \
                              -Dsonar.sources=. \
                              -Dsonar.exclusions=node_modules/**,dist/** \
                              -Dsonar.host.url=${SONAR_HOST} \
                              -Dsonar.token=${SONAR_TOKEN}
                        '''
                    }
                }
            }
        }

        stage('Login to Docker Registry') {
            steps {
                container('dind') {
                    sh '''
                        docker --version
                        docker login nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085 \
                          -u admin -p Changeme@2025
                    '''
                }
            }
        }

        stage('Build - Tag - Push') {
            steps {
                container('dind') {
                    sh '''
                        docker tag ngo:latest \
                          nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401018_ngo/ngo:v1

                        docker push \
                          nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401018_ngo/ngo:v1

                        docker image ls
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    dir('k8s') {
                        sh '''
                            echo "Deploying NGO application to Kubernetes..."

                            kubectl apply -f deployment.yaml -n 2401018
                            kubectl apply -f service.yaml -n 2401018

                            kubectl rollout status deployment/engeo-frontend-deployment \
                              -n 2401018 --timeout=120s
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
    steps {
        container('kubectl') {
            sh '''
                echo "Checking deployment rollout status..."
                kubectl rollout status deployment/engeo-frontend-deployment -n 2401018
            '''
        }
    }
}

stage('Verify Pods') {
    steps {
        container('kubectl') {
            sh '''
                kubectl get pods -n 2401018
            '''
        }
    }
}

stage('Verify Services') {
    steps {
        container('kubectl') {
            sh '''
                kubectl get svc -n 2401018
            '''
        }
    }
}

stage('Get Node IP') {
    steps {
        container('kubectl') {
            sh 'kubectl get nodes -o wide'
        }
    }
}



    }
}
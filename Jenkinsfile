pipeline {
    agent any
    tools{
        maven 'maven_3_5_0'
    }
    environment {
        DOCKER_HOME = '/usr/local/bin/docker'  // Path to the Docker executable
    }
    stages{
        stage('Build Maven'){
            steps{
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/Ataetano/test_deploy_with_jenkins.git']]])
                bat 'mvn clean install'
            }
        }
        stage('Build image'){
            steps{
                script{
                    bat '${DOCKER_HOME} build -t discovery-service:latest .'
                }
            }
        }
        
        stage('Push image to Hub'){
            steps{
                script{
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-pwd', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        bat '${DOCKER_HOME} login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}'
                        bat '${DOCKER_HOME} tag discovery-service:latest janescience/discovery-service:latest'
                        bat '${DOCKER_HOME} push janescience/discovery-service:latest'
                        bat '${DOCKER_HOME} rmi -f $(${DOCKER_HOME} images -f "dangling=true" -q)'
                    }
                }
            }
        }
        stage('Deploy to k8s'){
            steps{
                script{
                    kubernetesDeploy (configs: 'k8s/deployment.yml',kubeconfigId: 'k8sconfigpwd')
                    kubernetesDeploy (configs: 'k8s/service.yml',kubeconfigId: 'k8sconfigpwd')
                }
            }
        
        }
    }
}

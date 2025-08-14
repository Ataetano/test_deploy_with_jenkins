pipeline {
  agent any
  tools { maven 'maven_3_5_0' }

  environment {
    // Use the full path or just 'docker' if it's on PATH.
    DOCKER = 'C:\\Program Files\\Docker\\Docker\\resources\\bin\\docker.exe'
  }

  stages {
    stage('Checkout & Build') {
      steps {
        checkout([$class: 'GitSCM',
          branches: [[name: '*/main']],
          extensions: [],
          userRemoteConfigs: [[url: 'https://github.com/Ataetano/test_deploy_with_jenkins.git']]
        ])
        bat 'mvn -B clean install'
      }
    }

    stage('Docker Login') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-pwd',
                         usernameVariable: 'DOCKER_USERNAME',
                         passwordVariable: 'DOCKER_PASSWORD')]) {
          bat 'echo %DOCKER_PASSWORD% | "%DOCKER%" login -u %DOCKER_USERNAME% --password-stdin'
        }
      }
    }

    stage('Build & Push Image') {
      steps {
        bat '"%DOCKER%" build -t discovery-service:latest .'
        bat '"%DOCKER%" tag discovery-service:latest janescience/discovery-service:latest'
        bat '"%DOCKER%" push janescience/discovery-service:latest'
      }
    }

    stage('Cleanup (optional)') {
      steps {
        // Safer than FOR /F with a long path; removes dangling images
        bat '"%DOCKER%" image prune -f'
      }
    }

    stage('Deploy to k8s') {
      steps {
        script {
          kubernetesDeploy(configs: 'k8s/deployment.yml', kubeconfigId: 'k8sconfigpwd')
          kubernetesDeploy(configs: 'k8s/service.yml',    kubeconfigId: 'k8sconfigpwd')
        }
      }
    }
  }
}

pipeline {
  agent any
  tools { maven 'maven_3_5_0' }

  environment {
    // Use 'docker' if it's on PATH, or set to full path like:
    // 'C:\\Program Files\\Docker\\Docker\\resources\\bin\\docker.exe'
    DOCKER = 'docker'
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
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-pwd',
          usernameVariable: 'DOCKER_USERNAME',
          passwordVariable: 'DOCKER_PASSWORD'
        )]) {
          // Login via stdin (PowerShell handles special chars properly)
          powershell 'echo $env:DOCKER_PASSWORD | & $env:DOCKER login -u $env:DOCKER_USERNAME --password-stdin'
          // Show who we are logged in as (for sanity)
          powershell '& $env:DOCKER info | Select-String -Pattern "^ Username"'
        }
      }
    }

    stage('Build & Push Image') {
      steps {
        powershell '& $env:DOCKER build -t discovery-service:latest .'

        // Push to a namespace you control. If you’re logged in as `build2556`, push there:
        powershell '& $env:DOCKER tag discovery-service:latest build2556/discovery-service:latest'
        powershell '& $env:DOCKER push build2556/discovery-service:latest'

        // If you instead need to push to another namespace (e.g., janescience),
        // make sure the logged-in user has write access and change the two lines above accordingly.
      }
    }

    stage('Cleanup (optional)') {
      steps {
        // Remove dangling images; then logout
        powershell '& $env:DOCKER image prune -f'
        powershell '& $env:DOCKER logout'
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

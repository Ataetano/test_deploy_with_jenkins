pipeline {
  agent any
  tools { maven 'maven_3_5_0' }
  environment {
    // Either rely on PATH:
    DOCKER = 'C:\\Program Files\\Docker\\Docker\\resources\\bin\\docker.exe'
    // or hard-code the full path (quotes added by the bat line below handle spaces):
    // DOCKER = 'C:\\Program Files\\Docker\\Docker\\resources\\bin\\docker.exe'
  }
  stages {
    stage('Build Maven') {
      steps {
        bat 'mvn -B clean install'
      }
    }
    stage('Build image') {
      steps {
        bat '"%DOCKER%" build -t discovery-service:latest .'
      }
    }
    stage('Push image to Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-pwd',
                          usernameVariable: 'DOCKER_USERNAME',
                          passwordVariable: 'DOCKER_PASSWORD')]) {
          bat '''
echo %DOCKER_PASSWORD% | "%DOCKER%" login -u %DOCKER_USERNAME% --password-stdin
"%DOCKER%" tag discovery-service:latest janescience/discovery-service:latest
"%DOCKER%" push janescience/discovery-service:latest
for /f "usebackq delims=" %%i in (`"%DOCKER%" images -f "dangling=true" -q`) do "%DOCKER%" rmi -f %%i
'''
        }
      }
    }
  }
}

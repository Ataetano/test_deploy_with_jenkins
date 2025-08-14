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
        withCredentials([usernamePassword(credentialsId: 'dockerhub-pwd',
          usernameVariable: 'DOCKER_USERNAME',
          passwordVariable: 'DOCKER_PASSWORD')]) {

          // Prefer the simple, reliable form in Windows CI:
          powershell '& $env:DOCKER logout | Out-Null; & $env:DOCKER login -u $env:DOCKER_USERNAME -p $env:DOCKER_PASSWORD'
        }
      }
    }

    // stage('Docker Login') {
    //   steps {
    //     withCredentials([usernamePassword(
    //       credentialsId: 'dockerhub-pwd',
    //       usernameVariable: 'DOCKER_USERNAME',
    //       passwordVariable: 'DOCKER_PASSWORD'
    //     )]) {
    //       // Login via stdin (PowerShell handles special chars properly)
    //       powershell 'echo $env:DOCKER_PASSWORD | & $env:DOCKER login -u $env:DOCKER_USERNAME --password-stdin'
    //       // Show who we are logged in as (for sanity)
    //       powershell '& $env:DOCKER info | Select-String -Pattern "^ Username"'
    //     }
    //   }
    // }

    // stage('Docker Login (diagnose)') {
    //   steps {
    //     withCredentials([usernamePassword(
    //       credentialsId: 'dockerhub-pwd',
    //       usernameVariable: 'DOCKER_USERNAME',
    //       passwordVariable: 'DOCKER_PASSWORD'
    //     )]) {
    //       // Show which Jenkins account is running and the Docker CLI path/version
    //       powershell '''
    // Write-Host "Jenkins running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
    // $docker = $env:DOCKER; if (-not $docker) { $docker = "docker" }
    // & $docker --version

    // # Logout to clear any stale cached auth for this Windows profile
    // & $docker logout 2>$null | Out-Null

    // # Basic sanity: username and secret length
    // Write-Host "DockerHub user = $env:DOCKER_USERNAME"
    // $secret = $env:DOCKER_PASSWORD
    // if ($null -eq $secret) { throw "DOCKER_PASSWORD is empty in Jenkins credentials." }
    // $trimmed = $secret.Trim()     # remove accidental spaces/newlines
    // Write-Host "Secret length (trimmed) = $($trimmed.Length)"

    // # TRY 1: login with --password-stdin (recommended)
    // $loginCmd = "$env:DOCKER_USERNAME via --password-stdin"
    // $stdin = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($trimmed + "`n"))
    // $psi = New-Object System.Diagnostics.ProcessStartInfo
    // $psi.FileName  = $docker
    // $psi.Arguments = "login -u $env:DOCKER_USERNAME --password-stdin"
    // $psi.RedirectStandardInput  = $true
    // $psi.RedirectStandardOutput = $true
    // $psi.RedirectStandardError  = $true
    // $psi.UseShellExecute = $false
    // $p = New-Object System.Diagnostics.Process
    // $p.StartInfo = $psi
    // $p.Start() | Out-Null
    // $stdin.WriteTo($p.StandardInput.BaseStream)
    // $p.StandardInput.Close()
    // $p.WaitForExit()
    // if ($p.ExitCode -ne 0) {
    //   Write-Host "stdin login failed (exit $($p.ExitCode)). stderr:"
    //   Write-Host $p.StandardError.ReadToEnd()

    //   # TRY 2: fallback to -p (diagnostic). This is less secure but helps catch quoting issues.
    //   Write-Host "Retrying with -p (diagnostic)..."
    //   & $docker login -u $env:DOCKER_USERNAME -p $trimmed
    //   if ($LASTEXITCODE -ne 0) {
    //     throw "Docker login failed with both --password-stdin and -p. Check username/token in Jenkins credentials."
    //   }
    // }

    // # Verify who we are logged in as
    // $info = & $docker info 2>$null
    // if ($LASTEXITCODE -ne 0) { throw "Docker daemon not reachable or not running for this Jenkins user." }
    // $u = ($info -split "`n" | Where-Object { $_ -match 'Username:' } | ForEach-Object { $_.Split(':')[1].Trim() })
    // if (-not $u) { throw "Login appeared to succeed but no Username found in 'docker info'." }
    // Write-Host "Logged in as: $u"
    // if ($u -ne $env:DOCKER_USERNAME) {
    //   throw "Logged in as '$u' but expected '$env:DOCKER_USERNAME'. Wrong account or stale config.json."
    // }
    // '''
    //     }
    //   }
    // }

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

    stage('Deploy to k8s (kubectl)') {
      steps {
        // credentialsId: your uploaded kubeconfig (Secret file or Kubeconfig cred)
        withKubeConfig([credentialsId: 'k8sconfigpwd']) {
          // Optional sanity checks
          powershell '& kubectl version --short'
          powershell '& kubectl config current-context'
          powershell '& kubectl get ns'

          // Apply manifests (default namespace or specify -n)
          powershell '& kubectl apply -f k8s/deployment.yml'
          powershell '& kubectl apply -f k8s/service.yml'

          // If your Deployment name is discovery-service-app and you want to roll to the new image tag:
          // powershell '& kubectl -n default set image deploy/discovery-service-app discovery-service=build2556/discovery-service:${env:BUILD_NUMBER}'

          // Wait until rollout completes
          powershell '& kubectl -n default rollout status deploy/discovery-service-app --timeout=120s'
        }
      }
    }

  }
}

pipeline {
  agent any

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20'))
    disableConcurrentBuilds()
  }

  parameters {
    string(
      name: 'DOCKERHUB_REPO',
      defaultValue: 'vinayk14581/jenkins-flask',
      description: 'Full repo name (e.g. user/jenkins-flask)'
    )
    booleanParam(
      name: 'DEPLOY_LOCAL',
      defaultValue: true,
      description: 'Run the container on this Jenkins host after push'
    )
  }

  environment {
    IMAGE_NAME = "${params.DOCKERHUB_REPO}"
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Unit Tests (pytest)') {
      steps {
        script {
          // keep Jenkins node clean: run tests in a disposable Python container
          docker.image('python:3.12-slim').inside('-u 0') {
            sh '''
              python -V
              pip install --no-cache-dir -r app/requirements.txt
              cd app
              pytest -q
            '''
          }
        }
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest .
          docker image ls | head -n 10
        '''
      }
    }

    stage('Docker Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${IMAGE_NAME}:latest
          '''
        }
      }
    }

    stage('Deploy (local)') {
      when { expression { return params.DEPLOY_LOCAL } }
      steps {
        sh '''
          # stop existing container if present
          (docker ps -aq --filter "name=flask_app" | xargs -r docker rm -f) || true
          # run the newly built image
          docker run -d --name flask_app -p 5000:5000 ${IMAGE_NAME}:${IMAGE_TAG}
          docker ps --filter "name=flask_app"
        '''
      }
    }
  }

  post {
    success { echo "✅ Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}" }
    failure { echo "❌ Build failed" }
    always  { cleanWs(deleteDirs: false) }
  }
}

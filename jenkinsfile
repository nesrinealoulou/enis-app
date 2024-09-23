pipeline {
    agent any

    environment {
        REGION = 'us-east-1'
        REPOSITORY_FRONTEND = '746200881003.dkr.ecr.us-east-1.amazonaws.com/enis-app:frontend-app-latest'
        REPOSITORY_BACKEND = '746200881003.dkr.ecr.us-east-1.amazonaws.com/enis-app:backend-app-latest'
        AWS_CREDENTIALS_ID = 'aws-credentials'  // ID of the AWS credentials stored in Jenkins
    }

    stages {
        stage('Clone Repository') {
            steps {
                echo 'Cloning the repository...'
                git url: 'https://github.com/nesrinealoulou/enis-app.git', branch: 'main'
            }
        }

        stage('Build Frontend Docker Image') {
            steps {
                dir('frontend') {
                    script {
                        echo 'Building Frontend Docker Image...'
                        def frontendImage = docker.build('frontend-app')
                        echo "Built Image: ${frontendImage.id}"
                    }
                }
            }
        }

        stage('Build Backend Docker Image') {
            steps {
                dir('backend') {
                    script {
                        echo 'Building Backend Docker Image...'
                        def backendImage = docker.build('backend-app')
                        echo "Built Image: ${backendImage.id}"
                    }
                }
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'cd15bc80-8a23-4622-8c73-cf38e0e139d9']]) {
                    sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 746200881003.dkr.ecr.us-east-1.amazonaws.com/enis-app'
                }
            }
        }

        stage('Tag and Push Frontend Image') {
            steps {
                script {
                    echo 'Tagging and pushing Frontend Image...'
                    sh "docker tag frontend-app:latest $REPOSITORY_FRONTEND"
                    sh "docker push $REPOSITORY_FRONTEND"
                }
            }
        }

        stage('Tag and Push Backend Image') {
            steps {
                script {
                    echo 'Tagging and pushing Backend Image...'
                    sh "docker tag backend-app:latest $REPOSITORY_BACKEND"
                    sh "docker push $REPOSITORY_BACKEND"
                }
            }
        }
    }
}

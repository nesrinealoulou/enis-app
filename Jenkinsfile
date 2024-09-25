pipeline {
    agent any

    environment {
        REGION = 'us-east-1'
        REPOSITORY_FRONTEND = '746200881003.dkr.ecr.us-east-1.amazonaws.com/enis-app:frontend-app-latest'
        REPOSITORY_BACKEND = '746200881003.dkr.ecr.us-east-1.amazonaws.com/enis-app:backend-app-latest'
        AWS_CREDENTIALS_ID = 'aws-credentials'  // ID of the AWS credentials stored in Jenkins
        KEY_PATH = "${WORKSPACE}/ansible/myjupt.pem"
        ANSIBLE_CONFIG = "${WORKSPACE}/ansible/ansible.cfg"
    }

    stages {
        stage('Initialize and Apply Terraform') {
            steps {
                script {
                    // Initialize and apply Terraform
                    sh 'terraform init'
                    sh 'terraform apply --auto-approve'
                    
                    // Extract and set the IP dynamically
                    EC2_PUBLIC_IP = sh(script: "terraform output -raw ec2_public_ip", returnStdout: true).trim()
                }
            }
        }
        stage('Configure Ansible Inventory') {
            steps {
                script {
                    // Write the hosts file with the dynamically obtained IP
                    writeFile file: "${WORKSPACE}/ansible/hosts", text: """
                    [ec2-docker]
                    ${EC2_PUBLIC_IP}

                    [ec2-docker:vars]
                    ansible_ssh_private_key_file=${KEY_PATH}
                    ansible_user=ubuntu
                    """

                    // Print the hosts file to verify the contents
                    echo "Contents of the hosts file:"
                    sh "cat ${WORKSPACE}/ansible/hosts"
                }
            }
        }
        stage('Execute Ansible Playbook') {
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/playbook.yml',
                    inventory: "${WORKSPACE}/ansible/hosts"
                )
            }
        }
        stage('Clone Repository') {
            steps {
                script{
                    sleep("time": 30, "unit": "SECONDS")
                }
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
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'cd16bc80-8a23-4622-8c73-cf38e0e139d9']]) {
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
                    EC2_PUBLIC_IP = sh(
                    script: "terraform output ec2_public_ip",
                    returnStdout: true
                ).trim()
                }
            }
        }
        stage('Run Ansible Playbook') {
            environment {
                        AWS_ACCESS_KEY_ID     = credentials('jenkins_aws_access_key_id')
                        AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                        EC2_PUBLIC_IP = sh(script: "terraform output ec2_public_ip",returnStdout: true
                        ).trim()

                    }
            steps {
                
                script {
                    
                    // Assuming Ansible and SSH configurations are already in place
                    echo 'Running Ansible Playbook...'
                    sh 'chmod 600 ${WORKSPACE}/ansible/myjupt.pem'
                    
                    // Run the Ansible playbook
                    sh '''
                    ansible-playbook -i ansible/hosts ansible/deploy-docker.yaml --extra-vars "docker_compose_src=${WORKSPACE}/docker-compose.yaml"
                    '''

                }
            }
        }
        
        

    }
}

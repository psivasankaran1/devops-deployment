pipeline {
    agent any

    environment {
        DEV_REPO = "prabakaran90/devops-app-dev"
        PROD_REPO = "prabakaran90/devops-app-prod"
        IMAGE_TAG = "latest"

        // AWS Configuration
        AWS_REGION = "ap-south-1"
        AMI_ID = "ami-00bb6a80f01f03502"
        INSTANCE_TYPE = "t2.micro"
        KEY_NAME = "spkey1"
        SECURITY_GROUP = "guvi-project01-sg"
        SUBNET_ID = "subnet-01764d41845dfeaa2"
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    def BRANCH = 'master'   
                    //def BRANCH = env.BRANCH_NAME ?: 'dev'
                    echo "🚀 Cloning repository: Branch = ${BRANCH}"
                    git credentialsId: 'github-credentials', branch: BRANCH, url: 'https://github.com/psivasankaran1/devops-deployment.git'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def BRANCH = env.BRANCH_NAME ?: 'dev'
                    def IMAGE_NAME = (BRANCH == "master") ? "${PROD_REPO}:${IMAGE_TAG}" : "${DEV_REPO}:${IMAGE_TAG}"
                    
                    echo "🛠 Building Docker Image: $IMAGE_NAME"
                    sh "docker build -t $IMAGE_NAME ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    def BRANCH = env.BRANCH_NAME ?: 'dev'
                    def IMAGE_NAME = (BRANCH == "master") ? "${PROD_REPO}:${IMAGE_TAG}" : "${DEV_REPO}:${IMAGE_TAG}"

                    withDockerRegistry([credentialsId: 'docker-hub-credentials', url: 'https://index.docker.io/v1/']) {
                        echo "📤 Pushing Docker Image: $IMAGE_NAME"
                        sh "docker push $IMAGE_NAME"
                    }
                }
            }
        }

        stage('Deploy to AWS') {
            when {
                branch 'master'
            }
            steps {
                script {
                    echo "🚀 Deploying to AWS (only for master branch)..."

                    // Create EC2 instance and get instance ID
                    def INSTANCE_ID = sh(script: """
                        aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE \
                        --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP --subnet-id $SUBNET_ID \
                        --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-deployed-instance}]' \
                        --query 'Instances[0].InstanceId' --output text
                    """, returnStdout: true).trim()
                    
                    echo "�� EC2 Instance Created: $INSTANCE_ID"

                    // Get Public IP of the EC2 instance
                    sleep(10)  // Give some time for AWS to initialize
                    def PUBLIC_IP = sh(script: """
                        aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                        --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
                    """, returnStdout: true).trim()
                    
                    echo "📡 EC2 Public IP: $PUBLIC_IP"

                    // Deploy Docker container to the EC2 instance
                    def IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"
                    sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} <<EOF
                            docker login -u your-dockerhub-username -p your-dockerhub-password
                            docker pull $IMAGE_NAME
                            docker stop devops-app || true
                            docker rm devops-app || true
                            docker run -d --name devops-app -p 80:80 $IMAGE_NAME
                        EOF
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Deployment failed. Check logs!"
        }
    }
}

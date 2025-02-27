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
                    def BRANCH = env.BRANCH_NAME ?: env.GIT_BRANCH?.replace('origin/', '') ?: 'dev'
                    echo "🚀 Cloning repository: Branch = ${BRANCH}"
                    git credentialsId: 'github-credentials', branch: BRANCH, url: 'https://github.com/psivasankaran1/devops-deployment.git'
                    env.CURRENT_BRANCH = BRANCH
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def IMAGE_NAME = "${DEV_REPO}:${IMAGE_TAG}"
                    if (env.CURRENT_BRANCH == "master") {
                        IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"
                    }
                    echo "🛠 Building Docker Image: $IMAGE_NAME"
                    sh "docker build -t $IMAGE_NAME ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    def IMAGE_NAME = "${DEV_REPO}:${IMAGE_TAG}"
                    if (env.CURRENT_BRANCH == "master") {
                        IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"
                    }

                    withDockerRegistry([credentialsId: 'docker-hub-credentials', url: 'https://index.docker.io/v1/']) {
                        echo "📤 Pushing Docker Image: $IMAGE_NAME"
                        sh "docker push $IMAGE_NAME"
                    }
                }
            }
        }

        stage('Deploy to AWS') {
            when {
                expression { env.CURRENT_BRANCH == 'master' }
            }
            steps {
                script {
                    echo "🚀 Deploying to AWS (only for master branch)..."

                    echo "🖥 Creating EC2 instance..."
                    sh """
                        INSTANCE_ID=\$(aws ec2 run-instances \
                            --image-id $AMI_ID \
                            --instance-type $INSTANCE_TYPE \
                            --key-name $KEY_NAME \
                            --security-group-ids $SECURITY_GROUP \
                            --subnet-id $SUBNET_ID \
                            --count 1 \
                            --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-deployed-instance}]' \
                            --query 'Instances[0].InstanceId' --output text)
                        echo \$INSTANCE_ID > instance_id.txt
                    """

                    echo "📡 Getting EC2 Public IP..."
                    def INSTANCE_ID = sh(script: "cat instance_id.txt", returnStdout: true).trim()
                    sh """
                        PUBLIC_IP=\$(aws ec2 describe-instances \
                            --instance-ids $INSTANCE_ID \
                            --query 'Reservations[0].Instances[0].PublicIpAddress' \
                            --output text)
                        echo \$PUBLIC_IP > public_ip.txt
                    """

                    echo "🚀 Deploying Docker container to EC2 instance..."
                    def PUBLIC_IP = sh(script: "cat public_ip.txt", returnStdout: true).trim()
                    def IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"

                    sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@\$PUBLIC_IP <<EOF
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
